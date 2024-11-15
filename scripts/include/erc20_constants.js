// Auxiliary BN stuff
const BN = web3.utils.BN;
const TEN = new BN(10);

// Name of the token: Sigma Token
const NAME = "Sigma Token";

// Symbol of the token: SIG
const SYMBOL = "SIG";

// Decimals of the token: 18
const DECIMALS = 18;

// Decimals multiplier (DM): 10^18
const DM = TEN.pow(new BN(DECIMALS));

// Total supply of the token: initially 10,000,000
const TOTAL_SUPPLY = new BN(10_000_000).mul(DM); // 10 million * 10^18

// export all the constants
module.exports = {
	NAME,
	SYMBOL,
	DECIMALS,
	DM,
	TOTAL_SUPPLY,
};
