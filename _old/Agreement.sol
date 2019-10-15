// /**
//  * @title Inherited from BaseAgreement, should be deployed for ETH collateral
//  */
// contract AgreementETH is BaseAgreement {
//     function initialize(address payable _borrower, uint256 _collateralAmount,
//         uint256 _debtValue, uint256 _durationMins, uint256 _interestRate, bytes32 _collateralType)
//     public payable initializer {
//         require(msg.value == _collateralAmount, 'Actual ehter value is not correct');
//         super.initialize(_borrower, _collateralAmount, _debtValue, _durationMins, _interestRate, _collateralType);
//     }

//     /**
//      * @dev Closes agreement before it is matched and
//      * transfers collateral ETH back to user
//      */
//     function _cancelAgreement() internal onlyBeforeMatched() {
//         borrower.transfer(collateralAmount);
//         closeDate = getCurrentTime();
//         emit AgreementCanceled(msg.sender);
//         status = STATUS_CANCELED;
//     }
    
//     /**
//      * @dev Opens CDP contract in makerDAO system with ETH
//      * @return cdpId - id of cdp contract in makerDAO
//      */
//     function _lockAndDraw() internal {
//         return _lockETHAndDraw(collateralType, cdpId, collateralAmount, debtValue);
//     }

//     /**
//      * @dev Opens CDP contract in makerDAO system with ETH
//      * @return cdpId - id of cdp contract in makerDAO
//      */
//     function _openLockAndDraw() internal returns(uint256) {
//         return _openLockETHAndDraw(collateralType, debtValue, collateralAmount);
//     }

//     /**
//      * @dev Executes all required transfers after liquidation
//      * @return Operation success
//      */
//     function _refundAfterCdpLiquidation(uint _borrowerFraDebtDai) internal returns(bool _success) {
//         uint256 lenderRefundCollateral = getCollateralEquivalent(collateralType, _borrowerFraDebtDai);
//         lender.transfer(lenderRefundCollateral);

//         uint borrowerRefundCollateral = address(this).balance;
//         borrower.transfer(borrowerRefundCollateral);

//         emit RefundLiquidated(_borrowerFraDebtDai, lenderRefundCollateral, borrowerRefundCollateral);
//         return true;
//     }
// }

// /**
//  * @title Inherited from BaseAgreement, should be deployed for ERC20 collateral
//  */
// contract AgreementERC20 is BaseAgreement {
//     /**
//      * @dev Closes rejected agreement and
//      * transfers collateral tokens back to user
//      */
//     function _cancelAgreement() internal onlyBeforeMatched() {
//         _transferERC20(collateralType, borrower, collateralAmount);

//         status = STATUS_CANCELED;
//     }

//     /**
//      * @dev Opens CDP contract in makerDAO system with ETH
//      * @return cdpId - id of cdp contract in makerDAO
//      */
//     function _lockAndDraw() internal {
//         return _lockERC20AndDraw(collateralType, cdpId, collateralAmount, debtValue, true);
//     }

//     /**
//      * @dev Opens CDP contract in makerDAO system with ERC20
//      * @return cdpId - id of cdp contract in makerDAO
//      */
//     function _openLockAndDraw() internal returns(uint256) {
//         return _openLockERC20AndDraw(collateralType, debtValue, collateralAmount, true);
//     }

//     /**
//      * @dev Executes all required transfers after liquidation
//      * @return Operation success
//      */
//     function _refundAfterCdpLiquidation(uint _borrowerFraDebtDai) internal returns(bool _success) {
//         uint256 lenderRefundCollateral = getCollateralEquivalent(collateralType, _borrowerFraDebtDai);
//         _transferERC20(collateralType, lender, lenderRefundCollateral);

//         uint borrowerRefundCollateral = address(this).balance;
//         _transferERC20(collateralType, borrower, borrowerRefundCollateral);

//         emit RefundLiquidated(_borrowerFraDebtDai, lenderRefundCollateral, borrowerRefundCollateral);
//         return true;
//     }

// }
