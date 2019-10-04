pragma solidity 0.5.11;

import '../Agreement.sol';

/*
 * @title Base Agreement Mock contract
 * @dev Should not be deployed. It is being used as an abstract class
 */
contract BaseAgreementMock is BaseAgreement {
    uint256 public dsrTest = 105 * 10 ** 25;

    /**
     * @notice should be removed after testing!!!
     */
    function setBorrowerFraDebt(uint256 _borrowerFraDebt) public {
        borrowerFRADebt = _borrowerFraDebt;
    }
    
    function setdsrTest(uint256 _dsrTest) public {
        dsrTest = _dsrTest;
    }

    function getCurrentDSR() public returns(uint) {
        return dsrTest;
    }
}

/**
 * @title Inherited from BaseAgreementMock, should be deployed for ETH collateral
 */
contract AgreementETHMock is BaseAgreementMock {
}

/**
 * @title Inherited from BaseAgreementMock, should be deployed for ERC20 collateral
 */
contract AgreementERC20Mock is BaseAgreementMock {
}
