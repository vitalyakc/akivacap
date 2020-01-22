pragma solidity 0.5.12;

import "./Claimable.sol";

/**
 * @title   Claimable contract with initialization inside contructor
 */
contract ClaimableBase is Claimable {
    /**
     * @dev Constructor, set caller as contract owner
     */
    constructor () public {
        _setInitialOwner(msg.sender);
    }
}