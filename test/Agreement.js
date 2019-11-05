const Agreement = artifacts.require('AgreementDeepMock');
const Config = artifacts.require('ConfigMock');
const Reverter = require('./helpers/reverter');
const {assertReverts} = require('./helpers/assertThrows');
const BigNumber = require('bignumber.js');

contract('Agreement', async (accounts) => {
  const reverter = new Reverter(web3);

  let configContract;
  let agreement;

  const OWNER = accounts[0];
  const BORROWER = accounts[1];
  const LENDER = accounts[2];
  const NOBODY = accounts[3];
  const ETH_A = '0x4554482d41000000000000000000000000000000000000000000000000000000';
  const WRONG_COLLATERAL = '0x0000000000000000000000000000000000000000000000000000000000000000';

  const toBN = (num) => {
    return new BigNumber(num);
  };

  const fromPercentToRey = (num) => {
    return (toBN(num).times((toBN(10).pow(toBN(25))))).plus((toBN(10).pow(toBN(27))));
  };

  before('setup', async () => {
    agreement = await Agreement.new({from: OWNER});

    await reverter.snapshot();
  });

  afterEach('revert', reverter.revert);

  describe('initialize()', async () => {
    beforeEach('init config', async () => {
      configContract = await Config.new();
      await configContract
      .setGeneral(1440, 60, 2, 100, toBN(100).times(toBN(10).pow(toBN(18))), 86400, 31536000);
    });

    it('should be possible to initialize with average agruments on ETH', async () => {
      const result = await agreement.initAgreement(BORROWER, 2000, 300000, 90000,
        fromPercentToRey(3), ETH_A, true, configContract.address, {from: OWNER, value: 2000});

      assert.equal((await agreement.duration.call()).toNumber(), 90000);
      assert.equal(await agreement.borrower.call(), BORROWER);
      assert.equal((await agreement.debtValue.call()).toNumber(), 300000);
      assert.equal((await agreement.interestRate.call()).toString(), fromPercentToRey(3).toFixed());
      assert.equal((await agreement.collateralAmount.call()).toNumber(), 2000);
      assert.equal(await agreement.collateralType.call(), ETH_A);

      assert.equal(result.logs.length, 2);
      assert.equal(result.logs[1].event, 'AgreementInitiated');
      assert.equal(result.logs[1].args._borrower, BORROWER);
      assert.equal(result.logs[1].args._collateralValue.toNumber(), 2000);
      assert.equal(result.logs[1].args._debtValue.toNumber(), 300000);
      assert.equal(result.logs[1].args._expireDate.toNumber(), 90000);
      assert.equal(result.logs[1].args._interestRate.toString(), fromPercentToRey(3).toFixed());
    });

    it('should be possible to initialize with average case 2 on ETH', async () => {
      const result = await agreement.initAgreement(BORROWER, 20000, 300000, 90639,
        fromPercentToRey(43), ETH_A, true, configContract.address, {from: OWNER, value: 20000});

      assert.equal((await agreement.duration.call()).toNumber(), 90639);
      assert.equal(await agreement.borrower.call(), BORROWER);
      assert.equal((await agreement.debtValue.call()).toNumber(), 300000);
      assert.equal((await agreement.interestRate.call()).toString(),
        fromPercentToRey(43).toFixed());
      assert.equal((await agreement.collateralAmount.call()).toNumber(), 20000);
      assert.equal(await agreement.collateralType.call(), ETH_A);

      assert.equal(result.logs.length, 2);
      assert.equal(result.logs[1].event, 'AgreementInitiated');
      assert.equal(result.logs[1].args._borrower, BORROWER);
      assert.equal(result.logs[1].args._collateralValue.toNumber(), 20000);
      assert.equal(result.logs[1].args._debtValue.toNumber(), 300000);
      assert.equal(result.logs[1].args._expireDate.toNumber(), 90639);
      assert.equal(result.logs[1].args._interestRate.toString(), fromPercentToRey(43).toFixed());
    });

    it('should be possible to initialize with average case 3 on ETH', async () => {
      const result = await agreement.initAgreement(BORROWER, 150, 300, 120008, fromPercentToRey(97),
        ETH_A, true, configContract.address, {from: OWNER, value: 150});

      assert.equal((await agreement.duration.call()).toNumber(), 120008);
      assert.equal(await agreement.borrower.call(), BORROWER);
      assert.equal((await agreement.debtValue.call()).toNumber(), 300);
      assert.equal((await agreement.interestRate.call()).toString(),
        fromPercentToRey(97).toFixed());
      assert.equal((await agreement.collateralAmount.call()).toNumber(), 150);
      assert.equal(await agreement.collateralType.call(), ETH_A);

      assert.equal(result.logs.length, 2);
      assert.equal(result.logs[1].event, 'AgreementInitiated');
      assert.equal(result.logs[1].args._borrower, BORROWER);
      assert.equal(result.logs[1].args._collateralValue.toNumber(), 150);
      assert.equal(result.logs[1].args._debtValue.toNumber(), 300);
      assert.equal(result.logs[1].args._expireDate.toNumber(), 120008);
      assert.equal(result.logs[1].args._interestRate.toString(), fromPercentToRey(97).toFixed());
    });

    it('should be possible to initialize with interestRate = 100 on ETH', async () => {
      const result = await agreement.initAgreement(BORROWER, 2000, 300000, 110031,
        fromPercentToRey(100), ETH_A, true, configContract.address, {from: OWNER, value: 2000});

      assert.equal((await agreement.duration.call()).toNumber(), 110031);
      assert.equal(await agreement.borrower.call(), BORROWER);
      assert.equal((await agreement.debtValue.call()).toNumber(), 300000);
      assert.equal((await agreement.interestRate.call()).toString(),
        fromPercentToRey(100).toFixed());
      assert.equal((await agreement.collateralAmount.call()).toNumber(), 2000);
      assert.equal(await agreement.collateralType.call(), ETH_A);

      assert.equal(result.logs.length, 2);
      assert.equal(result.logs[1].event, 'AgreementInitiated');
      assert.equal(result.logs[1].args._borrower, BORROWER);
      assert.equal(result.logs[1].args._collateralValue.toNumber(), 2000);
      assert.equal(result.logs[1].args._debtValue.toNumber(), 300000);
      assert.equal(result.logs[1].args._expireDate.toNumber(), 110031);
      assert.equal(result.logs[1].args._interestRate.toString(), fromPercentToRey(100).toFixed());
    });

    it('should be possible to initialize with interestRate = 1 on ETH', async () => {
      const result = await agreement.initAgreement(BORROWER, 2000, 300000, 90000,
        fromPercentToRey(1), ETH_A, true, configContract.address, {from: OWNER, value: 2000});

      assert.equal((await agreement.duration.call()).toNumber(), 90000);
      assert.equal(await agreement.borrower.call(), BORROWER);
      assert.equal((await agreement.debtValue.call()).toNumber(), 300000);
      assert.equal((await agreement.interestRate.call()).toString(), fromPercentToRey(1).toFixed());
      assert.equal((await agreement.collateralAmount.call()).toNumber(), 2000);
      assert.equal(await agreement.collateralType.call(), ETH_A);

      assert.equal(result.logs.length, 2);
      assert.equal(result.logs[1].event, 'AgreementInitiated');
      assert.equal(result.logs[1].args._borrower, BORROWER);
      assert.equal(result.logs[1].args._collateralValue.toNumber(), 2000);
      assert.equal(result.logs[1].args._debtValue.toNumber(), 300000);
      assert.equal(result.logs[1].args._expireDate.toNumber(), 90000);
      assert.equal(result.logs[1].args._interestRate.toString(), fromPercentToRey(1).toFixed());
    });

    it('should be possible to initialize with duration = maxDuration - 1 on ETH', async () => {
      const result = await agreement.initAgreement(BORROWER, 2000, 300000, 31535999,
        fromPercentToRey(3), ETH_A, true, configContract.address, {from: OWNER, value: 2000});

      assert.equal((await agreement.duration.call()).toNumber(), 31535999);
      assert.equal(await agreement.borrower.call(), BORROWER);
      assert.equal((await agreement.debtValue.call()).toNumber(), 300000);
      assert.equal((await agreement.interestRate.call()).toString(), fromPercentToRey(3).toFixed());
      assert.equal((await agreement.collateralAmount.call()).toNumber(), 2000);
      assert.equal(await agreement.collateralType.call(), ETH_A);

      assert.equal(result.logs.length, 2);
      assert.equal(result.logs[1].event, 'AgreementInitiated');
      assert.equal(result.logs[1].args._borrower, BORROWER);
      assert.equal(result.logs[1].args._collateralValue.toNumber(), 2000);
      assert.equal(result.logs[1].args._debtValue.toNumber(), 300000);
      assert.equal(result.logs[1].args._expireDate.toNumber(), 31535999);
      assert.equal(result.logs[1].args._interestRate.toString(), fromPercentToRey(3).toFixed());
    });

    it('should be possible to initialize with duration = minDuratin + 1 on ETH', async () => {
      const result = await agreement.initAgreement(BORROWER, 2000, 300000, 86401,
        fromPercentToRey(3), ETH_A, true, configContract.address, {from: OWNER, value: 2000});

      assert.equal((await agreement.duration.call()).toNumber(), 86401);
      assert.equal(await agreement.borrower.call(), BORROWER);
      assert.equal((await agreement.debtValue.call()).toNumber(), 300000);
      assert.equal((await agreement.interestRate.call()).toString(), fromPercentToRey(3).toFixed());
      assert.equal((await agreement.collateralAmount.call()).toNumber(), 2000);
      assert.equal(await agreement.collateralType.call(), ETH_A);

      assert.equal(result.logs.length, 2);
      assert.equal(result.logs[1].event, 'AgreementInitiated');
      assert.equal(result.logs[1].args._borrower, BORROWER);
      assert.equal(result.logs[1].args._collateralValue.toNumber(), 2000);
      assert.equal(result.logs[1].args._debtValue.toNumber(), 300000);
      assert.equal(result.logs[1].args._expireDate.toNumber(), 86401);
      assert.equal(result.logs[1].args._interestRate.toString(), fromPercentToRey(3).toFixed());
    });

    it('should not be possible to initialize with debtValue = 0', async () => {
      await assertReverts(agreement.initAgreement(BORROWER, 2000, 0, 90000, fromPercentToRey(3),
        ETH_A, true, configContract.address, {from: OWNER, value: 2000}));
    });

    it('should not be possible to initialize with interestRate = 0', async () => {
      await assertReverts(agreement.initAgreement(BORROWER, 2000, 300000, 90000,
        fromPercentToRey(0), ETH_A, true, configContract.address, {from: OWNER, value: 2000}));
    });

    it('should not be possible to initialize with interestRate more than 100', async () => {
      await assertReverts(agreement.initAgreement(BORROWER, 2000, 300000, 90000,
        fromPercentToRey(101), ETH_A, true, configContract.address, {from: OWNER, value: 2000}));
    });

    it('should not be possible to initialize duration less than minDuration', async () => {
      await assertReverts(agreement.initAgreement(BORROWER, 2000, 300000, 86300,
        fromPercentToRey(3), ETH_A, true, configContract.address, {from: OWNER, value: 2000}));
    });

    it('should not be possible to initialize duration = minDuration', async () => {
      await assertReverts(agreement.initAgreement(BORROWER, 2000, 300000, 86400,
        fromPercentToRey(3), ETH_A, true, configContract.address, {from: OWNER, value: 2000}));
    });

    it('should not be possible to initialize duration = maxDuration', async () => {
      await assertReverts(agreement.initAgreement(BORROWER, 2000, 300000, 31536000,
        fromPercentToRey(3), ETH_A, true, configContract.address, {from: OWNER, value: 2000}));
    });

    it('should not be possible to initialize duration > maxDuration', async () => {
      await assertReverts(agreement.initAgreement(BORROWER, 2000, 300000, 71536000,
        fromPercentToRey(3), ETH_A, true, configContract.address, {from: OWNER, value: 2000}));
    });

    it('should not be possible to initialize with collateralAmount bigger than actual value', async () => {
      await assertReverts(agreement.initAgreement(BORROWER, 2000, 300000, 90000,
        fromPercentToRey(3), ETH_A, true, configContract.address, {from: OWNER, value: 2001}));
    });

    it('should not be possible to initialize with collateralAmount less than actual value', async () => {
      await assertReverts(agreement.initAgreement(BORROWER, 2000, 300000, 90000,
        fromPercentToRey(3), ETH_A, true, configContract.address, {from: OWNER, value: 1999}));
    });

    it('should not be possible to initialize with collateralAmount = 0', async () => {
      await assertReverts(agreement.initAgreement(BORROWER, 0, 300000, 90000, fromPercentToRey(3),
        ETH_A, true, configContract.address, {from: OWNER, value: 0}));
    });

    it('should not be possible to initialize with wrong collateral type', async () => {
      await assertReverts(agreement.initAgreement(BORROWER, 2000, 300000, 90000,
        fromPercentToRey(3), WRONG_COLLATERAL, true, configContract.address,
        {from: OWNER, value: 2000}));
    });

    it('should not be possible to initialize with valid collateral type but not enabled', async () => {
      await configContract.disableCollateral(ETH_A);
      await assertReverts(agreement.initAgreement(BORROWER, 2000, 300000, 90000,
        fromPercentToRey(3), ETH_A, true, configContract.address, {from: OWNER, value: 2000}));
    });
  });

  describe('approveAgreement()', async () => {
    beforeEach('init config', async () => {
      configContract = await Config.new();
      await configContract
      .setGeneral(1440, 60, 2, 100, toBN(100).times(toBN(10).pow(toBN(18))), 86400, 31536000);
    });

    it('should be possible to approve agreement by owner after initialization', async () => {
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000, fromPercentToRey(3),
        ETH_A, true, configContract.address, {from: OWNER, value: 2000});

      await agreement.setCurrentTime(1000);

      assert.equal((await agreement.status.call()).toNumber(), 1);
      const result = await agreement.approveAgreement();

      assert.equal((await agreement.status.call()).toNumber(), 2);

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'AgreementApproved');
      assert.equal((await agreement.approveDate.call()).toNumber(), 1000);
    });

    it('should not be possible to approve agreement by not owner after initialization', async () => {
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000, fromPercentToRey(3),
        ETH_A, true, configContract.address, {from: OWNER, value: 2000});

      await agreement.setCurrentTime(1000);

      assert.equal((await agreement.status.call()).toNumber(), 1);
      await assertReverts(agreement.approveAgreement({from: NOBODY}));

      assert.equal((await agreement.status.call()).toNumber(), 1);
      assert.equal((await agreement.approveDate.call()).toNumber(), 0);
    });

    it('should not be possible to approve agreement by owner before initialization', async () => {
      assert.equal((await agreement.status.call()).toNumber(), 0);
      await assertReverts(agreement.approveAgreement());

      await agreement.setCurrentTime(1000);

      assert.equal((await agreement.status.call()).toNumber(), 0);
      assert.equal((await agreement.approveDate.call()).toNumber(), 0);
    });

    it('should not be possible to approve agreement by not owner before initialization', async () => {
      assert.equal((await agreement.status.call()).toNumber(), 0);
      await assertReverts(agreement.approveAgreement({from: NOBODY}));

      await agreement.setCurrentTime(1000);

      assert.equal((await agreement.status.call()).toNumber(), 0);
      assert.equal((await agreement.approveDate.call()).toNumber(), 0);
    });

    it('should not be possible to approve agreement by owner after it is already approved', async () => {
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000, fromPercentToRey(3),
        ETH_A, true, configContract.address, {from: OWNER, value: 2000});

      await agreement.setCurrentTime(1000);

      assert.equal((await agreement.status.call()).toNumber(), 1);

      const result = await agreement.approveAgreement();

      assert.equal((await agreement.status.call()).toNumber(), 2);

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'AgreementApproved');

      await assertReverts(agreement.approveAgreement());

      assert.equal((await agreement.status.call()).toNumber(), 2);
      assert.equal((await agreement.approveDate.call()).toNumber(), 1000);
    });
  });

  describe('matchAgreement()', async () => {
    beforeEach('init config and init agreement', async () => {
      configContract = await Config.new();
      await configContract
      .setGeneral(1440, 60, 2, 100, toBN(100).times(toBN(10).pow(toBN(18))), 86400, 31536000);

      await agreement.initAgreement(BORROWER, 2000, 300000, 90000, fromPercentToRey(3),
        ETH_A, true, configContract.address, {from: OWNER, value: 2000});
    });

    it('should be possible to match initialized and approved agreement by lender', async () => {
      await agreement.approveAgreement();

      assert.equal((await agreement.status.call()).toNumber(), 2);

      await agreement.setCurrentTime(2000);
      const result = await agreement.matchAgreement({from: LENDER});

      assert.equal((await agreement.status.call()).toNumber(), 3);
      assert.equal((await agreement.matchDate.call()).toNumber(), 2000);
      assert.equal((await agreement.lastCheckTime.call()).toNumber(), 2000);
      assert.equal((await agreement.expireDate.call()).toNumber(), 92000);
      assert.equal(await agreement.lender.call(), LENDER);

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'AgreementMatched');
      assert.equal(result.logs[0].args._lender, LENDER);
    });

    it('should not be possible to match initialized but not approved agreement by lender', async () => {
      assert.equal((await agreement.status.call()).toNumber(), 1);

      await assertReverts(agreement.matchAgreement({from: LENDER}));

      assert.equal((await agreement.status.call()).toNumber(), 1);
    });

    it('should not be possible to match initialized and approved agreement by borrower', async () => {
      assert.equal((await agreement.status.call()).toNumber(), 1);

      await assertReverts(agreement.matchAgreement({from: BORROWER}));

      assert.equal((await agreement.status.call()).toNumber(), 1);
    });
  });

  describe('cancelAgreement(), rejectAgreement(), _cancelAgreement()', async () => {
    beforeEach('init agreemnet', async () => {
      configContract = await Config.new();
      await configContract
      .setGeneral(1440, 60, 2, 100, toBN(100).times(toBN(10).pow(toBN(18))), 86400, 31536000);

      await agreement.initAgreement(BORROWER, 2000, 300000, 90000, fromPercentToRey(3),
        ETH_A, true, configContract.address, {from: OWNER, value: 2000});
    });

    it('should be possible to cancel agreement by borrower when it is not matched', async () => {
      assert.equal(await agreement.status.call(), 1);

      await agreement.cancelAgreement({from: BORROWER});

      assert.equal(await agreement.status.call(), 12);
    });

    it('should be possible to cancel agreement by borrower when it is not matched and approved', async () => {
      await agreement.approveAgreement();
      await agreement.cancelAgreement({from: BORROWER});

      assert.equal(await agreement.status.call(), 12);
    });

    it('should not be possible to cancel agreement by owner when it is not matched and not approved', async () => {
      await assertReverts(agreement.cancelAgreement({from: OWNER}));
    });

    it('should not be possible to cancel agreement by owner when it is matched', async () => {
      await agreement.approveAgreement();
      await agreement.matchAgreement({from: LENDER});
      await assertReverts(agreement.cancelAgreement());
    });

    it('should not be possible to cancel agreement by borrower when it is matched', async () => {
      await agreement.approveAgreement();
      await agreement.matchAgreement({from: LENDER});
      await assertReverts(agreement.cancelAgreement({from: BORROWER}));
    });

    it('should not be possible to cancel agreement by nobody when it is matched', async () => {
      await agreement.approveAgreement();
      await agreement.matchAgreement({from: LENDER});
      await assertReverts(agreement.cancelAgreement({from: NOBODY}));
    });

    it('should not be possible to cancel agreement by nobody when it is not matched', async () => {
      await assertReverts(agreement.cancelAgreement({from: NOBODY}));
    });

    it('should not be possible to cancel agreement by nobody when it is approved and not matched', async () => {
      await agreement.approveAgreement();
      await assertReverts(agreement.cancelAgreement({from: NOBODY}));
    });

    it('should not be possible to cancel agreement by borrower when it is already canceled', async () => {
      await agreement.cancelAgreement({from: BORROWER});
      await assertReverts(agreement.cancelAgreement({from: BORROWER}));
    });

    it('should not be possible to cancel agreement by borrower when it is rejected', async () => {
      await agreement.rejectAgreement();
      await assertReverts(agreement.cancelAgreement({from: BORROWER}));
    });

    it('should be possible to reject agreement by owner when it is not matched', async () => {
      await agreement.rejectAgreement();

      assert.equal(await agreement.status.call(), 12);
    });

    it('should be possible to reject agreement by owner when it is not matched and approved', async () => {
      await agreement.approveAgreement();
      await agreement.rejectAgreement();

      assert.equal(await agreement.status.call(), 12);
    });

    it('should not be possible to reject agreement by borrower when it is not matched and not approved', async () => {
      await assertReverts(agreement.rejectAgreement({from: BORROWER}));
    });

    it('should not be possible to reject agreement by owner when it is matched', async () => {
      await agreement.approveAgreement();
      await agreement.matchAgreement({from: LENDER});
      await assertReverts(agreement.rejectAgreement());
    });

    it('should not be possible to reject agreement by borrower when it is matched', async () => {
      await agreement.approveAgreement();
      await agreement.matchAgreement({from: LENDER});
      await assertReverts(agreement.rejectAgreement({from: BORROWER}));
    });

    it('should not be possible to reject agreement by nobody when it is matched', async () => {
      await agreement.approveAgreement();
      await agreement.matchAgreement({from: LENDER});
      await assertReverts(agreement.rejectAgreement({from: NOBODY}));
    });

    it('should not be possible to reject agreement by nobody when it is not matched', async () => {
      await assertReverts(agreement.rejectAgreement({from: NOBODY}));
    });

    it('should not be possible to reject agreement by nobody when it is not matched', async () => {
      await agreement.approveAgreement();
      await assertReverts(agreement.rejectAgreement({from: NOBODY}));
    });

    it('should not be possible to reject agreement by owner when it is canceled', async () => {
      await agreement.cancelAgreement({from: BORROWER});
      await assertReverts(agreement.rejectAgreement());
    });

    it('should not be possible to reject agreement by owner when it is already rejected', async () => {
      await agreement.rejectAgreement();
      await assertReverts(agreement.rejectAgreement());
    });

    it('should transfer eth fuds correctly while canceling', async () => {
      assert.equal(await web3.eth.getBalance(BORROWER), '100000000000000000000');
      assert.equal(await web3.eth.getBalance(agreement.address), '2000');

      await agreement.rejectAgreement();

      assert.equal(await web3.eth.getBalance(BORROWER), '100000000000000002000');
      assert.equal(await web3.eth.getBalance(agreement.address), '0');
    });
  });

  describe('cheker and getter functions', async () => {
    beforeEach('init config', async () => {
      configContract = await Config.new();
      await configContract
      .setGeneral(1440, 60, 2, 100, toBN(100).times(toBN(10).pow(toBN(18))), 86400, 31536000);
    });

    it('isBeforeMatched() should return true if status is 0', async () => {
      assert.isTrue(await agreement.isBeforeMatched.call());
    });

    it('isBeforeMatched() should return true if status is pending', async () => {
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000, fromPercentToRey(3),
        ETH_A, true, configContract.address, {from: OWNER, value: 2000});

      assert.isTrue(await agreement.isBeforeMatched.call());
    });

    it('isBeforeMatched() should return true if status is open', async () => {
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000, fromPercentToRey(3),
        ETH_A, true, configContract.address, {from: OWNER, value: 2000});

      await agreement.approveAgreement();

      assert.isTrue(await agreement.isBeforeMatched.call());
    });

    it('isBeforeMatched() should return false if status is active', async () => {
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000, fromPercentToRey(3),
        ETH_A, true, configContract.address, {from: OWNER, value: 2000});

      await agreement.approveAgreement();

      await agreement.matchAgreement({from: LENDER});

      assert.isFalse(await agreement.isBeforeMatched.call());
    });

    it('isPending() should return true if status is pending', async () => {
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000, fromPercentToRey(3),
        ETH_A, true, configContract.address, {from: OWNER, value: 2000});

      assert.isTrue(await agreement.isPending.call());
    });

    it('isPending() should return false if status is 0', async () => {
      assert.isFalse(await agreement.isPending.call());
    });

    it('isPending() should return false if status is active', async () => {
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000, fromPercentToRey(3),
        ETH_A, true, configContract.address, {from: OWNER, value: 2000});

      await agreement.approveAgreement();

      await agreement.matchAgreement({from: LENDER});

      assert.isFalse(await agreement.isPending.call());
    });

    it('isOpen() should return true if status is open', async () => {
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000, fromPercentToRey(3),
        ETH_A, true, configContract.address, {from: OWNER, value: 2000});

      await agreement.approveAgreement();

      assert.isTrue(await agreement.isOpen.call());
    });

    it('isOpen() should return false if status is 0', async () => {
      assert.isFalse(await agreement.isOpen.call());
    });

    it('isOpen() should return false if status is active', async () => {
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000, fromPercentToRey(3),
        ETH_A, true, configContract.address, {from: OWNER, value: 2000});

      await agreement.approveAgreement();

      await agreement.matchAgreement({from: LENDER});

      assert.isFalse(await agreement.isOpen.call());
    });

    it('isActive() should return true if status is active', async () => {
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000, fromPercentToRey(3),
        ETH_A, true, configContract.address, {from: OWNER, value: 2000});

      await agreement.approveAgreement();

      await agreement.matchAgreement({from: LENDER});

      assert.isTrue(await agreement.isActive.call());
    });

    it('isActive() should return false if status is 0', async () => {
      assert.isFalse(await agreement.isActive.call());
    });

    it('isActive() should return false if status is open', async () => {
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000, fromPercentToRey(3),
        ETH_A, true, configContract.address, {from: OWNER, value: 2000});

      await agreement.approveAgreement();

      assert.isFalse(await agreement.isActive.call());
    });

    it('isEnded() should return true if status is ended', async () => {
      await agreement.setStatus(9);

      assert.isTrue(await agreement.isEnded.call());
    });

    it('isEnded() should return false if status is 0', async () => {
      assert.isFalse(await agreement.isEnded.call());
    });

    it('isEnded() should return false if status is open', async () => {
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000, fromPercentToRey(3),
        ETH_A, true, configContract.address, {from: OWNER, value: 2000});

      await agreement.approveAgreement();

      assert.isFalse(await agreement.isEnded.call());
    });

    it('isLiquidated() should return true if status is liquidated', async () => {
      await agreement.setStatus(10);

      assert.isTrue(await agreement.isLiquidated.call());
    });

    it('isLiquidated() should return false if status is 0', async () => {
      assert.isFalse(await agreement.isLiquidated.call());
    });

    it('isLiquidated() should return false if status is open', async () => {
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000, fromPercentToRey(3),
        ETH_A, true, configContract.address, {from: OWNER, value: 2000});

      await agreement.approveAgreement();

      assert.isFalse(await agreement.isLiquidated.call());
    });

    it('isClosed() should return true if status is closed', async () => {
      await agreement.setStatus(8);

      assert.isTrue(await agreement.isClosed.call());
    });

    it('isClosed() should return false if status is 0', async () => {
      assert.isFalse(await agreement.isClosed.call());
    });

    it('isClosed() should return false if status is open', async () => {
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000, fromPercentToRey(3),
        ETH_A, true, configContract.address, {from: OWNER, value: 2000});

      await agreement.approveAgreement();

      assert.isFalse(await agreement.isClosed.call());
    });

    it('borrowerFraDebt() should return correct fraDebt if delta is 0', async () => {
      await agreement.setDelta(0);

      assert.equal(await agreement.borrowerFraDebt.call(), 0);
    });

    it('borrowerFraDebt() should return correct fraDebt if delta is > 0', async () => {
      await agreement.setDelta(10);

      assert.equal(await agreement.borrowerFraDebt.call(), 0);
    });

    it('borrowerFraDebt() should return correct fraDebt if delta is < 0', async () => {
      await agreement.setDelta(toBN(-10).pow(toBN(31)));

      assert.equal((await agreement.borrowerFraDebt.call()).toString(), 10000);
    });
  });

  describe('_updateAgreementState()', async () => {
    beforeEach('init config', async () => {
      configContract = await Config.new();
      await configContract
      .setGeneral(1440, 60, 2, 100, toBN(100).times(toBN(10).pow(toBN(18))), 86400, 31536000);
    });

    it('should calculate correctly with valid values case 1', async () => {
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000, fromPercentToRey(3),
        ETH_A, true, configContract.address, {from: OWNER, value: 2000});

      await agreement.approveAgreement();
      await agreement.matchAgreement({from: LENDER});
      await agreement.setDsr(toBN(1000000000005000000000000000));
      await agreement.setLastCheckTime(50);
      await agreement.setCurrentTime(100000);
      await agreement.setUnlockedDai(toBN(300000));

      const result = await agreement.updateAgreementState();

      assert.equal((await agreement.borrowerFraDebt.call()).toNumber(), 28);
      assert.equal((await agreement.delta.call()).toString(), '-28374606558287520397889908041');
      assert.equal((await agreement.deltaCommon.call()).toString(),
        '-28374606558287520397889908041');

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'AgreementUpdated');
      assert.equal(result.logs[0].args._injectionAmount, 0);
      assert.equal(result.logs[0].args._delta, -28374606558287520397889908041);
      assert.equal(result.logs[0].args._deltaCommon, -28374606558287520397889908041);
      assert.equal(result.logs[0].args._savingsDifference.toString(),
        '-28374606558287520397889908041');
    });

    it('should calculate correctly with valid values case 2', async () => {
      await agreement.initAgreement(BORROWER, 2000, 1, 90000, fromPercentToRey(3),
        ETH_A, true, configContract.address, {from: OWNER, value: 2000});

      await agreement.approveAgreement();
      await agreement.matchAgreement({from: LENDER});
      await agreement.setDsr(toBN(1000000000005000000000000000));
      await agreement.setLastCheckTime(50);
      await agreement.setCurrentTime(100000);
      await agreement.setUnlockedDai(toBN(1));

      const result = await agreement.updateAgreementState();

      assert.equal((await agreement.borrowerFraDebt.call()).toNumber(), 0);
      assert.equal((await agreement.delta.call()).toString(), '-94582021860958401326299');
      assert.equal((await agreement.deltaCommon.call()).toString(), '-94582021860958401326299');

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'AgreementUpdated');
      assert.equal(result.logs[0].args._injectionAmount, 0);
      assert.equal(result.logs[0].args._delta, -94582021860958401326299);
      assert.equal(result.logs[0].args._deltaCommon, -94582021860958401326299);
      assert.equal(result.logs[0].args._savingsDifference.toString(), '-94582021860958401326299');
    });

    it('should calculate correctly with valid values case 3', async () => {
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000, fromPercentToRey(3),
        ETH_A, true, configContract.address, {from: OWNER, value: 2000});

      await agreement.approveAgreement();
      await agreement.matchAgreement({from: LENDER});
      await agreement.setDsr(toBN(1000000070000000000000000000));
      await agreement.setLastCheckTime(50);
      await agreement.setCurrentTime(100000);
      await agreement.setUnlockedDai(toBN(300000));

      const result = await agreement.updateAgreementState();

      assert.equal((await agreement.borrowerFraDebt.call()).toNumber(), 0);
      assert.equal((await agreement.delta.call()).toString(), '576441163269106903756478638');
      assert.equal((await agreement.deltaCommon.call()).toString(),
        '7666576441163269106903756478638');

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'AgreementUpdated');
      assert.equal(result.logs[0].args._injectionAmount, 7666);
      assert.equal(result.logs[0].args._delta, 576441163269106903756478638);
      assert.equal(result.logs[0].args._deltaCommon, 7666576441163269106903756478638);
      assert.equal(result.logs[0].args._savingsDifference.toString(),
        '7666576441163269106903756478638');
    });

    it('should calculate correctly with valid values case 4', async () => {
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000, fromPercentToRey(3),
        ETH_A, true, configContract.address, {from: OWNER, value: 2000});

      await agreement.approveAgreement();
      await agreement.matchAgreement({from: LENDER});
      await agreement.setDsr(toBN(1000000099000000000000000000));
      await agreement.setLastCheckTime(50);
      await agreement.setCurrentTime(500000);
      await agreement.setUnlockedDai(toBN(300000));

      const result = await agreement.updateAgreementState();

      assert.equal((await agreement.borrowerFraDebt.call()).toNumber(), 0);
      assert.equal((await agreement.delta.call()).toString(), '871661599566448101809453013');
      assert.equal((await agreement.deltaCommon.call()).toString(),
        '103029871661599566448101809453013');

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'AgreementUpdated');
      assert.equal(result.logs[0].args._injectionAmount, 103029);
      assert.equal(result.logs[0].args._delta, 871661599566448101809453013);
      assert.equal(result.logs[0].args._deltaCommon, 103029871661599566448101809453013);
      assert.equal(result.logs[0].args._savingsDifference.toString(),
        '103029871661599566448101809453013');
    });

    it('should calculate correctly with valid values case 5', async () => {
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000, fromPercentToRey(3),
        ETH_A, true, configContract.address, {from: OWNER, value: 2000});

      await agreement.approveAgreement();
      await agreement.matchAgreement({from: LENDER});
      await agreement.setDsr(toBN(1000000000000000000000400000));
      await agreement.setLastCheckTime(50);
      await agreement.setCurrentTime(500000);
      await agreement.setUnlockedDai(toBN(300000));
      await agreement.setDelta(toBN(871661599566448101809453013));

      const result = await agreement.updateAgreementState();

      assert.equal((await agreement.borrowerFraDebt.call()).toNumber(), 141);
      assert.equal((await agreement.delta.call()).toString(), '-141808132920981497205479452054');
      assert.equal((await agreement.deltaCommon.call()).toString(),
        '-142679794520547945205479452054');

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'AgreementUpdated');
      assert.equal(result.logs[0].args._injectionAmount, 0);
      assert.equal(result.logs[0].args._delta, -141808132920981497205479452054);
      assert.equal(result.logs[0].args._deltaCommon, -142679794520547945205479452054);
      assert.equal(result.logs[0].args._savingsDifference.toString(),
        '-142679794520547945205479452054');
    });

    it('should calculate correctly 2 updates one after the other with different time periods', async () => {
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000, fromPercentToRey(3),
        ETH_A, true, configContract.address, {from: OWNER, value: 2000});

      await agreement.approveAgreement();
      await agreement.matchAgreement({from: LENDER});
      await agreement.setDsr(toBN(1000000070000000000000000000));
      await agreement.setLastCheckTime(50);
      await agreement.setCurrentTime(100000);
      await agreement.setUnlockedDai(toBN(300000));

      let result = await agreement.updateAgreementState();

      assert.equal((await agreement.borrowerFraDebt.call()).toNumber(), 0);
      assert.equal((await agreement.delta.call()).toString(), '576441163269106903756478638');
      assert.equal((await agreement.deltaCommon.call()).toString(),
        '7666576441163269106903756478638');

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'AgreementUpdated');
      assert.equal(result.logs[0].args._injectionAmount, 7666);
      assert.equal(result.logs[0].args._delta, 576441163269106903756478638);
      assert.equal(result.logs[0].args._deltaCommon, 7666576441163269106903756478638);
      assert.equal(result.logs[0].args._savingsDifference.toString(),
        '7666576441163269106903756478638');

      await agreement.setCurrentTime(200000);
      await agreement.setUnlockedDai(toBN(292334));
      result = await agreement.updateAgreementState();

      assert.equal((await agreement.borrowerFraDebt.call()).toNumber(), 0);
      assert.equal((await agreement.delta.call()).toString(), '564529313300701955343351112');
      assert.equal((await agreement.deltaCommon.call()).toString(),
        '23003564529313300701955343351112');

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'AgreementUpdated');
      assert.equal(result.logs[0].args._injectionAmount, 15337);
      assert.equal(result.logs[0].args._delta, 564529313300701955343351112);
      assert.equal(result.logs[0].args._deltaCommon, 23003564529313300701955343351112);
      assert.equal(result.logs[0].args._savingsDifference.toString(),
        '15336988088150031595051586872474');
    });

    it('should calculate correctly 2 updates one after the other with different time periods and different dsr', async () => {
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000, fromPercentToRey(3),
        ETH_A, true, configContract.address, {from: OWNER, value: 2000});

      await agreement.approveAgreement();
      await agreement.matchAgreement({from: LENDER});
      await agreement.setDsr(toBN(1000000070000000000000000000));
      await agreement.setLastCheckTime(50);
      await agreement.setCurrentTime(100000);
      await agreement.setUnlockedDai(toBN(300000));

      let result = await agreement.updateAgreementState();

      assert.equal((await agreement.borrowerFraDebt.call()).toNumber(), 0);
      assert.equal((await agreement.delta.call()).toString(), '576441163269106903756478638');
      assert.equal((await agreement.deltaCommon.call()).toString(),
        '7666576441163269106903756478638');

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'AgreementUpdated');
      assert.equal(result.logs[0].args._injectionAmount, 7666);
      assert.equal(result.logs[0].args._delta, 576441163269106903756478638);
      assert.equal(result.logs[0].args._deltaCommon, 7666576441163269106903756478638);
      assert.equal(result.logs[0].args._savingsDifference.toString(),
        '7666576441163269106903756478638');

      await agreement.setDsr(toBN(1000000000000000000500000000));
      await agreement.setCurrentTime(400000);
      await agreement.setUnlockedDai(toBN(292334));
      result = await agreement.updateAgreementState();

      assert.equal((await agreement.borrowerFraDebt.call()).toNumber(), 113);
      assert.equal((await agreement.delta.call()).toString(), '-113564540571890710447841694877');
      assert.equal((await agreement.deltaCommon.call()).toString(),
        '7552435459428109289552158305123');

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'AgreementUpdated');
      assert.equal(result.logs[0].args._injectionAmount, 0);
      assert.equal(result.logs[0].args._delta, -113564540571890710447841694877);
      assert.equal(result.logs[0].args._deltaCommon, 7552435459428109289552158305123);
      assert.equal(result.logs[0].args._savingsDifference.toString(),
        '-114140981735159817351598173515');
    });

    it('should calculate correctly 2 updates one after the other with different time periods and different dsr case 2', async () => {
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000, fromPercentToRey(3),
        ETH_A, true, configContract.address, {from: OWNER, value: 2000});

      await agreement.approveAgreement();
      await agreement.matchAgreement({from: LENDER});
      await agreement.setDsr(toBN(1000000000005000000000000000));
      await agreement.setLastCheckTime(50);
      await agreement.setCurrentTime(100000);
      await agreement.setUnlockedDai(toBN(300000));

      let result = await agreement.updateAgreementState();

      assert.equal((await agreement.borrowerFraDebt.call()).toNumber(), 28);
      assert.equal((await agreement.delta.call()).toString(), '-28374606558287520397889908041');
      assert.equal((await agreement.deltaCommon.call()).toString(),
        '-28374606558287520397889908041');

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'AgreementUpdated');
      assert.equal(result.logs[0].args._injectionAmount, 0);
      assert.equal(result.logs[0].args._delta, -28374606558287520397889908041);
      assert.equal(result.logs[0].args._deltaCommon, -28374606558287520397889908041);
      assert.equal(result.logs[0].args._savingsDifference.toString(),
        '-28374606558287520397889908041');

      await agreement.setDsr(toBN(1000000000400000000000000000));
      await agreement.setCurrentTime(400000);

      result = await agreement.updateAgreementState();

      assert.equal((await agreement.borrowerFraDebt.call()).toNumber(), 94);
      assert.equal((await agreement.delta.call()).toString(), '-94217603696661333541977069664');
      assert.equal((await agreement.deltaCommon.call()).toString(),
        '-94217603696661333541977069664');

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'AgreementUpdated');
      assert.equal(result.logs[0].args._injectionAmount, 0);
      assert.equal(result.logs[0].args._delta, -94217603696661333541977069664);
      assert.equal(result.logs[0].args._deltaCommon, -94217603696661333541977069664);
      assert.equal(result.logs[0].args._savingsDifference.toString(),
        '-65842997138373813144087161623');
    });

    it('should inject a valid value if delta > 0', async () => {
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000, fromPercentToRey(3),
        ETH_A, true, configContract.address, {from: OWNER, value: 2000});

      await agreement.approveAgreement();
      await agreement.matchAgreement({from: LENDER});
      await agreement.setDsr(toBN(1000000097000000000000000000));
      await agreement.setLastCheckTime(50);
      await agreement.setCurrentTime(100000);
      await agreement.setUnlockedDai(toBN(300000));

      const result = await agreement.updateAgreementState();

      assert.equal((await agreement.borrowerFraDebt.call()).toNumber(), 0);
      assert.equal((await agreement.delta.call()).toString(), '851428396335582781259763913');
      assert.equal((await agreement.deltaCommon.call()).toString(),
        '19278851428396335582781259763913');

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'AgreementUpdated');
      assert.equal(result.logs[0].args._injectionAmount, 19278);
      assert.equal(result.logs[0].args._delta, 851428396335582781259763913);
      assert.equal(result.logs[0].args._deltaCommon, 19278851428396335582781259763913);
      assert.equal(result.logs[0].args._savingsDifference.toString(),
        '19278851428396335582781259763913');
    });

    it('should inject a valid value if delta < 0, borrower debt > 0 and dsr rises to be more than interestRate', async () => {
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000, fromPercentToRey(3),
        ETH_A, true, configContract.address, {from: OWNER, value: 2000});

      await agreement.approveAgreement();
      await agreement.matchAgreement({from: LENDER});
      await agreement.setDsr(toBN(1000000097000000000000000000));
      await agreement.setLastCheckTime(50);
      await agreement.setCurrentTime(100000);
      await agreement.setUnlockedDai(toBN(300000));
      await agreement.setDelta(toBN(-28374606558287520397889908041));

      assert.equal((await agreement.borrowerFraDebt.call()).toNumber(), 28);

      const result = await agreement.updateAgreementState();

      assert.equal((await agreement.borrowerFraDebt.call()).toNumber(), 0);
      assert.equal((await agreement.delta.call()).toString(), '476821838048059781259763913');
      assert.equal((await agreement.deltaCommon.call()).toString(),
        '19278851428396335582781259763913');

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'AgreementUpdated');
      assert.equal(result.logs[0].args._injectionAmount, 19250);
      assert.equal(result.logs[0].args._delta, 476821838048059781259763913);
      assert.equal(result.logs[0].args._deltaCommon, 19278851428396335582781259763913);
      assert.equal(result.logs[0].args._savingsDifference.toString(),
        '19278851428396335582781259763913');
    });
  });

  describe('_refund()', async () => {
    beforeEach('init config', async () => {
      configContract = await Config.new();
      await configContract
      .setGeneral(1440, 60, 2, 100, toBN(100).times(toBN(10).pow(toBN(18))), 86400, 31536000);
    });

    it('should be possible to refund if borrower debt = 0 and agreement is not liquidated', async () => {
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000,
        fromPercentToRey(3), ETH_A, true, configContract.address, {from: OWNER, value: 2000});
      await agreement.approveAgreement();
      await agreement.matchAgreement({from: LENDER});
      await agreement.setUnlockedDai(300000);

      const result = await agreement.refund(false);

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'RefundBase');
      assert.equal(result.logs[0].args.lender, LENDER);
      assert.equal(result.logs[0].args.lenderRefundDai, 300000);
      assert.equal(result.logs[0].args.borrower, BORROWER);
      assert.equal(result.logs[0].args.cdpId, (await agreement.cdpId.call()).toNumber());
    });

    it('should be possible to refund if borrower debt > 0 and agreement is not liquidated', async () => {
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000,
        fromPercentToRey(3), ETH_A, true, configContract.address, {from: OWNER, value: 2000});
      await agreement.approveAgreement();
      await agreement.matchAgreement({from: LENDER});
      await agreement.setUnlockedDai(300000);
      await agreement.setDelta(toBN(-28374606558287520397889908041));

      const result = await agreement.refund(false);

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'RefundBase');
      assert.equal(result.logs[0].args.lender, LENDER);
      assert.equal(result.logs[0].args.lenderRefundDai, 300028);
      assert.equal(result.logs[0].args.borrower, BORROWER);
      assert.equal(result.logs[0].args.cdpId, (await agreement.cdpId.call()).toNumber());
    });
  });

  describe('_terminate()', async () => {
    beforeEach('init config', async () => {
      configContract = await Config.new();
      await configContract
      .setGeneral(1440, 60, 2, 100, toBN(100).times(toBN(10).pow(toBN(18))), 86400, 31536000);
    });

    it('should be possible to terminate agreement is not liquidated', async () => {
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000,
        fromPercentToRey(3), ETH_A, true, configContract.address, {from: OWNER, value: 2000});
      await agreement.approveAgreement();
      await agreement.matchAgreement({from: LENDER});
      await agreement.setUnlockedDai(300000);
      await agreement.setCurrentTime(555);

      const result = await agreement.terminateAgreement();

      assert.isTrue(await agreement.terminateAgreement.call());
      assert.equal((await agreement.closeDate.call()).toNumber(), 555);
      assert.equal((await agreement.status.call()).toNumber(), 9);

      assert.equal(result.logs.length, 2);
      assert.equal(result.logs[0].event, 'RefundBase');
      assert.equal(result.logs[1].event, 'AgreementTerminated');
    });

    it('should be possible to terminate if borrower debt > 0 and agreement is not liquidated', async () => {
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000,
        fromPercentToRey(3), ETH_A, true, configContract.address, {from: OWNER, value: 2000});
      await agreement.approveAgreement();
      await agreement.matchAgreement({from: LENDER});
      await agreement.setUnlockedDai(300000);
      await agreement.setCurrentTime(555);
      await agreement.setDelta(toBN(-28374606558287520397889908041));

      const result = await agreement.terminateAgreement();

      assert.isTrue(await agreement.terminateAgreement.call());
      assert.equal((await agreement.closeDate.call()).toNumber(), 555);
      assert.equal((await agreement.status.call()).toNumber(), 9);

      assert.equal(result.logs.length, 2);
      assert.equal(result.logs[0].event, 'RefundBase');
      assert.equal(result.logs[1].event, 'AgreementTerminated');
    });
  });
});
