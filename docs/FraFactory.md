# Fra Factory (FraFactory.sol)

View Source: [contracts/FraFactory.sol](../contracts/FraFactory.sol)

**↗ Extends: [Administrable](Administrable.md)**

**FraFactory**

Handler of all agreements

## Contract Members
**Constants & Variables**

```js
address[] public agreementList;
address payable public agreementImpl;
address public configAddr;

```

## Functions

- [(address payable _agreementImpl, address _configAddr)](#)
- [initAgreementETH(uint256 _debtValue, uint256 _duration, uint256 _interestRate, bytes32 _collateralType)](#initagreementeth)
- [initAgreementERC20(uint256 _collateralValue, uint256 _debtValue, uint256 _duration, uint256 _interestRate, bytes32 _collateralType)](#initagreementerc20)
- [setAgreementImpl(address payable _agreementImpl)](#setagreementimpl)
- [setConfigAddr(address _configAddr)](#setconfigaddr)
- [approveAgreement(address _address)](#approveagreement)
- [batchApproveAgreements(address[] _addresses)](#batchapproveagreements)
- [rejectAgreement(address _address)](#rejectagreement)
- [batchRejectAgreements(address[] _addresses)](#batchrejectagreements)
- [autoRejectAgreements()](#autorejectagreements)
- [updateAgreement(address _address)](#updateagreement)
- [updateAgreements()](#updateagreements)
- [batchUpdateAgreements(address[] _addresses)](#batchupdateagreements)
- [blockAgreement(address _address)](#blockagreement)
- [removeAgreement(uint256 _ind)](#removeagreement)
- [transferAgreementOwnership(address _address)](#transferagreementownership)
- [claimAgreementOwnership(address _address)](#claimagreementownership)
- [getAgreementList()](#getagreementlist)

### 

Set config and agreement implementation

```js
function (address payable _agreementImpl, address _configAddr) public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _agreementImpl | address payable | address of agreement implementation contract | 
| _configAddr | address | address of config contract | 

### initAgreementETH

Requests agreement on ETH collateralType

```js
function initAgreementETH(uint256 _debtValue, uint256 _duration, uint256 _interestRate, bytes32 _collateralType) external payable
returns(_newAgreement address)
```

**Returns**

agreement address

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _debtValue | uint256 | value of borrower's ETH put into the contract as collateral | 
| _duration | uint256 | number of minutes which agreement should be terminated after | 
| _interestRate | uint256 | percent of interest rate, should be passed like RAY | 
| _collateralType | bytes32 | type of collateral, should be passed as bytes32 | 

### initAgreementERC20

Requests agreement on ERC-20 collateralType

```js
function initAgreementERC20(uint256 _collateralValue, uint256 _debtValue, uint256 _duration, uint256 _interestRate, bytes32 _collateralType) external nonpayable
returns(_newAgreement address)
```

**Returns**

agreement address

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _collateralValue | uint256 |  | 
| _debtValue | uint256 | value of borrower's collateral | 
| _duration | uint256 | number of minutes which agreement should be terminated after | 
| _interestRate | uint256 | percent of interest rate, should be passed like | 
| _collateralType | bytes32 | type of collateral, should be passed as bytes32 | 

### setAgreementImpl

Set the new agreement implememntation adresss

```js
function setAgreementImpl(address payable _agreementImpl) public nonpayable onlyAdmin 
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _agreementImpl | address payable | address of agreement implementation contract | 

### setConfigAddr

Set the new config adresss

```js
function setConfigAddr(address _configAddr) public nonpayable onlyAdmin 
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _configAddr | address | address of config contract | 

### approveAgreement

Makes the specific agreement valid

```js
function approveAgreement(address _address) public nonpayable onlyAdmin 
returns(_success bool)
```

**Returns**

operation success

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _address | address | agreement address | 

### batchApproveAgreements

Multi approve

```js
function batchApproveAgreements(address[] _addresses) public nonpayable onlyAdmin 
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _addresses | address[] | agreements addresses array | 

### rejectAgreement

Reject specific agreement

```js
function rejectAgreement(address _address) public nonpayable onlyAdmin 
returns(_success bool)
```

**Returns**

operation success

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _address | address | agreement address | 

### batchRejectAgreements

Multi reject

```js
function batchRejectAgreements(address[] _addresses) public nonpayable onlyAdmin 
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _addresses | address[] | agreements addresses array | 

### autoRejectAgreements

Function for cron autoreject (close agreements if matchLimit expired)

```js
function autoRejectAgreements() public nonpayable onlyAdmin 
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### updateAgreement

Update the state of specific agreement

```js
function updateAgreement(address _address) public nonpayable onlyAdmin 
returns(_success bool)
```

**Returns**

operation success

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _address | address | agreement address | 

### updateAgreements

Update the states of all agreemnets

```js
function updateAgreements() public nonpayable onlyAdmin 
```

**Returns**

operation success

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### batchUpdateAgreements

Update state of exact agreements

```js
function batchUpdateAgreements(address[] _addresses) public nonpayable onlyAdmin 
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _addresses | address[] | agreements addresses array | 

### blockAgreement

Block specific agreement

```js
function blockAgreement(address _address) public nonpayable onlyAdmin 
returns(_success bool)
```

**Returns**

operation success

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _address | address | agreement address | 

### removeAgreement

Remove agreement from list,
doesn't affect real agreement contract, just removes handle control

```js
function removeAgreement(uint256 _ind) public nonpayable onlyAdmin 
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _ind | uint256 |  | 

### transferAgreementOwnership

transfer agreement ownership to Fra Factory owner (admin)

```js
function transferAgreementOwnership(address _address) public nonpayable onlyAdmin 
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _address | address |  | 

### claimAgreementOwnership

accept agreement ownership by Fra Factory contract

```js
function claimAgreementOwnership(address _address) public nonpayable onlyAdmin 
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _address | address |  | 

### getAgreementList

Returns a full list of existing agreements

```js
function getAgreementList() public view
returns(_agreementList address[])
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
