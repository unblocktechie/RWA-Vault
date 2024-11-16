/**
 * default Hardhat configuration which uses account mnemonic to derive accounts
 * script expects following environment variables to be set:
 *   - P_KEY1 – mainnet private key, should start with 0x
 *     or
 *   - MNEMONIC1 – mainnet mnemonic, 12 words
 *
 *   - P_KEY5003 – mantle sepolia private key, should start with 0x
 *     or
 *   - MNEMONIC5003 – mantle sepolia mnemonic, 12 words
 *
 *   - P_KEY59141 – linea sepolia private key, should start with 0x
 *     or
 *   - MNEMONIC59141 – linea sepolia mnemonic, 12 words
 *
 *   - P_KEY1301 – unichain sepolia private key, should start with 0x
 *     or
 *   - MNEMONIC1301 – unichain sepolia mnemonic, 12 words
 *
 *   - P_KEY48899 – zircuit testnet private key, should start with 0x
 *     or
 *   - MNEMONIC48899 – zircuit testnet mnemonic, 12 words
 * 
 * 	 - P_KEY2810 – morph testnet private key, should start with 0x
 *     or
 *   - MNEMONIC48899 – morph testnet mnemonic, 12 words
 *
 *   - ALCHEMY_KEY – Alchemy API key
 *     or
 *   - INFURA_KEY – Infura API key (Project ID)
 *
 *   - ETHERSCAN_KEY – Etherscan API key
 *
 *   - MANTLESCAN_KEY – Mantlescan API key
 *
 *   - LINEASCAN_KEY – LineaScan API key
 *
 *   - UNISCAN_KEY – UniScan API key
 * 
 * 	 - ZIRCUITSCAN_KEY – ZircuitScan API key	
 */

// Loads env variables from .env file
require('dotenv').config()

// Enable Truffle 5 plugin for tests
// https://hardhat.org/guides/truffle-testing.html
require("@nomiclabs/hardhat-truffle5");

// enable Solidity-coverage
// https://hardhat.org/plugins/solidity-coverage.html
require("solidity-coverage");

// enable hardhat-gas-reporter
// https://hardhat.org/plugins/hardhat-gas-reporter.html
// require("hardhat-gas-reporter");

// compile Solidity sources directly from NPM dependencies
// https://github.com/ItsNickBarry/hardhat-dependency-compiler
require("hardhat-dependency-compiler");

// copy compiled Solidity bytecode directly from the NPM dependencies.
// https://github.com/vgorin/hardhat-dependency-injector
require("hardhat-dependency-injector");

// adds a mechanism to deploy contracts to any network,
// keeping track of them and replicating the same environment for testing
// https://www.npmjs.com/package/hardhat-deploy
require("hardhat-deploy");

