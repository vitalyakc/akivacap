# Administrable contract, multiadmins managing (Administrable.sol)

View Source: [contracts/helpers/Administrable.sol](../contracts/helpers/Administrable.sol)

**↗ Extends: [ClaimableBase](ClaimableBase.md)**
**↘ Derived Contracts: [FraFactory](FraFactory.md), [LenderPool](LenderPool.md)**

**Administrable**

Inherit Claimable contract with usual initialization in constructor

## Contract Members
**Constants & Variables**

```js
mapping(address => bool) public isAdmin;

```

**Events**

```js
event AdminAppointed(address  admin);
event AdminDismissed(address  admin);
```

## Modifiers

- [onlyAdmin](#onlyadmin)

### onlyAdmin

Grants access only for admin

```js
modifier onlyAdmin() internal
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

## Functions

- [()](#)
- [appointAdmin(address _newAdmin)](#appointadmin)
- [dismissAdmin(address _admin)](#dismissadmin)

### 

Appoint owner as admin

```js
function () public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### appointAdmin

Appoint new admin

```js
function appointAdmin(address _newAdmin) public nonpayable onlyContractOwner 
returns(success bool)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _newAdmin | address |  | 

### dismissAdmin

Dismiss admin

```js
function dismissAdmin(address _admin) public nonpayable onlyContractOwner 
returns(success bool)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _admin | address |  | 

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
