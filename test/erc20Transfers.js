const Agreement = artifacts.require('AgreementMock');
const FraFactory = artifacts.require('FraFactory');
const ERC20Token = artifacts.require('SimpleErc20Token');
const Config = artifacts.require('ConfigMock');
const Reverter = require('./helpers/reverter');
const {assertReverts} = require('./helpers/assertThrows')
const BigNumber = require('bignumber.js');

contract('erc20 Transfers', async (accounts) => {
  const reverter = new Reverter(web3);

  let configContract;
  let agreement;
  let fraFactory;

  const OWNER = accounts[0];
  const BORROWER = accounts[1];
  const LENDER = accounts[2];
  const NOBODY = accounts[3];
  const ADDRESS_NULL = '0x0000000000000000000000000000000000000000';
  const ETH_A = '0x4554482d41000000000000000000000000000000000000000000000000000000';
  const WRONG_COLLATERAL = '0x0000000000000000000000000000000000000000000000000000000000000000'

  const toBN = (num) => {
    return new BigNumber(num);
  }

  before('setup', async () => {
    agreement = await Agreement.new({from: OWNER});    
    configContract = await Config.new();
    fraFactory = await FraFactory.new(agreement.address, configContract.address);

    await reverter.snapshot();
  });

  afterEach('revert', reverter.revert);
  
  describe('initAgreementERC20()', async () => {
    let erc20;
    beforeEach('setup test erc20 token', async () => {
      erc20 = await ERC20Token.new();
      await configContract.setErc20collToken(erc20.address);
    })

    it.only('should be possible to init agreement on erc20 token', async () => {
      await erc20.mint(BORROWER, 2000);
      await erc20.approve(fraFactory.address, 2000, {from: BORROWER});
      
      await fraFactory.initAgreementERC20(2000, 1000, 90000, 3, 
        ETH_A, {from: BORROWER})

      assert.equal(await fraFactory.agreements.call(BORROWER, 0), 
      await fraFactory.agreementList.call(0));
      assert.notEqual(await fraFactory.agreements.call(BORROWER, 0), ADDRESS_NULL)

      const localAgreement = await Agreement.at(await fraFactory.agreements.call(BORROWER, 0));

      assert.equal(await localAgreement.borrower.call({from: NOBODY}), BORROWER);
      assert.equal(await localAgreement.collateralAmount.call({from: NOBODY}), 2000);
    })

    // to do
    it('should be possible to initialize with bigger allovance', async () => {

    })

    // to do
    it('should not be possible to initialize without allovance', async () => {

    })

    // to do
    it('should not be possible to initialize with less allovance', async () => {
    })
  })
})