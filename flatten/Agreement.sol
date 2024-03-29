
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

// File: contracts/helpers/Context.sol

pragma solidity 0.5.12;

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

pragma solidity 0.5.12;


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

// File: contracts/helpers/ClaimableIni.sol

pragma solidity 0.5.12;




/**
 * @title   Claimable contract with initialization inside initializer
 */
contract ClaimableIni is Claimable, Initializable, Context {
    /**
     * @dev Set caller as contract owner
     */
    function initialize() public initializer {
        _setInitialOwner(msg.sender);
    }
}

// File: contracts/mcd/McdAddressesR17.sol

pragma solidity 0.5.12;
/**
 * @title Mcd cdp maker dao system contracts deployed for 17th release
 */
contract McdAddressesR17 {
    uint public constant RELEASE = 17;

    address public constant proxyRegistryAddrMD = 0x64A436ae831C1672AE81F674CAb8B6775df3475C; // used by MakerDao portal oasis
    address constant proxyRegistryAddr = 0x8877152FA31F00eC81b161774209308535af157a;
    // * 0xda657E86db3e76BDa6d88e6a09798F0BBF5bDf75 "Compatible with 5.12 solc", deployed by 0x61de44946D6b809a30D8e6A236157966659f9640 May-16-2019 
    // Argument: 0x13c5d6fa341aa30a006a3e1cc14c6074543d7560, deployed by 0x61de44946D6b809a30D8e6A236157966659f9640 on May-16-2019
    // version: latest by then, compiled by solc 0.5.6. ProxyFactory needs to be deployed too and passed as parameter.
    // * Existing proxy registry: at 0x64a436ae831c1672ae81f674cab8b6775df3475c;  uses solc ^0.4.23 deployed Jun-22-2018
    // argument:  0xe11E3b391F7E8bC47247866aF32AF67Dd58Dc800
    // newly deployed: 0x8877152fa31f00ec81b161774209308535af157a 

    address constant proxyLib  = 0xd1D24637b9109B7f61459176EdcfF9Be56283a7B;  
    address constant proxyLibDsr = 0xc5CC1Dfb64A62B9C7Bb6Cbf53C2A579E2856bf92;
    address constant proxyLibEnd = 0x5652779B00e056d7DF87D03fe09fd656fBc322DF;
    
    address constant cdpManagerAddr = 0x1476483dD8C35F25e568113C5f70249D3976ba21;
    address constant mcdDaiAddr = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa;
    address constant mcdJoinDaiAddr = 0x5AA71a3ae1C0bd6ac27A1f28e1415fFFB6F15B8c;
    address constant mcdVatAddr = 0xbA987bDB501d131f766fEe8180Da5d81b34b69d9;

    address constant mcdJoinEthaAddr  = 0x775787933e92b709f2a3C70aa87999696e74A9F8;
    address constant mcdJoinBataAddr  = 0x2a4C485B1B8dFb46acCfbeCaF75b6188A59dBd0a;
    address constant mcdJoinUsdcaAddr = 0x4c514656E7dB7B859E994322D2b511d99105C1Eb;
    address constant mcdJoinUsdcbAddr = 0xaca10483e7248453BB6C5afc3e403e8b7EeDF314;
    address constant mcdJoinWbtcaAddr = 0xB879c7d51439F8e7AC6b2f82583746A0d336e63F;
    address constant mcdJoinTusdaAddr = 0xe53f6755A031708c87d80f5B1B43c43892551c17;
    address constant mcdJoinZrxaAddr  = 0x85D38fF6a6FCf98bD034FB5F9D72cF15e38543f2;
    address constant mcdJoinKncaAddr  = 0xE42427325A0e4c8e194692FfbcACD92C2C381598;
    address constant mcdJoinManaaAddr = 0xdC9Fe394B27525e0D9C827EE356303b49F607aaF;

    address constant mcdPotAddr  = 0xEA190DBDC7adF265260ec4dA6e9675Fd4f5A78bb;
    address constant mcdSpotAddr = 0x3a042de6413eDB15F2784f2f97cC68C7E9750b2D;
    address constant mcdCatAddr  = 0x0511674A67192FE51e86fE55Ed660eB4f995BDd6;
    address constant mcdJugAddr  = 0xcbB7718c9F39d05aEEDE1c472ca8Bf804b2f1EaD;
    address constant mcdEndAddr  = 0x24728AcF2E2C403F5d2db4Df6834B8998e56aA5F;
    
    address payable constant wethAddr = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
    address payable constant batAddr  = 0x9f8cFB61D3B2aF62864408DD703F9C3BEB55dff7;
    address payable constant usdcAddr = 0xBD84be3C303f6821ab297b840a99Bd0d4c4da6b5;
    address payable constant wbtcAddr = 0x7419f744bBF35956020C1687fF68911cD777f865;
    address payable constant tusdAddr = 0xD6CE59F06Ff2070Dd5DcAd0866A7D8cd9270041a;
    address payable constant zrxAddr  = 0xC2C08A566aD44129E69f8FC98684EAA28B01a6e7;
    address payable constant kncAddr  = 0x9800a0a3c7e9682e1AEb7CAA3200854eFD4E9327;
    address payable constant manaAddr = 0x221F4D62636b7B51b99e36444ea47Dc7831c2B2f;

    address constant mcdIlkRegAddr = 0x6618BD7bBaBFacC518Fdec43542E4a73629B0819;

}

// File: contracts/interfaces/IMcd.sol

pragma solidity 0.5.12;

/**
 * @title Interfaces for maker dao mcd contracts
 */
