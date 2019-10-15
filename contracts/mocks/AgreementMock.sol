pragma solidity 0.5.11;

import '../Agreement.sol';

/*
 * @title Base Agreement Mock contract
 * @dev Should not be deployed. It is being used as an abstract class
 */
contract AgreementMock is Agreement {
    uint public dsrTest = 105 * 10 ** 25;

    /**
     * @notice should be removed after testing!!!
     */
    function setDelta(int _delta) public {
        delta = _delta;
    }

    function setDsr(uint _dsrTest) public {
        dsrTest = _dsrTest;
    }

    function getDsr() public view returns(uint) {
        return dsrTest;
    }
}

