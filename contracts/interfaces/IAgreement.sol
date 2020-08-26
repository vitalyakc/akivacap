pragma solidity 0.5.12;

import "./IERC20.sol";

/**
 * @title Interface for Agreement contract
 */
interface IAgreement {
    enum Statuses {All, Pending, Open, Active, Closed}
    enum ClosedTypes {Ended, Liquidated, Blocked, Cancelled}

    function initAgreement(address payable, uint256, uint256, uint256, uint256, bytes32, bool, address) external payable;

    function transferOwnership(address) external;
    function claimOwnership() external;
    function approveAgreement() external returns(bool);
    function updateAgreement() external returns(bool);
    function cancelAgreement() external returns(bool); // ext
    function rejectAgreement() external returns(bool);
    function blockAgreement() external returns(bool);
    function matchAgreement() external returns(bool);
    function interestRate() external view returns(uint);
    function duration() external view returns(uint);
    function cdpDebtValue() external view returns(uint);
    function status() external view returns(uint);
    function lender() external view returns(address);
    function borrower() external view returns(address);
    function collateralType() external view returns(bytes32); // ext
    function isStatus(Statuses) external view returns(bool);
    function isBeforeStatus(Statuses) external view returns(bool);
    function isClosedWithType(ClosedTypes) external view returns(bool);
    function checkTimeToCancel(uint, uint) external view returns(bool);
    function cdpId() external view returns(uint);
    function erc20TokenContract(bytes32) external view returns(IERC20);
    function getAssets(address) external view returns(uint,uint); // ext
    function withdrawDai(uint) external;
    function getDaiAddress() external view returns(address); // ext

    function getInfo() external view returns (address,uint,uint,uint,address,address,bytes32,uint,uint,uint,bool); // ext

    event AgreementInitiated(address _borrower, uint _collateralValue, uint _debtValue, uint _expireDate, uint _interestRate);
    event AgreementApproved();
    event AgreementMatched(address _lender, uint _expireDate, uint _cdpId, uint _collateralAmount, uint _debtValue, uint _drawnDai);
    event AgreementUpdated(int _savingsDifference, int _delta, uint _timeInterval, uint _drawnDai, uint _injectionAmount);
    event AgreementClosed(uint _closedType, address _user);
    event AssetsCollateralPush(address _holder, uint _amount, bytes32 _collateralType);
    event AssetsCollateralPop(address _holder, uint _amount, bytes32 _collateralType);
    event AssetsDaiPush(address _holder, uint _amount);
    event AssetsDaiPop(address _holder, uint _amount);
    event CdpOwnershipTransferred(address _borrower, uint _cdpId);
    event AdditionalCollateralLocked(uint _amount);
    event RiskyToggled(bool _isRisky);
}