contract PotLike {
    function dsr() public view returns (uint);
    function chi() public view returns (uint);
    function pie(address) public view returns (uint);
    function drip() public;
    function join(uint) public;
    function exit(uint) public;
}
contract VatLike {
    function ilks(bytes32) public view returns (uint, uint, uint, uint, uint);
    function dai(address) public view returns (uint);
    function urns(bytes32, address) public view returns (uint, uint);
    function hope(address) public;
    function move(address, address, uint) public;
}

contract SpotterLike {
    struct Ilk {
        PipLike pip;
        uint256 mat;
    }
    mapping (bytes32 => Ilk) public ilks;
}

contract JugLike {
    struct Ilk {
        uint256 duty;
        uint256  rho;
    }
    mapping (bytes32 => Ilk) public ilks;
    function drip(bytes32 ilk) external returns (uint);
}
contract PipLike {
    function read() external view returns (bytes32);
    function peek() external returns (bytes32, bool);
}

contract CatLike {
    function ilks(bytes32) public view returns (address, uint, uint);
}

contract ManagerLike {
    mapping (uint => address) public urns;      // CDPId => UrnHandler
}

contract ProxyRegistryLike {
    mapping(address => DSProxyLike) public proxies;
    function build() public returns (address payable);
    function build(address) public returns (address payable);
}

contract DSProxyLike {
    function execute(bytes memory, bytes memory) public payable returns (address, bytes memory);
    function execute(address, bytes memory) public payable returns (bytes memory);
    function setOwner(address) public;
}

