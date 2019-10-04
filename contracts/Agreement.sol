pragma solidity 0.5.11;

import './helpers/Claimable.sol';
import './helpers/SafeMath.sol';
import './config/Config.sol';
import './McdWrapper.sol';
import './interfaces/ERC20Interface.sol';

/**
 * @title Base Agreement contract
 * @dev Should not be deployed. It is being used as an abstract class
 */
contract BaseAgreement is AgreementInterface, Claimable, Config, McdWrapper, RaySupport {
    using SafeMath for uint256;
    
    /**
     * in all closed statused the third bit = 1,
     * STATUS_ENDED & STATUS_CLOSED -> true
     * STATUS_LIQUIDATED & STATUS_CLOSED -> true
     * STATUS_CLOSED & STATUS_CLOSED -> true
     */
    uint constant STATUS_PENDING = 0;
    uint constant STATUS_OPEN = 1;
    uint constant STATUS_ACTIVE = 2;
    uint constant STATUS_CLOSED = 4; // 100
    uint constant STATUS_ENDED = 5; // 101
    uint constant STATUS_LIQUIDATED = 6; // 110

    uint status;

    // address constant daiStableCoinAddress = address(0xc7cC3413f169a027dccfeffe5208Ca4f38eF0c40);
    //address constant McdWrapperAddress = address(0x89DCC7caa7E5e33C712C2641254c91676b2c568d);
    
    //ERC20Interface DaiInstance = ERC20Interface(daiStableCoinAddress);
    //McdWrapper WrapperInstance = McdWrapper(McdWrapperAddress);

    uint256 public durationMins;
    uint256 public initialDate;
    uint256 public approveDate;
    uint256 public matchDate;
    uint256 public expireDate;
    
    address payable public borrower;
    address payable public lender;
    uint256 public collateralAmount;
    uint256 public debtValue;
    uint256 public interestRate;
    bytes32 public collateralType;
    
    uint256 public cdpId;
    uint256 public lastCheckTime;

    /**
     * @notice Grants access only to agreement borrower
     */
    modifier onlyBorrrower() {
        require(msg.sender == borrower, 'Accessible only for borrower');
    }

    /**
     * @notice Grants access only if agreement is not closed in any way yet
     */
    modifier onlyNotClosed() {
        require(status < STATUS_CLOSED, 'Agreement should be neither closed nor ended nor liquidated');
        _;
    }

    /**
     * @notice Grants access only if agreement is not matched yet
     */
    modifier onlyBeforeMatched() {
        require(isBeforeMatched(), 'Agreement should be pending or open');
        _;
    }
    
    /**
     * @notice Grants access only if agreement is pending
     */
    modifier onlyPending() {
        require(isPending(), 'Agreement should be pending');
        _;
    }
    
    /**
     * @notice Grants access only if agreement is approved
     */
    modifier onlyOpen() {
        require(isOpen(), 'Agreement should be approved');
        _;
    }

    /**
     * @notice Grants access only if agreement is active
     */
    modifier onlyActive() {
        require(isActive(), 'Agreement should be active');
        _;
    }
    
    
    function initialize(address payable _borrower, uint256 _collateralAmount,uint256 _debtValue, uint256 _durationMins, uint256 _interestRate, bytes32 _collateralType) 
    public payable initializer {
        require(_debtValue > 0, 'debt cannot be 0');
        require(_interestRate <= ONE, 'interestRate is more than 100 percent');
        require(_durationMins > 0);
        
        borrower = _borrower;
        debtValue = _debtValue;
        initialDate = now;
        durationMins = _durationMins;
        interestRate = _interestRate + ONE;
        collateralAmount = _collateralAmount;
        collateralType = _collateralType;

        cdpId = openCdp(collateralType);

        emit AgreementInitiated(
            borrower, collateralAmount, debtValue, durationMins, _interestRate);
    }
    
    /**
     * @notice Approves the agreement. Only for contract owner
     * @return Operation success
     */
    function approveAgreement() public onlyContractOwner() onlyPending() returns(bool _success) {
        //DaiInstance.transfer(borrower, debtValue);
        
        status = STATUS_APPROVED;
        approveDate = now;
        
        emit AgreementApproved(borrower, borrowerCollateralValue, debtValue, expireDate, interestRate);
        
        return true;
    }
    
    /**
     * @notice Connects lender to the agreement.
     * @return Operation success
     */
    function matchAgreement() public onlyOpen() returns(bool _success) {
        lockDai(debtValue);
        // lockEthAndDraw()
        // _lockColateralAndDrawDai()

        matchDate = now;
        status = STATUS_MATCHED;
        expireDate = matchDate.add(durationMins.mul(1 minutes));
        lender = msg.sender;
        lastCheckTime = now;
        
        emit AgreementMatched(msg.sender, matchDate);
        return true;
    }
    
    /**
     * @notice Calls needed function according to the expireDate
     * (terminates or updates the agreement)
     * @dev Executes lots of external calls
     * @return Operation success
     */
     function checkAgreement() public onlyContractOwner() onlyNotClosed() returns(bool _success) {
        if (isPending() && (now > initialDate.add(approveLimitHours.mul(1 hours)))) {
            _closePendingAgreement();
        } else if (isOpen() && (now > approveDate.add(matchLimitHours.mul(1 hours)))) {
            _closeOpenedAgreement();
        } else if (isActive()) {
            _updateAgreementState();
        
            if(WrapperInstance.isCDPLiquidated(collateralType, cdpId)) {
                _liquidateAgreement();
            }
            if(_checkExpiringDate()) {
                _terminateAgreement();
            }
        }
        lastCheckTime = now;
        return true;
    }

    function closeAgreement() public onlyBeforeMatched() onlyBorrower() returns(bool _success)  {
        if (isPending()) {
            return _closePendingAgreement();
        } else if (isOpen()) {
            return _closeOpenedAgreement();
        }
    }
    
    /**
     * @notice Allows borrower to terminate agreement if it has no lender yet
     * @return Operation success
     */
    function _closeOpenedAgreement() public onlyOpen() onlyBorrower() returns(bool _success) {
        transferCdpOwnership(cdpId, msg.sender);
        
        status = STATUS_CLOSED;
        return true;
    }
    
    
    /**
     * @dev check if status is pending
     */
    function isBeforeMatched() public view returns(bool) {
        return (status < STATUS_ACTIVE);
    }
    
    /**
     * @dev check if status is pending
     */
    function isPending() public view returns(bool) {
        return (status == STATUS_PENDING);
    }

    /**
     * @dev check if status is pending
     */
    function isOpen() public view returns(bool) {
        return (status == STATUS_OPEN);
    }

    /**
     * @dev check if status is pending
     */
    function isActive() public view returns(bool) {
        return (status == STATUS_ACTIVE);
    }
    
    /**
     * @dev check if status is pending
     */
    function isEnded() public view returns(bool) {
        return (status == STATUS_ENDED);
    }

    /**
     * @dev check if status is pending
     */
    function isLiquidated() public view returns(bool) {
        return (status == STATUS_LIQUIDATED);
    }

    /**
     * @dev check if status is pending
     */
    function isClosed() public view returns(bool) {
        return (status == STATUS_CLOSED);
    }

    /**
     * @dev check if status is closed or ended or liquidated
     */
    function isAnyClosed() public view returns(bool) {
        return (status >= STATUS_CLOSED);
    }
    
    function() external payable {}

    /**
     * @notice Updates the state of Agreement
     * @return Operation success
     */
    function _updateAgreementState() internal returns(bool _success) {
        uint256 currentDSR = getCurrentDSR(); //WrapperInstance.getDsr();
        uint256 timeInterval = now.sub(lastCheckTime);
        int256 savingsDifference;
        uint256 injectionAmount;

        uint256 lockedDai = unlockAllDai();
        savingsDifference = debtValue.mul(rpow(currentDSR, timeInterval, ONE) - rpow(interestRate, timeInterval, ONE));
        // OR (the same result, but different formula)
        // uint currentDsrAnnual = rpow(currentDSR, 1 years, ONE);
        // savingsDifference = debtValue.mul(currentDsrAnnual.sub(interestRate).mul(timeInterval) / 1 years);
        delta = delta.add(savingsDifference);

        if (fromWad(delta) >= injectionThreshold) {
            injectionAmount = fromWad(delta);

            injectToCdp(cdpId, injectionAmount);

            delta = delta.sub(injectionAmount * ONE);
            lockedDai = lockedDai.sub(injectionAmount);
        }
        lockDai(lockedDai);

        emit AgreementUpdated(injectionAmount, delta, lockedDai);
        return true;
    }

    /**
     * @notice checks whether expireDate has come
     */
    function _checkExpiringDate() internal view returns(bool _isExpired) {
        return (now > expireDate || isPending() && now > (initialDate + TWENTY_FOUR_HOURS));
    }
    
    /**
     * @notice Terminates agreement
     * @return Operation success
     */
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
        status = STATUS_ENDED;
        return true;
    }
    
    /**
     * @notice Liquidates agreement, mostly the sam as terminate 
     * but also covers collateral transfers after liquidation
     * @return Operation success
     */
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
        
        status = STATUS_LIQUIDATED;
        return true;
    }
    
    // solium-disable no-empty-blocks
    function _closePendingAgreement() internal {}
    function _refundUsersAfterCDPLiquidation() internal returns(bool _success) {}
    function _openCdp() internal returns(uint256) {}
    // solium-enable no-empty-blocks

    /**
     * @notice Makes a delegatecall and gives a possibility 
     * to get a returning value
     */
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

