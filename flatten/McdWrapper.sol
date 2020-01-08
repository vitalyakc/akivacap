
// File: contracts\mcd\McdAddressesR17.sol

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

// File: contracts\interfaces\IMcd.sol

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

// File: contracts\interfaces\IERC20.sol

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

// File: contracts\mcd\McdWrapper.sol

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

    function getCR(bytes32 ilk, uint cdpId) public view returns(uint) {
        (, uint rate, uint spot,,) = VatLike(mcdVatAddr).ilks(ilk);
        (uint ink, uint art) = VatLike(mcdVatAddr).urns(ilk, ManagerLike(cdpManagerAddr).urns(cdpId));
        (,uint mat) = SpotterLike(mcdSpotAddr).ilks(ilk);
        return ink.mul(spot).mul(ONE).div(art.mul(rate).mul(mat));
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
