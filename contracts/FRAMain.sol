pragma solidity 0.5.11;

contract Ownable {
    address public owner;
    
    constructor () public {
        owner = msg.sender;
    }
    
    modifier onlyContractOwner() {
        require(owner == msg.sender);
        _;
    }
}

contract DaiStableCoinPrototype {
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address src, address dst, uint wad) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function balanceOf(address who) public view returns (uint256);
}

contract FRAMain is Ownable{
    mapping(address => address[]) public agreements;
    // borrowersArray
    
    function requestAgreementOnETH (uint256 _myCollateral, uint256 _expairyDate, uint256 _debtValue, uint256 _interestRate) 
    public payable returns(address _newAgreement) {
        
        AgreementETH c = new AgreementETH(_myCollateral, _debtValue, _expairyDate, _interestRate);
        agreements[msg.sender].push(address(c));
        return address(c);
    }
    
    function getNow () public view returns(uint256) {
        return now;
    }
}

contract BaseAgreement is Ownable{
    address constant daiStableCoin = address(0xc7cC3413f169a027dccfeffe5208Ca4f38eF0c40);
    address constant SimpleCDPMockAddress = address(0xef55BfAc4228981E850936AAf042951F7b146e41); 
    address constant SimpleDSRMockAddress = address(0x8c1eD7e19abAa9f23c476dA86Dc1577F1Ef401f5);
    
    uint256 constant TWENTY_FOUR_HOURS = 86399;
    
    address payable public borrower;
    address payable public lender;
    uint256 public borrowerCollateralValue;
    uint256 public debtValue;
    uint256 public startDate;
    uint256 public initialDate;
    uint256 public expireDate;
    uint256 public interestRate;
    address internal DSProxy; // to be removed and used getter from Wrapper contract
    address internal CDPContract;
    uint256 injectedBorrowerAmount;// to be removed for now
    uint256 borrowerFRADebt;
    
    event AgreementMatched(address _borrower, address _lender, uint256 _interestRate, uint256 _borrowerCollateralValue, uint256 _debtValue);
    
    modifier isMatched() {
        require(lender != address(0));
        _;
    }
    
    constructor(address payable _borrower, uint256 _borrowerCollateralValue, uint256 _debtValue, uint256 _expireDate, uint256 _interestRate) public payable {
        require(_expireDate > now, 'expairy date is in the past');
        
        borrower = _borrower;
        owner = msg.sender;
        debtValue = _debtValue;
        initialDate = now;
        expireDate = _expireDate;
        interestRate = _interestRate;
        borrowerCollateralValue = _borrowerCollateralValue;
        
        DSProxy = SimpleCDPMock(SimpleCDPMockAddress).getDSProxy(address(this));
        SimpleCDPMock(SimpleCDPMockAddress).openAndLockETH(_borrowerCollateralValue);
    }
    
    function matchAgreement() public returns(bool _success) {
        require(lender == address(0), 'Agreement has its owner already');
        require(DaiStableCoinPrototype(daiStableCoin)
            .transferFrom(msg.sender, address(this), debtValue), 'Impossible to transfer DAI tokens, make valid allowance');
        lender = msg.sender;
        startDate = now;
        SimpleDSRMock(SimpleDSRMockAddress).lockTokens(debtValue);
        
        emit AgreementMatched(borrower, msg.sender, interestRate, borrowerCollateralValue, debtValue);
    }
    
    function checkThisAgreement() public onlyContractOwner() isMatched() { // is supposed to be called in loop externaly
        if(SimpleCDPMock(SimpleCDPMockAddress).checkLiquidation()) {
            _terminateAgreement(true);
        }
        
        if(_checkExpiringDate()) {
            _terminateAgreement(false);
        }
        require(_updateCurrentStateOrMakeInjection());
    }
    
    function _checkExpiringDate() internal returns(bool _isExpired) {
        return (now > expireDate || lender == address(0) && now > (initialDate + TWENTY_FOUR_HOURS));
    }
    
    function _terminateAgreement(bool _isLiquidated) internal returns(bool _success) {
        uint256 currentDaiLenderBalance;
        if(_isLiquidated) {
            lender.transfer(SimpleCDPMock(SimpleCDPMockAddress).calculateCollateralEquivalent(borrowerFRADebt));
            borrower.transfer(address(this).balance - 
                - SimpleCDPMock(SimpleCDPMockAddress).calculateCollateralEquivalent(borrowerFRADebt));  
        } else {
            if(borrowerFRADebt > 0) { // can be removed and replaced with code in this if {} to make code shorter but gas higher
                if(DaiStableCoinPrototype(daiStableCoin).transferFrom(borrower, address(this), borrowerFRADebt)) {
                    currentDaiLenderBalance = SimpleDSRMock(SimpleDSRMockAddress).unlockTokens();
                    DaiStableCoinPrototype(daiStableCoin).transfer(lender, currentDaiLenderBalance + borrowerFRADebt);
                    SimpleCDPMock(SimpleCDPMockAddress).transferOwnership(borrower);
                } else {
                    SimpleCDPMock(SimpleCDPMockAddress).quitCDP();
                    lender.transfer(SimpleCDPMock(SimpleCDPMockAddress).calculateCollateralEquivalent(borrowerFRADebt));
                    borrower.transfer(address(this).balance - 
                        - SimpleCDPMock(SimpleCDPMockAddress).calculateCollateralEquivalent(borrowerFRADebt));            
                }
            } else {
                currentDaiLenderBalance = SimpleDSRMock(SimpleDSRMockAddress).unlockTokens();
                DaiStableCoinPrototype(daiStableCoin).transfer(lender, currentDaiLenderBalance);
                SimpleCDPMock(SimpleCDPMockAddress).transferOwnership(borrower);
            }
        }
        return true;
    }
    
    function _updateCurrentStateOrMakeInjection() internal returns(bool _success) { 
        uint256 currentDSR = SimpleDSRMock(SimpleDSRMockAddress).getDSR();
        
        uint256 currentDaiLenderBalance = SimpleDSRMock(SimpleDSRMockAddress).unlockTokens();
        
        if(currentDSR >= interestRate) {
            uint256 currentDifference = debtValue * (currentDSR - interestRate); // to extend with calculation according to decimals
            
            if(currentDifference <= borrowerFRADebt) {
                borrowerFRADebt -= currentDifference;
            } else {
                currentDifference -= borrowerFRADebt;
                DaiStableCoinPrototype(daiStableCoin).approve(DSProxy, currentDifference);
                SimpleCDPMock(SimpleCDPMockAddress).inject(currentDifference); 
                currentDaiLenderBalance -= currentDifference;
            }
            
            //injectedBorrowerAmount += currentDifference;
        } else {
            uint256 currentDifference = debtValue * (interestRate - currentDSR); // to extend with calculation according to decimals
            //currentDaiBorrowerBalance -= currentDifference;
            currentDaiLenderBalance += currentDifference;
            
            borrowerFRADebt += currentDifference;
        }
        SimpleDSRMock(SimpleDSRMockAddress).lockTokens(currentDaiLenderBalance);
    }
}

