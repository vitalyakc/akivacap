pragma solidity 0.5.11;

import "./IERC20.sol";

/**
 * @title Interface for Agreement contract
 */
interface IAgreement {
    enum Statuses {All, Pending, Open, Active, Closed}
    enum ClosedTypes {Ended, Liquidated, Blocked, Cancelled}

    function initAgreement(
        address payable _borrower,
        uint256 _collateralAmount,
        uint256 _debtValue,
        uint256 _duration,
        uint256 _interestRate,
        bytes32 _collateralType,
        bool _isETH,
        address _configAddr
    ) external payable;

    function transferOwnership(address _newOwner) external;
    function claimOwnership() external;
    function approveAgreement() external returns(bool);
    function updateAgreement() external returns(bool);
    function cancelAgreement() external returns(bool);
    function rejectAgreement() external returns(bool);
    function blockAgreement() external returns(bool);
    function status() external view returns(uint);
    function lender() external view returns(address);
    function borrower() external view returns(address);
    function collateralType() external view returns(bytes32);
    function isStatus(Statuses _status) external view returns(bool);
    function isBeforeStatus(Statuses _status) external view returns(bool);
    function isClosedWithType(ClosedTypes _type) external view returns(bool);
    function checkTimeToCancel(uint _approveLimit, uint _matchLimit) external view returns(bool);
    function cdpId() external view returns(uint);
    function erc20TokenContract(bytes32 ilk) external view returns(IERC20);

    function getInfo()
        external
        view
        returns (
            address _addr,
            uint _status,
            uint _closedType,
            uint _duration,
            address _borrower,
            address _lender,
            bytes32 _collateralType,
            uint _collateralAmount,
            uint _debtValue,
            uint _interestRate,
            bool _isRisky
        );

    event AgreementInitiated(address _borrower, uint _collateralValue, uint _debtValue, uint _expireDate, uint _interestRate);
    event AgreementApproved();
    event AgreementMatched(address _lender, uint _expireDate, uint _cdpId, uint _collateralAmount, uint _debtValue, uint _drawnDai);
    event AgreementUpdated(int savingsDifference, uint currentDebt, int delta, uint currentDsrAnnual, uint timeInterval, uint drawnDai, uint injectionAmount);
    event AgreementCanceled(address _user);
    event AgreementTerminated();
    event AgreementLiquidated();
    event AgreementBlocked();
    event AssetsCollateralPush(address _holder, uint _amount, bytes32 collateralType);
    event AssetsCollateralPop(address _holder, uint _amount, bytes32 collateralType);
    event AssetsDaiPush(address _holder, uint _amount);
    event AssetsDaiPop(address _holder, uint _amount);
    event CdpOwnershipTransferred(address _borrower, uint _cdpId);
    event AdditionalCollateralLocked(uint _amount);
}