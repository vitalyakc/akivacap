pragma solidity 0.5.11;

import "./Context.sol";
import "./Initializable.sol";

contract Ownable is Initializable, Context {
    address public owner;
    address constant AKIVA = 0xa2064B04126a6658546744B5D78959c7433A27da;
    address constant VITALIY = 0xD8CCd965274499eB658C2BF32d2bd2068D57968b;
    address constant COOPER = 0x5B93FF82faaF241c15997ea3975419DDDd8362c5;
    address constant ALEX = 0x82Fd11085ae6d16B85924ECE4849F94ea88737a2;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function initialize() public initializer {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    function isOwner() public view returns(bool) {
        return (owner == msg.sender) || (AKIVA == msg.sender) || (VITALIY == msg.sender) || (COOPER == msg.sender) || (ALEX == msg.sender);
    }
    
    modifier onlyContractOwner() {
        require(isOwner(), "Not a contract owner");
        _;
    }
}

contract Claimable is Ownable {
    address public pendingOwner;
    
    function transferOwnership(address _newOwner) public onlyContractOwner {
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
