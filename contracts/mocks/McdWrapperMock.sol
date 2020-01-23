pragma solidity 0.5.12;

import "../mcd/McdWrapper.sol";

contract McdWrapperMock is McdWrapper {
    uint256 public cdpId;

    function initMcdWrapper(bytes32 ilk, bool isEther) public {
        _initMcdWrapper(ilk, isEther);
    }

    function setOwnerProxy(address newOwner) public {
        _setOwnerProxy(newOwner);
    }

    // send eth here firstly
    function openLockETHAndDraw(bytes32 ilk, uint wadD, uint wadC) public {
        _openLockETHAndDraw(ilk, wadD, wadC);
    }

    // send real erc20 firstly
    function openLockERC20AndDraw(bytes32 ilk, uint wadD, uint wadC, bool transferFrom) public {
        _openLockERC20AndDraw(ilk, wadD, wadC, transferFrom);
    }

    // send dai here
    function injectToCdpFromDsr(uint cdp, uint wad) public {
        _injectToCdpFromDsr(cdp, wad);
    }

    //send dai here
    function lockDai(uint wad) public {
        _lockDai(wad);
    }

    // lock firstly and then unlock and check contract for dai
    function unlockDai(uint wad) public {
        _unlockDai(wad);
    }

    // lock firstly and then unlock and check contract for dai
    function unlockAllDai() public {
        _unlockAllDai();
    }

    function transferCdpOwnership(uint cdp, address guy) public {
        _transferCdpOwnershipToProxy(cdp, guy);
    }

    function getCollateralAddreses(bytes32 ilk) public pure returns(address mcdJoinEthaAddr, address payable wethAddr) {
        return _getCollateralAddreses(ilk);
    }

    function () external payable {}
}