contract AgreementETH is BaseAgreement {
    
    constructor (uint256 _borrowerCollateralValue, uint256 _debtValue, uint256 _expairyDate, uint256 _interestRate) public
    BaseAgreement(msg.sender, _borrowerCollateralValue, _debtValue, _expairyDate, _interestRate) {
        
    }
}

/*contract AgreementERC20 is OwnableForLoosers{
    
    constructor (uint256 _borrowerCollateralValue, uint256 _debtValue, uint256 _expairyDate, uint256 _interestRate, address _tokenAddress) public
    BaseAgreement(_borrowerCollateralValue, _debtValue, _expairyDate, _interestRate) {
        require(ERC20(_tokenAddress).transferFrom);
    }
    
    function join () public {
        
    }
}*/

contract SimpleCDPMock is Ownable {
    uint256 public currentTokensAmount;
    uint256 public currentCollateralAmount;
    
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
    
    function transferOwnership(address _user) public {
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

contract SimpleDSRMock is Ownable {
    mapping(address => uint256) public lockedTokens;
    uint8 constant DSRPercent = 2;
    
    function lockTokens(uint256 _tokensAmount) public {
        lockedTokens[msg.sender] += _tokensAmount;
    }
    
    function unlockTokens() public returns(uint256) {
        uint256 tokens = lockedTokens[msg.sender];
        lockedTokens[msg.sender] = 0;
        return (tokens * (100 + DSRPercent))/100;
    }
    
    function getDSR() public view returns(uint256) {
        return DSRPercent;
    }
}
