# Set up dependencies

`npm install` - install all modules listed as dependencies in package.json

# Local test for main functionality

`npm run test-local` starts ganache-cli and runs all main tests locally. 


# Maker dao interaction tests in Kovan network

Interaction with maker dao contracts should be run in kovan network:
You need 3 addresses in Kovan test Ethereum network with access to it.
Next in the root project folder you need to create `.env` (copy paste `.env.example`) file and put there following data: 

`NFURA_API_KEY=<Your infura api key here>`

`PRIVATEKEY1=<private key>`
`PRIVATEKEY2=<private key>`
`PRIVATEKEY3=<private key>`

Further key-pair to PRIVATEKEY1 will be address1, PRIVATEKEY2 - address2, PRIVATEKEY3 - address3. Order is important.

For successful passing of the integration tests you need to have next amounts of funds on accounts:
address1 - about 4 ETH, and at least 11 dai tokens.
address2 - about 1 eth.
address3 - some ETH and at least 25 dai tokens.
* dai tokens must belong to token contract at address `0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa`.(17th release of dai token)
After all tests passes address2 will contain a lot of dai tokens.

You can get Infura api key on the https://infura.io/ . For getting api key registration is needed. After you need to create a new project on kovan network and you will get an Infura api key. Basically Infura is a service that provides an Ethereum node.

`npm run test-integration` runs tesing interaction with maker dao contracts in kovan network
