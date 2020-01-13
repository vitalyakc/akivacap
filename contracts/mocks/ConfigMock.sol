pragma solidity 0.5.12;

import '../config/Config.sol';


contract ConfigMock is Config {
  address public fakeErc20CollToken;

  function setErc20collToken(address _token) public {
    fakeErc20CollToken = _token;
  }

  function getErc20collToken() public view returns(address) {
    return fakeErc20CollToken;
  }
}