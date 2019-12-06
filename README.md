`according to 0.2.17th MCD CDP release`

# FRA 
This repository contains the core smart contract code for Forward Rate Agreement hedging Dai Savings Rate. 

# Core Contracts

## FraFactory

Is main system contracts for deploying and managing Agreement contracts. The deployer of FraFactory is owner and able to init new Agreement, reject, approve, update function of Agreement contracts.

## Agreement

`Agreement.sol` is implementation responsible for main logic of forward rate agreement. Should be deployed only once as logic, and `UpgradeabilityProxy.sol` is deployed every time when new agreement is inited. UpgradeabilityProxy acts as storage for each Agreement.
