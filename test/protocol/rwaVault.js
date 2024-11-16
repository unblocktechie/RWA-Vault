// RWA Vault: Unit Tests

// Zeppelin test helpers
const {
	BN,
	constants,
	expectEvent,
	expectRevert,
} = require("@openzeppelin/test-helpers");

const {
	assert,
	expect,
} = require("chai");

const {
	ZERO_ADDRESS,
	ZERO_BYTES32,
	MAX_UINT256,
} = constants;

// deployment routines in use
const {
	NAME,
	SYMBOL,
	DECIMALS,
	S0,
} = require("../erc20/include/deployment_routines");

// BN constants and utilities
const {random_bn255} = require("../../scripts/include/bn_utils");

// deployment fixture routines in use
const {
	get_rwaVault_deployment,
	get_rwaVault_upgradeable_deployment
} = require("../include/deployment_fixture_routines");

// run Unit tests
contract("RWAVault: Unit tests", function(accounts) {
	// extract accounts to be used:
	// A0 – special default zero account accounts[0] used by Truffle, reserved
	// a0 – deployment account having all the permissions, reserved
	// H0 – initial token holder account
	// a1, a2,... – working accounts to perform tests on
	const [A0, a0, H0, a1, a2] = accounts;
	const DEFAULT_ADMIN_ROLE = "0x0000000000000000000000000000000000000000000000000000000000000000";

	// define test suite: it will be reused to test several contracts
	function test_suite(contract_name, deployment_fn) {
		describe(`${contract_name}: ACL`, function() {
			// deploy contracts
			let rwa, rwaImpl;
			beforeEach(async function() {
				// a0 and H0 are ignored when using a fixture
				rwa = await deployment_fn.call(this, a0, H0);
				rwaImpl = await get_rwaVault_deployment.call(this, a0, H0);
			});

			const by = a1;
			const from = H0;
			const to = a2;

			describe("when operator has DEFAULT_ADMIN_ROLE", function() {
				beforeEach(async function() {
					await rwa.grantRole(DEFAULT_ADMIN_ROLE, by, {from: a0});
				});
				it("can pause contract", async function() {
					await rwa.pause({from: by});
					expect(await rwa.paused()).to.be.equals(true);
				});
				it("can unpause contract", async function() {
					await rwa.pause({from: by});
					await rwa.unpause({from: by});
					expect(await rwa.paused()).to.be.equals(false);
				});
				it("can transfer admin role", async function() {
					await rwa.transferAdmin(to, {from: by});
					expect(await rwa.hasRole(DEFAULT_ADMIN_ROLE, to)).to.be.equals(true);
					expect(await rwa.hasRole(DEFAULT_ADMIN_ROLE, by)).to.be.equals(false);
				});
			});
			describe("when operator does not have DEFAULT_ADMIN_ROLE", function() {
				beforeEach(async function() {
					await rwa.revokeRole(DEFAULT_ADMIN_ROLE, by, {from: a0});
				});
				it("can't pause contract", async function() {
					await expectRevert.unspecified(rwa.pause({from: by}));
				});
				it("can't unpause contract", async function() {
					await rwa.pause({from: a0});
					await expectRevert.unspecified(rwa.unpause({from: by}));
				});
				it("can't transfer admin role", async function() {
					await expectRevert.unspecified(rwa.transferAdmin(to, {from: by}));
				});
			});
			// describe("create pool", function() {
			// 	beforeEach(async function() {
			// 		await pdn.createPool("pool", "pm", "hash", 0, 10, 20, 30, {from: a0});
			// 	});
			// 	it("fails if pool id already exists", async function() {
			// 		await expectRevert.unspecified(pdn.createPool("pool", "pm", "hash", 0, 10, 20, 30, {from: a0}));
			// 	});
			// 	it("succeed otherwise", async function() {
			// 		await pdn.createPool("pool1", "pm", "hash", 0, 10, 20, 30, {from: a0});
			// 	});
			// 	it("emit pool added event", async function() {
			// 		expectEvent(await pdn.createPool("pool1", "pm", "hash", 0, 10, 20, 30, {from: a0}), 'PoolAdded', {
			// 			_poolId: "0xd2dd734abc5b00cd944e9263bc784f05764df8a693313e71125ba239d5d3103c", // keccak_256(pool1)
			// 			_poolManagerId: "pm",
			// 			_metaHash: "hash",
			// 			_ratings: BN(0),
			// 			_inceptionTime: BN(10),
			// 			_expiryTime: BN(20),
			// 			_poolSize: BN(30)
			// 		});
			// 	});
			// });
		});
	}

	// run the suite
	test_suite("RWA_Vault", get_rwaVault_upgradeable_deployment);
});
