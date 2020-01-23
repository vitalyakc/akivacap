# Ownable contract (Claimable.sol)

View Source: [contracts/helpers/Claimable.sol](../contracts/helpers/Claimable.sol)

**↗ Extends: [Ownable](Ownable.md)**
**↘ Derived Contracts: [ClaimableBase](ClaimableBase.md), [ClaimableIni](ClaimableIni.md)**

**Claimable**

Contract has all neccessary ownable functions but doesn't have initialization

## Contract Members
**Constants & Variables**

```js
address public owner;
address public pendingOwner;

```

**Events**

```js
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
```

## Modifiers

- [onlyContractOwner](#onlycontractowner)

### onlyContractOwner

Grants access only for owner

```js
modifier onlyContractOwner() internal
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

## Functions

- [isOwner(address _addr)](#isowner)
- [_setInitialOwner(address _addr)](#_setinitialowner)
- [transferOwnership(address _newOwner)](#transferownership)
- [claimOwnership()](#claimownership)

### isOwner

Check if address is  owner

```js
function isOwner(address _addr) public view
returns(bool)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _addr | address |  | 

### _setInitialOwner

Set initial owner

```js
function _setInitialOwner(address _addr) internal nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _addr | address |  | 

### transferOwnership

⤾ overrides [IAgreement.transferOwnership](IAgreement.md#transferownership)

Transfer ownership

```js
function transferOwnership(address _newOwner) public nonpayable onlyContractOwner 
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _newOwner | address |  | 

### claimOwnership

⤾ overrides [IAgreement.claimOwnership](IAgreement.md#claimownership)

Approve pending owner by new owner

```js
function claimOwnership() public nonpayable
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
