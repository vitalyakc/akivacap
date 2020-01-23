# RaySupport contract for ray (10^27) preceision calculations (RaySupport.sol)

View Source: [contracts/helpers/RaySupport.sol](../contracts/helpers/RaySupport.sol)

**↘ Derived Contracts: [McdWrapper](McdWrapper.md)**

**RaySupport**

## Contract Members
**Constants & Variables**

```js
uint256 public constant ONE;
uint256 public constant HUNDRED;

```

## Functions

- [toRay(uint256 _val)](#toray)
- [fromRay(uint256 _val)](#fromray)
- [toRay(int256 _val)](#toray)
- [fromRay(int256 _val)](#fromray)
- [rpow(uint256 x, uint256 n, uint256 base)](#rpow)

### toRay

Convert uint value to Ray format

```js
function toRay(uint256 _val) public pure
returns(uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _val | uint256 |  | 

### fromRay

Convert uint value from Ray format

```js
function fromRay(uint256 _val) public pure
returns(uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _val | uint256 |  | 

### toRay

Convert int value to Ray format

```js
function toRay(int256 _val) public pure
returns(int256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _val | int256 |  | 

### fromRay

Convert int value from Ray format

```js
function fromRay(int256 _val) public pure
returns(int256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _val | int256 |  | 

### rpow

Calculate x pow n by base

```js
function rpow(uint256 x, uint256 n, uint256 base) public pure
returns(z uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| x | uint256 |  | 
| n | uint256 |  | 
| base | uint256 |  | 

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
