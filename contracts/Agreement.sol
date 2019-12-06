pragma solidity 0.5.11;

import "./config/Config.sol";
import "./helpers/Claimable.sol";
import "./helpers/SafeMath.sol";
import "./mcd/McdWrapper.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IAgreement.sol";

/**
 * @title Base Agreement contract
 * @notice Contract will be deployed only once as logic(implementation), proxy will be deployed for each agreement as storage
 * @dev Should not be deployed. It is being used as an abstract class
 */
contract Agreement is IAgreement, Claimable, McdWrapper {
    using SafeMath for uint;
    using SafeMath for int;
    uint constant internal YEAR_SECS = 365 days;

    uint public status;

    /**
     * @dev set of statuses
     */
    uint constant internal STATUS_PENDING = 1;           // 0001
    uint constant internal STATUS_OPEN = 2;              // 0010
    uint constant internal STATUS_ACTIVE = 3;            // 0011

    /**
     * @dev in all closed statused the forth bit = 1, binary "AND" will equal:
     * STATUS_ENDED & STATUS_CLOSED -> STATUS_CLOSED
     * STATUS_LIQUIDATED & STATUS_CLOSED -> STATUS_CLOSED
     * STATUS_CANCELED & STATUS_CLOSED -> STATUS_CLOSED
     */
    uint constant internal STATUS_CLOSED = 8;            // 1000
    uint constant internal STATUS_ENDED = 9;             // 1001
    uint constant internal STATUS_LIQUIDATED = 10;       // 1010
    uint constant internal STATUS_BLOCKED = 11;          // 1011
    uint constant internal STATUS_CANCELED = 12;         // 1100
    
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
     * @notice Grants access only to agreement's borrower
     */
    modifier onlyBorrower() {
        require(msg.sender == borrower, "Agreement: Accessible only for borrower");
        _;
    }

    /**
     * @notice Grants access only if agreement is not closed in any way yet
     */
    modifier onlyNotClosed() {
        require(!isClosed(), "Agreement: Agreement should be neither closed nor ended nor liquidated");
        _;
    }

    /**
     * @notice Grants access only if agreement is closed in any way
     */
    modifier onlyClosed() {
        require(isClosed(), "Agreement: Agreement should be closed or ended or liquidated or blocked");
        _;
    }

    /**
     * @notice Grants access only if agreement is not matched yet
     */
    modifier onlyBeforeMatched() {
        require(isBeforeMatched(), "Agreement: Agreement should be pending or open");
        _;
    }
    
    /**
     * @notice Grants access only if agreement is active
     */
    modifier onlyActive() {
        require(isActive(), "Agreement: Agreement should be active");
        _;
    }

    /**
     * @notice Grants access only if agreement is pending
     */
    modifier onlyPending() {
        require(isPending(), "Agreement: Agreement should be pending");
        _;
    }
    
    /**
     * @notice Grants access only if agreement is open (ready to be matched)
     */
    modifier onlyOpen() {
        require(isOpen(), "Agreement: Agreement should be approved");
        _;
    }

    /**
     * @notice Initialize new agreement
     * @param _borrower borrower address
     * @param _collateralAmount value of borrower's collateral amount put into the contract as collateral or approved to transferFrom
     * @param _debtValue value of debt
     * @param _duration number of seconds which agreement should be terminated after
     * @param _interestRate percent of interest rate, should be passed like RAY
     * @param _collateralType type of collateral, should be passed as bytes32
     * @param _isETH true if ether and false if erc-20 token
     * @param _configAddr config contract address
     */
    function initAgreement(
        address payable _borrower,
        uint256 _collateralAmount,
        uint256 _debtValue,
        uint256 _duration,
        uint256 _interestRate,
        bytes32 _collateralType,
        bool _isETH,
        address _configAddr
    ) public payable initializer     {
        Ownable.initialize();

        require(Config(_configAddr).isCollateralEnabled(_collateralType), "Agreement: collateral type is currencly disabled");
        require(_debtValue > 0, "Agreement: debt is zero");
        require((_collateralAmount > Config(_configAddr).minCollateralAmount()) &&
            (_collateralAmount < Config(_configAddr).maxCollateralAmount()), "Agreement: collateral value does not match min and max");
        require((_interestRate > ONE) && 
            (_interestRate <= ONE * 2), "Agreement: interestRate should be between 0 and 100 %");
        require((_duration > Config(_configAddr).minDuration()) &&
            (_duration < Config(_configAddr).maxDuration()), "Agreement: duration value does not match min and max");
        if (_isETH) {
            require(msg.value == _collateralAmount, "Agreement: Actual ehter sent value is not correct");
        }
        injectionThreshold = Config(_configAddr).injectionThreshold();
        status = STATUS_PENDING;
        isETH = _isETH;
        borrower = _borrower;
        debtValue = _debtValue;
        duration = _duration;
        initialDate = now;
        interestRate = _interestRate;
        collateralAmount = _collateralAmount;
        collateralType = _collateralType;
        
        _initMcdWrapper(collateralType, isETH);

        emit AgreementInitiated(borrower, collateralAmount, debtValue, duration, interestRate);
    }
    
    /**
     * @notice Approve the agreement. Only for contract owner (FraFactory)
     * @return Operation success
     */
    function approveAgreement() external onlyContractOwner onlyPending returns(bool _success) {
        status = STATUS_OPEN;
        approveDate = now;
        emit AgreementApproved();

        return true;
    }
    
    /**
     * @notice Match lender to the agreement.
     * @return Operation success
     */
    function matchAgreement() external onlyOpen returns(bool _success) {
        matchDate = now;
        status = STATUS_ACTIVE;
        expireDate = matchDate.add(duration);
        lender = msg.sender;
        lastCheckTime = now;

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
     * @notice Update agreement state
     * @dev Calls needed function according to the expireDate
     * (terminates or liquidated or updates the agreement)
     * @return Operation success
     */
    function updateAgreement() external onlyContractOwner onlyActive returns(bool _success) {
        if(isCDPUnsafe(collateralType, cdpId)) {
            _liquidateAgreement();
        } else {
            if(now > expireDate) {
                _terminateAgreement();
            } else {
                _updateAgreementState(false);
            }
        }
        return true;
    }

    /**
     * @notice Cancel agreement by borrower before it is matched, change status to the correspondant one, refund
     * @return Operation success
     */
    function cancelAgreement() external onlyBeforeMatched onlyBorrower returns(bool _success)  {
        _cancelAgreement();
        return true;
    }

    /**
     * @notice Reject agreement by admin or cron job before it is matched, change status to the correspondant one, refund
     * @return Operation success
     */
    function rejectAgreement() external onlyBeforeMatched onlyContractOwner returns(bool _success)  {
        _cancelAgreement();
        return true;
    }

    /**
     * @notice Block active agreement, change status to the correspondant one, refund
     * @return Operation success
     */
    function blockAgreement() external onlyActive onlyContractOwner returns(bool _success)  {
        _blockAgreement();
        return true;
    }

    /**
     * @notice Withdraw accidentally locked ether in the contract, can be called only after agreement is closed and all assets are refunded
     * @return Operation success
     */
    function withdrawEth(address payable _to) external onlyClosed onlyContractOwner {
        _to.transfer(address(this).balance);
    }

    /**
     * @notice Get agreement main info
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
     * @notice check if agreement is not matched yet
     */
    function isBeforeMatched() public view returns(bool) {
        return (status < STATUS_ACTIVE);
    }

    /**
     * @notice check if status is pending
     */
    function isPending() public view returns(bool) {
        return (status == STATUS_PENDING);
    }

    /**
     * @notice check if status is open
     */
    function isOpen() public view returns(bool) {
        return (status == STATUS_OPEN);
    }

    /**
     * @notice check if status is active
     */
    function isActive() public view returns(bool) {
        return (status == STATUS_ACTIVE);
    }

    /**
     * @notice check if status is pending
     */
    function isEnded() public view returns(bool) {
        return (status == STATUS_ENDED);
    }

    /**
     * @notice check if status is liquidated
     */
    function isLiquidated() public view returns(bool) {
        return (status == STATUS_LIQUIDATED);
    }

    /**
     * @notice check if status is closed
     */
    function isClosed() public view returns(bool) {
        return ((status & STATUS_CLOSED) == STATUS_CLOSED);
    }

    /**
     * @notice Borrower debt according to FRA
     */
    function borrowerFraDebt() public view returns(uint) {
        return (delta < 0) ? uint(fromRay(-delta)) : 0;
    }

    /**
     * @notice check whether pending or open agreement should be canceled automatically by cron
     */
    function checkTimeToCancel(uint _approveLimit, uint _matchLimit) public view returns(bool){
        if ((isPending() && (now > initialDate.add(_approveLimit))) ||
            (isOpen() && (now > approveDate.add(_matchLimit)))
        ) {
            return true;
        }
    }

    /**
     * @notice Closes agreement before it is matched and
     * transfers collateral ETH back to user
     */
    function _cancelAgreement() internal {
        closeDate = now;
        status = STATUS_CANCELED;
        if (isETH) {
            borrower.transfer(collateralAmount);
        } else {
            _transferERC20(collateralType, borrower, collateralAmount);
        }
        emit AgreementCanceled(msg.sender);
    }

    /**
     * @notice Updates the state of Agreement
     * @param _isLastUpdate true if the agreement is going to be terminated, false otherwise
     * @return Operation success
     */
    function _updateAgreementState(bool _isLastUpdate) internal returns(bool _success) {
        // if it is last update take the time interval up to expireDate, otherwise up to current time
        uint timeInterval = (_isLastUpdate ? expireDate : now).sub(lastCheckTime);
        uint injectionAmount;
        uint currentDsrAnnual = rpow(getDsr(), YEAR_SECS, ONE);

        // calculate savings difference between dsr and interest rate during time interval
        int savingsDifference = int(debtValue.mul(timeInterval)).mul((int(currentDsrAnnual)).sub(int(interestRate))).div(int(YEAR_SECS));
        
        delta = delta.add(savingsDifference);
        deltaCommon = deltaCommon.add(savingsDifference);

        lastCheckTime = now;

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
     * @notice Terminates agreement
     * @return Operation success
     */
    function _terminateAgreement() internal returns(bool _success) {
        closeDate = now;
        status = STATUS_ENDED;
        _updateAgreementState(true);
        _refund(false);
        
        emit AgreementTerminated();
        return true;
    }

    /**
     * @dev Liquidates agreement, mostly the sam as terminate
     * but also covers collateral transfers after liquidation
     * @return Operation success
     */
    function _liquidateAgreement() internal returns(bool _success) {
        closeDate = now;
        status = STATUS_LIQUIDATED;
        _refund(true);
        
        emit AgreementLiquidated();
        return true;
    }

    /**
     * @notice Block agreement
     * @return Operation success
     */
    function _blockAgreement() internal returns(bool _success) {
        status = STATUS_BLOCKED;
        _refund(false);
        
        emit AgreementBlocked();
        return true;
    }

    /**
     * @notice Refund agreement, transfer dai to lender, cdp ownership to borrower if debt is payed
     * @return Operation success
     */
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
    /*
    function _refund(bool _isCdpLiquidated) internal {
        uint lenderRefundDai = _unlockAllDai();
        uint borrowerFraDebtDai = borrowerFraDebt();
        address cdpOwnershipTo;

        if (borrowerFraDebtDai > 0) {
            if (_callTransferFromDai(borrower, address(this), borrowerFraDebtDai)) {
                lenderRefundDai = lenderRefundDai.add(borrowerFraDebtDai);
                cdpOwnershipTo = borrower;
            } else {
                emit FraDebtPaybackFailed(borrower, borrowerFraDebtDai);
            }
        }
        _transferDai(lender, lenderRefundDai);
        _transferCdpOwnership(cdpId, cdpOwnershipTo);
        emit RefundBase(lender, lenderRefundDai, cdpOwnershipTo, cdpId);
    }*/

    /**
     * @notice Executes all required transfers after liquidation
     * @return Operation success
     */
    function _refundAfterCdpLiquidation(uint _borrowerFraDebtDai) internal returns(bool _success) {
        uint256 lenderRefundCollateral = getCollateralEquivalent(collateralType, _borrowerFraDebtDai);
        uint borrowerRefundCollateral;
        if (isETH) {
            borrowerRefundCollateral = address(this).balance;
            lender.transfer(lenderRefundCollateral);
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
     * @notice Executes all required transfers after liquidation
     * @return Operation success
     */
    function _refundAfterCdpLiquidation(uint _borrowerFraDebtDai) internal returns(bool _success) {
    }

    /**
     * @notice recovers remaining ETH from cdp (pays remaining debt if exists)
     * @param ilk     collateral type in bytes32 format
     * @param cdp cdp ID
     */
    function _freeETH(bytes32 ilk, uint cdp) internal {
    }
}