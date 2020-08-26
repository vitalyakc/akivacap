pragma solidity 0.5.12;

import "../Agreement.sol";
import "./ConfigMock.sol";

/*
 * @title Base Agreement Mock contract
 * @dev Should not be deployed. It is being used as an abstract class
 */
contract AgreementMock is Agreement {
    uint public dsrTest = 1000000001547125957863212448; // 5% per sec compounding
    uint256 public currentTime;
    uint256 public unlockedDai;
    address erc20Token;
    address public mcdDaiAddrMock;
    uint256 drawnCdp;
    uint256 injectionWad;
    uint256 CR;
    uint256 mcr;
    uint256 price;

    uint256 ink;
    uint256 art;
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

    function _lockDai(uint wad) internal {}

    function _lockETH(bytes32 ilk, uint cdp, uint wadC) internal {}

    function setMcdDaiAddrMock(address _addr) public {
      mcdDaiAddrMock = _addr;
    }

    function _transferDai(address, uint) internal returns(bool) {
          return true;
    }

    function _transferFromDai(address from, address to, uint amount) internal returns(bool) {
      IERC20(mcdDaiAddrMock).transferFrom(from, to, amount);
      return true;
    }
    
    function setUnlockedDai(uint256 _amount) public {
      unlockedDai = _amount;
    }

    function _unlockAllDai() internal returns(uint) {
        return unlockedDai;
    }

    function _balanceDai(address) internal view returns(uint) {
        return unlockedDai;
    }

    function _initMcdWrapper(bytes32 ilk, bool isEther) internal {}

    function setErc20Token(address _contract) public {
      erc20Token = _contract;
    }

    function erc20TokenContract(bytes32) public view returns(IERC20) {
      return IERC20(erc20Token);
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
      
      ink = _collateralAmount;
      art = _debtValue;
      setErc20Token(ConfigMock(_configAddr).getErc20collToken());
    }


    function updateAgreementState(bool _lastUpdate) public returns(bool success) {
      return _updateAgreementState(_lastUpdate);
    }

    function setLastCheckTime(uint256 _value) public {
      lastCheckTime = _value;
    }

    function setStatus(uint256 _status) public {
      status = Statuses(_status);
    }

    function refund() public {
      _refund();
    }

    function _transferCdpOwnershipToProxy(uint256, address) internal {}



    function setDrawnCdp(uint256 _drawnCdp) public {
        drawnCdp = _drawnCdp;
        _drawnCdp = 0; 
    }

    function _drawDaiToCdp(bytes32, uint, uint cdebt) internal returns (uint) {
      return drawnCdp > cdebt ? cdebt : drawnCdp;
    }




    function _injectToCdpFromDsr(uint, uint debt) internal returns(uint) {
      return injectionWad > debt? debt : injectionWad;
    }

    function setInjectionWad(uint256 _injectionWad) public {
      injectionWad = _injectionWad;
      _injectionWad = 0;
    }



    function nextStatus() public {
      _nextStatus();
    }

    function switchStatus(Statuses _next) public {
        _switchStatus(_next);
    }

    function switchStatusClosedWithType(ClosedTypes _closedType) public {
        _switchStatusClosedWithType(_closedType);
    }

    function doStatusSnapshot() public {
        _doStatusSnapshot();
    }

    function pushCollateralAsset(address _holder, uint _amount) public {
        _pushCollateralAsset(_holder, _amount);
    }

    function pushDaiAsset(address _holder, uint _amount) public {
        _pushDaiAsset(_holder, _amount);
    }

    function popCollateralAsset(address _holder, uint _amount) public {
        _popCollateralAsset(_holder, _amount);
    }

    function popDaiAsset(address _holder, uint _amount) public {
        _popDaiAsset(_holder, _amount);
    }

    function isCdpSafe(bytes32, uint) public view returns(bool) {
        return now < 200000;
    }

    function setCRBuffer(uint256 _CR) public {
        CR = _CR;
    }

    function getCRBuffer() public view returns(uint256) {
        return CR;
    }


    function getCdpInfo(bytes32 ilk, uint cdpId) public view returns(uint, uint) {
        return (ink, art); 

    }

  function setMCR(uint256 _mcr) public  {
    mcr = _mcr;
  }

    function getMCR() public view returns(uint256) {
      return mcr;  
    }



    function monitorRisky() public {
        _monitorRisky();
    }
}

contract AgreementDeepMock is AgreementMock {
  function _transferFromDai(address, address, uint) internal returns(bool) {
      return true;
  }
}