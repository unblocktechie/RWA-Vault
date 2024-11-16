// we use hardhat deployment to work with fixtures
// see https://github.com/wighawag/hardhat-deploy#creating-fixtures
const {deployments} = require('hardhat');

/**
 * Gets ERC20 token
 *
 * @returns ERC20 instance
 */
async function get_erc20_deployment() {
	// make sure fixtures were deployed, this can be also done via --deploy-fixture test flag
	// see https://github.com/wighawag/hardhat-deploy#creating-fixtures
	await deployments.fixture();

	// get deployed contract address
	const {address} = await deployments.get("USDC");

	// connect to the contract instance and return it
	const Contract = artifacts.require("./USDC");
	return await Contract.at(address);
}

/**
 * Gets RWA Vault
 *
 * @returns RWA Vault instance
 */
async function get_rwaVault_deployment() {
	// make sure fixtures were deployed, this can be also done via --deploy-fixture test flag
	// see https://github.com/wighawag/hardhat-deploy#creating-fixtures
	await deployments.fixture();

	// get deployed contract address
	const {address} = await deployments.get("RWAVault");

	// connect to the contract instance and return it
	const Contract = artifacts.require("./RWAVault");
	return await Contract.at(address);
}

/**
 * Gets Upgradeable RWAVault
 *
 * @returns Upgradeable RWAVault instance (ERC1967 Proxy)
 */
async function get_rwaVault_upgradeable_deployment() {
	// make sure fixtures were deployed, this can be also done via --deploy-fixture test flag
	// see https://github.com/wighawag/hardhat-deploy#creating-fixtures
	await deployments.fixture();

	// get deployed contract address
	const {address} = await deployments.get("RWAVault_Proxy");

	// connect to the contract instance and return it
	const Contract = artifacts.require("./RWAVault");
	return await Contract.at(address);
}

// export public deployment API
module.exports = {
	get_erc20_deployment,
	get_rwaVault_deployment,
	get_rwaVault_upgradeable_deployment,
};
