pragma solidity 0.5.12;
/**
 * @title Mcd cdp maker dao system contracts deployed for 17th release
 */
contract McdAddressesR17 {
    uint public constant RELEASE = 17;

    address public constant proxyRegistryAddrMD = 0x64A436ae831C1672AE81F674CAb8B6775df3475C; // used by MakerDao portal oasis
    address constant proxyRegistryAddr = 0x8877152FA31F00eC81b161774209308535af157a;
    // * 0xda657E86db3e76BDa6d88e6a09798F0BBF5bDf75 "Compatible with 5.12 solc", deployed by 0x61de44946D6b809a30D8e6A236157966659f9640 May-16-2019 
    // Argument: 0x13c5d6fa341aa30a006a3e1cc14c6074543d7560, deployed by 0x61de44946D6b809a30D8e6A236157966659f9640 on May-16-2019
    // version: latest by then, compiled by solc 0.5.6. ProxyFactory needs to be deployed too and passed as parameter.
    // * Existing proxy registry: at 0x64a436ae831c1672ae81f674cab8b6775df3475c;  uses solc ^0.4.23 deployed Jun-22-2018
    // argument:  0xe11E3b391F7E8bC47247866aF32AF67Dd58Dc800
    // newly deployed: 0x8877152fa31f00ec81b161774209308535af157a 

    address constant proxyLib  = 0xd1D24637b9109B7f61459176EdcfF9Be56283a7B;  
    address constant proxyLibDsr = 0xc5CC1Dfb64A62B9C7Bb6Cbf53C2A579E2856bf92;
    address constant proxyLibEnd = 0x5652779B00e056d7DF87D03fe09fd656fBc322DF;
    
    address constant cdpManagerAddr = 0x1476483dD8C35F25e568113C5f70249D3976ba21;
    address constant mcdDaiAddr = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa;
    address constant mcdJoinDaiAddr = 0x5AA71a3ae1C0bd6ac27A1f28e1415fFFB6F15B8c;
    address constant mcdVatAddr = 0xbA987bDB501d131f766fEe8180Da5d81b34b69d9;

    address constant mcdJoinEthaAddr  = 0x775787933e92b709f2a3C70aa87999696e74A9F8;
    address constant mcdJoinBataAddr  = 0x2a4C485B1B8dFb46acCfbeCaF75b6188A59dBd0a;
    address constant mcdJoinUsdcaAddr = 0x4c514656E7dB7B859E994322D2b511d99105C1Eb;
    address constant mcdJoinUsdcbAddr = 0xaca10483e7248453BB6C5afc3e403e8b7EeDF314;
    address constant mcdJoinWbtcaAddr = 0xB879c7d51439F8e7AC6b2f82583746A0d336e63F;
    address constant mcdJoinTusdaAddr = 0xe53f6755A031708c87d80f5B1B43c43892551c17;
    address constant mcdJoinZrxaAddr  = 0x85D38fF6a6FCf98bD034FB5F9D72cF15e38543f2;
    address constant mcdJoinKncaAddr  = 0xE42427325A0e4c8e194692FfbcACD92C2C381598;
    address constant mcdJoinManaaAddr = 0xdC9Fe394B27525e0D9C827EE356303b49F607aaF;

    address constant mcdPotAddr  = 0xEA190DBDC7adF265260ec4dA6e9675Fd4f5A78bb;
    address constant mcdSpotAddr = 0x3a042de6413eDB15F2784f2f97cC68C7E9750b2D;
    address constant mcdCatAddr  = 0x0511674A67192FE51e86fE55Ed660eB4f995BDd6;
    address constant mcdJugAddr  = 0xcbB7718c9F39d05aEEDE1c472ca8Bf804b2f1EaD;
    address constant mcdEndAddr  = 0x24728AcF2E2C403F5d2db4Df6834B8998e56aA5F;
    
    address payable constant wethAddr = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
    address payable constant batAddr  = 0x9f8cFB61D3B2aF62864408DD703F9C3BEB55dff7;
    address payable constant usdcAddr = 0xBD84be3C303f6821ab297b840a99Bd0d4c4da6b5;
    address payable constant wbtcAddr = 0x7419f744bBF35956020C1687fF68911cD777f865;
    address payable constant tusdAddr = 0xD6CE59F06Ff2070Dd5DcAd0866A7D8cd9270041a;
    address payable constant zrxAddr  = 0xC2C08A566aD44129E69f8FC98684EAA28B01a6e7;
    address payable constant kncAddr  = 0x9800a0a3c7e9682e1AEb7CAA3200854eFD4E9327;
    address payable constant manaAddr = 0x221F4D62636b7B51b99e36444ea47Dc7831c2B2f;

    address constant mcdIlkRegAddr = 0x6618BD7bBaBFacC518Fdec43542E4a73629B0819;

}
