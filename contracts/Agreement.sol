pragma solidity 0.5.11;

import './config/Config.sol';
import './helpers/Claimable.sol';
import './helpers/SafeMath.sol';
import './mcd/McdWrapper.sol';
import './interfaces/ERC20Interface.sol';
import './interfaces/AgreementInterface.sol';

/**
 * @title Base Agreement contract
 * @notice Contract will be deployed only once as logic(implementation), proxy will be deployed for each agreement as storage
 * @dev Should not be deployed. It is being used as an abstract class
 */
contract Agreement is AgreementInterface, Claimable, McdWrapper {
    using SafeMath for uint;
    using SafeMath for int;
    uint constant YEAR_SECS = 365 days;

    uint public status;

    /**
     * @dev set of statuses
     */
    uint constant STATUS_PENDING = 1;           // 0001
    uint constant STATUS_OPEN = 2;              // 0010   
    uint constant STATUS_ACTIVE = 3;            // 0011

    /**
     * in all closed statused the forth bit = 1, binary "AND" will equal:
     * STATUS_ENDED & STATUS_CLOSED -> STATUS_CLOSED
     * STATUS_LIQUIDATED & STATUS_CLOSED -> STATUS_CLOSED
     * STATUS_CANCELED & STATUS_CLOSED -> STATUS_CLOSED
     */
    uint constant STATUS_CLOSED = 8;            // 1000
    uint constant STATUS_ENDED = 9;             // 1001
    uint constant STATUS_LIQUIDATED = 10;       // 1010
    uint constant STATUS_ENDED_LIQUIDATED = 11; // 1011
    uint constant STATUS_CANCELED = 12;         // 1100
    
    bool public isETH;

    uint256 public duration;
    uint256 public initialDate;
    uint256 public approveDate;
    uint256 public matchDate;
    uint256 public expireDate;
    uint256 public closeDate;

    address payable public borrower;
    address payable public lender;
    bytes32 public collateralType;
    uint256 public collateralAmount;
    uint256 public debtValue;
    uint256 public interestRate;

    uint256 public cdpId;
    uint256 public lastCheckTime;

    int public delta;
    int public deltaCommon;

    uint public injectionThreshold;

    /**
     * @dev Grants access only to agreement borrower
     */
    modifier onlyBorrower() {
        require(msg.sender == borrower, 'Agreement: Accessible only for borrower');
        _;
    }

    /**
     * @dev Grants access only if agreement is not closed in any way yet
     */
    modifier onlyNotClosed() {
        require(!isClosed(), 'Agreement: Agreement should be neither closed nor ended nor liquidated');
        _;
    }

    /**
     * @dev Grants access only if agreement is not matched yet
     */
    modifier onlyBeforeMatched() {
        require(isBeforeMatched(), 'Agreement: Agreement should be pending or open');
        _;
    }
    
    /**
     * @dev Grants access only if agreement is pending
     */
    modifier onlyActive() {
        require(isActive(), 'Agreement: Agreement should be active');
        _;
    }

    /**
     * @dev Grants access only if agreement is pending
     */
    modifier onlyPending() {
        require(isPending(), 'Agreement: Agreement should be pending');
        _;
    }
    
    /**
     * @dev Grants access only if agreement is approved
     */
    modifier onlyOpen() {
        require(isOpen(), 'Agreement: Agreement should be approved');
        _;
    }

    function initAgreement(
        address payable _borrower,
        uint256 _collateralAmount,
        uint256 _debtValue,
        uint256 _duration,
        uint256 _interestRate,
        bytes32 _collateralType,
        bool _isETH,
        address configAddr
    ) public payable initializer {
        Ownable.initialize();
        
        require((_collateralAmount > Config(configAddr).minCollateralAmount()) && (_collateralAmount < Config(configAddr).maxCollateralAmount()), 'Agreement: collateral value does not match min and max');
        require(_debtValue > 0, 'Agreement: debt is zero');
        require((_interestRate > ONE) && (_interestRate <= ONE * 2), 'Agreement: interestRate should be between 0 and 100 %');
        require((_duration > Config(configAddr).minDuration()) && (_duration < Config(configAddr).maxDuration()), 'Agreement: duration is zero');
        require(Config(configAddr).isCollateralEnabled(_collateralType), 'Agreement: collateral type is currencly disabled');

        if (_isETH) {   
            require(msg.value == _collateralAmount, 'Actual ehter value is not correct');
        }
        injectionThreshold = Config(configAddr).injectionThreshold();
        status = STATUS_PENDING;
        isETH = _isETH;
        borrower = _borrower;
        debtValue = _debtValue;
        duration = _duration;
        initialDate = getCurrentTime();
        interestRate = _interestRate; //fromPercentToRay(_interestRatePercent);
        collateralAmount = _collateralAmount;
        collateralType = _collateralType;
        
        _initMcdWrapper(collateralType, isETH);

        emit AgreementInitiated(borrower, collateralAmount, debtValue, duration, interestRate);
    }
    
    /**
     * @dev Approves the agreement. Only for contract owner
     * @return Operation success
     */
    function approveAgreement() public onlyContractOwner() onlyPending() returns(bool _success) {
        status = STATUS_OPEN;
        approveDate = getCurrentTime();
        emit AgreementApproved();

        return true;
    }
    
    /**
     * @dev Connects lender to the agreement.
     * @return Operation success
     */
    function matchAgreement() public onlyOpen() returns(bool _success) {
        // transfer dai from borrower to agreement
        _transferFromDai(msg.sender, address(this), debtValue);
        _lockDai(debtValue);
        if (isETH) {
            cdpId = _openLockETHAndDraw(collateralType, collateralAmount, debtValue);
        } else {
            cdpId = _openLockERC20AndDraw(collateralType, collateralAmount, debtValue, true);
        }
        _transferDai(borrower, debtValue);
        
        matchDate = getCurrentTime();
        status = STATUS_ACTIVE;
        expireDate = matchDate.add(duration);
        lender = msg.sender;
        lastCheckTime = getCurrentTime();
        
        emit AgreementMatched(lender);
        return true;
    }

    /**
     * @dev check for close
     * @notice Calls needed function according to the expireDate
     * (terminates or updates the agreement)
     * @return Operation success
     */
     function updateAgreement() public onlyContractOwner() onlyActive() returns(bool _success) {
        if(_checkExpiringDate()) {
            _terminateAgreement();
        } else {
            _updateAgreementState(false);
        }

        // if(isCDPLiquidated(collateralType, cdpId)) {
        //     _liquidateAgreement();
        // }
        
        lastCheckTime = getCurrentTime();
        return true;
    }

    function cancelAgreement() public onlyBeforeMatched() onlyBorrower() returns(bool _success)  {
        _cancelAgreement();
        return true;
    }

    function rejectAgreement() public onlyBeforeMatched() onlyContractOwner() returns(bool _success)  {
        _cancelAgreement();
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
        // return (status == STATUS_ENDED);
        return ((status & STATUS_ENDED) == STATUS_ENDED);
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
        return ((status & STATUS_CLOSED) == STATUS_CLOSED);
    }

    /**
     * @dev borrower debt according to FRA
     */
    function borrowerFraDebt() public view returns(uint) {
        if (delta < 0) {
            return uint(fromRay(-delta));
        } else {
            return 0;
        }
    }

    function getCurrentTime() public view returns(uint) {
        return now;
    }

    function getInfo() public view returns(address _addr, uint _status, uint _duration, address _borrower, address _lender, bytes32 _collateralType, uint _collateralAmount, uint _debtValue, uint _interestRate) {
        _addr = address(this);
        _status = status;
        _duration = duration;
        _borrower = borrower;
        _lender = lender;
        _collateralType = collateralType;
        _collateralAmount = collateralAmount;
        _debtValue = debtValue;
        _interestRate = interestRate;
    }

    /**
     * @dev check whether pending agreement should be canceled automatically
     */
    function checkTimeToCancel(uint _approveLimit, uint _matchLimit) public view returns(bool){
        if (
            //(isPending() && (getCurrentTime() > initialDate.add(_approveLimit))) ||
            (isOpen() && (getCurrentTime() > approveDate.add(_matchLimit)))) {
            return true;
        }
    }

    /**
     * @dev Closes agreement before it is matched and
     * transfers collateral ETH back to user
     */
    function _cancelAgreement() internal {
        if (isETH) {
            borrower.transfer(collateralAmount);
        } else {
            _transferERC20(collateralType, borrower, collateralAmount);
        }
        closeDate = getCurrentTime();
        emit AgreementCanceled(msg.sender);
        status = STATUS_CANCELED;
    }

    /**
     * @dev Updates the state of Agreement
     * @return Operation success
     */
    function _updateAgreementState(bool _isLastUpdate) internal returns(bool _success) {
        uint timeInterval = getCurrentTime().sub(lastCheckTime);
        uint injectionAmount;
        uint unlockedDai;
        uint currentDsrAnnual = rpow(getDsr(), YEAR_SECS, ONE);

        int savingsDifference = (currentDsrAnnual > interestRate) ?
            int(debtValue.mul(currentDsrAnnual.sub(interestRate)).mul(timeInterval) / YEAR_SECS) :
            -int(debtValue.mul(interestRate.sub(currentDsrAnnual)).mul(timeInterval) / YEAR_SECS);
        // OR (the same result, but different formula and interest rate should be in the same format as dsr, e.g. multiplier per second)
        //savingsDifference = debtValue.mul(rpow(currentDSR, timeInterval, ONE) - rpow(interestRate, timeInterval, ONE));
        // require(savingsDifferenceU <= 2**255);
        
        delta = delta.add(savingsDifference);
        deltaCommon = deltaCommon.add(savingsDifference);
        
        if (_isLastUpdate) {
            injectionThreshold = 1;
        }

        if (fromRay(delta) >= int(injectionThreshold)) {
            injectionAmount = uint(fromRay(delta));

            _unlockDai(injectionAmount);
            unlockedDai = _balanceDai(address(this));
            if (unlockedDai < injectionAmount) {
                injectionAmount = unlockedDai;
            }
            _injectToCdp(cdpId, injectionAmount);

            delta = delta.sub(int(toRay(injectionAmount)));
        }
        emit AgreementUpdated(injectionAmount, delta, deltaCommon, savingsDifference, currentDsrAnnual, timeInterval);
        return true;
    }

    /**
     * @dev check whether active agreement period is expired
     */
    function _checkExpiringDate() internal view returns(bool) {
        return getCurrentTime() > expireDate;
    }

    /**
     * @dev Terminates agreement
     * @return Operation success
     */
    function _terminateAgreement() internal returns(bool _success) {
        _updateAgreementState(true);
        _refund(false);
        closeDate = getCurrentTime();
        status = STATUS_ENDED;

        emit AgreementTerminated();
        return true;
    }

    // /**
    //  * @dev Liquidates agreement, mostly the sam as terminate
    //  * but also covers collateral transfers after liquidation
    //  * @return Operation success
    //  */
    // function _liquidateAgreement() internal returns(bool _success) {
    //     _refund(true);
    //     closeDate = getCurrentTime();
    //     status = STATUS_LIQUIDATED;

    //     emit AgreementLiquidated();
    //     return true;
    // }

    function _refund(bool _isCdpLiquidated) internal {
        uint lenderRefundDai = _unlockAllDai();
        uint borrowerFraDebtDai = borrowerFraDebt();
        
        if (borrowerFraDebtDai > 0) {
            if (_isCdpLiquidated) {
                _refundAfterCdpLiquidation(borrowerFraDebtDai);
            } else {
                if (_callTransferFromDai(borrower, address(this), borrowerFraDebtDai)) {
                    lenderRefundDai = lenderRefundDai.add(borrowerFraDebtDai);
                } else {
                    _freeETH(collateralType, cdpId);
                    _refundAfterCdpLiquidation(borrowerFraDebtDai);
                }
            }
        }
        _transferDai(lender, lenderRefundDai);
        _transferCdpOwnership(cdpId, borrower);
        emit RefundBase(lender, lenderRefundDai, borrower, cdpId);
    }

    /**
     * @dev Executes all required transfers after liquidation
     * @return Operation success
     */
    function _refundAfterCdpLiquidation(uint _borrowerFraDebtDai) internal returns(bool _success) {
        uint256 lenderRefundCollateral = getCollateralEquivalent(collateralType, _borrowerFraDebtDai);
        uint borrowerRefundCollateral;
        if (isETH) {
            lender.transfer(lenderRefundCollateral);
            borrowerRefundCollateral = address(this).balance;
            borrower.transfer(borrowerRefundCollateral);
        } else {
            _transferERC20(collateralType, lender, lenderRefundCollateral);
            borrowerRefundCollateral = erc20TokenContract(collateralType).balanceOf(address(this));
            _transferERC20(collateralType, borrower, borrowerRefundCollateral);
        }
        emit RefundLiquidated(_borrowerFraDebtDai, lenderRefundCollateral, borrowerRefundCollateral);
        return true;
    }

    function() external payable {}
}

/**
 * @title Base Agreement contract
 * @notice Contract will be deployed only once as logic(implementation), proxy will be deployed for each agreement as storage
 * @dev Should not be deployed. It is being used as an abstract class
 */
contract AgreementLiquidationMock is Agreement {
    /**
     * @dev Executes all required transfers after liquidation
     * @return Operation success
     */
    function _refundAfterCdpLiquidation(uint _borrowerFraDebtDai) internal returns(bool _success) {
    }

    /**
     * @dev recovers remaining ETH from cdp (pays remaining debt if exists)
     * @param ilk     collateral type in bytes32 format
     * @param cdp cdp ID
     */
    function _freeETH(bytes32 ilk, uint cdp) internal {
    }
}