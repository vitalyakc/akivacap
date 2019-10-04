pragma solidity 0.5.11;

import './Context.sol';
import './Initializable.sol';

contract Ownable is Initializable, Context {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function initialize(address _sender) public initializer {
        owner = _sender;
        emit OwnershipTransferred(address(0), owner);
    }
    
    modifier onlyContractOwner() {
        require(owner == msg.sender, 'Not a contract owner');
        _;
    }
}

contract Claimable is Ownable {
    address internal pendingOwner;
    
    function transferOwnership(address _newOwner) public onlyContractOwner() {
        pendingOwner = _newOwner;
    }
    
    function claimOwnership() public {
        require(msg.sender == pendingOwner, 'Not a pending owner');
        owner = msg.sender;
        pendingOwner = address(0);
    }
}
