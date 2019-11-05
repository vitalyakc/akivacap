const RaySupport = artifacts.require('RaySupport');
const Reverter = require('./helpers/reverter');
const {assertReverts} = require('./helpers/assertThrows');
const BigNumber = require('bignumber.js');

contract('RaySupport', async (accounts) => {
  const reverter = new Reverter(web3);

  let raySupport;

  const toBN = (num) => {
    return new BigNumber(num);
  };

  before('setup', async () => {
    raySupport = await RaySupport.new();

    await reverter.snapshot();
  });

  afterEach('revert', reverter.revert);

  describe('toRay()', async () => {
    it('should correctly convert to ray value 5', async () => {
      assert.equal((toBN(await raySupport.toRay.call(5))).toFixed(), 5000000000000000000000000000);
    });

    it('should correctly convert to ray value 10', async () => {
      assert.equal((toBN(await raySupport.toRay.call(10))).toFixed(),
        10000000000000000000000000000);
    });

    it('should correctly convert to ray value 654', async () => {
      assert.equal((toBN(await raySupport.toRay.call(654))).toFixed(),
        654000000000000000000000000000);
    });

    it('should throw on overflow', async () => {
      await assertReverts(raySupport.toRay((toBN(2).pow(toBN(256))).minus(toBN(1))));
    });
  });

  describe('fromRay()', async () => {
    it('should correctly convert from ray value 5*10^27', async () => {
      assert.equal((toBN(await raySupport
      .fromRay.call(toBN(5000000000000000000000000000)))).toFixed(), 5);
    });

    it('should correctly convert from ray value 10*10^27', async () => {
      assert.equal((toBN(await raySupport
      .fromRay.call(toBN(10000000000000000000000000000)))).toFixed(), 10);
    });

    it('should correctly convert from ray value 654*10^27', async () => {
      assert.equal((toBN(await raySupport
      .fromRay.call(toBN(654000000000000000000000000000)))).toFixed(), 654);
    });

    it('should correctly convert from ray value 1', async () => {
      assert.equal((toBN(await raySupport
      .fromRay.call(1))).toFixed(), 0);
    });
  });

  describe('fromPercentToRay()', async () => {
    it('should correctly convert from persent 5 to ray', async () => {
      assert.equal((await raySupport
      .fromPercentToRay.call(5)).toString(), '1050000000000000000000000000');
    });

    it('should correctly convert from percent 10 to ray', async () => {
      assert.equal((await raySupport
      .fromPercentToRay.call(10)).toString(), '1100000000000000000000000000');
    });

    it('should correctly convert from percent 65 to ray', async () => {
      assert.equal((await raySupport
      .fromPercentToRay.call(65)).toString(), '1650000000000000000000000000');
    });

    it('should correctly convert from value 1 to ray', async () => {
      assert.equal((await raySupport
      .fromPercentToRay.call(1)).toString(), '1010000000000000000000000000');
    });
  });

  describe('fromRayToPercent()', async () => {
    it('should correctly convert from ray to persent 5', async () => {
      assert.equal((await raySupport
      .fromRayToPercent.call(toBN(1050000000000000000000000000))).toString(), 5);
    });

    it('should correctly convert from ray to percent 10', async () => {
      assert.equal((await raySupport
      .fromRayToPercent.call(toBN(1100000000000000000000000000))).toString(), 10);
    });

    it('should correctly convert from ray to percent 65', async () => {
      assert.equal((await raySupport
      .fromRayToPercent.call(toBN(1650000000000000000000000000))).toString(), 65);
    });

    it('should correctly convert from ray to percent 1', async () => {
      assert.equal((await raySupport
      .fromRayToPercent.call(toBN(1010000000000000000000000000))).toString(), 1);
    });
  });
});
