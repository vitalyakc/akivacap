# Pool contract for lenders (LenderPool.sol)

View Source: [contracts/pool/LenderPool.sol](../contracts/pool/LenderPool.sol)

**↗ Extends: [Administrable](Administrable.md)**
**↘ Derived Contracts: [LenderPoolMock](LenderPoolMock.md)**

**LenderPool**

**Enums**
### Statuses

```js
enum Statuses {
 Pending,
 Matched,
 Closed
}
```

## Contract Members
**Constants & Variables**

```js
enum LenderPool.Statuses public status;
address public targetAgreement;
uint256 public daiGoal;
uint256 public daiTotal;
uint256 public daiWithSavings;
uint256 public interestRate;
uint256 public duration;
uint256 public minDai;
uint256 public pendingExpireDate;
uint256 public minInterestRate;
uint256 public minDuration;
uint256 public maxDuration;
mapping(address => uint256) public balanceOf;
address public daiToken;

```

**Events**

```js
event MatchedAgreement(address  targetAgreement);
event RefundedFromAgreement(address  targetAgreement, uint256  daiWithSavings);
event TargetAgreementUpdated(address  targetAgreement, uint256  daiGoal, uint256  interestRate, uint256  duration);
event Deposited(address  pooler, uint256  amount);
event Withdrawn(address  caller, address  pooler, uint256  amount, uint256  amountWithSavings);
event AgreementRestrictionsUpdated(uint256  minInterestRate, uint256  minDuration, uint256  maxDuration);
event PoolRestrictionsUpdated(uint256  pendingExpireDate, uint256  minDai);
event StatusUpdated(uint256  next);
```

## Modifiers