contract IlkRegistryLike {
    function pos(bytes32 ilk) public view returns (uint); 
    function gem(bytes32) public view returns (address);
    function join(bytes32) public view returns (address payable);
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

// File: contracts/mcd/McdWrapper.sol

pragma solidity 0.5.12;





/**
 * @title   Agreement multicollateral dai wrapper for maker dao system interaction.
 * @dev     delegates calls to proxy. Oriented to exact MCD release. Current version oriented to 17th release mcd cdp.
 */
contract McdWrapper is McdAddressesR17, RaySupport {
    address payable public proxyAddress;

    /**
     * @dev     Get registered proxy for current caller (msg.sender address)
     */
    function proxy() public view returns (DSProxyLike) {
        return DSProxyLike(proxyAddress);
    }

    /**
     * @dev     transfer exact amount of erc20 tokens, approved beforehand
     * @param   ilk     collateral type
     * @return  IERC20 instance
     */
    function erc20TokenContract(bytes32 ilk) public view returns(IERC20) {
        (,address payable collateralBaseAddress) = _getCollateralAddreses(ilk);
        return IERC20(collateralBaseAddress);
    }

    /**
     * @dev     get amount of dai tokens currently locked in dsr(pot) contract.
     * @return  pie amount of all dai tokens locked in dsr
     */
    function getLockedDai() public view returns(uint256 pie, uint256 pieS) {
        pie = PotLike(mcdPotAddr).pie(address(proxy()));
        pieS = pie.mul(PotLike(mcdPotAddr).chi());
    }

    /**
     * @dev     get dai savings rate
     * @return  dsr value in multiplier format defined by maker dao system. 100 * 10^25 - means 0% dsr. 103 * 10^25 means 3% dsr.
     */
    function getDsr() public view returns(uint) {
        return PotLike(mcdPotAddr).dsr();
    }

    /**
     * @dev     get collateral cost
     * @return  Duty (base rate plus risk premium) in multiplier format, per-second accrual.
     */
    function getIlkDuty(bytes32 _ilkIndex) public view returns (uint) {
        (, uint _duty) = JugLike(mcdJugAddr).ilks(_ilkIndex);
        return _duty;
    }

    /**
     * @dev     Get the equivalent of exact dai amount in terms of collateral type.
     * @dev     Add one more collateral token unit in case if calculated value doesn't cover dai amount
     * @param   ilk         collateral type in bytes32 format
     * @param   daiAmount   dai tokens amount
     * @return  collateral tokens amount worth dai amount
     */
    function getCollateralEquivalent(bytes32 ilk, uint daiAmount) public view returns(uint) {
        uint price = getPrice(ilk);
        uint ethAmount = daiAmount.mul(ONE).div(price);
        return (ethAmount.mul(price).div(ONE) == daiAmount) ? ethAmount : (ethAmount.add(1));
    }

    /**
     * @dev     Get current cdp main info: collateral amount, dai (debt) amount
     * @param   ilk     collateral type in bytes32 format
     * @param   cdpId   cdp ID
     * @return  ink     collateral tokens amount
     *          art     dai debt amount
     */
    function getCdpInfo(bytes32 ilk, uint cdpId) public view returns(uint ink, uint art) {
        address urn = ManagerLike(cdpManagerAddr).urns(cdpId);
        (ink, art) = VatLike(mcdVatAddr).urns(ilk, urn);
    }

    /**
     * @dev     Get collateral token price to USD
     * @param   ilk     collateral type in bytes32 format
     * @return  collateral to USD price
     */
    function getPrice(bytes32 ilk) public view returns(uint) {
        return getSafePrice(ilk).mul(getLiquidationRatio(ilk)).div(ONE);
    }

    /**
     * @dev     Get collateral token safe price to USD. Equals current origin price devided by liquidation ratio
     * @param   ilk     collateral type in bytes32 format
     * @return  collateral to USD price
     */
    function getSafePrice(bytes32 ilk) public view returns(uint) {
        (,, uint spot,,) = VatLike(mcdVatAddr).ilks(ilk);
        return spot;
    }

    /**
     * @dev     Get collateral liquidation ratio. Percent of overcollateralization. If collateral / debt < liauidation ratio - cdp should be autoliquidated
     * @param   ilk     collateral type in bytes32 format
     * @return  liquidation ratio  150 * 10^25 - means 150%
     */
    function getLiquidationRatio(bytes32 ilk) public view returns(uint) {
        (,uint mat) = SpotterLike(mcdSpotAddr).ilks(ilk);
        return mat;
    }

    /**
     * @dev     Check is cdp is unsafe already
     * @param   ilk     collateral type in bytes32 format
     * @param   cdpId   cdp ID
     * @return  true if unsafe
     */
    function isCdpSafe(bytes32 ilk, uint cdpId) public view returns(bool) {
        return getDaiAvailable(ilk, cdpId) > 0;
    }

    /**
     * @dev     Calculate available dai to be drawn in Cdp
     * @param   ilk     collateral type in bytes32 format
     * @param   cdpId   cdp ID
     * @return  dai amount available to be drawn
     */
    function getDaiAvailable(bytes32 ilk, uint cdpId) public view returns(uint) {
        (, uint rate, uint spot,,) = VatLike(mcdVatAddr).ilks(ilk);
        (uint ink, uint art) = VatLike(mcdVatAddr).urns(ilk, ManagerLike(cdpManagerAddr).urns(cdpId));
        return (ink.mul(spot) > art.mul(rate)) ? fromRay(ink.mul(spot).sub(art.mul(rate))) : 0;
    }

    /**
     * @dev     Calculate current cdp collateralization ratio
     * @param   ilk     collateral type in bytes32 format
     * @param   cdpId   cdp ID
     * @return  collateralization ratio
     */
    function getCdpCR(bytes32 ilk, uint cdpId) public view returns(uint) {
        (, uint rate, uint spot,,) = VatLike(mcdVatAddr).ilks(ilk);
        (uint ink, uint art) = VatLike(mcdVatAddr).urns(ilk, ManagerLike(cdpManagerAddr).urns(cdpId));
        (,uint mat) = SpotterLike(mcdSpotAddr).ilks(ilk);
        return ink.mul(spot).mul(mat).div(art.mul(rate));
    }

    /**
     * @dev     Get minimal collateralization ratio for collateral type
     * @param   ilk     collateral type in bytes32 format
     * @return  minimal collateralization ratio
     */
    function getMCR(bytes32 ilk) public view returns(uint) {
        (,uint mat) = SpotterLike(mcdSpotAddr).ilks(ilk);
        return mat;
    }

    /**
     * @dev    init mcd Wrapper, build proxy
     * @param   ilk     collateral type in bytes32 format
     * @param   isEther  true if ether and false if erc-20 token
     */
    function _initMcdWrapper(bytes32 ilk, bool isEther) internal {
        _buildProxy();
        if (!isEther) {
            _approveERC20(ilk, proxyAddress, 2 ** 256 - 1);
        }
        _approveDai(proxyAddress, 2 ** 256 - 1);
    }

    /**
     * @dev    Build proxy for current caller (msg.sender address)
     */
    function _buildProxy() internal {
        proxyAddress = ProxyRegistryLike(proxyRegistryAddr).build();
    }

    /**
     * @dev     Change proxy owner to a new one
     * @param   newOwner new owner address
     */
    function _setOwnerProxy(address newOwner) internal {
        proxy().setOwner(newOwner);
    }

    /**
     * @dev     Lock additional ether as collateral
     * @param   ilk     collateral type in bytes32 format
     * @param   cdp     cdp id
     * @param   wadC    collateral amount to be locked in cdp contract
     */
    function _lockETH(bytes32 ilk, uint cdp, uint wadC) internal {
        bytes memory data;
        (address collateralJoinAddr,) = _getCollateralAddreses(ilk);
        data = abi.encodeWithSignature(
            "lockETH(address,address,uint256)",
            cdpManagerAddr, collateralJoinAddr, cdp);
        (bool success,) = proxyAddress.call.value(wadC)(abi.encodeWithSignature("execute(address,bytes)", proxyLib, data));
        require(success, "failed to lock eth");
    }

    /**
     * @dev     Lock additional erc-20 tokens as collateral
     * @param   ilk     collateral type in bytes32 format
     * @param   cdp     cdp id
     * @param   wadC    collateral amount to be locked in cdp contract
     * @param   transferFrom   collateral tokens should be transfered from caller
     */
    function _lockERC20(bytes32 ilk, uint cdp, uint wadC, bool transferFrom) internal {
        (address collateralJoinAddr,) = _getCollateralAddreses(ilk);
        proxy().execute(
            proxyLib,
            abi.encodeWithSignature(
                "lockGem(address,address,uint256,uint256,bool)",
                cdpManagerAddr, collateralJoinAddr, cdp, wadC, transferFrom));
    }

    /**
     * @dev     Create new cdp with Ether as collateral, lock collateral and draw dai
     * @dev     build new Proxy for a caller before cdp creation
     * @param   ilk     collateral type in bytes32 format
     * @param   wadC    collateral amount to be locked in cdp contract
     * @param   wadD    dai amount to be drawn
     */
    function _openLockETHAndDraw(bytes32 ilk, uint wadC, uint wadD) internal returns (uint cdp) {
        address payable target = proxyAddress;
        (address collateralJoinAddr,) = _getCollateralAddreses(ilk);
        bytes memory data = abi.encodeWithSignature(
            "execute(address,bytes)",
            proxyLib,
            abi.encodeWithSignature(
                "openLockETHAndDraw(address,address,address,address,bytes32,uint256)",
                cdpManagerAddr, mcdJugAddr, collateralJoinAddr, mcdJoinDaiAddr, ilk, wadD));
        assembly {
            let succeeded := call(sub(gas, 5000), target, wadC, add(data, 0x20), mload(data), 0, 0)
            let size := returndatasize
            let response := mload(0x40)
            mstore(0x40, add(response, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            cdp := mload(add(response, 0x60))

            switch iszero(succeeded)
            case 1 {
                // throw if delegatecall failed
                revert(add(response, 0x20), size)
            }
        }
    }

    /**
     * @dev     Create new cdp with ERC-20 tokens as collateral, lock collateral and draw dai
     * @dev     build new Proxy for a caller before cdp creation and approve transferFrom collateral token from Agrrement by Proxy
     * @param   ilk     collateral type in bytes32 format
     * @param   wadC    collateral amount to be locked in cdp contract
     * @param   wadD    dai amount to be drawn
     * @param   transferFrom   collateral tokens should be transfered from caller
     */
    function _openLockERC20AndDraw(bytes32 ilk, uint wadC, uint wadD, bool transferFrom) internal returns (uint cdp) {
        // _approveERC20(ilk, proxyAddress, wadC);
        (address collateralJoinAddr,) = _getCollateralAddreses(ilk);
        bytes memory response = proxy().execute(
            proxyLib,
            abi.encodeWithSignature(
                "openLockGemAndDraw(address,address,address,address,bytes32,uint256,uint256,bool)",
                cdpManagerAddr, mcdJugAddr, collateralJoinAddr, mcdJoinDaiAddr, ilk, wadC, wadD, transferFrom));
        assembly {
            cdp := mload(add(response, 0x20))
        }
    }

    /**
     * @dev     inject(wipe) some amount of dai to cdp from agreement (pay off some amount of dai to cdp)
     * @param   cdp   cdp ID
     * @param   wad   amount of dai tokens
     */
    function _injectToCdpFromDsr(uint cdp, uint wad) internal returns(uint injectionWad) {
        injectionWad = _unlockDai(wad);
        proxy().execute(
            proxyLib,
            abi.encodeWithSignature(
                "wipe(address,address,uint256,uint256)",
                cdpManagerAddr, mcdJoinDaiAddr, cdp, injectionWad));
    }

    /**
     * @dev     draw dai into cdp contract, if not enough - draw max available dai
     * @param   ilk   collateral type in bytes32 format
     * @param   cdp   cdp ID
     * @param   wad   amount of dai tokens
     * @return  drawn dai amount
     */
    function _drawDaiToCdp(bytes32 ilk, uint cdp, uint wad) internal returns (uint drawnDai) {
        JugLike(mcdJugAddr).drip(ilk);
        uint maxToDraw = getDaiAvailable(ilk, cdp);
        drawnDai = wad > maxToDraw ? maxToDraw : wad;
        proxy().execute(
            proxyLib,
            abi.encodeWithSignature(
                "draw(address,address,address,uint256,uint256)",
                cdpManagerAddr, mcdJugAddr, mcdJoinDaiAddr, cdp, drawnDai));
    }
    /**
     * @dev     lock dai tokens to dsr(pot) contract.
     * @dev     approves this amount of dai tokens to proxy before locking
     * @param   wad amount of dai tokens
     */
    function _lockDai(uint wad) internal {
        proxy().execute(
            proxyLibDsr,
            abi.encodeWithSignature(
                "join(address,address,uint256)",
                mcdJoinDaiAddr, mcdPotAddr, wad));
    }

    /**
     * @dev     unlock dai tokens from dsr(pot) contract.
     * @param   wad amount of dai tokens
     * @return  actually unlocked amount of dai
     */
    function _unlockDai(uint wad) internal returns(uint unlockedWad) {
        uint _balanceBefore = _balanceDai(address(this));
        proxy().execute(
            proxyLibDsr,
            abi.encodeWithSignature(
                "exit(address,address,uint256)",
                mcdJoinDaiAddr, mcdPotAddr, wad));
        unlockedWad = _balanceDai(address(this)).sub(_balanceBefore);
    }

    /**
     * @dev     unlock all dai tokens from dsr(pot) contract.
     * @return  pie amount of all dai tokens was unlocked in fact
     */
    function _unlockAllDai() internal returns(uint pie) {
        uint _balanceBefore = _balanceDai(address(this));
        proxy().execute(
            proxyLibDsr,
            abi.encodeWithSignature(
                "exitAll(address,address)",
                mcdJoinDaiAddr, mcdPotAddr));
        pie = _balanceDai(address(this)).sub(_balanceBefore);
    }

    /**
     * @dev     Approve exact amount of dai tokens for transferFrom
     * @param   to      address allowed to call transferFrom
     * @param   amount  tokens amount for approval
     */
    function _approveDai(address to, uint amount) internal returns(bool) {
        IERC20(mcdDaiAddr).approve(to, amount);
        return true;
    }

    /**
     * @dev     Approve exact amount of erc20 tokens for transferFrom
     * @param   ilk     collateral type
     * @param   to      address allowed to call transferFrom
     * @param   amount  tokens amount for approval
     */
    function _approveERC20(bytes32 ilk, address to, uint amount) internal returns(bool) {
        erc20TokenContract(ilk).approve(to, amount);
        return true;
    }

    /**
     * @dev     Transfer exact amount of dai tokens
     * @param   to      address of recepient
     * @param   amount  tokens amount
     */
    function _transferDai(address to, uint amount) internal returns(bool) {
        IERC20(mcdDaiAddr).transfer(to, amount);
        return true;
    }

    /**
     * @dev     Transfer exact amount of erc20 tokens
     * @param   ilk     collateral type
     * @param   to      address of recepient
     * @param   amount  tokens amount
     */
    function _transferERC20(bytes32 ilk, address to, uint amount) internal returns(bool) {
        erc20TokenContract(ilk).transfer(to, amount);
        return true;
    }

    /**
     * @dev     Transfer exact amount of dai tokens, approved beforehand
     * @param   from    address of spender
     * @param   to      address of recepient
     * @param   amount  tokens amount
     */
    function _transferFromDai(address from, address to, uint amount) internal returns(bool) {
        return IERC20(mcdDaiAddr).transferFrom(from, to, amount);
    }

    /**
     * @dev     Transfer exact amount of erc20 tokens, approved beforehand
     * @param   ilk     collateral type
     * @param   from    address of spender
     * @param   to      address of recepient
     * @param   amount  tokens amount
     */
    function _transferFromERC20(bytes32 ilk, address from, address to, uint amount) internal returns(bool) {
        return erc20TokenContract(ilk).transferFrom(from, to, amount);
    }

    /**
     * @dev     Transfer Cdp ownership to guy's proxy
     * @param   cdp     cdp ID
     * @param   guy     address, ownership should be transfered to
     */
    function _transferCdpOwnershipToProxy(uint cdp, address guy) internal {
        proxy().execute(
            proxyLib,
            abi.encodeWithSignature(
                "giveToProxy(address,address,uint256,address)",
                proxyRegistryAddrMD, cdpManagerAddr, cdp, guy));
    }

    /**
     * @dev     Get balance of dai tokens
     * @param   addr      address
     */
    function _balanceDai(address addr) internal view returns(uint) {
        return IERC20(mcdDaiAddr).balanceOf(addr);
    }

    /**
     * @dev     Transfer exact amount of erc20 tokens, approved beforehand
     * @param   ilk     collateral type 
     * @return  token adapter address
     * @return  token erc20 contract address
     */
    function _getCollateralAddreses(bytes32 ilk) internal view returns(address, address payable) {

        if (ilk == "ETH-A") {
            return (mcdJoinEthaAddr, wethAddr);
        }
        if (ilk == "BAT-A") {
            return (mcdJoinBataAddr, batAddr);
        }
        if (ilk == "WBTC-A") {
            return (mcdJoinWbtcaAddr, wbtcAddr);
        }
        if (ilk == "USDC-A") {
            return (mcdJoinUsdcaAddr, usdcAddr);
        }
        if (ilk == "USDC-B") {
            return (mcdJoinUsdcbAddr, usdcAddr);
        }

        // actual registry
        address _gem = IlkRegistryLike(mcdIlkRegAddr).gem(ilk);
        address payable _join = IlkRegistryLike(mcdIlkRegAddr).join(ilk);
        return (_gem, _join);        
    }
    
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

// File: contracts/Agreement.sol

pragma solidity 0.5.12;







/**
 * @title Base Agreement contract
 * @dev Contract will be deployed only once as logic(implementation), proxy will be deployed by FraFactory for each agreement as storage
 */
contract Agreement is IAgreement, ClaimableIni, McdWrapper {
    using SafeMath for uint;
    using SafeMath for int;
    
    struct Asset {
        uint collateral;
        uint dai;
    }
    
    uint constant internal YEAR_SECS = 365 days;

    /**
     * Agreement status timestamp snapshots
     */
    mapping(uint => uint) public statusSnapshots;

    /**
     * Agreement participants assets
     */
    mapping(address => Asset) public assets;

    /**
     * Agreement status
     */
    Statuses public status;

    /**
     * Type the agreement is closed by
     */
    ClosedTypes public closedType;

    /**
     * Config contract address
     */
    address public configAddr;

    /**
     * True if agreement collateral is ether
     */
    bool public isETH;

    /**
     * Agreement risky marker
     */
    bool public isRisky;

    /**
     * Aggreement duration in seconds
     */
    uint256 public duration;

    /**
     * Agreement expiration date. Is calculated during match
     */
    uint256 public expireDate;

    /**
     * Borrower address
     */
    address payable public borrower;

    /**
     * Lender address
     */
    address payable public lender;

    /**
     * Bytes32 representation of collateral type like ETH-A
     */
    bytes32 public collateralType;

    /**
     * Collateral amount
     */
    uint256 public collateralAmount;

    /**
     * Dai debt amount of CDP at the last update
     */
    uint256 public cdpDebtValue;

    /**
     * Fixed intereast rate %
     */
    uint256 public interestRate;

    /**
     * Vault (CDP) id in maker dao contracts
     */
    uint256 public cdpId;

    /**
     * Last time the agreement was updated
     */
    uint256 public lastCheckTime;

    /**
     * Total amount drawn to cdp while paying off borrower's agreement debt
     */
    uint public drawnTotal;

    /**
     * Total amount injected to cdp during paying off lender's agreement debt
     */
    uint public injectedTotal;

    /**
     * Delta shows user's debt (ray units)
     * if delta < 0 - it is borrower's debt to lender
     * if delta > 0 - it is lender's debt to borrower
     */
    int public delta;

    /**
     * shows borrower's unpaid fee debt, in RAY 
     */
    uint public feeAccum;

    /**
     * shows paid fee in DAI
     */
    uint public feePaidTotal;

    /**
     * @dev  Grants access only to agreement's borrower
     */
    modifier onlyBorrower() {
        require(msg.sender == borrower, "Agreement: Accessible only for borrower");
        _;
    }

    /**
     * @dev  Grants access only if agreement has appropriate status
     * @param   _status status should be checked with
     */
    modifier hasStatus(Statuses _status) {
        require(status == _status, "Agreement: Agreement status is incorrect");
        _;
    }

    /**
     * @dev  Grants access only if agreement has status before requested one
     * @param   _status check before status
     */
    modifier beforeStatus(Statuses _status) {
        require(status < _status, "Agreement: Agreement status is not before requested one");
        _;
    }

    /**
     * @dev  Initialize new agreement
     * @param   _borrower       borrower address
     * @param   _collateralAmount value of borrower's collateral amount put into the contract as collateral or approved to transferFrom
     * @param   _debtValue      value of debt
     * @param   _duration       number of seconds which agreement should be terminated after
     * @param   _interestRate   percent of interest rate, should be passed like RAY
     * @param   _collateralType type of collateral, should be passed as bytes32
     * @param   _isETH          true if ether and false if erc-20 token
     * @param   _configAddr     config contract address
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
    ) public payable initializer {
        ClaimableIni.initialize();

        require(Config(_configAddr).isCollateralEnabled(_collateralType), "Agreement: collateral type is currencly disabled");
        require(_debtValue > 0, "Agreement: debt is zero");
        require(
            (_collateralAmount > Config(_configAddr).minCollateralAmount()) &&
            (_collateralAmount < Config(_configAddr).maxCollateralAmount()), "Agreement: collateral value does not match min and max");
        require(
            (_interestRate > ONE) &&
            (_interestRate <= ONE * 2), "Agreement: interestRate should be between 0 and 100 %");
        require(
            (_duration > Config(_configAddr).minDuration()) &&
            (_duration < Config(_configAddr).maxDuration()), "Agreement: duration value does not match min and max");
        require(!_isETH || msg.value == _collateralAmount, "Agreement: Actual ether sent value is not correct");
    
        configAddr = _configAddr;
        isETH = _isETH;
        borrower = _borrower;
        cdpDebtValue = _debtValue;
        duration = _duration;
        interestRate = _interestRate;
        collateralAmount = _collateralAmount;
        collateralType = _collateralType;

        _nextStatus();
        _initMcdWrapper(collateralType, isETH);
        emit AgreementInitiated(borrower, collateralAmount, cdpDebtValue, duration, interestRate);

        _monitorRisky();
    }

    /**
     * @dev Approve the agreement. Only for contract owner (FraFactory)
     * @return Operation success
     */
    function approveAgreement() external onlyContractOwner hasStatus(Statuses.Pending) returns(bool _success) {
        _nextStatus();
        emit AgreementApproved();

        return true;
    }

    /**
     * @dev Match lender to the agreement.
     * @return Operation success
     */
    function matchAgreement() external hasStatus(Statuses.Open) returns(bool _success) {
        _nextStatus();
        expireDate = now.add(duration);
        lender = msg.sender;
        lastCheckTime = now;

        // transfer dai from lender to agreement & lock lender's dai to dsr
        _transferFromDai(msg.sender, address(this), cdpDebtValue);
        _lockDai(cdpDebtValue);

        if (isETH) {
            cdpId = _openLockETHAndDraw(collateralType, collateralAmount, cdpDebtValue);
        } else {
            cdpId = _openLockERC20AndDraw(collateralType, collateralAmount, cdpDebtValue, true);
        }
        uint drawnDai = _balanceDai(address(this));
        // due to the lack of preceision in mcd cdp contracts drawn dai can be less by 1 dai wei

        emit AgreementMatched(lender, expireDate, cdpId, collateralAmount, cdpDebtValue, drawnDai);
        _pushDaiAsset(borrower, cdpDebtValue < drawnDai ? cdpDebtValue : drawnDai);

        return true;
    }

    /**
     * @dev     Update Agreement state. Calls needed function according to the expireDate
     *          (terminates or liquidated or updates the agreement)
     * @return  Operation success
     */
    function updateAgreement() external onlyContractOwner hasStatus(Statuses.Active) returns(bool _success) {
        if (now > expireDate) {
            _closeAgreement(ClosedTypes.Ended);
            _updateAgreementState(true);
            return true;
        }
        if (!isCdpSafe(collateralType, cdpId)) {
            _closeAgreement(ClosedTypes.Liquidated);
            _updateAgreementState(true);
            return true;
        }
        _updateAgreementState(false);
        return true;
    }

    /**
     * @dev  Cancel agreement by borrower before it is matched, change status to the correspondant one, refund
     * @return  Operation success
     */
    function cancelAgreement() external onlyBorrower beforeStatus(Statuses.Active) returns(bool _success)  {
        _closeAgreement(ClosedTypes.Cancelled);
        //push to lenders internal wallet collateral locked in agreement
        _pushCollateralAsset(lender, collateralAmount);
        return true;
    }

    /**
     * @dev  Reject agreement by admin or cron job before it is matched, change status to the correspondant one, refund
     * @return  Operation success
     */
    function rejectAgreement() external onlyContractOwner beforeStatus(Statuses.Active) returns(bool _success)  {
        _closeAgreement(ClosedTypes.Cancelled);
        //push to lenders internal wallet collateral locked in agreement
        _pushCollateralAsset(lender, collateralAmount); 
        return true;
    }

    /**
     * @dev  Block active agreement, change status to the correspondant one, refund
     * @return  Operation success
     */
    function blockAgreement() external hasStatus(Statuses.Active) onlyContractOwner returns(bool _success)  {
        _closeAgreement(ClosedTypes.Blocked);
        _refund();
        return true;
    }

    /**
     * @dev  Lock additional ether as collateral to agreement cdp contract
     * @param   _amount collateral amount for additional lock
     * @return  Operation success
     */
    function lockAdditionalCollateral(uint _amount) external payable onlyBorrower beforeStatus(Statuses.Closed) returns(bool _success)  {
        if (!isETH) {
            erc20TokenContract(collateralType).transferFrom(msg.sender, address(this), _amount);
        }
        if (isStatus(Statuses.Active)) {
            if (isETH) {
                require(msg.value == _amount, "Agreement: ether sent doesn\'t coinside with required");
                _lockETH(collateralType, cdpId, msg.value);
            } else {
                _lockERC20(collateralType, cdpId, _amount, true);
            }
        }
        collateralAmount = collateralAmount.add(_amount);
        emit AdditionalCollateralLocked(_amount);
        _monitorRisky();
        return true;
    }

    /**
     * @dev  Withdraw dai to user's external wallet
     * @param   _amount dai amount for withdrawal
     */
    function withdrawDai(uint _amount) external {
        _popDaiAsset(msg.sender, _amount);
        _transferDai(msg.sender, _amount);
    }

    /**
     * @dev  Withdraw collateral to user's (msg.sender) external wallet from internal wallet
     * @param   _amount collateral amount for withdrawal
     */
    function withdrawCollateral(uint _amount) external {
        _popCollateralAsset(msg.sender, _amount);
        if (isETH) {
            msg.sender.transfer(_amount);
        } else {
            _transferERC20(collateralType, msg.sender, _amount);
        }
    }

    /**
     * @dev     Withdraw accidentally locked ether in the contract, can be called only after agreement is closed and all assets are refunded
     *          Check the current balance is more than users ether assets, and withdraw the remaining ether
     * @param   _to address should be withdrawn to
     */
    function withdrawRemainingEth(address payable _to) external hasStatus(Statuses.Closed) onlyContractOwner {
        uint _remainingEth = isETH ?
            address(this).balance.sub(assets[borrower].collateral.add(assets[lender].collateral)) :
            address(this).balance;
        require(_remainingEth > 0, "Agreement: the remaining balance available for withdrawal is zero");
        _to.transfer(_remainingEth);
    }

    /**
     * @dev     Get agreement main info
     */
    function getInfo() external view returns(
        address _addr,
        uint _status,
        uint _closedType,
        uint _duration,
        address _borrower,
        address _lender,
        bytes32 _collateralType,
        uint _collateralAmount,
        uint _debtValue,
        uint _interestRate, // per sec
        bool _isRisky
    ) {
        _addr = address(this);
        _status = uint(status);
        _closedType = uint(closedType);
        _duration = duration;
        _borrower = borrower;
        _lender = lender;
        _collateralType = collateralType;
        _collateralAmount = collateralAmount;
        _debtValue = cdpDebtValue;
        _interestRate = interestRate;
        _isRisky = isRisky;
    }

    /**
     * @dev     Get user assets available for withdrawal
     * @param   _holder address of lender or borrower
     * @return  collateral amount
     * @return  dai amount
     */
    function getAssets(address _holder) public view returns(uint,uint) {
        return (assets[_holder].collateral, assets[_holder].dai);
    }

    /**
     * @dev     Check if agreement has appropriate status
     * @param   _status status should be checked with
     */
    function isStatus(Statuses _status) public view returns(bool) {
        return status == _status;
    }

    /**
     * @dev     Check if agreement has status before requested one
     * @param   _status check before status
     */
    function isBeforeStatus(Statuses _status) public view returns(bool) {
        return status < _status;
    }

    /**
     * @dev     Check if agreement is closed with appropriate type
     * @param   _type type should be checked with
     */
    function isClosedWithType(ClosedTypes _type) public view returns(bool) {
        return isStatus(Statuses.Closed) && (closedType == _type);
    }

    /**
     * @dev     Borrower debt according to FRA
     */
    function borrowerFraDebt() public view returns(uint) {
        return (delta < 0) ? uint(fromRay(-delta)) : 0;
    }

    /**
     * @dev     check whether pending or open agreement should be canceled automatically by cron
     * @param   _approveLimit approve limit secods
     * @param   _matchLimit match limit secods
     * @return  true if should be cancelled
     */
    function checkTimeToCancel(uint _approveLimit, uint _matchLimit) public view returns(bool){
        if ((isStatus(Statuses.Pending) && now > statusSnapshots[uint(Statuses.Pending)].add(_approveLimit)) ||
            (isStatus(Statuses.Open) && now > statusSnapshots[uint(Statuses.Open)].add(_matchLimit))
        ) {
            return true;
        }
    }

    /**
     * @dev     get collateralization ratio, if cdp is already opened - get cdp CR, if no - calculate according to agreement initial parameters
     * @return  collateralization ratio in RAY
     */
    function getCR() public view returns(uint) {
        return cdpId > 0 ? getCdpCR(collateralType, cdpId) : collateralAmount.mul(getPrice(collateralType)).div(cdpDebtValue);
    }

    /**
     * @dev     get collateralization ratio buffer (difference between current CR and minimal one)
     * @return  buffer percents
     */
    function getCRBuffer() public view returns(uint) {
        return getCR() <= getMCR(collateralType) ? 0 : getCR().sub(getMCR(collateralType)).mul(100).div(ONE);
    }

    /**
     * @dev     get address of Dai token contract
     * @return  dai address
     */
    function getDaiAddress() public view returns(address) {
        return mcdDaiAddr;
    }

    /**
    * @dev      Save timestamp for current status
    */
    function _doStatusSnapshot() internal {
        statusSnapshots[uint(status)] = now;
    }

    /**
     * @dev     Close agreement
     * @param   _closedType closing type
     * @return  Operation success
     */
    function _closeAgreement(ClosedTypes _closedType) internal returns(bool _success) {
        _switchStatusClosedWithType(_closedType);

        emit AgreementClosed(uint(_closedType), msg.sender);
        return true;
    }

    /**
     * @dev     Updates the state of Agreement
     * @param   _isLastUpdate true if the agreement is going to be terminated, false otherwise
     * @return  Operation success
     */
    function _updateAgreementState(bool _isLastUpdate) internal returns(bool _success) {
        uint timeInterval = (_isLastUpdate ? expireDate : now).sub(lastCheckTime);
        uint injectionAmount;
        uint drawnDai;
        uint currentDebt;
        int  savingsDifference;
        // uint currDuty     = getIlkDuty(collateralType); // warn about change in pricing
  
        uint dsrEff = rpow(getDsr(), timeInterval, ONE);
        uint firEff = rpow(interestRate, timeInterval, ONE);
        if(getDsr() > interestRate ) 
        {                       // lender owes to borrower, savingsDiff >0
            savingsDifference = int(cdpDebtValue.mul( dsrEff.sub(firEff) ));
        } else {                // borrower owes to lender, savingsDiff <0
            savingsDifference = -int(cdpDebtValue.mul( firEff.sub(dsrEff) ));
        }

        delta = delta.add(savingsDifference);
        currentDebt = uint(fromRay(delta < 0 ? -delta : delta)); // and this is borrower debt

        if (currentDebt >= (_isLastUpdate ? 1 : Config(configAddr).injectionThreshold())) {    
            if (delta < 0) {  // if delta < 0 - currentDebt is borrower's debt to lender
                drawnDai = _drawDaiToCdp(collateralType, cdpId, currentDebt);
                if (drawnDai > 0) 
                {   
                    _pushDaiAsset(lender, drawnDai); // push to internal wallet
                    delta = delta.add(int(toRay(drawnDai)));
                    drawnTotal = drawnTotal.add(drawnDai);
                }
            } else {          // delta > 0 - currentDebt is lender's debt to borrower
                injectionAmount = _injectToCdpFromDsr(cdpId, currentDebt);
                delta = delta.sub(int(toRay(injectionAmount)));
                injectedTotal = injectedTotal.add(injectionAmount);
            }
        }        
        
        uint feeFrac =  rpow(Config(configAddr).acapFee(), timeInterval, ONE).sub(ONE);
        uint nowFee = cdpDebtValue.mul(feeFrac);
        feeAccum = feeAccum.add(nowFee); 
        uint feePay = fromRay(feeAccum);
        if ( feePay > Config(configAddr).injectionThreshold() || _isLastUpdate)  {
            drawnDai = _drawDaiToCdp(collateralType, cdpId, feePay);
            if (drawnDai > 0) 
            {
                _pushDaiAsset(Config(configAddr).acapAddr(), drawnDai); 
                drawnTotal   = drawnTotal.add(drawnDai);
                feePaidTotal = feePaidTotal.add(drawnDai);
                feeAccum     = feeAccum.sub(drawnDai);
            }
        }   

        emit AgreementUpdated(savingsDifference, delta, timeInterval, drawnDai, injectionAmount);
        
        // for the next iteration, last debt value and time
        lastCheckTime = now;
        (, cdpDebtValue) = getCdpInfo(collateralType, cdpId); // update new starting debt value for the next update
        
        _monitorRisky();
        if (_isLastUpdate)
            _refund();
    
        return true;
    }

    /**
     * @dev     Monitor and set up or set down risky marker
     */
    function _monitorRisky() internal {
        bool _isRisky = getCRBuffer() <= Config(configAddr).riskyMargin();
        if (isRisky != _isRisky) {
            isRisky = _isRisky;
            emit RiskyToggled(_isRisky);
        }
    }

    /**
     * @dev     Refund agreement, push dai to lender assets, transfer cdp ownership to borrower if debt is payed
     * @return  Operation success
     */
    function _refund() internal {
        _pushDaiAsset(lender, _unlockAllDai());
        _transferCdpOwnershipToProxy(cdpId, borrower);
        emit CdpOwnershipTransferred(borrower, cdpId);
    }

    /**
     * @dev     Serial status transition
     */
    function _nextStatus() internal {
        _switchStatus(Statuses(uint(status) + 1));
    }

    /**
    * @dev      switch to exact status
    * @param    _next status that should be switched to
    */
    function _switchStatus(Statuses _next) internal {
        status = _next;
        _doStatusSnapshot();
    }

    /**
    * @dev      switch status to closed with exact type
    * @param    _closedType closing type
    */
    function _switchStatusClosedWithType(ClosedTypes _closedType) internal {
        _switchStatus(Statuses.Closed);
        closedType = _closedType;
    }

    /**
     * @dev     Add collateral to user's internal wallet
     * @param   _holder user's address
     * @param   _amount collateral amount to push
     */
    function _pushCollateralAsset(address _holder, uint _amount) internal {
        assets[_holder].collateral = assets[_holder].collateral.add(_amount);
        emit AssetsCollateralPush(_holder, _amount, collateralType);
    }

    /**
     * @dev     Add dai to user's internal wallet
     * @param   _holder user's address
     * @param   _amount dai amount to push
     */
    function _pushDaiAsset(address _holder, uint _amount) internal {
        assets[_holder].dai = assets[_holder].dai.add(_amount);
        emit AssetsDaiPush(_holder, _amount);
    }

    /**
     * @dev     Take away collateral from user's internal wallet
     * @param   _holder user's address
     * @param   _amount collateral amount to pop
     */
    function _popCollateralAsset(address _holder, uint _amount) internal {
        assets[_holder].collateral = assets[_holder].collateral.sub(_amount);
        emit AssetsCollateralPop(_holder, _amount, collateralType);
    }

    /**
     * @dev     Take away dai from user's internal wallet
     * @param   _holder user's address
     * @param   _amount dai amount to pop
     */
    function _popDaiAsset(address _holder, uint _amount) internal {
        assets[_holder].dai = assets[_holder].dai.sub(_amount);
        emit AssetsDaiPop(_holder, _amount);
    }

    function() external payable {}
}
