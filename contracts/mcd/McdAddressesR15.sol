pragma solidity 0.5.12;
/**
 * @title Mcd cdp maker dao system contracts deployed for 14th release
 */
contract McdAddressesR15 {
    uint public constant RELEASE = 15;
    // address public constant proxyRegistryAddr = 0x64A436ae831C1672AE81F674CAb8B6775df3475C; //15 rel
    address constant proxyRegistryAddr = 0xda657E86db3e76BDa6d88e6a09798F0BBF5bDf75; //6 rel
    address constant proxyLib = 0x19Ee8a65a26f5E4e70b59FdCd8e1047920B57c13;
    address constant proxyLibDsr = 0x9F514de1FE291A657B08cc93d72c1B50D2cD704f;
    address constant proxyLibEnd = 0x1478de8E2FeEA7CC0cd6D5fAEfF45616be9C13fA;
    address constant cdpManagerAddr = 0xb1fd1f2c83A6cb5155866169D81a9b7cF9e2019D;
    address constant mcdDaiAddr = 0x1D7e3a1A65a367db1D1D3F51A54aC01a2c4C92ff;
    address constant mcdJoinDaiAddr = 0x9E0d5a6a836a6C323Cf45Eb07Cb40CFc81664eec;
    address constant mcdVatAddr = 0xb597803e4B5b2A43A92F3e1DCaFEA5425c873116;
    address constant mcdJoinEthaAddr = 0x55cD2f4cF74eDc7c869BcF5e16086781eE97EE40;
    address constant mcdJoinEthbAddr = 0x795BF49EB037F9Fd19Bd0Ff582da42D75323A53B;
    address constant mcdJoinEthcAddr = 0x3aaE95264b28F6460A79Be1494AeBb6d6167D836;
    address constant mcdJoinZrxaAddr = 0x1F4150647b4AA5Eb36287d06d757A5247700c521;
    address constant mcdJoinRepaAddr = 0xd40163eA845aBBe53A12564395e33Fe108F90cd3;
    address constant mcdJoinOmgaAddr = 0x2EBb31F1160c7027987A03482aB0fEC130e98251;
    address constant mcdJoinBataAddr = 0xe56B354524115F101798d243e05Fd891F7D92E99;
    address constant mcdJoinDgdaAddr = 0xD5f63712aF0D62597Ad6bf8D357F163bc699E18c;
    address constant mcdJoinGntaAddr = 0xC667AC878FD8Eb4412DCAd07988Fea80008B65Ee;

    address constant mcdPotAddr = 0x286D3429226F04DE6a9Cf5A1CB3608DeDF84810B;
    address constant mcdSpotAddr = 0x932E82e999Fad1f7Ea9566f42cd3E94a4F46897E;
    address constant mcdCatAddr = 0x212F54B04D50594317317c94dB73c15cE1A33B73;
    address constant mcdJugAddr = 0x9404A7Fd173f1AA716416f391ACCD28Bd0d84406;
    address constant mcdEndAddr = 0xAF2bD74A519f824483E3a2cea9058fbe6bDAC036;
    
    address payable constant wethAddr = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
    address payable constant zrxAddr = 0x18392097549390502069C17700d21403EA3C721A;
    address payable constant repAddr = 0xC7aa227823789E363f29679F23f7e8F6d9904a9B;
    address payable constant omgAddr = 0x441B1A74C69ee6e631834B626B29801D42076D38;
    address payable constant batAddr = 0x9f8cFB61D3B2aF62864408DD703F9C3BEB55dff7;
    address payable constant dgdAddr = 0x62aeEC5fb140bb233b1c5612a8747Ca1Dc56dc1B;
    address payable constant gntAddr = 0xc81bA844f451d4452A01BBb2104C1c4F89252907;
}