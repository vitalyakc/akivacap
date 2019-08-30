pragma solidity 0.5.11;

import './Claimable.sol';
import './MCDWrapperMock.sol';
import './DaiInterface.sol';


interface AgreementInterface {
    
    function isClosed() external view returns(bool);
    function matchAgreement() external returns(bool);
    function checkAgreement() external returns(bool);
    
    event AgreementInitiated(address _borrower, uint256 _interestRate, uint256 _borrowerCollateralValue, uint256 _debtValue);
    event AgreementMatched(address _borrower, address _lender, uint256 _interestRate, uint256 _borrowerCollateralValue, uint256 _debtValue);
}

contract BaseAgreement is Claimable, AgreementInterface{
    address constant daiStableCoinAddress = address(0xc7cC3413f169a027dccfeffe5208Ca4f38eF0c40);
    address constant MCDWrapperMockAddress = address(0xdE6A66562c299052B1cfD24ABC1DC639d429e1d6); 
    
    DaiInterface DaiInstance = DaiInterface(daiStableCoinAddress);
    MCDWrapperMock WrapperInstance = MCDWrapperMock(MCDWrapperMockAddress);

    uint32 constant TWENTY_FOUR_HOURS = 86399;
    
    address payable public borrower;
    address payable public lender;
    uint256 public borrowerCollateralValue;
    uint256 public debtValue;
    uint256 public startDate;
    uint256 public initialDate;
    uint256 public expireDate;
    uint256 public interestRate;
    uint256 borrowerFRADebt;
    bool public isClosed;
    
    modifier isActive() {
        require(!isClosed);
        _;
    }
    
    constructor(address payable _borrower, uint256 _borrowerCollateralValue, uint256 _debtValue, uint256 _expireDate, uint256 _interestRate) public payable {
        require(_expireDate > now, 'expairy date is in the past');
        require(_debtValue > 0);

        borrower = _borrower;
        debtValue = _debtValue;
        initialDate = now;
        expireDate = _expireDate;
        interestRate = _interestRate;
        borrowerCollateralValue = _borrowerCollateralValue;
        WrapperInstance.openAndLockETH(_borrowerCollateralValue);
    }
}

contract AgreementETH is BaseAgreement {
    
    constructor (address payable _borrower, uint256 _borrowerCollateralValue, uint256 _debtValue, uint256 _expairyDate, uint256 _interestRate) public
    BaseAgreement(_borrower, _borrowerCollateralValue, _debtValue, _expairyDate, _interestRate) {}
    
    function matchAgreement() public isActive() returns(bool _success) {
        require(isPending(), 'Agreement has its lender already');
        require(DaiInstance.transferFrom(msg.sender, address(this), debtValue), 'Impossible to transfer DAI tokens, make valid allowance');
        lender = msg.sender;
        startDate = now;
        WrapperInstance.lockTokens(debtValue);
        
        emit AgreementMatched(borrower, msg.sender, interestRate, borrowerCollateralValue, debtValue);
        return true;
    }
    
    function checkAgreement() public onlyContractOwner() isActive() returns(bool _success) { // is supposed to be called in loop externaly
        if (!isPending()) {
            _updateCurrentStateOrMakeInjection();
            
            if(WrapperInstance.checkLiquidation()) {
            _liquidateAgreement();
            }
        }
        
        if(_checkExpiringDate()) {
            _terminateAgreement();
        }
        
        return true;
    }
    
    function _checkExpiringDate() internal returns(bool _isExpired) {
        return (now > expireDate || isPending() && now > (initialDate + TWENTY_FOUR_HOURS));
    }
    
    function _terminateAgreement() internal returns(bool _success) {
        uint256 finalDaiLenderBalance;
        
        if(borrowerFRADebt > 0) {
        (bool TransferSuccessful,) = daiStableCoinAddress.call(abi.encodeWithSignature('transferFrom(address, address, uint256)', borrower, address(this), borrowerFRADebt));
            
            if(TransferSuccessful) {
                finalDaiLenderBalance = WrapperInstance.unlockDaiTokens() + borrowerFRADebt;
            } else {
                WrapperInstance.quitCDP();
                _refundUsersAfterCDPLiquidation();
            }
        } else {
            finalDaiLenderBalance = WrapperInstance.unlockDaiTokens();
        }
        
        DaiInstance.transfer(lender, finalDaiLenderBalance);
        WrapperInstance.transferCDPOwnership(borrower);
        
        isClosed = true;
        return true;
    }
    
    function _liquidateAgreement() internal returns(bool _success) {
        if(borrowerFRADebt > 0) {
            _refundUsersAfterCDPLiquidation();
        } else {
            borrower.transfer(address(this).balance);
        }
        
        DaiInstance.transfer(lender, WrapperInstance.unlockDaiTokens());
        WrapperInstance.transferCDPOwnership(borrower);
        
        isClosed = true;
        return true;
    }
    
    function _updateCurrentStateOrMakeInjection() internal returns(bool _success) { 
        uint256 currentDSR = WrapperInstance.getDSR();
        uint256 currentDaiLenderBalance;
        
        if(currentDSR >= interestRate) {
            currentDaiLenderBalance = WrapperInstance.unlockDaiTokens();
            
            uint256 currentDifference = debtValue * (currentDSR - interestRate); // to extend with calculation according to decimals
            
            if(currentDifference <= borrowerFRADebt) {
                borrowerFRADebt -= currentDifference;
            } else {
                currentDifference -= borrowerFRADebt;
                DaiInstance.approve(WrapperInstance.getDSProxy(address(this)), currentDifference);
                WrapperInstance.inject(currentDifference); 
                currentDaiLenderBalance -= currentDifference;
            }
            WrapperInstance.lockTokens(currentDaiLenderBalance);
        } else {
            uint256 currentDifference = debtValue * (interestRate - currentDSR); // to extend with calculation according to decimals
            currentDaiLenderBalance += currentDifference;
            
            borrowerFRADebt += currentDifference;
        }
        
        return true;
    }
    
    function isPending() public view returns(bool) {
        return (lender == address(0));
    }
    
    function _refundUsersAfterCDPLiquidation() internal returns(bool _success) {
        uint256 ethFRADebtEquivalent = WrapperInstance.calculateCollateralEquivalent(borrowerFRADebt);
        lender.transfer(ethFRADebtEquivalent);
        borrower.transfer(address(this).balance - ethFRADebtEquivalent);
        return true;
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
