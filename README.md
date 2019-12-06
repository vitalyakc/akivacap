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

## Agreement

`Agreement.sol` is implementation responsible for main logic of forward rate agreement. Should be deployed only once as logic, and `UpgradeabilityProxy.sol` is deployed every time when new agreement is inited. `UpgradeabilityProxy` acts as storage for each Agreement.


## McdWrapper
`McdWrapper.sol` acs as agreement multicollateral dai wrapper for maker dao system interaction
