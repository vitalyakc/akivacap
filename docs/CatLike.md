# Interfaces for maker dao mcd contracts (CatLike.sol)

View Source: [contracts/interfaces/IMcd.sol](../contracts/interfaces/IMcd.sol)

**CatLike**

## Structs
### Ilk

```js
struct Ilk {
 contract PipLike pip,
 uint256 mat
}
```

### Ilk

```js
struct Ilk {
 uint256 duty,
 uint256 rho
}
```

## Contract Members
**Constants & Variables**

```js
mapping(bytes32 => struct SpotterLike.Ilk) public ilks;
mapping(bytes32 => struct JugLike.Ilk) public ilks;
mapping(uint256 => address) public urns;
mapping(address => contract DSProxyLike) public proxies;

```

## Functions

- [dsr()](#dsr)
- [chi()](#chi)
- [pie(address )](#pie)
- [drip()](#drip)
- [join(uint256 )](#join)
- [exit(uint256 )](#exit)
- [ilks(bytes32 )](#ilks)
- [dai(address )](#dai)
- [urns(bytes32 , address )](#urns)
- [hope(address )](#hope)
- [move(address , address , uint256 )](#move)
- [drip(bytes32 ilk)](#drip)
- [read()](#read)
- [peek()](#peek)
- [ilks(bytes32 )](#ilks)
- [build()](#build)
- [build(address )](#build)
- [execute(bytes , bytes )](#execute)
- [execute(address , bytes )](#execute)
- [setOwner(address )](#setowner)

### dsr

```js
function dsr() public view
returns(uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### chi

```js
function chi() public view
returns(uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### pie

```js
function pie(address ) public view
returns(uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
|  | address |  | 

### drip

```js
function drip() public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### join

```js
function join(uint256 ) public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
|  | uint256 |  | 

### exit

```js
function exit(uint256 ) public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
|  | uint256 |  | 

### ilks

```js
function ilks(bytes32 ) public view
returns(uint256, uint256, uint256, uint256, uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
|  | bytes32 |  | 

### dai

```js
function dai(address ) public view
returns(uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
|  | address |  | 

### urns

```js
function urns(bytes32 , address ) public view
returns(uint256, uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
|  | bytes32 |  | 
|  | address |  | 

### hope

```js
function hope(address ) public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
|  | address |  | 

### move

```js
function move(address , address , uint256 ) public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
|  | address |  | 
|  | address |  | 
|  | uint256 |  | 

### drip

```js
function drip(bytes32 ilk) external nonpayable
returns(uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| ilk | bytes32 |  | 

### read

```js
function read() external view
returns(bytes32)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### peek

```js
function peek() external nonpayable
returns(bytes32, bool)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### ilks

```js
function ilks(bytes32 ) public view
returns(address, uint256, uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
|  | bytes32 |  | 

### build

```js
function build() public nonpayable
returns(address payable)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### build

```js
function build(address ) public nonpayable
returns(address payable)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
|  | address |  | 

### execute

```js
function execute(bytes , bytes ) public payable
returns(address, bytes)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
|  | bytes |  | 
|  | bytes |  | 

### execute

```js
function execute(address , bytes ) public payable
returns(bytes)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
|  | address |  | 
|  | bytes |  | 

### setOwner

```js
function setOwner(address ) public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
|  | address |  | 

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
