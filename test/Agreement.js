const Agreement = artifacts.require('AgreementDeepMock');
const Config = artifacts.require('ConfigMock');
const Reverter = require('./helpers/reverter');
const {assertReverts} = require('./helpers/assertThrows');
const BigNumber = require('bignumber.js');
const setCurrentTime = require('./helpers/ganacheTimeTraveler.js');

contract('Agreement', async (accounts) => {
  const reverter = new Reverter(web3);

  let configContract;
  let agreement;


  const YEAR_SEC = 60*60*24*365;
  const RAY = 10**27;
  const OWNER = accounts[0];
  const BORROWER = accounts[1];
  const LENDER = accounts[2];
  const NOBODY = accounts[3];
  const SOMEBODY = accounts[4];
  const ETH_A_IDX = web3.utils.hexToBytes('0x4554482d41000000000000000000000000000000000000000000000000000000');
  const ETH_A_SYM = web3.utils.fromAscii('ETH-A') + '000000000000000000000000000000000000000000000000000000';
  const WRONG_COLLATERAL = web3.utils.hexToBytes('0x0000000000000000000000000000000000000000000000000000000000000000');

  const printout = (comment, str1, str2) => {
    console.log(comment + " " + parseInt(str1)/(10**27) + " <VS> " + parseInt(str2)/(10**27) );
  }

  const printoutx = (comment, str1, str2) => {
    console.log("ASIS:  "+ comment + " " + (str1) + " <VS> " + (str2) );
  }

  const print_results = (result) => { 
    console.log("---------------------------");
    for (var i = 0; i < result.logs.length; i++)
      console.log("Log Entry " + i.toString() + " " + JSON.stringify(result.logs[i]));
    console.log("                           ");
  }

  //const FIVEPCTPERSEC  = (toBN('1000000001547125957863212448')).toFixed();
  // const FOURPCTPERSEC  = (toBN('1000000001243680656318820312')).toFixed();
  //const THREEPCTPERSEC = (toBN('1000000000937303470807876289')).toFixed();
  //const fromPercentToRay = (num) => {
  //  return (  toBN(num).times(  ( toBN(10).pow( toBN(25) ) )  )  ).plus((   toBN(10).pow(toBN(27))  ));
  //};

  const toBN = (num) => {
    return new BigNumber(num);
  };

  const fromPercentToRay = (num) => {
    x = Math.exp( Math.log((1.0+(num/100)))/YEAR_SEC );  
    return (BigNumber(Math.floor(x*RAY))).toFixed();
  };

  console.log( "collateral symbol bat-a in hex: " + web3.utils.fromAscii('BAT-A'));
  console.log ( ETH_A_SYM );

  before('setup', async () => {
    agreement = await Agreement.new({from: OWNER});
    console.log("Initialized agreement... ");
    await reverter.snapshot();
  });

  afterEach('revert', reverter.revert);

  describe('initialize()', async () => {
    beforeEach('init config', async () => {
      configContract = await Config.new();
      await configContract
      .setGeneral(1440, 60, 2, 100, toBN(100).times(toBN(10).pow(toBN(18))), 86400, 31536000, 10);

      await agreement.setCRBuffer(100);
    });

    it('should be possible to initialize with average agruments on WETH', async () => {
        agreement.initAgreement(BORROWER, toBN('1000000000000000000'), 25, 259200,
          toBN('1000000000937303600000000000'), ETH_A_SYM, true, configContract.address, {from: OWNER, value: 2000});
    });

    it('should be possible to initialize with average agruments on ETH', async () => {
      const result = await agreement.initAgreement(BORROWER, 2000, 300000, 90000,
        toBN('1000000000937303470807876289'), ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000});
      
      assert.equal((await agreement.duration.call()).toNumber(), 90000);
      assert.equal( await agreement.borrower.call(), BORROWER);
      assert.equal((await agreement.cdpDebtValue.call()).toNumber(), 300000);
      assert.equal((await agreement.interestRate.call()).toString(), (toBN('1000000000937303470807876289')).toFixed());
      assert.equal((await agreement.collateralAmount.call()).toNumber(), 2000);
      console.log ( "---> collateral type in contract: ", await agreement.collateralType.call() ); 
      assert.equal((await agreement.collateralType.call()).replace(/0+$/,''), ETH_A_SYM);
      assert.equal((await agreement.status()).toString(), 1);

      assert.equal(result.logs.length, 2);
      assert.equal(result.logs[1].event, 'AgreementInitiated');
      assert.equal(result.logs[1].args._borrower, BORROWER);
      assert.equal(result.logs[1].args._collateralValue.toNumber(), 2000);
      assert.equal(result.logs[1].args._debtValue.toNumber(), 300000);
      assert.equal(result.logs[1].args._expireDate.toNumber(), 90000);
      assert.equal(result.logs[1].args._interestRate.toString(), (toBN('1000000000937303470807876289')).toFixed());
    });

    it('should be possible to initialize with average case 2 on ETH', async () => {
      const result = await agreement.initAgreement(BORROWER, 20000, 300000, 90639,
        fromPercentToRay(43), ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 20000});

      assert.equal((await agreement.duration.call()).toNumber(), 90639);
      assert.equal(await agreement.borrower.call(), BORROWER);
      assert.equal((await agreement.cdpDebtValue.call()).toNumber(), 300000);
      assert.equal((await agreement.interestRate.call()).toString(),
        fromPercentToRay(43));
      assert.equal((await agreement.collateralAmount.call()).toNumber(), 20000);
      //assert.equal(await agreement.collateralType.call(), ETH_A_SYM);
      assert.equal((await agreement.status()).toString(), 1);

      assert.equal(result.logs.length, 2);
      assert.equal(result.logs[1].event, 'AgreementInitiated');
      assert.equal(result.logs[1].args._borrower, BORROWER);
      assert.equal(result.logs[1].args._collateralValue.toNumber(), 20000);
      assert.equal(result.logs[1].args._debtValue.toNumber(), 300000);
      assert.equal(result.logs[1].args._expireDate.toNumber(), 90639);
      assert.equal(result.logs[1].args._interestRate.toString(), fromPercentToRay(43));
    });

    it('should be possible to initialize with average case 3 on ETH', async () => {
      const result = await agreement.initAgreement(BORROWER, 150, 300, 120008, fromPercentToRay(97),
        ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 150});

      assert.equal((await agreement.duration.call()).toNumber(), 120008);
      assert.equal(await agreement.borrower.call(), BORROWER);
      assert.equal((await agreement.cdpDebtValue.call()).toNumber(), 300);
      assert.equal((await agreement.interestRate.call()).toString(),
        fromPercentToRay(97));
      assert.equal((await agreement.collateralAmount.call()).toNumber(), 150);
      //assert.equal(await agreement.collateralType.call(), ETH_A_SYM);
      assert.equal((await agreement.status()).toString(), 1);

      assert.equal(result.logs.length, 2);
      assert.equal(result.logs[1].event, 'AgreementInitiated');
      assert.equal(result.logs[1].args._borrower, BORROWER);
      assert.equal(result.logs[1].args._collateralValue.toNumber(), 150);
      assert.equal(result.logs[1].args._debtValue.toNumber(), 300);
      assert.equal(result.logs[1].args._expireDate.toNumber(), 120008);
      assert.equal(result.logs[1].args._interestRate.toString(), fromPercentToRay(97));
    });

    it('should be possible to initialize with interestRate = 100 on ETH', async () => {
      const result = await agreement.initAgreement(BORROWER, 2000, 300000, 110031,
        fromPercentToRay(100), ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000});

      assert.equal((await agreement.duration.call()).toNumber(), 110031);
      assert.equal(await agreement.borrower.call(), BORROWER);
      assert.equal((await agreement.cdpDebtValue.call()).toNumber(), 300000);
      assert.equal((await agreement.interestRate.call()).toString(),
        fromPercentToRay(100));
      assert.equal((await agreement.collateralAmount.call()).toNumber(), 2000);
      //assert.equal(await agreement.collateralType.call(), ETH_A_SYM);
      assert.equal((await agreement.status()).toString(), 1);

      assert.equal(result.logs.length, 2);
      assert.equal(result.logs[1].event, 'AgreementInitiated');
      assert.equal(result.logs[1].args._borrower, BORROWER);
      assert.equal(result.logs[1].args._collateralValue.toNumber(), 2000);
      assert.equal(result.logs[1].args._debtValue.toNumber(), 300000);
      assert.equal(result.logs[1].args._expireDate.toNumber(), 110031);
      assert.equal(result.logs[1].args._interestRate.toString(), fromPercentToRay(100));
    });

    it('should be possible to initialize with interestRate = 1 on ETH', async () => {
      const result = await agreement.initAgreement(BORROWER, 2000, 300000, 90000,
        fromPercentToRay(1), ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000});

      assert.equal((await agreement.duration.call()).toNumber(), 90000);
      assert.equal(await agreement.borrower.call(), BORROWER);
      assert.equal((await agreement.cdpDebtValue.call()).toNumber(), 300000);
      assert.equal((await agreement.interestRate.call()).toString(), fromPercentToRay(1));
      assert.equal((await agreement.collateralAmount.call()).toNumber(), 2000);
      //assert.equal(await agreement.collateralType.call(), ETH_A_SYM);
      assert.equal((await agreement.status()).toString(), 1);

      assert.equal(result.logs.length, 2);
      assert.equal(result.logs[1].event, 'AgreementInitiated');
      assert.equal(result.logs[1].args._borrower, BORROWER);
      assert.equal(result.logs[1].args._collateralValue.toNumber(), 2000);
      assert.equal(result.logs[1].args._debtValue.toNumber(), 300000);
      assert.equal(result.logs[1].args._expireDate.toNumber(), 90000);
      assert.equal(result.logs[1].args._interestRate.toString(), fromPercentToRay(1));
    });

    it('should be possible to initialize with duration = maxDuration - 1 on ETH', async () => {
      const result = await agreement.initAgreement(BORROWER, 2000, 300000, 31535999,
        fromPercentToRay(3), ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000});

      assert.equal((await agreement.duration.call()).toNumber(), 31535999);
      assert.equal(await agreement.borrower.call(), BORROWER);
      assert.equal((await agreement.cdpDebtValue.call()).toNumber(), 300000);
      assert.equal((await agreement.interestRate.call()).toString(), fromPercentToRay(3));
      assert.equal((await agreement.collateralAmount.call()).toNumber(), 2000);
      //assert.equal(await agreement.collateralType.call(), ETH_A_SYM);
      assert.equal((await agreement.status()).toString(), 1);

      assert.equal(result.logs.length, 2);
      assert.equal(result.logs[1].event, 'AgreementInitiated');
      assert.equal(result.logs[1].args._borrower, BORROWER);
      assert.equal(result.logs[1].args._collateralValue.toNumber(), 2000);
      assert.equal(result.logs[1].args._debtValue.toNumber(), 300000);
      assert.equal(result.logs[1].args._expireDate.toNumber(), 31535999);
      assert.equal(result.logs[1].args._interestRate.toString(), fromPercentToRay(3));
    });

    it('should be possible to initialize with duration = minDuratin + 1 on ETH', async () => {
      const result = await agreement.initAgreement(BORROWER, 2000, 300000, 86401,
        fromPercentToRay(3), ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000});

      assert.equal((await agreement.duration.call()).toNumber(), 86401);
      assert.equal(await agreement.borrower.call(), BORROWER);
      assert.equal((await agreement.cdpDebtValue.call()).toNumber(), 300000);
      assert.equal((await agreement.interestRate.call()).toString(), fromPercentToRay(3));
      assert.equal((await agreement.collateralAmount.call()).toNumber(), 2000);
      //assert.equal(await agreement.collateralType.call(), ETH_A_SYM);
      assert.equal((await agreement.status()).toString(), 1);

      assert.equal(result.logs.length, 2);
      assert.equal(result.logs[1].event, 'AgreementInitiated');
      assert.equal(result.logs[1].args._borrower, BORROWER);
      assert.equal(result.logs[1].args._collateralValue.toNumber(), 2000);
      assert.equal(result.logs[1].args._debtValue.toNumber(), 300000);
      assert.equal(result.logs[1].args._expireDate.toNumber(), 86401);
      assert.equal(result.logs[1].args._interestRate.toString(), fromPercentToRay(3));
    });

    it('should not be possible to initialize with debtValue = 0', async () => {
      await assertReverts(agreement.initAgreement(BORROWER, 2000, 0, 90000, fromPercentToRay(3),
        ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000}));

      assert.equal((await agreement.status()).toString(), 0);
    });

    // todo 
    //it('should not be possible to initialize with interestRate = 0', async () => {
    //  await assertReverts(agreement.initAgreement(BORROWER, 2000, 300000, 90000,
    //    fromPercentToRay(0), ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000}));
    //
    //  assert.equal((await agreement.status()).toString(), 0);
    //});

    //it('should not be possible to initialize with interestRate more than 100', async () => {
    //  await assertReverts(agreement.initAgreement(BORROWER, 2000, 300000, 90000,
    //    fromPercentToRay(101), ETH_A_SYM,  true, configContract.address, { from: OWNER, value: 2000 }));

    //  assert.equal((await agreement.status()).toString(), 0);
    //});

    it('should not be possible to initialize duration less than minDuration', async () => {
      await assertReverts(agreement.initAgreement(BORROWER, 2000, 300000, 86300,
        fromPercentToRay(3), ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000}));

      assert.equal((await agreement.status()).toString(), 0);
    });

    it('should not be possible to initialize duration = minDuration', async () => {
      await assertReverts(agreement.initAgreement(BORROWER, 2000, 300000, 86400,
        fromPercentToRay(3), ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000}));

      assert.equal((await agreement.status()).toString(), 0);
    });

    it('should not be possible to initialize duration = maxDuration', async () => {
      await assertReverts(agreement.initAgreement(BORROWER, 2000, 300000, 315360000,
        fromPercentToRay(3), ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000}));

      assert.equal((await agreement.status()).toString(), 0);
    });

    it('should not be possible to initialize duration > maxDuration', async () => {
      await assertReverts(agreement.initAgreement(BORROWER, 2000, 300000, 715360000,
        fromPercentToRay(3), ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000}));

      assert.equal((await agreement.status()).toString(), 0);
    });

    it('should not be possible to initialize with collateralAmount bigger than actual value', async () => {
      await assertReverts(agreement.initAgreement(BORROWER, 2000, 300000, 90000,
        fromPercentToRay(3), ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2001}));

      assert.equal((await agreement.status()).toString(), 0);
    });

    it('should not be possible to initialize with collateralAmount less than actual value', async () => {
      await assertReverts(agreement.initAgreement(BORROWER, 2000, 300000, 90000,
        fromPercentToRay(3), ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 1999}));

      assert.equal((await agreement.status()).toString(), 0);
    });

    it('should not be possible to initialize with collateralAmount = 0', async () => {
      await assertReverts(agreement.initAgreement(BORROWER, 0, 300000, 90000, fromPercentToRay(3),
        ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 0}));

      assert.equal((await agreement.status()).toString(), 0);
    });

    it('should not be possible to initialize with wrong collateral type', async () => {
      await assertReverts(agreement.initAgreement(BORROWER, 2000, 300000, 90000,
        fromPercentToRay(3), WRONG_COLLATERAL, true, configContract.address,
        {from: OWNER, value: 2000}));

      assert.equal((await agreement.status()).toString(), 0);
    });

    it('should not be possible to initialize with valid collateral type but not enabled', async () => {
      await configContract.disableCollateral(ETH_A_SYM);
      await assertReverts(agreement.initAgreement(BORROWER, 2000, 300000, 90000,
        fromPercentToRay(3), ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000}));

      assert.equal((await agreement.status()).toString(), 0);
    });
  });

  describe('approveAgreement()', async () => {
    beforeEach('init config', async () => {
      configContract = await Config.new();
      await configContract
      .setGeneral(1440, 60, 2, 100, toBN(100).times(toBN(10).pow(toBN(18))), 86400, 31536000, 10);
    });

    it('should be possible to approve agreement by owner after initialization', async () => {
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000, fromPercentToRay(3),
        ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000});

      await agreement.setCurrentTime(1000);

      assert.equal((await agreement.status.call()).toNumber(), 1);
      const result = await agreement.approveAgreement();

      assert.equal((await agreement.status.call()).toNumber(), 2);

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'AgreementApproved');
    });

    it('should not be possible to approve agreement by not owner after initialization', async () => {
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000, fromPercentToRay(3),
        ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000});

      await agreement.setCurrentTime(1000);

      assert.equal((await agreement.status.call()).toNumber(), 1);
      await assertReverts(agreement.approveAgreement({from: NOBODY}));

      assert.equal((await agreement.status.call()).toNumber(), 1);
    });

    it('should not be possible to approve agreement by owner before initialization', async () => {
      assert.equal((await agreement.status.call()).toNumber(), 0);
      await assertReverts(agreement.approveAgreement());

      await agreement.setCurrentTime(1000);

      assert.equal((await agreement.status.call()).toNumber(), 0);
    });

    it('should not be possible to approve agreement by not owner before initialization', async () => {
      assert.equal((await agreement.status.call()).toNumber(), 0);
      await assertReverts(agreement.approveAgreement({from: NOBODY}));

      await agreement.setCurrentTime(1000);

      assert.equal((await agreement.status.call()).toNumber(), 0);
    });

    it('should not be possible to approve agreement by owner after it is already approved', async () => {
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000, fromPercentToRay(3),
        ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000});

      await agreement.setCurrentTime(1000);

      assert.equal((await agreement.status.call()).toNumber(), 1);

      const result = await agreement.approveAgreement();

      assert.equal((await agreement.status.call()).toNumber(), 2);

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'AgreementApproved');

      await assertReverts(agreement.approveAgreement());

      assert.equal((await agreement.status.call()).toNumber(), 2);
    });
  });

  describe('matchAgreement()', async () => {
    beforeEach('init config and init agreement', async () => {
      configContract = await Config.new();
      await configContract
      .setGeneral(1440, 60, 2, 100, toBN(100).times(toBN(10).pow(toBN(18))), 86400, 31536000, 10);

      await agreement.setCRBuffer(100);

      await agreement.initAgreement(BORROWER, 2000, 300000, 90000, fromPercentToRay(3),
        ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000});
    });

    it('should be possible to match initialized and approved agreement by lender', async () => {
      await agreement.approveAgreement();

      assert.equal((await agreement.status.call()).toNumber(), 2);

      await setCurrentTime(2000);
      const result = await agreement.matchAgreement({from: LENDER});

      assert.equal((await agreement.status.call()).toNumber(), 3);
      assert.equal((await agreement.lastCheckTime.call()).toNumber(), 2000);
      assert.equal((await agreement.expireDate.call()).toNumber(), 92000);
      assert.equal(await agreement.lender.call(), LENDER);

      assert.equal(result.logs.length, 2);
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
      .setGeneral(1440, 60, 2, 100, toBN(100).times(toBN(10).pow(toBN(18))), 86400, 31536000, 10);

      await agreement.setCRBuffer(100);

      await agreement.initAgreement(BORROWER, 2000, 300000, 90000, fromPercentToRay(3),
        ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000});
    });

    it('should be possible to cancel agreement by borrower when it is not matched', async () => {
      assert.equal(await agreement.status.call(), 1);

      await agreement.cancelAgreement({from: BORROWER});

      assert.equal(await agreement.status.call(), 4);
    });

    it('should be possible to cancel agreement by borrower when it is not matched and approved', async () => {
      await agreement.approveAgreement();
      await agreement.cancelAgreement({from: BORROWER});

      assert.equal(await agreement.status.call(), 4);
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

      assert.equal(await agreement.status.call(), 4);
    });

    it('should be possible to reject agreement by owner when it is not matched and approved', async () => {
      await agreement.approveAgreement();
      await agreement.rejectAgreement();

      assert.equal(await agreement.status.call(), 4);
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

    it('should be possible to blockAgreemnet() by owner if status is active', async () => {
      await agreement.approveAgreement();
      await agreement.matchAgreement({from: LENDER});
      assert.equal((await agreement.status()).toString(), 3);

      await agreement.blockAgreement();

      assert.equal((await agreement.status()).toString(), 4);
    });

    it('should not be possible to blockAgreemnet() by owner if status is not active yet', async () => {
      await agreement.approveAgreement();
      assert.equal((await agreement.status()).toString(), 2);

      await assertReverts(agreement.blockAgreement());

      assert.equal((await agreement.status()).toString(), 2);
    });

    it('should not be possible to blockAgreemnet() by owner if status is closed', async () => {
      await agreement.approveAgreement();
      await agreement.matchAgreement({from: LENDER});
      assert.equal((await agreement.status()).toString(), 3);

      await agreement.blockAgreement();
      await assertReverts(agreement.blockAgreement());

      assert.equal((await agreement.status()).toString(), 4);
    });

    it('should not be possible to blockAgreemnet() by not owner', async () => {
      await agreement.approveAgreement();
      await agreement.matchAgreement({from: LENDER});
      assert.equal((await agreement.status()).toString(), 3);

      await assertReverts(agreement.blockAgreement({from: NOBODY}));

      assert.equal((await agreement.status()).toString(), 3);
    });
  });

  describe('borrowerFraDebt()', async () => {
    beforeEach('init config', async () => {
      configContract = await Config.new();
      await configContract
      .setGeneral(1440, 60, 2, 100, toBN(100).times(toBN(10).pow(toBN(18))), 86400, 31536000*10, 10);

      await agreement.setCRBuffer(100);
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
      //Arguments for setGeneral: 
      // uint _approveLimit, uint _matchLimit, uint _injectionThreshold,
      // uint _minCollateralAmount, uint _maxCollateralAmount, uint _minDuration, uint _maxDuration, uint _riskyMargin
      await configContract.setGeneral(1440, 60, 2, 100, toBN(100).times(toBN(10).pow(toBN(18))), 86400, 315360000, 10);
      await agreement.setCRBuffer(100);
    });


    it('should calculate correctly with valid values case 0', async () => {
      await setCurrentTime(10);
      console.log("Agreement initializing ...");
      //function initAgreement(address payable _borrower, uint256 _collateralAmount, uint256 _debtValue, uint256 _duration,
      //        uint256 _interestRatePercent, bytes32 _collateralType, bool _isETH, address _configAddr);
      await (agreement.initAgreement(BORROWER, 2000, 100000, YEAR_SEC+39, fromPercentToRay(5), //3%
                        ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000})) ;
      console.log("Agreement initialized ...");
      await setCurrentTime(10);
      await agreement.approveAgreement();
      await setCurrentTime(10);
      await debug(agreement.matchAgreement({from: LENDER}));
      await agreement.setDsr(fromPercentToRay(3)); 
      await agreement.setLastCheckTime(50);
      await agreement.setUnlockedDai(toBN(300000));
      await agreement.setDrawnCdp(5000); // vary result
      
      setCurrentTime( (60*60*24*365)+50 );// 1year
      console.log("fra debt before agr: "  + (await agreement.borrowerFraDebt.call()).toNumber() );
      console.log("lender assets before: " + (await agreement.assets(LENDER)).dai.toString());
      const result = await (agreement.updateAgreement());
      
      print_results(result);
      console.log("fra debt: "      + (await agreement.borrowerFraDebt.call()).toNumber() );
      console.log("delta: "         + (await agreement.delta.call()).toString() / (10**27));
      console.log("assets.lender: " + (await agreement.assets(LENDER)).dai.toString());
      console.log("drawn dai: "     + (await agreement.drawnTotal.call()).toNumber());
      console.log("done update agreement part!");
    });

    it('should calculate correctly with valid values case 1', async () => {
      await setCurrentTime(10);
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000, fromPercentToRay(3),
                        ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000}) ;
      await setCurrentTime(10);
      await agreement.approveAgreement();
      await setCurrentTime(10);
      await (agreement.matchAgreement({from: LENDER}));
      console.log("lender matched: " + (await agreement.lender.call()));
      await agreement.setDsr(toBN(1000000000005000000000000000));
      await agreement.setLastCheckTime(50);
      await agreement.setUnlockedDai(toBN(300000));
      await agreement.setDrawnCdp(13);
      setCurrentTime(145000);
      const result = await (agreement.updateAgreementState(false));
      
      printoutx("Borrower FRA debt", (await agreement.borrowerFraDebt.call()).toNumber(), 28);
      printout("Delta ", (await agreement.delta.call()).toString(), '-28149566989732627130306574993');
      printoutx("Dai lender assets", (await agreement.assets(LENDER)).dai.toString(), 13);

      print_results(result);
      //assert.equal(result.logs.length, 2);
      assert.equal(result.logs[2].event, 'AgreementUpdated');
      assert.equal(result.logs[2].args._injectionAmount, 0);
      printout("Delta ", result.logs[2].args._delta.toString(), '-28149566989732627130306574993');
      printoutx("Drawn Dai: " , result.logs[2].args._drawnDai.toNumber(), 13);
      //assert.equal(result.logs[1].args._currentDsrAnnual.toString(),     1000157692432144230673074666);
      printout("Savings difference", result.logs[2].args._savingsDifference.toString(), '-41149566989732627130306574993');

 
    });

    it('should calculate correctly with valid values case 2', async () => {
      await setCurrentTime(10);
      await agreement.initAgreement(BORROWER, 2000, 1, 90000, fromPercentToRay(3),
        ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000});

      await setCurrentTime(10);
      await agreement.approveAgreement();
      await setCurrentTime(10);
      await agreement.matchAgreement({from: LENDER});
      await agreement.setDsr(toBN(1000000000005000000000000000));
      await agreement.setLastCheckTime(50);
      await agreement.setUnlockedDai(toBN(1));

      await setCurrentTime(100000);
      const result = await agreement.updateAgreementState(false);

      assert.equal((await agreement.borrowerFraDebt.call()).toNumber(), 0);
      printout("Delta diff", (await agreement.delta.call()).toString(), '-94582021860958401326299');
      assert.equal((await agreement.assets(LENDER)).dai.toString(), 0);

      print_results(result);
      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'AgreementUpdated');
      assert.equal(result.logs[0].args._injectionAmount, 0);
      printout("Delta diff", result.logs[0].args._delta.toString(), '-94582021860958401326299');
      assert.equal(result.logs[0].args._drawnDai.toNumber(), 0);
      // vr todo assert.equal(result.logs[0].args._currentDsrAnnual.toString(), 1000157692432144230673074666);
      printout("Savings diff", result.logs[0].args._savingsDifference.toString(),  '-94582021860958401326299');
    });

    it('should calculate correctly with valid values case 3', async () => {
      await setCurrentTime(10);
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000, fromPercentToRay(3),
        ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000});

      await setCurrentTime(10);
      await agreement.approveAgreement();
      await setCurrentTime(10);
      await agreement.matchAgreement({from: LENDER});
      await agreement.setDsr(toBN(1000000070000000000000000000)); // dsr is high, 909%
      await agreement.setLastCheckTime(50);
      await agreement.setUnlockedDai(toBN(300000));
      await agreement.setInjectionWad(7666); // overinjection. The interest over the period 

      await setCurrentTime(100000);
      printoutx("FraDebt before ", (await agreement.borrowerFraDebt.call()).toNumber(), 0);
      const result = await debug(agreement.updateAgreementState(false));

      printoutx("FraDebt after ", (await agreement.borrowerFraDebt.call()).toNumber(), 0);
      printout("delta  ", (await agreement.delta.call()).toString(), '576441163269106903756478638');
      printout("injected tot", (await agreement.injectedTotal()).toString(), 7666);
      
      print_results(result);
      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'AgreementUpdated');
      printoutx("inj amount: ", result.logs[0].args._injectionAmount.toNumber(), 7666);
      printout("Delta ", result.logs[0].args._delta.toString(), '576441163269106903756478638');
      //assert.equal(result.logs[0].args._currentDsrAnnual.toString(), 9093136723312484727540999310);
      printout("SavingsDifference ", result.logs[0].args._savingsDifference.toString(),'7666576441163269106903756478638');
    });

    it('should calculate correctly with valid values case 4', async () => {
      await setCurrentTime(10);
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000, fromPercentToRay(3),
        ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000});

      await setCurrentTime(10);
      await agreement.approveAgreement();
      await setCurrentTime(10);
      await agreement.matchAgreement({from: LENDER});
      await agreement.setDsr(toBN(1000000099000000000000000000)); // 2260% APR
      await agreement.setLastCheckTime(50);
      await agreement.setUnlockedDai(toBN(300000));
      await agreement.setInjectionWad(155);

      await setCurrentTime(500000);
      const result = await (agreement.updateAgreementState(false));

      assert.equal((await agreement.borrowerFraDebt.call()).toNumber(), 0);
      printout("Delta: ", (await agreement.delta.call()).toString(), '102874871661599566448101809453013');
      assert.equal((await agreement.injectedTotal()).toString(), '155');

      print_results(result);
      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'AgreementUpdated');
      assert.equal(result.logs[0].args._injectionAmount, 155);
      printout("Delta logs", result.logs[0].args._delta.toString(), '102874871661599566448101809453013');
      //assert.equal(result.logs[0].args._currentDsrAnnual.toString(), 22693166534788171667215645984);
      printout("Savings difference: ", result.logs[0].args._savingsDifference.toString(),
        '103029871661599566448101809453013');
    });

    it('should calculate correctly with valid values case 5', async () => {
      await setCurrentTime(10);
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000, fromPercentToRay(3),
        ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000});

      await setCurrentTime(10);
      await agreement.approveAgreement();
      await setCurrentTime(10);
      await agreement.matchAgreement({from: LENDER});
      await agreement.setDsr(toBN(1000000000000000000000400000));
      await agreement.setLastCheckTime(50);
      await agreement.setUnlockedDai(toBN(300000));
      await agreement.setDelta(toBN(87166159956644810180));
      await agreement.setDrawnCdp(130);

      await setCurrentTime(500000);
      const result = await agreement.updateAgreementState(false);

      printoutx("FraDebt: ", (await agreement.borrowerFraDebt.call()).toNumber(), 12);
      printout("Delta: ", (await agreement.delta.call()).toString(), '-12679794433381785248834652054');
      assert.equal((await agreement.assets(LENDER)).dai.toString(), 130);

      print_results(result);
      //assert.equal(result.logs.length, 2);
      printoutx("Log events: ", result.logs[2].event, 'AgreementUpdated');
      assert.equal(result.logs[2].args._injectionAmount, 0);
      printout("Delta ", result.logs[2].args._delta.toString(), '-12679794433381785248834652054');
      printout("Savings difference: ", result.logs[2].args._savingsDifference.toString(),'-142679794520547945205479452054');
    });

    it('should calculate correctly during last update', async () => {
      await setCurrentTime(10);
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000, fromPercentToRay(3),
        ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000});

      await setCurrentTime(10);
      await agreement.approveAgreement();
      await setCurrentTime(10);
      await agreement.matchAgreement({from: LENDER});
      await setCurrentTime(10);
      await agreement.setDsr(toBN(1000000000005000000000000000));
      await agreement.setLastCheckTime(50);
      await agreement.setDrawnCdp(13);

      await setCurrentTime(145000);
      const result = await agreement.updateAgreementState(true);

      assert.equal((await agreement.borrowerFraDebt.call()).toNumber(), 12);
      printout("Delta: ", (await agreement.delta.call()).toString(), '-12538565342506706703293407977');
      assert.equal((await agreement.assets(LENDER)).dai.toString(), 13);

      print_results(result);
      //assert.equal(result.logs.length, 4);
      assert.equal(result.logs[2].event, 'AgreementUpdated');
      assert.equal(result.logs[2].args._injectionAmount, 0);
      printout("Delta compare: ", result.logs[2].args._delta.toString(), '-12538565342506706703293407977');
      printoutx("drawn Dai", result.logs[2].args._drawnDai.toNumber(), 13);
      //assert.equal(result.logs[0].args._currentDsrAnnual.toString(), 1000157692432144230673074666);
      printout("Savings Diff compare: ", result.logs[2].args._savingsDifference.toString(), '-25538565342506706703293407977');
    });

    it('should calculate correctly 2 updates one after the other with different time periods', async () => {
      await setCurrentTime(10);
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000, fromPercentToRay(3),
        ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000});

      await setCurrentTime(10);
      await agreement.approveAgreement();
      await setCurrentTime(10);
      await agreement.matchAgreement({from: LENDER});
      await agreement.setDsr(toBN(1000000012857214317438491659)); // 
      await agreement.setLastCheckTime(50);
      await agreement.setUnlockedDai(toBN(300000));
      await agreement.setInjectionWad(1003);

      await setCurrentTime(100000);
      let result = await (agreement.updateAgreementState(false));

      printoutx("FRA debt: ", (await agreement.borrowerFraDebt.call()).toNumber(), 0);
      printout("Delta1: ", (await agreement.delta.call()).toString(), '6663576441163269106903756478638');
      printoutx((await agreement.injectedTotal()).toString(), 1003);

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'AgreementUpdated');
      printoutx(result.logs[0].args._injectionAmount, 1003);
      //assert.equal(result.logs[0].args._delta, 6663576441163269106903756478638);
      printout("savingsDifference ", result.logs[0].args._savingsDifference.toString(),
        '7666576441163269106903756478638');

      await agreement.setUnlockedDai(toBN(292334));
      await agreement.setInjectionWad(1503);
      await setCurrentTime(200000);
      result = await agreement.updateAgreementState(false);

      assert.equal((await agreement.borrowerFraDebt.call()).toNumber(), 0);
      printout("delta2: ", (await agreement.delta.call()).toString(), '12830988088150031595051586872473');
      printoutx("injection tot" , (await agreement.injectedTotal()).toString(), 2506);

      print_results(result);
      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'AgreementUpdated');
      printout("injection amount: ",  result.logs[0].args._injectionAmount, 1503);
      //assert.equal(result.logs[0].args._delta, 12830988088150031595051586872473);
      printout("savingsDiff2", result.logs[0].args._savingsDifference.toString(), '7670411646986762488147830393835');
    });

    it('should calculate correctly 2 updates one after the other with different time periods and different dsr', async () => {
      await setCurrentTime(10);
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000, fromPercentToRay(3),
        ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000});

      await setCurrentTime(10);
      await agreement.approveAgreement();
      await setCurrentTime(10);
      await agreement.matchAgreement({from: LENDER});
      await agreement.setDsr(toBN(1000000070000000000000000000));
      await agreement.setLastCheckTime(50);
      await agreement.setUnlockedDai(toBN(300000));
      await agreement.setInjectionWad(7666);

      await setCurrentTime(100000);
      let result = await agreement.updateAgreementState(false);

      //assert.equal((await agreement.borrowerFraDebt.call()).toNumber(), 0);
      //assert.equal((await agreement.delta.call()).toString(), '576441163269106903756478638');
      printoutx("FraDebt: ", (await agreement.borrowerFraDebt.call()).toNumber(), "0")
      printout("deltas: ", (await agreement.delta.call()).toString(), '576441163269106903756478638');
      printoutx("inj total: ", ((await agreement.injectedTotal()).toString(), 7666));

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'AgreementUpdated');
      assert.equal(result.logs[0].args._injectionAmount, 7666);
      printout("Delta: ", result.logs[0].args._delta, 576441163269106903756478638);
      printout("Savings diff", result.logs[0].args._savingsDifference.toString(),
        '7666576441163269106903756478638');

      await agreement.setDsr(toBN(1000000000000000000500000000));
      await agreement.setUnlockedDai(toBN(292334));

      await setCurrentTime(400000);
      result = await agreement.updateAgreementState(false);
               
      printoutx("FraDebt: ", (await agreement.borrowerFraDebt.call()).toNumber(), 85);
      printout((await agreement.delta.call()).toString(), '-85039997192895276657887356978');

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'AgreementUpdated');
      assert.equal(result.logs[0].args._injectionAmount, 0);
      printout("Delta: ",result.logs[0].args._delta, -85039997192895276657887356978);
      printout("savdiff: ",result.logs[0].args._savingsDifference.toString(),
        '-85616438356164383561643835616');
    });

    it('should calculate correctly 2 updates one after the other with different time periods and different dsr case 2', async () => {
      await setCurrentTime(10);
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000, fromPercentToRay(3),
        ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000});

      await setCurrentTime(10);
      await agreement.approveAgreement();
      await setCurrentTime(10);
      await agreement.matchAgreement({from: LENDER});
      await agreement.setDsr(toBN(1000000000005000000000000000));
      await agreement.setLastCheckTime(50);
      await agreement.setUnlockedDai(toBN(300000));

      await setCurrentTime(100000);
      let result = await agreement.updateAgreementState(false);

      assert.equal((await agreement.borrowerFraDebt.call()).toNumber(), 28);
      printout("delta: ", (await agreement.delta.call()).toString(), '-28374606558287520397889908041');

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'AgreementUpdated');
      assert.equal(result.logs[0].args._injectionAmount, 0);
      printout("Delta: ", result.logs[0].args._delta, -28374606558287520397889908041);
      printout("savdiff: ", result.logs[0].args._savingsDifference.toString(),
        '-28374606558287520397889908041');

      await agreement.setDsr(toBN(1000000000400000000000000000));

      await setCurrentTime(400000);
      result = await agreement.updateAgreementState(false);

      printoutx("FRA debt: ",  (await agreement.borrowerFraDebt.call()).toNumber(), 77);
      printout("delta: ", (await agreement.delta.call()).toString(), '-77763027964743687276815144913');

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'AgreementUpdated');
      assert.equal(result.logs[0].args._injectionAmount, 0);
      printout("delta ", result.logs[0].args._delta, -77763027964743687276815144913);
      printout("savdiff ", result.logs[0].args._savingsDifference.toString(),
        '-49388421406456166878925236872');
    });

    it('should inject a valid value if delta > 0', async () => {
      await setCurrentTime(10);
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000, fromPercentToRay(3),
        ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000});

      await setCurrentTime(10);
      await agreement.approveAgreement();
      await setCurrentTime(10);
      await agreement.matchAgreement({from: LENDER});
      await agreement.setDsr(toBN(1000000097000000000000000000));
      await agreement.setLastCheckTime(50);
      await agreement.setUnlockedDai(toBN(300000));
      await agreement.setInjectionWad(19278);

      await setCurrentTime(100000);
      const result = await agreement.updateAgreementState(false);

      printoutx("FRA debt",(await agreement.borrowerFraDebt.call()).toNumber(), 0);
      printout("delta ", (await agreement.delta.call()).toString(), '851428396335582781259763913');


      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'AgreementUpdated');
      assert.equal(result.logs[0].args._injectionAmount, 19278);
      printout("delta ",result.logs[0].args._delta, 851428396335582781259763913);
      printout("savdiff ",result.logs[0].args._savingsDifference.toString(),
        '19278851428396335582781259763913');
    });

    it('should inject a valid value if delta < 0, borrower debt > 0 and dsr rises to be more than interestRate', async () => {
      await setCurrentTime(10);
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000, fromPercentToRay(3),
        ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000});

      await setCurrentTime(10);
      await agreement.approveAgreement();
      await setCurrentTime(10);
      await agreement.matchAgreement({from: LENDER});
      await agreement.setDsr(toBN(1000000097000000000000000000));
      await agreement.setLastCheckTime(50);
      await agreement.setUnlockedDai(toBN(300000));
      await agreement.setDelta(toBN(-28374606558287520397889908041));

      await setCurrentTime(100000);
      assert.equal((await agreement.borrowerFraDebt.call()).toNumber(), 28);
      agreement.setDrawnCdp(28);
      agreement.setInjectionWad(19250);

      const result = await agreement.updateAgreementState(false);
      print_results(result);
      printoutx("fra debt: ",(await agreement.borrowerFraDebt.call()).toNumber(), 0);
      printout("delta ",(await agreement.delta.call()).toString(), '476821838048059781259763913');

      printoutx(result.logs.length, 1);
      assert.equal(result.logs[1].event, 'AgreementUpdated');
      assert.equal(result.logs[1].args._injectionAmount, 19250);
      printout("delta ",result.logs[1].args._delta, 476821838048059781259763913);
      printout("savdif ",result.logs[1].args._savingsDifference.toString(),
        '19278851428396335582781259763913');
    });
  });

  describe('_refund()', async () => {
    beforeEach('init config', async () => {
      configContract = await Config.new();
      await configContract
      .setGeneral(1440, 60, 2, 100, toBN(100).times(toBN(10).pow(toBN(18))), 86400, 31536000, 10);

      await agreement.setCRBuffer(100);
    });

    it('should be possible to refund if agreement is not liquidated', async () => {
      await setCurrentTime(10);
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000,
        fromPercentToRay(3), ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000});
      await setCurrentTime(10);
      await agreement.approveAgreement();
      await setCurrentTime(10);
      await agreement.matchAgreement({from: LENDER});
      await agreement.setUnlockedDai(300000);

      await setCurrentTime(100000);
      await agreement.refund();

      assert.equal((await agreement.assets(LENDER)).dai.toString(), 300000);
    });
  });

  describe('statuses manipulations internal functions', async () => {
    beforeEach('init config', async () => {
      configContract = await Config.new();
      await configContract
      .setGeneral(1440, 60, 2, 100, toBN(100).times(toBN(10).pow(toBN(18))), 86400, 31536000, 10);

      await agreement.setCRBuffer(100);

      await setCurrentTime(10);
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000,
        fromPercentToRay(3), ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000});
    });

    it('should be possible to _nextStatus()', async () => {
      assert.equal((await agreement.status()).toString(), 1);

      await agreement.nextStatus();

      assert.equal((await agreement.status()).toString(), 2);
    });

    it('should be possible to _switchStatus()', async () => {
      assert.equal((await agreement.status()).toString(), 1);

      await setCurrentTime(150);
      await agreement.switchStatus(3);

      assert.equal((await agreement.status()).toString(), 3);
      assert.equal((await agreement.statusSnapshots(3)).toString(), 150);
    });

    it('should be possible to _switchStatusClosedWithType()', async () => {
      assert.equal((await agreement.status()).toString(), 1);

      await agreement.switchStatusClosedWithType(3);

      assert.equal((await agreement.status()).toString(), 4);
      assert.equal((await agreement.closedType()).toString(), 3);
    });

    it('should be possible to _doStatusSnapshot()', async () => {
      assert.equal((await agreement.status()).toString(), 1);

      await setCurrentTime(250);
      await agreement.doStatusSnapshot();

      assert.equal((await agreement.statusSnapshots(1)).toString(), 250);
    });
  });

  describe('lockAdditionalCollateral()', async () => {
    beforeEach('init config', async () => {
      configContract = await Config.new();
      await configContract
      .setGeneral(1440, 60, 2, 100, toBN(100).times(toBN(10).pow(toBN(18))), 86400, 31536000, 10);

      await agreement.setCRBuffer(100);

      await setCurrentTime(10);
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000,
        fromPercentToRay(3), ETH_A_SYM, true, configContract.address, {from: OWNER, value: 2000});
    });

    it('should be possible to lockAdditionalCollateral in ETH if status is active by borrower', async () => {
      await setCurrentTime(10);
      await agreement.approveAgreement();
      await setCurrentTime(10);
      await agreement.matchAgreement({from: LENDER});

      const result = await agreement.lockAdditionalCollateral(100, {from: BORROWER, value: 100});

      assert.equal((await agreement.collateralAmount()).toString(), 2100);

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'AdditionalCollateralLocked');
      assert.equal(result.logs[0].args._amount, 100);
    });

    it('should be possible to lockAdditionalCollateral in ETH if status is before active by borrower', async () => {
      await setCurrentTime(10);
      await agreement.approveAgreement();

      const result = await agreement.lockAdditionalCollateral(100, {from: BORROWER, value: 100});

      assert.equal((await agreement.collateralAmount()).toString(), 2100);

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'AdditionalCollateralLocked');
      assert.equal(result.logs[0].args._amount, 100);
    });

    it('should not be possible to lockAdditionalCollateral in ETH if status is closed by borrower', async () => {
      await setCurrentTime(10);
      await agreement.approveAgreement();
      await setCurrentTime(10);
      await agreement.matchAgreement({from: LENDER});
      await agreement.blockAgreement();

      await assertReverts(agreement.lockAdditionalCollateral(100, {from: BORROWER, value: 100}));

      assert.equal((await agreement.collateralAmount()).toString(), 2000);
    });

    it('should not be possible to lockAdditionalCollateral in ETH if status is active by borrower with different messge value', async () => {
      await setCurrentTime(10);
      await agreement.approveAgreement();
      await setCurrentTime(10);
      await agreement.matchAgreement({from: LENDER});

      await assertReverts(agreement.lockAdditionalCollateral(100, {from: BORROWER, value: 90}));

      assert.equal((await agreement.collateralAmount()).toString(), 2000);
    });

    it('should not be possible to lockAdditionalCollateral in ETH if status is active by borrower with different messge value case 2', async () => {
      await setCurrentTime(10);
      await agreement.approveAgreement();
      await setCurrentTime(10);
      await agreement.matchAgreement({from: LENDER});

      await assertReverts(agreement.lockAdditionalCollateral(100, {from: BORROWER, value: 110}));

      assert.equal((await agreement.collateralAmount()).toString(), 2000);
    });

    it('should not be possible to lockAdditionalCollateral in ETH if status is active by not borrower', async () => {
      await setCurrentTime(10);
      await agreement.approveAgreement();
      await setCurrentTime(10);
      await agreement.matchAgreement({from: LENDER});

      await assertReverts(agreement.lockAdditionalCollateral(100, {from: LENDER, value: 100}));

      assert.equal((await agreement.collateralAmount()).toString(), 2000);
    });
  });

  describe('withdrawDai(), withdrawCollateral(), withdrawRemainingEth()', async () => {
    beforeEach('init config', async () => {
      configContract = await Config.new();
      await configContract
      .setGeneral(1440, 60, 2, 100, toBN(100).times(toBN(10).pow(toBN(18))), 86400, 31536000, 10);

      await agreement.setCRBuffer(100);
    });

    it('should be possible to withdrawDai with sufficient asset', async () => {
      await setCurrentTime(10);
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000,
        fromPercentToRay(3), ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000});
      await setCurrentTime(10);
      await agreement.approveAgreement();
      await setCurrentTime(10);
      await agreement.matchAgreement({from: LENDER});
      await agreement.setUnlockedDai(300000);

      await setCurrentTime(100000);
      await agreement.refund();

      assert.equal((await agreement.assets(LENDER)).dai.toString(), 300000);

      await agreement.withdrawDai(1000, {from: LENDER});

      assert.equal((await agreement.assets(LENDER)).dai.toString(), 299000);
    });

    it('should not be possible to withdrawDai with insufficient asset', async () => {
      await setCurrentTime(10);
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000,
        fromPercentToRay(3), ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000});
      await setCurrentTime(10);
      await agreement.approveAgreement();
      await setCurrentTime(10);
      await agreement.matchAgreement({from: LENDER});
      await agreement.setUnlockedDai(300000);

      await setCurrentTime(100000);
      await agreement.refund();

      assert.equal((await agreement.assets(LENDER)).dai.toString(), 300000);
      assert.equal((await agreement.assets(BORROWER)).dai.toString(), 0);

      await assertReverts(agreement.withdrawDai(1000, {from: BORROWER}));

      assert.equal((await agreement.assets(LENDER)).dai.toString(), 300000);
      assert.equal((await agreement.assets(BORROWER)).dai.toString(), 0);
    });

    it('should be possible to withdrawCollateral with sufficient asset', async () => {
      await setCurrentTime(10);
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000,
        fromPercentToRay(3), ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000});
      await setCurrentTime(10);
      await agreement.approveAgreement();
      await agreement.cancelAgreement({from: BORROWER});

      assert.equal((await agreement.assets(BORROWER)).collateral.toString(), 2000);

      await agreement.withdrawCollateral(1500, {from: BORROWER});

      assert.equal((await agreement.assets(BORROWER)).collateral.toString(), 500);
    });

    it('should be possible to withdrawCollateral with insufficient asset', async () => {
      await setCurrentTime(10);
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000,
        fromPercentToRay(3), ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000});
      await setCurrentTime(10);
      await agreement.approveAgreement();
      await agreement.cancelAgreement({from: BORROWER});

      assert.equal((await agreement.assets(BORROWER)).collateral.toString(), 2000);

      await assertReverts(agreement.withdrawCollateral(2100, {from: BORROWER}));

      assert.equal((await agreement.assets(BORROWER)).collateral.toString(), 2000);
    });

    it('should not be possible to withdrawCollateral with insufficient asset', async () => {
      await setCurrentTime(10);
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000,
        fromPercentToRay(3), ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000});
      await setCurrentTime(10);
      await agreement.approveAgreement();
      await agreement.cancelAgreement({from: BORROWER});

      assert.equal((await agreement.assets(BORROWER)).collateral.toString(), 2000);

      await assertReverts(agreement.withdrawCollateral(2100, {from: BORROWER}));

      assert.equal((await agreement.assets(BORROWER)).collateral.toString(), 2000);
    });

    it('should be possible to withdrawRemainingEth when closed', async () => {
      await setCurrentTime(10);
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000,
        fromPercentToRay(3), ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000});
      await setCurrentTime(10);
      await agreement.approveAgreement();
      await setCurrentTime(10);
      await agreement.matchAgreement({from: LENDER});
      await agreement.send(5000025);
      await agreement.blockAgreement();

      assert.equal((await web3.eth.getBalance(SOMEBODY)).toString(), 100000000000000000000);

      await agreement.withdrawRemainingEth(SOMEBODY);

      assert.equal((await web3.eth.getBalance(SOMEBODY)).toString(), 100000000000005000025);
    });

    it('should not be possible to withdrawRemainingEth when not closed', async () => {
      await setCurrentTime(10);
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000,
        fromPercentToRay(3), ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000});
      await setCurrentTime(10);
      await agreement.approveAgreement();
      await setCurrentTime(10);
      await agreement.matchAgreement({from: LENDER});
      await agreement.send(5000025);

      assert.equal((await web3.eth.getBalance(SOMEBODY)).toString(), 100000000000000000000);

      await assertReverts(agreement.withdrawRemainingEth(SOMEBODY));

      assert.equal((await web3.eth.getBalance(SOMEBODY)).toString(), 100000000000000000000);
    });

    it('should not be possible to withdrawRemainingEth when closed from not an owner', async () => {
      await setCurrentTime(10);
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000,
        fromPercentToRay(3), ETH_A_SYM, true, configContract.address, {from: OWNER, value: 2000});
      await setCurrentTime(10);
      await agreement.approveAgreement();
      await setCurrentTime(10);
      await agreement.matchAgreement({from: LENDER});
      await agreement.send(5000025);
      await agreement.blockAgreement();

      assert.equal((await web3.eth.getBalance(SOMEBODY)).toString(), 100000000000000000000);

      await assertReverts(agreement.withdrawRemainingEth(SOMEBODY, {from: NOBODY}));

      assert.equal((await web3.eth.getBalance(SOMEBODY)).toString(), 100000000000000000000);
    });
  });

  describe('status checkers', async () => {
    beforeEach('init config', async () => {
      configContract = await Config.new();
      await configContract
      .setGeneral(1440, 60, 2, 100, toBN(100).times(toBN(10).pow(toBN(18))), 86400, 31536000, 10);

      await agreement.setCRBuffer(100);
    });

    it('isStatus should retrurn a correct status case 1', async () => {
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000,
        fromPercentToRay(3), ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000});

      assert.isTrue(await agreement.isStatus.call(1));
    });

    it('isStatus should retrurn a correct status case 2', async () => {
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000,
        fromPercentToRay(3), ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000});
      await agreement.approveAgreement();

      assert.isTrue(await agreement.isStatus.call(2));
    });

    it('isStatus should retrurn a correct status case 3', async () => {
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000,
        fromPercentToRay(3), ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000});
      await agreement.approveAgreement();
      await agreement.matchAgreement({from: LENDER});

      assert.isTrue(await agreement.isStatus.call(3));
    });

    it('isStatus should retrurn a correct status case 4', async () => {
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000,
        fromPercentToRay(3), ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000});
      await agreement.rejectAgreement();

      assert.isTrue(await agreement.isStatus.call(4));
    });

    it('isBeforeStatus should return a correct status case 1', async () => {
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000,
        fromPercentToRay(3), ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000});

      assert.isTrue(await agreement.isBeforeStatus.call(2));
    });

    it('isBeforeStatus should return a correct status case 2', async () => {
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000,
        fromPercentToRay(3), ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000});
      await agreement.approveAgreement();
      await agreement.matchAgreement({from: LENDER});

      assert.isTrue(await agreement.isBeforeStatus.call(4));
    });

    it('isClosedWithType should retrurn a correct status case 1', async () => {
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000,
        fromPercentToRay(3), ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000});
      await agreement.approveAgreement();
      await agreement.cancelAgreement({from: BORROWER});

      assert.isTrue(await agreement.isClosedWithType.call(3));
    });

    it('isClosedWithType should retrurn a correct status case 2', async () => {
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000,
        fromPercentToRay(3), ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000});
      await agreement.approveAgreement();
      await agreement.matchAgreement({from: LENDER});
      await agreement.blockAgreement();

      assert.isTrue(await agreement.isClosedWithType.call(2));
    });

    it('checkTimeToCancel should retrurn a correct status case 1', async () => {
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000,
        fromPercentToRay(3), ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000});

      await setCurrentTime(100000000000);
      assert.isTrue(await agreement.checkTimeToCancel.call(10, 10));
    });

    it('checkTimeToCancel should retrurn a correct status case 2', async () => {
      await agreement.initAgreement(BORROWER, 2000, 300000, 90000,
        fromPercentToRay(3), ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000});
      await agreement.approveAgreement();

      await setCurrentTime(100000000000);
      assert.isTrue(await agreement.checkTimeToCancel.call(1, 1));
    });
  });

  describe('push and pop assets', async () => {
    beforeEach('init config', async () => {
      configContract = await Config.new();
      await configContract
      .setGeneral(1440, 60, 2, 100, toBN(100).times(toBN(10).pow(toBN(18))), 86400, 31536000, 10);

      await agreement.setCRBuffer(100);

      await agreement.initAgreement(BORROWER, 2000, 300000, 90000,
        fromPercentToRay(3), ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000});
      await agreement.approveAgreement();
      await agreement.matchAgreement({from: LENDER});
    });

    it('should be possible to _pushCollateralAsset', async () => {
      assert.equal((await agreement.assets(BORROWER)).collateral.toString(), 0);

      const result = await agreement.pushCollateralAsset(BORROWER, 101);

      assert.equal((await agreement.assets(BORROWER)).collateral.toString(), 101);

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'AssetsCollateralPush');
      assert.equal(result.logs[0].args._holder, BORROWER);
      assert.equal(result.logs[0].args._amount, 101);
      //assert.equal(result.logs[0].args._collateralType, ETH_A_SYM);
    });

    it('should be possible to _pushDaiAsset', async () => {
      assert.equal((await agreement.assets(BORROWER)).collateral.toString(), 0);

      const result = await agreement.pushDaiAsset(BORROWER, 101);

      assert.equal((await agreement.assets(BORROWER)).dai.toString(), 101);

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'AssetsDaiPush');
      assert.equal(result.logs[0].args._holder, BORROWER);
      assert.equal(result.logs[0].args._amount, 101);
    });

    it('should be possible to _popCollateralAsset', async () => {
      assert.equal((await agreement.assets(BORROWER)).collateral.toString(), 0);

      await agreement.pushCollateralAsset(BORROWER, 101);

      assert.equal((await agreement.assets(BORROWER)).collateral.toString(), 101);

      const result = await agreement.popCollateralAsset(BORROWER, 50);

      assert.equal((await agreement.assets(BORROWER)).collateral.toString(), 51);

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'AssetsCollateralPop');
      assert.equal(result.logs[0].args._holder, BORROWER);
      assert.equal(result.logs[0].args._amount, 50);
      assert.equal(result.logs[0].args._collateralType, ETH_A_SYM);
    });

    it('should be possible to _popDaiAsset', async () => {
      assert.equal((await agreement.assets(BORROWER)).collateral.toString(), 0);

      await agreement.pushDaiAsset(BORROWER, 101);

      assert.equal((await agreement.assets(BORROWER)).dai.toString(), 101);

      const result = await agreement.popDaiAsset(BORROWER, 50);

      assert.equal((await agreement.assets(BORROWER)).dai.toString(), 51);

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'AssetsDaiPop');
      assert.equal(result.logs[0].args._holder, BORROWER);
      assert.equal(result.logs[0].args._amount, 50);
    });
  });

  describe('updateAgreement()', async () => {
    beforeEach('init config', async () => {
      configContract = await Config.new();
      await configContract
      .setGeneral(1440, 60, 2, 100, toBN(100).times(toBN(10).pow(toBN(18))), 86400, 31536000, 10);

      await agreement.setCRBuffer(100);

      await setCurrentTime(10);
      await agreement.initAgreement(BORROWER, 2000, 300000, 900000,
        fromPercentToRay(3), ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000});
      await setCurrentTime(10);
      await agreement.approveAgreement();
      await setCurrentTime(10);
      await agreement.matchAgreement({from: LENDER});
    });

    it('should be possible to updateAgreement when it is should not be closed yet', async () => {
      await agreement.setDsr(toBN(1000000000005000000000000000));
      await agreement.setLastCheckTime(50);
      await agreement.setUnlockedDai(toBN(300000));

      await setCurrentTime(145000);
      assert.isTrue(await agreement.updateAgreement.call());
      await setCurrentTime(145000);
      const result = await agreement.updateAgreement();

      assert.equal((await agreement.status()).toString(), 3);
      assert.equal((await agreement.borrowerFraDebt.call()).toNumber(), 41);

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'AgreementUpdated');
    });

    it('should be possible to updateAgreement when agreement should expire', async () => {
      await agreement.setDsr(toBN(1000000000005000000000000000));
      await agreement.setLastCheckTime(50);
      await agreement.setUnlockedDai(toBN(300000));

      await setCurrentTime(1450000);
      assert.isTrue(await agreement.updateAgreement.call());
      await setCurrentTime(1450000);
      const result = await agreement.updateAgreement();

      assert.equal((await agreement.status()).toString(), 4);
      assert.isTrue(await agreement.isClosedWithType.call(0));
      printoutx("FRA debt ", (await agreement.borrowerFraDebt.call()).toNumber(), 255);

      assert.equal(result.logs.length, 4);
      assert.equal(result.logs[1].event, 'AgreementUpdated');
    });

    it('should be possible to updateAgreement when agreement should expire', async () => {
      await agreement.setDsr(toBN(1000000000005000000000000000));
      await agreement.setLastCheckTime(50);
      await agreement.setUnlockedDai(toBN(300000));

      await setCurrentTime(245000);
      assert.isTrue(await agreement.updateAgreement.call());
      await setCurrentTime(245000);
      const result = await agreement.updateAgreement();

      assert.equal((await agreement.status()).toString(), 4);
      assert.isTrue(await agreement.isClosedWithType.call(1));
      printoutx("FRA debt mismatch : ", (await agreement.borrowerFraDebt.call()).toNumber(), 255);

      assert.equal(result.logs.length, 4);
      assert.equal(result.logs[1].event, 'AgreementUpdated');
    });

    it('should not be possible to updateAgreement when it is not active', async () => {
      await agreement.setDsr(toBN(1000000000005000000000000000));
      await agreement.setLastCheckTime(50);
      await agreement.setUnlockedDai(toBN(300000));
      await agreement.blockAgreement();

      assert.equal((await agreement.status()).toString(), 4);

      await setCurrentTime(145000);
      await assertReverts(agreement.updateAgreement());

      assert.equal((await agreement.status()).toString(), 4);
    });

    it('should be possible to updateAgreement from not a contract owner', async () => {
      await agreement.setDsr(toBN(1000000000005000000000000000));
      await agreement.setLastCheckTime(50);
      await agreement.setUnlockedDai(toBN(300000));

      await setCurrentTime(145000);
      await assertReverts(agreement.updateAgreement({from: NOBODY}));

      assert.equal((await agreement.status()).toString(), 3);
    });
  });

  describe('getters', async () => {
    beforeEach('init config', async () => {
      configContract = await Config.new();
      await configContract
      .setGeneral(1440, 60, 2, 100, toBN(100).times(toBN(10).pow(toBN(18))), 86400, 31536000, 10);

      await agreement.setCRBuffer(100);

      await setCurrentTime(10);
      await agreement.initAgreement(BORROWER, 2000, 300000, 900000,
        fromPercentToRay(3), ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000});
      await setCurrentTime(10);
      await agreement.approveAgreement();
      await setCurrentTime(10);
      await agreement.matchAgreement({from: LENDER});
    });

    it('VR getInfo should work correctly', async () => {
      const result = await agreement.getInfo();

      assert.equal(result._addr, agreement.address);
      assert.equal(result._status.toString(), 3);
      assert.equal(result._closedType, 0);
      assert.equal(result._duration, 900000);
      assert.equal(result._borrower, BORROWER);
      assert.equal(result._lender, LENDER);
      assert.equal(result._collateralType, ETH_A_SYM);
      assert.equal(result._collateralAmount, 2000);
      assert.equal(result._debtValue, 300000);
      assert.equal(result._interestRate.toString(), 1030000000000000000000000000);
      assert.equal(result._isRisky, false);
    });

    it('getAssets should work correctly', async () => {
      await agreement.setDsr(toBN(1000000000005000000000000000));
      await agreement.setLastCheckTime(50);
      await agreement.setUnlockedDai(toBN(300000));
      await agreement.setDrawnCdp(13);

      await setCurrentTime(145000);
      await agreement.updateAgreementState(false);

      const result = await agreement.getAssets(LENDER);

      assert.equal(result[0], 0);
      assert.equal(result[1], 13);
    });
  });

  describe('risky functionality', async () => {
    beforeEach('init config', async () => {
      configContract = await Config.new();
      await configContract
      .setGeneral(1440, 60, 2, 100, toBN(100).times(toBN(10).pow(toBN(18))), 86400, 31536000, 10);

      await agreement.setCRBuffer(100);

      await setCurrentTime(10);
      await agreement.initAgreement(BORROWER, 2000, 300000, 900000,
        fromPercentToRay(3), ETH_A_SYM,  true, configContract.address, {from: OWNER, value: 2000});
      await setCurrentTime(10);
      await agreement.approveAgreement();
      await setCurrentTime(10);
      await agreement.matchAgreement({from: LENDER});
    });

    it('should set isRisky to true if contract is risky', async () => {
      await agreement.setCRBuffer(1);
      const result = await agreement.monitorRisky();

      assert.equal(await agreement.isRisky(), true);

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'RiskyToggled');
      assert.equal(result.logs[0].args._isRisky, true);
    });

    it('should set isRisky to false if contract is not risky', async () => {
      await agreement.setCRBuffer(1);
      await agreement.monitorRisky();

      await agreement.setCRBuffer(100);
      const result = await agreement.monitorRisky();

      assert.equal(await agreement.isRisky(), false);

      assert.equal(result.logs.length, 1);
      assert.equal(result.logs[0].event, 'RiskyToggled');
      assert.equal(result.logs[0].args._isRisky, false);
    });
  });
});
