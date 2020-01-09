pragma solidity 0.5.11;

import "../helpers/SafeMath.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IAgreement.sol";

/**
 * @title Admin ownable
 */
contract Adminable {
    address public admin;

    constructor() public {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        if (msg.sender == admin)
            _;
    }

    function transferAdminOwnership(address newAdmin) public onlyAdmin {
        if (newAdmin != address(0)) admin = newAdmin;
    }
}

/**
 * @title Pool contract for lenders
 */
contract LenderPool is Adminable {
    using SafeMath for uint;
    enum Statuses {Pending, Depositing, Matched, Closed}

    Statuses public status;
    address targetAgreement;
    address daiToken;
    
    uint daiGoal;
    uint daiTotal;
    uint daiRefunded;
    uint interestRate;
    uint minDai;
    uint depositExpireDate;

    uint minInterestRate;
    uint minDuration;
    uint maxDuration;

    mapping(address=>uint) public balanceOf;

    /**
     * @notice Grants access only if pool has appropriate status
     * @param _status status should be checked with
     */
    modifier onlyStatus(Statuses _status) {
        require(status == _status, "LenderPool: status is incorrect");
        _;
    }

    constructor(address _targetAgreement, uint _minInterestRate, address _daiToken, uint maxDepositPeriod) public {
        setTargetAgreement(_targetAgreement);

        minInterestRate = _minInterestRate;
        daiToken = _daiToken;
        depositExpireDate = now.add(maxDepositPeriod);

        _switchStatus(Statuses.Depositing);
    }

    function setTargetAgreement(address _addr) public onlyAdmin {
        targetAgreement = _addr;
        daiGoal = IAgreement(targetAgreement).debtValue();
        interestRate = IAgreement(targetAgreement).interestRate();
        uint duration = IAgreement(targetAgreement).duration();

        require(interestRate >= minInterestRate, "LenderPool: target agreement interest rate is less than minimum");
        require(duration >= minDuration && duration <= maxDuration, "LenderPool: target agreement duration doesn't match min and max");
    }

    function deposit(uint _amount) public onlyStatus(Statuses.Depositing) {
        require(_amount >= minDai, "LenderPool: amount is less than minimum");
        require(daiTotal < daiGoal, "LenderPool: goal is reached");

        // adjust amount in order dai total doesn't exceed the goal
        uint amount = daiTotal.add(_amount) < daiGoal ? _amount : daiGoal.sub(daiTotal);
        IERC20(daiToken).transferFrom(msg.sender, address(this), amount);
        daiTotal = daiTotal.add(amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
    }

    function withdraw() public {
        uint share = availableForWithdrawal(msg.sender);
        require(share > 0, "LenderPool: dai balance is zero or can not be withdrawn now");

        balanceOf[msg.sender] = 0;
        IERC20(daiToken).transfer(msg.sender, share);
    }

    function matchAgreement() public onlyAdmin {
        IERC20(daiToken).approve(targetAgreement, daiGoal);
        IAgreement(targetAgreement).matchAgreement();
        _switchStatus(Statuses.Matched);
    }

    /**
     * @notice  refund dai from target agreement after it is closed (terminated, liquidated, cancelled, blocked)
     * @dev     pool status becomes Closed 
     */
    function refundAgreementDai() public onlyAdmin {
        require(IAgreement(targetAgreement).isStatus(IAgreement.Statuses.Closed), "LenderPool: agreement is not closed yet");
        (, daiRefunded) = IAgreement(targetAgreement).getAssets(address(this));
        IAgreement(targetAgreement).withdrawDai(daiRefunded);
        _switchStatus(Statuses.Closed);
    }

    /**
     * @notice  Function is aimed to adjust the total dai deposited to contract withe the goal
     * @dev     admin can refund some amount of dai tokens to pooler, but no more than pooler's balance
     * @param   _to         pooler address
     * @param   _amount     amount for withdrawal
     */
    function withdrawTo(address _to, uint _amount) public onlyAdmin onlyStatus(Statuses.Depositing) {
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_amount);
        IERC20(daiToken).transfer(_to, _amount);
    }

    /**
     * @notice  Check if pool has appropriate status
     * @param   _status     status should be checked with
     */
    function isStatus(Statuses _status) public view returns(bool) {
        return status == _status;
    }

    /**
     * @notice  Calculate the amount of dai available for withdrawal by pooler now
     * @dev     if pool is closed the share is calculated according to dai refunded with savings from agreement
     *          if pool has Depositing status but deposit time is expired - the share is equal to pooler's balance (deposited amount)
     * @param   _pooler         pooler address
     */
    function availableForWithdrawal(address _pooler) public view returns(uint share) {
        if (isStatus(Statuses.Closed)) {
            share = balanceOf[msg.sender].mul(daiRefunded).div(daiGoal);
        }
        if (isStatus(Statuses.Depositing) && now > depositExpireDate) {
            share = balanceOf[msg.sender];
        }
    }

    /**
    * @notice   switch to exact status
    * @param    _next   status that should be switched to
    */
    function _switchStatus(Statuses _next) internal {
        status = _next;
    }
}

