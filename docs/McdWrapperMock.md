# McdWrapperMock.sol

View Source: [contracts/mocks/McdWrapperMock.sol](../contracts/mocks/McdWrapperMock.sol)

**↗ Extends: [McdWrapper](McdWrapper.md)**

**McdWrapperMock**

## Contract Members
**Constants & Variables**

```js
uint256 public cdpId;

```

## Functions

- [initMcdWrapper(bytes32 ilk, bool isEther)](#initmcdwrapper)
- [setOwnerProxy(address newOwner)](#setownerproxy)
- [openLockETHAndDraw(bytes32 ilk, uint256 wadD, uint256 wadC)](#openlockethanddraw)
- [openLockERC20AndDraw(bytes32 ilk, uint256 wadD, uint256 wadC, bool transferFrom)](#openlockerc20anddraw)
- [injectToCdpFromDsr(uint256 cdp, uint256 wad)](#injecttocdpfromdsr)
- [lockDai(uint256 wad)](#lockdai)
- [unlockDai(uint256 wad)](#unlockdai)
- [unlockAllDai()](#unlockalldai)
- [transferCdpOwnership(uint256 cdp, address guy)](#transfercdpownership)
- [getCollateralAddreses(bytes32 ilk)](#getcollateraladdreses)
- [()](#)

### initMcdWrapper

```js
function initMcdWrapper(bytes32 ilk, bool isEther) public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| ilk | bytes32 |  | 
| isEther | bool |  | 

### setOwnerProxy

```js
function setOwnerProxy(address newOwner) public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| newOwner | address |  | 

### openLockETHAndDraw

```js
function openLockETHAndDraw(bytes32 ilk, uint256 wadD, uint256 wadC) public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| ilk | bytes32 |  | 
| wadD | uint256 |  | 
| wadC | uint256 |  | 

### openLockERC20AndDraw

```js
function openLockERC20AndDraw(bytes32 ilk, uint256 wadD, uint256 wadC, bool transferFrom) public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| ilk | bytes32 |  | 
| wadD | uint256 |  | 
| wadC | uint256 |  | 
| transferFrom | bool |  | 

### injectToCdpFromDsr

```js
function injectToCdpFromDsr(uint256 cdp, uint256 wad) public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| cdp | uint256 |  | 
| wad | uint256 |  | 

### lockDai

```js
function lockDai(uint256 wad) public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| wad | uint256 |  | 

### unlockDai

```js
function unlockDai(uint256 wad) public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| wad | uint256 |  | 

### unlockAllDai

```js
function unlockAllDai() public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### transferCdpOwnership

```js
function transferCdpOwnership(uint256 cdp, address guy) public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| cdp | uint256 |  | 
| guy | address |  | 

### getCollateralAddreses

```js
function getCollateralAddreses(bytes32 ilk) public pure
returns(mcdJoinEthaAddr address, wethAddr address payable)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| ilk | bytes32 |  | 

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
