#!/bin/bash

#deploy contracts
npx hardhat run --network devnet scripts/deploy.js

#copy abis
echo copying abis
cp artifacts/contracts/zkHangman.sol/zkHangman.json ../zk-hangman-frontend/abis/
cp artifacts/contracts/zkHangmanFactory.sol/zkHangmanFactory.json ../zk-hangman-frontend/abis/

# copy files
# rm -rf ../zk-hangman-frontend/public/
# cp -r public/ ../zk-hangman-frontend/