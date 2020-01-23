# Base Agreement contract (Agreement.sol)

View Source: [contracts/Agreement.sol](../contracts/Agreement.sol)

**↗ Extends: [IAgreement](IAgreement.md), [ClaimableIni](ClaimableIni.md), [McdWrapper](McdWrapper.md)**
**↘ Derived Contracts: [AgreementDeepMock](AgreementDeepMock.md), [AgreementMock](AgreementMock.md)**

**Agreement**

Contract will be deployed only once as logic(implementation), proxy will be deployed by FraFactory for each agreement as storage

## Structs
### Asset

```js
struct Asset {
 uint256 collateral,
 uint256 dai
}
```

## Contract Members
**Constants & Variables**

```js
//internal members
uint256 internal constant YEAR_SECS;

//public members
mapping(uint256 => uint256) public statusSnapshots;
mapping(address => struct Agreement.Asset) public assets;
enum IAgreement.Statuses public status;
enum IAgreement.ClosedTypes public closedType;
address public configAddr;
bool public isETH;
bool public isRisky;
uint256 public duration;
uint256 public expireDate;
address payable public borrower;
address payable public lender;
bytes32 public collateralType;
uint256 public collateralAmount;
uint256 public debtValue;
uint256 public interestRate;
uint256 public cdpId;
uint256 public lastCheckTime;
uint256 public drawnTotal;
uint256 public injectedTotal;
int256 public delta;

```

## Modifiers

