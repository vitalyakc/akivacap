
// File: contracts/helpers/SafeMath.sol

pragma solidity >=0.5.0 <0.6.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    int256 constant INT256_MIN = int256((uint256(1) << 255));

    int256 constant INT256_MAX = int256(~((uint256(1) << 255)));

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // require(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // require(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
    * @dev Multiplies two int numbers, throws on overflow.
    */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        if (a == 0) {
            return 0;
        }
        int256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
    * @dev Division of two int numbers, truncating the quotient.
    */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // require(b > 0); // Solidity automatically throws when dividing by 0
        int256 c = a / b;
        // require(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two int numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        require(!(a > 0 && b > INT256_MIN - a), "SafeMath: subtraction underflow");  // underflow
        require(!(a < 0 && b < INT256_MAX - a), "SafeMath: subtraction overflow");  // overflow

        return a - b;
    }

    /**
    * @dev Adds two int numbers, throws on overflow.
    */
    function add(int256 a, int256 b) internal pure returns (int256) {
        require(!(a > 0 && b > INT256_MAX - a), "SafeMath: addition underflow");  // overflow
        require(!(a < 0 && b < INT256_MIN - a), "SafeMath: addition overflow");  // underflow

        return a + b;
    }
}

// File: contracts/interfaces/IERC20.sol

pragma solidity 0.5.11;

