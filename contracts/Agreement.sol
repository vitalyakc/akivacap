pragma solidity 0.5.11;

import './Claimable.sol';
import './McdWrapper.sol';
import './SafeMath.sol';
import './ERC20Interface.sol';

/**
 * @title Interface for Agreement contract
 */
interface AgreementInterface {
    
    function isClosed() external view returns(bool);
    function approve() external returns(bool);
    function matchAgreement() external returns(bool);
    function checkAgreement() external returns(bool);
    function closePendingAgreement() external returns(bool);

    event AgreementInitiated(address _borrower, uint256 _borrowerCollateralValue, 
        uint256 _debtValue, uint256 _expireDate, uint256 _interestRate);
    event AgreementApproved(address _borrower, uint256 _borrowerCollateralValue, 
        uint256 _debtValue, uint256 _expireDate, uint256 _interestRate);
    event AgreementMatched(address _lender, uint256 _startDate, uint256 _lastCheckTime);
    event AgreementUpdated(uint256 _borrowerFRADebt, 
        uint256 _lenderPendingInjection, uint256 _injectedDaiAmount);
    event AgreementTerminated(uint256 _borrowerFraDebtDai, uint256 _finalDaiLenderBalance);
    event AgreementLiquidated(uint256 _lenderEthReward, uint256 _borrowerEthResedual);
}

/**
 * @title Base Agreement contract
 * @dev Should not be deployed. It is being used as an abstract class
 */
