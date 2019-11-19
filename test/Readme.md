`npm install` - install all modules listed as dependencies in package.json

`npm run test-local` starts ganache-cli and runs all main tests locally. 

Interaction with maker dao constacts should be run in kovan network:
You need an address in Kovan test Ethereum network with access to it and some ETH on it.
Next in the root project folder you need to create '.env' file and put there next data: 

INFURA_API_KEY=<Your infura api key here>

MNENOMIC=<Your mnenomic phrase of the wallet in kovan network here>

You can get Infura api key on the https://infura.io/ . For getting api key registration is needed. After you need to create a new project on kovan network and you will get an Infura api key. Basically Infura it is service that provides an Ethereum node.

`npm run test-mcdWrapper` runs tesing interaction with maker dao contracts in kovan network