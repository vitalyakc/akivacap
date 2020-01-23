# BaseUpgradeabilityProxy (BaseUpgradeabilityProxy.sol)

View Source: [zos-lib/contracts/upgradeability/BaseUpgradeabilityProxy.sol](../zos-lib/contracts/upgradeability/BaseUpgradeabilityProxy.sol)

**↗ Extends: [Proxy](Proxy.md)**
**↘ Derived Contracts: [UpgradeabilityProxy](UpgradeabilityProxy.md)**

**BaseUpgradeabilityProxy**

This contract implements a proxy that allows to change the
implementation address to which it will delegate.
Such a change is called an implementation upgrade.

## Contract Members
**Constants & Variables**

```js
bytes32 internal constant IMPLEMENTATION_SLOT;

```

**Events**

```js
event Upgraded(address indexed implementation);
```

## Functions

- [_implementation()](#_implementation)
- [_upgradeTo(address newImplementation)](#_upgradeto)
- [_setImplementation(address newImplementation)](#_setimplementation)

### _implementation

⤾ overrides [Proxy._implementation](Proxy.md#_implementation)

Returns the current implementation.

```js
function _implementation() internal view
returns(impl address)
```

**Returns**

Address of the current implementation

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### _upgradeTo

Upgrades the proxy to a new implementation.

```js
function _upgradeTo(address newImplementation) internal nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| newImplementation | address | Address of the new implementation. | 

### _setImplementation

Sets the implementation address of the proxy.

```js
function _setImplementation(address newImplementation) internal nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| newImplementation | address | Address of the new implementation. | 

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
