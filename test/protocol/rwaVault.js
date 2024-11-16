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
	get_erc20_deployment,
	get_rwaVault_deployment,
	get_rwaVault_upgradeable_deployment,
	get_rwaLeverage_deployment,
	get_rwaLeverage_upgradeable_deployment
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
			let rwa, rwaImpl, usdc, leverage;
			beforeEach(async function() {
				// a0 and H0 are ignored when using a fixture
				rwa = await deployment_fn.call(this, a0, H0);
				rwaImpl = await get_rwaVault_deployment.call(this, a0, H0);
				leverage = await get_rwaLeverage_upgradeable_deployment.call(this, a0, H0);
				usdc = await get_erc20_deployment.call(this, a0, H0);
				await rwa.activatePool({from:a0});
				await leverage.updatePoolStatus(1, {from:a0});
				await rwa.addGrantManager(leverage.address, {from:a0});
			});

			const by = a1;
			const from = H0;
			const to = a2;

			describe("Lend USDC to RWA vault", function() {
				beforeEach(async function() {
					await usdc.transfer(by, 1000, {from: a0});
					await usdc.approve(rwa.address, 1000, {from:by});
				});
				it("allows to lend usdc amount which is less than max deposit limit", async function() {
					await rwa.deposit(500, by, {from: by});
					expect(await rwa.balanceOf(by)).to.be.bignumber.equals(BN(500));
					expect(await usdc.balanceOf(by)).to.be.bignumber.equals(BN(500));
				});
			});
			describe("Withdraw USDC from RWA vault", function() {
				beforeEach(async function() {
					await usdc.transfer(by, 1000, {from: a0});
					await usdc.approve(rwa.address, 1000, {from:by});
					await rwa.deposit(1000, by, {from: by});
				});
				it("allows to withdraw usdc amount which is less than available pool reserve", async function() {
					await rwa.withdraw(100, by, by, {from: by});
					expect(await rwa.balanceOf(by)).to.be.bignumber.equals(BN(900));
					expect(await usdc.balanceOf(by)).to.be.bignumber.equals(BN(100));
				});
			});
			describe("Vault share price gets increased", function() {
				beforeEach(async function() {
					await usdc.transfer(by, 1000, {from: a0});
					await usdc.approve(rwa.address, 1000, {from:by});
					await rwa.deposit(1000, by, {from: by});
				});
				it("lender earn yield when underlying RWAs gain value over time", async function() {
					await rwa.updateAssetUnderManagement(500, {from: a0});
					expect(await rwa.convertToAssets(1000)).to.be.bignumber.equals(BN(1499));
				});
			});
			describe("Vault share price gets decreased", function() {
				beforeEach(async function() {
					await usdc.transfer(by, 1000, {from: a0});
					await usdc.approve(rwa.address, 1000, {from:by});
					await rwa.deposit(1000, by, {from: by});
				});
				it("lender loose capital when underlying RWAs loose value over time", async function() {
					await rwa.addGrantManager(a0, {from:a0});
					await rwa.grant(a0, 100, {from:a0});
					expect(await rwa.convertToAssets(1000)).to.be.bignumber.equals(BN(900));
				});
			});
			describe("Borrow", function() {
				beforeEach(async function() {
					await usdc.transfer(by, 1000, {from: a0});
					await usdc.approve(rwa.address, 1000, {from:by});
					await rwa.deposit(1000, by, {from: by});
					await rwa.approve(leverage.address, 1000, {from: by});
					await leverage.stake(500, 2592000, {from: by});
					await leverage.stake(500, 2592000, {from: by});
					await usdc.transfer(rwa.address, 1000, {from: a0});
				});
				it("lender can borrow from protocol by leveraging locked value", async function() {
					await leverage.borrow(1100, 2592000, {from: by});
					expect(await usdc.balanceOf(by)).to.be.bignumber.equals(BN(1100));
					const leverageInfo = await leverage.leverages(by);
					expect(leverageInfo.totalStaked).to.be.bignumber.equals(BN(1000));
					expect(leverageInfo.totalBorrowed).to.be.bignumber.equals(BN(1100));
					expect(leverageInfo.borrowAPY).to.be.bignumber.equals(BN(1200));
				});
			});
			describe("Pay", function() {
				beforeEach(async function() {
					await usdc.transfer(by, 1000, {from: a0});
					await usdc.approve(rwa.address, 1000, {from:by});
					await rwa.deposit(500, by, {from: by});
					await rwa.approve(leverage.address, 100, {from: by});
					await leverage.stake(100, 2592000, {from: by});
					await usdc.transfer(rwa.address, 1000, {from: a0});
					await leverage.borrow(100, 2592000, {from: by});
				});
				it("lender can pay from protocol by leveraging locked value", async function() {
					await usdc.approve(leverage.address, 100, {from:by});
					await leverage.pay({from:by});
					expect(await usdc.balanceOf(by)).to.be.bignumber.equals(BN(500));
					expect(await usdc.balanceOf(rwa.address)).to.be.bignumber.equals(BN(1125));
					const leverageInfo = await leverage.leverages(by);
					expect(leverageInfo.totalStaked).to.be.bignumber.equals(BN(100));
					expect(leverageInfo.totalBorrowed).to.be.bignumber.equals(BN(0));
					expect(leverageInfo.borrowAPY).to.be.bignumber.equals(BN(0));
					expect(leverageInfo.borrowTime).to.be.bignumber.equals(BN(0));
					expect(leverageInfo.paymentDue).to.be.bignumber.equals(BN(0));
				});
			});
			describe("Liquidate", function() {
				beforeEach(async function() {
					await usdc.transfer(by, 1000, {from: a0});
					await usdc.approve(rwa.address, 1000, {from:by});
					await rwa.deposit(500, by, {from: by});
					await rwa.approve(leverage.address, 100, {from: by});
					await leverage.stake(100, 2592000, {from: by});
					await usdc.transfer(rwa.address, 1000, {from: a0});
					await leverage.borrow(100, 2592000, {from: by});
				});
				it("liquidity manager can liquidate loan in case of due amount exceeds collateral value", async function() {
					await leverage.liquidate([{borrower: by, totalStaked: 0, totalBorrowed: 0, borrowAPY: 0, borrowTime:0, paymentDue:0}],{from:a0});
					const leverageInfo = await leverage.leverages(by);
					expect(leverageInfo.totalStaked).to.be.bignumber.equals(BN(0));
					expect(leverageInfo.totalBorrowed).to.be.bignumber.equals(BN(0));
					expect(leverageInfo.borrowAPY).to.be.bignumber.equals(BN(0));
					expect(leverageInfo.borrowTime).to.be.bignumber.equals(BN(0));
					expect(leverageInfo.paymentDue).to.be.bignumber.equals(BN(0));
				});
			});
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
		});
	}

	// run the suite
	test_suite("RWA_Vault", get_rwaVault_upgradeable_deployment);
});
