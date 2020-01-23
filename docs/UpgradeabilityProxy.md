# UpgradeabilityProxy (UpgradeabilityProxy.sol)

View Source: [zos-lib/contracts/upgradeability/UpgradeabilityProxy.sol](../zos-lib/contracts/upgradeability/UpgradeabilityProxy.sol)

**↗ Extends: [BaseUpgradeabilityProxy](BaseUpgradeabilityProxy.md)**

**UpgradeabilityProxy**

Extends BaseUpgradeabilityProxy with a constructor for initializing
implementation and init data.

## Functions

- [(address _logic, bytes _data)](#)

### 

Contract constructor.

```js
function (address _logic, bytes _data) public payable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _logic | address | Address of the initial implementation. | 
| _data | bytes | Data to send as msg.data to the implementation to initialize the proxied contract.
It should include the signature and the parameters of the function to be called, as described in
https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
This parameter is optional, if no data is given the initialization call to proxied contract will be skipped. | 

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
