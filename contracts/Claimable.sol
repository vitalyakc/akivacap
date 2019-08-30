pragma solidity 0.5.11;

contract Ownable {
    address public owner;
    
    constructor () public {
        owner = msg.sender;
    }
    
    modifier onlyContractOwner() {
        require(owner == msg.sender);
        _;
    }
}

contract Claimable is Ownable {
    address internal pendingOwner;
    
    function transferOwnership(address _newOwner) public onlyContractOwner() {
        pendingOwner = _newOwner;
    }
    
    function claimOwnership() public {
        require(msg.sender == pendingOwner);
        owner = msg.sender;
        pendingOwner = address(0);
    }
}
