pragma solidity >=0.5.0;

import './ProxyRegistry.sol';
import './ERC20Interface.sol';

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

/**
 * @title Agreement multicollateral dai wrapper for maker dao system interaction.
 * @dev delegates calls to proxy. Oriented to exact MCD release. Current version oriented to 6th release mcd cdp.
 */
contract McdWrapper {
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

    // tokens addresses
    address public constant wethAddr = 0xb39862D7D1b11CD9B781B1473e142Cbb545A6871;
    address public constant col1Addr = 0xC644e83399F3c0b4011D3dd3C61bc8b1617253E5;

    bytes32 public constant ETH_A = 0x4554482d41000000000000000000000000000000000000000000000000000000;
    bytes32 public constant ETH_B = 0x4554482d42000000000000000000000000000000000000000000000000000000;
    bytes32 public constant COL1_A = 0x434f4c312d410000000000000000000000000000000000000000000000000000;
    uint256 constant ONE = 10 ** 27;

    /**
     * @dev Build proxy for current caller (msg.sender address)
     */
    function buildProxy() public returns (address payable) {
        return ProxyRegistry(proxyRegistryAddr).build();
    }

    /**
     * @dev Get registered proxy for current caller (msg.sender address)
     */
    function proxy() public view returns (DSProxy) {
        return ProxyRegistry(proxyRegistryAddr).proxies(address(this));
    }

    /**
     * @dev Change proxy owner to a new one
     * @param newOwner new owner address
     */
    function setOwnerProxy(address newOwner) public {
        proxy().setOwner(newOwner);
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
        proxy().execute(proxyLib, abi.encodeWithSignature('wipe(address,address,uint256,uint256)', cdpManagerAddr, mcdJoinDaiAddr, cdp, wad));
    }

    /**
     * @dev lock dai tokens to dsr(pot) contract.
     * @notice approves this amount of dai tokens to proxy before locking
     * @param wad amount of dai tokens
     */
    function lockDai(uint wad) public {
        approveDai(address(proxy()), wad);
        proxy().execute(proxyLib, abi.encodeWithSignature('dsrJoin(address,address,uint256)', mcdJoinDaiAddr, mcdPotAddr, wad));
    }
    
    /**
     * @dev unlock dai tokens from dsr(pot) contract.
     * @param wad amount of dai tokens
     */
    function unlockDai(uint wad) public {
        proxy().execute(proxyLib, abi.encodeWithSignature('dsrExit(address,address,uint256)', mcdJoinDaiAddr, mcdPotAddr, wad));
    }
    
    /**
     * @dev     unlock all dai tokens from dsr(pot) contract.
     * @return  pie amount of all dai tokens was unlocked in fact
     */
    function unlockAllDai() public returns(uint pie) {
        pie = getLockedDai();
        unlockDai(pie);
        // function will be available in further releases (11)
        //proxy().execute(proxyLib, abi.encodeWithSignature("dsrExitAll(address,address)", mcdJoinDaiAddr, mcdPotAddr));
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
        (,uint rate,,,) = VatLike(mcdVatAddr).ilks(ilk); // need to be clarified what it is in mcd. In single collateral it is: The ratio of PETH/ETH is 1.012
        (,uint chop,) = CatLike(mcdCatAddr).ilks(ilk); // penalty
        uint price = getPrice(ilk);
        return (ink * price - (chop - ONE) * art) / price;
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
        ERC20Interface(_mcdTokenAddress(ilk)).approve(to, amount);
        return true;
    }
    
    /**
     * @dev     Transfer Cdp ownership
     * @param   cdp     cdp ID
     * @param   guy     address, ownership should be transfered to
     */
    function transferCdpOwnership(uint cdp, address guy) public {
        proxy().execute(proxyLib,  abi.encodeWithSignature('give(address,uint256,address)', cdpManagerAddr, cdp, guy));
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
        address payable target = buildProxy();
        bytes memory data = abi.encodeWithSignature('execute(address,bytes)', proxyLib, abi.encodeWithSignature('openLockETHAndDraw(address,address,address,bytes32,uint256)', cdpManagerAddr, _mcdJoinAddress(ilk), mcdJoinDaiAddr, ilk, wadD));
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
    function openLockERC20AndDraw(bytes32 ilk, uint wadD, uint wadC) public returns (uint cdp) {
        address payable proxy = buildProxy();
        approveERC20(ilk, proxy, wadC);
        bytes memory response = DSProxy(proxy).execute(proxyLib, abi.encodeWithSignature('openLockGemAndDraw(address,address,address,bytes32,uint256,uint256)', cdpManagerAddr, _mcdJoinAddress(ilk), mcdJoinDaiAddr, ilk, wadC, wadD));
        assembly {
            cdp := mload(add(response, 0x20))
        }
    }
    
    /**
     * @dev     Get contract address (Basic token adapters) in maker dao system responsible for joining collateral.
     * @param   ilk     collateral type in bytes32 format
     * @return  token adapters address
     */
    function _mcdJoinAddress(bytes32 ilk) public pure returns(address){
        if (ilk == ETH_A)
            return mcdJoinEthaAddr;
        if (ilk == ETH_B)
            return mcdJoinEthbAddr;
        if (ilk == COL1_A)
            return mcdJoinCol1aAddr;
    }

    /**
     * @dev     Get erc20 token contract address
     * @param   ilk     collateral type in bytes32 format
     * @return  erc20 token address
     */
    function _mcdTokenAddress(bytes32 ilk) public pure returns(address){
        if (ilk == ETH_A || ilk == ETH_B)
            return wethAddr;
        if (ilk == COL1_A)
            return col1Addr;
    }

    /**
     * @dev     Get contract address responsible for price storage
     * @param   ilk     collateral type in bytes32 format
     * @return  pip contract address
     */
    function _mcdPip(bytes32 ilk) public view returns(PipLike pip){
        (pip,) = SpotterLike(mcdCatAddr).ilks(ilk);
    }
}