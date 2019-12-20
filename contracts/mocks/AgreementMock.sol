pragma solidity 0.5.11;

import "../Agreement.sol";
import "./ConfigMock.sol";

/*
 * @title Base Agreement Mock contract
 * @dev Should not be deployed. It is being used as an abstract class
 */
contract AgreementMock is Agreement {
    uint public dsrTest = 105 * 10 ** 25;
    uint256 public currentTime;
    uint256 public unlockedDai;
    address erc20Token;
    address public mcdDaiAddrMock;

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

    function setCurrentTime(uint256 _time) public {
      currentTime = _time;
    }

    function getCurrentTime() public view returns(uint256) {
      return currentTime;
    }

    function _openCdp(bytes32 ilk) internal returns (uint cdp) {
        return 0;
    }

    function _lockDai(uint wad) internal {}

    function _lockETHAndDraw(bytes32 ilk, uint cdp, uint wadC, uint wadD) internal {}

    function _lockERC20AndDraw(bytes32 ilk, uint cdp, uint wadD, uint wadC, bool transferFrom) internal {}

    function setMcdDaiAddrMock(address _addr) public {
      mcdDaiAddrMock = _addr;
    }

    function _transferDai(address to, uint amount) internal returns(bool) {
          return true;
    }

    function _transferFromDai(address from, address to, uint amount) internal returns(bool) {
      IERC20(mcdDaiAddrMock).transferFrom(from, to, amount);
      return true;
    }
    
    function setUnlockedDai(uint256 _amount) public {
      unlockedDai = _amount;
    }

    function _unlockDai(uint wad) internal returns(uint unlockedWad) {}

    function _unlockAllDai() internal returns(uint) {
        return unlockedDai;
    }

    function _balanceDai(address addr) internal view returns(uint) {
        return unlockedDai;
    }

    function _injectToCdp(uint cdp, uint wad) internal {}

    function _forceLiquidateCdp(bytes32 ilk, uint cdpId) internal view returns(uint) {
      return 0;
    }

    function getCollateralEquivalent(bytes32 ilk, uint daiAmount) public view returns(uint) {
      return daiAmount * 200;
    }

    function _initMcdWrapper() internal {}

    function setErc20Token(address _contract) public {
      erc20Token = _contract;
    }

    function erc20TokenContract(bytes32 ilk) public view returns(IERC20) {
      return IERC20(erc20Token);
    }

    function setStatus(Statuses _status) public {
      status = _status;
    }

    function initAgreement(
      address payable _borrower,
      uint256 _collateralAmount,
      uint256 _debtValue,
      uint256 _duration,
      uint256 _interestRatePercent,
      bytes32 _collateralType,
      bool _isETH,
      address _configAddr
    ) public payable {
      Agreement.initAgreement(_borrower, _collateralAmount, _debtValue, 
        _duration, _interestRatePercent, _collateralType, _isETH, _configAddr);
      
      setErc20Token(ConfigMock(_configAddr).getErc20collToken());
    }

    function updateAgreementState(bool _lastUpdate) public returns(bool success) {
      return _updateAgreementState(_lastUpdate);
    }

    function setLastCheckTime(uint256 _value) public {
      lastCheckTime = _value;
    }

    function refund() public {
      _refund();
    }

    function terminateAgreement() public returns(bool _success) {
    //   return _terminateAgreement();
    }

    function _transferCdpOwnership(uint256, address) internal {}
}

contract AgreementDeepMock is AgreementMock {
  function _transferFromDai(address from, address to, uint amount) internal returns(bool) {
      return true;
  }
}