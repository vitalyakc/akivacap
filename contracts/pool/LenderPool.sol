pragma solidity 0.5.12;

import "../helpers/SafeMath.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IAgreement.sol";
import "../helpers/Administrable.sol";

/**
 * @title Pool contract for lenders
 */
contract LenderPool is Administrable {
    using SafeMath for uint;
    enum Statuses {Pending, Matched, Closed}

    Statuses public status;
    address public targetAgreement;

    uint public daiGoal;
    uint public daiTotal;
    uint public daiWithSavings;
    uint public interestRate;
    uint public duration;

    // pool restrictions
    uint public minDai;
    uint public pendingExpireDate;

    // target agreement restrictions
    uint public minInterestRate;
    uint public minDuration;
    uint public maxDuration;

    mapping(address=>uint) public balanceOf;

    address public daiToken = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa;

    event MatchedAgreement(address targetAgreement);
    event RefundedFromAgreement(address targetAgreement, uint daiWithSavings);
    event TargetAgreementUpdated(address targetAgreement, uint daiGoal, uint interestRate, uint duration);
    event Deposited(address pooler, uint amount);
    event Withdrawn(address caller, address pooler, uint amount, uint amountWithSavings);
    event AgreementRestrictionsUpdated(uint minInterestRate, uint minDuration, uint maxDuration);
    event PoolRestrictionsUpdated(uint pendingExpireDate, uint minDai);
    event StatusUpdated(uint next);

    /**
     * @notice Grants access only if pool has appropriate status
     * @param _status status should be checked with
     */
    modifier onlyStatus(Statuses _status) {
        require(status == _status, "LenderPool: status is incorrect");
        _;
    }

    /**
     * @notice  Constructor, set main restrictions, set target agreement
     * @param   _targetAgreement    address of target agreement
     * @param   _minInterestRate    min percent of interest rate, should be passed like RAY
     * @param   _minDuration        min available agreement duration in secs
     * @param   _maxDuration        mav available agreement duration in secs
     * @param   _maxPendingPeriod   max available pending period for gathering dai in pool and do match
     * @param   _minDai             min amount of dai tokens available for deposit to pool
     */
    constructor(
        address _targetAgreement,
        uint _minInterestRate,
        uint _minDuration,
        uint _maxDuration,
        uint _maxPendingPeriod,
        uint _minDai
    )
        public
    {
        _setAgreementRestrictions(_minInterestRate, _minDuration, _maxDuration);
        _setPoolRestrictions(_maxPendingPeriod, _minDai);
        setTargetAgreement(_targetAgreement);
    }
    
    /**
     * @notice Set target agreement address and check for restrictions of target agreement
     * @param   _addr   address of target agreement
     */
    function setTargetAgreement(address _addr) public onlyAdmin() {
        _setAgreement(_addr);

        // require(daiToken == IAgreement(targetAgreement).getDaiAddress(), "LenderPool: dai token address doesn't coincide with required");
        require(daiGoal > 0, "LenderPool: target agreement debt is zero");
        require(interestRate >= minInterestRate, "LenderPool: target agreement interest rate is low");
        require(duration >= minDuration && duration <= maxDuration, "LenderPool: target agreement duration does not match min and max");
        require(_isAgreementInStatus(IAgreement.Statuses.Open), "LenderPool: Agreement is not open");
    }

    /**
     * @notice  Deposit dai tokens to pool
     * @dev     Transfer from pooler's account dai tokens to pool contract. Pooler should approve the amount to this contract beforehand
     * @param   _amount     amount of dai tokens for depositing
     */
    function deposit(uint _amount) public onlyStatus(Statuses.Pending) {
        uint daiRemaining = daiGoal.sub(daiTotal);

        require(daiRemaining > 0, "LenderPool: goal is reached");
        // amount should be more than minimal, or if remaning to goal tokens is less than minimal - _amount should cover the remaining completely
        require(_amount >= minDai || _amount >= daiRemaining, "LenderPool: amount is less min or remaining");

        // adjust amount in order dai total doesn't exceed the goal
        _amount = _amount > daiRemaining ? daiRemaining : _amount;

        _deposit(msg.sender, _amount);
    }

    /**
     * @notice  Withdraw own dai tokens by pooler
     */
    function withdraw() public {
        uint share = availableForWithdrawal(msg.sender);
        require(share > 0, "LenderPool: dai balance is zero or can not be withdrawn now");
        _withdraw(msg.sender, balanceOf[msg.sender], share);
    }

    /**
     * @notice  Function is aimed to adjust the total dai, deposited to contract, with the goal
     * @dev     Admin can refund some amount of dai tokens to pooler, but no more than pooler's balance
     *          can be called only when pending
     * @param   _to         pooler address
     * @param   _amount     amount for withdrawal
     */
    function withdrawTo(address _to, uint _amount) public onlyAdmin() onlyStatus(Statuses.Pending) {
        require(_amount > 0, "LenderPool: amount is zero");
        _withdraw(_to, _amount, _amount);
    }

    /**
     * @notice  Do match with target agreement
     * @dev     Pool status becomes Matched
     */
    function matchAgreement() public onlyAdmin() onlyStatus(Statuses.Pending) {
        require(daiGoal == daiTotal, "LenderPool: dai total should be equal to goal (agreement debt)");

        _daiTokenApprove(targetAgreement, daiGoal);
        _matchAgreement();
        _switchStatus(Statuses.Matched);

        emit MatchedAgreement(targetAgreement);
    }

    /**
     * @notice  Refund dai from target agreement after it is closed (terminated, liquidated, cancelled, blocked)
     * @dev     Pool status becomes Closed
     */
    function refundFromAgreement() public onlyAdmin() onlyStatus(Statuses.Matched) {
        require(_isAgreementInStatus(IAgreement.Statuses.Closed), "LenderPool: agreement is not closed yet");

        (, daiWithSavings) = _getAgreementAssets();
        _withdrawDaiFromAgreement();

        _switchStatus(Statuses.Closed);

        emit RefundedFromAgreement(targetAgreement, daiWithSavings);
    }

    /**
     * @notice  Check if pool has appropriate status
     * @param   _status     status should be checked with
     */
    function isStatus(Statuses _status) public view returns(bool) {
        return status == _status;
    }

    /**
     * @notice  Calculate the amount of dai available for withdrawal for exact pooler now
     * @dev     if pool has Closed status the share is calculated according to dai refunded with savings from agreement
     *          if pool has Depositing status but deposit time is expired - the share is equal to pooler's balance (deposited amount)
     * @param   _pooler         pooler address
     */
    function availableForWithdrawal(address _pooler) public view returns(uint share) {
        if (isStatus(Statuses.Closed)) {
            share = balanceOf[_pooler].mul(daiWithSavings).div(daiGoal);
        }
        if (isStatus(Statuses.Pending) && now > pendingExpireDate) {
            share = balanceOf[_pooler];
        }
    }
    
    /**
     * @notice Set target agreement address
     * @param _addr  address of target agreement
     */
    function _setAgreement(address _addr) internal {
        require(_addr != address(0), "LenderPool: target agreement address is null");

        targetAgreement = _addr;
        daiGoal = _getAgreementDebtValue();
        interestRate = _getAgreementInterestRate();
        duration = _getAgreementDuration();

        emit TargetAgreementUpdated(targetAgreement, daiGoal, interestRate, duration);
    }

    /**
     * @notice  Deposit, change depositer (pooler) balance and total deposited dai
     * @dev     transfer from pooler's account dai tokens to pool contract. Pooler should approve the amount to this contract beforehand
     * @param   _pooler     depositer address
     * @param   _amount     amount of dai tokens for depositing
     */
    function _deposit(address _pooler, uint _amount) internal {
        _daiTokenTransferFrom(_pooler, address(this), _amount);
        daiTotal = daiTotal.add(_amount);
        balanceOf[_pooler] = balanceOf[_pooler].add(_amount);

        emit Deposited(_pooler, _amount);
    }

    /**
     * @notice  Decrease dai total balance and transfer dai tokens to pooler
     * @param   _pooler     pooler address
     * @param   _amount     amount the balance should be decreased by
     * @param   _amountWithSavings amount with savings should be transfered to pooler, if no savings - is equal to _amount
     */
    function _withdraw(address _pooler, uint _amount, uint _amountWithSavings) internal {
        daiTotal = daiTotal.sub(_amount);
        balanceOf[_pooler] = balanceOf[_pooler].sub(_amount);
        _daiTokenTransfer(_pooler, _amountWithSavings);

        emit Withdrawn(msg.sender, _pooler, _amount, _amountWithSavings);
    }

    /**
     * @notice Set restrictions to main parameters of target agreement, in irder to prevent match with unprofitable agreement
     * @param _minInterestRate  min percent of interest rate, should be passed like RAY
     * @param _minDuration      min available agreement duration in secs
     * @param _maxDuration      mav available agreement duration in secs
     */
    function _setAgreementRestrictions(uint _minInterestRate, uint _minDuration, uint _maxDuration) internal {
        minInterestRate = _minInterestRate;
        minDuration = _minDuration;
        maxDuration = _maxDuration;

        emit AgreementRestrictionsUpdated(minInterestRate, minDuration, maxDuration);
    }

    /**
     * @notice  Set restrictions to pool
     * @param   _maxPendingPeriod   max available pending period for gathering dai in pool and do match
     * @param   _minDai             min amount of dai tokens available for deposit to pool
     */
    function _setPoolRestrictions(uint _maxPendingPeriod, uint _minDai) internal {
        pendingExpireDate = now.add(_maxPendingPeriod);
        minDai = _minDai;

        emit PoolRestrictionsUpdated(pendingExpireDate, minDai);
    }

    /**
    * @notice   Switch to exact status
    * @param    _next   status that should be switched to
    */
    function _switchStatus(Statuses _next) internal {
        status = _next;

        emit StatusUpdated(uint(_next));
    }

    /**
    * @notice   Get Agreement debt dai amount
    */
    function _getAgreementDebtValue() internal returns (uint) {
        return IAgreement(targetAgreement).debtValue();
    }

    /**
    * @notice   Get Agreement interest rate
    */
    function _getAgreementInterestRate() internal returns (uint) {
        return IAgreement(targetAgreement).interestRate();
    }

    /**
    * @notice   Get Agreement duration
    */
    function _getAgreementDuration() internal returns (uint) {
        return IAgreement(targetAgreement).duration();
    }

    /**
    * @notice   Check agreement status
    */
    function _isAgreementInStatus(IAgreement.Statuses _status) internal returns(bool) {
        return IAgreement(targetAgreement).isStatus(_status);
    }

    /**
    * @notice   Do Agreement match
    */
    function _matchAgreement() internal {
        IAgreement(targetAgreement).matchAgreement();
    }

    /**
    * @notice   Get Agreement assets
    */
    function _getAgreementAssets() internal returns(uint, uint) {
        return IAgreement(targetAgreement).getAssets(address(this));
    }

    /**
    * @notice   Withdraw all dai from Agreement
    */
    function _withdrawDaiFromAgreement() internal {
        IAgreement(targetAgreement).withdrawDai(daiWithSavings);
    }

    /**
    * @notice   Approve dai to agreement
    * @param    _agreement  address
    * @param    _amount     dai to approve
    */
    function _daiTokenApprove(address _agreement, uint _amount) internal {
        IERC20(daiToken).approve(_agreement, _amount);
    }

    /**
    * @notice   Transfer dai from pooler to pool
    * @param    _pooler     address from
    * @param    _to         address to
    * @param    _amount     dai amount
    */
    function _daiTokenTransferFrom(address _pooler, address _to, uint _amount) internal {
        IERC20(daiToken).transferFrom(_pooler, _to, _amount);
    }

    /**
    * @notice   Transfer dai to pooler
    * @param    _pooler     address from
    * @param    _amount     dai amount
    */
    function _daiTokenTransfer(address _pooler, uint _amount) internal {
        IERC20(daiToken).transfer(_pooler, _amount);
    }
}

