pragma solidity 0.5.11;

import './Claimable.sol';
import './McdWrapper.sol';
import './DaiStableCoinPrototype.sol';


interface AgreementInterface {
    
    function isClosed() external view returns(bool);
    function matchAgreement() external returns(bool);
    function checkAgreement() external returns(bool);
    
    event AgreementInitiated(address _borrower, uint256 _interestRate, uint256 _borrowerCollateralValue, uint256 _debtValue);
    event AgreementMatched(address _borrower, address _lender, uint256 _interestRate, uint256 _borrowerCollateralValue, uint256 _debtValue);
}

contract BaseAgreement is Claimable, AgreementInterface{
    address constant daiStableCoinAddress = address(0xc7cC3413f169a027dccfeffe5208Ca4f38eF0c40);
    address constant MCDWrapperMockAddress = address(0xAF474f085cdBca740A39C60F4c2EB48e71a494bF); 
    
    DaiStableCoinPrototype DaiInstance = DaiStableCoinPrototype(daiStableCoinAddress);
    McdWrapper WrapperInstance = McdWrapper(MCDWrapperMockAddress);

    uint256 constant TWENTY_FOUR_HOURS = 86399;
    uint256 constant YEAR = 31536000;
    uint256 constant ONE = 10 ** 27;
    uint256 constant injectionThreshold = 2 * ONE;
    
    address payable public borrower;
    address payable public lender;
    uint256 public borrowerCollateralValue;
    uint256 public debtValue;
    uint256 public startDate;
    uint256 public initialDate;
    uint256 public expireDate;
    uint256 public interestRate;
    uint256 public borrowerFRADebt;
    uint256 public lenderPendingInjection;
    bool public isClosed;
    uint256 public cdpId;
    uint256 public lastCheckTime;
    
    // test version, should be extended after stable multicollaterall makerDAO release
    bytes32 constant collateralType = 0x4554482d41000000000000000000000000000000000000000000000000000000; // ETH-A
    uint256 public ethAmountAfterLiquidation;
    //
    
    modifier isActive() {
        require(!isClosed);
        _;
    }
    
    constructor(address payable _borrower, uint256 _borrowerCollateralValue, uint256 _debtValue, uint256 _expireDate, uint256 _interestRate) public payable {
        require(_expireDate > now, 'expairy date is in the past');
        require(_debtValue > 0);
        require(_interestRate <= ONE, 'interestRate');
        
        uint256 _cdpId;

        borrower = _borrower;
        debtValue = _debtValue;
        initialDate = now;
        expireDate = _expireDate;
        interestRate = _interestRate + ONE;
        borrowerCollateralValue = _borrowerCollateralValue;
        bytes32 response = execute(MCDWrapperMockAddress, abi.encodeWithSignature('openEthaCdp(uint256)', _debtValue));
        assembly {
            _cdpId := mload(add(response, 0x20))
        }
        cdpId = _cdpId;
    }
    
    function execute(address _target, bytes memory _data)
        public
        payable
        returns (bytes32 response)
    {
        require(_target != address(0));

        // call contract in current context
        assembly {
            let succeeded := delegatecall(sub(gas, 5000), _target, add(_data, 0x20), mload(_data), 0, 32)
            response := mload(0)      // load delegatecall output
            switch iszero(succeeded)
            case 1 {
                // throw if delegatecall failed
                revert(0, 0)
            }
        }
    }
}

