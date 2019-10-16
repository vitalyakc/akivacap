const Agreement = artifacts.require('AgreementMock');
const Reverter = require('./helpers/reverter');
const {assertReverts} = require('./helpers/assertThrows')
const BigNumber = require('bignumber.js');

contract('Agreement', async (accounts) => {
  const reverter = new Reverter(web3);

  let agreement;

  const OWNER = accounts[0];
  const BORROWER = accounts[1];
  const LENDER = accounts[2];
  const NOBODY = accounts[3];
  const ETH_A = '0x4554482d41000000000000000000000000000000000000000000000000000000';
  const WRONG_COLLATERAL = '0x0000000000000000000000000000000000000000000000000000000000000000'
  const ONE_MINUTE = 60;

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
    it('should be possible to initialize with average agruments on ETH', async () => {
      const result = await agreement.initAgreement(BORROWER, 2000, 300000, 30, 3, 
        ETH_A, true, {from: OWNER, value: 2000});

      assert.equal((await agreement.duration.call()).toNumber(), 30 * ONE_MINUTE);
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
      assert.equal(result.logs[1].args._expireDate.toNumber(), 30 * ONE_MINUTE);
      assert.equal(result.logs[1].args._interestRate.toString(), fromPercentToRey(3).toFixed());
    })

    it('should be possible to initialize with average case 2 on ETH', async () => {
      const result = await agreement.initAgreement(BORROWER, 20000, 3000000, 10, 43, 
        ETH_A, true, {from: OWNER, value: 20000});

      assert.equal((await agreement.duration.call()).toNumber(), 10 * ONE_MINUTE);
      assert.equal(await agreement.borrower.call(), BORROWER);
      assert.equal((await agreement.debtValue.call()).toNumber(), 3000000);
      assert.equal((await agreement.interestRate.call()).toString(), fromPercentToRey(43).toFixed());
      assert.equal((await agreement.collateralAmount.call()).toNumber(), 20000);
      assert.equal(await agreement.collateralType.call(), ETH_A);

      assert.equal(result.logs.length, 2);
      assert.equal(result.logs[1].event, 'AgreementInitiated');
      assert.equal(result.logs[1].args._borrower, BORROWER);
      assert.equal(result.logs[1].args._collateralValue.toNumber(), 20000);
      assert.equal(result.logs[1].args._debtValue.toNumber(), 3000000);
      assert.equal(result.logs[1].args._expireDate.toNumber(), 10 * ONE_MINUTE);
      assert.equal(result.logs[1].args._interestRate.toString(), fromPercentToRey(43).toFixed());
    })

    it('should be possible to initialize with average case 3 on ETH', async () => {
      const result = await agreement.initAgreement(BORROWER, 2, 3, 8, 97, 
        ETH_A, true, {from: OWNER, value: 2});

      assert.equal((await agreement.duration.call()).toNumber(), 8 * ONE_MINUTE);
      assert.equal(await agreement.borrower.call(), BORROWER);
      assert.equal((await agreement.debtValue.call()).toNumber(), 3);
      assert.equal((await agreement.interestRate.call()).toString(), fromPercentToRey(97).toFixed());
      assert.equal((await agreement.collateralAmount.call()).toNumber(), 2);
      assert.equal(await agreement.collateralType.call(), ETH_A);

      assert.equal(result.logs.length, 2);
      assert.equal(result.logs[1].event, 'AgreementInitiated');
      assert.equal(result.logs[1].args._borrower, BORROWER);
      assert.equal(result.logs[1].args._collateralValue.toNumber(), 2);
      assert.equal(result.logs[1].args._debtValue.toNumber(), 3);
      assert.equal(result.logs[1].args._expireDate.toNumber(), 8 * ONE_MINUTE);
      assert.equal(result.logs[1].args._interestRate.toString(), fromPercentToRey(97).toFixed());
    })

    it('should be possible to initialize with interestRate = 100 on ETH', async () => {
      const result = await agreement.initAgreement(BORROWER, 2000, 300000, 30, 100, 
        ETH_A, true, {from: OWNER, value: 2000});

      assert.equal((await agreement.duration.call()).toNumber(), 30 * ONE_MINUTE);
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
      assert.equal(result.logs[1].args._expireDate.toNumber(), 30 * ONE_MINUTE);
      assert.equal(result.logs[1].args._interestRate.toString(), fromPercentToRey(100).toFixed());
    })

    it('should be possible to initialize with interestRate = 1 on ETH', async () => {
      const result = await agreement.initAgreement(BORROWER, 2000, 300000, 30, 1, 
        ETH_A, true, {from: OWNER, value: 2000});

      assert.equal((await agreement.duration.call()).toNumber(), 30 * ONE_MINUTE);
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
      assert.equal(result.logs[1].args._expireDate.toNumber(), 30 * ONE_MINUTE);
      assert.equal(result.logs[1].args._interestRate.toString(), fromPercentToRey(1).toFixed());
    })

    it('should be possible to initialize with duration = 1 on ETH', async () => {
      const result = await agreement.initAgreement(BORROWER, 2000, 300000, 1, 3, 
        ETH_A, true, {from: OWNER, value: 2000});

      assert.equal((await agreement.duration.call()).toNumber(), ONE_MINUTE);
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
      assert.equal(result.logs[1].args._expireDate.toNumber(), ONE_MINUTE);
      assert.equal(result.logs[1].args._interestRate.toString(), fromPercentToRey(3).toFixed());
    })

    it('should be possible to initialize with duration = 1 on ETH', async () => {
      const result = await agreement.initAgreement(BORROWER, 2000, 300000, 1, 3, 
        ETH_A, true, {from: OWNER, value: 2000});

      assert.equal((await agreement.duration.call()).toNumber(), ONE_MINUTE);
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
      assert.equal(result.logs[1].args._expireDate.toNumber(), ONE_MINUTE);
      assert.equal(result.logs[1].args._interestRate.toString(), fromPercentToRey(3).toFixed());
    })

    it('should not be possible to initialize with debtValue = 0', async () => {
      await assertReverts(agreement.initAgreement(BORROWER, 2000, 0, 30, 3, 
        ETH_A, true, {from: NOBODY, value: 2000}));
    })

    it('should not be possible to initialize with interestRate more than 100', async () => {
      await assertReverts(agreement.initAgreement(BORROWER, 2000, 300000, 30, 101, 
        ETH_A, true, {from: NOBODY, value: 2000}));
    })

    it('should not be possible to initialize with interestRate more = 0', async () => {
      await assertReverts(agreement.initAgreement(BORROWER, 2000, 300000, 30, 0, 
        ETH_A, true, {from: NOBODY, value: 2000}));
    })

    it('should not be possible to initialize with interestRate more than 100', async () => {
      await assertReverts(agreement.initAgreement(BORROWER, 2000, 300000, 30, 101, 
        ETH_A, true, {from: NOBODY, value: 2000}));
    })

    it('should not be possible to initialize with duration = 0', async () => {
      await assertReverts(agreement.initAgreement(BORROWER, 2000, 300000, 0, 3, 
        ETH_A, true, {from: NOBODY, value: 2000}));
    })

    it('should not be possible to initialize with collateralAmount bigger than actual value', async () => {
      await assertReverts(agreement.initAgreement(BORROWER, 2000, 300000, 30, 3, 
        ETH_A, true, {from: NOBODY, value: 2001}));
    })

    it('should not be possible to initialize with collateralAmount less than actual value', async () => {
      await assertReverts(agreement.initAgreement(BORROWER, 2000, 300000, 30, 3, 
        ETH_A, true, {from: NOBODY, value: 1999}));
    })

    // Not implemented yet
    // it('should not be possible to initialize with collateralAmount = 0', async () => { 
    //   await assertReverts(agreement.initAgreement(BORROWER, 0, 300000, 30, 3, 
    //     ETH_A, true, {from: NOBODY, value: 0}));
    // })

    // Not implemented Yet
    // it('should not be possible to initialize with wrong collateral type', async () => {
    //   await assertReverts(agreement.initAgreement(BORROWER, 2000, 30000, 30, 3, 
    //     WRONG_COLLATERAL, true, {from: NOBODY, value: 2000}));
    // })
  })
});