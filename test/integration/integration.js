const Agreement = artifacts.require('Agreement');
const FraFactory = artifacts.require('FraFactory');
const Config = artifacts.require('Config');
const {assertReverts} = require('../helpers/assertThrows');
const BigNumber = require('bignumber.js');
const setCurrentTime = require('../helpers/ganacheTimeTraveler.js');
const ERC20Token = artifacts.require('IERC20');

const toBN = (num) => {
  return new BigNumber(num);
};

const fromPercentToRey = (num) => {
  return (toBN(num).times((toBN(10).pow(toBN(25))))).plus((toBN(10).pow(toBN(27))));
};

contract('Integration', async (accounts) => {
  let configContract;
  let agreement;
  let fraFactory;
  let daiToken;

  const daiAddress17Release = '0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa';

  const OWNER = accounts[0];
  const BORROWER = accounts[1];
  const LENDER = accounts[2];
  const ETH_A = '0x4554482d41000000000000000000000000000000000000000000000000000000';
  const ADDRESS_NULL = '0x0000000000000000000000000000000000000000';

  beforeEach('setup', async () => {
    agreement = await Agreement.new();
    configContract = await Config.new();
    fraFactory = await FraFactory.new(agreement.address, configContract.address);
    await configContract.setGeneral(1440, 60, 2, 100,
      toBN(100).times(toBN(10).pow(toBN(18))), 86400, 31536000, 10);

    daiToken = await ERC20Token.at(daiAddress17Release);
  });

  describe('Case when agreement is initialized by borrower and immediately canceled by borrower', async () => {
    it('', async () => {
      const initiatiziationResult = await agreement.initAgreement(BORROWER, 2300, 300000, 90000,
        fromPercentToRey(3), ETH_A, true, configContract.address, {from: OWNER, value: 2300});

      console.log('Agreement initialized');
      assert.equal((await agreement.duration.call()).toNumber(), 90000);
      console.log('Agreement duration is 900');
      assert.equal(await agreement.borrower.call(), BORROWER);
      console.log('Agreement borrower is ' + BORROWER);
      assert.equal((await agreement.debtValue.call()).toNumber(), 300000);
      console.log('Agreement debtValue is 300000');
      assert.equal((await agreement.interestRate.call()).toString(), fromPercentToRey(3).toFixed());
      console.log('Agreement interestRate is ' + fromPercentToRey(3).toFixed());
      assert.equal((await agreement.collateralAmount.call()).toNumber(), 2300);
      console.log('Agreement collateralAmount is 2300');
      assert.equal(await agreement.collateralType.call(), ETH_A);
      console.log('Agreement collateralType is ' + ETH_A);
      assert.equal((await agreement.status()).toString(), 1);
      console.log('Agreement collateralType is 1');

      assert.equal(initiatiziationResult.logs.length, 2);
      assert.equal(initiatiziationResult.logs[1].event, 'AgreementInitiated');
      assert.equal(initiatiziationResult.logs[1].args._borrower, BORROWER);
      assert.equal(initiatiziationResult.logs[1].args._collateralValue.toNumber(), 2300);
      assert.equal(initiatiziationResult.logs[1].args._debtValue.toNumber(), 300000);
      assert.equal(initiatiziationResult.logs[1].args._expireDate.toNumber(), 90000);
      assert.equal(initiatiziationResult.logs[1].args._interestRate.toString(), fromPercentToRey(3).toFixed());
      console.log('Event ' + initiatiziationResult.logs[1].event + ' emmited');

      const resultCanceled = await agreement.cancelAgreement({from: BORROWER});
      console.log('Agreement canceled by borrower');
      assert.equal((await agreement.assets(BORROWER)).collateral.toString(), 2300);
      console.log('Borrower gets collateral asset equal to 2300');

      assert.equal((await agreement.status()).toString(), 4);
      console.log('Agreement status is 4');

      assert.equal(resultCanceled.logs.length, 2);
      assert.equal(resultCanceled.logs[1].event, 'AgreementClosed');
      console.log('Event ' + resultCanceled.logs[1].event + ' emmited');
    });
  });

  describe('Case when agreement is initialized by borrower, gets approved by owner and immediately canceled by borrower', async () => {
    it('', async () => {
      const initiatiziationResult = await agreement.initAgreement(BORROWER, 2300, 300000, 90000,
        fromPercentToRey(3), ETH_A, true, configContract.address, {from: OWNER, value: 2300});

      console.log('Agreement initialized');
      assert.equal((await agreement.duration.call()).toNumber(), 90000);
      console.log('Agreement duration is 900');
      assert.equal(await agreement.borrower.call(), BORROWER);
      console.log('Agreement borrower is ' + BORROWER);
      assert.equal((await agreement.debtValue.call()).toNumber(), 300000);
      console.log('Agreement debtValue is 300000');
      assert.equal((await agreement.interestRate.call()).toString(), fromPercentToRey(3).toFixed());
      console.log('Agreement interestRate is ' + fromPercentToRey(3).toFixed());
      assert.equal((await agreement.collateralAmount.call()).toNumber(), 2300);
      console.log('Agreement collateralAmount is 2300');
      assert.equal(await agreement.collateralType.call(), ETH_A);
      console.log('Agreement collateralType is ' + ETH_A);
      assert.equal((await agreement.status()).toString(), 1);
      console.log('Agreement status is 1');

      assert.equal(initiatiziationResult.logs.length, 2);
      assert.equal(initiatiziationResult.logs[1].event, 'AgreementInitiated');
      assert.equal(initiatiziationResult.logs[1].args._borrower, BORROWER);
      assert.equal(initiatiziationResult.logs[1].args._collateralValue.toNumber(), 2300);
      assert.equal(initiatiziationResult.logs[1].args._debtValue.toNumber(), 300000);
      assert.equal(initiatiziationResult.logs[1].args._expireDate.toNumber(), 90000);
      assert.equal(initiatiziationResult.logs[1].args._interestRate.toString(), fromPercentToRey(3).toFixed());
      console.log('Event ' + initiatiziationResult.logs[1].event + ' emmited');

      const resultApproved = await agreement.approveAgreement();
      console.log('Agreement approved');

      assert.equal(resultApproved.logs.length, 1);
      assert.equal(resultApproved.logs[0].event, 'AgreementApproved');
      console.log('Event ' + resultApproved.logs[0].event + ' emmited');

      assert.equal((await agreement.status()).toString(), 2);

      const resultCanceled = await agreement.cancelAgreement({from: BORROWER});
      console.log('Agreement canceled by borrower');
      assert.equal((await agreement.assets(BORROWER)).collateral.toString(), 2300);
      console.log('Borrower gets collateral asset equal to 2300');

      assert.equal((await agreement.status()).toString(), 4);
      console.log('Agreement status is 4');

      assert.equal(resultCanceled.logs.length, 2);
      assert.equal(resultCanceled.logs[1].event, 'AgreementClosed');
      console.log('Event ' + resultCanceled.logs[1].event + ' emmited');
    });
  });

  describe.only('Case when agreement is initialized by borrower, gets approved by owner, gets matched by lender, gets updated and expires', async () => {
    it('', async () => {
      const initiatiziationResult = await agreement.initAgreement(BORROWER, 230, 3000, 90000,
        fromPercentToRey(3), ETH_A, true, configContract.address, {from: OWNER, value: 230});

      console.log('Agreement initialized');
      assert.equal((await agreement.duration.call()).toNumber(), 90000);
      console.log('Agreement duration is 900');
      assert.equal(await agreement.borrower.call(), BORROWER);
      console.log('Agreement borrower is ' + BORROWER);
      assert.equal((await agreement.debtValue.call()).toNumber(), 3000);
      console.log('Agreement debtValue is 3000');
      assert.equal((await agreement.interestRate.call()).toString(), fromPercentToRey(3).toFixed());
      console.log('Agreement interestRate is ' + fromPercentToRey(3).toFixed());
      assert.equal((await agreement.collateralAmount.call()).toNumber(), 230);
      console.log('Agreement collateralAmount is 230');
      assert.equal(await agreement.collateralType.call(), ETH_A);
      console.log('Agreement collateralType is ' + ETH_A);
      assert.equal((await agreement.status()).toString(), 1);
      console.log('Agreement status is 1');

      assert.equal(initiatiziationResult.logs.length, 2);
      assert.equal(initiatiziationResult.logs[1].event, 'AgreementInitiated');
      assert.equal(initiatiziationResult.logs[1].args._borrower, BORROWER);
      assert.equal(initiatiziationResult.logs[1].args._collateralValue.toNumber(), 230);
      assert.equal(initiatiziationResult.logs[1].args._debtValue.toNumber(), 3000);
      assert.equal(initiatiziationResult.logs[1].args._expireDate.toNumber(), 90000);
      assert.equal(initiatiziationResult.logs[1].args._interestRate.toString(), fromPercentToRey(3).toFixed());
      console.log('Event ' + initiatiziationResult.logs[1].event + ' emmited');

      const resultApproved = await agreement.approveAgreement();
      console.log('Agreement approved');

      assert.equal(resultApproved.logs.length, 1);
      assert.equal(resultApproved.logs[0].event, 'AgreementApproved');
      console.log('Event ' + resultApproved.logs[0].event + ' emmited');

      assert.equal((await agreement.status()).toString(), 2);

      await daiToken.approve(agreement.address, 3000, {from: LENDER});
      const resultMatched = await agreement.matchAgreement({from: LENDER});

      assert.equal(await agreement.lender(), LENDER);
      console.log('Lender is + ', LENDER);
      assert.equal((await agreement.status()).toString(), 3);
      console.log('Agreement status is 3 - active');
    });
  });
});
