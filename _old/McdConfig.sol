pragma solidity 0.5.11;

import './McdAddresses.sol';

/**
 * @title Collateral addresses and details contract
 */
contract McdConfig is McdAddressesR14 {
    struct CollateralAddresses{
        address mcdJoinAddr;
        address payable baseAddr;
    }
    mapping(bytes32 => CollateralAddresses) public collateralTypes;

    function _initMcdConfig(bytes32 _ilk) internal {
        if (_ilk == "ETH-A") {
            collateralTypes["ETH-A"].mcdJoinAddr = mcdJoinEthaAddr;
            collateralTypes["ETH-A"].baseAddr = wethAddr;
        }
        if (_ilk == "ETH-B") {
            collateralTypes["ETH-B"].mcdJoinAddr = mcdJoinEthbAddr;
            collateralTypes["ETH-B"].baseAddr = wethAddr;
        }
    }
}