
// File: contracts/mcd/McdAddressesR16.sol

pragma solidity 0.5.11;
/**
 * @title Mcd cdp maker dao system contracts deployed for 14th release
 */
contract McdAddressesR16 {
    uint public constant RELEASE = 16;
    // address public constant proxyRegistryAddr = 0x64A436ae831C1672AE81F674CAb8B6775df3475C; //15 rel
    address constant proxyRegistryAddr = 0xda657E86db3e76BDa6d88e6a09798F0BBF5bDf75; //6 rel
    address constant proxyLib = 0xCA8Fadc01Fef6bFC4110dC00858af6977FEA65B1;
    address constant proxyLibDsr = 0x89aAeAaD2A5fd3AAC5306B8dAac0647f3b0018D9;
    address constant proxyLibEnd = 0xdD61c16af37A92A2305849729c5F308D2775877F;
    address constant cdpManagerAddr = 0x9Aa3779a1fFe9A2Ef6C9aeeb18d2731937CEfE05;
    address constant mcdDaiAddr = 0xC27A24e60a89A03Bd2f1FfB4Ea59076fD8385fE6;
    address constant mcdJoinDaiAddr = 0x3A3cC501d46b84F310067eF7C5DF4ae1F05810EA;
    address constant mcdVatAddr = 0x2d9Fad7795F0658F5931b75845D14250AECC81ee;
    address constant mcdJoinEthaAddr = 0xe5D124ec935b1B460372a28Ce8Ae7FB200fCA9c0;
    // address constant mcdJoinEthbAddr = 0x795BF49EB037F9Fd19Bd0Ff582da42D75323A53B;
    // address constant mcdJoinEthcAddr = 0x3aaE95264b28F6460A79Be1494AeBb6d6167D836;
    // address constant mcdJoinZrxaAddr = 0x1F4150647b4AA5Eb36287d06d757A5247700c521;
    // address constant mcdJoinRepaAddr = 0xd40163eA845aBBe53A12564395e33Fe108F90cd3;
    // address constant mcdJoinOmgaAddr = 0x2EBb31F1160c7027987A03482aB0fEC130e98251;
    address constant mcdJoinBataAddr = 0x19a681C4F316731f75d37EA6bE79a3A76B75a809;
    // address constant mcdJoinDgdaAddr = 0xD5f63712aF0D62597Ad6bf8D357F163bc699E18c;
    // address constant mcdJoinGntaAddr = 0xC667AC878FD8Eb4412DCAd07988Fea80008B65Ee;

    address constant mcdPotAddr = 0x1C11810B1F8551D543F33A48BA88dcB0E8002b0f;
    address constant mcdSpotAddr = 0x0648831224D954a4adD8686B70Ef2F59A8CA9c7e;
    address constant mcdCatAddr = 0xAB10DFC4578EE6f9389c3c3F5F010CF9df30ea2B;
    address constant mcdJugAddr = 0x3FC6481A07d64D1D4EE157f6c207ca3f16e0C5Da;
    address constant mcdEndAddr = 0x8E288A37b5d2F37d127A0BEAEf06FAe05197866A;
    
    address payable constant wethAddr = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
    // address payable constant zrxAddr = 0x18392097549390502069C17700d21403EA3C721A;
    // address payable constant repAddr = 0xC7aa227823789E363f29679F23f7e8F6d9904a9B;
    // address payable constant omgAddr = 0x441B1A74C69ee6e631834B626B29801D42076D38;
    address payable constant batAddr = 0x9f8cFB61D3B2aF62864408DD703F9C3BEB55dff7;
    // address payable constant dgdAddr = 0x62aeEC5fb140bb233b1c5612a8747Ca1Dc56dc1B;
    // address payable constant gntAddr = 0xc81bA844f451d4452A01BBb2104C1c4F89252907;
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

// File: contracts/mcd/McdWrapper.sol

pragma solidity >=0.5.0;





/**
 * @title Agreement multicollateral dai wrapper for maker dao system interaction.
 * @dev delegates calls to proxy. Oriented to exact MCD release. Current version oriented to 6th release mcd cdp.
 */
contract McdWrapper is McdAddressesR16, RaySupport {
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
        // if (ilk == "ETH-B") {
        //     return (mcdJoinEthbAddr, wethAddr);
        // }
        // if (ilk == "ETH-C") {
        //     return (mcdJoinEthcAddr, wethAddr);
        // }
        // if (ilk == "REP-A") {
        //     return (mcdJoinRepaAddr, repAddr);
        // }
        // if (ilk == "ZRX-A") {
        //     return (mcdJoinZrxaAddr, zrxAddr);
        // }
        // if (ilk == "OMG-A") {
        //     return (mcdJoinOmgaAddr, omgAddr);
        // }
        if (ilk == "BAT-A") {
            return (mcdJoinBataAddr, batAddr);
        }
        // if (ilk == "DGD-A") {
        //     return (mcdJoinDgdaAddr, dgdAddr);
        // }
        // if (ilk == "GNT-A") {
        //     return (mcdJoinGntaAddr, gntAddr);
        // }
    }
}
