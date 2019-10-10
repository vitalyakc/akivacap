
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
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function initialize() public initializer {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }
    
    modifier onlyContractOwner() {
        require(owner == msg.sender, 'Not a contract owner');
        _;
    }
}

contract Claimable is Ownable {
    address internal pendingOwner;
    
    function transferOwnership(address _newOwner) public onlyContractOwner() {
        pendingOwner = _newOwner;
    }
    
    function claimOwnership() public {
        require(msg.sender == pendingOwner, 'Not a pending owner');
        owner = msg.sender;
        pendingOwner = address(0);
    }
}

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
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        assert(!(a > 0 && b > INT256_MIN - a));  // underflow
        assert(!(a < 0 && b < INT256_MAX - a));  // overflow

        return a - b;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        assert(!(a > 0 && b > INT256_MAX - a));  // overflow
        assert(!(a < 0 && b < INT256_MIN - a));  // underflow

        return a + b;
    }

    function mul(int256 a, int256 b) internal pure returns (int256) {
        if (a == 0) {
            return 0;
        }
        int256 c = a * b;
        assert(c / a == b);
        return c;
    }


}

// File: contracts/config/Config.sol

pragma solidity 0.5.11;

/**
 * @title Config for Agreement contract
 */
contract Config {
    uint constant YEAR_SECS = 365 days;
    uint public approveLimit; // max duration in secs available for approve after creation, if expires - agreement should be closed
    uint public matchLimit; // max duration in secs available for match after approve, if expires - agreement should be closed
    uint public injectionThreshold;
    uint public minCollateralAmount;
    uint public maxCollateralAmount;

    /**
     * @dev     Set defailt config
     */
    function _initConfig() internal {
        _setConfig(24, 24, 2, 100, 100 ether);
    }

    /**
     * @dev     set sonfig according to parameters
     * @param   _approveLimitHours      max duration available for approve after creation, if expires - agreement should be closed
     * @param   _matchLimitHours        max duration available for match after approve, if expires - agreement should be closed
     * @param   _injectionThreshold     minimal threshold permitted for injection
     * @param   _minCollateralAmount    min amount
     * @param   _maxCollateralAmount    max amount
     */
    function _setConfig(uint _approveLimitHours, uint _matchLimitHours,
        uint _injectionThreshold, uint _minCollateralAmount, uint _maxCollateralAmount) internal {

        approveLimit = _approveLimitHours * 1 hours;
        matchLimit = _matchLimitHours * 1 hours;
        injectionThreshold = _injectionThreshold;
        minCollateralAmount = _minCollateralAmount;
        maxCollateralAmount = _maxCollateralAmount;
    }

    
}

// File: contracts/config/McdAddresses.sol

pragma solidity 0.5.11;

/**
 * @title Mcd cdp maker dao system contracts deployed for 6th release
 */
contract McdAddressesR6 {
    uint public constant RELEASE = 6;
    address public constant proxyRegistryAddr = 0xda657E86db3e76BDa6d88e6a09798F0BBF5bDf75;
    address public constant proxyLib = 0x3B444f91f86d162C991D5EC048464C93b0890aE2;
    address public constant cdpManagerAddr = 0xd2e8d886Bc185Df6f437E22DF923DdF419daD4B8;
    address public constant mcdDaiAddr = 0xc7cC3413f169a027dccfeffe5208Ca4f38eF0c40;
    address public constant mcdJoinDaiAddr = 0x7bb403AAE0330F1aCAAd8F2a06ebe4b4e4784418;
    address public constant mcdVatAddr = 0xaCdd1ee0F74954Ed8F0aC581b081B7b86bD6aad9;
    address public constant getCdpsAddr = 0x81dD44A647dAC3e052D8EAf2C9F11ED3a9941DD7;
    address public constant mcdJoinEthaAddr = 0x75f0660705EF0dB9adde85337980F579626643af;
    address public constant mcdJoinEthbAddr = 0xD53f951608e7F9feB3763dc2fAf89FaAA545d8F2;
    address public constant mcdJoinCol1aAddr = 0xC4E81c9690Bb664d682826E3415134C23d08E7Bb;
    address public constant mcdPotAddr = 0xBb3571B3F1151a2f0545a297363ACddC87099FF5;
    address public constant mcdSpotAddr = 0x888C83473C72467C2D5289dCD6Ab26cCb8b00bd0;
    address public constant mcdCatAddr = 0x81F7Aa9c1570de564eB511b3a1e57DAe558C65b5;
    address public constant mcdJugAddr = 0x9f45059B6191B550356A92457ce5fFd7242FBb9B;
    
    address payable public constant wethAddr = 0xb39862D7D1b11CD9B781B1473e142Cbb545A6871;
    address payable public constant col1Addr = 0xC644e83399F3c0b4011D3dd3C61bc8b1617253E5;
}

/**
 * @title Mcd cdp maker dao system contracts deployed for 13th release
 */
