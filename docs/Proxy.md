# Proxy (Proxy.sol)

View Source: [zos-lib/contracts/upgradeability/Proxy.sol](../zos-lib/contracts/upgradeability/Proxy.sol)

**↘ Derived Contracts: [BaseUpgradeabilityProxy](BaseUpgradeabilityProxy.md)**

**Proxy**

Implements delegation of calls to other contracts, with proper
forwarding of return values and bubbling of failures.
It defines a fallback function that delegates all calls to the address
returned by the abstract _implementation() internal function.

## Functions

- [()](#)
- [_implementation()](#_implementation)
- [_delegate(address implementation)](#_delegate)
- [_willFallback()](#_willfallback)
- [_fallback()](#_fallback)

### 

Fallback function.
Implemented entirely in `_fallback`.

```js
function () external payable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### _implementation

⤿ Overridden Implementation(s): [BaseUpgradeabilityProxy._implementation](BaseUpgradeabilityProxy.md#_implementation)

```js
function _implementation() internal view
returns(address)
```

**Returns**

The Address of the implementation.

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### _delegate

Delegates execution to an implementation contract.
This is a low level function that doesn't return to its internal call site.
It will return to the external caller whatever the implementation returns.

```js
function _delegate(address implementation) internal nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| implementation | address | Address to delegate. | 

### _willFallback

Function that is run as the first thing in the fallback function.
Can be redefined in derived contracts to add functionality.
Redefinitions must call super._willFallback().

```js
function _willFallback() internal nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### _fallback

fallback implementation.
Extracted to enable manual triggering.

```js
function _fallback() internal nonpayable
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
