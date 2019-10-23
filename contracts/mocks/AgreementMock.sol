pragma solidity 0.5.11;

import '../Agreement.sol';

/*
 * @title Base Agreement Mock contract
 * @dev Should not be deployed. It is being used as an abstract class
 */
contract AgreementMock is Agreement {
    uint public dsrTest = 105 * 10 ** 25;
    uint256 public currentTime;
    uint256 public unlockedDai;
    address erc20Token;

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

    function _transferDai(address to, uint amount) internal returns(bool) {
      return true;
    }

    function setUnlockedDai(uint256 _amount) public {
      unlockedDai = _amount;
    }

    function _unlockAllDai() internal returns(uint pie) {
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

    function erc20TokenContract(bytes32 ilk) public view returns(ERC20Interface) {
      return ERC20Interface(erc20Token);
    }
}
