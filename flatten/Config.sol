
// File: contracts/helpers/Claimable.sol

pragma solidity 0.5.12;

/**
 * @title   Ownable contract
 * @dev     Contract has all neccessary ownable functions but doesn't have initialization
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev     Grants access only for owner
     */
    modifier onlyContractOwner() {
        require(isOwner(msg.sender), "Ownable: Not a contract owner");
        _;
    }

    /**
     * @dev     Check if address is  owner
     */
    function isOwner(address _addr) public view returns(bool) {
        return owner == _addr;
    }

    /**
     * @dev     Set initial owner
     * @param   _addr   owner address
     */
    function _setInitialOwner(address _addr) internal {
        owner = _addr;
        emit OwnershipTransferred(address(0), owner);
    }
}

/**
 * @title   Base Claimable contract
 * @dev     The same as Ownable but with two-step ownership transfering procedure
 *          Contract has all neccessary Claimable functions for transfer and claim ownership
 */
contract Claimable is Ownable {
    address public pendingOwner;

    /**
     * @dev     Transfer ownership
     * @param   _newOwner   address, the ownership should be transferred to, becomes pending until claim
     */
    function transferOwnership(address _newOwner) public onlyContractOwner {
        pendingOwner = _newOwner;
    }

    /**
     * @dev     Approve pending owner by new owner
     */
    function claimOwnership() public {
        require(msg.sender == pendingOwner, "Claimable: Not a pending owner");

        address previousOwner = owner;
        owner = msg.sender;
        pendingOwner = address(0);

        emit OwnershipTransferred(previousOwner, msg.sender);
    }
}

// File: contracts/helpers/ClaimableBase.sol

pragma solidity 0.5.12;


/**
 * @title   Claimable contract with initialization inside contructor
 */
contract ClaimableBase is Claimable {
    /**
     * @dev Constructor, set caller as contract owner
     */
    constructor () public {
        _setInitialOwner(msg.sender);
    }
}

// File: contracts/config/Config.sol

pragma solidity 0.5.12;


/**
 * @title Config for Agreement contract
 */
contract Config is ClaimableBase {
    mapping(bytes32 => bool) public collateralsEnabled;

    uint public approveLimit; // max duration in secs available for approve after creation, if expires - agreement should be closed
    uint public matchLimit; // max duration in secs available for match after approve, if expires - agreement should be closed
    uint public injectionThreshold;
    uint public minCollateralAmount;
    uint public maxCollateralAmount;
    uint public minDuration;
    uint public maxDuration;
    uint public riskyMargin;

    /**
     * @dev     Set default config
     */
    constructor() public {
        setGeneral(7 days, 1 days, 0.01 ether, 0.2 ether, 10000 ether, 1 minutes, 365 days, 20);
        enableCollateral("ETH-A");
        enableCollateral("BAT-A");
    }

    /**
     * @dev     set sonfig according to parameters
     * @param   _approveLimit      max duration available for approve after creation, if expires - agreement should be closed
     * @param   _matchLimit        max duration available for match after approve, if expires - agreement should be closed
     * @param   _injectionThreshold     minimal threshold permitted for injection
     * @param   _minCollateralAmount    min amount
     * @param   _maxCollateralAmount    max amount
     * @param   _minDuration        min agreement length
     * @param   _maxDuration        max agreement length
     * @param   _riskyMargin        risky Margin %
     */
    function setGeneral(
        uint _approveLimit,
        uint _matchLimit,
        uint _injectionThreshold,
        uint _minCollateralAmount,
        uint _maxCollateralAmount,
        uint _minDuration,
        uint _maxDuration,
        uint _riskyMargin
    ) public onlyContractOwner {
        approveLimit = _approveLimit;
        matchLimit = _matchLimit;
        
        injectionThreshold = _injectionThreshold;
        
        minCollateralAmount = _minCollateralAmount;
        maxCollateralAmount = _maxCollateralAmount;

        minDuration = _minDuration;
        maxDuration = _maxDuration;

        riskyMargin = _riskyMargin;
    }

    /**
     * @dev     set config parameter
     * @param   _riskyMargin        risky Margin %
     */
    function setRiskyMargin(uint _riskyMargin) public onlyContractOwner {
        riskyMargin = _riskyMargin;
    }

    /**
     * @dev     set config parameter
     * @param   _approveLimit        max duration available for approve after creation, if expires - agreement should be closed
     */
    function setApproveLimit(uint _approveLimit) public onlyContractOwner {
        approveLimit = _approveLimit;
    }

    /**
     * @dev     set config parameter
     * @param   _matchLimit        max duration available for match after approve, if expires - agreement should be closed
     */
    function setMatchLimit(uint _matchLimit) public onlyContractOwner {
        matchLimit = _matchLimit;
    }

    /**
     * @dev     set config parameter
     * @param   _injectionThreshold     minimal threshold permitted for injection
     */
    function setInjectionThreshold(uint _injectionThreshold) public onlyContractOwner {
        injectionThreshold = _injectionThreshold;
    }

    /**
     * @dev     enable colateral type
     * @param   _ilk     bytes32 collateral type
     */
    function enableCollateral(bytes32 _ilk) public onlyContractOwner {
        collateralsEnabled[_ilk] = true;
    }

    /**
     * @dev     disable colateral type
     * @param   _ilk     bytes32 collateral type
     */
    function disableCollateral(bytes32 _ilk) public onlyContractOwner {
        collateralsEnabled[_ilk] = false;
    }

    /**
     * @dev     check if colateral is enabled
     * @param   _ilk     bytes32 collateral type
     */
    function isCollateralEnabled(bytes32 _ilk) public view returns(bool) {
        return collateralsEnabled[_ilk];
    }
}
