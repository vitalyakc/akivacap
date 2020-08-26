
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

// File: contracts/helpers/SafeMath.sol

pragma solidity 0.5.12;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    int256 constant INT256_MIN = int256((uint256(1) << 255));

    int256 constant INT256_MAX = int256(~((uint256(1) << 255)));

    /**
    * @dev  Multiplies two numbers, throws on overflow.
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
    * @dev  Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // require(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // require(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev  Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
    * @dev  Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
    * @dev  Multiplies two int numbers, throws on overflow.
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
    * @dev  Division of two int numbers, truncating the quotient.
    */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // require(b > 0); // Solidity automatically throws when dividing by 0
        int256 c = a / b;
        // require(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev  Substracts two int numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        require(!(a > 0 && b > INT256_MIN - a), "SafeMath: subtraction underflow");  // underflow
        require(!(a < 0 && b < INT256_MAX - a), "SafeMath: subtraction overflow");  // overflow

        return a - b;
    }

    /**
    * @dev  Adds two int numbers, throws on overflow.
    */
    function add(int256 a, int256 b) internal pure returns (int256) {
        require(!(a > 0 && b > INT256_MAX - a), "SafeMath: addition underflow");  // overflow
        require(!(a < 0 && b < INT256_MIN - a), "SafeMath: addition overflow");  // underflow

        return a + b;
    }
}

// File: contracts/helpers/RaySupport.sol

pragma solidity 0.5.12;


/**
 * @title   RaySupport contract for ray (10^27) preceision calculations
 */
contract RaySupport {
    using SafeMath for uint256;
    using SafeMath for int256;
    uint constant public ONE  = 10 ** 27;
    uint constant public HALF = ONE / 2;
    uint constant public HUNDRED = 100;

    /**
     * @dev     Convert uint value to Ray format
     * @param   _val    uint value should be converted
     */
    function toRay(uint _val) public pure returns(uint) {
        return _val.mul(ONE);
    }

    /**
     * @dev     Convert uint value from Ray format
     * @param   _val    uint value should be converted
     */
    function fromRay(uint _val) public pure returns(uint) {
        uint x = _val / ONE;
        //if (  (_val.sub(toRay(x))) > uint( (HALF-1) ) )
        //    return x.add(1); 
        return x;
    }

    /**
     * @dev     Convert int value to Ray format
     * @param   _val    int value should be converted
     */
    function toRay(int _val) public pure returns(int) {
        return _val.mul(int(ONE));
    }

    /**
     * @dev     Convert int value from Ray format
     * @param   _val    int value should be converted
     */
    function fromRay(int _val) public pure returns(int) {
        int x = _val / int(ONE);
        //if (  (_val.sub(toRay(x))) > int( (HALF-1) ) )
        //    return x.add(1); 
        return x;
    }

    /**
     * @dev     Calculate x pow n by base
     * @param   x   value should be powered
     * @param   n   power degree
     * @param   base    base value
     */
    function rpow(uint x, uint n, uint base) public pure returns (uint z) {
        assembly {
            switch x case 0 {switch n case 0 {z := base} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := base } default { z := x }
                let half := div(base, 2)  // for rounding.
                for { n := div(n, 2) } n { n := div(n,2) } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) { revert(0,0) }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) { revert(0,0) }
                    x := div(xxRound, base)
                    if mod(n,2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) { revert(0,0) }
                        z := div(zxRound, base)
                    }
                }
            }
        }
    }
}

// File: contracts/config/Config.sol

pragma solidity 0.5.12;



/**
 * @title Config for Agreement contract
 */
