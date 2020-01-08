
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
        require(isOwner(), "Not a contract owner");
        _;
    }
}

contract Claimable is Ownable {
    address public pendingOwner;
    
    function transferOwnership(address _newOwner) public onlyContractOwner {
        pendingOwner = _newOwner;
    }
    
    function claimOwnership() public {
        require(msg.sender == pendingOwner, "Not a pending owner");

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
    uint public riskyMargin;
    

    /**
     * @dev     Set default config
     */
    constructor() public {
        super.initialize();
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

// File: contracts/mcd/McdAddressesR17.sol

pragma solidity 0.5.11;
/**
 * @title Mcd cdp maker dao system contracts deployed for 14th release
 */
contract McdAddressesR17 {
    uint public constant RELEASE = 17;
    address public constant proxyRegistryAddrMD = 0x64A436ae831C1672AE81F674CAb8B6775df3475C; // used by MakerDao portal oasis
    address constant proxyRegistryAddr = 0xda657E86db3e76BDa6d88e6a09798F0BBF5bDf75; // compatible with 5.11 solc
    address constant proxyLib = 0xd1D24637b9109B7f61459176EdcfF9Be56283a7B;
    address constant proxyLibDsr = 0xc5CC1Dfb64A62B9C7Bb6Cbf53C2A579E2856bf92;
    address constant proxyLibEnd = 0x5652779B00e056d7DF87D03fe09fd656fBc322DF;
    address constant cdpManagerAddr = 0x1476483dD8C35F25e568113C5f70249D3976ba21;
    address constant mcdDaiAddr = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa;
    address constant mcdJoinDaiAddr = 0x5AA71a3ae1C0bd6ac27A1f28e1415fFFB6F15B8c;
    address constant mcdVatAddr = 0xbA987bDB501d131f766fEe8180Da5d81b34b69d9;
    address constant mcdJoinEthaAddr = 0x775787933e92b709f2a3C70aa87999696e74A9F8;
    address constant mcdJoinBataAddr = 0x2a4C485B1B8dFb46acCfbeCaF75b6188A59dBd0a;

    address constant mcdPotAddr = 0xEA190DBDC7adF265260ec4dA6e9675Fd4f5A78bb;
    address constant mcdSpotAddr = 0x3a042de6413eDB15F2784f2f97cC68C7E9750b2D;
    address constant mcdCatAddr = 0x0511674A67192FE51e86fE55Ed660eB4f995BDd6;
    address constant mcdJugAddr = 0xcbB7718c9F39d05aEEDE1c472ca8Bf804b2f1EaD;
    address constant mcdEndAddr = 0x24728AcF2E2C403F5d2db4Df6834B8998e56aA5F;
    
    address payable constant wethAddr = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
    address payable constant batAddr = 0x9f8cFB61D3B2aF62864408DD703F9C3BEB55dff7;
}

// File: contracts/interfaces/IMcd.sol

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

    // function rmul(uint x, uint y) public pure returns (uint z) {
    //     z = mul(x, y) / ONE;
    // }

    // function add(uint x, uint y) internal view returns (uint z) {
    //     require((z = x + y) >= x);
    // }

    // function mul(uint x, uint y) internal view returns (uint z) {
    //     require(y == 0 || (z = x * y) / y == x);
    // }
}

// File: contracts/mcd/McdWrapper.sol

pragma solidity 0.5.11;





/**
 * @title Agreement multicollateral dai wrapper for maker dao system interaction.
 * @notice delegates calls to proxy. Oriented to exact MCD release. Current version oriented to 17th release mcd cdp.
 */
contract McdWrapper is McdAddressesR17, RaySupport {
    address payable public proxyAddress;

    /**
     * @notice  Get registered proxy for current caller (msg.sender address)
     */
    function proxy() public view returns (DSProxyLike) {
        return DSProxyLike(proxyAddress);
    }

    /**
     * @notice  transfer exact amount of erc20 tokens, approved beforehand
     * @param   ilk     collateral type
     * @return  IERC20 instance
     */
    function erc20TokenContract(bytes32 ilk) public view returns(IERC20) {
        (,address payable collateralBaseAddress) = _getCollateralAddreses(ilk);
        return IERC20(collateralBaseAddress);
    }

    /**
     * @notice  get amount of dai tokens currently locked in dsr(pot) contract.
     * @return  pie amount of all dai tokens locked in dsr
     */
    function getLockedDai() public view returns(uint256 pie, uint256 pieS) {
        pie = PotLike(mcdPotAddr).pie(address(proxy()));
        pieS = pie.mul(PotLike(mcdPotAddr).chi());
    }

    /**
     * @notice  get dai savings rate
     * @return  dsr value in multiplier format defined by maker dao system. 100 * 10^25 - means 0% dsr. 103 * 10^25 means 3% dsr.
     */
    function getDsr() public view returns(uint) {
        return PotLike(mcdPotAddr).dsr();
    }

    /**
     * @notice  Get the equivalent of exact dai amount in terms of collateral type.
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
     * @notice  Get current cdp main info: collateral amount, dai (debt) amount
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
     * @notice  Get collateral token price to USD
     * @param   ilk     collateral type in bytes32 format
     * @return  collateral to USD price
     */
    function getPrice(bytes32 ilk) public view returns(uint) {
        return getSafePrice(ilk).mul(getLiquidationRatio(ilk)).div(ONE);
    }

    /**
     * @notice  Get collateral token safe price to USD. Equals current origin price devided by liquidation ratio
     * @param   ilk     collateral type in bytes32 format
     * @return  collateral to USD price
     */
    function getSafePrice(bytes32 ilk) public view returns(uint) {
        (,, uint spot,,) = VatLike(mcdVatAddr).ilks(ilk);
        return spot;
    }

    /**
     * @notice  Get collateral liquidation ratio. Percent of overcollateralization. If collateral / debt < liauidation ratio - cdp should be autoliquidated
     * @param   ilk     collateral type in bytes32 format
     * @return  liquidation ratio  150 * 10^25 - means 150%
     */
    function getLiquidationRatio(bytes32 ilk) public view returns(uint) {
        (,uint mat) = SpotterLike(mcdSpotAddr).ilks(ilk);
        return mat;
    }

    /**
     * @notice  Check is cdp is unsafe already
     * @param   ilk     collateral type in bytes32 format
     * @param   cdpId   cdp ID
     * @return  true if unsafe
     */
    function isCdpSafe(bytes32 ilk, uint cdpId) public view returns(bool) {
        return getDaiAvailable(ilk, cdpId) > 0;
    }

    /**
     * @notice  Calculate available dai to be drawn in Cdp
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
     * @notice  Calculate current cdp collateralization ratio
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
     * @notice  Get minimal collateralization ratio for collateral type
     * @param   ilk     collateral type in bytes32 format
     * @return  minimal collateralization ratio
     */
    function getMCR(bytes32 ilk) public view returns(uint) {
        (,uint mat) = SpotterLike(mcdSpotAddr).ilks(ilk);
        return mat;
    }

    /**
     * @notice init mcd Wrapper, build proxy
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
     * @notice Build proxy for current caller (msg.sender address)
     */
    function _buildProxy() internal {
        proxyAddress = ProxyRegistryLike(proxyRegistryAddr).build();
    }

    /**
     * @notice  Change proxy owner to a new one
     * @param   newOwner new owner address
     */
    function _setOwnerProxy(address newOwner) internal {
        proxy().setOwner(newOwner);
    }

    /**
     * @notice  Lock additional ether as collateral
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
        require(success);
    }

    /**
     * @notice  Lock additional erc-20 tokens as collateral
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
     * @notice  Create new cdp with Ether as collateral, lock collateral and draw dai
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
     * @notice  Create new cdp with ERC-20 tokens as collateral, lock collateral and draw dai
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
     * @notice  inject(wipe) some amount of dai to cdp from agreement (pay off some amount of dai to cdp)
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
     * @notice  draw dai into cdp contract, if not enough - draw max available dai
     * @param   ilk   collateral type in bytes32 format
     * @param   cdp   cdp ID
     * @param   wad   amount of dai tokens
     * @return  drawn dai amount
     */
    function _drawDaiToCdp(bytes32 ilk, uint cdp, uint wad) internal returns (uint drawnDai) {
        uint maxToDraw = getDaiAvailable(ilk, cdp);
        drawnDai = wad > maxToDraw ? maxToDraw : wad;
        proxy().execute(
            proxyLib,
            abi.encodeWithSignature(
                "draw(address,address,address,uint256,uint256)",
                cdpManagerAddr, mcdJugAddr, mcdJoinDaiAddr, cdp, drawnDai));
    }

    /**
     * @notice  lock dai tokens to dsr(pot) contract.
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
     * @notice  unlock dai tokens from dsr(pot) contract.
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
     * @notice  unlock all dai tokens from dsr(pot) contract.
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
     * @notice  recovers remaining ETH from cdp (pays remaining debt if exists)
     * @param   ilk     collateral type in bytes32 format
     * @param   cdp cdp ID
     */
    function _freeETH(bytes32 ilk, uint cdp) internal {
        (address collateralJoinAddr,) = _getCollateralAddreses(ilk);
        proxy().execute(
            proxyLibEnd,
            abi.encodeWithSignature(
                "freeETH(address,address,address,uint)",
                cdpManagerAddr, collateralJoinAddr, mcdEndAddr, cdp));
    }

    /**
     * @notice  Approve exact amount of dai tokens for transferFrom
     * @param   to      address allowed to call transferFrom
     * @param   amount  tokens amount for approval
     */
    function _approveDai(address to, uint amount) internal returns(bool) {
        IERC20(mcdDaiAddr).approve(to, amount);
        return true;
    }

    /**
     * @notice  Approve exact amount of erc20 tokens for transferFrom
     * @param   ilk     collateral type
     * @param   to      address allowed to call transferFrom
     * @param   amount  tokens amount for approval
     */
    function _approveERC20(bytes32 ilk, address to, uint amount) internal returns(bool) {
        erc20TokenContract(ilk).approve(to, amount);
        return true;
    }

    /**
     * @notice  transfer exact amount of dai tokens
     * @param   to      address of recepient
     * @param   amount  tokens amount
     */
    function _transferDai(address to, uint amount) internal returns(bool) {
        IERC20(mcdDaiAddr).transfer(to, amount);
        return true;
    }

    /**
     * @notice  transfer exact amount of erc20 tokens
     * @param   ilk     collateral type
     * @param   to      address of recepient
     * @param   amount  tokens amount
     */
    function _transferERC20(bytes32 ilk, address to, uint amount) internal returns(bool) {
        erc20TokenContract(ilk).transfer(to, amount);
        return true;
    }

    /**
     * @notice  transfer exact amount of dai tokens, approved beforehand
     * @param   from    address of spender
     * @param   to      address of recepient
     * @param   amount  tokens amount
     */
    function _transferFromDai(address from, address to, uint amount) internal returns(bool) {
        return IERC20(mcdDaiAddr).transferFrom(from, to, amount);
    }

    /**
     * @notice  try transfer exact amount of dai tokens, approved beforehand
     * @param   from    address of spender
     * @param   to      address of recepient
     * @param   amount  tokens amount
     */
    function _callTransferFromDai(address from, address to, uint amount) internal returns(bool) {
        if ((IERC20(mcdDaiAddr).allowance(from, to) >= amount) && (IERC20(mcdDaiAddr).balanceOf(from) >= amount)) {
            return _transferFromDai(from, to, amount);
        }
        return false;
    }

    /**
     * @notice  transfer exact amount of erc20 tokens, approved beforehand
     * @param   ilk     collateral type
     * @param   from    address of spender
     * @param   to      address of recepient
     * @param   amount  tokens amount
     */
    function _transferFromERC20(bytes32 ilk, address from, address to, uint amount) internal returns(bool) {
        return erc20TokenContract(ilk).transferFrom(from, to, amount);
    }

    /**
     * @notice  Transfer Cdp ownership to guy's proxy
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
     * @notice  Get balance of dai tokens
     * @param   addr      address
     */
    function _balanceDai(address addr) internal view returns(uint) {
        return IERC20(mcdDaiAddr).balanceOf(addr);
    }

    /**
     * @notice  transfer exact amount of erc20 tokens, approved beforehand
     * @param   ilk     collateral type
     * @return  token adapter address
     * @return  token erc20 contract address
     */
    function _getCollateralAddreses(bytes32 ilk) internal pure returns(address, address payable) {
        if (ilk == "ETH-A") {
            return (mcdJoinEthaAddr, wethAddr);
        }
        if (ilk == "BAT-A") {
            return (mcdJoinBataAddr, batAddr);
        }
    }
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
    event riskyToggled(bool _isRisky);
}

// File: contracts/Agreement.sol

pragma solidity 0.5.11;







/**
 * @title Base Agreement contract
 * @notice Contract will be deployed only once as logic(implementation), proxy will be deployed for each agreement as storage
 * @dev Should not be deployed. It is being used as an abstract class
 */
contract Agreement is IAgreement, Claimable, McdWrapper {
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
     * Dai debt amount
     */
    uint256 public debtValue;

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
     * delta shows user's debt
     * if delta < 0 - it is borrower's debt to lender
     * if delta > 0 - it is lender's debt to borrower
     */
    int public delta;
    
    /**
     * @notice Grants access only to agreement's borrower
     */
    modifier onlyBorrower() {
        require(msg.sender == borrower, "Agreement: Accessible only for borrower");
        _;
    }

    /**
     * @notice Grants access only if agreement has appropriate status
     * @param _status status should be checked with
     */
    modifier hasStatus(Statuses _status) {
        require(status == _status, "Agreement: Agreement status is incorrect");
        _;
    }

    /**
     * @notice Grants access only if agreement has status before requested one
     * @param _status check before status
     */
    modifier beforeStatus(Statuses _status) {
        require(status < _status, "Agreement: Agreement status is not before requested one");
        _;
    }

    /**
    * @notice Save timestamp for current status
    */
    function _doStatusSnapshot() internal {
        statusSnapshots[uint(status)] = now;
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
    ) public payable initializer {
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
        configAddr = _configAddr;
        isETH = _isETH;
        borrower = _borrower;
        debtValue = _debtValue;
        duration = _duration;
        interestRate = _interestRate;
        collateralAmount = _collateralAmount;
        collateralType = _collateralType;
        
        _nextStatus();
        _initMcdWrapper(collateralType, isETH);
        _monitorRisky();
        emit AgreementInitiated(borrower, collateralAmount, debtValue, duration, interestRate);
    }
    
    /**
     * @notice Approve the agreement. Only for contract owner (FraFactory)
     * @return Operation success
     */
    function approveAgreement() external onlyContractOwner hasStatus(Statuses.Pending) returns(bool _success) {
        _nextStatus();
        emit AgreementApproved();

        return true;
    }
    
    /**
     * @notice Match lender to the agreement.
     * @return Operation success
     */
    function matchAgreement() external hasStatus(Statuses.Open) returns(bool _success) {
        _nextStatus();
        expireDate = now.add(duration);
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
        _pushDaiAsset(borrower, debtValue < drawnDai ? debtValue : drawnDai);

        emit AgreementMatched(lender, expireDate, cdpId, collateralAmount, debtValue, drawnDai);
        return true;
    }

    /**
     * @notice Update agreement state
     * @dev Calls needed function according to the expireDate
     * (terminates or liquidated or updates the agreement)
     * @return Operation success
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
     * @notice Cancel agreement by borrower before it is matched, change status to the correspondant one, refund
     * @return Operation success
     */
    function cancelAgreement() external onlyBorrower beforeStatus(Statuses.Active) returns(bool _success)  {
        _closeAgreement(ClosedTypes.Cancelled);
        //push to lenders internal wallet collateral locked in agreement
        _pushCollateralAsset(borrower, collateralAmount);
        return true;
    }

    /**
     * @notice Reject agreement by admin or cron job before it is matched, change status to the correspondant one, refund
     * @return Operation success
     */
    function rejectAgreement() external onlyContractOwner beforeStatus(Statuses.Active) returns(bool _success)  {
        _closeAgreement(ClosedTypes.Cancelled);
        //push to lenders internal wallet collateral locked in agreement
        _pushCollateralAsset(borrower, collateralAmount);
        return true;
    }

    /**
     * @notice Block active agreement, change status to the correspondant one, refund
     * @return Operation success
     */
    function blockAgreement() external hasStatus(Statuses.Active) onlyContractOwner returns(bool _success)  {
        _closeAgreement(ClosedTypes.Blocked);
        _refund();
        return true;
    }

    /**
     * @notice Lock additional ether as collateral to agreement cdp contract
     * @return Operation success
     */
    function lockAdditionalCollateral(uint _amount) external payable onlyBorrower beforeStatus(Statuses.Closed) returns(bool _success)  {
        if (!isETH) {
            erc20TokenContract(collateralType).transferFrom(msg.sender, address(this), _amount);
        }
        if (isStatus(Statuses.Active)) {
            if (isETH) {
                require(msg.value == _amount, "Agreement: ether sent doesn't coinside with required");
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
     * @notice withdraw dai to user's external wallet
     * @param _amount dai amount for withdrawal
     */
    function withdrawDai(uint _amount) external {
        _popDaiAsset(msg.sender, _amount);
        _transferDai(msg.sender, _amount);
    }

    /**
     * @notice withdraw collateral to user's (msg.sender) external wallet from internal wallet
     * @param _amount collateral amount for withdrawal
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
     * @notice Withdraw accidentally locked ether in the contract, can be called only after agreement is closed and all assets are refunded
     * @dev Check the current balance is more than users ether assets, and withdraw the remaining ether
     * @param _to address should be withdrawn to
     */
    function withdrawRemainingEth(address payable _to) external hasStatus(Statuses.Closed) onlyContractOwner {
        uint _remainingEth = isETH ? address(this).balance.sub(assets[borrower].collateral.add(assets[lender].collateral)) : address(this).balance;
        require(_remainingEth > 0, "Agreement: the remaining balance available for withdrawal is zero");
        _to.transfer(_remainingEth);
    }

    /**
     * @notice Get agreement main info
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
        uint _interestRate,
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
        _debtValue = debtValue;
        _interestRate = interestRate;
        _isRisky = isRisky;
    }

    function getAssets(address _holder) public view returns(uint,uint) {
        return (assets[_holder].collateral, assets[_holder].dai);
    }

    /**
     * @notice Check if agreement has appropriate status
     * @param _status status should be checked with
     */
    function isStatus(Statuses _status) public view returns(bool) {
        return status == _status;
    }

    /**
     * @notice Check if agreement has status before requested one
     * @param _status check before status
     */
    function isBeforeStatus(Statuses _status) public view returns(bool) {
        return status < _status;
    }

    /**
     * @notice Check if agreement is closed with appropriate type
     * @param _type type should be checked with
     */
    function isClosedWithType(ClosedTypes _type) public view returns(bool) {
        return isStatus(Statuses.Closed) && (closedType == _type);
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
        if ((isStatus(Statuses.Pending) && now > statusSnapshots[uint(Statuses.Pending)].add(_approveLimit)) ||
            (isStatus(Statuses.Open) && now > statusSnapshots[uint(Statuses.Open)].add(_matchLimit))
        ) {
            return true;
        }
    }

    function getCR() public view returns(uint) {
        return cdpId > 0 ? getCdpCR(collateralType, cdpId) : collateralAmount.mul(getPrice(collateralType)).div(debtValue);
    }
    function getCRBuffer() public view returns(uint) {
        return getCR().sub(getMCR(collateralType)).mul(100).div(ONE);
    }

    /**
     * @notice Close agreement
     * @param   _closedType closing type
     * @return Operation success
     */
    function _closeAgreement(ClosedTypes _closedType) internal returns(bool _success) {
        _switchStatusClosedWithType(_closedType);

        emit AgreementClosed(uint(_closedType), msg.sender);
        return true;
    }

    /**
     * @notice Updates the state of Agreement
     * @param _isLastUpdate true if the agreement is going to be terminated, false otherwise
     * @return Operation success
     */
    function _updateAgreementState(bool _isLastUpdate) public returns(bool _success) {
        // if it is last update take the time interval up to expireDate, otherwise up to current time
        uint timeInterval = (_isLastUpdate ? expireDate : now).sub(lastCheckTime);
        uint injectionAmount;
        uint drawnDai;
        uint currentDsrAnnual = rpow(getDsr(), YEAR_SECS, ONE);

        // calculate savings difference between dsr and interest rate during time interval
        int savingsDifference = int(debtValue.mul(timeInterval)).mul((int(currentDsrAnnual)).sub(int(interestRate))).div(int(YEAR_SECS));
        delta = delta.add(savingsDifference);
        lastCheckTime = now;

        uint currentDebt = uint(fromRay(delta < 0 ? -delta : delta));

        // check the current debt is above threshold
        if (currentDebt >= (_isLastUpdate ? 1 : Config(configAddr).injectionThreshold())) {
            if (delta < 0) {
                // if delta < 0 - currentDebt is borrower's debt to lender
                drawnDai = _drawDaiToCdp(collateralType, cdpId, currentDebt);
                delta = delta.add(int(toRay(drawnDai)));
                drawnTotal = drawnTotal.add(drawnDai);
            } else {
                // delta > 0 - currentDebt is lender's debt to borrower
                injectionAmount = _injectToCdpFromDsr(cdpId, currentDebt);
                delta = delta.sub(int(toRay(injectionAmount)));
                injectedTotal = injectedTotal.add(injectionAmount);
            }
        }
        
        emit AgreementUpdated(savingsDifference, delta, currentDsrAnnual, timeInterval, drawnDai, injectionAmount);
        if (drawnDai > 0)
            _pushDaiAsset(lender, drawnDai);
        _monitorRisky();
        if (_isLastUpdate)
            _refund();
        return true;
    }

    /**
     * @notice Monitor and set up or set down risky marker
     */
    function _monitorRisky() internal {
        bool _isRisky = getCRBuffer() <= Config(configAddr).riskyMargin();
        if (isRisky != _isRisky) {
            isRisky = _isRisky;
            emit riskyToggled(_isRisky);
        }
    }

    /**
     * @notice Refund agreement, push dai to lender assets, transfer cdp ownership to borrower if debt is payed
     * @return Operation success
     */
    function _refund() internal {
        _pushDaiAsset(lender, _unlockAllDai());
        _transferCdpOwnershipToProxy(cdpId, borrower);
        emit CdpOwnershipTransferred(borrower, cdpId);
    }

    /**
     * @notice Serial status transition
     */
    function _nextStatus() internal {
        _switchStatus(Statuses(uint(status) + 1));
    }

    /**
    * @notice switch to exact status
    * @param _next status that should be switched to
    */
    function _switchStatus(Statuses _next) internal {
        status = _next;
        _doStatusSnapshot();
    }

    /**
    * @notice switch status to closed with exact type
    * @param _closedType closing type
    */
    function _switchStatusClosedWithType(ClosedTypes _closedType) internal {
        _switchStatus(Statuses.Closed);
        closedType = _closedType;
    }

    /**
     * @notice Add collateral to user's internal wallet
     * @param _holder user's address
     * @param _amount collateral amount to push
     */
    function _pushCollateralAsset(address _holder, uint _amount) internal {
        assets[_holder].collateral = assets[_holder].collateral.add(_amount);
        emit AssetsCollateralPush(_holder, _amount, collateralType);
    }

    /**
     * @notice Add dai to user's internal wallet
     * @param _holder user's address
     * @param _amount dai amount to push
     */
    function _pushDaiAsset(address _holder, uint _amount) internal {
        assets[_holder].dai = assets[_holder].dai.add(_amount);
        emit AssetsDaiPush(_holder, _amount);
    }

    /**
     * @notice Take away collateral from user's internal wallet
     * @param _holder user's address
     * @param _amount collateral amount to pop
     */
    function _popCollateralAsset(address _holder, uint _amount) internal {
        assets[_holder].collateral = assets[_holder].collateral.sub(_amount);
        emit AssetsCollateralPop(_holder, _amount, collateralType);
    }

    /**
     * @notice Take away dai from user's internal wallet
     * @param _holder user's address
     * @param _amount dai amount to pop
     */
    function _popDaiAsset(address _holder, uint _amount) internal {
        assets[_holder].dai = assets[_holder].dai.sub(_amount);
        emit AssetsDaiPop(_holder, _amount);
    }

    function() external payable {}
}
