// Both Truffle and Hardhat with Truffle make an instance of web3 available in the global scope

// BN constants, functions to work with BN
const BN = web3.utils.BN;

// deadline (unix timestamp) which is always 5 seconds in the future (overridable)
async function default_deadline(offset = 5) {
	const block = await web3.eth.getBlock("latest");
	return block.timestamp + offset;
}

// extracts gas used from truffle/web3 transaction receipt
function extract_gas(receipt) {
	return receipt.gasUsed || receipt.receipt.gasUsed;
}

// extracts gas cost used from truffle/web3 transaction receipt
async function extract_gas_cost(receipt) {
	const tx = await web3.eth.getTransaction(receipt.tx || receipt.transactionHash || receipt.receipt.transactionHash);
	const gasPrice = tx.gasPrice;
	const gasUsed = extract_gas(receipt);
	return new web3.utils.BN(gasPrice).muln(gasUsed);
}

// export public module API
module.exports = {
	default_deadline,
	extract_gas,
	extract_gas_cost,
}