contract Config is ClaimableBase, RaySupport {
    mapping(bytes32 => bool) public collateralsEnabled;

    uint public approveLimit; // max duration in secs available for approve after creation, if expires - agreement should be closed
    uint public matchLimit; // max duration in secs available for match after approve, if expires - agreement should be closed
    uint public injectionThreshold;
    uint public minCollateralAmount;
    uint public maxCollateralAmount;
    uint public minDuration;
    uint public maxDuration;
    uint public riskyMargin;
    uint public acapFee;   // per second %
    address payable public acapAddr;  // 

    /**
     * @dev     Set default config
     */
    constructor() public {
        // last parameter: fee is 0.5% annual in per-second compounding 
        setGeneral(7 days, 1 days, 0.01 ether, 0.2 ether, 10000 ether, 1 minutes, 1000 days, 20);
        enableCollateral("ETH-A");
        enableCollateral("BAT-A");
        enableCollateral("WBTC-A");
        enableCollateral("USDC-A");
        enableCollateral("USDC-B");
        acapFee  = 1000000000158153903837946257;
        acapAddr = 0xF79179D06C687342a3f5C1daE5A7253AFC03C7A8;  

    }

    /**
     * @dev     Set all config parameters
     * @param   _approveLimit      max time available for approve after creation, if expires - agreement should be closed
     * @param   _matchLimit        max time available for match after approve, if expires - agreement should be closed
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
     * @dev     Set config parameter
     * @param   _acapFee  fee in % per second
     */
    function setAcapFee(uint _acapFee) public onlyContractOwner {
        acapFee = _acapFee;
    }

    /**
     * @dev     Set config parameter
     * @param   _a  address for fees
     */
    function setAcapAddr(address payable _a) public onlyContractOwner {
        acapAddr = _a;
    }


    /**
     * @dev     Set config parameter
     * @param   _riskyMargin        risky Margin %
     */
    function setRiskyMargin(uint _riskyMargin) public onlyContractOwner {
        riskyMargin = _riskyMargin;
    }

    /**
     * @dev     Set config parameter
     * @param   _approveLimit        max duration available for approve after creation, if expires - agreement should be closed
     */
    function setApproveLimit(uint _approveLimit) public onlyContractOwner {
        approveLimit = _approveLimit;
    }

    /**
     * @dev     Set config parameter
     * @param   _matchLimit        max duration available for match after approve, if expires - agreement should be closed
     */
    function setMatchLimit(uint _matchLimit) public onlyContractOwner {
        matchLimit = _matchLimit;
    }

    /**
     * @dev     Set config parameter
     * @param   _injectionThreshold     minimal threshold permitted for injection
     */
    function setInjectionThreshold(uint _injectionThreshold) public onlyContractOwner {
        injectionThreshold = _injectionThreshold;
    }

    /**
     * @dev     Enable colateral type
     * @param   _ilk     bytes32 collateral type
     */
    function enableCollateral(bytes32 _ilk) public onlyContractOwner {
        collateralsEnabled[_ilk] = true;
    }

    /**
     * @dev     Disable colateral type
     * @param   _ilk     bytes32 collateral type
     */
    function disableCollateral(bytes32 _ilk) public onlyContractOwner {
        collateralsEnabled[_ilk] = false;
    }

    /**
     * @dev     Check if colateral is enabled
     * @param   _ilk     bytes32 collateral type
     */
    function isCollateralEnabled(bytes32 _ilk) public view returns(bool) {
        return collateralsEnabled[_ilk];
    }
}

// File: contracts/interfaces/IERC20.sol

pragma solidity 0.5.12;

/**
 * @title Interface for ERC20 token contract
 */
interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address) external view returns (uint);
    function allowance(address, address) external view returns (uint);
    function transfer(address, uint) external returns (bool);
    function approve(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// File: contracts/interfaces/IAgreement.sol

pragma solidity 0.5.12;


/**
 * @title Interface for Agreement contract
 */
interface IAgreement {
    enum Statuses {All, Pending, Open, Active, Closed}
    enum ClosedTypes {Ended, Liquidated, Blocked, Cancelled}

    function initAgreement(address payable, uint256, uint256, uint256, uint256, bytes32, bool, address) external payable;

    function transferOwnership(address) external;
    function claimOwnership() external;
    function approveAgreement() external returns(bool);
    function updateAgreement() external returns(bool);
    function cancelAgreement() external returns(bool); // ext
    function rejectAgreement() external returns(bool);
    function blockAgreement() external returns(bool);
    function matchAgreement() external returns(bool);
    function interestRate() external view returns(uint);
    function duration() external view returns(uint);
    function cdpDebtValue() external view returns(uint);
    function status() external view returns(uint);
    function lender() external view returns(address);
    function borrower() external view returns(address);
    function collateralType() external view returns(bytes32); // ext
    function isStatus(Statuses) external view returns(bool);
    function isBeforeStatus(Statuses) external view returns(bool);
    function isClosedWithType(ClosedTypes) external view returns(bool);
    function checkTimeToCancel(uint, uint) external view returns(bool);
    function cdpId() external view returns(uint);
    function erc20TokenContract(bytes32) external view returns(IERC20);
    function getAssets(address) external view returns(uint,uint); // ext
    function withdrawDai(uint) external;
    function getDaiAddress() external view returns(address); // ext

    function getInfo() external view returns (address,uint,uint,uint,address,address,bytes32,uint,uint,uint,bool); // ext

    event AgreementInitiated(address _borrower, uint _collateralValue, uint _debtValue, uint _expireDate, uint _interestRate);
    event AgreementApproved();
    event AgreementMatched(address _lender, uint _expireDate, uint _cdpId, uint _collateralAmount, uint _debtValue, uint _drawnDai);
    event AgreementUpdated(int _savingsDifference, int _delta, uint _timeInterval, uint _drawnDai, uint _injectionAmount);
    event AgreementClosed(uint _closedType, address _user);
    event AssetsCollateralPush(address _holder, uint _amount, bytes32 _collateralType);
    event AssetsCollateralPop(address _holder, uint _amount, bytes32 _collateralType);
    event AssetsDaiPush(address _holder, uint _amount);
    event AssetsDaiPop(address _holder, uint _amount);
    event CdpOwnershipTransferred(address _borrower, uint _cdpId);
    event AdditionalCollateralLocked(uint _amount);
    event RiskyToggled(bool _isRisky);
}

// File: contracts/helpers/Administrable.sol

pragma solidity 0.5.12;


/**
 * @title   Administrable contract, multiadmins managing
 * @dev     Inherit Claimable contract with usual initialization in constructor
 */
contract Administrable is ClaimableBase {
    mapping (address => bool) public isAdmin;

    event AdminAppointed(address admin);
    event AdminDismissed(address admin);

    /**
     * @dev     Appoint owner as admin
     */
    constructor () public {
        isAdmin[owner] = true;
        emit AdminAppointed(owner);
    }

    /**
     * @dev     Grants access only for admin
     */
    modifier onlyAdmin () {
        require(isAdmin[msg.sender], "Administrable: not an admin");
        _;
    }

    /**
     * @dev     Appoint new admin
     * @param   _newAdmin   new admin address
     */
    function appointAdmin (address _newAdmin) public onlyContractOwner() returns(bool success) {
        if (isAdmin[_newAdmin] == false) {
            isAdmin[_newAdmin] = true;
            emit AdminAppointed(_newAdmin);
        }
        return true;
    }

    /**
     * @dev     Dismiss admin
     * @param   _admin   admin address
     */
    function dismissAdmin (address _admin) public onlyContractOwner() returns(bool success) {
        isAdmin[_admin] = false;
        emit AdminDismissed(_admin);
        return true;
    }
}

// File: zos-lib/contracts/upgradeability/Proxy.sol

pragma solidity ^0.5.0;

/**
 * @title Proxy
 * @dev Implements delegation of calls to other contracts, with proper
 * forwarding of return values and bubbling of failures.
 * It defines a fallback function that delegates all calls to the address
 * returned by the abstract _implementation() internal function.
 */
contract Proxy {
  /**
   * @dev Fallback function.
   * Implemented entirely in `_fallback`.
   */
  function () payable external {
    _fallback();
  }

  /**
   * @return The Address of the implementation.
   */
  function _implementation() internal view returns (address);

  /**
   * @dev Delegates execution to an implementation contract.
   * This is a low level function that doesn't return to its internal call site.
   * It will return to the external caller whatever the implementation returns.
   * @param implementation Address to delegate.
   */
  function _delegate(address implementation) internal {
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize)

      // Call the implementation.
      // out and outsize are 0 because we don't know the size yet.
      let result := delegatecall(gas, implementation, 0, calldatasize, 0, 0)

      // Copy the returned data.
      returndatacopy(0, 0, returndatasize)

      switch result
      // delegatecall returns 0 on error.
      case 0 { revert(0, returndatasize) }
      default { return(0, returndatasize) }
    }
  }

  /**
   * @dev Function that is run as the first thing in the fallback function.
   * Can be redefined in derived contracts to add functionality.
   * Redefinitions must call super._willFallback().
   */
  function _willFallback() internal {
  }

  /**
   * @dev fallback implementation.
   * Extracted to enable manual triggering.
   */
  function _fallback() internal {
    _willFallback();
    _delegate(_implementation());
  }
}

