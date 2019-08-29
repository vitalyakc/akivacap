pragma solidity 0.5.11;

contract DaiStableCoinPrototype {
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address src, address dst, uint wad) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function balanceOf(address who) public view returns (uint256);
}