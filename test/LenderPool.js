const LenderPool = artifacts.require('LenderPoolMock');
const Reverter = require('./helpers/reverter');
const {assertReverts} = require('./helpers/assertThrows');
const BigNumber = require('bignumber.js');
const setCurrentTime = require('./helpers/ganacheTimeTraveler.js');
const ERC20Token = artifacts.require('SimpleErc20Token');
const truffleAssert = require('truffle-assertions');


const toBN = (num) => {
  return new BigNumber(num);
};

const fromPercentToRay = (num) => {
  return (toBN(num).times((toBN(10).pow(toBN(25))))).plus((toBN(10).pow(toBN(27))));
};

contract('LenderPool', async (accounts) => {
  const reverter = new Reverter(web3);

  let lenderPool;
  let daiTokenMock;

  const OWNER = accounts[0];
  const ADMIN = accounts[1];
  const SOMEBODY = accounts[2];
  const NOBODY = accounts[3];
  const ADDRESS_NULL = '0x0000000000000000000000000000000000000000';
  const TARGET_AGREEMENT_ADDRESS = '0x0000000000000000000000000000000000000001';

  before('setup', async () => {
    lenderPool = await LenderPool.new(TARGET_AGREEMENT_ADDRESS,
      fromPercentToRay(1), 10, 1000000, 500000, 6000000000);
    daiTokenMock = await ERC20Token.new();
    await lenderPool.appointAdmin(ADMIN);

    await lenderPool.setAgreementDebtValue(20000000);
    await lenderPool.setAgreementInterestRate(fromPercentToRay(3));
    await lenderPool.setAgreementDuration(100000);
    await lenderPool.setDaiTokenMock(daiTokenMock.address);

    await setCurrentTime(100);
  });

  beforeEach('snapshot', reverter.snapshot);

  afterEach('revert', reverter.revert);

  describe('creation', async () => {
    it('should set all values correctly during creation', async () => {
      const lenderPoolLocal = await LenderPool.new(TARGET_AGREEMENT_ADDRESS,
        fromPercentToRay(1), 10, 1000000, 500000, 6000000000);

      const result = await truffleAssert.createTransactionResult(lenderPoolLocal,
        lenderPoolLocal.transactionHash);

      assert.equal(await lenderPoolLocal.targetAgreement(), TARGET_AGREEMENT_ADDRESS);
      assert.equal((await lenderPoolLocal.minInterestRate()).toString(),
        1010000000000000000000000000);
      assert.equal((await lenderPoolLocal.minDuration()).toString(), 10);
      assert.equal((await lenderPoolLocal.maxDuration()).toString(), 1000000);
      assert.equal((await lenderPoolLocal.pendingExpireDate()).toString(), 500100);
      assert.equal((await lenderPoolLocal.minDai()).toString(), 6000000000);

      assert.equal(result.logs.length, 5);
      assert.equal(result.logs[2].event, 'AgreementRestrictionsUpdated');
      assert.equal(result.logs[2].args.minInterestRate, 1010000000000000000000000000);
      assert.equal(result.logs[2].args.minDuration, 10);
      assert.equal(result.logs[2].args.maxDuration, 1000000);

      assert.equal(result.logs[3].event, 'PoolRestrictionsUpdated');
      assert.equal(result.logs[3].args.pendingExpireDate, 500100);
      assert.equal(result.logs[3].args.minDai, 6000000000);

      assert.equal(result.logs[4].event, 'TargetAgreementUpdated');
      assert.equal(result.logs[4].args.targetAgreement, TARGET_AGREEMENT_ADDRESS);
    });
  });

  describe('setTargetAgreement()', async () => {
    it('should be possible to setTargetAgreement with valid values from admin', async () => {
      assert.equal(await lenderPool.targetAgreement(), TARGET_AGREEMENT_ADDRESS);

      const result = await lenderPool.setTargetAgreement(SOMEBODY, {from: ADMIN});

      assert.equal(await lenderPool.targetAgreement(), SOMEBODY);
      assert.equal((await lenderPool.daiGoal()).toString(), 20000000);
      assert.equal((await lenderPool.interestRate()).toString(), 1030000000000000000000000000);
      assert.equal((await lenderPool.duration()).toString(), 100000);

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'TargetAgreementUpdated');
      assert.equal(result.logs[0].args.targetAgreement, SOMEBODY);
      assert.equal(result.logs[0].args.daiGoal, 20000000);
      assert.equal(result.logs[0].args.interestRate, 1030000000000000000000000000);
      assert.equal(result.logs[0].args.duration, 100000);
    });

    it('should not be possible to setTargetAgreement with target address equal to zero from admin', async () => {
      assert.equal(await lenderPool.targetAgreement(), TARGET_AGREEMENT_ADDRESS);

      await assertReverts(lenderPool.setTargetAgreement(ADDRESS_NULL, {from: ADMIN}));

      assert.equal(await lenderPool.targetAgreement(), TARGET_AGREEMENT_ADDRESS);
      assert.equal((await lenderPool.daiGoal()).toString(), 20000000);
      assert.equal((await lenderPool.interestRate()).toString(), 1030000000000000000000000000);
      assert.equal((await lenderPool.duration()).toString(), 10000);
    });

    it('should not be possible to setTargetAgreement with daiGola = 0 from admin', async () => {
      await lenderPool.setAgreementDebtValue(0);

      assert.equal(await lenderPool.targetAgreement(), TARGET_AGREEMENT_ADDRESS);

      await assertReverts(lenderPool.setTargetAgreement(SOMEBODY, {from: ADMIN}));

      assert.equal(await lenderPool.targetAgreement(), TARGET_AGREEMENT_ADDRESS);
      assert.equal((await lenderPool.daiGoal()).toString(), 20000000);
      assert.equal((await lenderPool.interestRate()).toString(), 1030000000000000000000000000);
      assert.equal((await lenderPool.duration()).toString(), 10000);
    });

    it('should not be possible to setTargetAgreement with interestRte < minInterestRate from admin', async () => {
      await lenderPool.setAgreementInterestRate('1005000000000000000000000000');

      assert.equal(await lenderPool.targetAgreement(), TARGET_AGREEMENT_ADDRESS);

      await assertReverts(lenderPool.setTargetAgreement(SOMEBODY, {from: ADMIN}));

      assert.equal(await lenderPool.targetAgreement(), TARGET_AGREEMENT_ADDRESS);
      assert.equal((await lenderPool.daiGoal()).toString(), 20000000);
      assert.equal((await lenderPool.interestRate()).toString(), 1030000000000000000000000000);
      assert.equal((await lenderPool.duration()).toString(), 10000);
    });

    it('should not be possible to setTargetAgreement with duration < minDuration from admin', async () => {
      await lenderPool.setAgreementDuration(5);

      assert.equal(await lenderPool.targetAgreement(), TARGET_AGREEMENT_ADDRESS);

      await assertReverts(lenderPool.setTargetAgreement(SOMEBODY, {from: ADMIN}));

      assert.equal(await lenderPool.targetAgreement(), TARGET_AGREEMENT_ADDRESS);
      assert.equal((await lenderPool.daiGoal()).toString(), 20000000);
      assert.equal((await lenderPool.interestRate()).toString(), 1030000000000000000000000000);
      assert.equal((await lenderPool.duration()).toString(), 10000);
    });

    it('should not be possible to setTargetAgreement with duration > maxDuration from admin', async () => {
      await lenderPool.setAgreementDuration(1000001);

      assert.equal(await lenderPool.targetAgreement(), TARGET_AGREEMENT_ADDRESS);

      await assertReverts(lenderPool.setTargetAgreement(SOMEBODY, {from: ADMIN}));

      assert.equal(await lenderPool.targetAgreement(), TARGET_AGREEMENT_ADDRESS);
      assert.equal((await lenderPool.daiGoal()).toString(), 20000000);
      assert.equal((await lenderPool.interestRate()).toString(), 1030000000000000000000000000);
      assert.equal((await lenderPool.duration()).toString(), 10000);
    });

    it('should not be possible to setTargetAgreement with duration > maxDuration from admin', async () => {
      await lenderPool.setAgreementDuration(1000001);

      assert.equal(await lenderPool.targetAgreement(), TARGET_AGREEMENT_ADDRESS);

      await assertReverts(lenderPool.setTargetAgreement(SOMEBODY, {from: ADMIN}));

      assert.equal(await lenderPool.targetAgreement(), TARGET_AGREEMENT_ADDRESS);
      assert.equal((await lenderPool.daiGoal()).toString(), 20000000);
      assert.equal((await lenderPool.interestRate()).toString(), 1030000000000000000000000000);
      assert.equal((await lenderPool.duration()).toString(), 10000);
    });

    it('should not be possible to setTargetAgreement with agreemnet stauts in not open from admin', async () => {
      await lenderPool.setAgreementStatus(false);

      assert.equal(await lenderPool.targetAgreement(), TARGET_AGREEMENT_ADDRESS);

      await assertReverts(lenderPool.setTargetAgreement(SOMEBODY, {from: ADMIN}));

      assert.equal(await lenderPool.targetAgreement(), TARGET_AGREEMENT_ADDRESS);
      assert.equal((await lenderPool.daiGoal()).toString(), 20000000);
      assert.equal((await lenderPool.interestRate()).toString(), 1030000000000000000000000000);
      assert.equal((await lenderPool.duration()).toString(), 10000);
    });

    it('should not be possible to setTargetAgreement with valid values not from admin', async () => {
      assert.equal(await lenderPool.targetAgreement(), TARGET_AGREEMENT_ADDRESS);

      await assertReverts(lenderPool.setTargetAgreement(SOMEBODY, {from: NOBODY}));

      assert.equal(await lenderPool.targetAgreement(), TARGET_AGREEMENT_ADDRESS);
      assert.equal((await lenderPool.daiGoal()).toString(), 20000000);
      assert.equal((await lenderPool.interestRate()).toString(), 1030000000000000000000000000);
      assert.equal((await lenderPool.duration()).toString(), 10000);
    });
  });

  describe('deposit()', async () => {
    it('should be possible to deposit with amount > minAmount and amount < remaining from somebody', async () => {
      await lenderPool.setAgreementDebtValue(toBN(900000000000));
      await lenderPool.setTargetAgreement(TARGET_AGREEMENT_ADDRESS, {from: ADMIN});

      await daiTokenMock.mint(SOMEBODY, 9000000000);
      await daiTokenMock.approve(lenderPool.address, 9000000000, {from: SOMEBODY});

      assert.equal((await daiTokenMock.balanceOf(SOMEBODY)).toString(), 9000000000);

      const result = await lenderPool.deposit(9000000000, {from: SOMEBODY});

      assert.equal((await daiTokenMock.balanceOf(SOMEBODY)).toString(), 0);
      assert.equal((await lenderPool.daiTotal()).toString(), 9000000000);
      assert.equal((await lenderPool.balanceOf(SOMEBODY)).toString(), 9000000000);
      assert.equal((await daiTokenMock.balanceOf(lenderPool.address)).toString(), 9000000000);

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'Deposited');
      assert.equal(result.logs[0].args.pooler, SOMEBODY);
      assert.equal(result.logs[0].args.amount, 9000000000);
    });

    it('should be possible to deposit with amount < minAmount but amount = remaining from somebody', async () => {
      await lenderPool.setAgreementDebtValue(9000000001);
      await lenderPool.setTargetAgreement(TARGET_AGREEMENT_ADDRESS, {from: ADMIN});
      await daiTokenMock.mint(NOBODY, 9000000000);
      await daiTokenMock.approve(lenderPool.address, 9000000000, {from: NOBODY});

      await lenderPool.deposit(9000000000, {from: NOBODY});

      assert.equal((await lenderPool.daiTotal()).toString(), 9000000000);
      assert.equal((await lenderPool.balanceOf(NOBODY)).toString(), 9000000000);
      assert.equal((await daiTokenMock.balanceOf(lenderPool.address)).toString(), 9000000000);

      await daiTokenMock.mint(SOMEBODY, 1);

      await daiTokenMock.approve(lenderPool.address, 1, {from: SOMEBODY});

      assert.equal((await daiTokenMock.balanceOf(SOMEBODY)).toString(), 1);

      const result = await lenderPool.deposit(1, {from: SOMEBODY});

      assert.equal((await daiTokenMock.balanceOf(SOMEBODY)).toString(), 0);
      assert.equal((await lenderPool.daiTotal()).toString(), 9000000001);
      assert.equal((await lenderPool.balanceOf(SOMEBODY)).toString(), 1);
      assert.equal((await daiTokenMock.balanceOf(lenderPool.address)).toString(), 9000000001);

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'Deposited');
      assert.equal(result.logs[0].args.pooler, SOMEBODY);
      assert.equal(result.logs[0].args.amount, 1);
    });

    it('should be possible to deposit with amount < minAmount but amount > remaining from somebody', async () => {
      await lenderPool.setAgreementDebtValue(9000000001);
      await lenderPool.setTargetAgreement(TARGET_AGREEMENT_ADDRESS, {from: ADMIN});
      await daiTokenMock.mint(NOBODY, 9000000000);
      await daiTokenMock.approve(lenderPool.address, 9000000000, {from: NOBODY});

      await lenderPool.deposit(9000000000, {from: NOBODY});

      assert.equal((await lenderPool.daiTotal()).toString(), 9000000000);
      assert.equal((await lenderPool.balanceOf(NOBODY)).toString(), 9000000000);
      assert.equal((await daiTokenMock.balanceOf(lenderPool.address)).toString(), 9000000000);

      await daiTokenMock.mint(SOMEBODY, 2);

      await daiTokenMock.approve(lenderPool.address, 2, {from: SOMEBODY});

      assert.equal((await daiTokenMock.balanceOf(SOMEBODY)).toString(), 2);

      const result = await lenderPool.deposit(2, {from: SOMEBODY});

      assert.equal((await lenderPool.daiTotal()).toString(), 9000000001);
      assert.equal((await lenderPool.balanceOf(SOMEBODY)).toString(), 1);
      assert.equal((await daiTokenMock.balanceOf(lenderPool.address)).toString(), 9000000001);
      assert.equal((await daiTokenMock.balanceOf(SOMEBODY)).toString(), 1);

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'Deposited');
      assert.equal(result.logs[0].args.pooler, SOMEBODY);
      assert.equal(result.logs[0].args.amount, 1);
    });

    it('should be possible to deposit with amount > minAmount and amount = remaining from somebody', async () => {
      await lenderPool.setAgreementDebtValue(90000000000);
      await lenderPool.setTargetAgreement(TARGET_AGREEMENT_ADDRESS, {from: ADMIN});
      await daiTokenMock.mint(NOBODY, 40000000000);
      await daiTokenMock.approve(lenderPool.address, 40000000000, {from: NOBODY});

      await lenderPool.deposit(40000000000, {from: NOBODY});

      assert.equal((await lenderPool.daiTotal()).toString(), 40000000000);
      assert.equal((await lenderPool.balanceOf(NOBODY)).toString(), 40000000000);
      assert.equal((await daiTokenMock.balanceOf(lenderPool.address)).toString(), 40000000000);

      await daiTokenMock.mint(SOMEBODY, 50000000000);

      await daiTokenMock.approve(lenderPool.address, 50000000000, {from: SOMEBODY});

      assert.equal((await daiTokenMock.balanceOf(SOMEBODY)).toString(), 50000000000);

      const result = await lenderPool.deposit(50000000000, {from: SOMEBODY});

      assert.equal((await daiTokenMock.balanceOf(SOMEBODY)).toString(), 0);
      assert.equal((await lenderPool.daiTotal()).toString(), 90000000000);
      assert.equal((await lenderPool.balanceOf(SOMEBODY)).toString(), 50000000000);
      assert.equal((await daiTokenMock.balanceOf(lenderPool.address)).toString(), 90000000000);

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'Deposited');
      assert.equal(result.logs[0].args.pooler, SOMEBODY);
      assert.equal(result.logs[0].args.amount, 50000000000);
    });

    it('should be possible to deposit with amount > minAmount and amount = remaining from somebody', async () => {
      await lenderPool.setAgreementDebtValue(90000000000);
      await lenderPool.setTargetAgreement(TARGET_AGREEMENT_ADDRESS, {from: ADMIN});
      await daiTokenMock.mint(NOBODY, 40000000000);
      await daiTokenMock.approve(lenderPool.address, 40000000000, {from: NOBODY});

      await lenderPool.deposit(40000000000, {from: NOBODY});

      assert.equal((await lenderPool.daiTotal()).toString(), 40000000000);
      assert.equal((await lenderPool.balanceOf(NOBODY)).toString(), 40000000000);
      assert.equal((await daiTokenMock.balanceOf(lenderPool.address)).toString(), 40000000000);

      await daiTokenMock.mint(SOMEBODY, 60000000000);

      await daiTokenMock.approve(lenderPool.address, 60000000000, {from: SOMEBODY});

      assert.equal((await daiTokenMock.balanceOf(SOMEBODY)).toString(), 60000000000);

      const result = await lenderPool.deposit(60000000000, {from: SOMEBODY});

      assert.equal((await daiTokenMock.balanceOf(SOMEBODY)).toString(), 10000000000);
      assert.equal((await lenderPool.daiTotal()).toString(), 90000000000);
      assert.equal((await lenderPool.balanceOf(SOMEBODY)).toString(), 50000000000);
      assert.equal((await daiTokenMock.balanceOf(lenderPool.address)).toString(), 90000000000);

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'Deposited');
      assert.equal(result.logs[0].args.pooler, SOMEBODY);
      assert.equal(result.logs[0].args.amount, 50000000000);
    });

    it('should not be possible to deposit with amount < minAmount and amount < remaining from somebody', async () => {
      await lenderPool.setAgreementDebtValue(toBN(900000000000));
      await lenderPool.setTargetAgreement(TARGET_AGREEMENT_ADDRESS, {from: ADMIN});

      await daiTokenMock.mint(SOMEBODY, 1);
      await daiTokenMock.approve(lenderPool.address, 1, {from: SOMEBODY});

      assert.equal((await daiTokenMock.balanceOf(SOMEBODY)).toString(), 1);

      await assertReverts(lenderPool.deposit(1, {from: SOMEBODY}));

      assert.equal((await daiTokenMock.balanceOf(SOMEBODY)).toString(), 1);
      assert.equal((await lenderPool.daiTotal()).toString(), 0);
      assert.equal((await lenderPool.balanceOf(SOMEBODY)).toString(), 0);
      assert.equal((await daiTokenMock.balanceOf(lenderPool.address)).toString(), 0);
    });

    it('should not be possible to deposit with amount > minAmount but remaining = 0 from somebody', async () => {
      await lenderPool.setAgreementDebtValue(toBN(9000000000));
      await lenderPool.setTargetAgreement(TARGET_AGREEMENT_ADDRESS, {from: ADMIN});

      await daiTokenMock.mint(NOBODY, 9000000000);
      await daiTokenMock.approve(lenderPool.address, 9000000000, {from: NOBODY});

      assert.equal((await daiTokenMock.balanceOf(NOBODY)).toString(), 9000000000);

      const result = await lenderPool.deposit(9000000000, {from: NOBODY});

      assert.equal((await daiTokenMock.balanceOf(NOBODY)).toString(), 0);
      assert.equal((await lenderPool.daiTotal()).toString(), 9000000000);
      assert.equal((await lenderPool.balanceOf(NOBODY)).toString(), 9000000000);
      assert.equal((await daiTokenMock.balanceOf(lenderPool.address)).toString(), 9000000000);

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'Deposited');
      assert.equal(result.logs[0].args.pooler, NOBODY);
      assert.equal(result.logs[0].args.amount, 9000000000);

      await daiTokenMock.mint(SOMEBODY, 9000000000);
      await daiTokenMock.approve(lenderPool.address, 9000000000, {from: SOMEBODY});

      assert.equal((await daiTokenMock.balanceOf(SOMEBODY)).toString(), 9000000000);

      await assertReverts(lenderPool.deposit(9000000000, {from: SOMEBODY}));

      assert.equal((await daiTokenMock.balanceOf(NOBODY)).toString(), 0);
      assert.equal((await lenderPool.daiTotal()).toString(), 9000000000);
      assert.equal((await lenderPool.balanceOf(NOBODY)).toString(), 9000000000);
      assert.equal((await daiTokenMock.balanceOf(SOMEBODY)).toString(), 9000000000);
      assert.equal((await lenderPool.balanceOf(SOMEBODY)).toString(), 0);
      assert.equal((await daiTokenMock.balanceOf(lenderPool.address)).toString(), 9000000000);
    });

    it('should not be possible to deposit with wrong status from somebody', async () => {
      await lenderPool.setAgreementDebtValue(toBN(9000000000));
      await lenderPool.setTargetAgreement(TARGET_AGREEMENT_ADDRESS, {from: ADMIN});

      await daiTokenMock.mint(SOMEBODY, 9000000000);
      await daiTokenMock.approve(lenderPool.address, 9000000000, {from: SOMEBODY});

      assert.equal((await daiTokenMock.balanceOf(SOMEBODY)).toString(), 9000000000);

      const result = await lenderPool.deposit(9000000000, {from: SOMEBODY});

      assert.equal((await daiTokenMock.balanceOf(SOMEBODY)).toString(), 0);
      assert.equal((await lenderPool.daiTotal()).toString(), 9000000000);
      assert.equal((await lenderPool.balanceOf(SOMEBODY)).toString(), 9000000000);
      assert.equal((await daiTokenMock.balanceOf(lenderPool.address)).toString(), 9000000000);

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'Deposited');
      assert.equal(result.logs[0].args.pooler, SOMEBODY);
      assert.equal(result.logs[0].args.amount, 9000000000);

      await lenderPool.matchAgreement();

      await daiTokenMock.mint(SOMEBODY, 9000000000);
      await daiTokenMock.approve(lenderPool.address, 9000000000, {from: SOMEBODY});

      assert.equal((await daiTokenMock.balanceOf(SOMEBODY)).toString(), 9000000000);

      await assertReverts(lenderPool.deposit(9000000000, {from: SOMEBODY}));
    });
  });

  describe('matchAgreement()', async () => {
    it('should be possible to matchAgreement with valid daiTotal from admin', async () => {
      await lenderPool.setAgreementDebtValue(toBN(9000000000));
      await lenderPool.setTargetAgreement(TARGET_AGREEMENT_ADDRESS, {from: ADMIN});

      await daiTokenMock.mint(SOMEBODY, 9000000000);
      await daiTokenMock.approve(lenderPool.address, 9000000000, {from: SOMEBODY});

      assert.equal((await daiTokenMock.balanceOf(SOMEBODY)).toString(), 9000000000);

      await lenderPool.deposit(9000000000, {from: SOMEBODY});

      assert.equal((await lenderPool.status()).toString(), 0);

      const result = await lenderPool.matchAgreement();

      assert.equal((await daiTokenMock.allowances(lenderPool.address,
        TARGET_AGREEMENT_ADDRESS)).toString(), 9000000000);

      assert.equal((await lenderPool.status()).toString(), 1);

      assert.equal(result.logs.length, 2);
      assert.equal(result.logs[1].event, 'MatchedAgreement');
      assert.equal(result.logs[1].args.targetAgreement, TARGET_AGREEMENT_ADDRESS);
    });

    it('should not be possible to matchAgreement with invalid daiTotal from admin if status is pending', async () => {
      await lenderPool.setAgreementDebtValue(toBN(9000000000));
      await lenderPool.setTargetAgreement(TARGET_AGREEMENT_ADDRESS, {from: ADMIN});

      await daiTokenMock.mint(SOMEBODY, 9000000000);
      await daiTokenMock.approve(lenderPool.address, 9000000000, {from: SOMEBODY});

      assert.equal((await daiTokenMock.balanceOf(SOMEBODY)).toString(), 9000000000);

      await lenderPool.deposit(8000000000, {from: SOMEBODY});

      assert.equal((await lenderPool.status()).toString(), 0);

      await assertReverts(lenderPool.matchAgreement());

      assert.equal((await daiTokenMock.allowances(lenderPool.address,
        TARGET_AGREEMENT_ADDRESS)).toString(), 0);

      assert.equal((await lenderPool.status()).toString(), 0);
    });

    it('should not be possible to matchAgreement with valid daiTotal from adminif status is pending', async () => {
      await lenderPool.setAgreementDebtValue(toBN(9000000000));
      await lenderPool.setTargetAgreement(TARGET_AGREEMENT_ADDRESS, {from: ADMIN});

      await daiTokenMock.mint(SOMEBODY, 9000000000);
      await daiTokenMock.approve(lenderPool.address, 9000000000, {from: SOMEBODY});

      assert.equal((await daiTokenMock.balanceOf(SOMEBODY)).toString(), 9000000000);

      await lenderPool.deposit(9000000000, {from: SOMEBODY});

      assert.equal((await lenderPool.status()).toString(), 0);

      await assertReverts(lenderPool.matchAgreement({from: NOBODY}));

      assert.equal((await daiTokenMock.allowances(lenderPool.address,
        TARGET_AGREEMENT_ADDRESS)).toString(), 0);

      assert.equal((await lenderPool.status()).toString(), 0);
    });

    it('should not be possible to matchAgreement with valid daiTotal from admin if status is not pending', async () => {
      await lenderPool.setAgreementDebtValue(toBN(9000000000));
      await lenderPool.setTargetAgreement(TARGET_AGREEMENT_ADDRESS, {from: ADMIN});

      await daiTokenMock.mint(SOMEBODY, 9000000000);
      await daiTokenMock.approve(lenderPool.address, 9000000000, {from: SOMEBODY});

      assert.equal((await daiTokenMock.balanceOf(SOMEBODY)).toString(), 9000000000);

      await lenderPool.deposit(9000000000, {from: SOMEBODY});

      assert.equal((await lenderPool.status()).toString(), 0);

      await lenderPool.matchAgreement();
      await assertReverts(lenderPool.matchAgreement());

      assert.equal((await daiTokenMock.allowances(lenderPool.address,
        TARGET_AGREEMENT_ADDRESS)).toString(), 9000000000);

      assert.equal((await lenderPool.status()).toString(), 1);
    });
  });

  describe('refundFromAgreement()', async () => {
    it('should be possible to refund if agreement status is closed from admin', async () => {
      await lenderPool.setAgreementDebtValue(toBN(9000000000));
      await lenderPool.setTargetAgreement(TARGET_AGREEMENT_ADDRESS, {from: ADMIN});

      await daiTokenMock.mint(SOMEBODY, 9000000000);
      await daiTokenMock.approve(lenderPool.address, 9000000000, {from: SOMEBODY});

      await lenderPool.deposit(9000000000, {from: SOMEBODY});

      assert.equal((await lenderPool.status()).toString(), 0);

      await lenderPool.matchAgreement();

      await lenderPool.setAgreementStatus(true);
      await lenderPool.setAgreementDaiAsset(9100000000);

      assert.equal((await lenderPool.status()).toString(), 1);

      const result = await lenderPool.refundFromAgreement({from: ADMIN});

      assert.equal((await lenderPool.daiWithSavings()).toString(), 9100000000);
      assert.equal((await lenderPool.status()).toString(), 2);

      assert.equal(result.logs.length, 2);
      assert.equal(result.logs[1].event, 'RefundedFromAgreement');
      assert.equal(result.logs[1].args.targetAgreement, TARGET_AGREEMENT_ADDRESS);
      assert.equal(result.logs[1].args.daiWithSavings, 9100000000);
    });

    it('should not be possible to refund if agreement status is not closed from admin', async () => {
      await lenderPool.setAgreementDebtValue(toBN(9000000000));
      await lenderPool.setTargetAgreement(TARGET_AGREEMENT_ADDRESS, {from: ADMIN});

      await daiTokenMock.mint(SOMEBODY, 9000000000);
      await daiTokenMock.approve(lenderPool.address, 9000000000, {from: SOMEBODY});

      await lenderPool.deposit(9000000000, {from: SOMEBODY});

      assert.equal((await lenderPool.status()).toString(), 0);

      await lenderPool.setAgreementStatus(true);
      await lenderPool.setAgreementDaiAsset(9100000000);

      await assertReverts(lenderPool.refundFromAgreement({from: ADMIN}));

      assert.equal((await lenderPool.daiWithSavings()).toString(), 0);
      assert.equal((await lenderPool.status()).toString(), 0);
    });

    it('should be possible to refund if agreement status is closed from not an admin', async () => {
      await lenderPool.setAgreementDebtValue(toBN(9000000000));
      await lenderPool.setTargetAgreement(TARGET_AGREEMENT_ADDRESS, {from: ADMIN});

      await daiTokenMock.mint(SOMEBODY, 9000000000);
      await daiTokenMock.approve(lenderPool.address, 9000000000, {from: SOMEBODY});

      await lenderPool.deposit(9000000000, {from: SOMEBODY});

      assert.equal((await lenderPool.status()).toString(), 0);

      await lenderPool.matchAgreement();

      await lenderPool.setAgreementStatus(true);
      await lenderPool.setAgreementDaiAsset(9100000000);

      assert.equal((await lenderPool.status()).toString(), 1);

      await assertReverts(lenderPool.refundFromAgreement({from: NOBODY}));

      assert.equal((await lenderPool.daiWithSavings()).toString(), 0);
      assert.equal((await lenderPool.status()).toString(), 1);
    });
  });

  describe('availableForWithdrawal()', async () => {
    it('should calculate withdraw share correctly with amountWithSavings > amount is status is closed case 1', async () => {
      await lenderPool.setAgreementDebtValue(toBN(20000000000));
      await lenderPool.setTargetAgreement(TARGET_AGREEMENT_ADDRESS, {from: ADMIN});

      await daiTokenMock.mint(SOMEBODY, 10000000000);
      await daiTokenMock.approve(lenderPool.address, 10000000000, {from: SOMEBODY});

      await daiTokenMock.mint(NOBODY, 10000000000);
      await daiTokenMock.approve(lenderPool.address, 10000000000, {from: NOBODY});

      await lenderPool.deposit(10000000000, {from: SOMEBODY});
      await lenderPool.deposit(10000000000, {from: NOBODY});

      await lenderPool.matchAgreement();

      await lenderPool.setAgreementStatus(true);
      await lenderPool.setAgreementDaiAsset(23000000000);

      await lenderPool.refundFromAgreement({from: ADMIN});

      assert.equal((await lenderPool.availableForWithdrawal.call(SOMEBODY)).toString(),
        11500000000);
    });

    it('should calculate withdraw share correctly with amountWithSavings > amount is status is closed case 2', async () => {
      await lenderPool.setAgreementDebtValue(toBN(70000000000));
      await lenderPool.setTargetAgreement(TARGET_AGREEMENT_ADDRESS, {from: ADMIN});

      await daiTokenMock.mint(SOMEBODY, 10000000000);
      await daiTokenMock.approve(lenderPool.address, 10000000000, {from: SOMEBODY});

      await daiTokenMock.mint(NOBODY, 10000000000);
      await daiTokenMock.approve(lenderPool.address, 10000000000, {from: NOBODY});

      await daiTokenMock.mint(OWNER, 50000000000);
      await daiTokenMock.approve(lenderPool.address, 50000000000);

      await lenderPool.deposit(10000000000, {from: SOMEBODY});
      await lenderPool.deposit(10000000000, {from: NOBODY});
      await lenderPool.deposit(50000000000);

      await lenderPool.matchAgreement();

      await lenderPool.setAgreementStatus(true);
      await lenderPool.setAgreementDaiAsset(71341074373);

      await lenderPool.refundFromAgreement({from: ADMIN});

      assert.equal((await lenderPool.availableForWithdrawal.call(SOMEBODY)).toString(),
        10191582053);
    });

    it('should calculate withdraw share correctly with amountWithSavings < amount if status is closed', async () => {
      await lenderPool.setAgreementDebtValue(toBN(70000000000));
      await lenderPool.setTargetAgreement(TARGET_AGREEMENT_ADDRESS, {from: ADMIN});

      await daiTokenMock.mint(SOMEBODY, 10000000000);
      await daiTokenMock.approve(lenderPool.address, 10000000000, {from: SOMEBODY});

      await daiTokenMock.mint(NOBODY, 10000000000);
      await daiTokenMock.approve(lenderPool.address, 10000000000, {from: NOBODY});

      await daiTokenMock.mint(OWNER, 50000000000);
      await daiTokenMock.approve(lenderPool.address, 50000000000);

      await lenderPool.deposit(10000000000, {from: SOMEBODY});
      await lenderPool.deposit(10000000000, {from: NOBODY});
      await lenderPool.deposit(50000000000);

      await lenderPool.matchAgreement();

      await lenderPool.setAgreementStatus(true);
      await lenderPool.setAgreementDaiAsset(69341074373);

      await lenderPool.refundFromAgreement({from: ADMIN});

      assert.equal((await lenderPool.availableForWithdrawal.call(SOMEBODY)).toString(), 9905867767);
    });

    it('should retrun valid share if status is pending and now > pendingExpireDate', async () => {
      await lenderPool.setAgreementDebtValue(toBN(70000000000));
      await lenderPool.setTargetAgreement(TARGET_AGREEMENT_ADDRESS, {from: ADMIN});

      await daiTokenMock.mint(SOMEBODY, 10000000000);
      await daiTokenMock.approve(lenderPool.address, 10000000000, {from: SOMEBODY});

      await daiTokenMock.mint(NOBODY, 10000000000);
      await daiTokenMock.approve(lenderPool.address, 10000000000, {from: NOBODY});

      await daiTokenMock.mint(OWNER, 50000000000);
      await daiTokenMock.approve(lenderPool.address, 50000000000);

      await lenderPool.deposit(10000000000, {from: SOMEBODY});
      await lenderPool.deposit(10000000000, {from: NOBODY});
      await lenderPool.deposit(50000000000);

      await setCurrentTime(10000000);

      assert.equal((await lenderPool.availableForWithdrawal.call(SOMEBODY)).toString(),
        10000000000);
    });

    it('should retrun valid share if status is pending and now > pendingExpireDate', async () => {
      await lenderPool.setAgreementDebtValue(toBN(70000000000));
      await lenderPool.setTargetAgreement(TARGET_AGREEMENT_ADDRESS, {from: ADMIN});

      await daiTokenMock.mint(SOMEBODY, 10000000000);
      await daiTokenMock.approve(lenderPool.address, 10000000000, {from: SOMEBODY});

      await daiTokenMock.mint(NOBODY, 10000000000);
      await daiTokenMock.approve(lenderPool.address, 10000000000, {from: NOBODY});

      await daiTokenMock.mint(OWNER, 50000000000);
      await daiTokenMock.approve(lenderPool.address, 50000000000);

      await lenderPool.deposit(10000000000, {from: SOMEBODY});
      await lenderPool.deposit(10000000000, {from: NOBODY});
      await lenderPool.deposit(50000000000);

      await setCurrentTime(100);

      assert.equal((await lenderPool.availableForWithdrawal.call(SOMEBODY)).toString(), 0);
    });

    it('should return valid share if status is closed but user contribution is 0', async () => {
      await lenderPool.setAgreementDebtValue(toBN(70000000000));
      await lenderPool.setTargetAgreement(TARGET_AGREEMENT_ADDRESS, {from: ADMIN});

      await daiTokenMock.mint(NOBODY, 10000000000);
      await daiTokenMock.approve(lenderPool.address, 10000000000, {from: NOBODY});

      await daiTokenMock.mint(OWNER, 50000000000);
      await daiTokenMock.approve(lenderPool.address, 50000000000);

      await lenderPool.deposit(10000000000, {from: NOBODY});
      await lenderPool.deposit(50000000000);

      await setCurrentTime(100);

      assert.equal((await lenderPool.availableForWithdrawal.call(SOMEBODY)).toString(), 0);
    });
  });

  describe('withdraw(), withdwarTo()', async () => {
    it('should be possible to withdraw if amount > 0', async () => {
      await lenderPool.setAgreementDebtValue(toBN(20000000000));
      await lenderPool.setTargetAgreement(TARGET_AGREEMENT_ADDRESS, {from: ADMIN});

      await daiTokenMock.mint(SOMEBODY, 10000000000);
      await daiTokenMock.approve(lenderPool.address, 10000000000, {from: SOMEBODY});

      await daiTokenMock.mint(NOBODY, 10000000000);
      await daiTokenMock.approve(lenderPool.address, 10000000000, {from: NOBODY});

      await lenderPool.deposit(10000000000, {from: SOMEBODY});
      await lenderPool.deposit(10000000000, {from: NOBODY});

      await lenderPool.matchAgreement();

      await lenderPool.setAgreementStatus(true);
      await lenderPool.setAgreementDaiAsset(23000000000);

      await lenderPool.refundFromAgreement({from: ADMIN});

      const result = await lenderPool.withdraw({from: SOMEBODY});

      assert.equal((await lenderPool.daiTotal()).toString(), 10000000000);
      assert.equal((await lenderPool.balanceOf(SOMEBODY)).toString(), 0);
      assert.equal((await daiTokenMock.balanceOf(SOMEBODY)).toString(), 11500000000);

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'Withdrawn');
      assert.equal(result.logs[0].args.caller, SOMEBODY);
      assert.equal(result.logs[0].args.pooler, SOMEBODY);
      assert.equal(result.logs[0].args.amount, 10000000000);
      assert.equal(result.logs[0].args.amountWithSavings, 11500000000);
    });

    it('should not be possible to withdraw if amount is 0', async () => {
      await lenderPool.setAgreementDebtValue(toBN(10000000000));
      await lenderPool.setTargetAgreement(TARGET_AGREEMENT_ADDRESS, {from: ADMIN});

      await daiTokenMock.mint(SOMEBODY, 10000000000);
      await daiTokenMock.approve(lenderPool.address, 10000000000, {from: SOMEBODY});

      await daiTokenMock.mint(NOBODY, 10000000000);
      await daiTokenMock.approve(lenderPool.address, 10000000000, {from: NOBODY});

      await lenderPool.deposit(10000000000, {from: NOBODY});

      await lenderPool.matchAgreement();

      await lenderPool.setAgreementStatus(true);
      await lenderPool.setAgreementDaiAsset(23000000000);

      await lenderPool.refundFromAgreement({from: ADMIN});

      await assertReverts(lenderPool.withdraw({from: SOMEBODY}));

      assert.equal((await lenderPool.daiTotal()).toString(), 10000000000);
      assert.equal((await lenderPool.balanceOf(SOMEBODY)).toString(), 0);
      assert.equal((await daiTokenMock.balanceOf(SOMEBODY)).toString(), 10000000000);
    });

    it('should be possible to withdrawTo all funds from somebody if status is pending from admin', async () => {
      await lenderPool.setAgreementDebtValue(toBN(20000000000));
      await lenderPool.setTargetAgreement(TARGET_AGREEMENT_ADDRESS, {from: ADMIN});

      await daiTokenMock.mint(SOMEBODY, 10000000000);
      await daiTokenMock.approve(lenderPool.address, 10000000000, {from: SOMEBODY});

      await daiTokenMock.mint(NOBODY, 10000000000);
      await daiTokenMock.approve(lenderPool.address, 10000000000, {from: NOBODY});

      await lenderPool.deposit(10000000000, {from: SOMEBODY});
      await lenderPool.deposit(10000000000, {from: NOBODY});

      const result = await lenderPool.withdrawTo(SOMEBODY, 10000000000, {from: ADMIN});

      assert.equal((await lenderPool.daiTotal()).toString(), 10000000000);
      assert.equal((await lenderPool.balanceOf(SOMEBODY)).toString(), 0);
      assert.equal((await daiTokenMock.balanceOf(SOMEBODY)).toString(), 10000000000);

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'Withdrawn');
      assert.equal(result.logs[0].args.caller, ADMIN);
      assert.equal(result.logs[0].args.pooler, SOMEBODY);
      assert.equal(result.logs[0].args.amount, 10000000000);
      assert.equal(result.logs[0].args.amountWithSavings, 10000000000);
    });

    it('should be possible to withdrawTo less funds than user has from somebody if status is pending from admin', async () => {
      await lenderPool.setAgreementDebtValue(toBN(20000000000));
      await lenderPool.setTargetAgreement(TARGET_AGREEMENT_ADDRESS, {from: ADMIN});

      await daiTokenMock.mint(SOMEBODY, 10000000000);
      await daiTokenMock.approve(lenderPool.address, 10000000000, {from: SOMEBODY});

      await daiTokenMock.mint(NOBODY, 10000000000);
      await daiTokenMock.approve(lenderPool.address, 10000000000, {from: NOBODY});

      await lenderPool.deposit(10000000000, {from: SOMEBODY});
      await lenderPool.deposit(10000000000, {from: NOBODY});

      const result = await lenderPool.withdrawTo(SOMEBODY, 5000000000, {from: ADMIN});

      assert.equal((await lenderPool.daiTotal()).toString(), 15000000000);
      assert.equal((await lenderPool.balanceOf(SOMEBODY)).toString(), 5000000000);
      assert.equal((await daiTokenMock.balanceOf(SOMEBODY)).toString(), 5000000000);

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'Withdrawn');
      assert.equal(result.logs[0].args.caller, ADMIN);
      assert.equal(result.logs[0].args.pooler, SOMEBODY);
      assert.equal(result.logs[0].args.amount, 5000000000);
      assert.equal(result.logs[0].args.amountWithSavings, 5000000000);
    });

    it('should not be possible to withdrawTo more funds than user has from somebody if status is pending from admin', async () => {
      await lenderPool.setAgreementDebtValue(toBN(20000000000));
      await lenderPool.setTargetAgreement(TARGET_AGREEMENT_ADDRESS, {from: ADMIN});

      await daiTokenMock.mint(SOMEBODY, 10000000000);
      await daiTokenMock.approve(lenderPool.address, 10000000000, {from: SOMEBODY});

      await daiTokenMock.mint(NOBODY, 10000000000);
      await daiTokenMock.approve(lenderPool.address, 10000000000, {from: NOBODY});

      await lenderPool.deposit(10000000000, {from: SOMEBODY});
      await lenderPool.deposit(10000000000, {from: NOBODY});

      await assertReverts(lenderPool.withdrawTo(SOMEBODY, 15000000000, {from: ADMIN}));

      assert.equal((await lenderPool.daiTotal()).toString(), 20000000000);
      assert.equal((await lenderPool.balanceOf(SOMEBODY)).toString(), 10000000000);
      assert.equal((await daiTokenMock.balanceOf(SOMEBODY)).toString(), 0);
    });

    it('should not be possible to withdrawTo all funds than user has from somebody if status is not pending from admin', async () => {
      await lenderPool.setAgreementDebtValue(toBN(20000000000));
      await lenderPool.setTargetAgreement(TARGET_AGREEMENT_ADDRESS, {from: ADMIN});

      await daiTokenMock.mint(SOMEBODY, 10000000000);
      await daiTokenMock.approve(lenderPool.address, 10000000000, {from: SOMEBODY});

      await daiTokenMock.mint(NOBODY, 10000000000);
      await daiTokenMock.approve(lenderPool.address, 10000000000, {from: NOBODY});

      await lenderPool.deposit(10000000000, {from: SOMEBODY});
      await lenderPool.deposit(10000000000, {from: NOBODY});

      await lenderPool.matchAgreement();

      await assertReverts(lenderPool.withdrawTo(SOMEBODY, 10000000000, {from: ADMIN}));

      assert.equal((await lenderPool.daiTotal()).toString(), 20000000000);
      assert.equal((await lenderPool.balanceOf(SOMEBODY)).toString(), 10000000000);
      assert.equal((await daiTokenMock.balanceOf(SOMEBODY)).toString(), 0);
    });

    it('should not be possible to withdrawTo 0 funds than user has from somebody if status is pending from admin', async () => {
      await lenderPool.setAgreementDebtValue(toBN(20000000000));
      await lenderPool.setTargetAgreement(TARGET_AGREEMENT_ADDRESS, {from: ADMIN});

      await daiTokenMock.mint(SOMEBODY, 10000000000);
      await daiTokenMock.approve(lenderPool.address, 10000000000, {from: SOMEBODY});

      await daiTokenMock.mint(NOBODY, 10000000000);
      await daiTokenMock.approve(lenderPool.address, 10000000000, {from: NOBODY});

      await lenderPool.deposit(10000000000, {from: SOMEBODY});
      await lenderPool.deposit(10000000000, {from: NOBODY});

      await assertReverts(lenderPool.withdrawTo(SOMEBODY, 0, {from: ADMIN}));

      assert.equal((await lenderPool.daiTotal()).toString(), 20000000000);
      assert.equal((await lenderPool.balanceOf(SOMEBODY)).toString(), 10000000000);
      assert.equal((await daiTokenMock.balanceOf(SOMEBODY)).toString(), 0);
    });

    it('should not be possible to withdrawTo all funds than user has from somebody if status is pending from not admin', async () => {
      await lenderPool.setAgreementDebtValue(toBN(20000000000));
      await lenderPool.setTargetAgreement(TARGET_AGREEMENT_ADDRESS, {from: ADMIN});

      await daiTokenMock.mint(SOMEBODY, 10000000000);
      await daiTokenMock.approve(lenderPool.address, 10000000000, {from: SOMEBODY});

      await daiTokenMock.mint(NOBODY, 10000000000);
      await daiTokenMock.approve(lenderPool.address, 10000000000, {from: NOBODY});

      await lenderPool.deposit(10000000000, {from: SOMEBODY});
      await lenderPool.deposit(10000000000, {from: NOBODY});

      await assertReverts(lenderPool.withdrawTo(SOMEBODY, 10000000000, {from: SOMEBODY}));

      assert.equal((await lenderPool.daiTotal()).toString(), 20000000000);
      assert.equal((await lenderPool.balanceOf(SOMEBODY)).toString(), 10000000000);
      assert.equal((await daiTokenMock.balanceOf(SOMEBODY)).toString(), 0);
    });
  });
});