// File: zos-lib/contracts/utils/Address.sol

pragma solidity ^0.5.0;

/**
 * Utility library of inline functions on addresses
 *
 * Source https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-solidity/v2.1.3/contracts/utils/Address.sol
 * This contract is copied here and renamed from the original to avoid clashes in the compiled artifacts
 * when the user imports a zos-lib contract (that transitively causes this contract to be compiled and added to the
 * build/artifacts folder) as well as the vanilla Address implementation from an openzeppelin version.
 */
library ZOSLibAddress {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

// File: zos-lib/contracts/upgradeability/BaseUpgradeabilityProxy.sol

pragma solidity ^0.5.0;



/**
 * @title BaseUpgradeabilityProxy
 * @dev This contract implements a proxy that allows to change the
 * implementation address to which it will delegate.
 * Such a change is called an implementation upgrade.
 */
contract BaseUpgradeabilityProxy is Proxy {
  /**
   * @dev Emitted when the implementation is upgraded.
   * @param implementation Address of the new implementation.
   */
  event Upgraded(address indexed implementation);

  /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "org.zeppelinos.proxy.implementation", and is
   * validated in the constructor.
   */
  bytes32 internal constant IMPLEMENTATION_SLOT = 0x7050c9e0f4ca769c69bd3a8ef740bc37934f8e2c036e5a723fd8ee048ed3f8c3;

  /**
   * @dev Returns the current implementation.
   * @return Address of the current implementation
   */
  function _implementation() internal view returns (address impl) {
    bytes32 slot = IMPLEMENTATION_SLOT;
    assembly {
      impl := sload(slot)
    }
  }

  /**
   * @dev Upgrades the proxy to a new implementation.
   * @param newImplementation Address of the new implementation.
   */
  function _upgradeTo(address newImplementation) internal {
    _setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }

  /**
   * @dev Sets the implementation address of the proxy.
   * @param newImplementation Address of the new implementation.
   */
  function _setImplementation(address newImplementation) internal {
    require(ZOSLibAddress.isContract(newImplementation), "Cannot set a proxy implementation to a non-contract address");

    bytes32 slot = IMPLEMENTATION_SLOT;

    assembly {
      sstore(slot, newImplementation)
    }
  }
}

// File: zos-lib/contracts/upgradeability/UpgradeabilityProxy.sol

pragma solidity ^0.5.0;


/**
 * @title UpgradeabilityProxy
 * @dev Extends BaseUpgradeabilityProxy with a constructor for initializing
 * implementation and init data.
 */
contract UpgradeabilityProxy is BaseUpgradeabilityProxy {
  /**
   * @dev Contract constructor.
   * @param _logic Address of the initial implementation.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  constructor(address _logic, bytes memory _data) public payable {
    assert(IMPLEMENTATION_SLOT == keccak256("org.zeppelinos.proxy.implementation"));
    _setImplementation(_logic);
    if(_data.length > 0) {
      (bool success,) = _logic.delegatecall(_data);
      require(success);
    }
  }  
}

// File: contracts/FraFactory.sol

pragma solidity 0.5.12;






/**
 * @title   Fra Factory
 * @dev     Handler of all agreements
 */
contract FraFactory is Administrable {
    address[] public agreementList;
    address payable public agreementImpl;
    address public configAddr;

    /**
     * @dev Set config and agreement implementation
     * @param _agreementImpl address of agreement implementation contract
     * @param _configAddr address of config contract
     */
    constructor(address payable _agreementImpl, address _configAddr) public {
        setConfigAddr(_configAddr);
        setAgreementImpl(_agreementImpl);
    }

    /**
     * @dev Requests agreement on ETH collateralType
     * @param _debtValue value of borrower's ETH put into the contract as collateral
     * @param _duration number of minutes which agreement should be terminated after
     * @param _interestRate percent of interest rate, should be passed like RAY
     * @param _collateralType type of collateral, should be passed as bytes32 - only ETH
     * @return agreement address
     */
    function initAgreementETH (
        uint256 _debtValue,
        uint256 _duration,
        uint256 _interestRate,
        bytes32 _collateralType
    ) external payable returns(address _newAgreement) {
        address payable agreementProxyAddr = address(new UpgradeabilityProxy(agreementImpl, ""));
        IAgreement(agreementProxyAddr).
            initAgreement.value(msg.value)(msg.sender, msg.value, _debtValue, _duration, _interestRate, _collateralType, true, configAddr);
        
        agreementList.push(agreementProxyAddr);
        return agreementProxyAddr; //address(agreement);
    }

    /**
     * @dev Requests agreement on ERC-20 collateralType
     * @param _debtValue value of borrower's collateral
     * @param _duration number of minutes which agreement should be terminated after
     * @param _interestRate percent of interest rate, should be passed like RAY 
     * @param _collateralType type of collateral, should be passed as bytes32
     * @return agreement address
     */
    function initAgreementERC20 (
        uint256 _collateralValue,
        uint256 _debtValue,
        uint256 _duration,
        uint256 _interestRate,
        bytes32 _collateralType
    ) external returns(address _newAgreement) {

        address  agreementProxyAddr;
        agreementProxyAddr = address(new UpgradeabilityProxy(agreementImpl, ""));
        
        IAgreement(agreementProxyAddr).
            initAgreement(msg.sender, _collateralValue, _debtValue, _duration, _interestRate, _collateralType, false, configAddr);
        
        IERC20 t = IAgreement(agreementProxyAddr).erc20TokenContract(_collateralType);        
        t.transferFrom(msg.sender, address(agreementProxyAddr), _collateralValue);
        
        agreementList.push(agreementProxyAddr);
        return agreementProxyAddr;
    }

    /**
     * @dev Set the new agreement implememntation adresss
     * @param _agreementImpl address of agreement implementation contract
     */
    function setAgreementImpl(address payable _agreementImpl) public onlyAdmin() {
        require(_agreementImpl != address(0), "FraFactory: agreement impl address should not be zero");
        agreementImpl = _agreementImpl;
    }

    /**
     * @dev Set the new config adresss
     * @param _configAddr address of config contract
     */
    function setConfigAddr(address _configAddr) public onlyAdmin() {
        require(_configAddr != address(0), "FraFactory: agreement impl address should not be zero");
        configAddr = _configAddr;
    }

    /**
     * @dev Makes the specific agreement valid
     * @param _address agreement address
     * @return operation success
     */
    function approveAgreement(address _address) public onlyAdmin() returns(bool _success) {
        return IAgreement(_address).approveAgreement();
    }

    /**
    * @dev Multi approve
    * @param _addresses agreements addresses array
    */
    function batchApproveAgreements(address[] calldata _addresses) external onlyAdmin() {
        require(_addresses.length <= 256, "FraMain: batch count is greater than 256");
        for (uint256 i = 0; i < _addresses.length; i++) {
            if (IAgreement(_addresses[i]).isStatus(IAgreement.Statuses.Pending)) {
                IAgreement(_addresses[i]).approveAgreement();
            }
        }
    }

    /**
     * @dev Reject specific agreement
     * @param _address agreement address
     * @return operation success
     */
    function rejectAgreement(address _address) external onlyAdmin() returns(bool _success) {
        return IAgreement(_address).rejectAgreement();
    }

    /**
    * @dev Multi reject
    * @param _addresses agreements addresses array
    */
    function batchRejectAgreements(address[] calldata _addresses) external onlyAdmin() {
        require(_addresses.length <= 256, "FraMain: batch count is greater than 256");
        for (uint256 i = 0; i < _addresses.length; i++) {
            if (IAgreement(_addresses[i]).isBeforeStatus(IAgreement.Statuses.Active)) {
                IAgreement(_addresses[i]).rejectAgreement();
            }
        }
    }

    /**
     * @dev Function for cron autoreject (close agreements if matchLimit expired)
     */
    function autoRejectAgreements() external onlyAdmin() {
        uint _approveLimit = Config(configAddr).approveLimit();
        uint _matchLimit = Config(configAddr).matchLimit();
        uint _len = agreementList.length;
        for (uint256 i = 0; i < _len; i++) {
            if (
                IAgreement(agreementList[i]).isBeforeStatus(IAgreement.Statuses.Active) &&
                IAgreement(agreementList[i]).checkTimeToCancel(_approveLimit, _matchLimit)
            ) {
                IAgreement(agreementList[i]).rejectAgreement();
            }
        }
    }

    /**
     * @dev Update the state of specific agreement
     * @param _address agreement address
     * @return operation success
     */
    function updateAgreement(address _address) external onlyAdmin() returns(bool _success) {
        return IAgreement(_address).updateAgreement();
    }

    /**
     * @dev Update the states of all agreemnets
     * @return operation success
     */
    function updateAgreements() external onlyAdmin() {
        for (uint256 i = 0; i < agreementList.length; i++) {
            if (IAgreement(agreementList[i]).isStatus(IAgreement.Statuses.Active)) {
                IAgreement(agreementList[i]).updateAgreement();
            }
        }
    }

    /**
    * @dev Update state of exact agreements
    * @param _addresses agreements addresses array
    */
    function batchUpdateAgreements(address[] calldata _addresses) external onlyAdmin() {
        require(_addresses.length <= 256, "FraMain: batch count is greater than 256");
        for (uint256 i = 0; i < _addresses.length; i++) {
            // check in order to prevent revert
            if (IAgreement(_addresses[i]).isStatus(IAgreement.Statuses.Active)) {
                IAgreement(_addresses[i]).updateAgreement();
            }
        }
    }

    /**
     * @dev Block specific agreement
     * @param _address agreement address
     * @return operation success
     */
    function blockAgreement(address _address) external onlyAdmin() returns(bool _success) {
        return IAgreement(_address).blockAgreement();
    }

    /**
     * @dev Remove agreement from list,
     * doesn't affect real agreement contract, just removes handle control
     */
    function removeAgreement(uint _ind) external onlyAdmin() {
        agreementList[_ind] = agreementList[agreementList.length-1];
        agreementList.length--; // Implicitly recovers gas from last element storage
    }

    /**
     * @dev transfer agreement ownership to Fra Factory owner (admin)
     */
    function transferAgreementOwnership(address _address) external onlyAdmin() {
        IAgreement(_address).transferOwnership(owner);
    }

    /**
     * @dev accept agreement ownership by Fra Factory contract
     */
    function claimAgreementOwnership(address _address) external onlyAdmin() {
        IAgreement(_address).claimOwnership();
    }

    /**
     * @dev Returns a full list of existing agreements
     */
    function getAgreementList() external view returns(address[] memory _agreementList) {
        return agreementList;
    }
}