// verify environment setup, display warning if required, replace missing values with fakes
const FAKE_MNEMONIC = "test test test test test test test test test test test junk";
if(!process.env.MNEMONIC1 && !process.env.P_KEY1) {
	console.warn("neither MNEMONIC1 nor P_KEY1 is not set. Mainnet deployments won't be available");
	process.env.MNEMONIC1 = FAKE_MNEMONIC;
}
else if(process.env.P_KEY1 && !process.env.P_KEY1.startsWith("0x")) {
	console.warn("P_KEY1 doesn't start with 0x. Appended 0x");
	process.env.P_KEY1 = "0x" + process.env.P_KEY1;
}
if(!process.env.MNEMONIC5003 && !process.env.P_KEY5003) {
	console.warn("neither MNEMONIC5003 nor P_KEY5003 is not set. Mantle testnet deployments won't be available");
	process.env.MNEMONIC3 = FAKE_MNEMONIC;
}
else if(process.env.P_KEY5003 && !process.env.P_KEY5003.startsWith("0x")) {
	console.warn("P_KEY59141 doesn't start with 0x. Appended 0x");
	process.env.P_KEY5003 = "0x" + process.env.P_KEY5003;
}
if(!process.env.MNEMONIC59141 && !process.env.P_KEY59141) {
	console.warn("neither MNEMONIC59141 nor P_KEY59141 is not set. Linea sepolia deployments won't be available");
	process.env.MNEMONIC59141 = FAKE_MNEMONIC;
}
else if(process.env.P_KEY59141 && !process.env.P_KEY59141.startsWith("0x")) {
	console.warn("P_KEY59141 doesn't start with 0x. Appended 0x");
	process.env.P_KEY59141 = "0x" + process.env.P_KEY59141;
}
if(!process.env.MNEMONIC1301 && !process.env.P_KEY1301) {
	console.warn("neither MNEMONIC1301 nor P_KEY1301 is not set. Unichain sepolia deployments won't be available");
	process.env.MNEMONIC1301 = FAKE_MNEMONIC;
}
else if(process.env.P_KEY1301 && !process.env.P_KEY1301.startsWith("0x")) {
	console.warn("P_KEY1301 doesn't start with 0x. Appended 0x");
	process.env.P_KEY1301 = "0x" + process.env.P_KEY1301;
}
if(!process.env.MNEMONIC48899 && !process.env.P_KEY48899) {
	console.warn("neither MNEMONIC48899 nor P_KEY48899 is not set. Zircuit testnet deployments won't be available");
	process.env.MNEMONIC48899 = FAKE_MNEMONIC;
}
else if(process.env.P_KEY48899 && !process.env.P_KEY48899.startsWith("0x")) {
	console.warn("P_KEY48899 doesn't start with 0x. Appended 0x");
	process.env.P_KEY48899 = "0x" + process.env.P_KEY48899;
}
if(!process.env.MNEMONIC2810 && !process.env.P_KEY2810) {
	console.warn("neither MNEMONIC2810 nor P_KEY2810 is not set. Morph testnet deployments won't be available");
	process.env.MNEMONIC2810 = FAKE_MNEMONIC;
}
else if(process.env.P_KEY2810 && !process.env.P_KEY2810.startsWith("0x")) {
	console.warn("P_KEY2810 doesn't start with 0x. Appended 0x");
	process.env.P_KEY2810 = "0x" + process.env.P_KEY2810;
}
if(!process.env.INFURA_KEY && !process.env.ALCHEMY_KEY) {
	console.warn("neither INFURA_KEY nor ALCHEMY_KEY is not set. Deployments may not be available");
	process.env.INFURA_KEY = "";
	process.env.ALCHEMY_KEY = "";
}
if(!process.env.ETHERSCAN_KEY) {
	console.warn("ETHERSCAN_KEY is not set. Deployed smart contract code verification won't be available");
	process.env.ETHERSCAN_KEY = "";
}
if(!process.env.MANTLESCAN_KEY) {
	console.warn("MANTLESCAN_KEY is not set. Deployed smart contract code verification won't be available on mantlescan");
	process.env.MANTLESCAN_KEY = "";
}
if(!process.env.LINEASCAN_KEY) {
	console.warn("LINEASCAN_KEY is not set. Deployed smart contract code verification won't be available on LineaScan");
	process.env.LINEASCAN_KEY = "";
}
if(!process.env.UNISCAN_KEY) {
	console.warn("UNISCAN_KEY is not set. Deployed smart contract code verification won't be available on UniScan");
	process.env.LINEASCAN_KEY = "";
}
if(!process.env.ZIRCUITSCAN_KEY) {
	console.warn("ZIRCUITSCAN_KEY is not set. Deployed smart contract code verification won't be available on ZircuitScan");
	process.env.ZIRCUITSCAN_KEY = "";
}
if(!process.env.MORPHSCAN_KEY) {
	console.warn("MORPHSCAN_KEY is not set. Deployed smart contract code verification won't be available on MorphScan");
	process.env.MORPHSCAN_KEY = "";
}

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
	defaultNetwork: "hardhat",
	networks: {
		// https://hardhat.org/hardhat-network/
		hardhat: {
			// set networkId to 0xeeeb04de as for all local networks
			chainId: 0xeeeb04de,
			// set the gas price to one for convenient tx costs calculations in tests
			// gasPrice: 1,
			// London hard fork fix: impossible to set gas price lower than baseFeePerGas (875,000,000)
			initialBaseFeePerGas: 0,
			accounts: {
				count: 35,
			},
/*
			forking: {
				url: "https://mainnet.infura.io/v3/" + process.env.INFURA_KEY, // create a key: https://infura.io/
				enabled: !!(process.env.HARDHAT_FORK),
			},
*/
		},
		// https://etherscan.io/
		mainnet: {
			url: get_endpoint_url("mainnet"),
			accounts: get_accounts(process.env.P_KEY1, process.env.MNEMONIC1),
		},
		// https://sepolia.mantlescan.xyz/
		mantle: {
			url: get_endpoint_url("mantle"),
			accounts: get_accounts(process.env.P_KEY5003, process.env.MNEMONIC5003),
		},
		// https://sepolia.lineascan.build/
		linea: {
			url: get_endpoint_url("linea"),
			accounts: get_accounts(process.env.P_KEY59141, process.env.MNEMONIC59141),
		},
		// https://sepolia.uniscan.xyz/
		unichain: {
			url: get_endpoint_url("unichain"),
			accounts: get_accounts(process.env.P_KEY1301, process.env.MNEMONIC1301),
		},
		// https://explorer.testnet.zircuit.com
		zircuit: {
			url: get_endpoint_url("zircuit"),
			accounts: get_accounts(process.env.P_KEY48899, process.env.MNEMONIC48899),
		},
		// https://explorer-holesky.morphl2.io/
		morph: {
			url: get_endpoint_url("morph"),
			accounts: get_accounts(process.env.P_KEY2810, process.env.MNEMONIC2810),
		},
	},

	// Configure Solidity compiler
	solidity: {
		// https://hardhat.org/guides/compile-contracts.html
		compilers: [
			{ // project main compiler version
				version: "0.8.9",
				settings: {
					optimizer: {
						enabled: true,
						runs: 200
					}
				}
			},
		]
	},

	// Set default mocha options here, use special reporters etc.
	mocha: {
		// timeout: 100000,

		// disable mocha timeouts:
		// https://mochajs.org/api/mocha#enableTimeouts
		enableTimeouts: false,
		// https://github.com/mochajs/mocha/issues/3813
		timeout: false,
	},

	// hardhat-gas-reporter will be disabled by default, use REPORT_GAS environment variable to enable it
	// https://hardhat.org/plugins/hardhat-gas-reporter.html
	gasReporter: {
		enabled: !!(process.env.REPORT_GAS)
	},

	// compile Solidity sources directly from NPM dependencies
	// https://github.com/ItsNickBarry/hardhat-dependency-compiler
	dependencyCompiler: {
		paths: [
			// ERC1967 is used to deploy upgradeable contracts
			"@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol",
		],
	},

	// copy compiled Solidity bytecode directly from NPM dependencies
	// https://github.com/vgorin/hardhat-dependency-injector
	dependencyInjector: {
		paths: [
			// OwnableToAccessControlAdapter is deployed to facade OZ Ownable contract
			"@lazy-sol/access-control/artifacts/contracts/OwnableToAccessControlAdapter.sol",
		],
	},
}

