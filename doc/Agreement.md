## Sūrya's Description Report

### Files Description Table


|  File Name  |  SHA-1 Hash  |
|-------------|--------------|
| contracts/Agreement.sol | 365b9b52c82ed62a69539044345827834201e6e1 |


### Contracts Description Table


|  Contract  |         Type        |       Bases      |                  |                 |
|:----------:|:-------------------:|:----------------:|:----------------:|:---------------:|
|     └      |  **Function Name**  |  **Visibility**  |  **Mutability**  |  **Modifiers**  |
||||||
| **Agreement** | Implementation | IAgreement, ClaimableIni, McdWrapper |||
| └ | initAgreement | Public ❗️ |  💵 | initializer |
| └ | approveAgreement | External ❗️ | 🛑  | onlyContractOwner hasStatus |
| └ | matchAgreement | External ❗️ | 🛑  | hasStatus |
| └ | updateAgreement | External ❗️ | 🛑  | onlyContractOwner hasStatus |
| └ | cancelAgreement | External ❗️ | 🛑  | onlyBorrower beforeStatus |
| └ | rejectAgreement | External ❗️ | 🛑  | onlyContractOwner beforeStatus |
| └ | blockAgreement | External ❗️ | 🛑  | hasStatus onlyContractOwner |
| └ | lockAdditionalCollateral | External ❗️ |  💵 | onlyBorrower beforeStatus |
| └ | withdrawDai | External ❗️ | 🛑  |NO❗️ |
| └ | withdrawCollateral | External ❗️ | 🛑  |NO❗️ |
| └ | withdrawRemainingEth | External ❗️ | 🛑  | hasStatus onlyContractOwner |
| └ | getInfo | External ❗️ |   |NO❗️ |
| └ | getAssets | Public ❗️ |   |NO❗️ |
| └ | isStatus | Public ❗️ |   |NO❗️ |
| └ | isBeforeStatus | Public ❗️ |   |NO❗️ |
| └ | isClosedWithType | Public ❗️ |   |NO❗️ |
| └ | borrowerFraDebt | Public ❗️ |   |NO❗️ |
| └ | checkTimeToCancel | Public ❗️ |   |NO❗️ |
| └ | getCR | Public ❗️ |   |NO❗️ |
| └ | getCRBuffer | Public ❗️ |   |NO❗️ |
| └ | getDaiAddress | Public ❗️ |   |NO❗️ |
| └ | _doStatusSnapshot | Internal 🔒 | 🛑  | |
| └ | _closeAgreement | Internal 🔒 | 🛑  | |
| └ | _updateAgreementState | Public ❗️ | 🛑  |NO❗️ |
| └ | _monitorRisky | Internal 🔒 | 🛑  | |
| └ | _refund | Internal 🔒 | 🛑  | |
| └ | _nextStatus | Internal 🔒 | 🛑  | |
| └ | _switchStatus | Internal 🔒 | 🛑  | |
| └ | _switchStatusClosedWithType | Internal 🔒 | 🛑  | |
| └ | _pushCollateralAsset | Internal 🔒 | 🛑  | |
| └ | _pushDaiAsset | Internal 🔒 | 🛑  | |
| └ | _popCollateralAsset | Internal 🔒 | 🛑  | |
| └ | _popDaiAsset | Internal 🔒 | 🛑  | |
| └ | <Fallback> | External ❗️ |  💵 |NO❗️ |


### Legend

|  Symbol  |  Meaning  |
|:--------:|-----------|
|    🛑    | Function can modify state |
|    💵    | Function is payable |
