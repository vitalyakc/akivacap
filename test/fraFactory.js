const Agreement = artifacts.require('AgreementDeepMock');
const FraFactory = artifacts.require('FraFactory');
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

contract('FraFactory', async (accounts) => {
  const reverter = new Reverter(web3);

  let configContract;
  let agreement;
  let fraFactory;

  const BORROWER = accounts[1];
  const LENDER = accounts[2];
  const NOBODY = accounts[3];
  const ETH_A = '0x4554482d41000000000000000000000000000000000000000000000000000000';
  const ADDRESS_NULL = '0x0000000000000000000000000000000000000000';

  before('setup', async () => {
    agreement = await Agreement.new();
    configContract = await Config.new();
    fraFactory = await FraFactory.new(agreement.address, configContract.address);

    await reverter.snapshot();
  });

  afterEach('revert', reverter.revert);

  describe('setAgreementImpl()', async () => {
    it('should be possible to set agreement implementation by contract owner', async () => {
      await fraFactory.setAgreementImpl(accounts[0]);
      assert.equal(await fraFactory.agreementImpl.call(), accounts[0]);

      await fraFactory.setAgreementImpl(agreement.address);
      assert.equal(await fraFactory.agreementImpl.call(), agreement.address);
    });

    it('should not be possible to set agreement implementation by not a contract owner', async () => {
      await assertReverts(fraFactory.setAgreementImpl(accounts[0], {from: NOBODY}));
      assert(await fraFactory.agreementImpl.call(), agreement.address);
    });
  });

  describe('initAgreementETH()', async () => {
    it('should be possible to init agreement on ETH with valid values from borrower', async () => {
      await fraFactory.initAgreementETH(300000, 90000, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: 2000});

      assert.equal(await fraFactory.agreements.call(BORROWER, 0),
        await fraFactory.agreementList.call(0));
      assert.notEqual(await fraFactory.agreements.call(BORROWER, 0), ADDRESS_NULL);

      const localAgreement = await Agreement.at(await fraFactory.agreements.call(BORROWER, 0));

      assert.equal(await localAgreement.borrower.call(), BORROWER);
      assert.equal(await localAgreement.collateralAmount.call(), 2000);
    });

    it('should not be possible to init agreement on ETH with 0 transaction value from borrower', async () => {
      await assertReverts(fraFactory.initAgreementETH(300000, 90000, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: 0}));
    });
  });

  describe('approveAgreement()', async () => {
    it('should be possible to approve agreement by owner', async () => {
      await fraFactory.initAgreementETH(300000, 90000, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement = await Agreement.at(await fraFactory.agreements.call(BORROWER, 0));

      assert.equal((await localAgreement.status.call({from: NOBODY})).toNumber(), 1);

      await fraFactory.approveAgreement(localAgreement.address);

      assert.equal((await localAgreement.status.call({from: NOBODY})).toNumber(), 2);
    });

    it('should not be possible to approve agreement by owner if status is not pending', async () => {
      await fraFactory.initAgreementETH(300000, 90000, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement = await Agreement.at(await fraFactory.agreements.call(BORROWER, 0));

      assert.equal((await localAgreement.status.call({from: NOBODY})).toNumber(), 1);

      await fraFactory.approveAgreement(localAgreement.address);

      assert.equal((await localAgreement.status.call({from: NOBODY})).toNumber(), 2);

      await assertReverts(fraFactory.approveAgreement(localAgreement.address));
    });

    it('should not be possible to approve agreement by not owner', async () => {
      await fraFactory.initAgreementETH(300000, 90000, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement = await Agreement.at(await fraFactory.agreements.call(BORROWER, 0));

      assert.equal((await localAgreement.status.call({from: NOBODY})).toNumber(), 1);

      await assertReverts(fraFactory.approveAgreement(localAgreement.address, {from: NOBODY}));

      assert.equal((await localAgreement.status.call({from: NOBODY})).toNumber(), 1);
    });

    it('should not be possible to approve agreement by not owner if status is not pending', async () => {
      await fraFactory.initAgreementETH(300000, 90000, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement = await Agreement.at(await fraFactory.agreements.call(BORROWER, 0));

      assert.equal((await localAgreement.status.call({from: NOBODY})).toNumber(), 1);

      await fraFactory.approveAgreement(localAgreement.address);

      assert.equal((await localAgreement.status.call({from: NOBODY})).toNumber(), 2);

      await assertReverts(fraFactory.approveAgreement.call(localAgreement.address, {from: NOBODY}));
    });
  });
  describe('batchApproveAgreements()', async () => {
    it('should be possible to batch approve agreement by owner', async () => {
      await fraFactory.initAgreementETH(300000, 90000, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement1 = await Agreement.at(await fraFactory.agreements.call(BORROWER, 0));

      await fraFactory.initAgreementETH(300000, 90000, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement2 = await Agreement.at(await fraFactory.agreements.call(BORROWER, 1));

      await fraFactory.initAgreementETH(300000, 90000, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement3 = await Agreement.at(await fraFactory.agreements.call(BORROWER, 2));

      assert.equal((await localAgreement1.status.call({from: NOBODY})).toNumber(), 1);
      assert.equal((await localAgreement2.status.call({from: NOBODY})).toNumber(), 1);
      assert.equal((await localAgreement3.status.call({from: NOBODY})).toNumber(), 1);

      await fraFactory.batchApproveAgreements([localAgreement1.address,
        localAgreement2.address, localAgreement3.address]);

      assert.equal((await localAgreement1.status.call({from: NOBODY})).toNumber(), 2);
      assert.equal((await localAgreement2.status.call({from: NOBODY})).toNumber(), 2);
      assert.equal((await localAgreement3.status.call({from: NOBODY})).toNumber(), 2);
    });

    it('should not be possible to batch approve agreement not by owner', async () => {
      await fraFactory.initAgreementETH(300000, 90000, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement1 = await Agreement.at(await fraFactory.agreements.call(BORROWER, 0));

      await fraFactory.initAgreementETH(300000, 90000, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement2 = await Agreement.at(await fraFactory.agreements.call(BORROWER, 1));

      await fraFactory.initAgreementETH(300000, 90000, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement3 = await Agreement.at(await fraFactory.agreements.call(BORROWER, 2));

      assert.equal((await localAgreement1.status.call({from: NOBODY})).toNumber(), 1);
      assert.equal((await localAgreement2.status.call({from: NOBODY})).toNumber(), 1);
      assert.equal((await localAgreement3.status.call({from: NOBODY})).toNumber(), 1);

      await assertReverts(fraFactory.batchApproveAgreements([localAgreement1.address,
        localAgreement2.address, localAgreement3.address], {from: NOBODY}));

      assert.equal((await localAgreement1.status.call({from: NOBODY})).toNumber(), 1);
      assert.equal((await localAgreement2.status.call({from: NOBODY})).toNumber(), 1);
      assert.equal((await localAgreement3.status.call({from: NOBODY})).toNumber(), 1);
    });

    // uncomment when all done
    // it('should not be possible to batch approve agreement by owner with array lenth > 256 addresses', async () => {
    //   const addressArray = [];
    //   for (let i = 0; i < 257; i++) {
    //     await fraFactory.initAgreementETH(300000, 90000, fromPercentToRey(3),
    //       ETH_A, {from: BORROWER, value: 2000});

    //     const localAgreement = await Agreement.at(await fraFactory.agreements.call(BORROWER, i));
    //     addressArray.push(localAgreement.address);
    //   }

    //   const localAgreement = await Agreement.at(addressArray[0]);

    //   assert.equal((await localAgreement.status.call({from: NOBODY})).toNumber(), 1);

    //   await assertReverts(fraFactory.batchApproveAgreements(addressArray));

    //   assert.equal((await localAgreement.status.call({from: NOBODY})).toNumber(), 1);
    // });
  });

  describe('rejectAgreement()', async () => {
    it('should be possible to reject agreement by owner', async () => {
      await fraFactory.initAgreementETH(300000, 90000, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement = await Agreement.at(await fraFactory.agreements.call(BORROWER, 0));

      assert.equal((await localAgreement.status.call({from: NOBODY})).toNumber(), 1);

      await fraFactory.rejectAgreement(localAgreement.address);

      assert.equal((await localAgreement.status.call({from: NOBODY})).toNumber(), 12);
    });

    it('should be possible to reject approved agreement by owner', async () => {
      await fraFactory.initAgreementETH(300000, 90000, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement = await Agreement.at(await fraFactory.agreements.call(BORROWER, 0));

      assert.equal((await localAgreement.status.call({from: NOBODY})).toNumber(), 1);

      await fraFactory.approveAgreement(localAgreement.address);

      assert.equal((await localAgreement.status.call({from: NOBODY})).toNumber(), 2);

      await fraFactory.rejectAgreement(localAgreement.address);

      assert.equal((await localAgreement.status.call({from: NOBODY})).toNumber(), 12);
    });

    it('should not be possible to reject already rejected agreement by owner', async () => {
      await fraFactory.initAgreementETH(300000, 90000, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement = await Agreement.at(await fraFactory.agreements.call(BORROWER, 0));

      assert.equal((await localAgreement.status.call({from: NOBODY})).toNumber(), 1);

      await fraFactory.rejectAgreement(localAgreement.address);

      assert.equal((await localAgreement.status.call({from: NOBODY})).toNumber(), 12);

      await assertReverts(fraFactory.rejectAgreement(localAgreement.address));

      assert.equal((await localAgreement.status.call({from: NOBODY})).toNumber(), 12);
    });

    it('should not be possible to reject agreement by not owner', async () => {
      await fraFactory.initAgreementETH(300000, 90000, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement = await Agreement.at(await fraFactory.agreements.call(BORROWER, 0));

      assert.equal((await localAgreement.status.call({from: NOBODY})).toNumber(), 1);

      await assertReverts(fraFactory.rejectAgreement(localAgreement.address, {from: NOBODY}));

      assert.equal((await localAgreement.status.call({from: NOBODY})).toNumber(), 1);
    });

    it('should not be possible to reject approved agreement by not owner', async () => {
      await fraFactory.initAgreementETH(300000, 90000, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement = await Agreement.at(await fraFactory.agreements.call(BORROWER, 0));

      assert.equal((await localAgreement.status.call({from: NOBODY})).toNumber(), 1);

      await fraFactory.approveAgreement(localAgreement.address);

      assert.equal((await localAgreement.status.call({from: NOBODY})).toNumber(), 2);

      await assertReverts(fraFactory.rejectAgreement(localAgreement.address, {from: NOBODY}));

      assert.equal((await localAgreement.status.call({from: NOBODY})).toNumber(), 2);
    });
  });

  describe('batchRejectAgreements()', async () => {
    it('should be possible to batch reject agreement by owner', async () => {
      await fraFactory.initAgreementETH(300000, 90000, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement1 = await Agreement.at(await fraFactory.agreements.call(BORROWER, 0));

      await fraFactory.initAgreementETH(300000, 90000, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement2 = await Agreement.at(await fraFactory.agreements.call(BORROWER, 1));

      await fraFactory.initAgreementETH(300000, 90000, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement3 = await Agreement.at(await fraFactory.agreements.call(BORROWER, 2));

      assert.equal((await localAgreement1.status.call({from: NOBODY})).toNumber(), 1);
      assert.equal((await localAgreement2.status.call({from: NOBODY})).toNumber(), 1);
      assert.equal((await localAgreement3.status.call({from: NOBODY})).toNumber(), 1);

      await fraFactory.batchRejectAgreements([localAgreement1.address,
        localAgreement2.address, localAgreement3.address]);

      assert.equal((await localAgreement1.status.call({from: NOBODY})).toNumber(), 12);
      assert.equal((await localAgreement2.status.call({from: NOBODY})).toNumber(), 12);
      assert.equal((await localAgreement3.status.call({from: NOBODY})).toNumber(), 12);
    });

    it('should not be possible to batch reject agreement not by owner', async () => {
      await fraFactory.initAgreementETH(300000, 90000, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement1 = await Agreement.at(await fraFactory.agreements.call(BORROWER, 0));

      await fraFactory.initAgreementETH(300000, 90000, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement2 = await Agreement.at(await fraFactory.agreements.call(BORROWER, 1));

      await fraFactory.initAgreementETH(300000, 90000, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement3 = await Agreement.at(await fraFactory.agreements.call(BORROWER, 2));

      assert.equal((await localAgreement1.status.call({from: NOBODY})).toNumber(), 1);
      assert.equal((await localAgreement2.status.call({from: NOBODY})).toNumber(), 1);
      assert.equal((await localAgreement3.status.call({from: NOBODY})).toNumber(), 1);

      await assertReverts(fraFactory.batchRejectAgreements([localAgreement1.address,
        localAgreement2.address, localAgreement3.address], {from: NOBODY}));

      assert.equal((await localAgreement1.status.call({from: NOBODY})).toNumber(), 1);
      assert.equal((await localAgreement2.status.call({from: NOBODY})).toNumber(), 1);
      assert.equal((await localAgreement3.status.call({from: NOBODY})).toNumber(), 1);
    });

    // uncomment when all done
    // it('should not be possible to batch reject agreement by owner with array lenth > 256 addresses', async () => {
    //   const addressArray = [];
    //   for (let i = 0; i < 257; i++) {
    //     await fraFactory.initAgreementETH(300000, 90000, fromPercentToRey(3),
    //       ETH_A, {from: BORROWER, value: 2000});

    //     const localAgreement = await Agreement.at(await fraFactory.agreements.call(BORROWER, i));
    //     addressArray.push(localAgreement.address);
    //   }

    //   const localAgreement = await Agreement.at(addressArray[0]);

    //   assert.equal((await localAgreement.status.call({from: NOBODY})).toNumber(), 1);

    //   await assertReverts(fraFactory.batchRejectAgreements(addressArray));

    //   assert.equal((await localAgreement.status.call({from: NOBODY})).toNumber(), 1);
    // });
  });

  describe('getAgreementList()', async () => {
    it('should be possible to get agremeent list', async () => {
      await fraFactory.initAgreementETH(300000, 90000, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement1 = await fraFactory.agreements.call(BORROWER, 0);

      await fraFactory.initAgreementETH(300000, 90000, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement2 = await fraFactory.agreements.call(BORROWER, 1);

      await fraFactory.initAgreementETH(300000, 90000, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement3 = await fraFactory.agreements.call(BORROWER, 2);

      const agreementList = await fraFactory.getAgreementList.call();

      assert.equal(agreementList[0], localAgreement1);
      assert.equal(agreementList[1], localAgreement2);
      assert.equal(agreementList[2], localAgreement3);
    });
  });

  describe('autoRejectAgreements()', async () => {
    it('should be possible to auto reject agreements by owner', async () => {
      await fraFactory.initAgreementETH(300000, 90000, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement1 = await Agreement.at(await fraFactory.agreements.call(BORROWER, 0));

      await fraFactory.initAgreementETH(300000, 90000, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement2 = await Agreement.at(await fraFactory.agreements.call(BORROWER, 1));

      await fraFactory.initAgreementETH(300000, 90000, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement3 = await Agreement.at(await fraFactory.agreements.call(BORROWER, 2));

      assert.equal((await localAgreement1.status.call({from: NOBODY})).toNumber(), 1);
      assert.equal((await localAgreement2.status.call({from: NOBODY})).toNumber(), 1);
      assert.equal((await localAgreement3.status.call({from: NOBODY})).toNumber(), 1);

      await fraFactory.autoRejectAgreements();

      assert.equal((await localAgreement1.status.call({from: NOBODY})).toNumber(), 1);
      assert.equal((await localAgreement2.status.call({from: NOBODY})).toNumber(), 1);
      assert.equal((await localAgreement3.status.call({from: NOBODY})).toNumber(), 1);
    });
  });

  describe('updateAgreement()', async () => {
    it('should be possible to update active agreement by owner', async () => {
      await fraFactory.initAgreementETH(300000, 900000, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement = await Agreement.at(await fraFactory.agreements.call(BORROWER, 0));

      await fraFactory.approveAgreement(localAgreement.address);
      await localAgreement.matchAgreement({from: LENDER});
      await localAgreement.setDsr(toBN(1000000000005000000000000000));
      await localAgreement.setLastCheckTime(50);
      await localAgreement.setCurrentTime(100000);
      await localAgreement.setUnlockedDai(toBN(300000));

      await fraFactory.updateAgreement(localAgreement.address);

      assert.equal((await localAgreement.borrowerFraDebt.call()).toString(), '28');
    });

    it('should not be possible to update active agreement not by owner', async () => {
      await fraFactory.initAgreementETH(300000, 900000, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement = await Agreement.at(await fraFactory.agreements.call(BORROWER, 0));

      await fraFactory.approveAgreement(localAgreement.address);
      await localAgreement.matchAgreement({from: LENDER});
      await localAgreement.setDsr(toBN(1000000000005000000000000000));
      await localAgreement.setLastCheckTime(50);
      await localAgreement.setCurrentTime(100000);
      await localAgreement.setUnlockedDai(toBN(300000));

      await assertReverts(fraFactory.updateAgreement(localAgreement.address, {from: NOBODY}));

      assert.equal((await localAgreement.borrowerFraDebt.call()).toString(), '0');
    });
  });

  describe('updateAgreements()', async () => {
    it('should be possible to update 3 active agreements by owner', async () => {
      await fraFactory.initAgreementETH(300000, 900000, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement1 = await Agreement.at(await fraFactory.agreements.call(BORROWER, 0));

      await fraFactory.initAgreementETH(300000, 900000, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement2 = await Agreement.at(await fraFactory.agreements.call(BORROWER, 1));

      await fraFactory.initAgreementETH(300000, 900000, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement3 = await Agreement.at(await fraFactory.agreements.call(BORROWER, 2));

      await fraFactory.approveAgreement(localAgreement1.address);
      await localAgreement1.matchAgreement({from: LENDER});
      await localAgreement1.setDsr(toBN(1000000000005000000000000000));
      await localAgreement1.setLastCheckTime(50);
      await localAgreement1.setCurrentTime(100000);
      await localAgreement1.setUnlockedDai(toBN(300000));

      await fraFactory.approveAgreement(localAgreement2.address);
      await localAgreement2.matchAgreement({from: LENDER});
      await localAgreement2.setDsr(toBN(1000000000005000000000000000));
      await localAgreement2.setLastCheckTime(50);
      await localAgreement2.setCurrentTime(100000);
      await localAgreement2.setUnlockedDai(toBN(300000));

      await fraFactory.approveAgreement(localAgreement3.address);
      await localAgreement3.matchAgreement({from: LENDER});
      await localAgreement3.setDsr(toBN(1000000000005000000000000000));
      await localAgreement3.setLastCheckTime(50);
      await localAgreement3.setCurrentTime(100000);
      await localAgreement3.setUnlockedDai(toBN(300000));

      await fraFactory.updateAgreements();

      assert.equal((await localAgreement1.borrowerFraDebt.call()).toString(), '28');
      assert.equal((await localAgreement2.borrowerFraDebt.call()).toString(), '28');
      assert.equal((await localAgreement3.borrowerFraDebt.call()).toString(), '28');
    });

    it('should not be possible to update 3 active agreements not by owner', async () => {
      await fraFactory.initAgreementETH(300000, 900000, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement1 = await Agreement.at(await fraFactory.agreements.call(BORROWER, 0));

      await fraFactory.initAgreementETH(300000, 900000, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement2 = await Agreement.at(await fraFactory.agreements.call(BORROWER, 1));

      await fraFactory.initAgreementETH(300000, 900000, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement3 = await Agreement.at(await fraFactory.agreements.call(BORROWER, 2));

      await fraFactory.approveAgreement(localAgreement1.address);
      await localAgreement1.matchAgreement({from: LENDER});
      await localAgreement1.setDsr(toBN(1000000000005000000000000000));
      await localAgreement1.setLastCheckTime(50);
      await localAgreement1.setCurrentTime(100000);
      await localAgreement1.setUnlockedDai(toBN(300000));

      await fraFactory.approveAgreement(localAgreement2.address);
      await localAgreement2.matchAgreement({from: LENDER});
      await localAgreement2.setDsr(toBN(1000000000005000000000000000));
      await localAgreement2.setLastCheckTime(50);
      await localAgreement2.setCurrentTime(100000);
      await localAgreement2.setUnlockedDai(toBN(300000));

      await fraFactory.approveAgreement(localAgreement3.address);
      await localAgreement3.matchAgreement({from: LENDER});
      await localAgreement3.setDsr(toBN(1000000000005000000000000000));
      await localAgreement3.setLastCheckTime(50);
      await localAgreement3.setCurrentTime(100000);
      await localAgreement3.setUnlockedDai(toBN(300000));

      await assertReverts(fraFactory.updateAgreements({from: NOBODY}));

      assert.equal((await localAgreement1.borrowerFraDebt.call()).toString(), '0');
      assert.equal((await localAgreement2.borrowerFraDebt.call()).toString(), '0');
      assert.equal((await localAgreement3.borrowerFraDebt.call()).toString(), '0');
    });
  });

  describe('batchUpdateAgreements()', async () => {
    it('should be possible to batch update 3 active agreements by owner', async () => {
      await fraFactory.initAgreementETH(300000, 900000, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement1 = await Agreement.at(await fraFactory.agreements.call(BORROWER, 0));

      await fraFactory.initAgreementETH(300000, 900000, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement2 = await Agreement.at(await fraFactory.agreements.call(BORROWER, 1));

      await fraFactory.initAgreementETH(300000, 900000, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement3 = await Agreement.at(await fraFactory.agreements.call(BORROWER, 2));

      await fraFactory.initAgreementETH(300000, 900000, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: 2000});

      await fraFactory.approveAgreement(localAgreement1.address);
      await localAgreement1.matchAgreement({from: LENDER});
      await localAgreement1.setDsr(toBN(1000000000005000000000000000));
      await localAgreement1.setLastCheckTime(50);
      await localAgreement1.setCurrentTime(100000);
      await localAgreement1.setUnlockedDai(toBN(300000));

      await fraFactory.approveAgreement(localAgreement2.address);
      await localAgreement2.matchAgreement({from: LENDER});
      await localAgreement2.setDsr(toBN(1000000000005000000000000000));
      await localAgreement2.setLastCheckTime(50);
      await localAgreement2.setCurrentTime(100000);
      await localAgreement2.setUnlockedDai(toBN(300000));

      await fraFactory.approveAgreement(localAgreement3.address);
      await localAgreement3.matchAgreement({from: LENDER});
      await localAgreement3.setDsr(toBN(1000000000005000000000000000));
      await localAgreement3.setLastCheckTime(50);
      await localAgreement3.setCurrentTime(100000);
      await localAgreement3.setUnlockedDai(toBN(300000));

      await fraFactory.batchUpdateAgreements([localAgreement1.address,
        localAgreement2.address, localAgreement3.address]);

      assert.equal((await localAgreement1.borrowerFraDebt.call()).toString(), '28');
      assert.equal((await localAgreement2.borrowerFraDebt.call()).toString(), '28');
      assert.equal((await localAgreement3.borrowerFraDebt.call()).toString(), '28');
    });

    it('should not be possible to batch update 3 active agreements not by owner', async () => {
      await fraFactory.initAgreementETH(300000, 900000, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement1 = await Agreement.at(await fraFactory.agreements.call(BORROWER, 0));

      await fraFactory.initAgreementETH(300000, 900000, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement2 = await Agreement.at(await fraFactory.agreements.call(BORROWER, 1));

      await fraFactory.initAgreementETH(300000, 900000, fromPercentToRey(3),
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement3 = await Agreement.at(await fraFactory.agreements.call(BORROWER, 2));

      await fraFactory.approveAgreement(localAgreement1.address);
      await localAgreement1.matchAgreement({from: LENDER});
      await localAgreement1.setDsr(toBN(1000000000005000000000000000));
      await localAgreement1.setLastCheckTime(50);
      await localAgreement1.setCurrentTime(100000);
      await localAgreement1.setUnlockedDai(toBN(300000));

      await fraFactory.approveAgreement(localAgreement2.address);
      await localAgreement2.matchAgreement({from: LENDER});
      await localAgreement2.setDsr(toBN(1000000000005000000000000000));
      await localAgreement2.setLastCheckTime(50);
      await localAgreement2.setCurrentTime(100000);
      await localAgreement2.setUnlockedDai(toBN(300000));

      await fraFactory.approveAgreement(localAgreement3.address);
      await localAgreement3.matchAgreement({from: LENDER});
      await localAgreement3.setDsr(toBN(1000000000005000000000000000));
      await localAgreement3.setLastCheckTime(50);
      await localAgreement3.setCurrentTime(100000);
      await localAgreement3.setUnlockedDai(toBN(300000));

      await assertReverts(fraFactory.batchUpdateAgreements([localAgreement1.address,
        localAgreement2.address, localAgreement3.address], {from: NOBODY}));

      assert.equal((await localAgreement1.borrowerFraDebt.call()).toString(), '0');
      assert.equal((await localAgreement2.borrowerFraDebt.call()).toString(), '0');
      assert.equal((await localAgreement3.borrowerFraDebt.call()).toString(), '0');
    });

    // it('should not be possible to batch update agreement by owner with array lenth > 256 addresses', async () => {
    //   const addressArray = [];
    //   for (let i = 0; i < 257; i++) {
    //     await fraFactory.initAgreementETH(300000, 90000, fromPercentToRey(3),
    //       ETH_A, {from: BORROWER, value: 2000});

    //     const localAgreement = await Agreement.at(await fraFactory.agreements.call(BORROWER, i));
    //     addressArray.push(localAgreement.address);

    //     await localAgreement.setStatus(3);
    //   }

    //   const localAgreement = await Agreement.at(addressArray[0]);

    //   assert.equal((await localAgreement.borrowerFraDebt.call({from: NOBODY})).toNumber(), 0);

    //   await assertReverts(fraFactory.batchUpdateAgreements(addressArray));

    //   assert.equal((await localAgreement.borrowerFraDebt.call({from: NOBODY})).toNumber(), 0);
    // });
  });
});