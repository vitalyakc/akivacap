# AgreementMock.sol

View Source: [contracts/mocks/AgreementMock.sol](../contracts/mocks/AgreementMock.sol)

**↗ Extends: [Agreement](Agreement.md)**

**AgreementMock**

## Contract Members
**Constants & Variables**

```js
//public members
uint256 public dsrTest;
uint256 public currentTime;
uint256 public unlockedDai;
address public mcdDaiAddrMock;

//internal members
address internal erc20Token;
uint256 internal drawnCdp;
uint256 internal injectionWad;
uint256 internal CR;
uint256 internal price;

```

## Functions

- [setDelta(int256 _delta)](#setdelta)
- [setDsr(uint256 _dsrTest)](#setdsr)
- [getDsr()](#getdsr)
- [setCurrentTime(uint256 _time)](#setcurrenttime)
- [_lockDai(uint256 wad)](#_lockdai)
- [_lockETH(bytes32 ilk, uint256 cdp, uint256 wadC)](#_locketh)
- [setMcdDaiAddrMock(address _addr)](#setmcddaiaddrmock)
- [_transferDai(address , uint256 )](#_transferdai)
- [_transferFromDai(address from, address to, uint256 amount)](#_transferfromdai)
- [setUnlockedDai(uint256 _amount)](#setunlockeddai)
- [_unlockAllDai()](#_unlockalldai)
- [_balanceDai(address )](#_balancedai)
- [_initMcdWrapper(bytes32 ilk, bool isEther)](#_initmcdwrapper)
- [setErc20Token(address _contract)](#seterc20token)
- [erc20TokenContract(bytes32 )](#erc20tokencontract)
- [initAgreement(address payable _borrower, uint256 _collateralAmount, uint256 _debtValue, uint256 _duration, uint256 _interestRatePercent, bytes32 _collateralType, bool _isETH, address _configAddr)](#initagreement)
- [updateAgreementState(bool _lastUpdate)](#updateagreementstate)
- [setLastCheckTime(uint256 _value)](#setlastchecktime)
- [setStatus(uint256 _status)](#setstatus)
- [refund()](#refund)
- [_transferCdpOwnershipToProxy(uint256 , address )](#_transfercdpownershiptoproxy)
- [setDrawnCdp(uint256 _drawnCdp)](#setdrawncdp)
- [_drawDaiToCdp(bytes32 , uint256 , uint256 )](#_drawdaitocdp)
- [_injectToCdpFromDsr(uint256 , uint256 )](#_injecttocdpfromdsr)
- [setInjectionWad(uint256 _injectionWad)](#setinjectionwad)
- [nextStatus()](#nextstatus)
- [switchStatus(enum IAgreement.Statuses _next)](#switchstatus)
- [switchStatusClosedWithType(enum IAgreement.ClosedTypes _closedType)](#switchstatusclosedwithtype)
- [doStatusSnapshot()](#dostatussnapshot)
- [pushCollateralAsset(address _holder, uint256 _amount)](#pushcollateralasset)
- [pushDaiAsset(address _holder, uint256 _amount)](#pushdaiasset)
- [popCollateralAsset(address _holder, uint256 _amount)](#popcollateralasset)
- [popDaiAsset(address _holder, uint256 _amount)](#popdaiasset)
- [isCdpSafe(bytes32 , uint256 )](#iscdpsafe)
- [setCRBuffer(uint256 _CR)](#setcrbuffer)
- [getCRBuffer()](#getcrbuffer)
- [monitorRisky()](#monitorrisky)
- [_transferFromDai(address , address , uint256 )](#_transferfromdai)

### setDelta

should be removed after testing!!!

```js
function setDelta(int256 _delta) public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _delta | int256 |  | 

### setDsr

```js
function setDsr(uint256 _dsrTest) public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _dsrTest | uint256 |  | 

### getDsr

⤾ overrides [McdWrapper.getDsr](McdWrapper.md#getdsr)

```js
function getDsr() public view
returns(uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### setCurrentTime

```js
function setCurrentTime(uint256 _time) public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _time | uint256 |  | 

### _lockDai

⤾ overrides [McdWrapper._lockDai](McdWrapper.md#_lockdai)

```js
function _lockDai(uint256 wad) internal nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| wad | uint256 |  | 

### _lockETH

⤾ overrides [McdWrapper._lockETH](McdWrapper.md#_locketh)

```js
function _lockETH(bytes32 ilk, uint256 cdp, uint256 wadC) internal nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| ilk | bytes32 |  | 
| cdp | uint256 |  | 
| wadC | uint256 |  | 

### setMcdDaiAddrMock

```js
function setMcdDaiAddrMock(address _addr) public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _addr | address |  | 

### _transferDai

⤾ overrides [McdWrapper._transferDai](McdWrapper.md#_transferdai)

```js
function _transferDai(address , uint256 ) internal nonpayable
returns(bool)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
|  | address |  | 
|  | uint256 |  | 

### _transferFromDai

⤾ overrides [McdWrapper._transferFromDai](McdWrapper.md#_transferfromdai)

⤿ Overridden Implementation(s): [AgreementDeepMock._transferFromDai](AgreementDeepMock.md#_transferfromdai),[AgreementMock._transferFromDai](AgreementMock.md#_transferfromdai)

```js
function _transferFromDai(address from, address to, uint256 amount) internal nonpayable
returns(bool)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| from | address |  | 
| to | address |  | 
| amount | uint256 |  | 

### setUnlockedDai

```js
function setUnlockedDai(uint256 _amount) public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _amount | uint256 |  | 

### _unlockAllDai

⤾ overrides [McdWrapper._unlockAllDai](McdWrapper.md#_unlockalldai)

```js
function _unlockAllDai() internal nonpayable
returns(uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### _balanceDai

⤾ overrides [McdWrapper._balanceDai](McdWrapper.md#_balancedai)

```js
function _balanceDai(address ) internal view
returns(uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
|  | address |  | 

### _initMcdWrapper

⤾ overrides [McdWrapper._initMcdWrapper](McdWrapper.md#_initmcdwrapper)

```js
function _initMcdWrapper(bytes32 ilk, bool isEther) internal nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| ilk | bytes32 |  | 
| isEther | bool |  | 

### setErc20Token

```js
function setErc20Token(address _contract) public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _contract | address |  | 

### erc20TokenContract

⤾ overrides [McdWrapper.erc20TokenContract](McdWrapper.md#erc20tokencontract)

```js
function erc20TokenContract(bytes32 ) public view
returns(contract IERC20)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
|  | bytes32 |  | 

### initAgreement

⤾ overrides [Agreement.initAgreement](Agreement.md#initagreement)

```js
function initAgreement(address payable _borrower, uint256 _collateralAmount, uint256 _debtValue, uint256 _duration, uint256 _interestRatePercent, bytes32 _collateralType, bool _isETH, address _configAddr) public payable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _borrower | address payable |  | 
| _collateralAmount | uint256 |  | 
| _debtValue | uint256 |  | 
| _duration | uint256 |  | 
| _interestRatePercent | uint256 |  | 
| _collateralType | bytes32 |  | 
| _isETH | bool |  | 
| _configAddr | address |  | 

### updateAgreementState

```js
function updateAgreementState(bool _lastUpdate) public nonpayable
returns(success bool)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _lastUpdate | bool |  | 

### setLastCheckTime

```js
function setLastCheckTime(uint256 _value) public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _value | uint256 |  | 

### setStatus

```js
function setStatus(uint256 _status) public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _status | uint256 |  | 

### refund

```js
function refund() public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### _transferCdpOwnershipToProxy

⤾ overrides [McdWrapper._transferCdpOwnershipToProxy](McdWrapper.md#_transfercdpownershiptoproxy)

```js
function _transferCdpOwnershipToProxy(uint256 , address ) internal nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
|  | uint256 |  | 
|  | address |  | 

### setDrawnCdp

```js
function setDrawnCdp(uint256 _drawnCdp) public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _drawnCdp | uint256 |  | 

### _drawDaiToCdp

⤾ overrides [McdWrapper._drawDaiToCdp](McdWrapper.md#_drawdaitocdp)

```js
function _drawDaiToCdp(bytes32 , uint256 , uint256 ) internal nonpayable
returns(uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
|  | bytes32 |  | 
|  | uint256 |  | 
|  | uint256 |  | 

### _injectToCdpFromDsr

⤾ overrides [McdWrapper._injectToCdpFromDsr](McdWrapper.md#_injecttocdpfromdsr)

```js
function _injectToCdpFromDsr(uint256 , uint256 ) internal nonpayable
returns(uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
|  | uint256 |  | 
|  | uint256 |  | 

### setInjectionWad

```js
function setInjectionWad(uint256 _injectionWad) public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _injectionWad | uint256 |  | 

### nextStatus

```js
function nextStatus() public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### switchStatus

```js
function switchStatus(enum IAgreement.Statuses _next) public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _next | enum IAgreement.Statuses |  | 

### switchStatusClosedWithType

```js
function switchStatusClosedWithType(enum IAgreement.ClosedTypes _closedType) public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _closedType | enum IAgreement.ClosedTypes |  | 

### doStatusSnapshot

```js
function doStatusSnapshot() public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### pushCollateralAsset

```js
function pushCollateralAsset(address _holder, uint256 _amount) public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _holder | address |  | 
| _amount | uint256 |  | 

### pushDaiAsset

```js
function pushDaiAsset(address _holder, uint256 _amount) public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _holder | address |  | 
| _amount | uint256 |  | 

### popCollateralAsset

```js
function popCollateralAsset(address _holder, uint256 _amount) public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _holder | address |  | 
| _amount | uint256 |  | 

### popDaiAsset

```js
function popDaiAsset(address _holder, uint256 _amount) public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _holder | address |  | 
| _amount | uint256 |  | 

### isCdpSafe

⤾ overrides [McdWrapper.isCdpSafe](McdWrapper.md#iscdpsafe)

```js
function isCdpSafe(bytes32 , uint256 ) public view
returns(bool)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
|  | bytes32 |  | 
|  | uint256 |  | 

### setCRBuffer

```js
function setCRBuffer(uint256 _CR) public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| _CR | uint256 |  | 

### getCRBuffer

⤾ overrides [Agreement.getCRBuffer](Agreement.md#getcrbuffer)

```js
function getCRBuffer() public view
returns(uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### monitorRisky

```js
function monitorRisky() public nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### _transferFromDai

⤾ overrides [AgreementDeepMock._transferFromDai](AgreementDeepMock.md#_transferfromdai)

```js
function _transferFromDai(address , address , uint256 ) internal nonpayable
returns(bool)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
|  | address |  | 
|  | address |  | 
|  | uint256 |  | 

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
