pragma solidity 0.5.12;

import "./ClaimableBase.sol";

/**
 * @title   Administrable contract, multiadmins managing
 * @dev     Inherit Claimable contract with usual initialization in constructor
 */
contract Administrable is ClaimableBase {
    mapping (address => bool) public isAdmin;

    event AdminAppointed(address admin);
    event AdminDismissed(address admin);

    /**
     * @dev     Appoint owner as admin
     */
    constructor () public {
        isAdmin[owner] = true;
        emit AdminAppointed(owner);
    }

    /**
     * @dev     Grants access only for admin
     */
    modifier onlyAdmin () {
        require(isAdmin[msg.sender], "Administrable: not an admin");
        _;
    }

    /**
     * @dev     Appoint new admin
     * @param   _newAdmin   new admin address
     */
    function appointAdmin (address _newAdmin) public onlyContractOwner() returns(bool success) {
        if (isAdmin[_newAdmin] == false) {
            isAdmin[_newAdmin] = true;
            emit AdminAppointed(_newAdmin);
        }
        return true;
    }

    /**
     * @dev     Dismiss admin
     * @param   _admin   admin address
     */
    function dismissAdmin (address _admin) public onlyContractOwner() returns(bool success) {
        isAdmin[_admin] = false;
        emit AdminDismissed(_admin);
        return true;
    }
}