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
    address constant MCDWrapperMockAddress = address(0x458dAdcE7579057a26bfC78B951058AB12FB8093); 
    
    DaiStableCoinPrototype DaiInstance = DaiStableCoinPrototype(daiStableCoinAddress);
    McdWrapper WrapperInstance = McdWrapper(MCDWrapperMockAddress);

    uint256 constant TWENTY_FOUR_HOURS = 86399;
    uint256 constant ONE = 10 ** 27;
    
    address payable public borrower;
    address payable public lender;
    uint256 public borrowerCollateralValue;
    uint256 public debtValue;
    uint256 public startDate;
    uint256 public initialDate;
    uint256 public expireDate;
    uint256 public interestRate;
    uint256 borrowerFRADebt;
    bool public isClosed;
    uint256 cdpId;
    
    // test version, should be extended after stable multicollaterall makerDAO release
    bytes32 constant collateralType = 0x4554482d41000000000000000000000000000000000000000000000000000000; // ETH-A
    uint256 ethAmountAfterLiquidation;
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
        interestRate = _interestRate;
        borrowerCollateralValue = _borrowerCollateralValue;
        bytes32 response = execute(MCDWrapperMockAddress, abi.encodeWithSignature('openEthaCdp(uint256)', _borrowerCollateralValue));
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
    
    constructor (address payable _borrower, uint256 _borrowerCollateralValue, uint256 _debtValue, uint256 _expairyDate, uint256 _interestRate) public
    BaseAgreement(_borrower, _borrowerCollateralValue, _debtValue, _expairyDate, _interestRate) {}
    
    function matchAgreement() public isActive() returns(bool _success) {
        require(isPending(), 'Agreement has its lender already');
        
        (bool transferSuccess,) = daiStableCoinAddress.call(
            abi.encodeWithSignature('transferFrom(address, address, uint256)', msg.sender, address(this), debtValue));
        require(transferSuccess, 'Impossible to transfer DAI tokens, make valid allowance');
        
        lender = msg.sender;
        startDate = now;
        execute(MCDWrapperMockAddress, abi.encodeWithSignature('lockDai(uint256)', debtValue));

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
        
        return true;
    }
    
    function _checkExpiringDate() internal view returns(bool _isExpired) {
        return (now > expireDate || isPending() && now > (initialDate + TWENTY_FOUR_HOURS));
    }
    
    function _terminateAgreement() internal returns(bool _success) {
        uint256 finalDaiLenderBalance;
        
        if(borrowerFRADebt > 0) {
        (bool TransferSuccessful,) = daiStableCoinAddress
            .call(abi.encodeWithSignature('transferFrom(address, address, uint256)', borrower, address(this), borrowerFRADebt));
            
            if(TransferSuccessful) {
                uint256 unlockedDaiAmount;
                unlockedDaiAmount = WrapperInstance.getLockedDai();
                execute(MCDWrapperMockAddress, abi.encodeWithSignature('unlockDai()'));
                finalDaiLenderBalance = unlockedDaiAmount + borrowerFRADebt;
            } else {
                ethAmountAfterLiquidation = WrapperInstance.forceLiquidate(collateralType, cdpId);
                _refundUsersAfterCDPLiquidation();
            }
        } else {
            finalDaiLenderBalance = WrapperInstance.getLockedDai();
            execute(MCDWrapperMockAddress, abi.encodeWithSignature('unlockDai()'));
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
        uint256 currentDSR = WrapperInstance.getDsr();
        uint256 currentDaiLenderBalance;
        
        currentDaiLenderBalance = WrapperInstance.getLockedDai();
        execute(MCDWrapperMockAddress, abi.encodeWithSignature('unlockDai()'));

        if(currentDSR >= interestRate) {
            
            uint256 currentDifference = debtValue * (currentDSR - interestRate); // to extend with calculation according to decimals
            
            if(currentDifference <= borrowerFRADebt) {
                borrowerFRADebt -= currentDifference;
            } else {
                currentDifference -= borrowerFRADebt;
                borrowerFRADebt = 0;
                execute(MCDWrapperMockAddress, abi.encodeWithSignature('inject(uint256)', currentDifference));
                currentDaiLenderBalance -= currentDifference;
            }
        } else {
            uint256 currentDifference = debtValue * (interestRate - currentDSR); // to extend with calculation according to decimals
            borrowerFRADebt += currentDifference;
        }
        
        WrapperInstance.lockDai(currentDaiLenderBalance);
        
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
