const Agreement = artifacts.require('AgreementMock');
const FraFactory = artifacts.require('FraFactory');
const Config = artifacts.require('Config');
const ERC20Token = artifacts.require('SimpleErc20Token');
const Reverter = require('./helpers/reverter');
const {assertReverts} = require('./helpers/assertThrows')
const BigNumber = require('bignumber.js');

contract('FraFactory', async (accounts) => {
  const reverter = new Reverter(web3);

  let configContract;
  let agreement;
  let fraFactory;

  const OWNER = accounts[0];
  const BORROWER = accounts[1];
  const LENDER = accounts[2];
  const NOBODY = accounts[3];
  const ETH_A = '0x4554482d41000000000000000000000000000000000000000000000000000000';
  const WRONG_COLLATERAL = '0x0000000000000000000000000000000000000000000000000000000000000000'
  const SOME_COLLATERAL = '0x1234500000000000000000000000000000000000000000000000000000000000'
  const ADDRESS_NULL = '0x0000000000000000000000000000000000000000';

  const toBN = (num) => {
    return new BigNumber(num);
  }

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
    })

    it('should not be possible to set agreement implementation by not a contract owner', async () => {
      await assertReverts(fraFactory.setAgreementImpl(accounts[0], {from: NOBODY}));
      assert(await fraFactory.agreementImpl.call(), agreement.address);
    })
  })

  describe('initAgreementETH()', async () => {
    it('should be possible to init agreement on ETH with valid values from borrower', async () => {
      await fraFactory.initAgreementETH(300000, 90000, 3, 
        ETH_A, {from: BORROWER, value: 2000});

      assert.equal(await fraFactory.agreements.call(BORROWER, 0), 
        await fraFactory.agreementList.call(0));
      assert.notEqual(await fraFactory.agreements.call(BORROWER, 0), ADDRESS_NULL)

      const localAgreement = await Agreement.at(await fraFactory.agreements.call(BORROWER, 0));

      assert.equal(await localAgreement.borrower.call(), BORROWER);
      assert.equal(await localAgreement.collateralAmount.call(), 2000);
    })

    it('should not be possible to init agreement on ETH with 0 transaction value from borrower', async () => {
      await assertReverts(fraFactory.initAgreementETH(300000, 90000, 3, 
        ETH_A, {from: BORROWER, value: 0}));
     })
  })

  describe('initAgreementERC20()', async () => {
    let erc20;
    beforeEach('setup test erc20 token', async () => {
      erc20 = await ERC20Token.new();
      await agreement.setErc20Token(erc20.address);
    })

    // to fix in contract
    it('should be possible to init agreement on erc20 token', async () => {
      await erc20.mint(BORROWER, 2000);
      await erc20.approve(fraFactory.address, 2000, {from: BORROWER});
      console.log(await agreement.erc20TokenContract.call(ETH_A));
      // console.log((await erc20.allowance(BORROWER, fraFactory.address)).toString());
      console.log(await fraFactory.agreementImpl.call())
      // console.log(erc20.address)
      // console.log(await agreement.erc20TokenContract.call(ETH_A));
      console.log(erc20.address);

      console.log(await fraFactory.initAgreementERC20.call(2000, 1000, 90000, 3, 
        ETH_A, {from: BORROWER}))
      // await fraFactory.initAgreementERC20(2000, 1000, 90000, 3, 
      //   ETH_A, {from: BORROWER})

      // assert.equal(await fraFactory.agreements.call(BORROWER, 0), 
      // await fraFactory.agreementList.call(0));
      // assert.notEqual(await fraFactory.agreements.call(BORROWER, 0), ADDRESS_NULL)

      // const localAgreement = await Agreement.at(await fraFactory.agreements.call(BORROWER, 0));

      // assert.equal(await localAgreement.borrower.call(), BORROWER);
      // assert.equal(await localAgreement.collateralAmount.call(), 2000);
    })

    // to do
    it('should be possible to initialize with bigger allovance', async () => {

    })

    // to do
    it('should not be possible to initialize without allovance', async () => {

    })

    // to do
    it('should not be possible to initialize with less allovance', async () => {

    })
  })

  describe('approveAgreement()', async () => {
    it('should be possible to approve agreement by owner', async () => {
      await fraFactory.initAgreementETH(300000, 90000, 3, 
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement = await Agreement.at(await fraFactory.agreements.call(BORROWER, 0));

      assert.equal((await localAgreement.status.call()).toNumber(), 0);

      await fraFactory.approveAgreement(localAgreement.address);

      assert.equal((await localAgreement.status.call()).toNumber(), 1);
    })

    it('should not be possible to approve agreement by owner if status is not pending', async () => {
      await fraFactory.initAgreementETH(300000, 90000, 3, 
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement = await Agreement.at(await fraFactory.agreements.call(BORROWER, 0));

      assert.equal((await localAgreement.status.call()).toNumber(), 0);

      await fraFactory.approveAgreement(localAgreement.address);

      assert.equal((await localAgreement.status.call()).toNumber(), 1);

      assert.isFalse(await fraFactory.approveAgreement.call(localAgreement.address));
    })

    it('should not be possible to approve agreement by not owner', async () => {
      await fraFactory.initAgreementETH(300000, 90000, 3, 
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement = await Agreement.at(await fraFactory.agreements.call(BORROWER, 0));

      assert.equal((await localAgreement.status.call()).toNumber(), 0);

      await assertReverts(fraFactory.approveAgreement(localAgreement.address, {from: NOBODY}));

      assert.equal((await localAgreement.status.call()).toNumber(), 0);

    })

    it('should not be possible to approve agreement by not owner if status is not pending', async () => {
      await fraFactory.initAgreementETH(300000, 90000, 3, 
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement = await Agreement.at(await fraFactory.agreements.call(BORROWER, 0));

      assert.equal((await localAgreement.status.call()).toNumber(), 0);

      await fraFactory.approveAgreement(localAgreement.address);

      assert.equal((await localAgreement.status.call()).toNumber(), 1);

      await assertReverts(fraFactory.approveAgreement.call(localAgreement.address, {from:NOBODY}));
    })
  })
  describe('batchApproveAgreements()', async () => {
    it('should be possible to batch approve agreement by owner', async () => {
      await fraFactory.initAgreementETH(300000, 90000, 3, 
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement1 = await Agreement.at(await fraFactory.agreements.call(BORROWER, 0));

      await fraFactory.initAgreementETH(300000, 90000, 3, 
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement2 = await Agreement.at(await fraFactory.agreements.call(BORROWER, 1));

      await fraFactory.initAgreementETH(300000, 90000, 3, 
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement3 = await Agreement.at(await fraFactory.agreements.call(BORROWER, 2));

      assert.equal((await localAgreement1.status.call()).toNumber(), 0);
      assert.equal((await localAgreement2.status.call()).toNumber(), 0);
      assert.equal((await localAgreement3.status.call()).toNumber(), 0);

      await fraFactory.batchApproveAgreements([localAgreement1.address, 
        localAgreement2.address, localAgreement3.address]);

      assert.equal((await localAgreement1.status.call()).toNumber(), 1);
      assert.equal((await localAgreement2.status.call()).toNumber(), 1);
      assert.equal((await localAgreement3.status.call()).toNumber(), 1);
    })

    it('should not be possible to batch approve agreement not by owner', async () => {
      await fraFactory.initAgreementETH(300000, 90000, 3, 
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement1 = await Agreement.at(await fraFactory.agreements.call(BORROWER, 0));

      await fraFactory.initAgreementETH(300000, 90000, 3, 
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement2 = await Agreement.at(await fraFactory.agreements.call(BORROWER, 1));

      await fraFactory.initAgreementETH(300000, 90000, 3, 
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement3 = await Agreement.at(await fraFactory.agreements.call(BORROWER, 2));

      assert.equal((await localAgreement1.status.call()).toNumber(), 0);
      assert.equal((await localAgreement2.status.call()).toNumber(), 0);
      assert.equal((await localAgreement3.status.call()).toNumber(), 0);

      await assertReverts(fraFactory.batchApproveAgreements([localAgreement1.address, 
        localAgreement2.address, localAgreement3.address], {from: NOBODY}));

      assert.equal((await localAgreement1.status.call()).toNumber(), 0);
      assert.equal((await localAgreement2.status.call()).toNumber(), 0);
      assert.equal((await localAgreement3.status.call()).toNumber(), 0);
    })

    it('should not be possible to batch approve agreement by owner with array lenth > 256 addresses', async () => {
      let addressArray = [];
      for(let i = 0; i < 257; i++) {
        await fraFactory.initAgreementETH(300000, 90000, 3, 
          ETH_A, {from: BORROWER, value: 2000});

        const localAgreement = await Agreement.at(await fraFactory.agreements.call(BORROWER, i));
        addressArray.push(localAgreement.address);
      }

      const localAgreement = await Agreement.at(addressArray[0]);

      assert.equal((await localAgreement.status.call()).toNumber(), 0);

      await assertReverts(fraFactory.batchApproveAgreements(addressArray));

      assert.equal((await localAgreement.status.call()).toNumber(), 0);
    })
  })

  describe('rejectAgreement()', async() => {
    it('should be possible to reject agreement by owner', async () => {
      await fraFactory.initAgreementETH(300000, 90000, 3, 
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement = await Agreement.at(await fraFactory.agreements.call(BORROWER, 0));

      assert.equal((await localAgreement.status.call()).toNumber(), 0);

      await fraFactory.rejectAgreement(localAgreement.address);

      assert.equal((await localAgreement.status.call()).toNumber(), 12);
    })

    it('should be possible to reject approved agreement by owner', async () => {
      await fraFactory.initAgreementETH(300000, 90000, 3, 
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement = await Agreement.at(await fraFactory.agreements.call(BORROWER, 0));

      assert.equal((await localAgreement.status.call()).toNumber(), 0);

      await fraFactory.approveAgreement(localAgreement.address);

      assert.equal((await localAgreement.status.call()).toNumber(), 1);

      await fraFactory.rejectAgreement(localAgreement.address);

      assert.equal((await localAgreement.status.call()).toNumber(), 12);
    })

    it('should not be possible to reject already rejected agreement by owner', async () => {
      await fraFactory.initAgreementETH(300000, 90000, 3, 
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement = await Agreement.at(await fraFactory.agreements.call(BORROWER, 0));

      assert.equal((await localAgreement.status.call()).toNumber(), 0);

      await fraFactory.rejectAgreement(localAgreement.address);

      assert.equal((await localAgreement.status.call()).toNumber(), 12);

      await assertReverts(fraFactory.rejectAgreement(localAgreement.address));

      assert.equal((await localAgreement.status.call()).toNumber(), 12);
    })

    it('should not be possible to reject agreement by not owner', async () => {
      await fraFactory.initAgreementETH(300000, 90000, 3, 
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement = await Agreement.at(await fraFactory.agreements.call(BORROWER, 0));

      assert.equal((await localAgreement.status.call()).toNumber(), 0);

      await assertReverts(fraFactory.rejectAgreement(localAgreement.address, {from: NOBODY}));

      assert.equal((await localAgreement.status.call()).toNumber(), 0);
    })

    it('should not be possible to reject approved agreement by not owner', async () => {
      await fraFactory.initAgreementETH(300000, 90000, 3, 
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement = await Agreement.at(await fraFactory.agreements.call(BORROWER, 0));

      assert.equal((await localAgreement.status.call()).toNumber(), 0);

      await fraFactory.approveAgreement(localAgreement.address);

      assert.equal((await localAgreement.status.call()).toNumber(), 1);

      await assertReverts(fraFactory.rejectAgreement(localAgreement.address, {from: NOBODY}));

      assert.equal((await localAgreement.status.call()).toNumber(), 1);
    })
  })
  describe('batchRejectAgreements()', async () => {
    it('should be possible to batch reject agreement by owner', async () => {
      await fraFactory.initAgreementETH(300000, 90000, 3, 
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement1 = await Agreement.at(await fraFactory.agreements.call(BORROWER, 0));

      await fraFactory.initAgreementETH(300000, 90000, 3, 
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement2 = await Agreement.at(await fraFactory.agreements.call(BORROWER, 1));

      await fraFactory.initAgreementETH(300000, 90000, 3, 
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement3 = await Agreement.at(await fraFactory.agreements.call(BORROWER, 2));

      assert.equal((await localAgreement1.status.call()).toNumber(), 0);
      assert.equal((await localAgreement2.status.call()).toNumber(), 0);
      assert.equal((await localAgreement3.status.call()).toNumber(), 0);

      await fraFactory.batchRejectAgreements([localAgreement1.address, 
        localAgreement2.address, localAgreement3.address]);

      assert.equal((await localAgreement1.status.call()).toNumber(), 12);
      assert.equal((await localAgreement2.status.call()).toNumber(), 12);
      assert.equal((await localAgreement3.status.call()).toNumber(), 12);
    })

    it('should not be possible to batch reject agreement not by owner', async () => {
      await fraFactory.initAgreementETH(300000, 90000, 3, 
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement1 = await Agreement.at(await fraFactory.agreements.call(BORROWER, 0));

      await fraFactory.initAgreementETH(300000, 90000, 3, 
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement2 = await Agreement.at(await fraFactory.agreements.call(BORROWER, 1));

      await fraFactory.initAgreementETH(300000, 90000, 3, 
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement3 = await Agreement.at(await fraFactory.agreements.call(BORROWER, 2));

      assert.equal((await localAgreement1.status.call()).toNumber(), 0);
      assert.equal((await localAgreement2.status.call()).toNumber(), 0);
      assert.equal((await localAgreement3.status.call()).toNumber(), 0);

      await assertReverts(fraFactory.batchRejectAgreements([localAgreement1.address, 
        localAgreement2.address, localAgreement3.address], {from: NOBODY}));

      assert.equal((await localAgreement1.status.call()).toNumber(), 0);
      assert.equal((await localAgreement2.status.call()).toNumber(), 0);
      assert.equal((await localAgreement3.status.call()).toNumber(), 0);
    })

    it('should not be possible to batch reject agreement by owner with array lenth > 256 addresses', async () => {
      let addressArray = [];
      for(let i = 0; i < 257; i++) {
        await fraFactory.initAgreementETH(300000, 90000, 3, 
          ETH_A, {from: BORROWER, value: 2000});

        const localAgreement = await Agreement.at(await fraFactory.agreements.call(BORROWER, i));
        addressArray.push(localAgreement.address);
      }

      const localAgreement = await Agreement.at(addressArray[0]);

      assert.equal((await localAgreement.status.call()).toNumber(), 0);

      await assertReverts(fraFactory.batchRejectAgreements(addressArray));

      assert.equal((await localAgreement.status.call()).toNumber(), 0);
    })
  })

  describe('getAgreementList()', async () => {
    it('should be possible to get agremeent list', async () => {
      await fraFactory.initAgreementETH(300000, 90000, 3, 
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement1 = await fraFactory.agreements.call(BORROWER, 0);

      await fraFactory.initAgreementETH(300000, 90000, 3, 
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement2 = await fraFactory.agreements.call(BORROWER, 1);

      await fraFactory.initAgreementETH(300000, 90000, 3, 
        ETH_A, {from: BORROWER, value: 2000});

      const localAgreement3 = await fraFactory.agreements.call(BORROWER, 2);

      const agreementList = await fraFactory.getAgreementList.call();

      assert.equal(agreementList[0], localAgreement1);
      assert.equal(agreementList[1], localAgreement2);
      assert.equal(agreementList[2], localAgreement3);
    })
  })
});
