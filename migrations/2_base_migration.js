var Config = artifacts.require("Config");
var Agreement = artifacts.require("Agreement");
var FraFactory = artifacts.require("FraFactory");

module.exports = function (deployer, network) {
    if (network == 'kovandeploy') {
        deployer.then(async () => {
            await deployer.deploy(Config)
            await deployer.deploy(Agreement)
            
            FraFactoryInst = await deployer.deploy(FraFactory, Agreement.address, Config.address)

            const admins = process.env.ADMINS.split(',');
            for(var i = 0; i < admins.length; i++) {
                await FraFactoryInst.appointAdmin(admins[i]);
            }
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