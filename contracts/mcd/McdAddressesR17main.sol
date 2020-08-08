pragma solidity 0.5.12;
/**
 * @title Mcd cdp maker dao system contracts deployed for 17th release
 */
contract McdAddressesR17 {
    uint public constant RELEASE = 17;

    address public constant proxyRegistryAddrMD = 0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4; // used by MakerDao portal oasis
    address constant proxyRegistryAddr = 0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4; // original maker deployment solc ^0.4.23

    address constant proxyLib = 0x82ecD135Dce65Fbc6DbdD0e4237E0AF93FFD5038;  
    address constant proxyLibDsr = 0x07ee93aEEa0a36FfF2A9B95dd22Bd6049EE54f26; 
    address constant proxyLibEnd = 0x069B2fb501b6F16D1F5fE245B16F6993808f1008; 
    
    address constant cdpManagerAddr = 0x5ef30b9986345249bc32d8928B7ee64DE9435E39;  
    address constant mcdDaiAddr = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant mcdJoinDaiAddr = 0x9759A6Ac90977b93B58547b4A71c78317f391A28; 
    address constant mcdVatAddr = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B; 

    address constant mcdJoinEthaAddr  = 0x2F0b23f53734252Bda2277357e97e1517d6B042A;
    address constant mcdJoinBataAddr  = 0x3D0B1912B66114d4096F48A8CEe3A56C231772cA;
    address constant mcdJoinUsdcaAddr = 0xA191e578a6736167326d05c119CE0c90849E84B7;
    address constant mcdJoinUsdcbAddr = 0x2600004fd1585f7270756DDc88aD9cfA10dD0428;
    address constant mcdJoinWbtcaAddr = 0xBF72Da2Bd84c5170618Fbe5914B0ECA9638d5eb5;
    address constant mcdJoinTusdaAddr = 0x4454aF7C8bb9463203b66C816220D41ED7837f44;
    address constant mcdJoinZrxaAddr  = 0xc7e8Cd72BDEe38865b4F5615956eF47ce1a7e5D0;
    address constant mcdJoinKncaAddr  = 0x475F1a89C1ED844A08E8f6C50A00228b5E59E4A9;
    address constant mcdJoinManaaAddr = 0xA6EA3b9C04b8a38Ff5e224E7c3D6937ca44C0ef9;

    address constant mcdPotAddr = 0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7;
    address constant mcdSpotAddr = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
    address constant mcdCatAddr = 0x78F2c2AF65126834c51822F56Be0d7469D7A523E;
    address constant mcdJugAddr = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address constant mcdEndAddr = 0xaB14d3CE3F733CACB76eC2AbE7d2fcb00c99F3d5;
    
    address payable constant wethAddr = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address payable constant batAddr  = 0x0D8775F648430679A709E98d2b0Cb6250d2887EF;
    address payable constant usdcAddr = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address payable constant wbtcAddr = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address payable constant tusdAddr = 0x0000000000085d4780B73119b644AE5ecd22b376;
    address payable constant zrxAddr  = 0xE41d2489571d322189246DaFA5ebDe1F4699F498;
    address payable constant kncAddr  = 0xdd974D5C2e2928deA5F71b9825b8b646686BD200;
    address payable constant manaAddr = 0x0F5D2fB29fb7d3CFeE444a200298f468908cC942;

    address constant mcdIlkRegAddr = 0xbE4F921cdFEf2cF5080F9Cf00CC2c14F1F96Bd07; 

}
