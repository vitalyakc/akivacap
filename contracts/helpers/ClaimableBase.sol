pragma solidity 0.5.12;

contract OwnableBase {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    function isOwner() public view returns(bool) {
        return (owner == msg.sender);
    }
    
    modifier onlyContractOwner() {
        require(isOwner(), "Not a contract owner");
        _;
    }
}

contract ClaimableBase is OwnableBase {
    address public pendingOwner;
    
    function transferOwnership(address _newOwner) public onlyContractOwner() {
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
