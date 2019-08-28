pragma solidity >=0.5.0;

import "./ProxyRegistry.sol";

contract DaiLike {
    function approve(address usr, uint wad) external returns (bool);
}

contract McdWrapper {
    address public constant proxyRegistryAddr = 0xda657E86db3e76BDa6d88e6a09798F0BBF5bDf75;
    address public constant proxyLib = 0x3B444f91f86d162C991D5EC048464C93b0890aE2;
    address public constant cdpManagerAddr = 0xd2e8d886Bc185Df6f437E22DF923DdF419daD4B8;
    address public constant mcdDaiAddr = 0xc7cC3413f169a027dccfeffe5208Ca4f38eF0c40;
    address public constant mcdJoinDaiAddr = 0x7bb403AAE0330F1aCAAd8F2a06ebe4b4e4784418;
    address public constant mcdVatAddr = 0xaCdd1ee0F74954Ed8F0aC581b081B7b86bD6aad9;
    address public constant getCdpsAddr = 0x81dD44A647dAC3e052D8EAf2C9F11ED3a9941DD7;
    address public constant wethAddr = 0xb39862D7D1b11CD9B781B1473e142Cbb545A6871;
    address public constant mcdJoinEthaAddr = 0x75f0660705EF0dB9adde85337980F579626643af;
    address public constant mcdPotAddr = 0xBb3571B3F1151a2f0545a297363ACddC87099FF5;
    
    function buildProxy() public returns (address payable) {
        return ProxyRegistry(proxyRegistryAddr).build(msg.sender);
    }
    
    function proxy() public view returns (DSProxy) {
        return ProxyRegistry(proxyRegistryAddr).proxies(msg.sender);
    }
    
    function setOwnerProxy(address newOwner) public {
        proxy().setOwner(newOwner);
    }
    
    function openCdp1(bytes32 ilk) public returns (bool success,bytes memory data)  {
        (success, data) = address(proxy()).call(abi.encodeWithSignature("execute(address,bytes)", proxyLib, abi.encodeWithSignature("open(address,bytes32)", cdpManagerAddr, ilk)));
    }
    
    function openCdp(bytes32 ilk) public  {
        proxy().execute(proxyLib,  abi.encodeWithSignature("open(address,bytes32)", cdpManagerAddr, ilk));
    }
    
    function give(uint cdp, address guy) public {
        proxy().execute(proxyLib,  abi.encodeWithSignature("give(address,uint,address)", cdpManagerAddr, cdp, guy));
    }
    
    function allow(uint cdp, address guy, uint ok) public {
        proxy().execute(proxyLib,  abi.encodeWithSignature("allow(uint,address,uint)", cdpManagerAddr, cdp, guy, ok));
    }
    
    function lockETH(uint cdp) public payable {
        (bool success,) = address(proxy()).call.value(msg.value)(abi.encodeWithSignature("execute(address,bytes)", proxyLib, abi.encodeWithSignature("lockETH(address,address,uint)", cdpManagerAddr, mcdJoinEthaAddr, cdp)));
        require(success, "");
    }
    
    function freeETH(uint cdp, uint wad) public {
        proxy().execute(proxyLib,  abi.encodeWithSignature("freeETH(address,address,uint,uint)", cdpManagerAddr, mcdJoinEthaAddr, cdp, wad));
    }
    
    function lockETHAndDraw(uint cdp, uint wadD) public payable {        
        (bool success,) = address(proxy()).call.value(msg.value)(abi.encodeWithSignature("execute(address,bytes)", proxyLib, abi.encodeWithSignature("lockETHAndDraw(address,address,address,uint,uint)", cdpManagerAddr, mcdJoinEthaAddr, mcdJoinDaiAddr, cdp, wadD)));
        require(success, "");
    }
    
    function openLockETHAndDraw(bytes32 ilk, uint wadD) public payable returns (uint cdp) {
        address payable target = address(proxy());
        bytes memory data = abi.encodeWithSignature("execute(address,bytes)", proxyLib, abi.encodeWithSignature("openLockETHAndDraw(address,address,address,bytes32,uint)", cdpManagerAddr, mcdJoinEthaAddr, mcdJoinDaiAddr, ilk, wadD));
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
        proxy().execute(proxyLib, abi.encodeWithSignature("wipeAndFreeETH(address,address,address,uint,uint,uint)", cdpManagerAddr, mcdJoinEthaAddr, mcdJoinDaiAddr, cdp, wadC, wadD));
    }
    
    function wipe(uint cdp, uint wad) public {
        proxy().execute(proxyLib, abi.encodeWithSignature("wipe(address,address,uint,uint)", cdpManagerAddr, mcdJoinDaiAddr, cdp, wad));
    }
    
    function dsrJoin(uint wad) public {
        proxy().execute(proxyLib, abi.encodeWithSignature("dsrJoin(address,address,uint)", mcdJoinDaiAddr, mcdPotAddr, wad));
    }
    
    function dsrExit(uint wad) public {
        proxy().execute(proxyLib, abi.encodeWithSignature("dsrExit(address,address,uint)", mcdJoinDaiAddr, mcdPotAddr, wad));
    }
    
    function dsrExitAll() public {
        proxy().execute(proxyLib, abi.encodeWithSignature("dsrExitAll(address,address)", mcdJoinDaiAddr, mcdPotAddr));
    }
    
    function draw(uint cdp, uint wad) public {
        proxy().execute(proxyLib, abi.encodeWithSignature("draw(address,address,uint,uint)", cdpManagerAddr, mcdJoinDaiAddr, cdp, wad));
    }
    
    function approveDai(address to, uint amount) public returns(bool) {
        DaiLike(mcdDaiAddr).approve(to, amount);
        return true;
    }
}