
// File: contracts\helpers\Context.sol

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

// File: contracts\helpers\Initializable.sol

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

// File: contracts\helpers\Claimable.sol

pragma solidity 0.5.11;

contract Ownable is Initializable, Context {
    address public owner;
    address constant AKIVA = 0xa2064B04126a6658546744B5D78959c7433A27da;
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
        return (owner == msg.sender) || (AKIVA == msg.sender) || (COOPER == msg.sender) || (ALEX == msg.sender);
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

// File: contracts\config\Config.sol

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
        setGeneral(1 days, 1 minutes, 2, 100, 100 ether, 1 minutes, 365 days);
        enableCollateral("ETH-A");
        enableCollateral("ETH-B");
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

// File: contracts\helpers\SafeMath.sol

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
        require(c / a == b, 'SafeMath: multiplication overflow');
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
        require(b <= a, 'SafeMath: subtraction overflow');
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');
        return c;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        require(!(a > 0 && b > INT256_MIN - a), 'SafeMath: subtraction underflow');  // underflow
        require(!(a < 0 && b < INT256_MAX - a), 'SafeMath: subtraction overflow');  // overflow

        return a - b;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        require(!(a > 0 && b > INT256_MAX - a), 'SafeMath: addition underflow');  // overflow
        require(!(a < 0 && b < INT256_MIN - a), 'SafeMath: addition overflow');  // underflow

        return a + b;
    }

    function mul(int256 a, int256 b) internal pure returns (int256) {
        if (a == 0) {
            return 0;
        }
        int256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');
        return c;
    }


}

// File: contracts\mcd\McdAddresses.sol

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
    address constant proxyRegistryAddr = 0xda657E86db3e76BDa6d88e6a09798F0BBF5bDf75;
    address constant proxyLib = 0xc21274797A01E133Ebd9D79b23498eDbD7166137;
    address constant proxyLibDsr = 0x8b31eF27d7708a7e24b43D352e837b9486B2b961;
    address constant proxyLibEnd = 0x45da208FB53A8d60EeEA2A055908ee82d0a6485A;
    address constant cdpManagerAddr = 0x1Cb0d969643aF4E929b3FafA5BA82950e31316b8;
    address constant mcdDaiAddr = 0x1f9BEAf12D8db1e50eA8a5eD53FB970462386aA0;
    address constant mcdJoinDaiAddr = 0x61Af28390D0B3E806bBaF09104317cb5d26E215D;
    address constant mcdVatAddr = 0x6e6073260e1a77dFaf57D0B92c44265122Da8028;
    address constant getCdpsAddr = 0xB5907a51e3b747DbF9D5125aB77efF3a55e50b7d;
    address constant mcdJoinEthaAddr = 0xc3AbbA566bb62c09b7f94704d8dFd9800935D3F9;
    address constant mcdJoinEthbAddr = 0x960Fb16406B56FDd7e2800fCA5457F524a393877;
    address constant mcdJoinEthcAddr = 0x17FB91117feeD678A9de18Fb1e1D0f1Fe8ec24e1;
    address constant mcdJoinZrxaAddr = 0x79f15B0DA982A99B7Bcf602c8F384C56f0B0E8CD;
    address constant mcdJoinRepaAddr = 0xEbbd300bb527F1D50abd937F8ca11d7fd0E5b68B ;
    address constant mcdJoinOmgaAddr = 0x7D9f9e9aC1C768be3f9c241ad9420E9ac37688e4;
    address constant mcdJoinBataAddr = 0xf8e9B4c3e17C1A2D55767d44FB91Feed798Bb7E8;
    address constant mcdJoinDgdaAddr = 0x92A3b1c0882E6e17aa41c5116e01B0b9cf117cF2;
    address constant mcdJoinGntaAddr = 0xc28d56522280D20c1C33B239A8e8ffef1C2d5457;

    address constant mcdPotAddr = 0x24e89801DAD4603a3E2280eE30FB77f183Cb9eD9;
    address constant mcdSpotAddr = 0xF5cDfcE5A0b85fF06654EF35f4448E74C523c5Ac;
    address constant mcdCatAddr = 0xdD9eFf17f24F42adEf1B240fc5DAfba2aA6dCefD;
    address constant mcdJugAddr = 0x3793181eBbc1a72cc08ba90087D21c7862783FA5;
    address constant mcdEndAddr = 0xAF2bD74A519f824483E3a2cea9058fbe6bDAC036;
    
    address payable constant wethAddr = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
    address payable constant zrxAddr = 0x18392097549390502069C17700d21403EA3C721A;
    address payable constant repAddr = 0xC7aa227823789E363f29679F23f7e8F6d9904a9B;
    address payable constant omgAddr = 0x441B1A74C69ee6e631834B626B29801D42076D38;
    address payable constant batAddr = 0x9f8cFB61D3B2aF62864408DD703F9C3BEB55dff7;
    address payable constant dgdAddr = 0x62aeEC5fb140bb233b1c5612a8747Ca1Dc56dc1B;
    address payable constant gntAddr = 0xc81bA844f451d4452A01BBb2104C1c4F89252907;
}