contract McdAddressesR13 {
    uint public constant RELEASE = 13;
    // address public constant proxyRegistryAddr = 0x64A436ae831C1672AE81F674CAb8B6775df3475C;
    address public constant proxyRegistryAddr = 0xda657E86db3e76BDa6d88e6a09798F0BBF5bDf75;
    address public constant proxyLib = 0xfD561c946cD13A82962E1a28978b305560Ccd009;
    address public constant cdpManagerAddr = 0x89DB53B3A774e6c29c4Db596281F3CA3E1247610;
    address public constant mcdDaiAddr = 0x98738f2Ca303a7e8BF22B252E4418f2B14BbdFa2;
    address public constant mcdJoinDaiAddr = 0xa9aC4aE91F3e933CBB12a4229c425B7CFd3Ac458;
    address public constant mcdVatAddr = 0x1CC5ABe5C0464F3af2a10df0c711236a8446BF75;
    address public constant getCdpsAddr = 0x4EF9C49AAe6419F3E2663D31aa104341b8Ad3DB1;
    address public constant mcdJoinEthaAddr = 0xAAf1114dB4b7aB3cF67015358326e0805af3AEA5;
    address public constant mcdJoinEthbAddr = 0x85F16b70d62e04f4Cdcd2b1378E657E563479732;
    address public constant mcdJoinZrxaAddr = 0xCd0B608aAf35C81E6E3f132425244671948e16e9;
    address public constant mcdPotAddr = 0x3d9AfbED6Ee2C2d17749B003875EAa38c0ce0c7f;
    address public constant mcdSpotAddr = 0xa5aa0fB23322FF0A60832BB08cd0d360a71413C1;
    address public constant mcdCatAddr = 0x48187b8b3ED3be81284C0a686A180B2b595e6d19;
    address public constant mcdJugAddr = 0x5a4e9bb2407cf12624DBF966FE88aB77c93FBf74;
    
    address payable public constant wethAddr = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
    address payable public constant zrxAddr = 0x18392097549390502069C17700d21403EA3C721A;
}

/**
 * @title Mcd cdp maker dao system contracts deployed for 14th release
 */
contract McdAddressesR14 {
    uint public constant RELEASE = 14;
    // address public constant proxyRegistryAddr = 0x64A436ae831C1672AE81F674CAb8B6775df3475C;
    address public constant proxyRegistryAddr = 0xda657E86db3e76BDa6d88e6a09798F0BBF5bDf75;
    address public constant proxyLib = 0xc21274797A01E133Ebd9D79b23498eDbD7166137;
    address public constant proxyLibDsr = 0x8b31eF27d7708a7e24b43D352e837b9486B2b961;
    address public constant proxyLibEnd = 0x45da208FB53A8d60EeEA2A055908ee82d0a6485A;
    address public constant cdpManagerAddr = 0x1Cb0d969643aF4E929b3FafA5BA82950e31316b8;
    address public constant mcdDaiAddr = 0x1f9BEAf12D8db1e50eA8a5eD53FB970462386aA0;
    address public constant mcdJoinDaiAddr = 0x61Af28390D0B3E806bBaF09104317cb5d26E215D;
    address public constant mcdVatAddr = 0x6e6073260e1a77dFaf57D0B92c44265122Da8028;
    address public constant getCdpsAddr = 0xB5907a51e3b747DbF9D5125aB77efF3a55e50b7d;
    address public constant mcdJoinEthaAddr = 0xc3AbbA566bb62c09b7f94704d8dFd9800935D3F9;
    address public constant mcdJoinEthbAddr = 0x960Fb16406B56FDd7e2800fCA5457F524a393877;
    address public constant mcdJoinZrxaAddr = 0x79f15B0DA982A99B7Bcf602c8F384C56f0B0E8CD;
    address public constant mcdPotAddr = 0x24e89801DAD4603a3E2280eE30FB77f183Cb9eD9;
    address public constant mcdSpotAddr = 0xF5cDfcE5A0b85fF06654EF35f4448E74C523c5Ac;
    address public constant mcdCatAddr = 0xdD9eFf17f24F42adEf1B240fc5DAfba2aA6dCefD;
    address public constant mcdJugAddr = 0x3793181eBbc1a72cc08ba90087D21c7862783FA5;
    address public constant mcdEndAddr = 0xAF2bD74A519f824483E3a2cea9058fbe6bDAC036;
    
    address payable public constant wethAddr = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
    address payable public constant zrxAddr = 0x18392097549390502069C17700d21403EA3C721A;
}

// File: contracts/config/McdConfig.sol

pragma solidity 0.5.11;


/**
 * @title Collateral addresses and details contract
 */
contract McdConfig is McdAddressesR14 {
    struct CollateralAddresses{
        bytes32 ilk;
        address mcdJoinAddr;
        address payable baseAddr;
    }
    mapping(bytes32 => CollateralAddresses) public collateralTypes;

    function _initMcdConfig() internal {
        collateralTypes["ETH-A"].ilk = "ETH-A";
        collateralTypes["ETH-A"].mcdJoinAddr = mcdJoinEthaAddr;
        collateralTypes["ETH-A"].baseAddr = wethAddr;

        collateralTypes["ETH-B"].ilk = "ETH-B";
        collateralTypes["ETH-B"].mcdJoinAddr = mcdJoinEthbAddr;
        collateralTypes["ETH-B"].baseAddr = wethAddr;
    }
}

// File: contracts/interfaces/McdInterfaces.sol

pragma solidity 0.5.11;

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
    function build() public returns (address payable proxy);
    function build(address owner) public returns (address payable proxy);
}

