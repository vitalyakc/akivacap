# Interface for Agreement contract (IAgreement.sol)

View Source: [contracts/interfaces/IAgreement.sol](../contracts/interfaces/IAgreement.sol)

**↘ Derived Contracts: [Agreement](Agreement.md)**

**IAgreement**

**Enums**
### Statuses

```js
enum Statuses {
 All,
 Pending,
 Open,
 Active,
 Closed
}
```

### ClosedTypes

```js
enum ClosedTypes {
 Ended,
 Liquidated,
 Blocked,
 Cancelled
}
```

**Events**

```js
event AgreementInitiated(address  _borrower, uint256  _collateralValue, uint256  _debtValue, uint256  _expireDate, uint256  _interestRate);
event AgreementApproved();
event AgreementMatched(address  _lender, uint256  _expireDate, uint256  _cdpId, uint256  _collateralAmount, uint256  _debtValue, uint256  _drawnDai);
event AgreementUpdated(int256  _savingsDifference, int256  _delta, uint256  _currentDsrAnnual, uint256  _timeInterval, uint256  _drawnDai, uint256  _injectionAmount);
event AgreementClosed(uint256  _closedType, address  _user);
event AssetsCollateralPush(address  _holder, uint256  _amount, bytes32  _collateralType);
event AssetsCollateralPop(address  _holder, uint256  _amount, bytes32  _collateralType);
event AssetsDaiPush(address  _holder, uint256  _amount);
event AssetsDaiPop(address  _holder, uint256  _amount);
event CdpOwnershipTransferred(address  _borrower, uint256  _cdpId);
event AdditionalCollateralLocked(uint256  _amount);
event RiskyToggled(bool  _isRisky);
```

## Functions

