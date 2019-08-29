pragma solidity 0.5.11;

import './Claimable.sol';


contract MCDWrapperMock is Claimable {
    uint256 public currentTokensAmount;
    uint256 public currentCollateralAmount;
    
    mapping(address => uint256) public lockedTokens;
    uint8 constant DSRPercent = 2;
    
    function lockTokens(uint256 _tokensAmount) public {
        lockedTokens[msg.sender] += _tokensAmount;
    }
    
    function unlockDaiTokens() public returns(uint256) {
        uint256 tokens = lockedTokens[msg.sender];
        lockedTokens[msg.sender] = 0;
        return (tokens * (100 + DSRPercent))/100;
    }
    
    function getDSR() public view returns(uint256) {
        return DSRPercent;
    }
    
    function openAndLockETH(uint256 _eth) public onlyContractOwner() returns(uint256 _tokensAmount) {
        uint256 tokensAmount = (_eth*66)/100;
        currentTokensAmount += tokensAmount;
        currentCollateralAmount += _eth;
        
        return currentTokensAmount;
    }
    
    function unlockETH(uint256 _tokensAmount) public onlyContractOwner() {
        currentTokensAmount -= _tokensAmount;
        if(currentTokensAmount == 0) {
            currentCollateralAmount = 0; // send collateral back to borrower
        }
        
    }
    
    function getDSProxy (address _proxyOwner) public returns(address) {
        return address(0); // to be changed
    }
    
    function transferCDPOwnership(address _user) public {
        //returns ownership to user
    }
    
    function inject (uint256 _tokenAmount) public {
        // approve()
        // wipe()
    }
    
    function quitCDP() public {
        // quits CDP contrct and transfers collateral to agreement contract address
    }
    
    function calculateCollateralEquivalent(uint256 _daiAmount) public returns(uint256 _collateralAmount) {
        return 0;
    }
    
    function checkLiquidation() public returns(bool _isLiquidated) {
        return false;
    }
}
