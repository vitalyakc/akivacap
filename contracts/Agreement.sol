pragma solidity 0.5.12;

import "./config/Config.sol";
import "./helpers/ClaimableIni.sol";
import "./helpers/SafeMath.sol";
import "./mcd/McdWrapper.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IAgreement.sol";

/**
 * @title Base Agreement contract
 * @dev Contract will be deployed only once as logic(implementation), proxy will be deployed by FraFactory for each agreement as storage
 */
contract Agreement is IAgreement, ClaimableIni, McdWrapper {
    using SafeMath for uint;
    using SafeMath for int;
    
    struct Asset {
        uint collateral;
        uint dai;
    }
    
    uint constant internal YEAR_SECS = 365 days;

    /**
     * Agreement status timestamp snapshots
     */
    mapping(uint => uint) public statusSnapshots;

    /**
     * Agreement participants assets
     */
    mapping(address => Asset) public assets;

    /**
     * Agreement status
     */
    Statuses public status;

    /**
     * Type the agreement is closed by
     */
    ClosedTypes public closedType;

    /**
     * Config contract address
     */
    address public configAddr;

    /**
     * True if agreement collateral is ether
     */
    bool public isETH;

    /**
     * Agreement risky marker
     */
    bool public isRisky;

    /**
     * Aggreement duration in seconds
     */
    uint256 public duration;

    /**
     * Agreement expiration date. Is calculated during match
     */
    uint256 public expireDate;

    /**
     * Borrower address
     */
    address payable public borrower;

    /**
     * Lender address
     */
    address payable public lender;

    /**
     * Bytes32 representation of collateral type like ETH-A
     */
    bytes32 public collateralType;

    /** 
     * uint ilk index in Jug and IlkRegistry
     */
    bytes32 public ilkIndex;

    /**
     * Collateral amount
     */
    uint256 public collateralAmount;

    /**
     * Dai debt amount of CDP at the last update
     */
    uint256 public cdpDebtValue;

    /**
     * Fixed intereast rate %
     */
    uint256 public interestRate;

    /**
     * Vault (CDP) id in maker dao contracts
     */
    uint256 public cdpId;

    /**
     * Last time the agreement was updated
     */
    uint256 public lastCheckTime;

    /**
     * Total amount drawn to cdp while paying off borrower's agreement debt
     */
    uint public drawnTotal;

    /**
     * Total amount injected to cdp during paying off lender's agreement debt
     */
    uint public injectedTotal;

    /**
     * Delta shows user's debt (ray units)
     * if delta < 0 - it is borrower's debt to lender
     * if delta > 0 - it is lender's debt to borrower
     */
    int public delta;

    /**
     * shows borrower's unpaid fee debt, in RAY 
     */
    uint public feeAccum;

    /**
     * shows paid fee in DAI
     */
    uint public feePaidTotal;

    /**
     * @dev  Grants access only to agreement's borrower
     */
    modifier onlyBorrower() {
        require(msg.sender == borrower, "Agreement: Accessible only for borrower");
        _;
    }

    /**
     * @dev  Grants access only if agreement has appropriate status
     * @param   _status status should be checked with
     */
    modifier hasStatus(Statuses _status) {
        require(status == _status, "Agreement: Agreement status is incorrect");
        _;
    }

    /**
     * @dev  Grants access only if agreement has status before requested one
     * @param   _status check before status
     */
    modifier beforeStatus(Statuses _status) {
        require(status < _status, "Agreement: Agreement status is not before requested one");
        _;
    }

    /**
     * @dev  Initialize new agreement
     * @param   _borrower       borrower address
     * @param   _collateralAmount value of borrower's collateral amount put into the contract as collateral or approved to transferFrom
     * @param   _debtValue      value of debt
     * @param   _duration       number of seconds which agreement should be terminated after
     * @param   _interestRate   percent of interest rate, should be passed like RAY
     * @param   _collateralType type of collateral, should be passed as bytes32
     * @param   _isETH          true if ether and false if erc-20 token
     * @param   _configAddr     config contract address
     */
    function initAgreement(
        address payable _borrower,
        uint256 _collateralAmount,
        uint256 _debtValue,
        uint256 _duration,
        uint256 _interestRate,
        bytes32 _collateralType,
        bytes32 _ilkIndex,
        bool    _isETH,
        address _configAddr
    ) public payable initializer {
        ClaimableIni.initialize();

        require(Config(_configAddr).isCollateralEnabled(_collateralType), "Agreement: collateral type is currencly disabled");
        require(_debtValue > 0, "Agreement: debt is zero");
        require(
            (_collateralAmount > Config(_configAddr).minCollateralAmount()) &&
            (_collateralAmount < Config(_configAddr).maxCollateralAmount()), "Agreement: collateral value does not match min and max");
        require(
            (_interestRate > ONE) &&
            (_interestRate <= ONE * 2), "Agreement: interestRate should be between 0 and 100 %");
        require(
            (_duration > Config(_configAddr).minDuration()) &&
            (_duration < Config(_configAddr).maxDuration()), "Agreement: duration value does not match min and max");
        require(!_isETH || msg.value == _collateralAmount, "Agreement: Actual ehter sent value is not correct");
    
        configAddr = _configAddr;
        isETH = _isETH;
        borrower = _borrower;
        cdpDebtValue = _debtValue;
        duration = _duration;
        interestRate = _interestRate;
        collateralAmount = _collateralAmount;
        collateralType = _collateralType;
        ilkIndex = _ilkIndex;

        _nextStatus();
        _initMcdWrapper(collateralType, isETH);
        emit AgreementInitiated(borrower, collateralAmount, cdpDebtValue, duration, interestRate);

        _monitorRisky();
    }

    /**
     * @dev Approve the agreement. Only for contract owner (FraFactory)
     * @return Operation success
     */
    function approveAgreement() external onlyContractOwner hasStatus(Statuses.Pending) returns(bool _success) {
        _nextStatus();
        emit AgreementApproved();

        return true;
    }

    /**
     * @dev Match lender to the agreement.
     * @return Operation success
     */
    function matchAgreement() external hasStatus(Statuses.Open) returns(bool _success) {
        _nextStatus();
        expireDate = now.add(duration);
        lender = msg.sender;
        lastCheckTime = now;

        // transfer dai from lender to agreement & lock lender's dai to dsr
        _transferFromDai(msg.sender, address(this), cdpDebtValue);
        _lockDai(cdpDebtValue);

        if (isETH) {
            cdpId = _openLockETHAndDraw(collateralType, collateralAmount, cdpDebtValue);
        } else {
            cdpId = _openLockERC20AndDraw(collateralType, collateralAmount, cdpDebtValue, true);
        }
        uint drawnDai = _balanceDai(address(this));
        // due to the lack of preceision in mcd cdp contracts drawn dai can be less by 1 dai wei

        emit AgreementMatched(lender, expireDate, cdpId, collateralAmount, cdpDebtValue, drawnDai);
        _pushDaiAsset(borrower, cdpDebtValue < drawnDai ? cdpDebtValue : drawnDai);

        return true;
    }

    /**
     * @dev     Update Agreement state. Calls needed function according to the expireDate
     *          (terminates or liquidated or updates the agreement)
     * @return  Operation success
     */
    function updateAgreement() external onlyContractOwner hasStatus(Statuses.Active) returns(bool _success) {
        if (now > expireDate) {
            _closeAgreement(ClosedTypes.Ended);
            _updateAgreementState(true);
            return true;
        }
        if (!isCdpSafe(collateralType, cdpId)) {
            _closeAgreement(ClosedTypes.Liquidated);
            _updateAgreementState(true);
            return true;
        }
        _updateAgreementState(false);
        return true;
    }

    /**
     * @dev  Cancel agreement by borrower before it is matched, change status to the correspondant one, refund
     * @return  Operation success
     */
    function cancelAgreement() external onlyBorrower beforeStatus(Statuses.Active) returns(bool _success)  {
        _closeAgreement(ClosedTypes.Cancelled);
        //push to lenders internal wallet collateral locked in agreement
        _pushCollateralAsset(borrower, collateralAmount);
        return true;
    }

    /**
     * @dev  Reject agreement by admin or cron job before it is matched, change status to the correspondant one, refund
     * @return  Operation success
     */
    function rejectAgreement() external onlyContractOwner beforeStatus(Statuses.Active) returns(bool _success)  {
        _closeAgreement(ClosedTypes.Cancelled);
        //push to lenders internal wallet collateral locked in agreement
        _pushCollateralAsset(borrower, collateralAmount);
        return true;
    }

    /**
     * @dev  Block active agreement, change status to the correspondant one, refund
     * @return  Operation success
     */
    function blockAgreement() external hasStatus(Statuses.Active) onlyContractOwner returns(bool _success)  {
        _closeAgreement(ClosedTypes.Blocked);
        _refund();
        return true;
    }

    /**
     * @dev  Lock additional ether as collateral to agreement cdp contract
     * @param   _amount collateral amount for additional lock
     * @return  Operation success
     */
    function lockAdditionalCollateral(uint _amount) external payable onlyBorrower beforeStatus(Statuses.Closed) returns(bool _success)  {
        if (!isETH) {
            erc20TokenContract(collateralType).transferFrom(msg.sender, address(this), _amount);
        }
        if (isStatus(Statuses.Active)) {
            if (isETH) {
                require(msg.value == _amount, "Agreement: ether sent doesn\'t coinside with required");
                _lockETH(collateralType, cdpId, msg.value);
            } else {
                _lockERC20(collateralType, cdpId, _amount, true);
            }
        }
        collateralAmount = collateralAmount.add(_amount);
        emit AdditionalCollateralLocked(_amount);
        _monitorRisky();
        return true;
    }

    /**
     * @dev  Withdraw dai to user's external wallet
     * @param   _amount dai amount for withdrawal
     */
    function withdrawDai(uint _amount) external {
        _popDaiAsset(msg.sender, _amount);
        _transferDai(msg.sender, _amount);
    }

    /**
     * @dev  Withdraw collateral to user's (msg.sender) external wallet from internal wallet
     * @param   _amount collateral amount for withdrawal
     */
    function withdrawCollateral(uint _amount) external {
        _popCollateralAsset(msg.sender, _amount);
        if (isETH) {
            msg.sender.transfer(_amount);
        } else {
            _transferERC20(collateralType, msg.sender, _amount);
        }
    }

    /**
     * @dev     Withdraw accidentally locked ether in the contract, can be called only after agreement is closed and all assets are refunded
     *          Check the current balance is more than users ether assets, and withdraw the remaining ether
     * @param   _to address should be withdrawn to
     */
    function withdrawRemainingEth(address payable _to) external hasStatus(Statuses.Closed) onlyContractOwner {
        uint _remainingEth = isETH ?
            address(this).balance.sub(assets[borrower].collateral.add(assets[lender].collateral)) :
            address(this).balance;
        require(_remainingEth > 0, "Agreement: the remaining balance available for withdrawal is zero");
        _to.transfer(_remainingEth);
    }

    /**
     * @dev     Get agreement main info
     */
    function getInfo() external view returns(
        address _addr,
        uint _status,
        uint _closedType,
        uint _duration,
        address _borrower,
        address _lender,
        bytes32 _collateralType,
        bytes32 _ilkIndex,
        uint _collateralAmount,
        uint _debtValue,
        uint _interestRate, // per sec
        bool _isRisky
    ) {
        _addr = address(this);
        _status = uint(status);
        _closedType = uint(closedType);
        _duration = duration;
        _borrower = borrower;
        _lender = lender;
        _collateralType = collateralType;
        _ilkIndex = ilkIndex;
        _collateralAmount = collateralAmount;
        _debtValue = cdpDebtValue;
        _interestRate = interestRate;
        _isRisky = isRisky;
    }

    /**
     * @dev     Get user assets available for withdrawal
     * @param   _holder address of lender or borrower
     * @return  collateral amount
     * @return  dai amount
     */
    function getAssets(address _holder) public view returns(uint,uint) {
        return (assets[_holder].collateral, assets[_holder].dai);
    }

    /**
     * @dev     Check if agreement has appropriate status
     * @param   _status status should be checked with
     */
    function isStatus(Statuses _status) public view returns(bool) {
        return status == _status;
    }

    /**
     * @dev     Check if agreement has status before requested one
     * @param   _status check before status
     */
    function isBeforeStatus(Statuses _status) public view returns(bool) {
        return status < _status;
    }

    /**
     * @dev     Check if agreement is closed with appropriate type
     * @param   _type type should be checked with
     */
    function isClosedWithType(ClosedTypes _type) public view returns(bool) {
        return isStatus(Statuses.Closed) && (closedType == _type);
    }

    /**
     * @dev     Borrower debt according to FRA
     */
    function borrowerFraDebt() public view returns(uint) {
        return (delta < 0) ? uint(fromRay(-delta)) : 0;
    }

    /**
     * @dev     check whether pending or open agreement should be canceled automatically by cron
     * @param   _approveLimit approve limit secods
     * @param   _matchLimit match limit secods
     * @return  true if should be cancelled
     */
    function checkTimeToCancel(uint _approveLimit, uint _matchLimit) public view returns(bool){
        if ((isStatus(Statuses.Pending) && now > statusSnapshots[uint(Statuses.Pending)].add(_approveLimit)) ||
            (isStatus(Statuses.Open) && now > statusSnapshots[uint(Statuses.Open)].add(_matchLimit))
        ) {
            return true;
        }
    }

    /**
     * @dev     get collateralization ratio, if cdp is already opened - get cdp CR, if no - calculate according to agreement initial parameters
     * @return  collateralization ratio in RAY
     */
    function getCR() public view returns(uint) {
        return cdpId > 0 ? getCdpCR(collateralType, cdpId) : collateralAmount.mul(getPrice(collateralType)).div(cdpDebtValue);
    }

    /**
     * @dev     get collateralization ratio buffer (difference between current CR and minimal one)
     * @return  buffer percents
     */
    function getCRBuffer() public view returns(uint) {
        return getCR() <= getMCR(collateralType) ? 0 : getCR().sub(getMCR(collateralType)).mul(100).div(ONE);
    }

    /**
     * @dev     get address of Dai token contract
     * @return  dai address
     */
    function getDaiAddress() public view returns(address) {
        return mcdDaiAddr;
    }

    /**
    * @dev      Save timestamp for current status
    */
    function _doStatusSnapshot() internal {
        statusSnapshots[uint(status)] = now;
    }

    /**
     * @dev     Close agreement
     * @param   _closedType closing type
     * @return  Operation success
     */
    function _closeAgreement(ClosedTypes _closedType) internal returns(bool _success) {
        _switchStatusClosedWithType(_closedType);

        emit AgreementClosed(uint(_closedType), msg.sender);
        return true;
    }

    /**
     * @dev     Updates the state of Agreement
     * @param   _isLastUpdate true if the agreement is going to be terminated, false otherwise
     * @return  Operation success
     */
    function _updateAgreementState(bool _isLastUpdate) internal returns(bool _success) {
        // if it is last update take the time interval up to expireDate, otherwise up to current time
        uint timeInterval = (_isLastUpdate ? expireDate : now).sub(lastCheckTime);
        uint irDiff; 
        uint injectionAmount;
        uint drawnDai;
        uint currentDebt;
        int savingsDifference;
        uint dsr = getDsr();
        uint rp;
        // uint currDuty     = getIlkDuty(ilkIndex); // warn about change in pricing

        // calculate savings difference between dsr and fixed interest rate during time interval
        if(getDsr() > interestRate) {
            irDiff = ONE.add(dsr.sub(interestRate));
            rp = rpow(irDiff, timeInterval, ONE);
            savingsDifference = int(cdpDebtValue.mul( rp ));
            delta = delta.add(savingsDifference); // lender debt increases
        } else {
            irDiff = ONE.add((interestRate).sub(dsr));
            rp = rpow(irDiff, timeInterval, ONE);
            savingsDifference = int(cdpDebtValue.mul( rp ));
            delta = delta.sub(savingsDifference); // lender debt decreases
        }                
        
        feeAccum = feeAccum.add(cdpDebtValue.mul( rpow(Config(configAddr).acapFee(), timeInterval, ONE)));
    
        // check the current debt is above threshold
        currentDebt = uint(fromRay(delta < 0 ? -delta : delta));
        if (currentDebt >= (_isLastUpdate ? 1 : Config(configAddr).injectionThreshold())) {    
            if (delta < 0) {  // if delta < 0 - currentDebt is borrower's debt to lender
                drawnDai = _drawDaiToCdp(collateralType, cdpId, currentDebt);
                delta = delta.add(int(toRay(drawnDai)));
                drawnTotal = drawnTotal.add(drawnDai);
                if (drawnDai > 0) 
                    _pushDaiAsset(lender, drawnDai);
            } else {          // delta > 0 - currentDebt is lender's debt to borrower
                injectionAmount = _injectToCdpFromDsr(cdpId, currentDebt);
                delta = delta.sub(int(toRay(injectionAmount)));
                injectedTotal = injectedTotal.add(injectionAmount);
            }
        }        
        
        emit AgreementUpdated(savingsDifference, delta, getDsr(), timeInterval, drawnDai, injectionAmount);       
        
        uint daiFee = fromRay(feeAccum);
        if ( daiFee > Config(configAddr).injectionThreshold()) 
            {
                drawnDai = _drawDaiToCdp(collateralType, cdpId, daiFee);
                if (drawnDai > 0) 
                {   
                    _transferDai(Config(configAddr).acapAddr(), drawnDai );
                    feeAccum     = feeAccum.sub(drawnDai);
                    feePaidTotal = feePaidTotal.add(drawnDai); 
                }
            }   


        // for the next iteration, last debt value and time
        lastCheckTime = now;
        //(, cdpDebtValue) = getCdpInfo(ilkIndex, cdpId); // update new starting debt value for the next update

        // vr _monitorRisky();
        // if (_isLastUpdate)
        //    _refund();
        return true;
    }

    /**
     * @dev     Monitor and set up or set down risky marker
     */
    function _monitorRisky() internal {
        bool _isRisky = getCRBuffer() <= Config(configAddr).riskyMargin();
        if (isRisky != _isRisky) {
            isRisky = _isRisky;
            emit RiskyToggled(_isRisky);
        }
    }

    /**
     * @dev     Refund agreement, push dai to lender assets, transfer cdp ownership to borrower if debt is payed
     * @return  Operation success
     */
    function _refund() internal {
        
        uint resfee = uint(fromRay(feeAccum)); 
        _pushDaiAsset(lender, _unlockAllDai().sub(resfee));
        if ( resfee > 0)
        {
            _transferDai(Config(configAddr).acapAddr(), resfee );
            feePaidTotal = feePaidTotal.add(resfee);
        }
        _transferCdpOwnershipToProxy(cdpId, borrower);
        emit CdpOwnershipTransferred(borrower, cdpId);
    }

    /**
     * @dev     Serial status transition
     */
    function _nextStatus() internal {
        _switchStatus(Statuses(uint(status) + 1));
    }

    /**
    * @dev      switch to exact status
    * @param    _next status that should be switched to
    */
    function _switchStatus(Statuses _next) internal {
        status = _next;
        _doStatusSnapshot();
    }

    /**
    * @dev      switch status to closed with exact type
    * @param    _closedType closing type
    */
    function _switchStatusClosedWithType(ClosedTypes _closedType) internal {
        _switchStatus(Statuses.Closed);
        closedType = _closedType;
    }

    /**
     * @dev     Add collateral to user's internal wallet
     * @param   _holder user's address
     * @param   _amount collateral amount to push
     */
    function _pushCollateralAsset(address _holder, uint _amount) internal {
        assets[_holder].collateral = assets[_holder].collateral.add(_amount);
        emit AssetsCollateralPush(_holder, _amount, collateralType);
    }

    /**
     * @dev     Add dai to user's internal wallet
     * @param   _holder user's address
     * @param   _amount dai amount to push
     */
    function _pushDaiAsset(address _holder, uint _amount) internal {
        assets[_holder].dai = assets[_holder].dai.add(_amount);
        emit AssetsDaiPush(_holder, _amount);
    }

    /**
     * @dev     Take away collateral from user's internal wallet
     * @param   _holder user's address
     * @param   _amount collateral amount to pop
     */
    function _popCollateralAsset(address _holder, uint _amount) internal {
        assets[_holder].collateral = assets[_holder].collateral.sub(_amount);
        emit AssetsCollateralPop(_holder, _amount, collateralType);
    }

    /**
     * @dev     Take away dai from user's internal wallet
     * @param   _holder user's address
     * @param   _amount dai amount to pop
     */
    function _popDaiAsset(address _holder, uint _amount) internal {
        assets[_holder].dai = assets[_holder].dai.sub(_amount);
        emit AssetsDaiPop(_holder, _amount);
    }

    function() external payable {}
}