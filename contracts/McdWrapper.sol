pragma solidity >=0.5.0;

import "./ProxyRegistry.sol";


contract DaiLike {
    function approve(address usr, uint wad) external returns (bool);
}

contract McdWrapper {
    address public proxyRegistryAddr;
    address public proxyLib;
    address public cdpManagerAddr;
    address public mcdDaiAddr;
    address public mcdJoinDaiAddr;
    address public mcdVat;
    address public getCdpsAddr;
    address public wethAddr;
    address public mcdJoinEthaAddr;
    
    constructor() public {
        proxyRegistryAddr = 0xda657E86db3e76BDa6d88e6a09798F0BBF5bDf75;
        proxyLib = 0x3B444f91f86d162C991D5EC048464C93b0890aE2;
        cdpManagerAddr = 0xd2e8d886Bc185Df6f437E22DF923DdF419daD4B8;
        mcdDaiAddr = 0xc7cC3413f169a027dccfeffe5208Ca4f38eF0c40;
        mcdJoinDaiAddr = 0x7bb403AAE0330F1aCAAd8F2a06ebe4b4e4784418;
        mcdVat = 0xaCdd1ee0F74954Ed8F0aC581b081B7b86bD6aad9;
        getCdpsAddr = 0x81dD44A647dAC3e052D8EAf2C9F11ED3a9941DD7;
        wethAddr = 0xb39862D7D1b11CD9B781B1473e142Cbb545A6871;
        mcdJoinEthaAddr = 0x75f0660705EF0dB9adde85337980F579626643af;
    }
    
    function buildProxy() public returns (address payable proxy) {
        proxy = ProxyRegistry(proxyRegistryAddr).build(msg.sender);
    }

    function proxy() public view returns (DSProxy) {
        return ProxyRegistry(proxyRegistryAddr).proxies(msg.sender);
    }
    
    // function setOwnerProxy(address _owner) public {
    //     proxy().setOwner(_owner);
    //     address(proxy()).delegatecall(abi.encodeWithSignature("setOwner(address)", _owner));
    // }
    
    function transfer(address, address, uint256) public {
        proxy().execute(proxyLib, msg.data);
    }
    

    function openCdp(bytes32 ilk) public  {
        address(proxy()).call(abi.encodeWithSignature("execute(address,bytes)", proxyLib,  abi.encodeWithSignature("open(address,bytes32)", cdpManagerAddr, ilk)));
    }
    
    function openCdp1(bytes32 ilk) public  {
        proxy().execute(proxyLib,  abi.encodeWithSignature("open(address,bytes32)", cdpManagerAddr, ilk));
    }
    
    function open(address, bytes32) public returns (uint cdp) {
        bytes memory response = proxy().execute(proxyLib, msg.data);
        assembly {
            cdp := mload(add(response, 0x20))
        }
    }

}