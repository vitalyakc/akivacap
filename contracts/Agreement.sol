pragma solidity 0.5.11;

import './Claimable.sol';
import './McdWrapper.sol';
import './SafeMath.sol';
import './ERC20Interface.sol';


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

contract BaseAgreement is Claimable, AgreementInterface {
    using SafeMath for uint256;
    
    address constant daiStableCoinAddress = address(0xc7cC3413f169a027dccfeffe5208Ca4f38eF0c40);
    address constant McdWrapperAddress = address(0x36dEb52Eab3B17BccF68f5FD5F5282789640F26E); 
    
    ERC20Interface DaiInstance = ERC20Interface(daiStableCoinAddress);
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
    bytes32 public collateralType;
    uint256 public borrowerFRADebt;
    uint256 public lenderPendingInjection;
    bool public isClosed;
    uint256 public cdpId;
    uint256 public lastCheckTime;
    bool public isApproved;
    
    // test version, should be extended after stable 
    // multicollaterall makerDAO release
    uint256 public dsrTest = 105 * 10 ** 25;
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
        uint256 _debtValue, uint256 _expireDate, uint256 _interestRate, bytes32 _collateralType) 
    public payable 
    {
        require(_debtValue > 0, 'debt cannot be 0');
        require(_interestRate <= ONE, 'interestRate is more than 100 percent');
        
        expireDate = now.add(_expireDate.mul(60));
        
        require(expireDate > now, 'expire date is in the past');

        borrower = _borrower;
        debtValue = _debtValue;
        initialDate = now;
        interestRate = _interestRate + ONE;
        borrowerCollateralValue = _borrowerCollateralValue;
        collateralType = _collateralType;
        
        emit AgreementInitiated(
            _borrower, _borrowerCollateralValue, _debtValue, _expireDate, _interestRate);
    }
    
    function approve() public onlyContractOwner() isNotClosed() returns(bool _success) {
        require(!isApproved, 'Agreement is already approved');
        
        uint256 _cdpId;
        
        bytes memory response = execute(
            McdWrapperAddress, 
            abi.encodeWithSignature(
                'openLockETHAndDraw(bytes32,uint256,uint256)', 
                collateralType, debtValue, borrowerCollateralValue));
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
    
    //should be removed after testing!!!
    function setBorrowerFraDebt(uint256 _borrowerFraDebt) public {
        borrowerFRADebt = _borrowerFraDebt;
    } 
    
    function setdsrTest(uint256 _dsrTest) public {
        dsrTest = _dsrTest;
    }
    //
    
    function() external payable {}
    
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
            currentDifference = ((debtValue.mul(
                (interestRate.sub(currentDSR)))).mul(timeInterval)) / YEAR;
            if(lenderPendingInjection >= currentDifference) {
                lenderPendingInjection = lenderPendingInjection.sub(currentDifference);
            } else {
                borrowerFRADebt = currentDifference.sub(lenderPendingInjection);
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
    
    function _checkExpiringDate() internal view returns(bool _isExpired) {
        return (now > expireDate || isPending() && now > (initialDate + TWENTY_FOUR_HOURS));
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
        uint256 finalDaiLenderBalance;
        
        _refundUsersAfterCDPLiquidation();
        
        bytes memory response = execute(
            McdWrapperAddress, abi.encodeWithSignature('unlockAllDai()'));
        assembly {
            finalDaiLenderBalance := mload(add(response, 0x20))
        }
        
        DaiInstance.transfer(lender, finalDaiLenderBalance);
        execute(
            McdWrapperAddress, 
            abi.encodeWithSignature('transferCdpOwnership(uint256,address)', cdpId, borrower));
        
        isClosed = true;
        return true;
    }
    
    function _closeRejectedAgreement() internal {}
    function _refundUsersAfterCDPLiquidation() internal returns(bool _success) {}
    
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
    constructor (
        address payable _borrower, uint256 _borrowerCollateralValue, 
        uint256 _debtValue, uint256 _expairyDate, uint256 _interestRate, bytes32 _collateralType) 
    public payable
    BaseAgreement(
        _borrower, _borrowerCollateralValue, _debtValue, 
        _expairyDate, _interestRate, _collateralType) 
    {
        require(msg.value == _borrowerCollateralValue, 'Actual ehter value is not correct');
    }
    
    function _closeRejectedAgreement() isNotClosed() internal {
        borrower.transfer(borrowerCollateralValue);
        
        isClosed = true;
    }
    
    function _refundUsersAfterCDPLiquidation() internal returns(bool _success) {
        uint256 collateralFRADebtEquivalent = WrapperInstance.getCollateralEquivalent(
            collateralType, borrowerFRADebt);
            
        lender.transfer(collateralFRADebtEquivalent);
        
        uint256 lenderRefundAmount = address(this).balance;
        borrower.transfer(lenderRefundAmount);
        
        emit AgreementLiquidated(
            collateralFRADebtEquivalent, lenderRefundAmount);
        return true;
    }
}

contract AgreementERC20 is BaseAgreement {
    address erc20ContractAddress;
    ERC20Interface Erc20Instance;
    
    constructor (
        address payable _borrower, uint256 _borrowerCollateralValue, 
        uint256 _debtValue, uint256 _expairyDate, uint256 _interestRate, 
        bytes32 _collateralType, address _erc20ContractAddress) 
    public payable
    BaseAgreement(
        _borrower, _borrowerCollateralValue, _debtValue, 
        _expairyDate, _interestRate, _collateralType) 
    {
        erc20ContractAddress = _erc20ContractAddress;
        Erc20Instance = ERC20Interface(_erc20ContractAddress);
    }
    
    function _closeRejectedAgreement() isNotClosed() internal {
        Erc20Instance.transfer(borrower, borrowerCollateralValue);
        
        isClosed = true;
    }
    
    function _refundUsersAfterCDPLiquidation() internal returns(bool _success) {
        uint256 collateralFRADebtEquivalent = WrapperInstance.getCollateralEquivalent(
            collateralType, borrowerFRADebt);
            
        Erc20Instance.transfer(lender, collateralFRADebtEquivalent);
        
        uint256 lenderRefundAmount = Erc20Instance.balanceOf(address(this));
        Erc20Instance.transfer(borrower, lenderRefundAmount);

        emit AgreementLiquidated(
            collateralFRADebtEquivalent, lenderRefundAmount);
        return true;
    }
}
