pragma solidity 0.5.12;

/**
 * @title   Ownable contract
 * @dev     Contract has all neccessary ownable functions but doesn't have initialization
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev     Grants access only for owner
     */
    modifier onlyContractOwner() {
        require(isOwner(msg.sender), "Ownable: Not a contract owner");
        _;
    }

    /**
     * @dev     Check if address is  owner
     */
    function isOwner(address _addr) public view returns(bool) {
        return owner == _addr;
    }

    /**
     * @dev     Set initial owner
     * @param   _addr   owner address
     */
    function _setInitialOwner(address _addr) internal {
        owner = _addr;
        emit OwnershipTransferred(address(0), owner);
    }
}

/**
 * @title   Base Claimable contract
 * @dev     The same as Ownable but with two-step ownership transfering procedure
 *          Contract has all neccessary Claimable functions for transfer and claim ownership
 */
contract Claimable is Ownable {
    address public pendingOwner;

    /**
     * @dev     Transfer ownership
     * @param   _newOwner   address, the ownership should be transferred to, becomes pending until claim
     */
    function transferOwnership(address _newOwner) public onlyContractOwner {
        pendingOwner = _newOwner;
    }

    /**
     * @dev     Approve pending owner by new owner
     */
    function claimOwnership() public {
        require(msg.sender == pendingOwner, "Claimable: Not a pending owner");

        address previousOwner = owner;
        owner = msg.sender;
        pendingOwner = address(0);

        emit OwnershipTransferred(previousOwner, msg.sender);
    }
}