contract IERC20 {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// File: contracts/interfaces/IAgreement.sol

pragma solidity 0.5.11;


/**
 * @title Interface for Agreement contract
 */
interface IAgreement {
    enum Statuses {All, Pending, Open, Active, Closed}
    enum ClosedTypes {Ended, Liquidated, Blocked, Cancelled}

    function initAgreement(
        address payable _borrower,
        uint256 _collateralAmount,
        uint256 _debtValue,
        uint256 _duration,
        uint256 _interestRate,
        bytes32 _collateralType,
        bool _isETH,
        address _configAddr
    ) external payable;

    function transferOwnership(address _newOwner) external;
    function claimOwnership() external;
    function approveAgreement() external returns(bool);
    function updateAgreement() external returns(bool);
    function cancelAgreement() external returns(bool);
    function rejectAgreement() external returns(bool);
    function blockAgreement() external returns(bool);
    function matchAgreement() external returns(bool _success);
    function interestRate() external view returns(uint);
    function duration() external view returns(uint);
    function debtValue() external view returns(uint);
    function status() external view returns(uint);
    function lender() external view returns(address);
    function borrower() external view returns(address);
    function collateralType() external view returns(bytes32);
    function isStatus(Statuses _status) external view returns(bool);
    function isBeforeStatus(Statuses _status) external view returns(bool);
    function isClosedWithType(ClosedTypes _type) external view returns(bool);
    function checkTimeToCancel(uint _approveLimit, uint _matchLimit) external view returns(bool);
    function cdpId() external view returns(uint);
    function erc20TokenContract(bytes32 ilk) external view returns(IERC20);
    function getAssets(address _holder) external view returns(uint,uint);
    function withdrawDai(uint _amount) external;
    function getDaiAddress() external view returns(address);

    function getInfo()
        external
        view
        returns (
            address _addr,
            uint _status,
            uint _closedType,
            uint _duration,
            address _borrower,
            address _lender,
            bytes32 _collateralType,
            uint _collateralAmount,
            uint _debtValue,
            uint _interestRate,
            bool _isRisky
        );

    event AgreementInitiated(address _borrower, uint _collateralValue, uint _debtValue, uint _expireDate, uint _interestRate);
    event AgreementApproved();
    event AgreementMatched(address _lender, uint _expireDate, uint _cdpId, uint _collateralAmount, uint _debtValue, uint _drawnDai);
    event AgreementUpdated(int _savingsDifference, int _delta, uint _currentDsrAnnual, uint _timeInterval, uint _drawnDai, uint _injectionAmount);
    event AgreementClosed(uint _closedType, address _user);
    event AssetsCollateralPush(address _holder, uint _amount, bytes32 _collateralType);
    event AssetsCollateralPop(address _holder, uint _amount, bytes32 _collateralType);
    event AssetsDaiPush(address _holder, uint _amount);
    event AssetsDaiPop(address _holder, uint _amount);
    event CdpOwnershipTransferred(address _borrower, uint _cdpId);
    event AdditionalCollateralLocked(uint _amount);
    event RiskyToggled(bool _isRisky);
}

// File: contracts/pool/LenderPool.sol

pragma solidity 0.5.11;




/**
 * @title Admin ownable
 */
contract Adminable {
    address public admin;

    event AdminOwnershipTransferred(address indexed previousAdmin, address indexed newAdmin);

    /**
     * @dev Initializes the contract setting the deployer as the initial admin.
     */
    constructor() internal {
        admin = msg.sender;
    }

    /**
     * @notice  Grants access only for admin
     */
    modifier onlyAdmin() {
        require (msg.sender == admin, "Adminable: caller is not admin");
        _;
    }

    /**
     * @notice  Transfers ownership of the contract to a new account (`_newAdmin`).
     * @dev     Can only be called by the current admin.
     */
    function transferAdminOwnership(address _newAdmin) public onlyAdmin {
        require(_newAdmin != address(0), "Adminable: new owner is the zero address");
        emit AdminOwnershipTransferred(admin, _newAdmin);
        admin = _newAdmin;
    }
}

/**
 * @title Pool contract for lenders
 */
contract LenderPool is Adminable {
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

    address constant daiToken = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa;

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
    function setTargetAgreement(address _addr) public onlyAdmin {
        _setAgreement(_addr);

        // require(daiToken == IAgreement(targetAgreement).getDaiAddress(), "LenderPool: dai token address doesn't coincide with required");
        require(daiGoal > 0, "LenderPool: target agreement debt is zero");
        require(interestRate >= minInterestRate, "LenderPool: target agreement interest rate is low");
        require(duration >= minDuration && duration <= maxDuration, "LenderPool: target agreement duration does not match min and max");
        require(IAgreement(targetAgreement).isStatus(IAgreement.Statuses.Open), "LenderPool: Agreement is not open");
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
    function withdrawTo(address _to, uint _amount) public onlyAdmin onlyStatus(Statuses.Pending) {
        require(_amount > 0, "LenderPool: amount is zero");
        _withdraw(_to, _amount, _amount);
    }

    /**
     * @notice  Do match with target agreement
     * @dev     Pool status becomes Matched
     */
    function matchAgreement() public onlyAdmin {
        require(daiGoal == daiTotal, "LenderPool: dai total should be equal to goal (agreement debt)");
        IERC20(daiToken).approve(targetAgreement, daiGoal);
        IAgreement(targetAgreement).matchAgreement();
        _switchStatus(Statuses.Matched);

        emit MatchedAgreement(targetAgreement);
    }

    /**
     * @notice  Refund dai from target agreement after it is closed (terminated, liquidated, cancelled, blocked)
     * @dev     Pool status becomes Closed
     */
    function refundFromAgreement() public onlyAdmin {
        require(IAgreement(targetAgreement).isStatus(IAgreement.Statuses.Closed), "LenderPool: agreement is not closed yet");
        (, daiWithSavings) = IAgreement(targetAgreement).getAssets(address(this));
        IAgreement(targetAgreement).withdrawDai(daiWithSavings);
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
        daiGoal = IAgreement(targetAgreement).debtValue();
        interestRate = IAgreement(targetAgreement).interestRate();
        duration = IAgreement(targetAgreement).duration();

        emit TargetAgreementUpdated(targetAgreement, daiGoal, interestRate, duration);
    }

    /**
     * @notice  Deposit, change depositer (pooler) balance and total deposited dai
     * @dev     transfer from pooler's account dai tokens to pool contract. Pooler should approve the amount to this contract beforehand
     * @param   _pooler     depositer address
     * @param   _amount     amount of dai tokens for depositing
     */
    function _deposit(address _pooler, uint _amount) internal {
        IERC20(daiToken).transferFrom(_pooler, address(this), _amount);
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
        IERC20(daiToken).transfer(_pooler, _amountWithSavings);

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
}
