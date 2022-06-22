async function main() {
  // We get the contract to deploy
	let networkName = hre.network.name
  const GuessVerifier = await ethers.getContractFactory("GuessVerifier");
  const InitVerifier = await ethers.getContractFactory("InitVerifier");
	const ZKHangmanFactory = await ethers.getContractFactory("zkHangmanFactory")
	const ZKHangman = await ethers.getContractFactory("zkHangman")

	const guessVerifier = await GuessVerifier.deploy()
	await guessVerifier.deployed()
  console.log("Guess Verifier deployed to:", guessVerifier.address);

	const initVerifier = await InitVerifier.deploy()
	await guessVerifier.deployed()
  console.log("Init Verifier deployed to:", initVerifier.address);

	const zkHangmanFactory = await ZKHangmanFactory.deploy()
	await zkHangmanFactory.deployed()
  console.log("ZK Hangman Factory deployed to:", zkHangmanFactory.address);

	switch (networkName) {
		case 'mainnet':
			networkName = 'main'
			break;
		case 'testnet':
			networkName = 'test'
			break;
		case 'devnet':
			networkName = 'dev'
			break;
		case 'localhost':
			networkName = 'local'
			break;
		case 'hardhat':
			networkName = 'local'
			break;
		default:
			break;
	}
	console.log()
	console.log(`const ${networkName}ZkHangmanFactory = "${zkHangmanFactory.address}"`)
	console.log(`const ${networkName}InitVerifier = "${initVerifier.address}"`)
	console.log(`const ${networkName}GuessVerifier = "${guessVerifier.address}"`)

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
