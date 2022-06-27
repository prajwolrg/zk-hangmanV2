# zk-hangmanV2
Circuits and contracts for zk-hangmanV2.

An implementation of a frontend can be found here: <https://github.com/prajwolrg/zk-hangmanV2-frontend>

## Overview
This is the implementation of the classic Hangman game with the use of smart contracts and 
zero knowledge proofs. It improves upon the work [here](https://github.com/russel-ra/zk-hangman).

## Table of Contents

- [zk-hangmanV2](#zk-hangmanv2)
	- [Overview](#overview)
	- [Table of Contents](#table-of-contents)
	- [Project Structure](#project-structure)
		- [circuits](#circuits)
		- [contracts](#contracts)
		- [scripts](#scripts)
	- [Zero Knowledge Structure](#zero-knowledge-structure)
	- [Run Locally](#run-locally)
		- [Clone the Repository](#clone-the-repository)
		- [Install dependencies](#install-dependencies)
		- [Run circuits](#run-circuits)
		- [Run contracts](#run-contracts)

## Project Structure

The project has three main folders:

- circuits
- contracts
- scripts

### circuits
The [circuits folder](/circuits/) contains all the circuits used in zkHangmanV2.

### contracts
The [contracts folder](/contracts/) contains all the smart contracts used in zkGames. InitVerifier and GuessVerifier contracts are auto-generated.

### scripts
The [scripts folder](/scripts/) contains the scripts for easy compilation of circuits and deployment of contracts.

## Zero Knowledge Structure

The following graphic shows the structure of the most important zero knowledge elements of the zkHangmanV2 project. `public` folder is created on compile.
```text
├── circuits
│   ├── circomlib
│   │   ├── comparators.circom
│   │   ├── mimcsponge.circom
│   ├── guess
│   │   ├── guess.circom
│   ├── init
│   │   ├── init.circom
├── contracts
│   ├── contracts
│   │   ├── GuessVerifier.sol
│   │   ├── InitVerifier.sol
│   │   ├── zkHangman.sol
│   │   ├── zkHangmanFactory.sol
├── public
│   ├── guess_0001.zkey
│   ├── guess_verification_key.json
│   ├── guess.wasm
│   ├── init_0001.zkey
│   ├── init_verification_key.json
│   ├── init.wasm
```
## Run Locally

### Clone the Repository

```bash
git clone https://github.com/prajwolrg/zk-hangmanV2
```
### Install dependencies

```bash
yarn
```

### Run circuits

To run cicuits, we'll utilize te script the `scripts` folder:

```bash
source .scripts/compile_circuits.sh
```

### Run contracts
//TODO: Automate this with script
Update the solidity version and the contract name.
InitVerifier: contract Verifier -> contract InitVerifier
GuessVerifier: contract Verifier -> contract GuessVerifier
Also bump the solidity versions on both contracts to ^0.8.0

Before deploying the contracts, create a `.env` file and add to it:
```bash
MNEMONIC=<YOUR_MNEMONIC>
```

Now deploy to the appropriate network
```bash
npx hardhat run --network devnet scripts/deploy.js
```
