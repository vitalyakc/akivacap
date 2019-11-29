pragma solidity 0.5.11;

import '../mcd/McdWrapper.sol';

contract McdWrapperMock is McdWrapper {
  uint256 public cdpId;

  function initMcdWrapper(bytes32 ilk, bool isEther) public {
    _initMcdWrapper(ilk, isEther);
  }

  function setOwnerProxy(address newOwner) public {
    _setOwnerProxy(newOwner);
  }

  function lockETHAndDraw(bytes32 ilk, uint cdp, uint wadC, uint wadD) public { // send eth here firstly
    _lockETHAndDraw(ilk, cdp, wadC, wadD);
  }

  function lockERC20AndDraw(bytes32 ilk, uint cdp, uint wadD, uint wadC, bool transferFrom) public { // send real erc20 firstly 
    _lockERC20AndDraw(ilk, cdp, wadD, wadC, transferFrom);
  }

  function openLockETHAndDraw(bytes32 ilk, uint wadD, uint wadC) public { // send eth here firstly
    _openLockETHAndDraw(ilk, wadD, wadC);
  }

  function openLockERC20AndDraw(bytes32 ilk, uint wadD, uint wadC, bool transferFrom) public { // send real erc20 firstly
    _openLockERC20AndDraw(ilk, wadD, wadC, transferFrom);
  }

  function injectToCdp(uint cdp, uint wad) public { // send dai here
    _injectToCdp(cdp, wad);
  }

  function lockDai(uint wad) public { //send dai here
    _lockDai(wad);
  }

  function unlockDai(uint wad) public { // lock firstly and then unlock and check contract for dai
    _unlockDai(wad);
  }

  function unlockAllDai() public { // lock firstly and then unlock and check contract for dai
    _unlockAllDai();
  }

  function transferCdpOwnership(uint cdp, address guy) public {
    _transferCdpOwnershipToProxy(cdp, guy);
  }

  function getCollateralAddreses(bytes32 ilk) public view returns(address mcdJoinEthaAddr, address payable wethAddr){
    return _getCollateralAddreses(ilk);
  }

  function () external payable {}
}