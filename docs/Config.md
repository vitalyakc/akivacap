# Config for Agreement contract (Config.sol)

View Source: [contracts/config/Config.sol](../contracts/config/Config.sol)

**↗ Extends: [ClaimableBase](ClaimableBase.md)**
**↘ Derived Contracts: [ConfigMock](ConfigMock.md)**

**Config**

## Contract Members
**Constants & Variables**

```js
mapping(bytes32 => bool) public collateralsEnabled;
uint256 public approveLimit;
uint256 public matchLimit;
uint256 public injectionThreshold;
uint256 public minCollateralAmount;
uint256 public maxCollateralAmount;
uint256 public minDuration;
uint256 public maxDuration;
uint256 public riskyMargin;

```

## Functions

- [()](#)
- [setGeneral(uint256 _approveLimit, uint256 _matchLimit, uint256 _injectionThreshold, uint256 _minCollateralAmount, uint256 _maxCollateralAmount, uint256 _minDuration, uint256 _maxDuration, uint256 _riskyMargin)](#setgeneral)
- [setRiskyMargin(uint256 _riskyMargin)](#setriskymargin)
- [setApproveLimit(uint256 _approveLimit)](#setapprovelimit)
- [setMatchLimit(uint256 _matchLimit)](#setmatchlimit)
- [setInjectionThreshold(uint256 _injectionThreshold)](#setinjectionthreshold)
- [enableCollateral(bytes32 _ilk)](#enablecollateral)
- [disableCollateral(bytes32 _ilk)](#disablecollateral)
- [isCollateralEnabled(bytes32 _ilk)](#iscollateralenabled)

### 

Set default config

```js
function () public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### setGeneral

Set all config parameters

```js
function setGeneral(uint256 _approveLimit, uint256 _matchLimit, uint256 _injectionThreshold, uint256 _minCollateralAmount, uint256 _maxCollateralAmount, uint256 _minDuration, uint256 _maxDuration, uint256 _riskyMargin) public nonpayable onlyContractOwner 
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _approveLimit | uint256 |  | 
| _matchLimit | uint256 |  | 
| _injectionThreshold | uint256 |  | 
| _minCollateralAmount | uint256 |  | 
| _maxCollateralAmount | uint256 |  | 
| _minDuration | uint256 |  | 
| _maxDuration | uint256 |  | 
| _riskyMargin | uint256 |  | 

### setRiskyMargin

Set config parameter

```js
function setRiskyMargin(uint256 _riskyMargin) public nonpayable onlyContractOwner 
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _riskyMargin | uint256 |  | 

### setApproveLimit

Set config parameter

```js
function setApproveLimit(uint256 _approveLimit) public nonpayable onlyContractOwner 
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _approveLimit | uint256 |  | 

### setMatchLimit

Set config parameter

```js
function setMatchLimit(uint256 _matchLimit) public nonpayable onlyContractOwner 
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _matchLimit | uint256 |  | 

### setInjectionThreshold

Set config parameter

```js
function setInjectionThreshold(uint256 _injectionThreshold) public nonpayable onlyContractOwner 
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _injectionThreshold | uint256 |  | 

### enableCollateral

Enable colateral type

```js
function enableCollateral(bytes32 _ilk) public nonpayable onlyContractOwner 
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _ilk | bytes32 |  | 

### disableCollateral

Disable colateral type

```js
function disableCollateral(bytes32 _ilk) public nonpayable onlyContractOwner 
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _ilk | bytes32 |  | 

### isCollateralEnabled

Check if colateral is enabled

```js
function isCollateralEnabled(bytes32 _ilk) public view
returns(bool)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _ilk | bytes32 |  | 

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