contract BaseAgreement is Claimable, AgreementInterface {
    using SafeMath for uint256;
    
    address constant daiStableCoinAddress = address(0xc7cC3413f169a027dccfeffe5208Ca4f38eF0c40);
    address constant McdWrapperAddress = address(0x89DCC7caa7E5e33C712C2641254c91676b2c568d);
    
    ERC20Interface DaiInstance = ERC20Interface(daiStableCoinAddress);
    McdWrapper WrapperInstance = McdWrapper(McdWrapperAddress);

    uint256 constant TWENTY_FOUR_HOURS = 86399;
    uint256 constant YEAR =  31536000;
    uint256 constant ONE = 10 ** 27;
    
    uint256 public injectionThreshold = 2 * ONE;
    
    address payable public borrower;
    address payable public lender;
    uint256 public borrowerCollateralValue;
    uint256 public debtValue;
    uint256 public startDate;
    uint256 public initialDate;
    uint256 public expireDate;
    uint256 public interestRate;
    bytes32 public collateralType;
    uint256 public borrowerFRADebt;
    uint256 public lenderPendingInjection;
    bool public isClosed;
    uint256 public cdpId;
    uint256 public lastCheckTime;
    bool public isApproved;
    
    // test version, should be extended after stable 
    // multicollaterall makerDAO release
    uint256 public dsrTest = 105 * 10 ** 25;
    
    /**
     * @notice Grants access only if agreement is not terminated yet
     */ 
    modifier isNotClosed() {
        require(!isClosed, 'Agreement is closed');
        _;
    }

    /**
     * @notice Grants access only if agreement does not have lender address yet
     */
    modifier onlyPending() {
        require(isPending(), 'Agreement has its lender already');
        _;
    }
    
    /**
     * @notice Grants access only if agreement is approved
     */ 
    modifier onlyApproved() {
        require(isApproved, 'Agreement is not approved');
        _;
    }
    
    constructor(address payable _borrower, uint256 _borrowerCollateralValue, 
        uint256 _debtValue, uint256 _expireDate, uint256 _interestRate, bytes32 _collateralType) 
    public payable 
    {
        require(_debtValue > 0, 'debt cannot be 0');
        require(_interestRate <= ONE, 'interestRate is more than 100 percent');
        
        expireDate = now.add(_expireDate.mul(60));
        
        require(expireDate > now, 'expire date is in the past');

        borrower = _borrower;
        debtValue = _debtValue;
        initialDate = now;
        interestRate = _interestRate + ONE;
        borrowerCollateralValue = _borrowerCollateralValue;
        collateralType = _collateralType;
        
        emit AgreementInitiated(
            _borrower, _borrowerCollateralValue, _debtValue, _expireDate, _interestRate);
    }
    
    /**
     * @notice Approves the agreement. Only for contract owner
     * @return Operation success
     */
    function approve() public onlyContractOwner() isNotClosed() returns(bool _success) {
        require(!isApproved, 'Agreement is already approved');
        
        cdpId = _openCdp();
        
        DaiInstance.transfer(borrower, debtValue);
        
        isApproved = true;
        
        emit AgreementApproved(
            borrower, borrowerCollateralValue, debtValue, expireDate, interestRate);
        
        return true;
    }
    
    /**
     * @notice Connects lender to the agreement.
     * @return Operation success
     */
    function matchAgreement() 
    public isNotClosed() onlyPending() onlyApproved() returns(bool _success) {
        (bool transferSuccess,) = daiStableCoinAddress.call(
            abi.encodeWithSignature(
            'transferFrom(address,address,uint256)', msg.sender, address(this), debtValue));
        require(transferSuccess, 'Impossible to transfer DAI tokens, make valid allowance');
        
        lender = msg.sender;
        startDate = now;
        execute(McdWrapperAddress, abi.encodeWithSignature('lockDai(uint256)', debtValue));

        lastCheckTime = now;
        
        emit AgreementMatched(msg.sender, now, now);
        return true;
    }
    
    /**
     * @notice Calls needed function according to the expireDate
     * (terminates or updates the agreement)
     * @dev Executes lots of external calls
     * @return Operation success
     */
     function checkAgreement() public onlyContractOwner() isNotClosed() returns(bool _success) { 
        if(!isApproved && now > initialDate + TWENTY_FOUR_HOURS) {
            _closeRejectedAgreement();
        } else {
            if (!isPending()) {
                _updateCurrentStateOrMakeInjection();
            
                if(WrapperInstance.isCDPLiquidated(collateralType, cdpId)) {
                    _liquidateAgreement();
                }
            }
        
            if(_checkExpiringDate()) {
                _terminateAgreement();
            }
        
            lastCheckTime = now;
        }
        
        return true;
    }
    
    /**
     * @notice Allows borrower to terminate agreement if it has no lender yet
     * @return Operation success
     */
    function closePendingAgreement()
     public isNotClosed() onlyPending() onlyApproved() returns(bool _success) {
        require(msg.sender == borrower, 'Accessible only for borrower');
        
        execute(
            McdWrapperAddress, 
            abi.encodeWithSignature('transferCdpOwnership(uint256,address)', cdpId, msg.sender));
        
        isClosed = true;
        
        return true;
    }
    
    /**
     * @notice returns lender existence
     */
    function isPending() public view returns(bool) {
        return (lender == address(0));
    }
    
    /**
     * @notice should be removed after testing!!!
     */
    function setBorrowerFraDebt(uint256 _borrowerFraDebt) public {
        borrowerFRADebt = _borrowerFraDebt;
    }
    
    function setdsrTest(uint256 _dsrTest) public {
        dsrTest = _dsrTest;
    }
    
    function() external payable {}

    /**
     * @notice Updates the state of Agreement
     * @return Operation success
     */
    function _updateCurrentStateOrMakeInjection() internal returns(bool _success) { 
        uint256 currentDSR = dsrTest; //WrapperInstance.getDsr();
        uint256 currentDaiLenderBalance;
        uint256 timeInterval = now.sub(lastCheckTime);
        uint256 currentDifference;
        uint256 lenderPendingInjectionDai;
        
        bytes memory response = execute(
            McdWrapperAddress, abi.encodeWithSignature('unlockAllDai()'));
        assembly {
            currentDaiLenderBalance := mload(add(response, 0x20))
        }
        
        if(currentDSR >= interestRate) {
            
            //rad, 45
            currentDifference = ((debtValue.mul(
                (currentDSR.sub(interestRate)))).mul(timeInterval)) / YEAR; 
            
            if(currentDifference <= borrowerFRADebt) {
                //rad, 45
                borrowerFRADebt = borrowerFRADebt.sub(currentDifference);
            } else {
                currentDifference = currentDifference.sub(borrowerFRADebt);
                borrowerFRADebt = 0;
                //rad, 45
                lenderPendingInjection = lenderPendingInjection.add(currentDifference);
                if(lenderPendingInjection >= injectionThreshold) {
                    //wad, 18
                    lenderPendingInjectionDai = lenderPendingInjection/ONE;
                    execute(
                        McdWrapperAddress, 
                        abi.encodeWithSignature(
                        'injectToCdp(uint256,uint256)', cdpId, lenderPendingInjectionDai));
                    //wad, 18
                    lenderPendingInjection = lenderPendingInjection.sub(lenderPendingInjectionDai * ONE);
                    currentDaiLenderBalance = currentDaiLenderBalance.sub(lenderPendingInjectionDai);
                } 
            }
        } else {
            currentDifference = ((debtValue.mul(
                (interestRate.sub(currentDSR)))).mul(timeInterval)) / YEAR;
            if(lenderPendingInjection >= currentDifference) {
                lenderPendingInjection = lenderPendingInjection.sub(currentDifference);
            } else {
                borrowerFRADebt = currentDifference.sub(lenderPendingInjection);
                lenderPendingInjection = 0;
            }
        }
        
        execute(
            McdWrapperAddress, 
            abi.encodeWithSignature(
            'lockDai(uint256)', currentDaiLenderBalance));
        
        emit AgreementUpdated(borrowerFRADebt, lenderPendingInjection, lenderPendingInjectionDai);
        return true;
    }

    /**
     * @notice checks whether expireDate has come
     */
    function _checkExpiringDate() internal view returns(bool _isExpired) {
        return (now > expireDate || isPending() && now > (initialDate + TWENTY_FOUR_HOURS));
    }
    
    /**
     * @notice Terminates agreement
     * @return Operation success
     */
    function _terminateAgreement() internal returns(bool _success) {
        uint256 borrowerFraDebtDai = borrowerFRADebt/ONE;
        uint256 finalDaiLenderBalance;
        
        bytes memory response = execute(
            McdWrapperAddress, abi.encodeWithSignature('unlockAllDai()'));
        assembly {
            finalDaiLenderBalance := mload(add(response, 0x20))
        }
        if(borrowerFraDebtDai > 0) {
            (bool TransferSuccessful,) = daiStableCoinAddress.call(abi.encodeWithSignature(
                'transferFrom(address,address,uint256)', borrower, address(this), borrowerFraDebtDai));
            
            if(TransferSuccessful) {
                finalDaiLenderBalance = finalDaiLenderBalance.add(borrowerFraDebtDai);
                
                emit AgreementTerminated(borrowerFraDebtDai, finalDaiLenderBalance);
            } else {
                WrapperInstance.forceLiquidate(collateralType, cdpId);
                _refundUsersAfterCDPLiquidation();
            }
        }
        
        DaiInstance.transfer(lender, finalDaiLenderBalance);
        execute(
            McdWrapperAddress, 
            abi.encodeWithSignature('transferCdpOwnership(uint256,address)', cdpId, borrower));
        
        isClosed = true;
        return true;
    }
    
    /**
     * @notice Liquidates agreement, mostly the sam as terminate 
     * but also covers collateral transfers after liquidation
     * @return Operation success
     */
    function _liquidateAgreement() internal returns(bool _success) {
        uint256 finalDaiLenderBalance;
        
        _refundUsersAfterCDPLiquidation();
        
        bytes memory response = execute(
            McdWrapperAddress, abi.encodeWithSignature('unlockAllDai()'));
        assembly {
            finalDaiLenderBalance := mload(add(response, 0x20))
        }
        
        DaiInstance.transfer(lender, finalDaiLenderBalance);
        execute(
            McdWrapperAddress, 
            abi.encodeWithSignature('transferCdpOwnership(uint256,address)', cdpId, borrower));
        
        isClosed = true;
        return true;
    }
    
    // solium-disable no-empty-blocks
    function _closeRejectedAgreement() internal {}
    function _refundUsersAfterCDPLiquidation() internal returns(bool _success) {}
    function _openCdp() internal returns(uint256) {}
    // solium-enable no-empty-blocks

    /**
     * @notice Makes a delegatecall and gives a possibility 
     * to get a returning value
     */
    function execute(address _target, bytes memory _data)
        public
        payable
        returns (bytes memory response)
    {
        require(_target != address(0), 'ds-proxy-target-address-required');

        // call contract in current context
        assembly {
            let succeeded := delegatecall(sub(gas, 5000), _target, add(_data, 0x20), mload(_data), 0, 0)
            let size := returndatasize

            response := mload(0x40)
            mstore(0x40, add(response, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            switch iszero(succeeded)
            case 1 {
                // throw if delegatecall failed
                revert(add(response, 0x20), size)
            }
        }
    }
}

/**
 * @title Inherited from BaseAgreement, should be deployed for ETH collateral
 */
contract AgreementETH is BaseAgreement {
    constructor (
        address payable _borrower, uint256 _borrowerCollateralValue, 
        uint256 _debtValue, uint256 _expairyDate, uint256 _interestRate, bytes32 _collateralType) 
    public payable
    BaseAgreement(
        _borrower, _borrowerCollateralValue, _debtValue, 
        _expairyDate, _interestRate, _collateralType) 
    {
        require(msg.value == _borrowerCollateralValue, 'Actual ehter value is not correct');
    }
    
    /**
     * @notice Closes rejected agreement and 
     * transfers collateral ETH back to user
     */
    function _closeRejectedAgreement() internal isNotClosed() {
        borrower.transfer(borrowerCollateralValue);
        
        isClosed = true;
    }
    
    /**
     * @notice Opens CDP contract in makerDAO system with ETH
     * @return cdpId - id of cdp contract in makerDAO
     */
    function _openCdp() internal returns(uint256) {
        uint256 _cdpId;
        
        // solium-disable-next-line indentation
        bytes memory response = execute(McdWrapperAddress, abi.encodeWithSignature(
            'openLockETHAndDraw(bytes32,uint256,uint256)', 
            collateralType, debtValue, borrowerCollateralValue));
        assembly {
            _cdpId := mload(add(response, 0x20))
        }
        
        return _cdpId;
    }
    
    /**
     * @notice Executes all required transfers after liquidation
     * @return Operation success
     */
    function _refundUsersAfterCDPLiquidation() internal returns(bool _success) {
        uint256 collateralFRADebtEquivalent = WrapperInstance.getCollateralEquivalent(
            collateralType, borrowerFRADebt/ONE);
            
        lender.transfer(collateralFRADebtEquivalent);
        
        uint256 borrowerRefundAmount = address(this).balance;
        borrower.transfer(borrowerRefundAmount);
        
        emit AgreementLiquidated(
            collateralFRADebtEquivalent, borrowerRefundAmount);
        return true;
    }
}

/**
 * @title Inherited from BaseAgreement, should be deployed for ERC20 collateral
 */
contract AgreementERC20 is BaseAgreement {
    address erc20ContractAddress;
    ERC20Interface Erc20Instance;
    
    constructor (
        address payable _borrower, uint256 _borrowerCollateralValue, 
        uint256 _debtValue, uint256 _expairyDate, uint256 _interestRate, 
        bytes32 _collateralType, address _erc20ContractAddress) 
    public payable
    BaseAgreement(
        _borrower, _borrowerCollateralValue, _debtValue, 
        _expairyDate, _interestRate, _collateralType) 
    {
        erc20ContractAddress = _erc20ContractAddress;
        Erc20Instance = ERC20Interface(_erc20ContractAddress);
    }
    
    /**
     * @notice Closes rejected agreement and 
     * transfers collateral tokens back to user
     */
    function _closeRejectedAgreement() internal isNotClosed() {
        Erc20Instance.transfer(borrower, borrowerCollateralValue);
        
        isClosed = true;
    }
    
    /**
     * @notice Opens CDP contract in makerDAO system with ERC20
     * @return cdpId - id of cdp contract in makerDAO
     */
    function _openCdp() internal returns(uint256) {
        uint256 _cdpId;
        
        // solium-disable-next-line indentation
        bytes memory response = execute(McdWrapperAddress, abi.encodeWithSignature(
            'openLockERC20AndDraw(bytes32,uint256,uint256)', 
            collateralType, debtValue, borrowerCollateralValue));
        assembly {
            _cdpId := mload(add(response, 0x20))
        }
        
        return _cdpId;
    }
    
    /**
     * @notice Executes all required transfers after liquidation
     * @return Operation success
     */
    function _refundUsersAfterCDPLiquidation() internal returns(bool _success) {
        uint256 collateralFRADebtEquivalent = WrapperInstance.getCollateralEquivalent(
            collateralType, borrowerFRADebt/ONE);
            
        Erc20Instance.transfer(lender, collateralFRADebtEquivalent);
        
        uint256 borrowerRefundAmount = Erc20Instance.balanceOf(address(this));
        Erc20Instance.transfer(borrower, borrowerRefundAmount);

        emit AgreementLiquidated(
            collateralFRADebtEquivalent, borrowerRefundAmount);
        return true;
    }
}
