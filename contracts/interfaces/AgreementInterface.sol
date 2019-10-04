pragma solidity 0.5.11;

/**
 * @title Interface for Agreement contract
 */
interface AgreementInterface {
    
    function approve() external returns(bool);
    function matchAgreement() external returns(bool);
    function checkAgreement() external returns(bool);
    function closePendingAgreement() external returns(bool);

    event AgreementInitiated(address _borrower, uint256 _collateralValue, uint256 _debtValue, uint256 _expireDate, uint256 _interestRate);
    event AgreementApproved(address _borrower, uint256 _collateralValue, uint256 _debtValue, uint256 _expireDate, uint256 _interestRate);
    event AgreementMatched(address _lender, uint256 _matchDate);
    event AgreementUpdated(uint256 _injectionAmount, uint256 _delta, uint256 _lockedDai);
    event AgreementTerminated(uint256 _borrowerFraDebtDai, uint256 _finalDaiLenderBalance);
    event AgreementLiquidated(uint256 _lenderEthReward, uint256 _borrowerEthResedual);
}