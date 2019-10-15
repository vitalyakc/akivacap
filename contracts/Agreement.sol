pragma solidity 0.5.11;

import './helpers/Claimable.sol';
import './helpers/SafeMath.sol';
import './config/Config.sol';
import './McdWrapper.sol';
import './interfaces/ERC20Interface.sol';
import './interfaces/AgreementInterface.sol';

/**
 * @title Base Agreement contract
 * @notice Contract will be deployed only once as logic(implementation), proxy will be deployed for each agreement as storage
 * @dev Should not be deployed. It is being used as an abstract class
 */
contract Agreement is AgreementInterface, Claimable, Config, McdWrapper {
    using SafeMath for uint;
    using SafeMath for int;

    uint status;

    /**
     * @dev set of statuses
     */
    uint constant STATUS_PENDING = 0;
    uint constant STATUS_OPEN = 1;              // 0001
    uint constant STATUS_ACTIVE = 2;            // 0010

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

    bool isETH;

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

    int delta;
    int deltaCommon;

    /**
     * @dev Grants access only to agreement borrower
     */
    modifier onlyBorrower() {
        require(msg.sender == borrower, 'BaseAgreement: Accessible only for borrower');
        _;
    }

    /**
     * @dev Grants access only if agreement is not closed in any way yet
     */
    modifier onlyNotClosed() {
        require(!isClosed(), 'BaseAgreement: Agreement should be neither closed nor ended nor liquidated');
        _;
    }

    /**
     * @dev Grants access only if agreement is not matched yet
     */
    modifier onlyBeforeMatched() {
        require(isBeforeMatched(), 'BaseAgreement: Agreement should be pending or open');
        _;
    }
    
    /**
     * @dev Grants access only if agreement is pending
     */
    modifier onlyPending() {
        require(isPending(), 'BaseAgreement: Agreement should be pending');
        _;
    }
    
    /**
     * @dev Grants access only if agreement is approved
     */
    modifier onlyOpen() {
        require(isOpen(), 'BaseAgreement: Agreement should be approved');
        _;
    }

    function initialize(address payable _borrower, uint256 _collateralAmount,
        uint256 _debtValue, uint256 _durationMins, uint256 _interestRatePercent, bytes32 _collateralType, bool _isETH)
    public payable initializer {
        Ownable.initialize();
        require(_debtValue > 0, 'BaseAgreement: debt is zero');
        require((_interestRatePercent > 0) && (_interestRatePercent <= 100), 'BaseAgreement: interestRate should be between 0 and 100');
        require(_durationMins > 0, 'BaseAgreement: duration is zero');

        if (_isETH) {
            require(msg.value == _collateralAmount, 'Actual ehter value is not correct');
        }

        isETH = _isETH;
        borrower = _borrower;
        debtValue = _debtValue;
        initialDate = getCurrentTime();
        duration = _durationMins.mul(1 minutes);
        interestRate = fromPercentToRay(_interestRatePercent);
        collateralAmount = _collateralAmount;
        collateralType = _collateralType;
        

        _initConfig();
        _initMcdWrapper();
        cdpId = _openCdp(collateralType);

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
        _lockDai(debtValue);
        if (isETH) {
            _lockETHAndDraw(collateralType, cdpId, collateralAmount, debtValue);
        } else {
            _lockERC20AndDraw(collateralType, cdpId, collateralAmount, debtValue, true);
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
     function checkAgreement() public onlyContractOwner() onlyNotClosed() returns(bool _success) {
        if (_checkTimeToCancel()) {
            _cancelAgreement();
        } else if (isActive()) {
            _updateAgreementState();

            // if(isCDPLiquidated(collateralType, cdpId)) {
            //     _liquidateAgreement();
            // }
            if(_checkExpiringDate()) {
                _terminateAgreement();
            }
        }
        lastCheckTime = getCurrentTime();
        return true;
    }

    function cancelAgreement() public onlyBeforeMatched() onlyBorrower() returns(bool _success)  {
        _cancelAgreement();
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
        return ((status & STATUS_CLOSED) == STATUS_CLOSED);
    }

    /**
     * @dev borrower debt according to FRA
     */
    function borrowerFraDebt() public view returns(uint) {
        if (delta < 0) {
            fromRay(-delta);
        } else {
            return 0;
        }
    }

    function getCurrentTime() public view returns(uint) {
        return now;
    }

    /**
     * @dev Closes agreement before it is matched and
     * transfers collateral ETH back to user
     */
    function _cancelAgreement() internal onlyBeforeMatched() {
        if (isETH) {
            _transferERC20(collateralType, borrower, collateralAmount);
        } else {
            borrower.transfer(collateralAmount);
        }
        closeDate = getCurrentTime();
        emit AgreementCanceled(msg.sender);
        status = STATUS_CANCELED;
    }

    /**
     * @dev Updates the state of Agreement
     * @return Operation success
     */
    function _updateAgreementState() internal returns(bool _success) {
        uint timeInterval = getCurrentTime().sub(lastCheckTime);
        uint injectionAmount;
        uint lockedDai = _unlockAllDai();
        uint currentDsrAnnual = rpow(getDsr(), YEAR_SECS, ONE);

        int savingsDifference = (currentDsrAnnual > interestRate) ?
            int(debtValue.mul(currentDsrAnnual.sub(interestRate)).mul(timeInterval) / YEAR_SECS) :
            -int(debtValue.mul(interestRate.sub(currentDsrAnnual)).mul(timeInterval) / YEAR_SECS);
        // OR (the same result, but different formula and interest rate should be in the same format as dsr, e.g. multiplier per second)
        //savingsDifference = debtValue.mul(rpow(currentDSR, timeInterval, ONE) - rpow(interestRate, timeInterval, ONE));
        // require(savingsDifferenceU <= 2**255);

        delta = delta.add(savingsDifference);
        deltaCommon = deltaCommon.add(savingsDifference);

        if (fromRay(delta) >= int(injectionThreshold)) {
            injectionAmount = uint(fromRay(delta));

            _injectToCdp(cdpId, injectionAmount);

            delta = delta.sub(int(toRay(injectionAmount)));
            lockedDai = lockedDai.sub(injectionAmount);
        }
        _lockDai(lockedDai);

        emit AgreementUpdated(injectionAmount, delta, deltaCommon, lockedDai);
        return true;
    }

    /**
     * @dev check whether active agreement period is expired
     */
    function _checkExpiringDate() internal view returns(bool) {
        return getCurrentTime() > expireDate;
    }

    /**
     * @dev check whether pending agreement should be canceled automatically
     */
    function _checkTimeToCancel() internal view returns(bool){
        if ((isPending() && (getCurrentTime() > initialDate.add(approveLimit))) ||
            (isOpen() && (getCurrentTime() > approveDate.add(matchLimit)))) {
            return true;
        }
    }

    /**
     * @dev Terminates agreement
     * @return Operation success
     */
    function _terminateAgreement() internal returns(bool _success) {
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
                    _forceLiquidateCdp(collateralType, cdpId);
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