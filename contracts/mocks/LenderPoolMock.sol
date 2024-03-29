pragma solidity 0.5.12;

import "../pool/LenderPool.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IAgreement.sol";

contract LenderPoolMock is LenderPool {

    uint debtValue = 20000000;
    uint interestRate = 1000000000937303470807876289;  // per sec 3%
    uint duration = 10000;
    bool isStatusMock = true;
    uint daiAsset;

    constructor (
        address _targetAgreement,
        uint _minInterestRate,
        uint _minDuration,
        uint _maxDuration,
        uint _maxPendingPeriod,
        uint _minDai
    ) LenderPool(
        _targetAgreement,
        _minInterestRate,
        _minDuration,
        _maxDuration,
        _maxPendingPeriod,
        _minDai
    ) public {}

    function setDaiTokenMock(address _daiTokenMock) public {
        daiToken = _daiTokenMock;
    }

    function setAgreementDebtValue(uint _debtValue) public {
        debtValue = _debtValue;
    }

    function _getAgreementDebtValue() internal view returns (uint) {
        return debtValue;
    }

    function setAgreementInterestRate(uint _interestRate) public {
        interestRate = _interestRate;
    }

    function _getAgreementInterestRate() internal view returns (uint) {
        return interestRate;
    }

    function setAgreementDuration(uint _duration) public {
        duration = _duration;
    }

    function _getAgreementDuration() internal view returns (uint) {
        return duration;
    }

    function setAgreementStatus(bool _status) public {
        isStatusMock = _status;
    }

    function _isAgreementInStatus(IAgreement.Statuses) internal view returns(bool) {
        return isStatusMock;
    }

    function _matchAgreement() internal {}

    function setAgreementDaiAsset(uint _daiAsset) public {
        daiAsset = _daiAsset;
    }

    function _getAgreementAssets() internal view returns(uint, uint) {
        return (0, daiAsset);
    }

    function _withdrawDaiFromAgreement() internal {}
}