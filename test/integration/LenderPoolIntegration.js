const Agreement = artifacts.require('Agreement');
const FraFactory = artifacts.require('FraFactory');
const Config = artifacts.require('Config');
const BigNumber = require('bignumber.js');
const ERC20Token = artifacts.require('IERC20');
const LenderPool = artifacts.require('LenderPool');

const toBN = (num) => {
  return new BigNumber(num);
};

const fromPercentToRey = (num) => {
  return (toBN(num).times((toBN(10).pow(toBN(25))))).plus((toBN(10).pow(toBN(27))));
};

contract('IntegrationPool', async (accounts) => {
  let configContract;
  let agreement;
  let fraFactory;
  let lenderPool;
  let daiToken;

  const daiAddress17Release = '0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa';

  const OWNER = accounts[0];
  const BORROWER = accounts[1];
  const LENDER = accounts[2];
  const ETH_A = '0x4554482d41000000000000000000000000000000000000000000000000000000';

  before('setup', async () => {
    agreement = await Agreement.new();
    configContract = await Config.new();
    fraFactory = await FraFactory.new(agreement.address, configContract.address);
    await configContract.setGeneral(1440, 60, 2, 100,
      toBN(100).times(toBN(10).pow(toBN(18))), 1, 31536000, 10);

    daiToken = await ERC20Token.at(daiAddress17Release);
  });

  describe('Agreement lifesycle complete flow with pooling lender system integration test', async () => {
    it('', async () => {
      const localAgreementAddress =
      await fraFactory.initAgreementETH.call(toBN(20000000000000000000), 90, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: toBN(250000000000000000)});

      await fraFactory.initAgreementETH(toBN(20000000000000000000),
        120, fromPercentToRey(3), ETH_A, {from: BORROWER, value: toBN(250000000000000000)});

      console.log('Agreement initialized with address ' + localAgreementAddress);

      await fraFactory.approveAgreement(localAgreementAddress);

      console.log('Agreement approved ');

      lenderPool = await LenderPool.new(localAgreementAddress,
        fromPercentToRey(1), 1, 50000, 1, 20000000000000, {from: LENDER});

      console.log('lenderPool created ' + lenderPool.address);

      await daiToken.approve(lenderPool.address, toBN(10000000000000000000), {from: LENDER});
      await daiToken.approve(lenderPool.address, toBN(10000000000000000000), {from: OWNER});

      const resultDeposited1 = await lenderPool.deposit(toBN(10000000000000000000), {from: LENDER});
      const resultDeposited2 = await lenderPool.deposit(toBN(10000000000000000000), {from: OWNER});

      assert.equal(resultDeposited1.logs[0].event, 'Deposited');
      assert.equal(resultDeposited2.logs[0].event, 'Deposited');

      console.log('user1 and user2 deposited to the pool contract');
      assert.equal((await lenderPool.daiTotal()).toString(), '20000000000000000000');

      const resultMatched = await lenderPool.matchAgreement({from: LENDER});

      assert.equal(resultMatched.logs[1].event, 'MatchedAgreement');
      console.log('Pool matched to agreement');

      const localAgreement = await Agreement.at(localAgreementAddress);

      while (await localAgreement.status() < 4) {
        await fraFactory.updateAgreement(localAgreementAddress);
        console.log('Agreement updated');
      }

      const resultRefunded = await lenderPool.refundFromAgreement({from: LENDER});

      assert.equal(resultRefunded.logs[1].event, 'RefundedFromAgreement');
      console.log('Amount refunded to pool is ' + (await lenderPool.daiWithSavings()).toString());

      const resultWithdrawn1 = await lenderPool.withdraw({from: LENDER});
      const resultWithdrawn2 = await lenderPool.withdraw({from: OWNER});

      assert.isTrue(toBN(resultWithdrawn1.logs[0].args
      .amountWithSavings) > toBN(10000000000000000000));
      assert.isTrue(toBN(resultWithdrawn2.logs[0].args
      .amountWithSavings) > toBN(10000000000000000000));

      assert.equal(resultWithdrawn1.logs[0].event, 'Withdrawn');
      assert.equal(resultWithdrawn1.logs[0].args.caller, LENDER);
      assert.equal(resultWithdrawn1.logs[0].args.pooler, LENDER);
      assert.equal(resultWithdrawn1.logs[0].args.amount, '10000000000000000000');
      console.log(resultWithdrawn1.logs[0].args
      .amountWithSavings + ' tokens where taken from contract by user1');

      assert.equal(resultWithdrawn2.logs[0].event, 'Withdrawn');
      assert.equal(resultWithdrawn2.logs[0].args.caller, OWNER);
      assert.equal(resultWithdrawn2.logs[0].args.pooler, OWNER);
      assert.equal(resultWithdrawn2.logs[0].args.amount, '10000000000000000000');
      console.log(resultWithdrawn2.logs[0].args
      .amountWithSavings + ' tokens where taken from contract by user2');
    });
  });
});
