const Agreement = artifacts.require('AgreementMock');
const FraFactory = artifacts.require('FraFactory');
const Config = artifacts.require('Config');
const Reverter = require('./helpers/reverter');
const {assertReverts} = require('./helpers/assertThrows')
const BigNumber = require('bignumber.js');

contract('FraFactory', async (accounts) => {
  const reverter = new Reverter(web3);

  let configContract;
  let agreement;
  let fraFactory;

  const OWNER = accounts[0];
  const BORROWER = accounts[1];
  const LENDER = accounts[2];
  const NOBODY = accounts[3];
  const ETH_A = '0x4554482d41000000000000000000000000000000000000000000000000000000';
  const WRONG_COLLATERAL = '0x0000000000000000000000000000000000000000000000000000000000000000'

  const toBN = (num) => {
    return new BigNumber(num);
  }

  before('setup', async () => {
    agreement = await Agreement.new();
    configContract = await Config.new();
    fraFactory = await FraFactory.new(agreement.address, configContract.address);

    await reverter.snapshot();
  });

  afterEach('revert', reverter.revert);

  describe('setAgreementImpl()', async () => {
    it('should be possible to set agreement implementation by contract owner', async () => {
      await fraFactory.setAgreementImpl(accounts[0]);
      assert.equal(await fraFactory.agreementImpl.call(), accounts[0]);

      await fraFactory.setAgreementImpl(agreement.address);
      assert.equal(await fraFactory.agreementImpl.call(), agreement.address);
    })

    it('should not be possible to set agreement implementation by contract not a owner', async () => {
      await assertReverts(fraFactory.setAgreementImpl(accounts[0], {from: NOBODY}));
      assert(await fraFactory.agreementImpl.call(), agreement.address);
    })
  })

  describe('initAgreementETH()', async () => {
    it.only('should be possible to init agreement on ETH with valid values from borrower', async () => {
      const result = await fraFactory.initAgreementETH(300000, 90000, 3, 
        ETH_A, {from: BORROWER, value: 2000});

      const agreementProxyAddr = await fraFactory.initAgreementETH.call(300000, 90000, 3, 
        ETH_A, {from: BORROWER, value: 2000});

      assert.equal((await fraFactory.agreements.call(BORROWER, 0)), agreementProxyAddr);
    })
  })
});
