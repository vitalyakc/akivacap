const Agreement = artifacts.require("Agreement");

module.exports = function(deployer) {
  deployer.deploy(Agreement);
};