- [initAgreement(address payable , uint256 , uint256 , uint256 , uint256 , bytes32 , bool , address )](#initagreement)
- [transferOwnership(address )](#transferownership)
- [claimOwnership()](#claimownership)
- [approveAgreement()](#approveagreement)
- [updateAgreement()](#updateagreement)
- [cancelAgreement()](#cancelagreement)
- [rejectAgreement()](#rejectagreement)
- [blockAgreement()](#blockagreement)
- [matchAgreement()](#matchagreement)
- [interestRate()](#interestrate)
- [duration()](#duration)
- [debtValue()](#debtvalue)
- [status()](#status)
- [lender()](#lender)
- [borrower()](#borrower)
- [collateralType()](#collateraltype)
- [isStatus(enum IAgreement.Statuses )](#isstatus)
- [isBeforeStatus(enum IAgreement.Statuses )](#isbeforestatus)
- [isClosedWithType(enum IAgreement.ClosedTypes )](#isclosedwithtype)
- [checkTimeToCancel(uint256 , uint256 )](#checktimetocancel)
- [cdpId()](#cdpid)
- [erc20TokenContract(bytes32 )](#erc20tokencontract)
- [getAssets(address )](#getassets)
- [withdrawDai(uint256 )](#withdrawdai)
- [getDaiAddress()](#getdaiaddress)
- [getInfo()](#getinfo)

### initAgreement

⤿ Overridden Implementation(s): [Agreement.initAgreement](Agreement.md#initagreement),[AgreementDeepMock.initAgreement](AgreementDeepMock.md#initagreement),[AgreementMock.initAgreement](AgreementMock.md#initagreement)

```js
function initAgreement(address payable , uint256 , uint256 , uint256 , uint256 , bytes32 , bool , address ) external payable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
|  | address payable |  | 
|  | uint256 |  | 
|  | uint256 |  | 
|  | uint256 |  | 
|  | uint256 |  | 
|  | bytes32 |  | 
|  | bool |  | 
|  | address |  | 

### transferOwnership

⤿ Overridden Implementation(s): [Claimable.transferOwnership](Claimable.md#transferownership),[Ownable.transferOwnership](Ownable.md#transferownership)

```js
function transferOwnership(address ) external nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
|  | address |  | 

### claimOwnership

⤿ Overridden Implementation(s): [Claimable.claimOwnership](Claimable.md#claimownership),[Ownable.claimOwnership](Ownable.md#claimownership)

```js
function claimOwnership() external nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### approveAgreement

⤿ Overridden Implementation(s): [Agreement.approveAgreement](Agreement.md#approveagreement)

```js
function approveAgreement() external nonpayable
returns(bool)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### updateAgreement

⤿ Overridden Implementation(s): [Agreement.updateAgreement](Agreement.md#updateagreement)

```js
function updateAgreement() external nonpayable
returns(bool)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### cancelAgreement

⤿ Overridden Implementation(s): [Agreement.cancelAgreement](Agreement.md#cancelagreement)

```js
function cancelAgreement() external nonpayable
returns(bool)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### rejectAgreement

⤿ Overridden Implementation(s): [Agreement.rejectAgreement](Agreement.md#rejectagreement)

```js
function rejectAgreement() external nonpayable
returns(bool)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### blockAgreement

⤿ Overridden Implementation(s): [Agreement.blockAgreement](Agreement.md#blockagreement)

```js
function blockAgreement() external nonpayable
returns(bool)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### matchAgreement

⤿ Overridden Implementation(s): [Agreement.matchAgreement](Agreement.md#matchagreement)

```js
function matchAgreement() external nonpayable
returns(bool)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### interestRate

```js
function interestRate() external view
returns(uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### duration

```js
function duration() external view
returns(uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### debtValue

```js
function debtValue() external view
returns(uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### status

```js
function status() external view
returns(uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### lender

```js
function lender() external view
returns(address)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### borrower

```js
function borrower() external view
returns(address)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### collateralType

```js
function collateralType() external view
returns(bytes32)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### isStatus

⤿ Overridden Implementation(s): [Agreement.isStatus](Agreement.md#isstatus)

```js
function isStatus(enum IAgreement.Statuses ) external view
returns(bool)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
|  | enum IAgreement.Statuses |  | 

### isBeforeStatus

⤿ Overridden Implementation(s): [Agreement.isBeforeStatus](Agreement.md#isbeforestatus)

```js
function isBeforeStatus(enum IAgreement.Statuses ) external view
returns(bool)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
|  | enum IAgreement.Statuses |  | 

### isClosedWithType

⤿ Overridden Implementation(s): [Agreement.isClosedWithType](Agreement.md#isclosedwithtype)

```js
function isClosedWithType(enum IAgreement.ClosedTypes ) external view
returns(bool)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
|  | enum IAgreement.ClosedTypes |  | 

### checkTimeToCancel

⤿ Overridden Implementation(s): [Agreement.checkTimeToCancel](Agreement.md#checktimetocancel)

```js
function checkTimeToCancel(uint256 , uint256 ) external view
returns(bool)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
|  | uint256 |  | 
|  | uint256 |  | 

### cdpId

```js
function cdpId() external view
returns(uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### erc20TokenContract

⤿ Overridden Implementation(s): [AgreementDeepMock.erc20TokenContract](AgreementDeepMock.md#erc20tokencontract),[AgreementMock.erc20TokenContract](AgreementMock.md#erc20tokencontract),[McdWrapper.erc20TokenContract](McdWrapper.md#erc20tokencontract)

```js
function erc20TokenContract(bytes32 ) external view
returns(contract IERC20)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
|  | bytes32 |  | 

### getAssets

⤿ Overridden Implementation(s): [Agreement.getAssets](Agreement.md#getassets)

```js
function getAssets(address ) external view
returns(uint256, uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
|  | address |  | 

### withdrawDai

⤿ Overridden Implementation(s): [Agreement.withdrawDai](Agreement.md#withdrawdai)

```js
function withdrawDai(uint256 ) external nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
|  | uint256 |  | 

### getDaiAddress

⤿ Overridden Implementation(s): [Agreement.getDaiAddress](Agreement.md#getdaiaddress)

```js
function getDaiAddress() external view
returns(address)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### getInfo

⤿ Overridden Implementation(s): [Agreement.getInfo](Agreement.md#getinfo)

```js
function getInfo() external view
returns(address, uint256, uint256, uint256, address, address, bytes32, uint256, uint256, uint256, bool)
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