- [onlyBorrower](#onlyborrower)
- [hasStatus](#hasstatus)
- [beforeStatus](#beforestatus)

### onlyBorrower

Grants access only to agreement's borrower

```js
modifier onlyBorrower() internal
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### hasStatus

Grants access only if agreement has appropriate status

```js
modifier hasStatus(enum IAgreement.Statuses _status) internal
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _status | enum IAgreement.Statuses | status should be checked with | 

### beforeStatus

Grants access only if agreement has status before requested one

```js
modifier beforeStatus(enum IAgreement.Statuses _status) internal
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _status | enum IAgreement.Statuses | check before status | 

## Functions

- [_doStatusSnapshot()](#_dostatussnapshot)
- [initAgreement(address payable _borrower, uint256 _collateralAmount, uint256 _debtValue, uint256 _duration, uint256 _interestRate, bytes32 _collateralType, bool _isETH, address _configAddr)](#initagreement)
- [approveAgreement()](#approveagreement)
- [matchAgreement()](#matchagreement)
- [updateAgreement()](#updateagreement)
- [cancelAgreement()](#cancelagreement)
- [rejectAgreement()](#rejectagreement)
- [blockAgreement()](#blockagreement)
- [lockAdditionalCollateral(uint256 _amount)](#lockadditionalcollateral)
- [withdrawDai(uint256 _amount)](#withdrawdai)
- [withdrawCollateral(uint256 _amount)](#withdrawcollateral)
- [withdrawRemainingEth(address payable _to)](#withdrawremainingeth)
- [getInfo()](#getinfo)
- [getAssets(address _holder)](#getassets)
- [isStatus(enum IAgreement.Statuses _status)](#isstatus)
- [isBeforeStatus(enum IAgreement.Statuses _status)](#isbeforestatus)
- [isClosedWithType(enum IAgreement.ClosedTypes _type)](#isclosedwithtype)
- [borrowerFraDebt()](#borrowerfradebt)
- [checkTimeToCancel(uint256 _approveLimit, uint256 _matchLimit)](#checktimetocancel)
- [getCR()](#getcr)
- [getCRBuffer()](#getcrbuffer)
- [getDaiAddress()](#getdaiaddress)
- [_closeAgreement(enum IAgreement.ClosedTypes _closedType)](#_closeagreement)
- [_updateAgreementState(bool _isLastUpdate)](#_updateagreementstate)
- [_monitorRisky()](#_monitorrisky)
- [_refund()](#_refund)
- [_nextStatus()](#_nextstatus)
- [_switchStatus(enum IAgreement.Statuses _next)](#_switchstatus)
- [_switchStatusClosedWithType(enum IAgreement.ClosedTypes _closedType)](#_switchstatusclosedwithtype)
- [_pushCollateralAsset(address _holder, uint256 _amount)](#_pushcollateralasset)
- [_pushDaiAsset(address _holder, uint256 _amount)](#_pushdaiasset)
- [_popCollateralAsset(address _holder, uint256 _amount)](#_popcollateralasset)
- [_popDaiAsset(address _holder, uint256 _amount)](#_popdaiasset)
- [()](#)

### _doStatusSnapshot

Save timestamp for current status

```js
function _doStatusSnapshot() internal nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### initAgreement

⤾ overrides [IAgreement.initAgreement](IAgreement.md#initagreement)

⤿ Overridden Implementation(s): [AgreementDeepMock.initAgreement](AgreementDeepMock.md#initagreement),[AgreementMock.initAgreement](AgreementMock.md#initagreement)

Initialize new agreement

```js
function initAgreement(address payable _borrower, uint256 _collateralAmount, uint256 _debtValue, uint256 _duration, uint256 _interestRate, bytes32 _collateralType, bool _isETH, address _configAddr) public payable initializer 
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _borrower | address payable | borrower address | 
| _collateralAmount | uint256 | value of borrower's collateral amount put into the contract as collateral or approved to transferFrom | 
| _debtValue | uint256 | value of debt | 
| _duration | uint256 | number of seconds which agreement should be terminated after | 
| _interestRate | uint256 | percent of interest rate, should be passed like RAY | 
| _collateralType | bytes32 | type of collateral, should be passed as bytes32 | 
| _isETH | bool | true if ether and false if erc-20 token | 
| _configAddr | address | config contract address | 

### approveAgreement

⤾ overrides [IAgreement.approveAgreement](IAgreement.md#approveagreement)

Approve the agreement. Only for contract owner (FraFactory)

```js
function approveAgreement() external nonpayable onlyContractOwner hasStatus 
returns(_success bool)
```

**Returns**

Operation success

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### matchAgreement

⤾ overrides [IAgreement.matchAgreement](IAgreement.md#matchagreement)

Match lender to the agreement.

```js
function matchAgreement() external nonpayable hasStatus 
returns(_success bool)
```

**Returns**

Operation success

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### updateAgreement

⤾ overrides [IAgreement.updateAgreement](IAgreement.md#updateagreement)

Update agreement state

```js
function updateAgreement() external nonpayable onlyContractOwner hasStatus 
returns(_success bool)
```

**Returns**

Operation success

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### cancelAgreement

⤾ overrides [IAgreement.cancelAgreement](IAgreement.md#cancelagreement)

Cancel agreement by borrower before it is matched, change status to the correspondant one, refund

```js
function cancelAgreement() external nonpayable onlyBorrower beforeStatus 
returns(_success bool)
```

**Returns**

Operation success

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### rejectAgreement

⤾ overrides [IAgreement.rejectAgreement](IAgreement.md#rejectagreement)

Reject agreement by admin or cron job before it is matched, change status to the correspondant one, refund

```js
function rejectAgreement() external nonpayable onlyContractOwner beforeStatus 
returns(_success bool)
```

**Returns**

Operation success

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### blockAgreement

⤾ overrides [IAgreement.blockAgreement](IAgreement.md#blockagreement)

Block active agreement, change status to the correspondant one, refund

```js
function blockAgreement() external nonpayable hasStatus onlyContractOwner 
returns(_success bool)
```

**Returns**

Operation success

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### lockAdditionalCollateral

Lock additional ether as collateral to agreement cdp contract

```js
function lockAdditionalCollateral(uint256 _amount) external payable onlyBorrower beforeStatus 
returns(_success bool)
```

**Returns**

Operation success

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _amount | uint256 |  | 

### withdrawDai

⤾ overrides [IAgreement.withdrawDai](IAgreement.md#withdrawdai)

withdraw dai to user's external wallet

```js
function withdrawDai(uint256 _amount) external nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _amount | uint256 | dai amount for withdrawal | 

### withdrawCollateral

withdraw collateral to user's (msg.sender) external wallet from internal wallet

```js
function withdrawCollateral(uint256 _amount) external nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _amount | uint256 | collateral amount for withdrawal | 

### withdrawRemainingEth

Withdraw accidentally locked ether in the contract, can be called only after agreement is closed and all assets are refunded

```js
function withdrawRemainingEth(address payable _to) external nonpayable hasStatus onlyContractOwner 
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _to | address payable | address should be withdrawn to | 

### getInfo

⤾ overrides [IAgreement.getInfo](IAgreement.md#getinfo)

Get agreement main info

```js
function getInfo() external view
returns(_addr address, _status uint256, _closedType uint256, _duration uint256, _borrower address, _lender address, _collateralType bytes32, _collateralAmount uint256, _debtValue uint256, _interestRate uint256, _isRisky bool)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### getAssets

⤾ overrides [IAgreement.getAssets](IAgreement.md#getassets)

Get user assets available for withdrawal

```js
function getAssets(address _holder) public view
returns(uint256, uint256)
```

**Returns**

collateral amount

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _holder | address | address of lender or borrower | 

### isStatus

⤾ overrides [IAgreement.isStatus](IAgreement.md#isstatus)

Check if agreement has appropriate status

```js
function isStatus(enum IAgreement.Statuses _status) public view
returns(bool)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _status | enum IAgreement.Statuses | status should be checked with | 

### isBeforeStatus

⤾ overrides [IAgreement.isBeforeStatus](IAgreement.md#isbeforestatus)

Check if agreement has status before requested one

```js
function isBeforeStatus(enum IAgreement.Statuses _status) public view
returns(bool)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _status | enum IAgreement.Statuses | check before status | 

### isClosedWithType

⤾ overrides [IAgreement.isClosedWithType](IAgreement.md#isclosedwithtype)

Check if agreement is closed with appropriate type

```js
function isClosedWithType(enum IAgreement.ClosedTypes _type) public view
returns(bool)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _type | enum IAgreement.ClosedTypes | type should be checked with | 

### borrowerFraDebt

Borrower debt according to FRA

```js
function borrowerFraDebt() public view
returns(uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### checkTimeToCancel

⤾ overrides [IAgreement.checkTimeToCancel](IAgreement.md#checktimetocancel)

check whether pending or open agreement should be canceled automatically by cron

```js
function checkTimeToCancel(uint256 _approveLimit, uint256 _matchLimit) public view
returns(bool)
```

**Returns**

true if should be cancelled

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _approveLimit | uint256 | approve limit secods | 
| _matchLimit | uint256 | match limit secods | 

### getCR

get collateralization ratio, if cdp is already opened - get cdp CR, if no - calculate according to agreement initial parameters

```js
function getCR() public view
returns(uint256)
```

**Returns**

collateralization ratio in RAY

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### getCRBuffer

⤿ Overridden Implementation(s): [AgreementDeepMock.getCRBuffer](AgreementDeepMock.md#getcrbuffer),[AgreementMock.getCRBuffer](AgreementMock.md#getcrbuffer)

get collateralization ratio buffer (difference between current CR and minimal one)

```js
function getCRBuffer() public view
returns(uint256)
```

**Returns**

buffer percents

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### getDaiAddress

⤾ overrides [IAgreement.getDaiAddress](IAgreement.md#getdaiaddress)

get address of Dai token contract

```js
function getDaiAddress() public view
returns(address)
```

**Returns**

dai address

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### _closeAgreement

Close agreement

```js
function _closeAgreement(enum IAgreement.ClosedTypes _closedType) internal nonpayable
returns(_success bool)
```

**Returns**

Operation success

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _closedType | enum IAgreement.ClosedTypes |  | 

### _updateAgreementState

Updates the state of Agreement

```js
function _updateAgreementState(bool _isLastUpdate) public nonpayable
returns(_success bool)
```

**Returns**

Operation success

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _isLastUpdate | bool | true if the agreement is going to be terminated, false otherwise | 

### _monitorRisky

Monitor and set up or set down risky marker

```js
function _monitorRisky() internal nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### _refund

Refund agreement, push dai to lender assets, transfer cdp ownership to borrower if debt is payed

```js
function _refund() internal nonpayable
```

**Returns**

Operation success

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### _nextStatus

Serial status transition

```js
function _nextStatus() internal nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### _switchStatus

switch to exact status

```js
function _switchStatus(enum IAgreement.Statuses _next) internal nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _next | enum IAgreement.Statuses | status that should be switched to | 

### _switchStatusClosedWithType

switch status to closed with exact type

```js
function _switchStatusClosedWithType(enum IAgreement.ClosedTypes _closedType) internal nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _closedType | enum IAgreement.ClosedTypes | closing type | 

### _pushCollateralAsset

Add collateral to user's internal wallet

```js
function _pushCollateralAsset(address _holder, uint256 _amount) internal nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _holder | address | user's address | 
| _amount | uint256 | collateral amount to push | 

### _pushDaiAsset

Add dai to user's internal wallet

```js
function _pushDaiAsset(address _holder, uint256 _amount) internal nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _holder | address | user's address | 
| _amount | uint256 | dai amount to push | 

### _popCollateralAsset

Take away collateral from user's internal wallet

```js
function _popCollateralAsset(address _holder, uint256 _amount) internal nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _holder | address | user's address | 
| _amount | uint256 | collateral amount to pop | 

### _popDaiAsset

Take away dai from user's internal wallet

```js
function _popDaiAsset(address _holder, uint256 _amount) internal nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _holder | address | user's address | 
| _amount | uint256 | dai amount to pop | 

### 

```js
function () external payable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

## Contracts

* [Administrable](Administrable.md)
* [Agreement](Agreement.md)
* [AgreementDeepMock](AgreementDeepMock.md)
* [AgreementMock](AgreementMock.md)
* [BaseUpgradeabilityProxy](BaseUpgradeabilityProxy.md)
* [CatLike](CatLike.md)
* [Claimable](Claimable.md)
* [ClaimableBase](ClaimableBase.md)
* [ClaimableIni](ClaimableIni.md)
* [Config](Config.md)
* [ConfigMock](ConfigMock.md)
* [Context](Context.md)
* [DSProxyLike](DSProxyLike.md)
* [FraFactory](FraFactory.md)
* [FraFactoryI](FraFactoryI.md)
* [FraQueries](FraQueries.md)
* [IAgreement](IAgreement.md)
* [IERC20](IERC20.md)
* [Initializable](Initializable.md)
* [JugLike](JugLike.md)
* [LenderPool](LenderPool.md)
* [LenderPoolMock](LenderPoolMock.md)
* [ManagerLike](ManagerLike.md)
* [McdAddressesR17](McdAddressesR17.md)
* [McdWrapper](McdWrapper.md)
* [McdWrapperMock](McdWrapperMock.md)
* [Migrations](Migrations.md)
* [Ownable](Ownable.md)
* [PipLike](PipLike.md)
* [PotLike](PotLike.md)
* [Proxy](Proxy.md)
* [ProxyRegistryLike](ProxyRegistryLike.md)
* [RaySupport](RaySupport.md)
* [SafeMath](SafeMath.md)
* [SimpleErc20Token](SimpleErc20Token.md)
* [SpotterLike](SpotterLike.md)
* [UpgradeabilityProxy](UpgradeabilityProxy.md)
* [VatLike](VatLike.md)
* [ZOSLibAddress](ZOSLibAddress.md)
