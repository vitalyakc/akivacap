const Agreement = artifacts.require('AgreementMock');
const Config = artifacts.require('Config');
const Reverter = require('./helpers/reverter');
const {assertReverts} = require('./helpers/assertThrows')
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
  const WRONG_COLLATERAL = '0x0000000000000000000000000000000000000000000000000000000000000000'

  const toBN = (num) => {
    return new BigNumber(num);
  }

  const fromPercentToRey = (num) => {
    return (toBN(num).times((toBN(10).pow(toBN(25))))).plus((toBN(10).pow(toBN(27))));
  }
  before('setup', async () => {
    agreement = await Agreement.new({from: OWNER});    

    await reverter.snapshot();
  });

  afterEach('revert', reverter.revert);

  describe('initialize()', async () => {
    beforeEach('init config', async () => {
      configContract = await Config.new();
      await configContract.setGeneral(1440, 60, 2, 100, toBN(100).times(toBN(10).pow(toBN(18))), 86400, 31536000);
    })

    it('should be possible to initialize with average agruments on ETH', async () => {
      const result = await agreement.initAgreement(BORROWER, 2000, 300000, 90000, 3, 
        ETH_A, true, configContract.address, {from: OWNER, value: 2000});

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
    })

    it('should be possible to initialize with average case 2 on ETH', async () => {
      const result = await agreement.initAgreement(BORROWER, 20000, 300000, 90639, 43, 
        ETH_A, true, configContract.address, {from: OWNER, value: 20000});

      assert.equal((await agreement.duration.call()).toNumber(), 90639);
      assert.equal(await agreement.borrower.call(), BORROWER);
      assert.equal((await agreement.debtValue.call()).toNumber(), 300000);
      assert.equal((await agreement.interestRate.call()).toString(), fromPercentToRey(43).toFixed());
      assert.equal((await agreement.collateralAmount.call()).toNumber(), 20000);
      assert.equal(await agreement.collateralType.call(), ETH_A);

      assert.equal(result.logs.length, 2);
      assert.equal(result.logs[1].event, 'AgreementInitiated');
      assert.equal(result.logs[1].args._borrower, BORROWER);
      assert.equal(result.logs[1].args._collateralValue.toNumber(), 20000);
      assert.equal(result.logs[1].args._debtValue.toNumber(), 300000);
      assert.equal(result.logs[1].args._expireDate.toNumber(), 90639);
      assert.equal(result.logs[1].args._interestRate.toString(), fromPercentToRey(43).toFixed());
    })

    it('should be possible to initialize with average case 3 on ETH', async () => {
      const result = await agreement.initAgreement(BORROWER, 150, 300, 120008, 97, 
        ETH_A, true, configContract.address, {from: OWNER, value: 150});

      assert.equal((await agreement.duration.call()).toNumber(), 120008);
      assert.equal(await agreement.borrower.call(), BORROWER);
      assert.equal((await agreement.debtValue.call()).toNumber(), 300);
      assert.equal((await agreement.interestRate.call()).toString(), fromPercentToRey(97).toFixed());
      assert.equal((await agreement.collateralAmount.call()).toNumber(), 150);
      assert.equal(await agreement.collateralType.call(), ETH_A);

      assert.equal(result.logs.length, 2);
      assert.equal(result.logs[1].event, 'AgreementInitiated');
      assert.equal(result.logs[1].args._borrower, BORROWER);
      assert.equal(result.logs[1].args._collateralValue.toNumber(), 150);
      assert.equal(result.logs[1].args._debtValue.toNumber(), 300);
      assert.equal(result.logs[1].args._expireDate.toNumber(), 120008);
      assert.equal(result.logs[1].args._interestRate.toString(), fromPercentToRey(97).toFixed());
    })

    it('should be possible to initialize with interestRate = 100 on ETH', async () => {
      const result = await agreement.initAgreement(BORROWER, 2000, 300000, 110031, 100, 
        ETH_A, true, configContract.address, {from: OWNER, value: 2000});

      assert.equal((await agreement.duration.call()).toNumber(), 110031);
      assert.equal(await agreement.borrower.call(), BORROWER);
      assert.equal((await agreement.debtValue.call()).toNumber(), 300000);
      assert.equal((await agreement.interestRate.call()).toString(), fromPercentToRey(100).toFixed());
      assert.equal((await agreement.collateralAmount.call()).toNumber(), 2000);
      assert.equal(await agreement.collateralType.call(), ETH_A);

      assert.equal(result.logs.length, 2);
      assert.equal(result.logs[1].event, 'AgreementInitiated');
      assert.equal(result.logs[1].args._borrower, BORROWER);
      assert.equal(result.logs[1].args._collateralValue.toNumber(), 2000);
      assert.equal(result.logs[1].args._debtValue.toNumber(), 300000);
      assert.equal(result.logs[1].args._expireDate.toNumber(), 110031);
      assert.equal(result.logs[1].args._interestRate.toString(), fromPercentToRey(100).toFixed());
    })

    it('should be possible to initialize with interestRate = 1 on ETH', async () => {
      const result = await agreement.initAgreement(BORROWER, 2000, 300000, 90000, 1, 
        ETH_A, true, configContract.address, {from: OWNER, value: 2000});

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
    })

    it('should be possible to initialize with duration = maxDuration - 1 on ETH', async () => {
      const result = await agreement.initAgreement(BORROWER, 2000, 300000, 31535999, 3, 
        ETH_A, true, configContract.address, {from: OWNER, value: 2000});

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
    })

    it('should be possible to initialize with duration = minDuratin + 1 on ETH', async () => {
      const result = await agreement.initAgreement(BORROWER, 2000, 300000, 86401, 3, 
        ETH_A, true, configContract.address, {from: OWNER, value: 2000});

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
    })

    it('should not be possible to initialize with debtValue = 0', async () => {
      await assertReverts(agreement.initAgreement(BORROWER, 2000, 0, 90000, 3, 
        ETH_A, true, configContract.address, {from: OWNER, value: 2000}));
    })

    it('should not be possible to initialize with interestRate = 0', async () => {
      await assertReverts(agreement.initAgreement(BORROWER, 2000, 300000, 90000, 0, 
        ETH_A, true, configContract.address, {from: OWNER, value: 2000}));
    })

    it('should not be possible to initialize with interestRate more than 100', async () => {
      await assertReverts(agreement.initAgreement(BORROWER, 2000, 300000, 90000, 101, 
        ETH_A, true, configContract.address, {from: OWNER, value: 2000}));
    })

    it('should not be possible to initialize duration less than minDuration', async () => {
      await assertReverts(agreement.initAgreement(BORROWER, 2000, 300000, 86300, 3, 
        ETH_A, true, configContract.address, {from: OWNER, value: 2000}));
    }) 

    it('should not be possible to initialize duration = minDuration', async () => {
      await assertReverts(agreement.initAgreement(BORROWER, 2000, 300000, 86400, 3, 
        ETH_A, true, configContract.address, {from: OWNER, value: 2000}));
    })

    it('should not be possible to initialize duration = maxDuration', async () => {
      await assertReverts(agreement.initAgreement(BORROWER, 2000, 300000, 31536000, 3, 
        ETH_A, true, configContract.address, {from: OWNER, value: 2000}));
    })

    it('should not be possible to initialize duration > maxDuration', async () => {
      await assertReverts(agreement.initAgreement(BORROWER, 2000, 300000, 71536000, 3, 
        ETH_A, true, configContract.address, {from: OWNER, value: 2000}));
    })

    it('should not be possible to initialize with collateralAmount bigger than actual value', async () => {
      await assertReverts(agreement.initAgreement(BORROWER, 2000, 300000, 90000, 3, 
        ETH_A, true, configContract.address, {from: OWNER, value: 2001}));
    })

    it('should not be possible to initialize with collateralAmount less than actual value', async () => {
      await assertReverts(agreement.initAgreement(BORROWER, 2000, 300000, 90000, 3, 
        ETH_A, true, configContract.address, {from: OWNER, value: 1999}));
    })

    it('should not be possible to initialize with collateralAmount = 0', async () => { 
      await assertReverts(agreement.initAgreement(BORROWER, 0, 300000, 90000, 3, 
        ETH_A, true, configContract.address, {from: OWNER, value: 0}));
    })

    it('should not be possible to initialize with wrong collateral type', async () => {
      await assertReverts(agreement.initAgreement(BORROWER, 2000, 300000, 90000, 3, 
        WRONG_COLLATERAL, true, configContract.address, {from: OWNER, value: 2000}));
    })

    it('should not be possible to initialize with valid collateral type but not enabled', async () => {
      await configContract.disableCollateral(ETH_A);
      await assertReverts(agreement.initAgreement(BORROWER, 2000, 300000, 90000, 3, 
        ETH_A, true, configContract.address, {from: OWNER, value: 2000}));
    })
  })

  describe('approveAgreement()', async () => {
    beforeEach('init config', async () => {
      configContract = await Config.new();
      await configContract.setGeneral(1440, 60, 2, 100, toBN(100).times(toBN(10).pow(toBN(18))), 86400, 31536000);
    })

    it('should be possible to approve agreement by owner after initialization', async () => {
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000, 3, 
        ETH_A, true, configContract.address, {from: OWNER, value: 2000});

      await agreement.setCurrentTime(1000);

      assert.equal((await agreement.status.call()).toNumber(), 0);
      const result = await agreement.approveAgreement();

      assert.equal((await agreement.status.call()).toNumber(), 1);

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'AgreementApproved');
      assert.equal((await agreement.approveDate.call()).toNumber(), 1000);
    })

    it('should not be possible to approve agreement by not owner after initialization', async () => {
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000, 3, 
        ETH_A, true, configContract.address, {from: OWNER, value: 2000});

      await agreement.setCurrentTime(1000);

      assert.equal((await agreement.status.call()).toNumber(), 0);
      await assertReverts(agreement.approveAgreement({from: NOBODY}));

      assert.equal((await agreement.status.call()).toNumber(), 0);
      assert.equal((await agreement.approveDate.call()).toNumber(), 0);
    })

    it('should not be possible to approve agreement by owner before initialization', async () => {
      assert.equal((await agreement.status.call()).toNumber(), 0);
      await assertReverts(agreement.approveAgreement());

      await agreement.setCurrentTime(1000);

      assert.equal((await agreement.status.call()).toNumber(), 0);
      assert.equal((await agreement.approveDate.call()).toNumber(), 0);
    })

    it('should not be possible to approve agreement by not owner before initialization', async () => {
      assert.equal((await agreement.status.call()).toNumber(), 0);
      await assertReverts(agreement.approveAgreement({from: NOBODY}));

      await agreement.setCurrentTime(1000);

      assert.equal((await agreement.status.call()).toNumber(), 0);
      assert.equal((await agreement.approveDate.call()).toNumber(), 0);
    })

    it('should not be possible to approve agreement by owner after it is already approved', async () => {
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000, 3, 
        ETH_A, true, configContract.address, {from: OWNER, value: 2000});

      await agreement.setCurrentTime(1000);

      assert.equal((await agreement.status.call()).toNumber(), 0);

      const result = await agreement.approveAgreement();

      assert.equal((await agreement.status.call()).toNumber(), 1);

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'AgreementApproved');

      await assertReverts(agreement.approveAgreement());

      assert.equal((await agreement.status.call()).toNumber(), 1);
      assert.equal((await agreement.approveDate.call()).toNumber(), 1000);
    })
  })

  describe('matchAgreement()', async () => {
    beforeEach('init config and init agreement', async () => {
      configContract = await Config.new();
      await configContract.setGeneral(1440, 60, 2, 100, toBN(100).times(toBN(10).pow(toBN(18))), 86400, 31536000);

      await agreement.initAgreement(BORROWER, 2000, 300000, 90000, 3, 
        ETH_A, true, configContract.address, {from: OWNER, value: 2000});
    });
    
    it('should be possible to match initialized and approved agreement by lender', async () => {
      await agreement.approveAgreement();

      assert.equal((await agreement.status.call()).toNumber(), 1);

      await agreement.setCurrentTime(2000);
      const result = await agreement.matchAgreement({from: LENDER});

      assert.equal((await agreement.status.call()).toNumber(), 2);
      assert.equal((await agreement.matchDate.call()).toNumber(), 2000);
      assert.equal((await agreement.lastCheckTime.call()).toNumber(), 2000);
      assert.equal((await agreement.expireDate.call()).toNumber(), 92000);
      assert.equal(await agreement.lender.call(), LENDER);

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'AgreementMatched');
      assert.equal(result.logs[0].args._lender, LENDER);
    })

    it('should not be possible to match initialized but not approved agreement by lender', async () => {
      assert.equal((await agreement.status.call()).toNumber(), 0);

      await assertReverts(agreement.matchAgreement({from: LENDER}));

      assert.equal((await agreement.status.call()).toNumber(), 0);
    })

    it('should not be possible to match initialized and approved agreement by borrower', async () => {
      assert.equal((await agreement.status.call()).toNumber(), 0);

      await assertReverts(agreement.matchAgreement({from: BORROWER}));

      assert.equal((await agreement.status.call()).toNumber(), 0);
    })
  })
});
