var Config = artifacts.require("Config");
var Agreement = artifacts.require("Agreement");
var FraFactory = artifacts.require("FraFactory");

module.exports = function (deployer, network) {
    if (/^kovan/.test(network)) { // == 'kovandeploy') {
        deployer.then(async () => {
            console.log("Deploying Config")
            await deployer.deploy(Config)
            console.log("Deploying Agreement")
            await deployer.deploy(Agreement)
            
            FraFactoryInst = await deployer.deploy(FraFactory, Agreement.address, Config.address)

            const admins = process.env.ADMINS.split(',');
            for(var i = 0; i < admins.length; i++) {
                await FraFactoryInst.appointAdmin(admins[i]);
            }
        })
        .catch(err => {
            console.log("Error in base_migration:")
            console.log(err)
        })
    }

    if (network == 'mainnet') {
        deployer.then(async () => {
     
            // todo replace 
     
            await deployer.deploy(Config)
            await deployer.deploy(Agreement)
            
            FraFactoryInst = await deployer.deploy(FraFactory, Agreement.address, Config.address)

            const admins = process.env.ADMINS.split(',');
            for(var i = 0; i < admins.length; i++) {
                await FraFactoryInst.appointAdmin(admins[i]);
            }
        })
    }
}