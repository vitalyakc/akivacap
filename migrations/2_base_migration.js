var Config = artifacts.require("Config");
var Agreement = artifacts.require("Agreement");
var FraFactory = artifacts.require("FraFactory");

module.exports = function (deployer) {
    deployer.then(async () => {
        await deployer.deploy(Config)
        await deployer.deploy(Agreement)
        await deployer.deploy(FraFactory, Agreement.address, Config.address)
    })
}