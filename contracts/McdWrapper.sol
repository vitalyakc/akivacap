pragma solidity >=0.5.0;

import './ProxyRegistry.sol';

contract DaiLike {
    function approve(address usr, uint wad) external returns (bool);
}

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

contract McdWrapper {
    address public constant proxyRegistryAddr = 0xda657E86db3e76BDa6d88e6a09798F0BBF5bDf75;
    address public constant proxyLib = 0x3B444f91f86d162C991D5EC048464C93b0890aE2;
    address public constant cdpManagerAddr = 0xd2e8d886Bc185Df6f437E22DF923DdF419daD4B8;
    address public constant mcdDaiAddr = 0xc7cC3413f169a027dccfeffe5208Ca4f38eF0c40;
    address public constant mcdJoinEthbAddr = 0xD53f951608e7F9feB3763dc2fAf89FaAA545d8F2;
    address public constant mcdJoinDaiAddr = 0x7bb403AAE0330F1aCAAd8F2a06ebe4b4e4784418;
    address public constant mcdVatAddr = 0xaCdd1ee0F74954Ed8F0aC581b081B7b86bD6aad9;
    address public constant getCdpsAddr = 0x81dD44A647dAC3e052D8EAf2C9F11ED3a9941DD7;
    address public constant wethAddr = 0xb39862D7D1b11CD9B781B1473e142Cbb545A6871;
    address public constant mcdJoinEthaAddr = 0x75f0660705EF0dB9adde85337980F579626643af;
    address public constant mcdPotAddr = 0xBb3571B3F1151a2f0545a297363ACddC87099FF5;
    address public constant mcdSpotAddr = 0x888C83473C72467C2D5289dCD6Ab26cCb8b00bd0;
    address public constant mcdCatAddr = 0x81F7Aa9c1570de564eB511b3a1e57DAe558C65b5;

    bytes32 public constant ETH_A = 0x4554482d41000000000000000000000000000000000000000000000000000000;
    bytes32 public constant ETH_B = 0x4554482d42000000000000000000000000000000000000000000000000000000;
    uint256 constant ONE = 10 ** 27;

    function buildProxy() public returns (address payable) {
        return ProxyRegistry(proxyRegistryAddr).build();
    }
    
    function proxyAddress(address _proxyOwner) public view returns (address) {
        return address(ProxyRegistry(proxyRegistryAddr).proxies(_proxyOwner));
    }

    function proxy() public view returns (DSProxy) {
        return ProxyRegistry(proxyRegistryAddr).proxies(address(this));
    }
    
    function setOwnerProxy(address newOwner) public {
        proxy().setOwner(newOwner);
    }
    
    function openEthaCdp(uint wadD) public payable returns (uint cdp) {
        return openLockETHAndDraw(mcdJoinEthaAddr, ETH_A, wadD);
    }

    function openEthaCdpNonPayable(uint wadC, uint wadD) public returns (uint cdp) {
        return this.openEthaCdp.value(wadC)(wadD);
    }
    
    function openEthbCdp(uint wadD) public payable returns (uint cdp) {
        return openLockETHAndDraw(mcdJoinEthbAddr, ETH_B, wadD);
    }
    
    function injectToCdp(uint cdp, uint wad) public {
        approveDai(address(proxy()), wad);
        wipe(cdp, wad);
    }
    
    function lockDai(uint wad) public {
        approveDai(address(proxy()), wad);
        proxy().execute(proxyLib, abi.encodeWithSignature('dsrJoin(address,address,uint256)', mcdJoinDaiAddr, mcdPotAddr, wad));
    }
    
    function unlockDai(uint wad) public {
        proxy().execute(proxyLib, abi.encodeWithSignature('dsrExit(address,address,uint256)', mcdJoinDaiAddr, mcdPotAddr, wad));
    }
    
    function unlockAllDai() public returns(uint pie) {
        pie = getLockedDai();
        unlockDai(pie);
        //proxy().execute(proxyLib, abi.encodeWithSignature("dsrExitAll(address,address)", mcdJoinDaiAddr, mcdPotAddr));
    }
    
    function getLockedDai() public view returns(uint256) {
        return PotLike(mcdPotAddr).pie(address(proxy()));
    }
    
    function getDsr() public view returns(uint) {
        return PotLike(mcdPotAddr).dsr();
    }

    /**
     *  To determine how much collateral you would possess after a Liquidation you can use the following simplified formula:
     *  (Collateral * Oracle Price * PETH/ETH Ratio) - (Liquidation Penalty * Stability Debt) - Stability Debt = (Remaining Collateral * Oracle Price) DAI
     */
    function forceLiquidate(bytes32 ilk, uint cdpId) public view returns(uint) {
        address urn = ManagerLike(cdpManagerAddr).urns(cdpId);
        (uint ink, uint art) = VatLike(mcdVatAddr).urns(ilk, urn);
        (,uint rate,,,) = VatLike(mcdVatAddr).ilks(ilk); // need to be clarified what it os in mcd. In single collateral it is: The ratio of PETH/ETH is 1.012
        (,uint chop,) = CatLike(mcdCatAddr).ilks(ilk); // penalty
        chop = 1100000000000000000000000000;
        uint price = getPrice(ilk);
        return (ink * price - (chop - ONE) * art) / price;
    }

    function getCollateralEquivalent(bytes32 ilk, uint daiAmount) public view returns(uint) {
        // (,, uint spot,,) = VatLike(mcdVatAddr).ilks(ilk);
        uint price = getPrice(ilk);
        uint ethAmount = daiAmount * ONE / price;
        if (ethAmount * price / ONE == daiAmount)
        {
            return ethAmount;
        }
        else return ethAmount + 1;
    }

    function getCdpInfo(bytes32 ilk, uint cdpId) public view returns(uint ink, uint art) {
        address urn = ManagerLike(cdpManagerAddr).urns(cdpId);
        (ink, art) = VatLike(mcdVatAddr).urns(ilk, urn);
    }

    function getPie(address _proxy) public view returns(uint256) {
        return PotLike(mcdPotAddr).pie(_proxy);
    }

    function getPrice(bytes32 ilk) public view returns(uint) {
        return getSafePrice(ilk) * getLiquidationRatio(ilk) / ONE;
    }

    function getSafePrice(bytes32 ilk) public view returns(uint) {
        (,, uint spot,,) = VatLike(mcdVatAddr).ilks(ilk);
        return spot;
    }

    function getLiquidationRatio(bytes32 ilk) public view returns(uint) {
        (,uint mat) = SpotterLike(mcdSpotAddr).ilks(ilk);
        return mat;
    }

    function isCDPLiquidated(bytes32 ilk, uint cdpId) public view returns(bool) {
        return false;
    }
     
    function wipe(uint cdp, uint wad) public {
        proxy().execute(proxyLib, abi.encodeWithSignature('wipe(address,address,uint256,uint256)', cdpManagerAddr, mcdJoinDaiAddr, cdp, wad));
    }
    
    function approveDai(address to, uint amount) public returns(bool) {
        DaiLike(mcdDaiAddr).approve(to, amount);
        return true;
    }
    
    function open(bytes32 ilk) public returns(uint cdp)  {
        bytes memory response = proxy().execute(proxyLib,  abi.encodeWithSignature('open(address,bytes32)', cdpManagerAddr, ilk));
        assembly {
            cdp := mload(add(response, 0x20))
        }
    }
    
    function transferCdpOwnership(uint cdp, address guy) public {
        proxy().execute(proxyLib,  abi.encodeWithSignature('give(address,uint256,address)', cdpManagerAddr, cdp, guy));
    }
    
    function allow(uint cdp, address guy, uint ok) public {
        proxy().execute(proxyLib,  abi.encodeWithSignature('allow(uint256,address,uint256)', cdpManagerAddr, cdp, guy, ok));
    }
    
     function lockETH(address, address, uint) public payable {
        (bool success,) = address(proxy()).call.value(msg.value)(abi.encodeWithSignature('execute(address,bytes)', proxyLib, msg.data));
        require(success, '');
    }
    
    function lockETHWrapper(uint cdp) public payable {
        (bool success,) = address(proxy()).call.value(msg.value)(abi.encodeWithSignature('execute(address,bytes)', proxyLib, abi.encodeWithSignature('lockETH(address,address,uint256)', cdpManagerAddr, mcdJoinEthaAddr, cdp)));
        require(success, '');
    }
    
    function freeETH(uint cdp, uint wad) public {
        proxy().execute(proxyLib,  abi.encodeWithSignature('freeETH(address,address,uint256,uint256)', cdpManagerAddr, mcdJoinEthaAddr, cdp, wad));
    }
    
    function lockETHAndDraw(uint cdp, uint wadD) public payable {        
        (bool success,) = address(proxy()).call.value(msg.value)(abi.encodeWithSignature('execute(address,bytes)', proxyLib, abi.encodeWithSignature('lockETHAndDraw(address,address,address,uint256,uint256)', cdpManagerAddr, mcdJoinEthaAddr, mcdJoinDaiAddr, cdp, wadD)));
        require(success, '');
    }
    
    function openLockETHAndDraw(address mcdJoinCollateralAddr, bytes32 ilk, uint wadD) public payable returns (uint cdp) {
        address payable target = buildProxy();
        bytes memory data = abi.encodeWithSignature('execute(address,bytes)', proxyLib, abi.encodeWithSignature('openLockETHAndDraw(address,address,address,bytes32,uint256)', cdpManagerAddr, mcdJoinCollateralAddr, mcdJoinDaiAddr, ilk, wadD));
        assembly {
            let succeeded := call(sub(gas, 5000), target, callvalue, add(data, 0x20), mload(data), 0, 0)
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
    
    function wipeAndFreeETH(uint cdp, uint wadC, uint wadD) public {
        proxy().execute(proxyLib, abi.encodeWithSignature('wipeAndFreeETH(address,address,address,uint256,uint256,uint256)', cdpManagerAddr, mcdJoinEthaAddr, mcdJoinDaiAddr, cdp, wadC, wadD));
    }
    
    function draw(uint cdp, uint wad) public {
        proxy().execute(proxyLib, abi.encodeWithSignature('draw(address,address,uint256,uint256)', cdpManagerAddr, mcdJoinDaiAddr, cdp, wad));
    }
    
    function quit(uint cdp, address dst) public {
        proxy().execute(proxyLib, abi.encodeWithSignature('draw(address,address,uint256,uint256)', cdpManagerAddr, cdp, dst));
    }
}