contract AgreementETH is BaseAgreement {
    
    uint256 public dsrTest = 105 * 10 ** 25;
    
    constructor (address payable _borrower, uint256 _borrowerCollateralValue, uint256 _debtValue, uint256 _expairyDate, uint256 _interestRate) public payable
    BaseAgreement(_borrower, _borrowerCollateralValue, _debtValue, _expairyDate, _interestRate) {}
    
    function setdsrTest(uint256 _dsrTest) public {
        dsrTest = _dsrTest;
    }
    
    function matchAgreement() public isActive() returns(bool _success) {
        require(isPending(), 'Agreement has its lender already');
        
        (bool transferSuccess,) = daiStableCoinAddress.call(
            abi.encodeWithSignature('transferFrom(address,address,uint256)', msg.sender, address(this), debtValue));
        require(transferSuccess, 'Impossible to transfer DAI tokens, make valid allowance');
        
        lender = msg.sender;
        startDate = now;
        execute(MCDWrapperMockAddress, abi.encodeWithSignature('lockDai(uint256)', debtValue));

        lastCheckTime = now;
        emit AgreementMatched(borrower, msg.sender, interestRate, borrowerCollateralValue, debtValue);
        return true;
    }
    
    function checkAgreement() public onlyContractOwner() isActive() returns(bool _success) { // is supposed to be called in loop externaly
        if (!isPending()) {
            _updateCurrentStateOrMakeInjection();
            
            if(WrapperInstance.isCDPLiquidated(collateralType, cdpId)) {
                _liquidateAgreement();
            }
        }
        
        if(_checkExpiringDate()) {
            _terminateAgreement();
        }
        
        lastCheckTime = now;
        
        return true;
    }
    
    function _checkExpiringDate() internal view returns(bool _isExpired) {
        return (now > expireDate || isPending() && now > (initialDate + TWENTY_FOUR_HOURS));
    }
    
    function _terminateAgreement() internal returns(bool _success) {
        uint256 borrowerFraDebtDai = borrowerFRADebt/ONE;
        
        uint256 finalDaiLenderBalance = WrapperInstance.getLockedDai();
        execute(MCDWrapperMockAddress, abi.encodeWithSignature('unlockDai()'));
            
        if(borrowerFRADebt > 0) {
        (bool TransferSuccessful,) = daiStableCoinAddress
            .call(abi.encodeWithSignature(
                'transferFrom(address, address, uint256)', borrower, address(this), borrowerFraDebtDai));
            
            if(TransferSuccessful) {
                finalDaiLenderBalance += borrowerFRADebt;
            } else {
                ethAmountAfterLiquidation = WrapperInstance.forceLiquidate(collateralType, cdpId);
                _refundUsersAfterCDPLiquidation();
            }
        }
        
        DaiInstance.transfer(lender, finalDaiLenderBalance);
        WrapperInstance.transferCdpOwnership(cdpId, borrower);
        
        isClosed = true;
        return true;
    }
    
    function _liquidateAgreement() internal returns(bool _success) {
        if(borrowerFRADebt > 0) {
            _refundUsersAfterCDPLiquidation();
        } else {
            borrower.transfer(address(this).balance);
        }
        
        execute(MCDWrapperMockAddress, abi.encodeWithSignature('unlockDai()'));
        DaiInstance.transfer(lender, WrapperInstance.getLockedDai());
        WrapperInstance.transferCdpOwnership(cdpId, borrower);
        
        isClosed = true;
        return true;
    }
    
    function _updateCurrentStateOrMakeInjection() internal returns(bool _success) { 
        uint256 currentDSR = dsrTest; //WrapperInstance.getDsr();
        uint256 currentDaiLenderBalance;
        uint256 timeInterval = now - lastCheckTime;
        
        currentDaiLenderBalance = WrapperInstance.getLockedDai();
        execute(MCDWrapperMockAddress, abi.encodeWithSignature('unlockAllDai()'));

        if(currentDSR >= interestRate) {
            
            //rad, 45
            uint256 currentDifference = ((debtValue * (currentDSR - interestRate)) * timeInterval) / YEAR; // to extend with calculation according to decimals
            
            if(currentDifference <= borrowerFRADebt) {
                //rad, 45
                borrowerFRADebt -= currentDifference;
            } else {
                currentDifference -= borrowerFRADebt;
                borrowerFRADebt = 0;
                //rad, 45
                lenderPendingInjection += currentDifference;
                if(lenderPendingInjection >= injectionThreshold) {
                    //wad, 18
                    uint256 lenderPendingInjectionDai = lenderPendingInjection/ONE;
                    execute(MCDWrapperMockAddress, abi.encodeWithSignature('inject(uint256)', lenderPendingInjectionDai));
                    //wad, 18
                    lenderPendingInjection = 0;
                    currentDaiLenderBalance -= lenderPendingInjectionDai;
                } 
            }
        } else {
            uint256 currentDifference = ((debtValue * (interestRate - currentDSR)) * timeInterval) / YEAR; // to extend with calculation according to decimals
            borrowerFRADebt += currentDifference;
        }
        
        execute(MCDWrapperMockAddress, abi.encodeWithSignature('lockDai(uint256)', currentDaiLenderBalance));
        
        return true;
    }
    
    function isPending() public view returns(bool) {
        return (lender == address(0));
    }
    
    function _refundUsersAfterCDPLiquidation() internal returns(bool _success) {
        uint256 ethFRADebtEquivalent = WrapperInstance.getCollateralEquivalent(collateralType, borrowerFRADebt);
        lender.transfer(ethFRADebtEquivalent);
        borrower.transfer(address(this).balance - ethFRADebtEquivalent);
        return true;
    }
}

/*contract AgreementERC20 is BaseAgreement{
    
    constructor (uint256 _borrowerCollateralValue, uint256 _debtValue, uint256 _expairyDate, uint256 _interestRate, address _tokenAddress) public
    BaseAgreement(_borrowerCollateralValue, _debtValue, _expairyDate, _interestRate) {
        require(ERC20(_tokenAddress).transferFrom);
    }
    ...
}*/
