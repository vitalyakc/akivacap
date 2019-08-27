const McdWrapper = artifacts.require("McdWrapper");

module.exports = function(deployer) {
  deployer.deploy(McdWrapper);
};
