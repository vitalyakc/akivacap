pragma solidity 0.5.12;

/**
 * @title Interfaces for maker dao mcd contracts
 */
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
    function drip(bytes32 ilk) external returns (uint);
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
    function build() public returns (address payable);
    function build(address) public returns (address payable);
}

contract DSProxyLike {
    function execute(bytes memory, bytes memory) public payable returns (address, bytes memory);
    function execute(address, bytes memory) public payable returns (bytes memory);
    function setOwner(address) public;
}

contract IlkRegistryLike {
    function pos(bytes32 ilk) public view returns (uint); 
    function gem(bytes32) public view returns (address);
    function join(bytes32) public view returns (address payable);
}