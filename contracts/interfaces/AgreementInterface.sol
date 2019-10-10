pragma solidity 0.5.11;

/**
 * @title Interface for Agreement contract
 */
interface AgreementInterface {
    // function initialize(address payable _borrower, uint256 _collateralAmount,
    //     uint256 _debtValue, uint256 _durationMins, uint256 _interestRatePercent, bytes32 _collateralType) external payable;
    function approveAgreement() external returns(bool);
    function rejectAgreement() external returns(bool);
    function matchAgreement() external returns(bool);
    function checkAgreement() external returns(bool);
    function cancelAgreement() external returns(bool);
    function isClosed() external view returns(bool);

    event AgreementInitiated(address _borrower, uint _collateralValue, uint _debtValue, uint _expireDate, uint _interestRate);
    event AgreementApproved();
    event AgreementMatched(address _lender);
    event AgreementUpdated(uint _injectionAmount, int _delta, int _deltaCommon, uint _lockedDai);
    
    event AgreementCanceled(address _user);
    event AgreementTerminated();
    event AgreementLiquidated();
    event RefundBase(address lender, uint lenderRefundDai, address borrower, uint cdpId);
    event RefundLiquidated(uint borrowerFraDebtDai, uint lenderRefundCollateral, uint borrowerRefundCollateral);
}