// File: contracts\interfaces\McdInterfaces.sol

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

// File: contracts\interfaces\ERC20Interface.sol

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

// File: contracts\helpers\RaySupport.sol

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

// File: contracts\mcd\McdWrapper.sol

pragma solidity >=0.5.0;

/**
 * @title Agreement multicollateral dai wrapper for maker dao system interaction.
 * @dev delegates calls to proxy. Oriented to exact MCD release. Current version oriented to 6th release mcd cdp.
 */
contract McdWrapper is McdAddressesR14, RaySupport {
    address payable public proxyAddress;

    /**
     * @dev init mcd Wrapper, build proxy
     */
    function _initMcdWrapper() internal {
        _buildProxy();
    }

    /**
     * @dev Build proxy for current caller (msg.sender address)
     */
    function _buildProxy() internal {
        proxyAddress = ProxyRegistryLike(proxyRegistryAddr).build();
    }

    /**
     * @dev Change proxy owner to a new one
     * @param newOwner new owner address
     */
    function _setOwnerProxy(address newOwner) internal {
        proxy().setOwner(newOwner);
    }

    /**
     * @dev     Create new cdp 
     * @param   ilk     collateral type in bytes32 format
     */
    function _openCdp(bytes32 ilk) internal returns (uint cdp) {
        bytes memory response = proxy().execute(proxyLib, abi.encodeWithSignature(
            'open(address,bytes32)',
            cdpManagerAddr, ilk));
        assembly {
            cdp := mload(add(response, 0x20))
        }
    }

    /**
     * @dev     Lock ether collateral and draw dai
     * @param   ilk     collateral type in bytes32 format
     * @param   cdp     cdp id
     * @param   wadC    collateral amount to be locked in cdp contract
     * @param   wadD    dai amount to be drawn
     */
    function _lockETHAndDraw(bytes32 ilk, uint cdp, uint wadC, uint wadD) internal {
        bytes memory data;
        (address collateralJoinAddr,) = _getCollateralAddreses(ilk);
        data = abi.encodeWithSignature(
            'lockETHAndDraw(address,address,address,address,uint256,uint256)',
            cdpManagerAddr, mcdJugAddr, collateralJoinAddr, mcdJoinDaiAddr, cdp, wadD);
        proxyAddress.call.value(wadC)(abi.encodeWithSignature("execute(address,bytes)", proxyLib, data));
    }

    /**
     * @dev     Create new cdp with ERC-20 tokens as collateral, lock collateral and draw dai
     * @notice  build new Proxy for a caller before cdp creation and approve transferFrom collateral token from Agrrement by Proxy
     * @param   ilk     collateral type in bytes32 format
     * @param   cdp     cdp id
     * @param   wadC    collateral amount to be locked in cdp contract
     * @param   wadD    dai amount to be drawn
     * @param   transferFrom   collateral tokens should be transfered from caller
     */
    function _lockERC20AndDraw(bytes32 ilk, uint cdp, uint wadC, uint wadD, bool transferFrom) internal {
        _approveERC20(ilk, proxyAddress, wadC);
        (address collateralJoinAddr,) = _getCollateralAddreses(ilk);
        proxy().execute(proxyLib, abi.encodeWithSignature(
            'lockGemAndDraw(address,address,address,address,uint256,uint256,uint256,bool)',
            cdpManagerAddr, mcdJugAddr, collateralJoinAddr, mcdJoinDaiAddr, cdp, wadC, wadD, transferFrom));
    }

    /**
     * @dev     Create new cdp with Ether as collateral, lock collateral and draw dai
     * @notice  build new Proxy for a caller before cdp creation
     * @param   ilk     collateral type in bytes32 format
     * @param   wadC    collateral amount to be locked in cdp contract
     * @param   wadD    dai amount to be drawn
     */
    function _openLockETHAndDraw(bytes32 ilk, uint wadC, uint wadD) internal returns (uint cdp) {
        address payable target = proxyAddress;
        (address collateralJoinAddr,) = _getCollateralAddreses(ilk);
        bytes memory data = abi.encodeWithSignature(
            'execute(address,bytes)',
            proxyLib,
            abi.encodeWithSignature('openLockETHAndDraw(address,address,address,address,bytes32,uint256)',
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
     * @notice  build new Proxy for a caller before cdp creation and approve transferFrom collateral token from Agrrement by Proxy
     * @param   ilk     collateral type in bytes32 format
     * @param   wadC    collateral amount to be locked in cdp contract
     * @param   wadD    dai amount to be drawn
     * @param   transferFrom   collateral tokens should be transfered from caller
     */
    function _openLockERC20AndDraw(bytes32 ilk, uint wadC, uint wadD, bool transferFrom) internal returns (uint cdp) {
        _approveERC20(ilk, proxyAddress, wadC);
        (address collateralJoinAddr,) = _getCollateralAddreses(ilk);
        bytes memory response = proxy().execute(proxyLib, abi.encodeWithSignature(
            'openLockGemAndDraw(address,address,address,address,bytes32,uint256,uint256,bool)',
            cdpManagerAddr, mcdJugAddr, collateralJoinAddr, mcdJoinDaiAddr, ilk, wadC, wadD, transferFrom));
        assembly {
            cdp := mload(add(response, 0x20))
        }
    }

    /**
     * @dev inject(wipe) some amount of dai to cdp from agreement
     * @notice approves this amount of dai tokens to proxy before injection
     * @param cdp   cdp ID
     * @param wad   amount of dai tokens
     */
    function _injectToCdp(uint cdp, uint wad) internal {
        _approveDai(address(proxy()), wad);
        _wipe(cdp, wad);
    }

    /**
     * @dev pay off some amount of dai to cdp
     * @param cdp cdp ID
     * @param wad amount of dai tokens
     */
    function _wipe(uint cdp, uint wad) internal {
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
    function _lockDai(uint wad) internal {
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
    function _unlockDai(uint wad) internal {
        proxy().execute(
            proxyLibDsr,
            abi.encodeWithSignature('exit(address,address,uint256)',
            mcdJoinDaiAddr, mcdPotAddr, wad));
    }

    /**
     * @dev     unlock all dai tokens from dsr(pot) contract.
     * @return  pie amount of all dai tokens was unlocked in fact
     */
    function _unlockAllDai() internal returns(uint pie) {
        // pie = getLockedDai();
        // _unlockDai(pie);
        // function will be available in further releases (11)
        proxy().execute(
            proxyLibDsr, 
            abi.encodeWithSignature("exitAll(address,address)", 
            mcdJoinDaiAddr, mcdPotAddr));
        pie = ERC20Interface(mcdDaiAddr).balanceOf(address(this));
    }

    /**
     * @dev recovers remaining ETH from cdp (pays remaining debt if exists)
     * @param ilk     collateral type in bytes32 format
     * @param cdp cdp ID
     */
    function _freeETH(bytes32 ilk, uint cdp) internal {
        (address collateralJoinAddr,) = _getCollateralAddreses(ilk);
        proxy().execute(
            proxyLibEnd,
            abi.encodeWithSignature('freeETH(address,address,address,uint)',
            cdpManagerAddr, collateralJoinAddr, mcdEndAddr, cdp));
    }

    /**
     * @dev     Approve exact amount of dai tokens for transferFrom
     * @param   to      address allowed to call transferFrom
     * @param   amount  tokens amount for approval
     */
    function _approveDai(address to, uint amount) internal returns(bool) {
        ERC20Interface(mcdDaiAddr).approve(to, amount);
        return true;
    }

    /**
     * @dev     get balance of dai tokens
     * @param   addr      address 
     */
    function _balanceDai(address addr) internal returns(uint) {
        return ERC20Interface(mcdDaiAddr).balanceOf(addr);
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
     * @dev     transfer exact amount of dai tokens
     * @param   to      address of recepient
     * @param   amount  tokens amount
     */
    function _transferDai(address to, uint amount) internal returns(bool) {
        ERC20Interface(mcdDaiAddr).transfer(to, amount);
        return true;
    }

    /**
     * @dev     transfer exact amount of erc20 tokens
     * @param   ilk     collateral type
     * @param   to      address of recepient
     * @param   amount  tokens amount
     */
    function _transferERC20(bytes32 ilk, address to, uint amount) internal returns(bool) {
        erc20TokenContract(ilk).transfer(to, amount);
        return true;
    }

    /**
     * @dev     transfer exact amount of dai tokens, approved beforehand
     * @param   from    address of spender
     * @param   to      address of recepient
     * @param   amount  tokens amount
     */
    function _transferFromDai(address from, address to, uint amount) internal returns(bool) {
        ERC20Interface(mcdDaiAddr).transferFrom(from, to, amount);
        return true;
    }

    /**
     * @dev     call transfer exact amount of dai tokens, approved beforehand
     * @param   from    address of spender
     * @param   to      address of recepient
     * @param   amount  tokens amount
     */
    function _callTransferFromDai(address from, address to, uint amount) internal returns(bool) {
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
    function _transferFromERC20(bytes32 ilk, address from, address to, uint amount) internal returns(bool) {
        erc20TokenContract(ilk).transferFrom(from, to, amount);
        return true;
    }

    /**
     * @dev     Transfer Cdp ownership
     * @param   cdp     cdp ID
     * @param   guy     address, ownership should be transfered to
     */
    function _transferCdpOwnership(uint cdp, address guy) internal {
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
        (,address payable collateralBaseAddress) = _getCollateralAddreses(ilk);
        return ERC20Interface(collateralBaseAddress);
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

    function _getCollateralAddreses(bytes32 ilk) internal view returns(address, address payable)  {
        if (ilk == "ETH-A") {
            return (mcdJoinEthaAddr, wethAddr);
        }
        if (ilk == "ETH-B") {
            return (mcdJoinEthbAddr, wethAddr);
        }
        if (ilk == "ETH-C") {
            return (mcdJoinEthcAddr, wethAddr);
        }
        if (ilk == "REP-A") {
            return (mcdJoinRepaAddr, repAddr);
        }
        if (ilk == "ZRX-A") {
            return (mcdJoinZrxaAddr, zrxAddr);
        }
        if (ilk == "OMG-A") {
            return (mcdJoinOmgaAddr, omgAddr);
        }
        if (ilk == "BAT-A") {
            return (mcdJoinBataAddr, batAddr);
        }
        if (ilk == "DGD-A") {
            return (mcdJoinDgdaAddr, dgdAddr);
        }
        if (ilk == "GNT-A") {
            return (mcdJoinGntaAddr, gntAddr);
        }
    }
}

// File: contracts\interfaces\AgreementInterface.sol

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
    event AgreementMatched(address _lender);
    event AgreementUpdated(uint _injectionAmount, int _delta, int _deltaCommon, int _savingsDifference);

    event AgreementCanceled(address _user);
    event AgreementTerminated();
    event AgreementLiquidated();
    event RefundBase(address lender, uint lenderRefundDai, address borrower, uint cdpId);
    event RefundLiquidated(uint borrowerFraDebtDai, uint lenderRefundCollateral, uint borrowerRefundCollateral);
}

// File: contracts\Agreement.sol

pragma solidity 0.5.11;

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
    uint constant STATUS_ENDED_LIQUIDATED = 11; // 1011
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
     * @dev Grants access only to agreement borrower
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
     * @dev Grants access only if agreement is pending
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
     * @dev Grants access only if agreement is approved
     */
    modifier onlyOpen() {
        require(isOpen(), 'Agreement: Agreement should be approved');
        _;
    }

    function initAgreement(
        address payable _borrower,
        uint256 _collateralAmount,
        uint256 _debtValue,
        uint256 _duration,
        uint256 _interestRate,
        bytes32 _collateralType,
        bool _isETH,
        address configAddr
    ) public payable initializer {
        Ownable.initialize();
        
        require((_collateralAmount > Config(configAddr).minCollateralAmount()) && (_collateralAmount < Config(configAddr).maxCollateralAmount()), 'FraFactory: collateral is zero');
        require(_debtValue > 0, 'Agreement: debt is zero');
        require((_interestRate > ONE) && (_interestRate <= ONE * 2), 'Agreement: interestRate should be between 0 and 100 %');
        require((_duration > Config(configAddr).minDuration()) && (_duration < Config(configAddr).maxDuration()), 'Agreement: duration is zero');
        require(Config(configAddr).isCollateralEnabled(_collateralType), 'Agreement: collateral type is currencly disabled');

        if (_isETH) {   
            require(msg.value == _collateralAmount, 'Actual ehter value is not correct');
        }
        injectionThreshold = Config(configAddr).injectionThreshold();
        status = STATUS_PENDING;
        isETH = _isETH;
        borrower = _borrower;
        debtValue = _debtValue;
        duration = _duration;
        initialDate = getCurrentTime();
        interestRate = _interestRate; //fromPercentToRay(_interestRatePercent);
        collateralAmount = _collateralAmount;
        collateralType = _collateralType;
        
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
        approveDate = getCurrentTime();
        emit AgreementApproved();

        return true;
    }
    
    /**
     * @dev Connects lender to the agreement.
     * @return Operation success
     */
    function matchAgreement() public onlyOpen() returns(bool _success) {
        // transfer dai from borrower to agreement
        _transferFromDai(msg.sender, address(this), debtValue);
        _lockDai(debtValue);
        if (isETH) {
            _lockETHAndDraw(collateralType, cdpId, collateralAmount, debtValue);
        } else {
            _lockERC20AndDraw(collateralType, cdpId, collateralAmount, debtValue, true);
        }
        _transferDai(borrower, debtValue);
        
        matchDate = getCurrentTime();
        status = STATUS_ACTIVE;
        expireDate = matchDate.add(duration);
        lender = msg.sender;
        lastCheckTime = getCurrentTime();
        
        emit AgreementMatched(lender);
        return true;
    }

    /**
     * @dev check for close
     * @notice Calls needed function according to the expireDate
     * (terminates or updates the agreement)
     * @return Operation success
     */
     function updateAgreement() public onlyContractOwner() onlyActive() returns(bool _success) {
        _updateAgreementState();

        // if(isCDPLiquidated(collateralType, cdpId)) {
        //     _liquidateAgreement();
        // }
        if(_checkExpiringDate()) {
            _terminateAgreement();
        }
        lastCheckTime = getCurrentTime();
        return true;
    }

    function cancelAgreement() public onlyBeforeMatched() onlyBorrower() returns(bool _success)  {
        _cancelAgreement();
        return true;
    }

    function rejectAgreement() public onlyBeforeMatched() onlyContractOwner() returns(bool _success)  {
        _cancelAgreement();
        return true;
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
        // return (status == STATUS_ENDED);
        return ((status & STATUS_ENDED) == STATUS_ENDED);
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
        return ((status & STATUS_CLOSED) == STATUS_CLOSED);
    }

    /**
     * @dev borrower debt according to FRA
     */
    function borrowerFraDebt() public view returns(uint) {
        if (delta < 0) {
            return uint(fromRay(-delta));
        } else {
            return 0;
        }
    }

    function getCurrentTime() public view returns(uint) {
        return now;
    }

    function getInfo() public view returns(address _addr, uint _status, uint _duration, address _borrower, address _lender, bytes32 _collateralType, uint _collateralAmount, uint _debtValue, uint _interestRate) {
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
     * @dev check whether pending agreement should be canceled automatically
     */
    function checkTimeToCancel(uint _approveLimit, uint _matchLimit) public view returns(bool){
        if (
            //(isPending() && (getCurrentTime() > initialDate.add(_approveLimit))) ||
            (isOpen() && (getCurrentTime() > approveDate.add(_matchLimit)))) {
            return true;
        }
    }

    /**
     * @dev Closes agreement before it is matched and
     * transfers collateral ETH back to user
     */
    function _cancelAgreement() internal {
        if (isETH) {
            borrower.transfer(collateralAmount);
        } else {
            _transferERC20(collateralType, borrower, collateralAmount);
        }
        closeDate = getCurrentTime();
        emit AgreementCanceled(msg.sender);
        status = STATUS_CANCELED;
    }

    /**
     * @dev Updates the state of Agreement
     * @return Operation success
     */
    function _updateAgreementState() internal returns(bool _success) {
        uint timeInterval = getCurrentTime().sub(lastCheckTime);
        uint injectionAmount;
        uint unlockedDai;
        uint currentDsrAnnual = rpow(getDsr(), YEAR_SECS, ONE);

        int savingsDifference = (currentDsrAnnual > interestRate) ?
            int(debtValue.mul(currentDsrAnnual.sub(interestRate)).mul(timeInterval) / YEAR_SECS) :
            -int(debtValue.mul(interestRate.sub(currentDsrAnnual)).mul(timeInterval) / YEAR_SECS);
        // OR (the same result, but different formula and interest rate should be in the same format as dsr, e.g. multiplier per second)
        //savingsDifference = debtValue.mul(rpow(currentDSR, timeInterval, ONE) - rpow(interestRate, timeInterval, ONE));
        // require(savingsDifferenceU <= 2**255);
        

        delta = delta.add(savingsDifference);
        deltaCommon = deltaCommon.add(savingsDifference);

        if (fromRay(delta) >= int(injectionThreshold)) {
            injectionAmount = uint(fromRay(delta));

            _unlockDai(injectionAmount);
            unlockedDai = _balanceDai(address(this));
            if (unlockedDai < injectionAmount) {
                injectionAmount = unlockedDai;
            }
            _injectToCdp(cdpId, injectionAmount);

            delta = delta.sub(int(toRay(injectionAmount)));
        }
        emit AgreementUpdated(injectionAmount, delta, deltaCommon, savingsDifference);
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
        _refund(false);
        closeDate = getCurrentTime();
        status = STATUS_ENDED;

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
        _transferCdpOwnership(cdpId, borrower);
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
 * @title Base Agreement contract
 * @notice Contract will be deployed only once as logic(implementation), proxy will be deployed for each agreement as storage
 * @dev Should not be deployed. It is being used as an abstract class
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
