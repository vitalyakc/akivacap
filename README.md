# FRA
This repository contains the core smart contract code for Forward Rate Agreement hedging Dai Savings Rate. 

# Core Contracts

## FraFactory

Is main system contracts for deploying and managing Agreement contracts. The deployer of FraFactory is owner and able to init new Agreementreject, approve, update function of Agreement contracts.

## Agreement

Agreement.sol is implementation responsible for forward rate agreement main logic. Should be deployed only once
