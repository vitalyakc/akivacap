# Set up dependencies

`npm install` - install all modules listed as dependencies in package.json

# Local test for main functionality

`npm run test-local` starts ganache-cli and runs all main tests locally. 


# Maker dao interaction tests in Kovan network

Interaction with maker dao contracts should be run in kovan network:
You need an address in Kovan test Ethereum network with access to it and some ETH on it.
Next in the root project folder you need to create `.env` (copy paste `.env.example`) file and put there following data: 

`NFURA_API_KEY=<Your infura api key here>`

`MNEMONIC=<Your mnenomic phrase of the wallet in kovan network here>`

You can get Infura api key on the https://infura.io/ . For getting api key registration is needed. After you need to create a new project on kovan network and you will get an Infura api key. Basically Infura is a service that provides an Ethereum node.

`npm run test-mcdWrapper` runs tesing interaction with maker dao contracts in kovan network
