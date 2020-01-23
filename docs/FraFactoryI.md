# FraFactoryI.sol

View Source: [contracts/FraQueries.sol](../contracts/FraQueries.sol)

**FraFactoryI**

## Contract Members
**Constants & Variables**

```js
mapping(address => address[]) public agreements;
address[] public agreementList;

```

## Functions

- [getAgreementList()](#getagreementlist)
- [()](#)
- [getAgreements(address _fraFactoryAddr, uint256 _status, address _user)](#getagreements)
- [getAgreementsCount(address _fraFactoryAddr)](#getagreementscount)
- [getActiveCdps(address _fraFactoryAddr)](#getactivecdps)
- [getTotalCdps(address _fraFactoryAddr)](#gettotalcdps)
- [getUsers(address _fraFactoryAddr)](#getusers)

### getAgreementList

```js
function getAgreementList() public view
returns(_agreementList address[])
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### 

```js
function () public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### getAgreements

```js
function getAgreements(address _fraFactoryAddr, uint256 _status, address _user) public view
returns(agreementsSorted address[])
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _fraFactoryAddr | address |  | 
| _status | uint256 |  | 
| _user | address |  | 

### getAgreementsCount

```js
function getAgreementsCount(address _fraFactoryAddr) public view
returns(cntOpen uint256, cntActive uint256, cntEnded uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _fraFactoryAddr | address |  | 

### getActiveCdps

```js
function getActiveCdps(address _fraFactoryAddr) public view
returns(cdpIds uint256[])
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _fraFactoryAddr | address |  | 

### getTotalCdps

```js
function getTotalCdps(address _fraFactoryAddr) public view
returns(cdpIds uint256[])
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _fraFactoryAddr | address |  | 

### getUsers

```js
function getUsers(address _fraFactoryAddr) public view
returns(lenders address[], borrowers address[])
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _fraFactoryAddr | address |  | 

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