/**
 * @title Inherited from BaseAgreement, should be deployed for ETH collateral
 */
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
    
    /**
     * @notice Closes rejected agreement and 
     * transfers collateral ETH back to user
     */
    function _closePendingAgreement() internal isNotClosed() {
        borrower.transfer(borrowerCollateralValue);
        
        status = STATUS_CLOSED;
    }
    
    /**
     * @notice Opens CDP contract in makerDAO system with ETH
     * @return cdpId - id of cdp contract in makerDAO
     */
    function _lockCollateralAndDrawDai() internal returns(uint256) {
        uint256 _cdpId;

        lockETHAndDraw(collateralType, cdpId, collateralAmount, debtValue);

        // solium-disable-next-line indentation
        bytes memory response = execute(McdWrapperAddress, abi.encodeWithSignature(
            'lockETHAndDraw(bytes32,uint256,uint256)', 
            collateralType, debtValue, borrowerCollateralValue));
        assembly {
            _cdpId := mload(add(response, 0x20))
        }
        
        return _cdpId;
    }

    /**
     * @notice Opens CDP contract in makerDAO system with ETH
     * @return cdpId - id of cdp contract in makerDAO
     */
    function _openCdp() internal returns(uint256) {
        uint256 _cdpId;
        
        // solium-disable-next-line indentation
        bytes memory response = execute(McdWrapperAddress, abi.encodeWithSignature(
            'openLockETHAndDraw(bytes32,uint256,uint256)', 
            collateralType, debtValue, borrowerCollateralValue));
        assembly {
            _cdpId := mload(add(response, 0x20))
        }
        
        return _cdpId;
    }
    
    /**
     * @notice Executes all required transfers after liquidation
     * @return Operation success
     */
    function _refundUsersAfterCDPLiquidation() internal returns(bool _success) {
        uint256 collateralFRADebtEquivalent = WrapperInstance.getCollateralEquivalent(
            collateralType, borrowerFRADebt/ONE);
            
        lender.transfer(collateralFRADebtEquivalent);
        
        uint256 borrowerRefundAmount = address(this).balance;
        borrower.transfer(borrowerRefundAmount);
        
        emit AgreementLiquidated(
            collateralFRADebtEquivalent, borrowerRefundAmount);
        return true;
    }
}