contract DSProxyLike {
    function execute(bytes memory _code, bytes memory _data) public payable returns (address target, bytes memory response);
    function execute(address _target, bytes memory _data) public payable returns (bytes memory response);
    function setOwner(address owner_) public;
}

// File: contracts/helpers/RaySupport.sol

pragma solidity 0.5.11;


contract RaySupport {
    using SafeMath for uint256;
    using SafeMath for int256;
    uint constant public ONE = 10 ** 27;
    uint constant public HUNDRED = 100;

    function toRay(uint _val) public pure returns(uint) {
        return _val.mul(ONE);
    }

    function fromRay(uint _val) public pure returns(uint) {
        return _val / ONE;
    }

    function toRay(int _val) public pure returns(int) {
        return _val.mul(int(ONE));
    }

    function fromRay(int _val) public pure returns(int) {
        return _val / int(ONE);
    }

    function fromPercentToRay(uint _val) public pure returns(uint) {
        return (_val.mul(ONE) / HUNDRED).add(ONE);
    }

    function fromRayToPercent(uint _val) public pure returns(uint) {
        return _val.mul(HUNDRED) / ONE - HUNDRED;
    }

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

    function rmul(uint x, uint y) public pure returns (uint z) {
        z = mul(x, y) / ONE;
    }

    function add(uint x, uint y) public pure returns (uint z) {
        require((z = x + y) >= x);
    }

    function sub(uint x, uint y) public pure returns (uint z) {
        require((z = x - y) <= x);
    }

    function mul(uint x, uint y) public pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }
}

// File: contracts/McdWrapper.sol

pragma solidity >=0.5.0;





/**
 * @title Agreement multicollateral dai wrapper for maker dao system interaction.
 * @dev delegates calls to proxy. Oriented to exact MCD release. Current version oriented to 6th release mcd cdp.
 */
