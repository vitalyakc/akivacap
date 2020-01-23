# LenderPoolMock.sol

View Source: [contracts/mocks/LenderPoolMock.sol](../contracts/mocks/LenderPoolMock.sol)

**↗ Extends: [LenderPool](LenderPool.md)**

**LenderPoolMock**

## Contract Members
**Constants & Variables**

```js
uint256 internal debtValue;
uint256 internal interestRate;
uint256 internal duration;
bool internal isStatusMock;
uint256 internal daiAsset;

```

## Functions

- [(address _targetAgreement, uint256 _minInterestRate, uint256 _minDuration, uint256 _maxDuration, uint256 _maxPendingPeriod, uint256 _minDai)](#)
- [setDaiTokenMock(address _daiTokenMock)](#setdaitokenmock)
- [setAgreementDebtValue(uint256 _debtValue)](#setagreementdebtvalue)
- [_getAgreementDebtValue()](#_getagreementdebtvalue)
- [setAgreementInterestRate(uint256 _interestRate)](#setagreementinterestrate)
- [_getAgreementInterestRate()](#_getagreementinterestrate)
- [setAgreementDuration(uint256 _duration)](#setagreementduration)
- [_getAgreementDuration()](#_getagreementduration)
- [setAgreementStatus(bool _status)](#setagreementstatus)
- [_isAgreementInStatus(enum IAgreement.Statuses )](#_isagreementinstatus)
- [_matchAgreement()](#_matchagreement)
- [setAgreementDaiAsset(uint256 _daiAsset)](#setagreementdaiasset)
- [_getAgreementAssets()](#_getagreementassets)
- [_withdrawDaiFromAgreement()](#_withdrawdaifromagreement)

### 

```js
function (address _targetAgreement, uint256 _minInterestRate, uint256 _minDuration, uint256 _maxDuration, uint256 _maxPendingPeriod, uint256 _minDai) public nonpayable LenderPool 
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

### setDaiTokenMock

```js
function setDaiTokenMock(address _daiTokenMock) public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _daiTokenMock | address |  | 

### setAgreementDebtValue

```js
function setAgreementDebtValue(uint256 _debtValue) public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _debtValue | uint256 |  | 

### _getAgreementDebtValue

⤾ overrides [LenderPool._getAgreementDebtValue](LenderPool.md#_getagreementdebtvalue)

```js
function _getAgreementDebtValue() internal view
returns(uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### setAgreementInterestRate

```js
function setAgreementInterestRate(uint256 _interestRate) public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _interestRate | uint256 |  | 

### _getAgreementInterestRate

⤾ overrides [LenderPool._getAgreementInterestRate](LenderPool.md#_getagreementinterestrate)

```js
function _getAgreementInterestRate() internal view
returns(uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### setAgreementDuration

```js
function setAgreementDuration(uint256 _duration) public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _duration | uint256 |  | 

### _getAgreementDuration

⤾ overrides [LenderPool._getAgreementDuration](LenderPool.md#_getagreementduration)

```js
function _getAgreementDuration() internal view
returns(uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### setAgreementStatus

```js
function setAgreementStatus(bool _status) public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _status | bool |  | 

### _isAgreementInStatus

⤾ overrides [LenderPool._isAgreementInStatus](LenderPool.md#_isagreementinstatus)

```js
function _isAgreementInStatus(enum IAgreement.Statuses ) internal view
returns(bool)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
|  | enum IAgreement.Statuses |  | 

### _matchAgreement

⤾ overrides [LenderPool._matchAgreement](LenderPool.md#_matchagreement)

```js
function _matchAgreement() internal nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### setAgreementDaiAsset

```js
function setAgreementDaiAsset(uint256 _daiAsset) public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _daiAsset | uint256 |  | 

### _getAgreementAssets

⤾ overrides [LenderPool._getAgreementAssets](LenderPool.md#_getagreementassets)

```js
function _getAgreementAssets() internal view
returns(uint256, uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### _withdrawDaiFromAgreement

⤾ overrides [LenderPool._withdrawDaiFromAgreement](LenderPool.md#_withdrawdaifromagreement)

```js
function _withdrawDaiFromAgreement() internal nonpayable
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
