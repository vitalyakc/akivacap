# Interface for ERC20 token contract (IERC20.sol)

View Source: [contracts/interfaces/IERC20.sol](../contracts/interfaces/IERC20.sol)

**↘ Derived Contracts: [SimpleErc20Token](SimpleErc20Token.md)**

**IERC20**

**Events**

```js
event Transfer(address indexed from, address indexed to, uint256  tokens);
event Approval(address indexed tokenOwner, address indexed spender, uint256  tokens);
```

## Functions

- [totalSupply()](#totalsupply)
- [balanceOf(address )](#balanceof)
- [allowance(address , address )](#allowance)
- [transfer(address , uint256 )](#transfer)
- [approve(address , uint256 )](#approve)
- [transferFrom(address , address , uint256 )](#transferfrom)

### totalSupply

⤿ Overridden Implementation(s): [SimpleErc20Token.totalSupply](SimpleErc20Token.md#totalsupply)

```js
function totalSupply() external view
returns(uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### balanceOf

⤿ Overridden Implementation(s): [SimpleErc20Token.balanceOf](SimpleErc20Token.md#balanceof)

```js
function balanceOf(address ) external view
returns(uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
|  | address |  | 

### allowance

⤿ Overridden Implementation(s): [SimpleErc20Token.allowance](SimpleErc20Token.md#allowance)

```js
function allowance(address , address ) external view
returns(uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
|  | address |  | 
|  | address |  | 

### transfer

⤿ Overridden Implementation(s): [SimpleErc20Token.transfer](SimpleErc20Token.md#transfer)

```js
function transfer(address , uint256 ) external nonpayable
returns(bool)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
|  | address |  | 
|  | uint256 |  | 

### approve

⤿ Overridden Implementation(s): [SimpleErc20Token.approve](SimpleErc20Token.md#approve)

```js
function approve(address , uint256 ) external nonpayable
returns(bool)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
|  | address |  | 
|  | uint256 |  | 

### transferFrom

⤿ Overridden Implementation(s): [SimpleErc20Token.transferFrom](SimpleErc20Token.md#transferfrom)

```js
function transferFrom(address , address , uint256 ) external nonpayable
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
