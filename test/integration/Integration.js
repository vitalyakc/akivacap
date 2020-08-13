const Agreement = artifacts.require('Agreement');
const FraFactory = artifacts.require('FraFactory');
const Config = artifacts.require('Config');
const BigNumber = require('bignumber.js');
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
  let daiToken;

  const daiAddress17Release = '0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa';

  const OWNER = accounts[0];
  const BORROWER = accounts[1];
  const LENDER = accounts[2];
  const ETH_A_SYM = "ETH-A"
  const ETH_A_IDX = '0x4554482d41000000000000000000000000000000000000000000000000000000';

  beforeEach('setup', async () => {
    agreement = await Agreement.new();
    configContract = await Config.new();
    fraFactory = await FraFactory.new(agreement.address, configContract.address);
    await configContract.setGeneral(1440, 60, 2, 100,
      toBN(100).times(toBN(10).pow(toBN(18))), 0, 31536000, 10);

    daiToken = await ERC20Token.at(daiAddress17Release);
  });

  describe('Case when agreement is initialized by borrower and immediately canceled by borrower', async () => {
    it('', async () => {
      const initiatiziationResult = await agreement.initAgreement(BORROWER, 2300, 30000, 90000,
        fromPercentToRey(3), ETH_A_SYM, ETH_A_IDX, true, configContract.address, {from: OWNER, value: 2300});

      console.log(agreement.address);

      console.log('Agreement initialized');
      assert.equal((await agreement.duration.call()).toString(), 90000);
      console.log('Agreement duration is 900');
      assert.equal(await agreement.borrower.call(), BORROWER);
      console.log('Agreement borrower is ' + BORROWER);
      assert.equal((await agreement.debtValue.call()).toString(), 30000);
      console.log('Agreement debtValue is 30000');
      assert.equal((await agreement.interestRate.call()).toString(), fromPercentToRey(3).toFixed());
      console.log('Agreement interestRate is ' + fromPercentToRey(3).toFixed());
      assert.equal((await agreement.collateralAmount.call()).toString(), 2300);
      console.log('Agreement collateralAmount is 2300');
      assert.equal(await agreement.collateralType.call(), ETH_A_SYM);
      console.log('Agreement collateralType is ' + ETH_A_SYM, ETH_A_IDX);
      assert.equal((await agreement.status()).toString(), 1);
      console.log('Agreement collateralType is 1');

      assert.equal(initiatiziationResult.logs.length, 2);
      assert.equal(initiatiziationResult.logs[1].event, 'AgreementInitiated');
      assert.equal(initiatiziationResult.logs[1].args._borrower, BORROWER);
      assert.equal(initiatiziationResult.logs[1].args._collateralValue.toString(), 2300);
      assert.equal(initiatiziationResult.logs[1].args._debtValue.toString(), 30000);
      assert.equal(initiatiziationResult.logs[1].args._expireDate.toString(), 90000);
      assert.equal(initiatiziationResult.logs[1].args._interestRate.toString(),
        fromPercentToRey(3).toFixed());
      console.log('Event ' + initiatiziationResult.logs[1].event + ' emmited');

      const resultCanceled = await agreement.cancelAgreement({from: BORROWER});
      console.log('Agreement canceled by borrower');
      assert.equal((await agreement.assets(BORROWER)).collateral.toString(), 2300);
      console.log('Borrower gets collateral asset equal to 2300');

      assert.equal((await agreement.status()).toString(), 4);
      console.log('Agreement status is 4');

      assert.equal(resultCanceled.logs.length, 2);
      assert.equal(resultCanceled.logs[0].event, 'AgreementClosed');
      console.log('Event ' + resultCanceled.logs[0].event + ' emmited');
    });
  });

  describe('Case when agreement is initialized by borrower and gets rejected by owner', async () => {
    it('', async () => {
      const initiatiziationResult = await agreement.initAgreement(BORROWER, 2300, 30000, 90000,
        fromPercentToRey(3), ETH_A_SYM, ETH_A_IDX, true, configContract.address, {from: OWNER, value: 2300});

      console.log(agreement.address);

      console.log('Agreement initialized');
      assert.equal((await agreement.duration.call()).toString(), 90000);
      console.log('Agreement duration is 900');
      assert.equal(await agreement.borrower.call(), BORROWER);
      console.log('Agreement borrower is ' + BORROWER);
      assert.equal((await agreement.debtValue.call()).toString(), 30000);
      console.log('Agreement debtValue is 30000');
      assert.equal((await agreement.interestRate.call()).toString(), fromPercentToRey(3).toFixed());
      console.log('Agreement interestRate is ' + fromPercentToRey(3).toFixed());
      assert.equal((await agreement.collateralAmount.call()).toString(), 2300);
      console.log('Agreement collateralAmount is 2300');
      assert.equal(await agreement.collateralType.call(), ETH_A_SYM);
      console.log('Agreement collateralType is ' + ETH_A_SYM, ETH_A_IDX);
      assert.equal((await agreement.status()).toString(), 1);
      console.log('Agreement status is 1');

      assert.equal(initiatiziationResult.logs.length, 2);
      assert.equal(initiatiziationResult.logs[1].event, 'AgreementInitiated');
      assert.equal(initiatiziationResult.logs[1].args._borrower, BORROWER);
      assert.equal(initiatiziationResult.logs[1].args._collateralValue.toString(), 2300);
      assert.equal(initiatiziationResult.logs[1].args._debtValue.toString(), 30000);
      assert.equal(initiatiziationResult.logs[1].args._expireDate.toString(), 90000);
      assert.equal(initiatiziationResult.logs[1].args._interestRate.toString(),
        fromPercentToRey(3).toFixed());
      console.log('Event ' + initiatiziationResult.logs[1].event + ' emmited');

      await agreement.rejectAgreement();
      console.log('Agreement rejected');

      assert.equal((await agreement.status()).toString(), 4);
    });
  });

  describe('Case when agreement is initialized by borrower, gets approved by owner and immediately canceled by borrower', async () => {
    it('', async () => {
      const initiatiziationResult = await agreement.initAgreement(BORROWER, 2300, 30000, 90000,
        fromPercentToRey(3), ETH_A_SYM, ETH_A_IDX, true, configContract.address, {from: OWNER, value: 2300});

      console.log(agreement.address);

      console.log('Agreement initialized');
      assert.equal((await agreement.duration.call()).toString(), 90000);
      console.log('Agreement duration is 900');
      assert.equal(await agreement.borrower.call(), BORROWER);
      console.log('Agreement borrower is ' + BORROWER);
      assert.equal((await agreement.debtValue.call()).toString(), 30000);
      console.log('Agreement debtValue is 30000');
      assert.equal((await agreement.interestRate.call()).toString(), fromPercentToRey(3).toFixed());
      console.log('Agreement interestRate is ' + fromPercentToRey(3).toFixed());
      assert.equal((await agreement.collateralAmount.call()).toString(), 2300);
      console.log('Agreement collateralAmount is 2300');
      assert.equal(await agreement.collateralType.call(), ETH_A_SYM);
      console.log('Agreement collateralType is ' + ETH_A_SYM);
      assert.equal((await agreement.status()).toString(), 1);
      console.log('Agreement status is 1');

      assert.equal(initiatiziationResult.logs.length, 2);
      assert.equal(initiatiziationResult.logs[1].event, 'AgreementInitiated');
      assert.equal(initiatiziationResult.logs[1].args._borrower, BORROWER);
      assert.equal(initiatiziationResult.logs[1].args._collateralValue.toString(), 2300);
      assert.equal(initiatiziationResult.logs[1].args._debtValue.toString(), 30000);
      assert.equal(initiatiziationResult.logs[1].args._expireDate.toString(), 90000);
      assert.equal(initiatiziationResult.logs[1].args._interestRate.toString(),
        fromPercentToRey(3).toFixed());
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
      assert.equal(resultCanceled.logs[0].event, 'AgreementClosed');
      console.log('Event ' + resultCanceled.logs[0].event + ' emmited');
    });
  });

  describe('Case when agreement is initialized by borrower, gets approved by owner, gets matched by lender, gets updated and terminated by owner', async () => {
    it('', async () => {
      const initiatiziationResult = await agreement.initAgreement(BORROWER,
        toBN(250000000000000000), toBN(20000000000000000000), 90000,
        fromPercentToRey(3), ETH_A_SYM, ETH_A_IDX, true, configContract.address,
        {from: OWNER, value: toBN(250000000000000000)});

      console.log(agreement.address);

      console.log('Agreement initialized');
      assert.equal((await agreement.duration.call()).toString(), 90000);
      console.log('Agreement duration is 900');
      assert.equal(await agreement.borrower.call(), BORROWER);
      console.log('Agreement borrower is ' + BORROWER);
      assert.equal((await agreement.debtValue.call()).toString(), '20000000000000000000');
      console.log('Agreement debtValue is 20000000000000000000');
      assert.equal((await agreement.interestRate.call()).toString(), fromPercentToRey(3).toFixed());
      console.log('Agreement interestRate is ' + fromPercentToRey(3).toFixed());
      assert.equal((await agreement.collateralAmount.call()).toString(), '250000000000000000');
      console.log('Agreement collateralAmount is 250000000000000000 wei');
      assert.equal(await agreement.collateralType.call(), ETH_A_SYM);
      console.log('Agreement collateralType is ' + ETH_A_SYM);
      assert.equal((await agreement.status()).toString(), 1);
      console.log('Agreement status is 1');

      assert.equal(initiatiziationResult.logs.length, 2);
      assert.equal(initiatiziationResult.logs[1].event, 'AgreementInitiated');
      assert.equal(initiatiziationResult.logs[1].args._borrower, BORROWER);
      assert.equal(initiatiziationResult.logs[1].args._collateralValue.toString(),
        '250000000000000000');
      assert.equal(initiatiziationResult.logs[1].args._debtValue.toString(),
        '20000000000000000000');
      assert.equal(initiatiziationResult.logs[1].args._expireDate.toString(), 90000);
      assert.equal(initiatiziationResult.logs[1].args._interestRate.toString(),
        fromPercentToRey(3).toFixed());
      console.log('Event ' + initiatiziationResult.logs[1].event + ' emmited');

      const resultApproved = await agreement.approveAgreement();
      console.log('Agreement approved');

      assert.equal(resultApproved.logs.length, 1);
      assert.equal(resultApproved.logs[0].event, 'AgreementApproved');
      console.log('Event ' + resultApproved.logs[0].event + ' emmited');

      assert.equal((await agreement.status()).toString(), 2);

      await daiToken.approve(agreement.address, toBN(20000000000000000000), {from: LENDER});
      const resultMatched = await agreement.matchAgreement({from: LENDER});

      console.log('Agreement matched');
      console.log('Cdp id is ' + resultMatched.logs[0].args._cdpId);
      console.log('expire date is ' + resultMatched.logs[0].args._expireDate);

      assert.equal(await agreement.lender(), LENDER);
      console.log('Lender is '+ LENDER);
      assert.equal((await agreement.status()).toString(), 3);
      console.log('Agreement status is 3 - active');

      assert.equal(resultMatched.logs.length, 2);
      assert.equal(resultMatched.logs[0].event, 'AgreementMatched');
      assert.equal(resultMatched.logs[0].args._lender, LENDER);
      assert.equal(resultMatched.logs[0].args._collateralAmount, '250000000000000000');
      assert.equal(resultMatched.logs[0].args._debtValue, '20000000000000000000');
      assert.equal(resultMatched.logs[0].args._drawnDai, '20000000000000000000');

      await agreement.updateAgreement();
      console.log('Agreement updated');
      await agreement.updateAgreement();
      console.log('Agreement updated');
      await agreement.updateAgreement();
      console.log('Agreement updated');

      await agreement.blockAgreement();
      console.log('Agreement blocked by owner');

      assert.equal((await agreement.status()).toString(), 4);

      console.log((await agreement.assets(LENDER)).dai
      .toString() + ' Amount of dai available to withdraw by lender');

      await agreement.withdrawDai((await agreement.assets(LENDER)).dai, {from: LENDER});
      console.log('Lender gets debt dai back');

      await agreement.withdrawDai((await agreement.assets(BORROWER)).dai,
        {from: BORROWER});

      console.log('Borrower gets dai for deposited eth');
    });
  });

  describe('Case when agreement is initialized by borrower, gets approved by owner, gets matched by lender, gets updated few times, becomes risky and borrower adds some collateral after gets updated few more times', async () => {
    it('', async () => {
      const initiatiziationResult = await agreement.initAgreement(BORROWER,
        toBN(250000000000000000), toBN(28000000000000000000), 90000,
        fromPercentToRey(3), ETH_A_SYM, ETH_A_IDX, true, configContract.address,
        {from: OWNER, value: toBN(250000000000000000)});

      console.log(agreement.address);

      console.log('Agreement initialized');
      assert.equal((await agreement.duration.call()).toString(), 90000);
      console.log('Agreement duration is 900');
      assert.equal(await agreement.borrower.call(), BORROWER);
      console.log('Agreement borrower is ' + BORROWER);
      assert.equal((await agreement.debtValue.call()).toString(), '28000000000000000000');
      console.log('Agreement debtValue is 28000000000000000000');
      assert.equal((await agreement.interestRate.call()).toString(), fromPercentToRey(3).toFixed());
      console.log('Agreement interestRate is ' + fromPercentToRey(3).toFixed());
      assert.equal((await agreement.collateralAmount.call()).toString(), '250000000000000000');
      console.log('Agreement collateralAmount is 250000000000000000 wei');
      assert.equal(await agreement.collateralType.call(), ETH_A_SYM);
      console.log('Agreement collateralType is ' + ETH_A_SYM);
      assert.equal((await agreement.status()).toString(), 1);
      console.log('Agreement status is 1');

      assert.equal(initiatiziationResult.logs.length, 3);
      assert.equal(initiatiziationResult.logs[1].event, 'AgreementInitiated');
      assert.equal(initiatiziationResult.logs[1].args._borrower, BORROWER);
      assert.equal(initiatiziationResult.logs[1].args._collateralValue.toString(),
        '250000000000000000');
      assert.equal(initiatiziationResult.logs[1].args._debtValue.toString(),
        '28000000000000000000');
      assert.equal(initiatiziationResult.logs[1].args._expireDate.toString(), 90000);
      assert.equal(initiatiziationResult.logs[1].args._interestRate.toString(),
        fromPercentToRey(3).toFixed());
      console.log('Event ' + initiatiziationResult.logs[1].event + ' emmited');

      const resultApproved = await agreement.approveAgreement();
      console.log('Agreement approved');

      assert.equal(resultApproved.logs.length, 1);
      assert.equal(resultApproved.logs[0].event, 'AgreementApproved');
      console.log('Event ' + resultApproved.logs[0].event + ' emmited');

      assert.equal((await agreement.status()).toString(), 2);

      await daiToken.approve(agreement.address, toBN(28000000000000000000), {from: LENDER});
      const resultMatched = await agreement.matchAgreement({from: LENDER});

      console.log('Agreement matched');
      console.log('Cdp id is ' + resultMatched.logs[0].args._cdpId);
      console.log('expire date is ' + resultMatched.logs[0].args._expireDate);

      assert.equal(await agreement.lender(), LENDER);
      console.log('Lender is '+ LENDER);
      assert.equal((await agreement.status()).toString(), 3);
      console.log('Agreement status is 3 - active');

      assert.equal(resultMatched.logs.length, 2);
      assert.equal(resultMatched.logs[0].event, 'AgreementMatched');
      assert.equal(resultMatched.logs[0].args._lender, LENDER);
      assert.equal(resultMatched.logs[0].args._collateralAmount, '250000000000000000');
      assert.equal(resultMatched.logs[0].args._debtValue, '28000000000000000000');
      assert.equal(resultMatched.logs[0].args._drawnDai, '28000000000000000000');

      await agreement.updateAgreement();
      console.log('Agreement updated');
      await agreement.updateAgreement();
      console.log('Agreement updated');
      await agreement.updateAgreement();
      console.log('Agreement updated');

      await agreement.lockAdditionalCollateral(toBN(50000000000000000),
        {from: BORROWER, value: toBN(50000000000000000)});

      console.log('Borrower added collateral 0.05 eth');

      assert.equal((await agreement.collateralAmount()).toString(), '300000000000000000');
      console.log('New collateral amount is 300000000000000000 wei or 0.3 eth');

      await agreement.updateAgreement();
      console.log('Agreement updated');
      await agreement.updateAgreement();
      console.log('Agreement updated');
      await agreement.updateAgreement();
      console.log('Agreement updated');

      await agreement.blockAgreement();
      console.log('Agreement blocked by owner');

      assert.equal((await agreement.status()).toString(), 4);

      console.log((await agreement.assets(LENDER)).dai
      .toString() + ' Amount of dai available to withdraw by lender');

      await agreement.withdrawDai((await agreement.assets(LENDER)).dai, {from: LENDER});
      console.log('Lender gets debt dai back');

      await agreement.withdrawDai((await agreement.assets(BORROWER)).dai,
        {from: BORROWER});

      console.log('Borrower gets dai for deposited eth');
    });
  });

  describe('Case when agreement is initialized by borrower, gets approved by owner, gets matched by lender, gets updated and expires with interestRate > DSR', async () => {
    it('', async () => {
      const initiatiziationResult = await agreement.initAgreement(BORROWER,
        toBN(250000000000000000), toBN(20000000000000000000), 90,
        fromPercentToRey(3), ETH_A_SYM, ETH_A_IDX, true, configContract.address,
        {from: OWNER, value: toBN(250000000000000000)});

      console.log(agreement.address);

      console.log('Agreement initialized');
      assert.equal((await agreement.duration.call()).toString(), 90);
      console.log('Agreement duration is 90');
      assert.equal(await agreement.borrower.call(), BORROWER);
      console.log('Agreement borrower is ' + BORROWER);
      assert.equal((await agreement.debtValue.call()).toString(), '20000000000000000000');
      console.log('Agreement debtValue is 20000000000000000000');
      assert.equal((await agreement.interestRate.call()).toString(), fromPercentToRey(3).toFixed());
      console.log('Agreement interestRate is ' + fromPercentToRey(3).toFixed());
      assert.equal((await agreement.collateralAmount.call()).toString(), '250000000000000000');
      console.log('Agreement collateralAmount is 250000000000000000 wei');
      assert.equal(await agreement.collateralType.call(), ETH_A_SYM);
      console.log('Agreement collateralType is ' + ETH_A_SYM);
      assert.equal((await agreement.status()).toString(), 1);
      console.log('Agreement status is 1');

      assert.equal(initiatiziationResult.logs.length, 2);
      assert.equal(initiatiziationResult.logs[1].event, 'AgreementInitiated');
      assert.equal(initiatiziationResult.logs[1].args._borrower, BORROWER);
      assert.equal(initiatiziationResult.logs[1].args._collateralValue.toString(),
        '250000000000000000');
      assert.equal(initiatiziationResult.logs[1].args._debtValue.toString(),
        '20000000000000000000');
      assert.equal(initiatiziationResult.logs[1].args._expireDate.toString(), 90);
      assert.equal(initiatiziationResult.logs[1].args._interestRate.toString(),
        fromPercentToRey(3).toFixed());
      console.log('Event ' + initiatiziationResult.logs[1].event + ' emmited');

      const resultApproved = await agreement.approveAgreement();
      console.log('Agreement approved');

      assert.equal(resultApproved.logs.length, 1);
      assert.equal(resultApproved.logs[0].event, 'AgreementApproved');
      console.log('Event ' + resultApproved.logs[0].event + ' emmited');

      assert.equal((await agreement.status()).toString(), 2);

      await daiToken.approve(agreement.address, toBN(20000000000000000000), {from: LENDER});
      const resultMatched = await agreement.matchAgreement({from: LENDER});

      console.log('Agreement matched');
      console.log('Cdp id is ' + resultMatched.logs[0].args._cdpId);
      console.log('expire date is ' + resultMatched.logs[0].args._expireDate);

      assert.equal(await agreement.lender(), LENDER);
      console.log('Lender is '+ LENDER);
      assert.equal((await agreement.status()).toString(), 3);
      console.log('Agreement status is 3 - active');

      assert.equal(resultMatched.logs.length, 2);
      assert.equal(resultMatched.logs[0].event, 'AgreementMatched');
      assert.equal(resultMatched.logs[0].args._lender, LENDER);
      assert.equal(resultMatched.logs[0].args._collateralAmount, '250000000000000000');
      assert.equal(resultMatched.logs[0].args._debtValue, '20000000000000000000');
      assert.equal(resultMatched.logs[0].args._drawnDai, '20000000000000000000');

      let resultTerminated;

      while (await agreement.status() < 4) {
        resultTerminated = await agreement.updateAgreement();
        console.log('Agreement updated');
      }

      assert.equal(resultTerminated.logs[0].event, 'AgreementClosed');
      assert.equal(resultTerminated.logs[0].args._closedType, 0);

      console.log('Agreement was canceled due to expiration');

      assert.equal((await agreement.status()).toString(), 4);

      console.log((await agreement.assets(LENDER)).dai
      .toString() + ' Amount of dai available to withdraw by lender');

      await agreement.withdrawDai((await agreement.assets(LENDER)).dai, {from: LENDER});
      console.log('Lender gets debt dai back');

      await agreement.withdrawDai((await agreement.assets(BORROWER)).dai,
        {from: BORROWER});

      console.log('Borrower gets dai for deposited eth');
    });
  });

  describe('Case when agreement is initialized by borrower, gets approved by owner, gets matched by lender, gets updated and expires with interestRate < DSR', async () => {
    it('', async () => {
      const initiatiziationResult = await agreement.initAgreement(BORROWER,
        toBN(300000000000000000), toBN(22000000000000000000), 90,
        '1005000000000000000000000000', ETH_A_SYM, ETH_A_IDX, true, configContract.address,
        {from: OWNER, value: toBN(300000000000000000)});

      console.log(agreement.address);

      console.log('Agreement initialized');
      assert.equal((await agreement.duration.call()).toString(), 90);
      console.log('Agreement duration is 90');
      assert.equal(await agreement.borrower.call(), BORROWER);
      console.log('Agreement borrower is ' + BORROWER);
      assert.equal((await agreement.debtValue.call()).toString(), '22000000000000000000');
      console.log('Agreement debtValue is 22000000000000000000');
      assert.equal((await agreement.interestRate.call()).toString(), '1005000000000000000000000000');
      console.log('Agreement interestRate is 1005000000000000000000000000');
      assert.equal((await agreement.collateralAmount.call()).toString(), '300000000000000000');
      console.log('Agreement collateralAmount is 300000000000000000 wei');
      assert.equal(await agreement.collateralType.call(), ETH_A_SYM);
      console.log('Agreement collateralType is ' + ETH_A_SYM);
      assert.equal((await agreement.status()).toString(), 1);
      console.log('Agreement status is 1');

      assert.equal(initiatiziationResult.logs.length, 2);
      assert.equal(initiatiziationResult.logs[1].event, 'AgreementInitiated');
      assert.equal(initiatiziationResult.logs[1].args._borrower, BORROWER);
      assert.equal(initiatiziationResult.logs[1].args._collateralValue.toString(),
        '300000000000000000');
      assert.equal(initiatiziationResult.logs[1].args._debtValue.toString(),
        '22000000000000000000');
      assert.equal(initiatiziationResult.logs[1].args._expireDate.toString(), 90);
      assert.equal(initiatiziationResult.logs[1].args._interestRate.toString(),
        '1005000000000000000000000000');
      console.log('Event ' + initiatiziationResult.logs[1].event + ' emmited');

      const resultApproved = await agreement.approveAgreement();
      console.log('Agreement approved');

      assert.equal(resultApproved.logs.length, 1);
      assert.equal(resultApproved.logs[0].event, 'AgreementApproved');
      console.log('Event ' + resultApproved.logs[0].event + ' emmited');

      assert.equal((await agreement.status()).toString(), 2);

      await daiToken.approve(agreement.address, toBN(22000000000000000000), {from: LENDER});
      const resultMatched = await agreement.matchAgreement({from: LENDER});

      console.log('Agreement matched');
      console.log('Cdp id is ' + resultMatched.logs[0].args._cdpId);
      console.log('expire date is ' + resultMatched.logs[0].args._expireDate);

      assert.equal(await agreement.lender(), LENDER);
      console.log('Lender is '+ LENDER);
      assert.equal((await agreement.status()).toString(), 3);
      console.log('Agreement status is 3 - active');

      assert.equal(resultMatched.logs.length, 2);
      assert.equal(resultMatched.logs[0].event, 'AgreementMatched');
      assert.equal(resultMatched.logs[0].args._lender, LENDER);
      assert.equal(resultMatched.logs[0].args._collateralAmount, '300000000000000000');
      assert.equal(resultMatched.logs[0].args._debtValue, '22000000000000000000');
      assert.equal(resultMatched.logs[0].args._drawnDai, '22000000000000000000');

      let resultTerminated;

      while (await agreement.status() < 4) {
        resultTerminated = await agreement.updateAgreement();
        console.log('Agreement updated');
      }

      assert.equal(resultTerminated.logs[0].event, 'AgreementClosed');
      assert.equal(resultTerminated.logs[0].args._closedType, 0);

      console.log('Agreement was canceled due to expiration');

      assert.equal((await agreement.status()).toString(), 4);

      console.log((await agreement.assets(LENDER)).dai
      .toString() + ' Amount of dai available to withdraw by lender');

      await agreement.withdrawDai((await agreement.assets(LENDER)).dai, {from: LENDER});
      console.log('Lender gets debt dai back');

      await agreement.withdrawDai((await agreement.assets(BORROWER)).dai,
        {from: BORROWER});

      console.log('Borrower gets dai for deposited eth');
    });
  });

  describe('Case when agreement is initialized by borrower, gets approved by owner, gets matched by lender, gets updated and gets liquidated', async () => {
    it('', async () => {
      const initiatiziationResult = await agreement.initAgreement(BORROWER,
        toBN(215771454874996400), '24999999000000000000', 60000,
        fromPercentToRey(5), ETH_A_SYM, ETH_A_IDX, true, configContract.address,
        {from: OWNER, value: toBN(215771454874996400)});

      console.log(agreement.address);

      console.log('Agreement initialized');
      assert.equal((await agreement.duration.call()).toString(), 60000);
      console.log('Agreement duration is 60000');
      assert.equal(await agreement.borrower.call(), BORROWER);
      console.log('Agreement borrower is ' + BORROWER);
      assert.equal((await agreement.debtValue.call()).toString(), '24999999000000000000');
      console.log('Agreement debtValue is 24999999000000000000');
      assert.equal((await agreement.interestRate.call()).toString(), fromPercentToRey(5).toFixed());
      console.log('Agreement interestRate is ' + fromPercentToRey(5).toFixed());
      assert.equal((await agreement.collateralAmount.call()).toString(), '215771454874996400');
      console.log('Agreement collateralAmount is 215771454874996400 wei');
      assert.equal(await agreement.collateralType.call(), ETH_A_SYM);
      console.log('Agreement collateralType is ' + ETH_A_SYM);
      assert.equal((await agreement.status()).toString(), 1);
      console.log('Agreement status is 1');

      assert.equal(initiatiziationResult.logs.length, 3);
      assert.equal(initiatiziationResult.logs[1].event, 'AgreementInitiated');
      assert.equal(initiatiziationResult.logs[1].args._borrower, BORROWER);
      assert.equal(initiatiziationResult.logs[1].args._collateralValue.toString(),
        '215771454874996400');
      assert.equal(initiatiziationResult.logs[1].args._debtValue.toString(),
        '24999999000000000000');
      assert.equal(initiatiziationResult.logs[1].args._expireDate.toString(), 60000);
      assert.equal(initiatiziationResult.logs[1].args._interestRate.toString(),
        fromPercentToRey(5).toFixed());
      console.log('Event ' + initiatiziationResult.logs[1].event + ' emmited');

      const resultApproved = await agreement.approveAgreement();
      console.log('Agreement approved');

      assert.equal(resultApproved.logs.length, 1);
      assert.equal(resultApproved.logs[0].event, 'AgreementApproved');
      console.log('Event ' + resultApproved.logs[0].event + ' emmited');

      assert.equal((await agreement.status()).toString(), 2);

      await daiToken.approve(agreement.address, '24999999000000000000', {from: LENDER});
      const resultMatched = await agreement.matchAgreement({from: LENDER});

      console.log('Agreement matched');
      console.log('Cdp id is ' + resultMatched.logs[0].args._cdpId);
      console.log('expire date is ' + resultMatched.logs[0].args._expireDate);

      assert.equal(await agreement.lender(), LENDER);
      console.log('Lender is '+ LENDER);
      assert.equal((await agreement.status()).toString(), 3);
      console.log('Agreement status is 3 - active');

      assert.equal(resultMatched.logs.length, 2);
      assert.equal(resultMatched.logs[0].event, 'AgreementMatched');
      assert.equal(resultMatched.logs[0].args._lender, LENDER);
      assert.equal(resultMatched.logs[0].args._collateralAmount, '215771454874996400');
      assert.equal(resultMatched.logs[0].args._debtValue, '24999999000000000000');
      assert.equal(resultMatched.logs[0].args._drawnDai, '24999999000000000000');

      let resultLiquidated;

      while (await agreement.status() < 4) {
        resultLiquidated = await agreement.updateAgreement();
        console.log('Agreement updated');
      }

      assert.equal(resultLiquidated.logs[0].event, 'AgreementClosed');
      assert.equal(resultLiquidated.logs[0].args._closedType, 1);

      console.log('Agreement was liquidated');

      console.log((await agreement.assets(LENDER)).dai
      .toString() + ' Amount of dai available to withdraw by lender');

      await agreement.withdrawDai((await agreement.assets(LENDER)).dai, {from: LENDER});
      console.log('Lender gets debt dai back');

      await agreement.withdrawDai((await agreement.assets(BORROWER)).dai,
        {from: BORROWER});

      console.log('Borrower gets dai for deposited eth');
    });
  });

  // for reviving lost tokens from agreement contract
  //   describe.only('withdraw lost tokens', async () => {
  //     it('', async () => {
  //       const localAgreemnet = await Agreement.at('0x545a519A719DaBFe7DEa988D3D9d3d2d9d0D414e');

  //       // await localAgreemnet.blockAgreement();
  //       // console.log('Agreement blocked by owner');

  //       await localAgreemnet.withdrawDai((await localAgreemnet.assets(LENDER)).dai,
  //         {from: LENDER});
  //       console.log('Lender gets debt dai back');
  //   });
  // });
});