/**
 * Determines a JSON-RPC endpoint to use to connect to the node
 * based on the requested network name and environment variables set
 *
 * Tries to use custom RPC URL first (MAINNET_RPC_URL/ROPSTEN_RPC_URL/RINKEBY_RPC_URL/KOVAN_RPC_URL)
 * Tries to use alchemy RPC URL next (if ALCHEMY_KEY is set)
 * Fallbacks to infura RPC URL
 *
 * @param network_name one of mainnet/ropsten/rinkeby/kovan
 * @return JSON-RPC endpoint URL
 */
function get_endpoint_url(network_name) {
	// try custom RPC endpoint first (private node, quicknode, etc.)
	// create a quicknode key: https://www.quicknode.com/
	if(process.env.MAINNET_RPC_URL && network_name === "mainnet") {
		return process.env.MAINNET_RPC_URL;
	}
	if(process.env.MANTLE_RPC_URL && network_name === "mantle") {
		return process.env.MANTLE_RPC_URL;
	}
	if(process.env.LINEA_RPC_URL && network_name === "linea") {
		return process.env.LINEA_RPC_URL;
	}
	if(process.env.UNICHAIN_RPC_URL && network_name === "unichain") {
		return process.env.UNICHAIN_RPC_URL;
	}
	if(process.env.ZIRCUIT_RPC_URL && network_name === "zircuit") {
		return process.env.ZIRCUIT_RPC_URL;
	}
	if(process.env.MORPH_RPC_URL && network_name === "morph") {
		return process.env.MORPH_RPC_URL;
	}

	// try the alchemy next
	// create a key: https://www.alchemy.com/
	if(process.env.ALCHEMY_KEY) {
		switch(network_name) {
			case "mainnet": return "https://eth-mainnet.alchemyapi.io/v2/" + process.env.ALCHEMY_KEY;
		}
	}

	// fallback to infura
	// create a key: https://infura.io/
	if(process.env.INFURA_KEY) {
		switch(network_name) {
			case "mainnet": return "https://mainnet.infura.io/v3/" + process.env.INFURA_KEY;
			case "mantle": return "https://mantle-sepolia.infura.io/v3/" + process.env.INFURA_KEY;
			case "linea": return "https://linea-sepolia.infura.io/v3/" + process.env.INFURA_KEY;
		}
	}

	// some networks don't require API key
	switch(network_name) {
		case "mantle": return "https://rpc.sepolia.mantle.xyz";
		case "linea": return "https://rpc.sepolia.linea.build";
		case "unichain": return "https://sepolia.unichain.org/";
		case "zircuit":  return "https://zircuit1-testnet.liquify.com";
		case "morph": return "https://rpc-quicknode-holesky.morphl2.io";
	}

	// fallback to default JSON_RPC_URL (if set)
	return process.env.JSON_RPC_URL || "";
}

/**
 * Depending on which of the inputs are available (private key or mnemonic),
 * constructs an account object for use in the hardhat config
 *
 * @param p_key account private key, export private key from mnemonic: https://metamask.io/
 * @param mnemonic 12 words mnemonic, create 12 words: https://metamask.io/
 * @return either [p_key] if p_key is defined, or {mnemonic} if mnemonic is defined
 */
function get_accounts(p_key, mnemonic) {
	return p_key? [p_key]: mnemonic? {mnemonic, initialIndex: 0}: undefined;
}