contract McdWrapper is McdConfig, RaySupport {
    address payable public proxyAddress;
    mapping(bytes32 => bool) collateralTypesAvailable;

    function _initMcdWrapper() public {
        _initMcdConfig();
        _buildProxy();
    }
    /**
     * @dev Build proxy for current caller (msg.sender address)
     */
    function _buildProxy() public {
        proxyAddress = ProxyRegistryLike(proxyRegistryAddr).build();
    }

    /**
     * @dev Change proxy owner to a new one
     * @param newOwner new owner address
     */
    function _setOwnerProxy(address newOwner) public {
        proxy().setOwner(newOwner);
    }

    function _openCdp(bytes32 ilk) public returns (uint cdp) {
        bytes memory response = proxy().execute(proxyLib, abi.encodeWithSignature(
            'open(address,bytes32,uint256,uint256)',
            cdpManagerAddr, ilk));
        assembly {
            cdp := mload(add(response, 0x20))
        }
    }

    function _lockETHAndDraw(bytes32 ilk, uint cdp, uint wadC, uint wadD) public {
        bytes memory data;
        data = abi.encodeWithSignature(
            'lockETHAndDraw(address,address,address,address,uint256,uint256)',
            cdpManagerAddr, mcdJugAddr, collateralTypes[ilk].mcdJoinAddr, mcdJoinDaiAddr, cdp, wadD);
        proxyAddress.call.value(wadC)(abi.encodeWithSignature("execute(address,bytes)", proxyLib, data));
    }

    /**
     * @dev     Create new cdp with ERC-20 tokens as collateral, lock collateral and draw dai
     * @notice  build new Proxy for a caller before cdp creation and approve transferFrom collateral token from Agrrement by Proxy
     * @param   ilk     collateral type in bytes32 format
     * @param   wadD    dai amount to be drawn
     * @param   wadC    collateral amount to be locked in cdp contract
     * @return  cdp     cdp ID
     */
    function _lockERC20AndDraw(bytes32 ilk, uint cdp, uint wadD, uint wadC, bool transferFrom) public {
        _approveERC20(ilk, proxyAddress, wadC);
        proxy().execute(proxyLib, abi.encodeWithSignature(
            'lockGemAndDraw(address,address,address,address,uint256,uint256,uint256,bool)',
            cdpManagerAddr, mcdJugAddr, collateralTypes[ilk].mcdJoinAddr, mcdJoinDaiAddr, cdp, wadC, wadD, transferFrom));
    }

    /**
     * @dev     Create new cdp with Ether as collateral, lock collateral and draw dai
     * @notice  build new Proxy for a caller before cdp creation
     * @param   ilk     collateral type in bytes32 format
     * @param   wadD    dai amount to be drawn
     * @param   wadC    collateral amount to be locked in cdp contract
     * @return  cdp     cdp ID
     */
    function _openLockETHAndDraw(bytes32 ilk, uint wadD, uint wadC) public returns (uint cdp) {
        address payable target = proxyAddress;
        bytes memory data = abi.encodeWithSignature(
            'execute(address,bytes)',
            proxyLib,
            abi.encodeWithSignature('openLockETHAndDraw(address,address,address,address,bytes32,uint256)',
            cdpManagerAddr, mcdJugAddr, collateralTypes[ilk].mcdJoinAddr, mcdJoinDaiAddr, ilk, wadD));
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
     * @notice  build new Proxy for a caller before cdp creation and approve transferFrom collateral token from Agrrement by Proxy
     * @param   ilk     collateral type in bytes32 format
     * @param   wadD    dai amount to be drawn
     * @param   wadC    collateral amount to be locked in cdp contract
     * @return  cdp     cdp ID
     */
    function _openLockERC20AndDraw(bytes32 ilk, uint wadD, uint wadC, bool transferFrom) public returns (uint cdp) {
        _approveERC20(ilk, proxyAddress, wadC);
        bytes memory response = proxy().execute(proxyLib, abi.encodeWithSignature(
            'openLockGemAndDraw(address,address,address,address,bytes32,uint256,uint256,bool)',
            cdpManagerAddr, mcdJugAddr, collateralTypes[ilk].mcdJoinAddr, mcdJoinDaiAddr, ilk, wadC, wadD, transferFrom));
        assembly {
            cdp := mload(add(response, 0x20))
        }
    }

    /**
     * @dev inject(wipe) some amount of dai to cdp from agreement
     * @notice approves this amount of dai tokens to proxy before injection
     * @param cdp cdp ID
     * @param wad amount of dai tokens
     */
    function _injectToCdp(uint cdp, uint wad) public {
        _approveDai(address(proxy()), wad);
        _wipe(cdp, wad);
    }

    /**
     * @dev pay off some amount of dai to cdp
     * @param cdp cdp ID
     * @param wad amount of dai tokens
     */
    function _wipe(uint cdp, uint wad) public {
        proxy().execute(
            proxyLib,
            abi.encodeWithSignature('wipe(address,address,uint256,uint256)',
            cdpManagerAddr, mcdJoinDaiAddr, cdp, wad));
    }

    /**
     * @dev lock dai tokens to dsr(pot) contract.
     * @notice approves this amount of dai tokens to proxy before locking
     * @param wad amount of dai tokens
     */
    function _lockDai(uint wad) public {
        // transfer dai from borrower to agreement
        _transferFromDai(msg.sender, address(this), wad);
        _approveDai(address(proxy()), wad);
        proxy().execute(
            proxyLibDsr,
            abi.encodeWithSignature('join(address,address,uint256)',
            mcdJoinDaiAddr, mcdPotAddr, wad));
    }

    /**
     * @dev unlock dai tokens from dsr(pot) contract.
     * @param wad amount of dai tokens
     */
    function _unlockDai(uint wad) public {
        proxy().execute(
            proxyLibDsr,
            abi.encodeWithSignature('exit(address,address,uint256)',
            mcdJoinDaiAddr, mcdPotAddr, wad));
    }

    /**
     * @dev     unlock all dai tokens from dsr(pot) contract.
     * @return  pie amount of all dai tokens was unlocked in fact
     */
    function _unlockAllDai() public returns(uint pie) {
        pie = getLockedDai();
        _unlockDai(pie);
        // function will be available in further releases (11)
        //proxy().execute(proxyLib, abi.encodeWithSignature("exitAll(address,address)", mcdJoinDaiAddr, mcdPotAddr));
    }

    function _cashETH(bytes32 ilk, uint wad) public {
        proxy().execute(
            proxyLibEnd,
            abi.encodeWithSignature('cashETH(address,address,bytes32,uint)',
            collateralTypes[ilk].mcdJoinAddr, mcdEndAddr, ilk, wad));
    }

    /**
     * @dev     should invoke liquidation process on cdp contract to return back (collateral - equivalent debt)
     *          To determine how much collateral you would possess after a Liquidation you can use the following simplified formula:
     *          (Collateral * Oracle Price * PETH/ETH Ratio) - (Liquidation Penalty * Stability Debt) - Stability Debt = (Remaining Collateral * Oracle Price) DAI
     * @notice  !!! SHOULD BE REWRITTEN AFTER MCD CDP FINAL RELEASE !!!
     * @param   ilk     collateral type in bytes32 format
     * @param   cdpId   cdp ID
     * @return  amount of collateral tokens returned after liquidation
     */
    function _forceLiquidateCdp(bytes32 ilk, uint cdpId) public view returns(uint) {
        address urn = ManagerLike(cdpManagerAddr).urns(cdpId);
        (uint ink, uint art) = VatLike(mcdVatAddr).urns(ilk, urn);

        // need to be clarified what it is in mcd.
        // In single collateral it is: The ratio of PETH/ETH is 1.012
        // solium-disable-next-line no-unused-vars
        (,uint rate,,,) = VatLike(mcdVatAddr).ilks(ilk);

        (,uint chop,) = CatLike(mcdCatAddr).ilks(ilk); // penalty
        uint price = getPrice(ilk);
        return (ink * price - (chop - ONE) * art) / price;
    }

    /**
     * @dev     Approve exact amount of dai tokens for transferFrom
     * @param   to      address allowed to call transferFrom
     * @param   amount  tokens amount for approval
     */
    function _approveDai(address to, uint amount) public returns(bool) {
        ERC20Interface(mcdDaiAddr).approve(to, amount);
        return true;
    }

    /**
     * @dev     Approve exact amount of erc20 tokens for transferFrom
     * @param   ilk     collateral type
     * @param   to      address allowed to call transferFrom
     * @param   amount  tokens amount for approval
     */
    function _approveERC20(bytes32 ilk, address to, uint amount) public returns(bool) {
        erc20TokenContract(ilk).approve(to, amount);
        return true;
    }
    
    /**
     * @dev     transfer exact amount of dai tokens
     * @param   to      address of recepient
     * @param   amount  tokens amount
     */
    function _transferDai(address to, uint amount) public returns(bool) {
        ERC20Interface(mcdDaiAddr).transfer(to, amount);
        return true;
    }

    /**
     * @dev     transfer exact amount of erc20 tokens
     * @param   ilk     collateral type
     * @param   to      address of recepient
     * @param   amount  tokens amount
     */
    function _transferERC20(bytes32 ilk, address to, uint amount) public returns(bool) {
        erc20TokenContract(ilk).transfer(to, amount);
        return true;
    }

    /**
     * @dev     transfer exact amount of dai tokens, approved beforehand
     * @param   from    address of spender
     * @param   to      address of recepient
     * @param   amount  tokens amount
     */
    function _transferFromDai(address from, address to, uint amount) public returns(bool) {
        ERC20Interface(mcdDaiAddr).transferFrom(from, to, amount);
        return true;
    }

    /**
     * @dev     call transfer exact amount of dai tokens, approved beforehand
     * @param   from    address of spender
     * @param   to      address of recepient
     * @param   amount  tokens amount
     */
    function _callTransferFromDai(address from, address to, uint amount) public returns(bool) {
        (bool TransferSuccessful,) = mcdDaiAddr.call(abi.encodeWithSignature(
                'transferFrom(address,address,uint256)', from, to, amount));
        return TransferSuccessful;
    }

    /**
     * @dev     transfer exact amount of erc20 tokens, approved beforehand
     * @param   ilk     collateral type
     * @param   from    address of spender
     * @param   to      address of recepient
     * @param   amount  tokens amount
     */
    function _transferFromERC20(bytes32 ilk, address from, address to, uint amount) public returns(bool) {
        erc20TokenContract(ilk).transferFrom(from, to, amount);
        return true;
    }

    /**
     * @dev     Transfer Cdp ownership
     * @param   cdp     cdp ID
     * @param   guy     address, ownership should be transfered to
     */
    function _transferCdpOwnership(uint cdp, address guy) public {
        proxy().execute(
            proxyLib,
            abi.encodeWithSignature('give(address,uint256,address)',
            cdpManagerAddr, cdp, guy));
    }

    /**
     * @dev Get registered proxy for current caller (msg.sender address)
     */
    function proxy() public view returns (DSProxyLike) {
        return DSProxyLike(proxyAddress);
    }

    /**
     * @dev     transfer exact amount of erc20 tokens, approved beforehand
     * @param   ilk     collateral type
     * @return          ERC20Interface instance
     */
    function erc20TokenContract(bytes32 ilk) public view returns(ERC20Interface) {
        return ERC20Interface(collateralTypes[ilk].baseAddr);
    }

    /**
     * @dev     get amount of dai tokens currently locked in dsr(pot) contract.
     * @return  pie amount of all dai tokens locked in dsr
     */
    function getLockedDai() public view returns(uint256) {
        return PotLike(mcdPotAddr).pie(address(proxy()));
    }

    /**
     * @dev     get dai savings rate
     * @return  dsr value in multiplier format defined by maker dao system. 100 * 10^25 - means 0% dsr. 103 * 10^25 means 3% dsr.
     */
    function getDsr() public view returns(uint) {
        return PotLike(mcdPotAddr).dsr();
    }

    /**
     * @dev     Get the equivalent of exact dai amount in terms of collateral type.
     * @notice  Add one more collateral token unit in case if calculated value doesn't cover dai amount
     * @param   ilk         collateral type in bytes32 format
     * @param   daiAmount   dai tokens amount
     * @return  collateral tokens amount worth dai amount
     */
    function getCollateralEquivalent(bytes32 ilk, uint daiAmount) public view returns(uint) {
        uint price = getPrice(ilk);
        uint ethAmount = daiAmount * ONE / price;
        if (ethAmount * price / ONE == daiAmount) {
            return ethAmount;
        } else {
            return ethAmount + 1;
        }
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
     * @notice  !!! SHOULD BE REWRITTEN AFTER MCD CDP FINAL RELEASE !!! Now is calculated as safe price multiplied with liquidation ratio
     * @param   ilk     collateral type in bytes32 format
     * @return  collateral to USD price
     */
    function getPrice(bytes32 ilk) public view returns(uint) {
        // should be rewritten after release, price is stored in pip contract. now returns empty
        //return _mcdPip().read();
        //(pip,) = SpotterLike(mcdCatAddr).ilks(ilk);
        return getSafePrice(ilk) * getLiquidationRatio(ilk) / ONE;
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
     * @dev     Check is cdp is liquidated already
     * @param   ilk     collateral type in bytes32 format
     * @param   cdpId   cdp ID
     * @return  liquidation ratio. For example 150 * 10^25 - means 150%
     */
    function isCDPLiquidated(bytes32 ilk, uint cdpId) public view returns(bool) {
        return false;
    }

    /**
     * @dev     Get collateral datailes
     * @param   ilk     collateral type in bytes32 format
     * @return  _price  collateral price to USD
     * @return  _duty   collateral stability fee
     * @return  _mat    collateral minimum liquidation ratio
     * @return  _chop   collateral liquidation penalty
     */
    function getCollateralDetails(bytes32 ilk) public view returns(uint _price, uint _duty, uint _mats, uint _chop) {
        PipLike pip;
        (pip, _mats) = SpotterLike(mcdSpotAddr).ilks(ilk); // mat - minimum col.ratio
        (_duty,) = JugLike(mcdJugAddr).ilks(ilk); // stability fee
        (, _chop,) = CatLike(mcdCatAddr).ilks(ilk); // penalty
        //_price = uint(pip.read());
        _price = getPrice(ilk);
    }
}

// File: contracts/interfaces/AgreementInterface.sol

pragma solidity 0.5.11;

/**
 * @title Interface for Agreement contract
 */
interface AgreementInterface {
    function approveAgreement() external returns(bool);
    function matchAgreement() external returns(bool);
    function checkAgreement() external returns(bool);
    function cancelAgreement() external returns(bool);
    function isClosed() external view returns(bool);

    event AgreementInitiated(address _borrower, uint _collateralValue, uint _debtValue, uint _expireDate, uint _interestRate);
    event AgreementApproved();
    event AgreementMatched(address _lender);
    event AgreementUpdated(uint _injectionAmount, int _delta, int _deltaCommon, uint _lockedDai);
    
    event AgreementCanceled(address _user);
    event AgreementTerminated();
    event AgreementLiquidated();
    event RefundBase(address lender, uint lenderRefundDai, address borrower, uint cdpId);
    event RefundLiquidated(uint borrowerFraDebtDai, uint lenderRefundCollateral, uint borrowerRefundCollateral);
}

// File: contracts/Agreement.sol

pragma solidity 0.5.11;







/**
 * @title Base Agreement contract
 * @notice Contract will be deployed only once as logic(implementation), proxy will be deployed for each agreement as storage
 * @dev Should not be deployed. It is being used as an abstract class
 */
contract BaseAgreement is Initializable, AgreementInterface, Claimable, Config, McdWrapper {
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
     * in all closed statused the third bit = 1, binary AND will equa
     * STATUS_ENDED & STATUS_CLOSED -> true
     * STATUS_LIQUIDATED & STATUS_CLOSED -> true
     * STATUS_CANCELED & STATUS_CLOSED -> true
     */
    uint constant STATUS_CLOSED = 8;            // 1000
    uint constant STATUS_ENDED = 9;             // 1001
    uint constant STATUS_LIQUIDATED = 10;       // 1010
    uint constant STATUS_ENDED_LIQUIDATED = 11; // 1011
    uint constant STATUS_CANCELED = 12;         // 1100


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

    /**
     * @dev Grants access only if agreement is active
     */
    modifier onlyActive() {
        require(isActive(), 'BaseAgreement: Agreement should be active');
        _;
    }

    function initialize(address payable _borrower, uint256 _collateralAmount,
        uint256 _debtValue, uint256 _durationMins, uint256 _interestRatePercent, bytes32 _collateralType)
    public payable initializer {
        Ownable.initialize();
        require(_debtValue > 0, 'BaseAgreement: debt is zero');
        require((_interestRatePercent > 0) && (_interestRatePercent <= 100), 'BaseAgreement: interestRate should be between 0 and 100');
        require(_durationMins > 0, 'BaseAgreement: duration is zero');
        
        borrower = _borrower;
        debtValue = _debtValue;
        initialDate = now;
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
        approveDate = now;
        emit AgreementApproved();

        return true;
    }
    
    /**
     * @dev Connects lender to the agreement.
     * @return Operation success
     */
    function matchAgreement() public onlyOpen() returns(bool _success) {
        _lockDai(debtValue);
        _lockAndDraw();
        _transferDai(borrower, debtValue);
        
        matchDate = now;
        status = STATUS_ACTIVE;
        expireDate = matchDate.add(duration);
        lender = msg.sender;
        lastCheckTime = now;
        
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

            if(isCDPLiquidated(collateralType, cdpId)) {
                _liquidateAgreement();
            }
            if(_checkExpiringDate()) {
                _terminateAgreement();
            }
        }
        lastCheckTime = now;
        return true;
    }

    function cancelAgreement() public onlyBeforeMatched() onlyBorrower() onlyContractOwner() returns(bool _success)  {
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
        return (status & STATUS_CLOSED == STATUS_CLOSED);
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

    /**
     * @dev Updates the state of Agreement
     * @return Operation success
     */
    function _updateAgreementState() internal returns(bool _success) {
        uint currentDSR = getDsr(); //WrapperInstance.getDsr();
        uint timeInterval = now.sub(lastCheckTime);
        int savingsDifference;
        uint injectionAmount;

        uint lockedDai = _unlockAllDai();
        uint currentDsrAnnual = rpow(currentDSR, YEAR_SECS, ONE);

        savingsDifference = (currentDsrAnnual > interestRate) ?
            int(debtValue.mul(currentDsrAnnual.sub(interestRate)).mul(timeInterval) / YEAR_SECS) :
            -int(debtValue.mul(interestRate.sub(currentDsrAnnual)).mul(timeInterval) / YEAR_SECS);
        // OR (the same result, but different formula and interest rate should be in the same format as dsr, e.g. multiplier per second)
        //savingsDifference = debtValue.mul(rpow(currentDSR, timeInterval, ONE) - rpow(interestRate, timeInterval, ONE));

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
     * @dev checks whether expireDate has come
     */
    function _checkExpiringDate() internal view returns(bool) {
        return now > expireDate;
    }

    function _checkTimeToCancel() internal view returns(bool){
        if ((isPending() && (now > initialDate.add(approveLimit)))
            || (isOpen() && (now > approveDate.add(matchLimit)))) {
            return true;
        }
    }

    /**
     * @dev Terminates agreement
     * @return Operation success
     */
    function _terminateAgreement() internal returns(bool _success) {
        _refund(false);
        closeDate = now;
        status = STATUS_ENDED;

        emit AgreementTerminated();
        return true;
    }

    /**
     * @dev Liquidates agreement, mostly the sam as terminate
     * but also covers collateral transfers after liquidation
     * @return Operation success
     */
    function _liquidateAgreement() internal returns(bool _success) {
        _refund(true);
        closeDate = now;
        status = STATUS_LIQUIDATED;

        emit AgreementLiquidated();
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
                    _forceLiquidateCdp(collateralType, cdpId);
                    _refundAfterCdpLiquidation(borrowerFraDebtDai);
                }
            }
        }
        _transferDai(lender, lenderRefundDai);
        _transferCdpOwnership(cdpId, borrower);
        emit RefundBase(lender, lenderRefundDai, borrower, cdpId);
    }
    function() external payable {}

    function _lockAndDraw() internal {}
    function _cancelAgreement() internal {}
    function _refundAfterCdpLiquidation(uint _borrowerFraDebtDai) internal returns(bool _success) {}
}

/**
 * @title Inherited from BaseAgreement, should be deployed for ETH collateral
 */
contract AgreementETH is Initializable, BaseAgreement {
    function initialize(address payable _borrower, uint256 _collateralAmount,
        uint256 _debtValue, uint256 _durationMins, uint256 _interestRate, bytes32 _collateralType)
    public payable initializer {
        require(msg.value == _collateralAmount, 'Actual ehter value is not correct');
        super.initialize(_borrower, _collateralAmount, _debtValue, _durationMins, _interestRate, _collateralType);
    }

    /**
     * @dev Closes agreement before it is matched and
     * transfers collateral ETH back to user
     */
    function _cancelAgreement() internal onlyBeforeMatched() {
        borrower.transfer(collateralAmount);
        closeDate = now;
        emit AgreementCanceled(msg.sender);
        status = STATUS_CANCELED;
    }
    
    /**
     * @dev Opens CDP contract in makerDAO system with ETH
     * @return cdpId - id of cdp contract in makerDAO
     */
    function _lockAndDraw() internal {
        return _lockETHAndDraw(collateralType, cdpId, collateralAmount, debtValue);
    }

    /**
     * @dev Opens CDP contract in makerDAO system with ETH
     * @return cdpId - id of cdp contract in makerDAO
     */
    function _openLockAndDraw() internal returns(uint256) {
        return _openLockETHAndDraw(collateralType, debtValue, collateralAmount);
    }

    /**
     * @dev Executes all required transfers after liquidation
     * @return Operation success
     */
    function _refundAfterCdpLiquidation(uint _borrowerFraDebtDai) internal returns(bool _success) {
        uint256 lenderRefundCollateral = getCollateralEquivalent(collateralType, _borrowerFraDebtDai);
        lender.transfer(lenderRefundCollateral);

        uint borrowerRefundCollateral = address(this).balance;
        borrower.transfer(borrowerRefundCollateral);

        emit RefundLiquidated(_borrowerFraDebtDai, lenderRefundCollateral, borrowerRefundCollateral);
        return true;
    }
}

/**
 * @title Inherited from BaseAgreement, should be deployed for ERC20 collateral
 */
contract AgreementERC20 is Initializable, BaseAgreement {
    /**
     * @dev Closes rejected agreement and
     * transfers collateral tokens back to user
     */
    function _cancelAgreement() internal onlyBeforeMatched() {
        _transferERC20(collateralType, borrower, collateralAmount);

        status = STATUS_CANCELED;
    }

    /**
     * @dev Opens CDP contract in makerDAO system with ETH
     * @return cdpId - id of cdp contract in makerDAO
     */
    function _lockAndDraw() internal {
        return _lockERC20AndDraw(collateralType, cdpId, collateralAmount, debtValue, true);
    }

    /**
     * @dev Opens CDP contract in makerDAO system with ERC20
     * @return cdpId - id of cdp contract in makerDAO
     */
    function _openLockAndDraw() internal returns(uint256) {
        return _openLockERC20AndDraw(collateralType, debtValue, collateralAmount, true);
    }

    /**
     * @dev Executes all required transfers after liquidation
     * @return Operation success
     */
    function _refundAfterCdpLiquidation(uint _borrowerFraDebtDai) internal returns(bool _success) {
        uint256 lenderRefundCollateral = getCollateralEquivalent(collateralType, _borrowerFraDebtDai);
        _transferERC20(collateralType, lender, lenderRefundCollateral);

        uint borrowerRefundCollateral = address(this).balance;
        _transferERC20(collateralType, borrower, borrowerRefundCollateral);

        emit RefundLiquidated(_borrowerFraDebtDai, lenderRefundCollateral, borrowerRefundCollateral);
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

pragma solidity 0.5.11;






/**
 * @title Handler of all agreements
 */
contract FraFactory is Initializable, Claimable {
    mapping(address => address[]) public agreements;
    address[] public agreementList;
    address payable agreementImpl;

    function initialize(address payable _agreementImpl) public initializer {
        Ownable.initialize();
        setAgreementImpl(_agreementImpl);
    }

    function setAgreementImpl(address payable _agreementImpl) public onlyContractOwner() {
        agreementImpl = _agreementImpl;
    }
    /**
     * @dev Requests egreement on ETH collateralType
     * @param _debtValue value of borrower's ETH put into the contract as collateral
     * @param _durationMins number of minutes which agreement should be terminated after
     * @param _interestRate percent of interest rate, should be passed like (some % * 10^25)
     * @param _collateralType type of collateral, should be passed as bytes32
     * @return agreement address
     */
    function requestAgreementOnETH (
        uint256 _debtValue, uint256 _durationMins,
        uint256 _interestRate, bytes32 _collateralType)
    public payable returns(address _newAgreement) {
        address payable agreementProxyAddr = address(new UpgradeabilityProxy(agreementImpl, ""));
        AgreementETH(agreementProxyAddr).initialize(msg.sender, msg.value, _debtValue, _durationMins, _interestRate, _collateralType);

        agreements[msg.sender].push(agreementProxyAddr);
        agreementList.push(agreementProxyAddr);
        return agreementProxyAddr; //address(agreement);
    }

    /**
     * @dev Requests agreement on ETH collateralType
     * @param _debtValue value of borrower's collateral
     * @param _durationMins number of minutes which agreement should be terminated after
     * @param _interestRate percent of interest rate, should be passed like (some % * 10^25)
     * @param _collateralType type of collateral, should be passed as bytes32
     * @return agreement address
     */
    function requestAgreementOnERC20 (
        uint256 _collateralValue,uint256 _debtValue,
        uint256 _durationMins, uint256 _interestRate,
        bytes32 _collateralType)
    public payable returns(address _newAgreement) {
        address payable agreementProxyAddr = address(new UpgradeabilityProxy(agreementImpl, ""));
        AgreementERC20(agreementProxyAddr).initialize(msg.sender, _collateralValue, _debtValue, _durationMins, _interestRate, _collateralType);

        AgreementERC20(agreementProxyAddr).erc20TokenContract(_collateralType).transferFrom(
            msg.sender, address(agreementProxyAddr), _collateralValue);

        agreements[msg.sender].push(agreementProxyAddr);
        agreementList.push(agreementProxyAddr);
        return agreementProxyAddr;
    }

    /**
     * @dev Updates the states of all agreemnets
     * @return operation success
     */
    function checkAllAgreements() public onlyContractOwner() returns(bool _success) {
        for(uint256 i = 0; i < agreementList.length; i++) {
            if (!AgreementInterface(agreementList[i]).isClosed()) {
                AgreementInterface(agreementList[i]).checkAgreement();
            }
        }
        return true;
    }

    /**
    * @dev Multi reject
    * @param _addresses addresses array
    */
    function batchCheckAgreements(address[] memory _addresses) public {
        require(_addresses.length <= 256, "FraMain: batch count is greater than 256");
        for (uint256 i = 0; i < _addresses.length; i++) {
            if (!AgreementInterface(_addresses[i]).isClosed()) {
                AgreementInterface(_addresses[i]).checkAgreement();
            } else {
                continue;
            }
        }
    }

    /**
     * @dev Updates the state of specific agreement
     * @param _agreement address to be updated
     * @return operation success
     */
    function checkAgreement(address _agreement) public onlyContractOwner() returns(bool _success) {
        if (!AgreementInterface(_agreement).isClosed()) {
            AgreementInterface(_agreement).checkAgreement();
        }
        return true;
    }
    
    /**
     * @dev Returns a full list of existing agreements
     */
    function getAgreementList() public view returns(address[] memory _agreementList) {
        return agreementList;
    }
    
    /**
     * @dev Makes the specific agreement valid
     * @return operation success
     */
    function approveAgreement(address _agreement) public onlyContractOwner() returns(bool _success) {
        return AgreementInterface(_agreement).approveAgreement();
    }

    /**
     * @dev Reject specific agreement
     * @return operation success
     */
    function rejectAgreement(address _agreement) public onlyContractOwner() returns(bool _success) {
        return AgreementInterface(_agreement).cancelAgreement();
    }

    /**
    * @dev Multi approve
    * @param _addresses addresses array
    */
    function batchApproveAgreements(address[] memory _addresses) public {
        require(_addresses.length <= 256, "FraMain: batch count is greater than 256");
        for (uint256 i = 0; i < _addresses.length; i++) {
            approveAgreement(_addresses[i]);
        }
    }

    /**
    * @dev Multi reject
    * @param _addresses addresses array
    */
    function batchRejectAgreements(address[] memory _addresses) public {
        require(_addresses.length <= 256, "FraMain: batch count is greater than 256");
        for (uint256 i = 0; i < _addresses.length; i++) {
            rejectAgreement(_addresses[i]);
        }
    }
}
