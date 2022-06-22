require("@nomiclabs/hardhat-waffle");

require("dotenv").config();

// require("@nomiclabs/hardhat-etherscan");
// require("hardhat-gas-reporter");
// require("solidity-coverage");


//Taken from https://rpc.info/
const DEFAULT_INFURA_KEY = '9aa3d95b3bc440fa88ea12eaa4456161'

const INFURA_KEY_ROPSTEN =
	process.env.INFURA_KEY_ROPSTEN ||
	DEFAULT_INFURA_KEY;

const INFURA_KEY_RINKEBY =
	process.env.INFURA_KEY_RINKEBY ||
	DEFAULT_INFURA_KEY;

const MNEMONIC =
	process.env.MNEMONIC ||
	'test test test test test test test test test test test junk'

const ACCOUNTS = {
	mnemonic: MNEMONIC,
	initialIndex: 0,
	count: 10,
	path: `m/44'/60'/0'/0`
}

module.exports = {
	defaultNetwork: "local",
	solidity: {
		compilers: [
			{
				version: '0.8.7',
				settings: {
					optimizer: {
						enabled: true,
						runs: 1,
					},
				},
			},
		],
	},
	networks: {
		hardhat: {
			blockGasLimit: 10000000,
			gas: 10000000,
			initialBaseFeePerGas: 0,
			accounts: ACCOUNTS
		},
		localhost: {
			url: 'http://127.0.0.1:8545',
			blockGasLimit: 10000000,
			gas: 10000000,
			network_id: '*', // eslint-disable-line camelcase
			accounts: ACCOUNTS
		},
		local: {
			url: 'http://127.0.0.1:8545',
			blockGasLimit: 10000000,
			gas: 10000000,
			network_id: '*', // eslint-disable-line camelcase
			accounts: ACCOUNTS
		},
		ropsten: {
			url: `https://ropsten.infura.io/v3/${INFURA_KEY_ROPSTEN}`,
			network_id: '*',
			accounts: ACCOUNTS
		},
		rinkeby: {
			url: `https://rinkeby.infura.io/v3/${INFURA_KEY_RINKEBY}`,
			network_id: '*',
			accounts: ACCOUNTS
		},
		harmony: {
			url: `https://api.s0.b.hmny.io`,
			accounts: ACCOUNTS
		},
		devnet: {
			url: `https://api.s0.ps.hmny.io/`,
			accounts: ACCOUNTS
		}

	},
};
