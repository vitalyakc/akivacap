pragma solidity 0.5.11;
/**
 * @title Mcd cdp maker dao system contracts deployed for 14th release
 */
contract McdAddressesR17 {
    uint public constant RELEASE = 17;
    address public constant proxyRegistryAddrMD = 0x64A436ae831C1672AE81F674CAb8B6775df3475C; // used by MakerDao portal oasis
    address constant proxyRegistryAddr = 0xda657E86db3e76BDa6d88e6a09798F0BBF5bDf75; // compatible with 5.11 solc
    address constant proxyLib = 0xd1D24637b9109B7f61459176EdcfF9Be56283a7B;
    address constant proxyLibDsr = 0xc5CC1Dfb64A62B9C7Bb6Cbf53C2A579E2856bf92;
    address constant proxyLibEnd = 0x5652779B00e056d7DF87D03fe09fd656fBc322DF;
    address constant cdpManagerAddr = 0x1476483dD8C35F25e568113C5f70249D3976ba21;
    address constant mcdDaiAddr = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa;
    address constant mcdJoinDaiAddr = 0x5AA71a3ae1C0bd6ac27A1f28e1415fFFB6F15B8c;
    address constant mcdVatAddr = 0xbA987bDB501d131f766fEe8180Da5d81b34b69d9;
    address constant mcdJoinEthaAddr = 0x775787933e92b709f2a3C70aa87999696e74A9F8;
    // address constant mcdJoinEthbAddr = 0x795BF49EB037F9Fd19Bd0Ff582da42D75323A53B;
    // address constant mcdJoinEthcAddr = 0x3aaE95264b28F6460A79Be1494AeBb6d6167D836;
    // address constant mcdJoinZrxaAddr = 0x1F4150647b4AA5Eb36287d06d757A5247700c521;
    // address constant mcdJoinRepaAddr = 0xd40163eA845aBBe53A12564395e33Fe108F90cd3;
    // address constant mcdJoinOmgaAddr = 0x2EBb31F1160c7027987A03482aB0fEC130e98251;
    address constant mcdJoinBataAddr = 0x2a4C485B1B8dFb46acCfbeCaF75b6188A59dBd0a;
    // address constant mcdJoinDgdaAddr = 0xD5f63712aF0D62597Ad6bf8D357F163bc699E18c;
    // address constant mcdJoinGntaAddr = 0xC667AC878FD8Eb4412DCAd07988Fea80008B65Ee;

    address constant mcdPotAddr = 0xEA190DBDC7adF265260ec4dA6e9675Fd4f5A78bb;
    address constant mcdSpotAddr = 0x3a042de6413eDB15F2784f2f97cC68C7E9750b2D;
    address constant mcdCatAddr = 0x0511674A67192FE51e86fE55Ed660eB4f995BDd6;
    address constant mcdJugAddr = 0xcbB7718c9F39d05aEEDE1c472ca8Bf804b2f1EaD;
    address constant mcdEndAddr = 0x24728AcF2E2C403F5d2db4Df6834B8998e56aA5F;
    
    address payable constant wethAddr = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
    // address payable constant zrxAddr = 0x18392097549390502069C17700d21403EA3C721A;
    // address payable constant repAddr = 0xC7aa227823789E363f29679F23f7e8F6d9904a9B;
    // address payable constant omgAddr = 0x441B1A74C69ee6e631834B626B29801D42076D38;
    address payable constant batAddr = 0x9f8cFB61D3B2aF62864408DD703F9C3BEB55dff7;
    // address payable constant dgdAddr = 0x62aeEC5fb140bb233b1c5612a8747Ca1Dc56dc1B;
    // address payable constant gntAddr = 0xc81bA844f451d4452A01BBb2104C1c4F89252907;
}