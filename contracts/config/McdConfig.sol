pragma solidity 0.5.11;

import '../helpers/RaySupport.sol';
import './McdAddresses.sol';

/**
 * @title Collateral addresses and details contract
 */
contract McdConfig is McdAddressesR14, RaySupport {
    struct CollateralAddresses{
        bytes32 ilk;
        address mcdJoinAddr;
        address payable baseAddr;
    }
    mapping(bytes32 => CollateralAddresses) public collateralTypes;

    function _initMcdConfig() internal {
        collateralTypes["ETH-A"].ilk = "ETH-A";
        collateralTypes["ETH-A"].mcdJoinAddr = mcdJoinEthaAddr;
        collateralTypes["ETH-A"].baseAddr = wethAddr;

        collateralTypes["ETH-B"].ilk = "ETH-B";
        collateralTypes["ETH-B"].mcdJoinAddr = mcdJoinEthbAddr;
        collateralTypes["ETH-B"].baseAddr = wethAddr;
    }
}