- [onlyStatus](#onlystatus)

### onlyStatus

Grants access only if pool has appropriate status

```js
modifier onlyStatus(enum LenderPool.Statuses _status) internal
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _status | enum LenderPool.Statuses |  | 

## Functions

- [(address _targetAgreement, uint256 _minInterestRate, uint256 _minDuration, uint256 _maxDuration, uint256 _maxPendingPeriod, uint256 _minDai)](#)
- [setTargetAgreement(address _addr)](#settargetagreement)
- [deposit(uint256 _amount)](#deposit)
- [withdraw()](#withdraw)
- [withdrawTo(address _to, uint256 _amount)](#withdrawto)
- [matchAgreement()](#matchagreement)
- [refundFromAgreement()](#refundfromagreement)
- [isStatus(enum LenderPool.Statuses _status)](#isstatus)
- [availableForWithdrawal(address _pooler)](#availableforwithdrawal)
- [_setAgreement(address _addr)](#_setagreement)
- [_deposit(address _pooler, uint256 _amount)](#_deposit)
- [_withdraw(address _pooler, uint256 _amount, uint256 _amountWithSavings)](#_withdraw)
- [_setAgreementRestrictions(uint256 _minInterestRate, uint256 _minDuration, uint256 _maxDuration)](#_setagreementrestrictions)
- [_setPoolRestrictions(uint256 _maxPendingPeriod, uint256 _minDai)](#_setpoolrestrictions)
- [_switchStatus(enum LenderPool.Statuses _next)](#_switchstatus)
- [_matchAgreement()](#_matchagreement)
- [_withdrawDaiFromAgreement()](#_withdrawdaifromagreement)
- [_daiTokenApprove(address _agreement, uint256 _amount)](#_daitokenapprove)
- [_daiTokenTransferFrom(address _pooler, address _to, uint256 _amount)](#_daitokentransferfrom)
- [_daiTokenTransfer(address _pooler, uint256 _amount)](#_daitokentransfer)
- [_getAgreementDebtValue()](#_getagreementdebtvalue)
- [_getAgreementInterestRate()](#_getagreementinterestrate)
- [_getAgreementDuration()](#_getagreementduration)
- [_isAgreementInStatus(enum IAgreement.Statuses _status)](#_isagreementinstatus)
- [_getAgreementAssets()](#_getagreementassets)

### 

Constructor, set main restrictions, set target agreement

```js
function (address _targetAgreement, uint256 _minInterestRate, uint256 _minDuration, uint256 _maxDuration, uint256 _maxPendingPeriod, uint256 _minDai) public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _targetAgreement | address |  | 
| _minInterestRate | uint256 |  | 
| _minDuration | uint256 |  | 
| _maxDuration | uint256 |  | 
| _maxPendingPeriod | uint256 |  | 
| _minDai | uint256 |  | 

### setTargetAgreement

Set target agreement address and check for restrictions of target agreement

```js
function setTargetAgreement(address _addr) public nonpayable onlyAdmin 
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _addr | address |  | 

### deposit

Deposit dai tokens to pool
         Transfer from pooler's account dai tokens to pool contract. Pooler should approve the amount to this contract beforehand

```js
function deposit(uint256 _amount) public nonpayable onlyStatus 
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _amount | uint256 |  | 

### withdraw

Withdraw own dai tokens by pooler

```js
function withdraw() public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### withdrawTo

Function is aimed to adjust the total dai, deposited to contract, with the goal
         Admin can refund some amount of dai tokens to pooler, but no more than pooler's balance
         can be called only when pending

```js
function withdrawTo(address _to, uint256 _amount) public nonpayable onlyAdmin onlyStatus 
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _to | address |  | 
| _amount | uint256 |  | 

### matchAgreement

Do match with target agreement
         Pool status becomes Matched

```js
function matchAgreement() public nonpayable onlyAdmin onlyStatus 
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### refundFromAgreement

Refund dai from target agreement after it is closed (terminated, liquidated, cancelled, blocked)
         Pool status becomes Closed

```js
function refundFromAgreement() public nonpayable onlyAdmin onlyStatus 
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### isStatus

Check if pool has appropriate status

```js
function isStatus(enum LenderPool.Statuses _status) public view
returns(bool)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _status | enum LenderPool.Statuses |  | 

### availableForWithdrawal

Calculate the amount of dai available for withdrawal for exact pooler now
         if pool has Closed status the share is calculated according to dai refunded with savings from agreement
         if pool has Depositing status but deposit time is expired - the share is equal to pooler's balance (deposited amount)

```js
function availableForWithdrawal(address _pooler) public view
returns(share uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _pooler | address |  | 

### _setAgreement

Set target agreement address

```js
function _setAgreement(address _addr) internal nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _addr | address |  | 

### _deposit

Deposit, change depositer (pooler) balance and total deposited dai
         Transfer from pooler's account dai tokens to pool contract. Pooler should approve the amount to this contract beforehand

```js
function _deposit(address _pooler, uint256 _amount) internal nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _pooler | address |  | 
| _amount | uint256 |  | 

### _withdraw

Decrease dai total balance and transfer dai tokens to pooler

```js
function _withdraw(address _pooler, uint256 _amount, uint256 _amountWithSavings) internal nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _pooler | address |  | 
| _amount | uint256 |  | 
| _amountWithSavings | uint256 |  | 

### _setAgreementRestrictions

Set restrictions to main parameters of target agreement, in irder to prevent match with unprofitable agreement

```js
function _setAgreementRestrictions(uint256 _minInterestRate, uint256 _minDuration, uint256 _maxDuration) internal nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _minInterestRate | uint256 |  | 
| _minDuration | uint256 |  | 
| _maxDuration | uint256 |  | 

### _setPoolRestrictions

Set restrictions to pool

```js
function _setPoolRestrictions(uint256 _maxPendingPeriod, uint256 _minDai) internal nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _maxPendingPeriod | uint256 |  | 
| _minDai | uint256 |  | 

### _switchStatus

Switch to exact status

```js
function _switchStatus(enum LenderPool.Statuses _next) internal nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _next | enum LenderPool.Statuses |  | 

### _matchAgreement

⤿ Overridden Implementation(s): [LenderPoolMock._matchAgreement](LenderPoolMock.md#_matchagreement)

Do match with agreement

```js
function _matchAgreement() internal nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### _withdrawDaiFromAgreement

⤿ Overridden Implementation(s): [LenderPoolMock._withdrawDaiFromAgreement](LenderPoolMock.md#_withdrawdaifromagreement)

Withdraw all dai from Agreement

```js
function _withdrawDaiFromAgreement() internal nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### _daiTokenApprove

Approve dai to agreement

```js
function _daiTokenApprove(address _agreement, uint256 _amount) internal nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _agreement | address |  | 
| _amount | uint256 |  | 

### _daiTokenTransferFrom

Transfer dai from pooler to pool

```js
function _daiTokenTransferFrom(address _pooler, address _to, uint256 _amount) internal nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _pooler | address |  | 
| _to | address |  | 
| _amount | uint256 |  | 

### _daiTokenTransfer

Transfer dai to pooler

```js
function _daiTokenTransfer(address _pooler, uint256 _amount) internal nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _pooler | address |  | 
| _amount | uint256 |  | 

### _getAgreementDebtValue

⤿ Overridden Implementation(s): [LenderPoolMock._getAgreementDebtValue](LenderPoolMock.md#_getagreementdebtvalue)

Get Agreement debt dai amount

```js
function _getAgreementDebtValue() internal view
returns(uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### _getAgreementInterestRate

⤿ Overridden Implementation(s): [LenderPoolMock._getAgreementInterestRate](LenderPoolMock.md#_getagreementinterestrate)

Get Agreement interest rate

```js
function _getAgreementInterestRate() internal view
returns(uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### _getAgreementDuration

⤿ Overridden Implementation(s): [LenderPoolMock._getAgreementDuration](LenderPoolMock.md#_getagreementduration)

Get Agreement duration

```js
function _getAgreementDuration() internal view
returns(uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### _isAgreementInStatus

⤿ Overridden Implementation(s): [LenderPoolMock._isAgreementInStatus](LenderPoolMock.md#_isagreementinstatus)

Check agreement status

```js
function _isAgreementInStatus(enum IAgreement.Statuses _status) internal view
returns(bool)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _status | enum IAgreement.Statuses |  | 

### _getAgreementAssets

⤿ Overridden Implementation(s): [LenderPoolMock._getAgreementAssets](LenderPoolMock.md#_getagreementassets)

Get Agreement assets

```js
function _getAgreementAssets() internal view
returns(uint256, uint256)
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
