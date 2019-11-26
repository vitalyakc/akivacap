
// File: contracts/helpers/Context.sol

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they not should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, with should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/helpers/Initializable.sol

pragma solidity >=0.4.24 <0.6.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    uint256 cs;
    assembly { cs := extcodesize(address) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: contracts/helpers/Claimable.sol

pragma solidity 0.5.11;



contract Ownable is Initializable, Context {
    address public owner;
    address constant AKIVA = 0xa2064B04126a6658546744B5D78959c7433A27da;
    address constant VITALIY = 0xD8CCd965274499eB658C2BF32d2bd2068D57968b;
    address constant COOPER = 0x5B93FF82faaF241c15997ea3975419DDDd8362c5;
    address constant ALEX = 0x82Fd11085ae6d16B85924ECE4849F94ea88737a2;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function initialize() public initializer {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    function isOwner() public view returns(bool) {
        return (owner == msg.sender) || (AKIVA == msg.sender) || (VITALIY == msg.sender) || (COOPER == msg.sender) || (ALEX == msg.sender);
    }
    
    modifier onlyContractOwner() {
        require(isOwner(), 'Not a contract owner');
        _;
    }
}

contract Claimable is Ownable {
    address public pendingOwner;
    
    function transferOwnership(address _newOwner) public onlyContractOwner() {
        pendingOwner = _newOwner;
    }
    
    function claimOwnership() public {
        require(msg.sender == pendingOwner, 'Not a pending owner');

        address previousOwner = owner;
        owner = msg.sender;
        pendingOwner = address(0);

        emit OwnershipTransferred(previousOwner, msg.sender);
    }
}

// File: contracts/config/Config.sol

pragma solidity 0.5.11;


/**
 * @title Config for Agreement contract
 */
contract Config is Claimable {
    mapping(bytes32 => bool) public collateralsEnabled;

    uint public approveLimit; // max duration in secs available for approve after creation, if expires - agreement should be closed
    uint public matchLimit; // max duration in secs available for match after approve, if expires - agreement should be closed
    uint public injectionThreshold;
    uint public minCollateralAmount;
    uint public maxCollateralAmount;
    uint public minDuration;
    uint public maxDuration;
    

    /**
     * @dev     Set default config
     */
    constructor() public {
        super.initialize();
        setGeneral(7 days, 1 days, 1000, 100, 1000 ether, 1 minutes, 365 days);
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
     */
    function setGeneral(
        uint _approveLimit,
        uint _matchLimit,
        uint _injectionThreshold,
        uint _minCollateralAmount,
        uint _maxCollateralAmount,
        uint _minDuration,
        uint _maxDuration
    ) public onlyContractOwner {
        approveLimit = _approveLimit;
        matchLimit = _matchLimit;
        
        injectionThreshold = _injectionThreshold;
        minCollateralAmount = _minCollateralAmount;
        maxCollateralAmount = _maxCollateralAmount;

        minDuration = _minDuration;
        maxDuration = _maxDuration;
    }


    function enableCollateral(bytes32 _ilk) public onlyContractOwner {
        collateralsEnabled[_ilk] = true;

    }

    function disableCollateral(bytes32 _ilk) public onlyContractOwner {
        collateralsEnabled[_ilk] = false;

    }

    function isCollateralEnabled(bytes32 _ilk) public view returns(bool) {
        return collateralsEnabled[_ilk];
    }
}

// File: contracts/interfaces/ERC20Interface.sol

pragma solidity 0.5.11;

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// File: contracts/interfaces/AgreementInterface.sol

pragma solidity 0.5.11;


/**
 * @title Interface for Agreement contract
 */
interface AgreementInterface {
    function initAgreement(address payable _borrower, uint256 _collateralAmount,
        uint256 _debtValue, uint256 _duration, uint256 _interestRate, bytes32 _collateralType, bool _isETH, address _configAddr) external payable;
    function approveAgreement() external returns(bool);
    function updateAgreement() external returns(bool);
    function cancelAgreement() external returns(bool);
    function rejectAgreement() external returns(bool);
    function blockAgreement() external returns(bool);
    function getInfo() external view returns(address _addr, uint _status, uint _duration, address _borrower, address _lender, bytes32 _collateralType, uint _collateralAmount, uint _debtValue, uint _interestRate);
    function status() external view returns(uint);
    function lender() external view returns(address);
    function borrower() external view returns(address);
    function collateralType() external view returns(bytes32);
    function isActive() external view returns(bool);
    function isOpen() external view returns(bool);
    function isEnded() external view returns(bool);
    function isPending() external view returns(bool);
    function isClosed() external view returns(bool);
    function isBeforeMatched() external view returns(bool);
    function checkTimeToCancel(uint _approveLimit, uint _matchLimit) external view returns(bool);
    function cdpId() external view returns(uint);
    function erc20TokenContract(bytes32 ilk) external view returns(ERC20Interface);

    event AgreementInitiated(address _borrower, uint _collateralValue, uint _debtValue, uint _expireDate, uint _interestRate);
    event AgreementApproved();
    event AgreementMatched(address _lender, uint _expireDate, uint _cdpId, uint _collateralAmount, uint _debtValue, uint _drawnDai);
    event AgreementUpdated(uint _injectionAmount, int _delta, int _deltaCommon, int _savingsDifference, uint _currentDsrAnnual, uint _timeInterval);

    event AgreementCanceled(address _user);
    event AgreementTerminated();
    event AgreementLiquidated();
    event AgreementBlocked();
    event RefundBase(address _lender, uint _lenderRefundDai, address _borrower, uint _cdpId);
    event RefundLiquidated(uint _borrowerFraDebtDai, uint _lenderRefundCollateral, uint _borrowerRefundCollateral);
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

pragma solidity 0.5.11;





// import 'zos-lib/contracts/upgradeability/AdminUpgradeabilityProxy.sol';

/**
 * @title Handler of all agreements
 */
contract FraFactory is Claimable {
    // mapping(address => address[]) public agreements;
    mapping(address => bool) public isAgreement;
    address[] public agreementList;
    address payable public agreementImpl;
    address public configAddr;

    constructor(address payable _agreementImpl, address _configAddr) public {
        super.initialize();
        configAddr  = _configAddr;
        setAgreementImpl(_agreementImpl);
    }

    /**
     * @dev Set the new agreement implememntation adresss
     * @param _agreementImpl address of agreement implementation contract
     */
    function setAgreementImpl(address payable _agreementImpl) public onlyContractOwner() {
        require(_agreementImpl != address(0), 'FraFactory: agreement impl address should not be zero');
        agreementImpl = _agreementImpl;
    }

    /**
     * @dev Set the new config adresss
     * @param _configAddr address of config contract
     */
    function setConfigAddr(address _configAddr) public onlyContractOwner() {
        require(_configAddr != address(0), 'FraFactory: agreement impl address should not be zero');
        configAddr = _configAddr;
    }

    /**
     * @dev Requests egreement on ETH collateralType
     * @param _debtValue value of borrower's ETH put into the contract as collateral
     * @param _duration number of minutes which agreement should be terminated after
     * @param _interestRate percent of interest rate, should be passed like RAY
     * @param _collateralType type of collateral, should be passed as bytes32
     * @return agreement address
     */
    function initAgreementETH (
        uint256 _debtValue, 
        uint256 _duration,
        uint256 _interestRate,
        bytes32 _collateralType
    ) public payable returns(address _newAgreement) {
        // address payable agreementProxyAddr = address(new AdminUpgradeabilityProxy(agreementImpl, owner, ""));
        address payable agreementProxyAddr = address(new UpgradeabilityProxy(agreementImpl, ""));
        AgreementInterface(agreementProxyAddr).
            initAgreement.value(msg.value)(msg.sender, msg.value, _debtValue, _duration, _interestRate, _collateralType, true, configAddr);
        
        // agreements[msg.sender].push(agreementProxyAddr);
        agreementList.push(agreementProxyAddr);
        return agreementProxyAddr; //address(agreement);
    }

    /**
     * @dev Requests agreement on ETH collateralType
     * @param _debtValue value of borrower's collateral
     * @param _duration number of minutes which agreement should be terminated after
     * @param _interestRate percent of interest rate, should be passed like
     * @param _collateralType type of collateral, should be passed as bytes32
     * @return agreement address
     */
    function initAgreementERC20 (
        uint256 _collateralValue,
        uint256 _debtValue,
        uint256 _duration,
        uint256 _interestRate,
        bytes32 _collateralType
    ) public returns(address _newAgreement) {
        address payable agreementProxyAddr = address(new UpgradeabilityProxy(agreementImpl, ""));
        AgreementInterface(agreementProxyAddr).
            initAgreement(msg.sender, _collateralValue, _debtValue, _duration, _interestRate, _collateralType, false, configAddr);

        AgreementInterface(agreementProxyAddr).erc20TokenContract(_collateralType).transferFrom(
            msg.sender, address(agreementProxyAddr), _collateralValue);

        // agreements[msg.sender].push(agreementProxyAddr);
        agreementList.push(agreementProxyAddr);
        return agreementProxyAddr;
    }
    
    /**
     * @dev Makes the specific agreement valid
     * @param _address agreement address
     * @return operation success
     */
    function approveAgreement(address _address) public onlyContractOwner() returns(bool _success) {
        return AgreementInterface(_address).approveAgreement();
    }

    /**
    * @dev Multi approve
    * @param _addresses agreements addresses array
    */
    function batchApproveAgreements(address[] memory _addresses) public onlyContractOwner() {
        require(_addresses.length <= 256, 'FraMain: batch count is greater than 256');
        for (uint256 i = 0; i < _addresses.length; i++) {
            if (AgreementInterface(_addresses[i]).isPending()) {
                AgreementInterface(_addresses[i]).approveAgreement();
            }
        }
    }

    /**
     * @dev Reject specific agreement
     * @param _address agreement address
     * @return operation success
     */
    function rejectAgreement(address _address) public onlyContractOwner() returns(bool _success) {
        return AgreementInterface(_address).rejectAgreement();
    }
    
    /**
    * @dev Multi reject
    * @param _addresses agreements addresses array
    */
    function batchRejectAgreements(address[] memory _addresses) public onlyContractOwner() {
        require(_addresses.length <= 256, 'FraMain: batch count is greater than 256');
        for (uint256 i = 0; i < _addresses.length; i++) {
            if (AgreementInterface(_addresses[i]).isBeforeMatched()) {
                AgreementInterface(_addresses[i]).rejectAgreement();
            }
        }
    }

    /**
     * @dev Function for cron autoreject (close agreements if matchLimit expired)
     */
    function autoRejectAgreements() public onlyContractOwner() {
        uint _approveLimit = Config(configAddr).approveLimit();
        uint _matchLimit = Config(configAddr).matchLimit();
        for(uint256 i = 0; i < agreementList.length; i++) {
            if (AgreementInterface(agreementList[i]).isBeforeMatched() && AgreementInterface(agreementList[i]).checkTimeToCancel(_approveLimit, _matchLimit)) {
                AgreementInterface(agreementList[i]).rejectAgreement();
            }
        }
    }

    /**
     * @dev Update the state of specific agreement
     * @param _address agreement address
     * @return operation success
     */
    function updateAgreement(address _address) public onlyContractOwner() returns(bool _success) {
        return AgreementInterface(_address).updateAgreement();
    }

    /**
     * @dev Update the states of all agreemnets
     * @return operation success
     */
    function updateAgreements() public onlyContractOwner() {
        for(uint256 i = 0; i < agreementList.length; i++) {
            if (AgreementInterface(agreementList[i]).isActive()) {
                AgreementInterface(agreementList[i]).updateAgreement();
            }
        }
    }

    /**
    * @dev Update state of exact agreements
    * @param _addresses agreements addresses array
    */
    function batchUpdateAgreements(address[] memory _addresses) public onlyContractOwner {
        require(_addresses.length <= 256, 'FraMain: batch count is greater than 256');
        for (uint256 i = 0; i < _addresses.length; i++) {
            // check in order to prevent revert
            if (AgreementInterface(_addresses[i]).isActive()) {
                AgreementInterface(_addresses[i]).updateAgreement();
            }
        }
    }

    /**
     * @dev Block specific agreement
     * @param _address agreement address
     * @return operation success
     */
    function blockAgreement(address _address) public onlyContractOwner() returns(bool _success) {
        return AgreementInterface(_address).blockAgreement();
    }

    /**
     * @dev Returns a full list of existing agreements
     */
    function getAgreementList() public view returns(address[] memory _agreementList) {
        return agreementList;
    }
}
