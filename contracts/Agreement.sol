pragma solidity 0.5.11;

import './Claimable.sol';
import './McdWrapper.sol';
import './DaiInterface.sol';
import './SafeMath.sol';


interface AgreementInterface {
    
    function isClosed() external view returns(bool);
    function approve() external returns(bool);
    function matchAgreement() external returns(bool);
    function checkAgreement() external returns(bool);
    function closePendingAgreement() external returns(bool);
    
    event AgreementInitiated(address _borrower, uint256 _borrowerCollateralValue, 
        uint256 _debtValue, uint256 _expireDate, uint256 _interestRate);
    event AgreementApproved(address _borrower, uint256 _borrowerCollateralValue, 
        uint256 _debtValue, uint256 _expireDate, uint256 _interestRate);
    event AgreementMatched(address _lender, uint256 _startDate, uint256 _lastCheckTime);
    event AgreementUpdated(uint256 _borrowerFRADebt, 
        uint256 _lenderPendingInjection, uint256 _injectedDaiAmount);
    event AgreementTerminated(uint256 _borrowerFraDebtDai, uint256 _finalDaiLenderBalance);
    event AgreementLiquidated(uint256 _lenderEthReward, uint256 _borrowerEthResedual);
}

contract BaseAgreement is Claimable, AgreementInterface{
    using SafeMath for uint256;
    
    address constant daiStableCoinAddress = address(0xc7cC3413f169a027dccfeffe5208Ca4f38eF0c40);
    address constant McdWrapperAddress = address(0x0f08888710B58aFC942843CFC5D12DF86211eD45); 
    
    DaiInterface DaiInstance = DaiInterface(daiStableCoinAddress);
    McdWrapper WrapperInstance = McdWrapper(McdWrapperAddress);

    uint256 constant TWENTY_FOUR_HOURS = 86399;
    uint256 constant YEAR =  31536000;
    uint256 constant ONE = 10 ** 27;
    
    uint256 public injectionThreshold = 2 * ONE;
    
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
    bool public isApproved;
    
    // test version, should be extended after stable 
    // multicollaterall makerDAO release
    bytes32 public collateralType =
    0x4554482d41000000000000000000000000000000000000000000000000000000; // ETH-A
    //
    
    modifier isNotClosed() {
        require(!isClosed, 'Agreement is closed');
        _;
    }
    
    modifier onlyPending() {
        require(isPending(), 'Agreement has its lender already');
        _;
    }
    
    modifier onlyApproved() {
        require(isApproved, 'Agreement is not approved');
        _;
    }
    
    constructor(address payable _borrower, uint256 _borrowerCollateralValue, 
        uint256 _debtValue, uint256 _expireDate, uint256 _interestRate) 
    public payable 
    {
        require(msg.value == _borrowerCollateralValue, 'Actual ehter value is not correct');
        require(_debtValue > 0, 'debt cannot be 0');
        require(_interestRate <= ONE, 'interestRate is more than 100 percent');
        
        expireDate = now.add(_expireDate.mul(60));
        
        require(expireDate > now, 'expire date is in the past');

        borrower = _borrower;
        debtValue = _debtValue;
        initialDate = now;
        interestRate = _interestRate + ONE;
        borrowerCollateralValue = _borrowerCollateralValue;
        
        emit AgreementInitiated(
            _borrower, _borrowerCollateralValue, _debtValue, _expireDate, _interestRate);
    }
    
    function approve() public onlyContractOwner() isNotClosed() returns(bool _success) {
        require(!isApproved, 'Agreement is already approved');
        
        uint256 _cdpId;
        
        bytes memory response = execute(
            McdWrapperAddress, 
            abi.encodeWithSignature('openEthaCdpNonPayable(uint256,uint256)', borrowerCollateralValue, debtValue));
        assembly {
            _cdpId := mload(add(response, 0x20))
        }
        cdpId = _cdpId;
        
        DaiInstance.transfer(borrower, debtValue);
        
        isApproved = true;
        
        emit AgreementApproved(
            borrower, borrowerCollateralValue, debtValue, expireDate, interestRate);
        
        return true;
    }
    
    function closePendingAgreement() public isNotClosed() onlyPending() onlyApproved() returns(bool _success) {
        require(msg.sender == borrower, 'Accessible only for borrower');
        
        execute(
            McdWrapperAddress, 
            abi.encodeWithSignature('transferCdpOwnership(uint256,address)', cdpId, msg.sender));
        
        isClosed = true;
        
        return true;
    }
    
    function isPending() public view returns(bool) {
        return (lender == address(0));
    }
    
    function() external payable {}
    
    function execute(address _target, bytes memory _data)
        public
        payable
        returns (bytes memory response)
    {
        require(_target != address(0), 'ds-proxy-target-address-required');

        // call contract in current context
        assembly {
            let succeeded := delegatecall(sub(gas, 5000), _target, add(_data, 0x20), mload(_data), 0, 0)
            let size := returndatasize

            response := mload(0x40)
            mstore(0x40, add(response, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            switch iszero(succeeded)
            case 1 {
                // throw if delegatecall failed
                revert(add(response, 0x20), size)
            }
        }
    }
}

contract AgreementETH is BaseAgreement {
    
    uint256 public dsrTest = 105 * 10 ** 25;
    
    constructor (
        address payable _borrower, uint256 _borrowerCollateralValue, 
        uint256 _debtValue, uint256 _expairyDate, uint256 _interestRate) 
    public payable
    BaseAgreement(_borrower, _borrowerCollateralValue, _debtValue, _expairyDate, _interestRate) {}
    
    function setdsrTest(uint256 _dsrTest) public {
        dsrTest = _dsrTest;
    }
    
    function matchAgreement() public isNotClosed() onlyPending() onlyApproved() returns(bool _success) {
        (bool transferSuccess,) = daiStableCoinAddress.call(
            abi.encodeWithSignature(
            'transferFrom(address,address,uint256)', msg.sender, address(this), debtValue));
        require(transferSuccess, 'Impossible to transfer DAI tokens, make valid allowance');
        
        lender = msg.sender;
        startDate = now;
        execute(McdWrapperAddress, abi.encodeWithSignature('lockDai(uint256)', debtValue));

        lastCheckTime = now;
        
        emit AgreementMatched(msg.sender, now, now);
        return true;
    }
    
    // is supposed to be called in loop externaly
    function checkAgreement() public onlyContractOwner() isNotClosed() returns(bool _success) { 
        if(!isApproved && now > initialDate + TWENTY_FOUR_HOURS) {
            _closeRejectedAgreement();
        } else {
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
        }
        
        return true;
    }
    
    function _checkExpiringDate() internal view returns(bool _isExpired) {
        return (now > expireDate || isPending() && now > (initialDate + TWENTY_FOUR_HOURS));
    }
    
    function _closeRejectedAgreement() internal {
        borrower.transfer(borrowerCollateralValue);
        
        isClosed = true;
    }
    
    function _terminateAgreement() internal returns(bool _success) {
        
        uint256 borrowerFraDebtDai = borrowerFRADebt/ONE;
        uint256 finalDaiLenderBalance;
        
        bytes memory response = execute(
            McdWrapperAddress, abi.encodeWithSignature('unlockAllDai()'));
        assembly {
            finalDaiLenderBalance := mload(add(response, 0x20))
        }
        if(borrowerFraDebtDai > 0) {
            (bool TransferSuccessful,) = daiStableCoinAddress.call(abi.encodeWithSignature(
                'transferFrom(address,address,uint256)', borrower, address(this), borrowerFraDebtDai));
            
            if(TransferSuccessful) {
                finalDaiLenderBalance = finalDaiLenderBalance.add(borrowerFraDebtDai);
                
                emit AgreementTerminated(borrowerFraDebtDai, finalDaiLenderBalance);
            } else {
                WrapperInstance.forceLiquidate(collateralType, cdpId);
                _refundUsersAfterCDPLiquidation();
            }
        }
        
        DaiInstance.transfer(lender, finalDaiLenderBalance);
        execute(
            McdWrapperAddress, 
            abi.encodeWithSignature('transferCdpOwnership(uint256,address)', cdpId, borrower));
        
        isClosed = true;
        return true;
    }
    
    function _liquidateAgreement() internal returns(bool _success) {
        if(borrowerFRADebt > 0) {
            _refundUsersAfterCDPLiquidation();
        } else {
            borrower.transfer(address(this).balance);
        }
        
        execute(McdWrapperAddress, abi.encodeWithSignature('unlockDai()'));
        
        DaiInstance.transfer(lender, WrapperInstance.getLockedDai());
        WrapperInstance.transferCdpOwnership(cdpId, borrower);
        
        isClosed = true;
        return true;
    }
    
    function _updateCurrentStateOrMakeInjection() internal returns(bool _success) { 
        uint256 currentDSR = dsrTest; //WrapperInstance.getDsr();
        uint256 currentDaiLenderBalance;
        uint256 timeInterval = now.sub(lastCheckTime);
        uint256 currentDifference;
        uint256 lenderPendingInjectionDai;
        
        bytes memory response = execute(
            McdWrapperAddress, abi.encodeWithSignature('unlockAllDai()'));
        assembly {
            currentDaiLenderBalance := mload(add(response, 0x20))
        }
        
        if(currentDSR >= interestRate) {
            
            //rad, 45
            currentDifference = ((debtValue.mul(
                (currentDSR.sub(interestRate)))).mul(timeInterval)) / YEAR; 
            
            if(currentDifference <= borrowerFRADebt) {
                //rad, 45
                borrowerFRADebt = borrowerFRADebt.sub(currentDifference);
            } else {
                currentDifference = currentDifference.sub(borrowerFRADebt);
                borrowerFRADebt = 0;
                //rad, 45
                lenderPendingInjection = lenderPendingInjection.add(currentDifference);
                if(lenderPendingInjection >= injectionThreshold) {
                    //wad, 18
                    lenderPendingInjectionDai = lenderPendingInjection/ONE;
                    execute(
                        McdWrapperAddress, 
                        abi.encodeWithSignature(
                        'injectToCdp(uint256,uint256)', cdpId, lenderPendingInjectionDai));
                    //wad, 18
                    lenderPendingInjection = lenderPendingInjection.sub(lenderPendingInjectionDai * ONE);
                    currentDaiLenderBalance = currentDaiLenderBalance.sub(lenderPendingInjectionDai);
                } 
            }
        } else {
            currentDifference = debtValue.mul(interestRate.sub(currentDSR)).mul(timeInterval) / YEAR;
            if(lenderPendingInjection >= currentDifference) {
                lenderPendingInjection = lenderPendingInjection.sub(currentDifference);
            } else {
                borrowerFRADebt = borrowerFRADebt.add(currentDifference.sub(lenderPendingInjection));
                lenderPendingInjection = 0;
            }
        }
        
        execute(
            McdWrapperAddress, 
            abi.encodeWithSignature(
            'lockDai(uint256)', currentDaiLenderBalance));
        
        emit AgreementUpdated(borrowerFRADebt, lenderPendingInjection, lenderPendingInjectionDai);
        return true;
    }
    
    function _refundUsersAfterCDPLiquidation() internal returns(bool _success) {
        uint256 ethFRADebtEquivalent = WrapperInstance.getCollateralEquivalent(
            collateralType, borrowerFRADebt / ONE);
        lender.transfer(ethFRADebtEquivalent);
        borrower.transfer(address(this).balance);
        
        emit AgreementLiquidated(
            ethFRADebtEquivalent, address(this).balance.sub(ethFRADebtEquivalent));
        return true;
    }
    
    //should be removed after testing!!!
    function setBorrowerFraDebt(uint256 _borrowerFraDebt) public {
        borrowerFRADebt = _borrowerFraDebt;
    }
}

/*contract AgreementERC20 is BaseAgreement{
    
    constructor (uint256 _borrowerCollateralValue, uint256 _debtValue, uint256 _expairyDate, uint256 _interestRate, address _tokenAddress) public
    BaseAgreement(_borrowerCollateralValue, _debtValue, _expairyDate, _interestRate) {
        require(ERC20(_tokenAddress).transferFrom);
    }
    ...
}*/
