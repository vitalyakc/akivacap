pragma solidity 0.5.12;

import "./Context.sol";
import "./Initializable.sol";
import "./Claimable.sol";

/**
 * @title   Claimable contract with initialization inside initializer
 */
contract ClaimableIni is Claimable, Initializable, Context {
    /**
     * @dev Set caller as contract owner
     */
    function initialize() public initializer {
        _setInitialOwner(msg.sender);
    }
}