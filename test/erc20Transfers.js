const Agreement = artifacts.require('AgreementMock');
const FraFactory = artifacts.require('FraFactory');
const ERC20Token = artifacts.require('SimpleErc20Token');
const Config = artifacts.require('ConfigMock');
const Reverter = require('./helpers/reverter');
const {assertReverts} = require('./helpers/assertThrows');
const BigNumber = require('bignumber.js');

const toBN = (num) => {
  return new BigNumber(num);
};

const fromPercentToRey = (num) => {
  return (toBN(num).times((toBN(10).pow(toBN(25))))).plus((toBN(10).pow(toBN(27))));
};

contract('erc20 Transfers', async (accounts) => {
  const reverter = new Reverter(web3);

  let configContract;
  let agreement;
  let fraFactory;
  let daiErc20;
  let erc20;

  const OWNER = accounts[0];
  const BORROWER = accounts[1];
  const LENDER = accounts[2];
  const NOBODY = accounts[3];
  const ADDRESS_NULL = '0x0000000000000000000000000000000000000000';
  const ETH_A = '0x4554482d41000000000000000000000000000000000000000000000000000000';

  before('setup', async () => {
    agreement = await Agreement.new({from: OWNER});
    configContract = await Config.new();
    fraFactory = await FraFactory.new(agreement.address, configContract.address);

    daiErc20 = await ERC20Token.new();
    await agreement.setMcdDaiAddrMock(daiErc20.address);

    erc20 = await ERC20Token.new();
    await configContract.setErc20collToken(erc20.address);
    await configContract
    .setGeneral(1440, 60, 2, 100, toBN(100).times(toBN(10).pow(toBN(18))), 86400, 31536000, 10);

    await reverter.snapshot();
  });

  afterEach('revert', reverter.revert);

  describe('checking erc20 collateral transfering ininitAgreementERC20()', async () => {
    it('should be possible to init agreement on erc20 token', async () => {
      await erc20.mint(BORROWER, 2000);
      await erc20.approve(fraFactory.address, 2000, {from: BORROWER});

      await fraFactory.initAgreementERC20(2000, 1000, 90000, fromPercentToRey(3),
        ETH_A, {from: BORROWER});

      assert.notEqual(await fraFactory.agreementList.call(0), ADDRESS_NULL);

      const localAgreement = await Agreement.at(await fraFactory.agreementList.call(0));

      assert.equal(await localAgreement.borrower.call({from: NOBODY}), BORROWER);
      assert.equal(await localAgreement.collateralAmount.call({from: NOBODY}), 2000);
    });

    it('should be possible to initialize with bigger allovance', async () => {
      await erc20.mint(BORROWER, 2000);
      await erc20.approve(fraFactory.address, 3000, {from: BORROWER});

      await fraFactory.initAgreementERC20(2000, 1000, 90000, fromPercentToRey(3),
        ETH_A, {from: BORROWER});

      assert.notEqual(await fraFactory.agreementList.call(0), ADDRESS_NULL);

      const localAgreement = await Agreement.at(await fraFactory.agreementList.call(0));

      assert.equal(await localAgreement.borrower.call({from: NOBODY}), BORROWER);
      assert.equal(await localAgreement.collateralAmount.call({from: NOBODY}), 2000);
    });

    it('should not be possible to initialize without allovance', async () => {
      await erc20.mint(BORROWER, 2000);

      await assertReverts(fraFactory.initAgreementERC20(2000, 1000, 90000, fromPercentToRey(3),
        ETH_A, {from: BORROWER}));
    });

    it('should not be possible to initialize with less allovance', async () => {
      await erc20.mint(BORROWER, 2000);
      await erc20.approve(fraFactory.address, 1999, {from: BORROWER});

      await assertReverts(fraFactory.initAgreementERC20(2000, 1000, 90000, 3,
        ETH_A, {from: BORROWER}));
    });
  });

  describe('checking erc20 collateral transfering matchAgreement()', async () => {
    // Share with Tanya
    // it('dai tokens should be taken from lender balance and added to agreement with valid allowance', async () => {
    //   await daiErc20.mint(LENDER, 150);

    //   await erc20.mint(BORROWER, 150);
    //   await erc20.approve(fraFactory.address, 150, {from: BORROWER});

    //   await fraFactory.initAgreementERC20(150, 150, 90000, fromPercentToRey(3),
    //     ETH_A, {from: BORROWER});

    //   const localAgreement = await Agreement.at(await fraFactory.agreementList.call(0));
    //   await localAgreement.setMcdDaiAddrMock(daiErc20.address);
    //   await daiErc20.approve(localAgreement.address, 150, {from: LENDER});

    //   await fraFactory.approveAgreement(localAgreement.address);
    //   await localAgreement.matchAgreement({from: LENDER});

    //   assert.equal((await daiErc20.balanceOf.call(LENDER)).toNumber(), 0);
    //   assert.equal((await daiErc20.balanceOf.call(localAgreement.address)).toNumber(), 150);
    // });

    it('dai tokens should be taken from lender balance and added to agreement with valid allowance', async () => {
      await daiErc20.mint(LENDER, 2000);

      await fraFactory.initAgreementETH(1005, 90000, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement = await Agreement.at(await fraFactory.agreementList.call(0));
      await localAgreement.setMcdDaiAddrMock(daiErc20.address);
      await daiErc20.approve(localAgreement.address, 2000, {from: LENDER});

      await fraFactory.approveAgreement(localAgreement.address);
      await localAgreement.matchAgreement({from: LENDER});

      assert.equal((await daiErc20.balanceOf.call(LENDER)).toNumber(), 995);
      assert.equal((await daiErc20.balanceOf.call(localAgreement.address)).toNumber(), 1005);
    });
  });
});
