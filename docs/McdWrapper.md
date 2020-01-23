# Agreement multicollateral dai wrapper for maker dao system interaction. (McdWrapper.sol)

View Source: [contracts/mcd/McdWrapper.sol](../contracts/mcd/McdWrapper.sol)

**↗ Extends: [McdAddressesR17](McdAddressesR17.md), [RaySupport](RaySupport.md)**
**↘ Derived Contracts: [Agreement](Agreement.md), [McdWrapperMock](McdWrapperMock.md)**

**McdWrapper**

delegates calls to proxy. Oriented to exact MCD release. Current version oriented to 17th release mcd cdp.

## Contract Members
**Constants & Variables**

```js
address payable public proxyAddress;

```

## Functions

- [proxy()](#proxy)
- [erc20TokenContract(bytes32 ilk)](#erc20tokencontract)
- [getLockedDai()](#getlockeddai)
- [getDsr()](#getdsr)
- [getCollateralEquivalent(bytes32 ilk, uint256 daiAmount)](#getcollateralequivalent)
- [getCdpInfo(bytes32 ilk, uint256 cdpId)](#getcdpinfo)
- [getPrice(bytes32 ilk)](#getprice)
- [getSafePrice(bytes32 ilk)](#getsafeprice)
- [getLiquidationRatio(bytes32 ilk)](#getliquidationratio)
- [isCdpSafe(bytes32 ilk, uint256 cdpId)](#iscdpsafe)
- [getDaiAvailable(bytes32 ilk, uint256 cdpId)](#getdaiavailable)
- [getCdpCR(bytes32 ilk, uint256 cdpId)](#getcdpcr)
- [getMCR(bytes32 ilk)](#getmcr)
- [_initMcdWrapper(bytes32 ilk, bool isEther)](#_initmcdwrapper)
- [_buildProxy()](#_buildproxy)
- [_setOwnerProxy(address newOwner)](#_setownerproxy)
- [_lockETH(bytes32 ilk, uint256 cdp, uint256 wadC)](#_locketh)
- [_lockERC20(bytes32 ilk, uint256 cdp, uint256 wadC, bool transferFrom)](#_lockerc20)
- [_openLockETHAndDraw(bytes32 ilk, uint256 wadC, uint256 wadD)](#_openlockethanddraw)
- [_openLockERC20AndDraw(bytes32 ilk, uint256 wadC, uint256 wadD, bool transferFrom)](#_openlockerc20anddraw)
- [_injectToCdpFromDsr(uint256 cdp, uint256 wad)](#_injecttocdpfromdsr)
- [_drawDaiToCdp(bytes32 ilk, uint256 cdp, uint256 wad)](#_drawdaitocdp)
- [_lockDai(uint256 wad)](#_lockdai)
- [_unlockDai(uint256 wad)](#_unlockdai)
- [_unlockAllDai()](#_unlockalldai)
- [_approveDai(address to, uint256 amount)](#_approvedai)
- [_approveERC20(bytes32 ilk, address to, uint256 amount)](#_approveerc20)
- [_transferDai(address to, uint256 amount)](#_transferdai)
- [_transferERC20(bytes32 ilk, address to, uint256 amount)](#_transfererc20)
- [_transferFromDai(address from, address to, uint256 amount)](#_transferfromdai)
- [_transferFromERC20(bytes32 ilk, address from, address to, uint256 amount)](#_transferfromerc20)
- [_transferCdpOwnershipToProxy(uint256 cdp, address guy)](#_transfercdpownershiptoproxy)
- [_balanceDai(address addr)](#_balancedai)
- [_getCollateralAddreses(bytes32 ilk)](#_getcollateraladdreses)

### proxy

Get registered proxy for current caller (msg.sender address)

```js
function proxy() public view
returns(contract DSProxyLike)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### erc20TokenContract

⤾ overrides [IAgreement.erc20TokenContract](IAgreement.md#erc20tokencontract)

⤿ Overridden Implementation(s): [AgreementDeepMock.erc20TokenContract](AgreementDeepMock.md#erc20tokencontract),[AgreementMock.erc20TokenContract](AgreementMock.md#erc20tokencontract)

transfer exact amount of erc20 tokens, approved beforehand

```js
function erc20TokenContract(bytes32 ilk) public view
returns(contract IERC20)
```

**Returns**

IERC20 instance

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| ilk | bytes32 |  | 

### getLockedDai

get amount of dai tokens currently locked in dsr(pot) contract.

```js
function getLockedDai() public view
returns(pie uint256, pieS uint256)
```

**Returns**

pie amount of all dai tokens locked in dsr

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### getDsr

⤿ Overridden Implementation(s): [AgreementDeepMock.getDsr](AgreementDeepMock.md#getdsr),[AgreementMock.getDsr](AgreementMock.md#getdsr)

get dai savings rate

```js
function getDsr() public view
returns(uint256)
```

**Returns**

dsr value in multiplier format defined by maker dao system. 100 * 10^25 - means 0% dsr. 103 * 10^25 means 3% dsr.

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### getCollateralEquivalent

Get the equivalent of exact dai amount in terms of collateral type.

```js
function getCollateralEquivalent(bytes32 ilk, uint256 daiAmount) public view
returns(uint256)
```

**Returns**

collateral tokens amount worth dai amount

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| ilk | bytes32 |  | 
| daiAmount | uint256 |  | 

### getCdpInfo

Get current cdp main info: collateral amount, dai (debt) amount

```js
function getCdpInfo(bytes32 ilk, uint256 cdpId) public view
returns(ink uint256, art uint256)
```

**Returns**

ink     collateral tokens amount
         art     dai debt amount

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| ilk | bytes32 |  | 
| cdpId | uint256 |  | 

### getPrice

Get collateral token price to USD

```js
function getPrice(bytes32 ilk) public view
returns(uint256)
```

**Returns**

collateral to USD price

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| ilk | bytes32 |  | 

### getSafePrice

Get collateral token safe price to USD. Equals current origin price devided by liquidation ratio

```js
function getSafePrice(bytes32 ilk) public view
returns(uint256)
```

**Returns**

collateral to USD price

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| ilk | bytes32 |  | 

### getLiquidationRatio

Get collateral liquidation ratio. Percent of overcollateralization. If collateral / debt < liauidation ratio - cdp should be autoliquidated

```js
function getLiquidationRatio(bytes32 ilk) public view
returns(uint256)
```

**Returns**

liquidation ratio  150 * 10^25 - means 150%

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| ilk | bytes32 |  | 

### isCdpSafe

⤿ Overridden Implementation(s): [AgreementDeepMock.isCdpSafe](AgreementDeepMock.md#iscdpsafe),[AgreementMock.isCdpSafe](AgreementMock.md#iscdpsafe)

Check is cdp is unsafe already

```js
function isCdpSafe(bytes32 ilk, uint256 cdpId) public view
returns(bool)
```

**Returns**

true if unsafe

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| ilk | bytes32 |  | 
| cdpId | uint256 |  | 

### getDaiAvailable

Calculate available dai to be drawn in Cdp

```js
function getDaiAvailable(bytes32 ilk, uint256 cdpId) public view
returns(uint256)
```

**Returns**

dai amount available to be drawn

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| ilk | bytes32 |  | 
| cdpId | uint256 |  | 

### getCdpCR

Calculate current cdp collateralization ratio

```js
function getCdpCR(bytes32 ilk, uint256 cdpId) public view
returns(uint256)
```

**Returns**

collateralization ratio

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| ilk | bytes32 |  | 
| cdpId | uint256 |  | 

### getMCR

Get minimal collateralization ratio for collateral type

```js
function getMCR(bytes32 ilk) public view
returns(uint256)
```

**Returns**

minimal collateralization ratio

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| ilk | bytes32 |  | 

### _initMcdWrapper

⤿ Overridden Implementation(s): [AgreementDeepMock._initMcdWrapper](AgreementDeepMock.md#_initmcdwrapper),[AgreementMock._initMcdWrapper](AgreementMock.md#_initmcdwrapper)

init mcd Wrapper, build proxy

```js
function _initMcdWrapper(bytes32 ilk, bool isEther) internal nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| ilk | bytes32 |  | 
| isEther | bool |  | 

### _buildProxy

Build proxy for current caller (msg.sender address)

```js
function _buildProxy() internal nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### _setOwnerProxy

Change proxy owner to a new one

```js
function _setOwnerProxy(address newOwner) internal nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| newOwner | address |  | 

### _lockETH

⤿ Overridden Implementation(s): [AgreementDeepMock._lockETH](AgreementDeepMock.md#_locketh),[AgreementMock._lockETH](AgreementMock.md#_locketh)

Lock additional ether as collateral

```js
function _lockETH(bytes32 ilk, uint256 cdp, uint256 wadC) internal nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| ilk | bytes32 |  | 
| cdp | uint256 |  | 
| wadC | uint256 |  | 

### _lockERC20

Lock additional erc-20 tokens as collateral

```js
function _lockERC20(bytes32 ilk, uint256 cdp, uint256 wadC, bool transferFrom) internal nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| ilk | bytes32 |  | 
| cdp | uint256 |  | 
| wadC | uint256 |  | 
| transferFrom | bool |  | 

### _openLockETHAndDraw

Create new cdp with Ether as collateral, lock collateral and draw dai

```js
function _openLockETHAndDraw(bytes32 ilk, uint256 wadC, uint256 wadD) internal nonpayable
returns(cdp uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| ilk | bytes32 |  | 
| wadC | uint256 |  | 
| wadD | uint256 |  | 

### _openLockERC20AndDraw

Create new cdp with ERC-20 tokens as collateral, lock collateral and draw dai

```js
function _openLockERC20AndDraw(bytes32 ilk, uint256 wadC, uint256 wadD, bool transferFrom) internal nonpayable
returns(cdp uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| ilk | bytes32 |  | 
| wadC | uint256 |  | 
| wadD | uint256 |  | 
| transferFrom | bool |  | 

### _injectToCdpFromDsr

⤿ Overridden Implementation(s): [AgreementDeepMock._injectToCdpFromDsr](AgreementDeepMock.md#_injecttocdpfromdsr),[AgreementMock._injectToCdpFromDsr](AgreementMock.md#_injecttocdpfromdsr)

inject(wipe) some amount of dai to cdp from agreement (pay off some amount of dai to cdp)

```js
function _injectToCdpFromDsr(uint256 cdp, uint256 wad) internal nonpayable
returns(injectionWad uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| cdp | uint256 |  | 
| wad | uint256 |  | 

### _drawDaiToCdp

⤿ Overridden Implementation(s): [AgreementDeepMock._drawDaiToCdp](AgreementDeepMock.md#_drawdaitocdp),[AgreementMock._drawDaiToCdp](AgreementMock.md#_drawdaitocdp)

draw dai into cdp contract, if not enough - draw max available dai

```js
function _drawDaiToCdp(bytes32 ilk, uint256 cdp, uint256 wad) internal nonpayable
returns(drawnDai uint256)
```

**Returns**

drawn dai amount

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| ilk | bytes32 |  | 
| cdp | uint256 |  | 
| wad | uint256 |  | 

### _lockDai

⤿ Overridden Implementation(s): [AgreementDeepMock._lockDai](AgreementDeepMock.md#_lockdai),[AgreementMock._lockDai](AgreementMock.md#_lockdai)

lock dai tokens to dsr(pot) contract.

```js
function _lockDai(uint256 wad) internal nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| wad | uint256 |  | 

### _unlockDai

unlock dai tokens from dsr(pot) contract.

```js
function _unlockDai(uint256 wad) internal nonpayable
returns(unlockedWad uint256)
```

**Returns**

actually unlocked amount of dai

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| wad | uint256 |  | 

### _unlockAllDai

⤿ Overridden Implementation(s): [AgreementDeepMock._unlockAllDai](AgreementDeepMock.md#_unlockalldai),[AgreementMock._unlockAllDai](AgreementMock.md#_unlockalldai)

unlock all dai tokens from dsr(pot) contract.

```js
function _unlockAllDai() internal nonpayable
returns(pie uint256)
```

**Returns**

pie amount of all dai tokens was unlocked in fact

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### _approveDai

Approve exact amount of dai tokens for transferFrom

```js
function _approveDai(address to, uint256 amount) internal nonpayable
returns(bool)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| to | address |  | 
| amount | uint256 |  | 

### _approveERC20

Approve exact amount of erc20 tokens for transferFrom

```js
function _approveERC20(bytes32 ilk, address to, uint256 amount) internal nonpayable
returns(bool)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| ilk | bytes32 |  | 
| to | address |  | 
| amount | uint256 |  | 

### _transferDai

⤿ Overridden Implementation(s): [AgreementDeepMock._transferDai](AgreementDeepMock.md#_transferdai),[AgreementMock._transferDai](AgreementMock.md#_transferdai)

Transfer exact amount of dai tokens

```js
function _transferDai(address to, uint256 amount) internal nonpayable
returns(bool)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| to | address |  | 
| amount | uint256 |  | 

### _transferERC20

Transfer exact amount of erc20 tokens

```js
function _transferERC20(bytes32 ilk, address to, uint256 amount) internal nonpayable
returns(bool)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| ilk | bytes32 |  | 
| to | address |  | 
| amount | uint256 |  | 

### _transferFromDai

⤿ Overridden Implementation(s): [AgreementDeepMock._transferFromDai](AgreementDeepMock.md#_transferfromdai),[AgreementDeepMock._transferFromDai](AgreementDeepMock.md#_transferfromdai),[AgreementMock._transferFromDai](AgreementMock.md#_transferfromdai),[AgreementMock._transferFromDai](AgreementMock.md#_transferfromdai)

Transfer exact amount of dai tokens, approved beforehand

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

### _transferFromERC20

Transfer exact amount of erc20 tokens, approved beforehand

```js
function _transferFromERC20(bytes32 ilk, address from, address to, uint256 amount) internal nonpayable
returns(bool)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| ilk | bytes32 |  | 
| from | address |  | 
| to | address |  | 
| amount | uint256 |  | 

### _transferCdpOwnershipToProxy

⤿ Overridden Implementation(s): [AgreementDeepMock._transferCdpOwnershipToProxy](AgreementDeepMock.md#_transfercdpownershiptoproxy),[AgreementMock._transferCdpOwnershipToProxy](AgreementMock.md#_transfercdpownershiptoproxy)

Transfer Cdp ownership to guy's proxy

```js
function _transferCdpOwnershipToProxy(uint256 cdp, address guy) internal nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| cdp | uint256 |  | 
| guy | address |  | 

### _balanceDai

⤿ Overridden Implementation(s): [AgreementDeepMock._balanceDai](AgreementDeepMock.md#_balancedai),[AgreementMock._balanceDai](AgreementMock.md#_balancedai)

Get balance of dai tokens

```js
function _balanceDai(address addr) internal view
returns(uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| addr | address |  | 

### _getCollateralAddreses

Transfer exact amount of erc20 tokens, approved beforehand

```js
function _getCollateralAddreses(bytes32 ilk) internal pure
returns(address, address payable)
```

**Returns**

token adapter address

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| ilk | bytes32 |  | 

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
