`according to 0.2.17th MCD CDP release`

# FRA 
This repository contains the core smart contract code for Forward Rate Agreement hedging Dai Savings Rate. 

# Core Contracts

## FraFactory

`FraFactory.sol` is main system contracts for deploying and managing Agreement contracts. The deployer of FraFactory is owner and able to init new Agreement, call reject/approve/update functions of Agreement contracts.

- `initAgreementETH` - Requests agreement on ETH collateralType
- `initAgreementERC20` - Requests agreement on ERC-20 collateralType
- `setAgreementImpl` - Set the new agreement implememntation adresss
- `setConfigAddr` - Set the new config adresss
- `approveAgreement` -  Makes the specific agreement valid
- `batchApproveAgreements` - Multi approve
- `rejectAgreement` - Reject specific agreement
- `batchRejectAgreements` - Multi reject
- `autoRejectAgreements` - Function for cron autoreject (close agreements if matchLimit or approveLimit from Config contract expired)
- `updateAgreement` - Update the state of specific agreement
- `updateAgreements` - Update the states of all agreemnets
- `batchUpdateAgreements` -Update state of exact agreements
- `removeAgreement` - Remove agreement from list, doesn't affect real agreement contract, just removes handle control
- `transferAgreementOwnership` - transfer agreement ownership to Fra Factory owner (admin)
- `getAgreementList` - Returns a full list of existing agreements

## UpgradeabilityProxy
`UpgradeabilityProxy.sol` is proxy acts as storage for Agreement. It delegates calls to Agreement implementation contract

## Agreement

`Agreement.sol` is implementation responsible for main logic of forward rate agreement. Should be deployed only once as logic, and `UpgradeabilityProxy.sol` is deployed every time when new agreement is inited. `UpgradeabilityProxy` acts as storage for each Agreement.

###The main storage variables:
- `status` - current status of agreement. Can be:
    - 1 - STATUS_PENDING // 0001
    - 2 - STATUS_OPEN // 0010
    - 3 - STATUS_ACTIVE // 0011
    - 8 - STATUS_CLOSED // 1000
    - 9 - STATUS_ENDED // 1001
    - 10 - STATUS_LIQUIDATED // 1010
    - 11 - STATUS_BLOCKED // 1011
    - 12 - STATUS_CANCELED // 1100
    
    in all closed statused the forth bit = 1, binary "AND" with STATUS_CLOSED is used to determine whether the agreement is closed
- `borrower` - borrower's address
- `lender` - lender's address
- `collateralType` - type of collateral (ETH-A, BAT-A), should be passed as bytes32 
- `collateralAmount` (in *wad* units) - value of borrower's collateral amount put into the contract as collateral or approved to transferFrom
- `debtValue` (in *wad* units) - value of debt
- `interestRate` (in *ray* units) - percent of interest rate, should be passed like RAY
- `cdpId` - CDP id (Vault ID) of multi-collateral dai system
- `duration` - number of seconds which agreement should be terminated after

###Datetime variables:
- `initialDate` 
- `approveDate`
- `matchDate`
- `expireDate`
- `closeDate`
- `lastCheckTime`

###Forward rate agreement current results
- `delta` (in *rad* units) - signed integer, if < 0 - shows borrowers Fra debt, if > 0 shows dai amount waiting for injection (waiting of excess of injectionThreshold which is set during agrement init (is defined in Config contract)). Every agreement update `delta` is increased or decreased according to difference between current `dsr` from Multi Collateral Dai `Pot.sol` % and fixed `interestRate` %. After injection `delta` resets to zero
- `deltaCommon` (in *rad* units) - shows common profit for lender (< 0) or borrower (> 0). Every agreement update `delta` is increased or decreased according to difference between current `dsr` from Multi Collateral Dai `Pot.sol` % and fixed `interestRate` %. Unlike to `delta`, `deltaCommon` doesn't reset to zero after injection.

###Basic agreement lifecycle
- borrower calls initAgreement via `FraFactory`. `FraFactory` deploys new storage for Agreement.
- admin approves or rejects Agreement via `FraFactory`
- lender matches the exact agreement. During match - the new cdp in MCD CDP system is created, collateral is locked and Dai is drawn. Lenders dai is locked to DSR contract (`Pot.sol`)
- every day the cron runs 
    - `autoRejectAgreements` - closes agreements are not approved or matched during defined in config period of time
    - `updateAgreements` - update the state of all active agreements
- if agreement is expired it is terminated
- if agreement CR is less than MCR - it is liquidated
- during termination\liquidation the dai locked from dsr + borrowersFraDebt if any is refunded to lender, cdp ownership (if borrowersFradebt is zero or settled) is transferred to borrower

###Saving difference

The savings difference (in *rad* units) is calculated according to formula:

`savingsDifference = debtValue * (currentDsrAnnual - interestRate) * timeInterval / YEAR_SECS`

where `currentDsrAnnual` is annual dsr % ans is calculated by formula:

`currentDsrAnnual = (dsr / ONE)  ^ YEAR_SECS`

where `dsr` is dsr value from `Pot.sol` in mcd cdp system

###Units

Dai has three different numerical units: `wad`, `ray` and `rad`

- `wad`: fixed point decimal with 18 decimals (for basic quantities, e.g. balances)
- `ray`: fixed point decimal with 27 decimals (for precise quantites, e.g. ratios)
- `rad`: fixed point decimal with 45 decimals (result of integer multiplication with a `wad` and a `ray`)

`rad` is a new unit exists to prevent precision loss.

The base of `ray` is `ONE = 10 ** 27`.

A good explanation of fixed point arithmetic can be found at [Wikipedia](https://en.wikipedia.org/wiki/Fixed-point_arithmetic).

## McdWrapper
`McdWrapper.sol` acts as agreement multicollateral dai wrapper for maker dao system interaction
