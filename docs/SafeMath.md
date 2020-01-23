# SafeMath (SafeMath.sol)

View Source: [contracts/helpers/SafeMath.sol](../contracts/helpers/SafeMath.sol)

**SafeMath**

Math operations with safety checks that throw on error

## Contract Members
**Constants & Variables**

```js
int256 internal constant INT256_MIN;
int256 internal constant INT256_MAX;

```

## Functions

- [mul(uint256 a, uint256 b)](#mul)
- [div(uint256 a, uint256 b)](#div)
- [sub(uint256 a, uint256 b)](#sub)
- [add(uint256 a, uint256 b)](#add)
- [mul(int256 a, int256 b)](#mul)
- [div(int256 a, int256 b)](#div)
- [sub(int256 a, int256 b)](#sub)
- [add(int256 a, int256 b)](#add)

### mul

Multiplies two numbers, throws on overflow.

```js
function mul(uint256 a, uint256 b) internal pure
returns(uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| a | uint256 |  | 
| b | uint256 |  | 

### div

Integer division of two numbers, truncating the quotient.

```js
function div(uint256 a, uint256 b) internal pure
returns(uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| a | uint256 |  | 
| b | uint256 |  | 

### sub

Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).

```js
function sub(uint256 a, uint256 b) internal pure
returns(uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| a | uint256 |  | 
| b | uint256 |  | 

### add

Adds two numbers, throws on overflow.

```js
function add(uint256 a, uint256 b) internal pure
returns(uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| a | uint256 |  | 
| b | uint256 |  | 

### mul

Multiplies two int numbers, throws on overflow.

```js
function mul(int256 a, int256 b) internal pure
returns(int256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| a | int256 |  | 
| b | int256 |  | 

### div

Division of two int numbers, truncating the quotient.

```js
function div(int256 a, int256 b) internal pure
returns(int256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| a | int256 |  | 
| b | int256 |  | 

### sub

Substracts two int numbers, throws on overflow (i.e. if subtrahend is greater than minuend).

```js
function sub(int256 a, int256 b) internal pure
returns(int256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| a | int256 |  | 
| b | int256 |  | 

### add

Adds two int numbers, throws on overflow.

```js
function add(int256 a, int256 b) internal pure
returns(int256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| a | int256 |  | 
| b | int256 |  | 

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
