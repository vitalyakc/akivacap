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
    function transferFrom(address src, address dst, uint wad) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
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
    address constant SimpleCDPMockAddress = address(0x0DCd2F752394c41875e259e00bb44fd505297caF); 
    address constant SimpleDSRMockAddress = address(0x5E72914535f202659083Db3a02C984188Fa26e9f);
    
    uint256 constant TWENTY_FOUR_HOURS = 86399;
    
    address borrower;
    uint256 public borrowerCollateralValue;
    uint256 public debtValue;
    uint256 public startDate;
    uint256 public initialDate;
    uint256 public expireDate;
    uint256 public interestRate;
    address public lender;
    address internal DSProxy; // to be removed and used getter from Wrapper contract
    address internal CDPContract;
    uint256 currentDaiBorrowerBalance;
    uint256 currentDaiLenderBalance;
    uint256 injectedBorrowerAmount;
    
    event AgreementMatched(address _borrower, address _lender, uint256 _interestRate, uint256 _borrowerCollateralValue, uint256 _debtValue);
    
    modifier isMatched() {
        require(lender != address(0));
        _;
    }
    
    constructor(address _borrower, uint256 _borrowerCollateralValue, uint256 _debtValue, uint256 _expireDate, uint256 _interestRate) public payable {
        require(_expireDate > now, 'expairy date is in the past');
        
        borrower = _borrower;
        owner = msg.sender;
        currentDaiBorrowerBalance = borrowerCollateralValue = _borrowerCollateralValue;
        debtValue = _debtValue;
        initialDate = now;
        expireDate = _expireDate;
        interestRate = _interestRate;
        
        DSProxy = SimpleCDPMock(SimpleCDPMockAddress).getDSProxy(address(this));
        currentDaiBorrowerBalance = SimpleCDPMock(SimpleCDPMockAddress).openLockETHAndDraw(borrowerCollateralValue);
    }
    
    function matchAgreement() public returns(bool _success) {
        require(lender == address(0), 'Agreement has its owner already');
        require(DaiStableCoinPrototype(daiStableCoin)
            .transferFrom(msg.sender, address(this), debtValue), 'Impossible to transfer DAI tokens, make valid allowance');
        lender = msg.sender;
        startDate = now;
        currentDaiLenderBalance = debtValue;
        SimpleDSRMock(SimpleDSRMockAddress).lockTokens(debtValue);
        
        emit AgreementMatched(borrower, msg.sender, interestRate, borrowerCollateralValue, debtValue);
    }
    
    function checkThisAgreement() public onlyContractOwner() isMatched() { // is supposed to be called in loop externaly
        if(_checkExpiringDate()) {
            _terminateAgreement();
        }
        require(_updateCurrentBalancesAndMakeInjection());
    }
    
    function _checkExpiringDate() internal returns(bool _isExpired) {
        return (now > expireDate || lender == address(0) && now > (initialDate + TWENTY_FOUR_HOURS));
    }
    
    function _terminateAgreement() internal returns(bool _success) {
        // to do
    }
    
    function _updateCurrentBalancesAndMakeInjection() internal returns(bool _success) { 
        uint256 currentDSR = SimpleDSRMock(SimpleDSRMockAddress).getDSR();
        
        currentDaiLenderBalance = SimpleDSRMock(SimpleDSRMockAddress).unlockTokens();
        
        if(currentDSR >= interestRate) {
            uint256 currentDifference = debtValue * (currentDSR - interestRate); // to extend with calculation according to decimals
            DaiStableCoinPrototype(daiStableCoin).approve(DSProxy, currentDifference);
            SimpleCDPMock(SimpleCDPMockAddress).inject(currentDifference);
            injectedBorrowerAmount += currentDifference;
            currentDaiLenderBalance -= currentDifference;
        } else {
            uint256 currentDifference = debtValue * (interestRate - currentDSR); // to extend with calculation according to decimals
            currentDaiBorrowerBalance -= currentDifference;
            currentDaiLenderBalance += currentDifference;
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
    
    function openLockETHAndDraw(uint256 _eth) public onlyContractOwner() returns(uint256 _tokensAmount) {
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
    
    function inject (uint256 _tokenAmount) public {
        // approve()
        // wipe()
    }
}
