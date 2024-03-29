# SimpleErc20Token.sol

View Source: [contracts/mocks/SimpleErc20Token.sol](../contracts/mocks/SimpleErc20Token.sol)

**↗ Extends: [IERC20](IERC20.md), [ClaimableBase](ClaimableBase.md), [Context](Context.md)**

**SimpleErc20Token**

Implementation of the {IERC20} interface.
 * This implementation is agnostic to the way tokens are created. This means
that a supply mechanism has to be added in a derived contract using {_mint}.
For a generic mechanism see {ERC20Mintable}.
 * TIP: For a detailed writeup see our guide
https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
to implement supply mechanisms].
 * We have followed general OpenZeppelin guidelines: functions revert instead
of returning `false` on failure. This behavior is nonetheless conventional
and does not conflict with the expectations of ERC20 applications.
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
This allows applications to reconstruct the allowance for all accounts just
by listening to said events. Other implementations of the EIP may not emit
these events, as it isn't required by the specification.
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
functions have been added to mitigate the well-known issues around setting
allowances. See {IERC20-approve}.

## Contract Members
**Constants & Variables**

```js
//private members
mapping(address => uint256) private _balances;
uint256 private _totalSupply;

//public members
mapping(address => mapping(address => uint256)) public allowances;

```

## Functions

- [totalSupply()](#totalsupply)
- [balanceOf(address account)](#balanceof)
- [transfer(address recipient, uint256 amount)](#transfer)
- [allowance(address owner, address spender)](#allowance)
- [approve(address spender, uint256 amount)](#approve)
- [transferFrom(address sender, address recipient, uint256 amount)](#transferfrom)
- [increaseAllowance(address spender, uint256 addedValue)](#increaseallowance)
- [decreaseAllowance(address spender, uint256 subtractedValue)](#decreaseallowance)
- [_transfer(address sender, address recipient, uint256 amount)](#_transfer)
- [mint(address account, uint256 amount)](#mint)
- [_mint(address account, uint256 amount)](#_mint)
- [_burn(address account, uint256 amount)](#_burn)
- [_approve(address owner, address spender, uint256 amount)](#_approve)
- [_burnFrom(address account, uint256 amount)](#_burnfrom)

### totalSupply

⤾ overrides [IERC20.totalSupply](IERC20.md#totalsupply)

See {IERC20-totalSupply}.

```js
function totalSupply() public view
returns(uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|

### balanceOf

⤾ overrides [IERC20.balanceOf](IERC20.md#balanceof)

See {IERC20-balanceOf}.

```js
function balanceOf(address account) public view
returns(uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| account | address |  | 

### transfer

⤾ overrides [IERC20.transfer](IERC20.md#transfer)

See {IERC20-transfer}.
     * Requirements:
     * - `recipient` cannot be the zero address.
- the caller must have a balance of at least `amount`.

```js
function transfer(address recipient, uint256 amount) public nonpayable
returns(bool)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| recipient | address |  | 
| amount | uint256 |  | 

### allowance

⤾ overrides [IERC20.allowance](IERC20.md#allowance)

See {IERC20-allowance}.

```js
function allowance(address owner, address spender) public view
returns(uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| owner | address |  | 
| spender | address |  | 

### approve

⤾ overrides [IERC20.approve](IERC20.md#approve)

See {IERC20-approve}.
     * Requirements:
     * - `spender` cannot be the zero address.

```js
function approve(address spender, uint256 amount) public nonpayable
returns(bool)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| spender | address |  | 
| amount | uint256 |  | 

### transferFrom

⤾ overrides [IERC20.transferFrom](IERC20.md#transferfrom)

See {IERC20-transferFrom}.
     * Emits an {Approval} event indicating the updated allowance. This is not
required by the EIP. See the note at the beginning of {ERC20};
     * Requirements:
- `sender` and `recipient` cannot be the zero address.
- `sender` must have a balance of at least `amount`.
- the caller must have allowance for `sender`'s tokens of at least
`amount`.

```js
function transferFrom(address sender, address recipient, uint256 amount) public nonpayable
returns(bool)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| sender | address |  | 
| recipient | address |  | 
| amount | uint256 |  | 

### increaseAllowance

Atomically increases the allowance granted to `spender` by the caller.
     * This is an alternative to {approve} that can be used as a mitigation for
problems described in {IERC20-approve}.
     * Emits an {Approval} event indicating the updated allowance.
     * Requirements:
     * - `spender` cannot be the zero address.

```js
function increaseAllowance(address spender, uint256 addedValue) public nonpayable
returns(bool)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| spender | address |  | 
| addedValue | uint256 |  | 

### decreaseAllowance

Atomically decreases the allowance granted to `spender` by the caller.
     * This is an alternative to {approve} that can be used as a mitigation for
problems described in {IERC20-approve}.
     * Emits an {Approval} event indicating the updated allowance.
     * Requirements:
     * - `spender` cannot be the zero address.
- `spender` must have allowance for the caller of at least
`subtractedValue`.

```js
function decreaseAllowance(address spender, uint256 subtractedValue) public nonpayable
returns(bool)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| spender | address |  | 
| subtractedValue | uint256 |  | 

### _transfer

Moves tokens `amount` from `sender` to `recipient`.
     * This is internal function is equivalent to {transfer}, and can be used to
e.g. implement automatic token fees, slashing mechanisms, etc.
     * Emits a {Transfer} event.
     * Requirements:
     * - `sender` cannot be the zero address.
- `recipient` cannot be the zero address.
- `sender` must have a balance of at least `amount`.

```js
function _transfer(address sender, address recipient, uint256 amount) internal nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| sender | address |  | 
| recipient | address |  | 
| amount | uint256 |  | 

### mint

Creates `amount` tokens and assigns them to `account`, increasing
the total supply.
     * Emits a {Transfer} event with `from` set to the zero address.
     * Requirements
     * - `to` cannot be the zero address.

```js
function mint(address account, uint256 amount) public nonpayable onlyContractOwner 
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| account | address |  | 
| amount | uint256 |  | 

### _mint

```js
function _mint(address account, uint256 amount) internal nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| account | address |  | 
| amount | uint256 |  | 

### _burn

Destroys `amount` tokens from `account`, reducing the
total supply.
     * Emits a {Transfer} event with `to` set to the zero address.
     * Requirements
     * - `account` cannot be the zero address.
- `account` must have at least `amount` tokens.

```js
function _burn(address account, uint256 amount) internal nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| account | address |  | 
| amount | uint256 |  | 

### _approve

Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     * This is internal function is equivalent to `approve`, and can be used to
e.g. set automatic allowances for certain subsystems, etc.
     * Emits an {Approval} event.
     * Requirements:
     * - `owner` cannot be the zero address.
- `spender` cannot be the zero address.

```js
function _approve(address owner, address spender, uint256 amount) internal nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| owner | address |  | 
| spender | address |  | 
| amount | uint256 |  | 

### _burnFrom

Destroys `amount` tokens from `account`.`amount` is then deducted
from the caller's allowance.
     * See {_burn} and {_approve}.

```js
function _burnFrom(address account, uint256 amount) internal nonpayable
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| account | address |  | 
| amount | uint256 |  | 

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