/**
 * @title Inherited from BaseAgreement, should be deployed for ERC20 collateral
 */
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
    
    /**
     * @notice Closes rejected agreement and 
     * transfers collateral tokens back to user
     */
    function _closePendingAgreement() internal isNotClosed() {
        Erc20Instance.transfer(borrower, borrowerCollateralValue);
        
        status = STATUS_CLOSED;
    }
    
    /**
     * @notice Opens CDP contract in makerDAO system with ERC20
     * @return cdpId - id of cdp contract in makerDAO
     */
    function _openCdp() internal returns(uint256) {
        uint256 _cdpId;
        
        // solium-disable-next-line indentation
        bytes memory response = execute(McdWrapperAddress, abi.encodeWithSignature(
            'openLockERC20AndDraw(bytes32,uint256,uint256)', 
            collateralType, debtValue, borrowerCollateralValue));
        assembly {
            _cdpId := mload(add(response, 0x20))
        }
        
        return _cdpId;
    }
    
    /**
     * @notice Executes all required transfers after liquidation
     * @return Operation success
     */
    function _refundUsersAfterCDPLiquidation() internal returns(bool _success) {
        uint256 collateralFRADebtEquivalent = WrapperInstance.getCollateralEquivalent(
            collateralType, borrowerFRADebt/ONE);
            
        Erc20Instance.transfer(lender, collateralFRADebtEquivalent);
        
        uint256 borrowerRefundAmount = Erc20Instance.balanceOf(address(this));
        Erc20Instance.transfer(borrower, borrowerRefundAmount);

        emit AgreementLiquidated(
            collateralFRADebtEquivalent, borrowerRefundAmount);
        return true;
    }
}
