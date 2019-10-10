
// File: contracts/SafeMath.sol

pragma solidity 0.5.11;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/contracts@next`.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/contracts@next`.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/contracts@next`.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/helpers/RaySupport.sol

pragma solidity 0.5.11;


contract RaySupport {
    using SafeMath for uint256;
    uint256 constant public ONE = 10 ** 27;

    function toWad(uint _val) public pure returns(uint) {
        return _val.mul(ONE);
    }

    function fromWad(uint _val) public pure returns(uint) {
        return _val.div(ONE);
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

// File: contracts/config/McdAddresses.sol

pragma solidity 0.5.11;

contract McdAddressesR6 {
    uint public constant release = 6;
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

contract McdAddressesR13 {
    uint public constant release = 13;
    address public constant proxyRegistryAddr = 0x64A436ae831C1672AE81F674CAb8B6775df3475C;
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

contract McdAddressesR14 {
    uint public constant RELEASE = 14;
    address public constant proxyRegistryAddr = 0x64A436ae831C1672AE81F674CAb8B6775df3475C;
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
contract McdConfig is McdAddressesR14, RaySupport {
    struct CollateralAddresses{
        bytes32 ilk;
        address mcdJoinAddr;
        address payable baseAddr;
    }
    mapping(bytes32 => CollateralAddresses) public collateralTypes;

    constructor() public {
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

// File: contracts/McdWrapper.sol

pragma solidity >=0.5.0;




/**
 * @title Agreement multicollateral dai wrapper for maker dao system interaction.
 * @dev delegates calls to proxy. Oriented to exact MCD release. Current version oriented to 6th release mcd cdp.
 */
contract McdWrapper is McdConfig {
    address public proxyAddr;
    mapping(bytes32 => bool) collateralTypesAvailable;
    /**
     * @dev Build proxy for current caller (msg.sender address)
     */
    function buildProxy() public returns (address payable) {
        return ProxyRegistryLike(proxyRegistryAddr).build();
    }

    /**
     * @dev Get registered proxy for current caller (msg.sender address)
     */
    function proxy() public view returns (DSProxyLike) {
        if (proxyAddr == address(0)) {
            return DSProxyLike(buildProxy());
        } else {
            return DSProxyLike(proxyAddr);
        }
    }

    /**
     * @dev Get registered proxy for current caller (msg.sender address)
     */
    function proxyAddress() public view returns (address) {
        if (proxyAddr == address(0)) {
            return buildProxy();
        } else {
            return proxyAddr;
        }
    }

    /**
     * @dev Change proxy owner to a new one
     * @param newOwner new owner address
     */
    function setOwnerProxy(address newOwner) public {
        proxy().setOwner(newOwner);
    }

    function openCdp(bytes32 ilk) public returns (uint cdp) {
        bytes memory response = proxy().execute(proxyLib, abi.encodeWithSignature(
            'open(address,bytes32,uint256,uint256)',
            cdpManagerAddr, ilk));
        assembly {
            cdp := mload(add(response, 0x20))
        }
    }

    function lockETHAndDraw(bytes32 ilk, uint cdp, uint wadC, uint wadD) public {
        bytes memory data;
        data = abi.encodeWithSignature(
            'lockETHAndDraw(address,address,address,address,uint256,uint256)',
            cdpManagerAddr, mcdJugAddr, collateralTypes[ilk].mcdJoinAddr, mcdJoinDaiAddr, cdp, wadD);
        proxyAddress().call.value(wadC)(abi.encodeWithSignature("execute(address,bytes)", proxyLib, data));
    }

    /**
     * @dev     Create new cdp with ERC-20 tokens as collateral, lock collateral and draw dai
     * @notice  build new Proxy for a caller before cdp creation and approve transferFrom collateral token from Agrrement by Proxy
     * @param   ilk     collateral type in bytes32 format
     * @param   wadD    dai amount to be drawn
     * @param   wadC    collateral amount to be locked in cdp contract
     * @return  cdp     cdp ID
     */
    function lockERC20AndDraw(bytes32 ilk, uint cdp, uint wadD, uint wadC, bool transferFrom) public {
        approveERC20(ilk, proxy(), wadC);
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
    function openLockETHAndDraw(bytes32 ilk, uint wadD, uint wadC) public returns (uint cdp) {
        bytes memory data = abi.encodeWithSignature(
            'execute(address,bytes)',
            proxyLib,
            abi.encodeWithSignature('openLockETHAndDraw(address,address,address,address,bytes32,uint256)',
            cdpManagerAddr, mcdJugAddr, collateralTypes[ilk].mcdJoinAddr, mcdJoinDaiAddr, ilk, wadD));
        assembly {
            let succeeded := call(sub(gas, 5000), proxyAddress(), wadC, add(data, 0x20), mload(data), 0, 0)
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
    function openLockERC20AndDraw(bytes32 ilk, uint wadD, uint wadC) public returns (uint cdp) {
        approveERC20(ilk, proxy(), wadC);
        bytes memory response = proxy().execute(proxyLib, abi.encodeWithSignature(
            'openLockGemAndDraw(address,address,address,address,bytes32,uint256,uint256)',
            cdpManagerAddr, mcdJugAddr, collateralTypes[ilk].mcdJoinAddr, mcdJoinDaiAddr, ilk, wadC, wadD));
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
    function injectToCdp(uint cdp, uint wad) public {
        approveDai(address(proxy()), wad);
        wipe(cdp, wad);
    }

    /**
     * @dev pay off some amount of dai to cdp
     * @param cdp cdp ID
     * @param wad amount of dai tokens
     */
    function wipe(uint cdp, uint wad) public {
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
    function lockDai(uint wad) public {
        // transfer dai from borrower to agreement
        _transferFromDai(msg.sender, address(this), wad);
        approveDai(address(proxy()), wad);
        proxy().execute(
            proxyLibDsr,
            abi.encodeWithSignature('join(address,address,uint256)',
            mcdJoinDaiAddr, mcdPotAddr, wad));
    }

    /**
     * @dev unlock dai tokens from dsr(pot) contract.
     * @param wad amount of dai tokens
     */
    function unlockDai(uint wad) public {
        proxy().execute(
            proxyLibDsr,
            abi.encodeWithSignature('exit(address,address,uint256)',
            mcdJoinDaiAddr, mcdPotAddr, wad));
    }

    /**
     * @dev     unlock all dai tokens from dsr(pot) contract.
     * @return  pie amount of all dai tokens was unlocked in fact
     */
    function unlockAllDai() public returns(uint pie) {
        pie = getLockedDai();
        unlockDai(pie);
        // function will be available in further releases (11)
        //proxy().execute(proxyLib, abi.encodeWithSignature("exitAll(address,address)", mcdJoinDaiAddr, mcdPotAddr));
    }

    function cashETH(bytes32 ilk, uint wad) public {
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
    function forceLiquidate(bytes32 ilk, uint cdpId) public view returns(uint) {
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
    function approveDai(address to, uint amount) public returns(bool) {
        ERC20Interface(mcdDaiAddr).approve(to, amount);
        return true;
    }

    /**
     * @dev     Approve exact amount of erc20 tokens for transferFrom
     * @param   to      address allowed to call transferFrom
     * @param   amount  tokens amount for approval
     */
    function approveERC20(bytes32 ilk, address to, uint amount) public returns(bool) {
        ERC20Interface(collateralTypes[ilk].mcdJoinAddr).approve(to, amount);
        return true;
    }
    
    /**
     * @dev     transfer exact amount of dai tokens
     * @param   to      address of recepient
     * @param   amount  tokens amount
     */
    function transferDai(address from, address to, uint amount) public returns(bool) {
        ERC20Interface(mcdDaiAddr).transfer(to, amount);
        return true;
    }

    /**
     * @dev     transfer exact amount of erc20 tokens
     * @param   to      address of recepient
     * @param   amount  tokens amount
     */
    function transferERC20(bytes32 ilk, address from, address to, uint amount) public returns(bool) {
        ERC20Interface(collateralTypes[ilk].baseAddr).transfer(to, amount);
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
     * @dev     transfer exact amount of erc20 tokens, approved beforehand
     * @param   from    address of spender
     * @param   to      address of recepient
     * @param   amount  tokens amount
     */
    function transferFromERC20(bytes32 ilk, address from, address to, uint amount) public returns(bool) {
        ERC20Interface(collateralTypes[ilk].baseAddr).transferFrom(from, to, amount);
        return true;
    }
    
    /**
     * @dev     Transfer Cdp ownership
     * @param   cdp     cdp ID
     * @param   guy     address, ownership should be transfered to
     */
    function transferCdpOwnership(uint cdp, address guy) public {
        proxy().execute(
            proxyLib,
            abi.encodeWithSignature('give(address,uint256,address)',
            cdpManagerAddr, cdp, guy));
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
