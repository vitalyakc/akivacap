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
    uint constant STATUS_BLOCKED = 11;          // 1011
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
     * @dev Grants access only to agreement's borrower
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
     * @dev Grants access only if agreement is active
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
     * @dev Grants access only if agreement is open (ready to be matched)
     */
    modifier onlyOpen() {
        require(isOpen(), 'Agreement: Agreement should be approved');
        _;
    }

    /**
     * @dev check if agreement is not matched yet
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
     * @dev check if status is open
     */
    function isOpen() public view returns(bool) {
        return (status == STATUS_OPEN);
    }

    /**
     * @dev check if status is active
     */
    function isActive() public view returns(bool) {
        return (status == STATUS_ACTIVE);
    }

    /**
     * @dev check if status is pending
     */
    function isEnded() public view returns(bool) {
        return (status == STATUS_ENDED);
        // return ((status & STATUS_ENDED) == STATUS_ENDED);
    }

    /**
     * @dev check if status is liquidated
     */
    function isLiquidated() public view returns(bool) {
        return (status == STATUS_LIQUIDATED);
    }

    /**
     * @dev check if status is closed
     */
    function isClosed() public view returns(bool) {
        return ((status & STATUS_CLOSED) == STATUS_CLOSED);
    }

    /**
     * @dev Initialize new agreement
     * @param _borrower borrower address
     * @param _collateralAmount value of borrower's collateral amount put into the contract as collateral or approved to transferFrom
     * @param _debtValue value of debt
     * @param _duration number of seconds which agreement should be terminated after
     * @param _interestRate percent of interest rate, should be passed like RAY
     * @param _collateralType type of collateral, should be passed as bytes32
     * @param _isETH true if ether and false if erc-20 token
     */
    function initAgreement(
        address payable _borrower,
        uint256 _collateralAmount,
        uint256 _debtValue,
        uint256 _duration,
        uint256 _interestRate,
        bytes32 _collateralType,
        bool _isETH,
        address configAddr
    ) external payable initializer {
        Ownable.initialize();
        
        require((_collateralAmount > Config(configAddr).minCollateralAmount()) &&
            (_collateralAmount < Config(configAddr).maxCollateralAmount()), 'Agreement: collateral value does not match min and max');
        require(_debtValue > 0, 'Agreement: debt is zero');
        require((_interestRate > ONE) && (_interestRate <= ONE * 2), 'Agreement: interestRate should be between 0 and 100 %');
        require((_duration > Config(configAddr).minDuration()) &&
            (_duration < Config(configAddr).maxDuration()), 'Agreement: duration value does not match min and max');
        require(Config(configAddr).isCollateralEnabled(_collateralType), 'Agreement: collateral type is currencly disabled');

        if (_isETH) {
            require(msg.value == _collateralAmount, 'Agreement: Actual ehter sent value is not correct');
        }
        injectionThreshold = Config(configAddr).injectionThreshold();
        status = STATUS_PENDING;
        isETH = _isETH;
        borrower = _borrower;
        debtValue = _debtValue;
        duration = _duration;
        initialDate = getCurrentTime();
        interestRate = _interestRate;
        collateralAmount = _collateralAmount;
        collateralType = _collateralType;
        
        _initMcdWrapper(collateralType, isETH);

        emit AgreementInitiated(borrower, collateralAmount, debtValue, duration, interestRate);
    }
    
    /**
     * @dev Approves the agreement. Only for contract owner
     * @return Operation success
     */
    function approveAgreement() external onlyContractOwner() onlyPending() returns(bool _success) {
        status = STATUS_OPEN;
        approveDate = getCurrentTime();
        emit AgreementApproved();

        return true;
    }
    
    /**
     * @dev Match lender to the agreement.
     * @return Operation success
     */
    function matchAgreement() external onlyOpen() returns(bool _success) {
        matchDate = getCurrentTime();
        status = STATUS_ACTIVE;
        expireDate = matchDate.add(duration);
        lender = msg.sender;
        lastCheckTime = getCurrentTime();

        // transfer dai from lender to agreement & lock lender's dai to dsr
        _transferFromDai(msg.sender, address(this), debtValue);
        _lockDai(debtValue);

        if (isETH) {
            cdpId = _openLockETHAndDraw(collateralType, collateralAmount, debtValue);
        } else {
            cdpId = _openLockERC20AndDraw(collateralType, collateralAmount, debtValue, true);
        }
        uint drawnDai = _balanceDai(address(this));
        // due to the lack of preceision in mcd cdp contracts drawn dai can be less by 1 dai wei
        if (debtValue < drawnDai) { // !!! check for == debtValue-1
            drawnDai = debtValue;
        }
        _transferDai(borrower, drawnDai);

        emit AgreementMatched(lender, expireDate, cdpId, collateralAmount, debtValue, drawnDai);
        return true;
    }

    /**
     * @dev Update agreement state
     * @notice Calls needed function according to the expireDate
     * (terminates or liquidated or updates the agreement)
     * @return Operation success
     */
     function updateAgreement() external onlyContractOwner() onlyActive() returns(bool _success) {
        if(_checkExpiringDate()) {
            _terminateAgreement();
        } else {
            _updateAgreementState(false);
        }

        // if(isCDPLiquidated(collateralType, cdpId)) {
        //     _liquidateAgreement();
        // }
        return true;
    }

    /**
     * @dev Cancel agreement by borrower before it is matched, change status to the correspondant one, refund
     * @return Operation success
     */
    function cancelAgreement() external onlyBeforeMatched() onlyBorrower() returns(bool _success)  {
        _cancelAgreement();
        return true;
    }

    /**
     * @dev Reject agreement by admin or cron job before it is matched, change status to the correspondant one, refund
     * @return Operation success
     */
    function rejectAgreement() external onlyBeforeMatched() onlyContractOwner() returns(bool _success)  {
        _cancelAgreement();
        return true;
    }

    /**
     * @dev Block active agreement, change status to the correspondant one, refund
     * @return Operation success
     */
    function blockAgreement() external onlyActive() onlyContractOwner() returns(bool _success)  {
        _blockAgreement();
        return true;
    }

    /**
     * @dev Borrower debt according to FRA
     */
    function borrowerFraDebt() public view returns(uint) {
        return (delta < 0) ? uint(fromRay(-delta)) : 0;
    }

    /**
     * @dev Get current time
     */
    function getCurrentTime() public view returns(uint) {
        return now;
    }

    /**
     * @dev Get agreement main info
     */
    function getInfo() external view returns(
        address _addr,
        uint _status,
        uint _duration,
        address _borrower,
        address _lender,
        bytes32 _collateralType,
        uint _collateralAmount,
        uint _debtValue,
        uint _interestRate
    ) {
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
     * @dev check whether pending or open agreement should be canceled automatically by cron
     */
    function checkTimeToCancel(uint _approveLimit, uint _matchLimit) public view returns(bool){
        if ((isPending() && (getCurrentTime() > initialDate.add(_approveLimit))) ||
            (isOpen() && (getCurrentTime() > approveDate.add(_matchLimit)))
        ) {
            return true;
        }
    }

    /**
     * @dev Closes agreement before it is matched and
     * transfers collateral ETH back to user
     */
    function _cancelAgreement() internal {
        closeDate = getCurrentTime();
        status = STATUS_CANCELED;
        if (isETH) {
            borrower.transfer(collateralAmount);
        } else {
            _transferERC20(collateralType, borrower, collateralAmount);
        }
        emit AgreementCanceled(msg.sender);
    }

    /**
     * @dev Updates the state of Agreement
     * @param _isLastUpdate true if the agreement is going to be terminated, false otherwise
     * @return Operation success
     */
    function _updateAgreementState(bool _isLastUpdate) internal returns(bool _success) {
        // if it is last update take the time interval up to expireDate, otherwise up to current time
        uint timeInterval = (_isLastUpdate ? expireDate : getCurrentTime()).sub(lastCheckTime);
        uint injectionAmount;
        uint currentDsrAnnual = rpow(getDsr(), YEAR_SECS, ONE);

        // calculate savings difference between dsr and interest rate during time interval
        int savingsDifference = int(debtValue.mul(timeInterval)).mul((int(currentDsrAnnual)).sub(int(interestRate))) / (int(YEAR_SECS));
        
        delta = delta.add(savingsDifference);
        deltaCommon = deltaCommon.add(savingsDifference);

        lastCheckTime = getCurrentTime();

        if (fromRay(delta) >= int(_isLastUpdate ? 1 : injectionThreshold)) {
            injectionAmount = uint(fromRay(delta));

            uint unlockedDai = _unlockDai(injectionAmount);
            if (unlockedDai < injectionAmount) { // !!! check if = injectionAmount - 1
                injectionAmount = unlockedDai;
            }
            delta = delta.sub(int(toRay(injectionAmount)));
            _injectToCdp(cdpId, injectionAmount);
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
        closeDate = getCurrentTime();
        status = STATUS_ENDED;
        _updateAgreementState(true);
        _refund(false);
        
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

    /**
     * @dev Block agreement
     * @return Operation success
     */
    function _blockAgreement() internal returns(bool _success) {
        status = STATUS_BLOCKED;
        _refund(false);
        
        emit AgreementBlocked();
        return true;
    }

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
        _transferCdpOwnershipToProxy(cdpId, borrower);
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
 * @title Agreement contract with mocked refund after liquidation functionality
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