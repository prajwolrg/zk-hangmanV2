const fs = require("fs");

const solidityRegex = /pragma solidity \^\d+\.\d+\.\d+/
const contractNameRegex = /contract Verifier/

const INIT_VERIFIER_PATH = './contracts/InitVerifier.sol'
let initContent = fs.readFileSync(INIT_VERIFIER_PATH, { encoding: 'utf-8' });
let initBumped = initContent.replace(solidityRegex, 'pragma solidity ^0.8.0');
let initBumpedAndRenamed = initBumped.replace(contractNameRegex, 'contract InitVerifier')
fs.writeFileSync(INIT_VERIFIER_PATH, initBumpedAndRenamed);

const GUESS_VERIFIER_PATH = './contracts/GuessVerifier.sol'
let guessContent = fs.readFileSync(GUESS_VERIFIER_PATH, { encoding: 'utf-8' });
let guessBumped = guessContent.replace(solidityRegex, 'pragma solidity ^0.8.0');
let guessBumpedAndRenamed = guessBumped.replace(contractNameRegex, 'contract GuessVerifier')
fs.writeFileSync(GUESS_VERIFIER_PATH, guessBumpedAndRenamed);
