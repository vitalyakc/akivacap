pragma solidity 0.5.11;

import './ERC20Interface.sol';

/**
 * @title Interface for Agreement contract
 */
interface AgreementInterface {
    function initAgreement(address payable _borrower, uint256 _collateralAmount,
        uint256 _debtValue, uint256 _duration, uint256 _interestRate, bytes32 _collateralType, bool _isETH, address _configAddr) external payable;
    function approveAgreement() external returns(bool);
    function updateAgreement() external returns(bool);
    function cancelAgreement() external returns(bool);
    function rejectAgreement() external returns(bool);
    function getInfo() external view returns(uint _status, uint _duration, address _borrower, address _lender, bytes32 _collateralType, uint _collateralAmount, uint _debtValue, uint _interestRate);
    function status() external view returns(uint);
    function collateralType() external view returns(bytes32);
    function isActive() external view returns(bool);
    function isPending() external view returns(bool);
    function isClosed() external view returns(bool);
    function isBeforeMatched() external view returns(bool);
    function erc20TokenContract(bytes32 ilk) external view returns(ERC20Interface);

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