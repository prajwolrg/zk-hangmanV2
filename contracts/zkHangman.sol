// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {InitVerifier} from "./InitVerifier.sol";
import "./GuessVerifier.sol";

contract zkHangman {
    InitVerifier public initVerifier;
    GuessVerifier public guessVerifier;

    address public host;
    address public player;

    uint256 public playerLives = 6;
    uint256 public secretHash;
    uint256 public correctGuesses;
    uint256 public turn;
    uint256 public totalChars;

    bool public gameOver;

    uint256[] public guesses;
    uint256[] public characterHashes;
    uint256[] public revealedChars;

    event NextTurn(uint256 nextTurn);

    // verify init proof and set up contract state
    // input[0] contains the hash of the secret
    // input[1..] contains the hashes of the characters
    // the host has to choose a word with a length of 5
    function initializeGame(
        uint256[2] memory _a,
        uint256[2][2] memory _b,
        uint256[2] memory _c,
        uint256[26] memory _input,
        uint256 _totalChars
    ) private gameNotOver {
        require(turn == 0, "invalid turn");
        require(initVerifier.verifyProof(_a, _b, _c, _input), "invalid proof");
        require(_totalChars < _input.length, "total chars must be less");

        secretHash = _input[0];
        totalChars = _totalChars;

        for (uint256 i = 0; i < totalChars; i++) {
            characterHashes.push(_input[i + 1]);
            revealedChars.push(99); // we'll use 99 to indicate that a char has not been revealed yet
        }

        turn++;

        emit NextTurn(turn);
    }

    constructor(
        address _player,
        address _initVerifier,
        address _guessVerifier,
        uint256[2] memory _a,
        uint256[2][2] memory _b,
        uint256[2] memory _c,
        uint256[26] memory _input,
        uint256 _totalChars
    ) {
        host = tx.origin;
        player = _player;
        initVerifier = InitVerifier(_initVerifier);
        guessVerifier = GuessVerifier(_guessVerifier);

        initializeGame(_a, _b, _c, _input, _totalChars);
    }

    modifier gameNotOver() {
        require(!gameOver, "the game is over");
        _;
    }

    function playerGuess(uint256 _guess) external gameNotOver {
        require(playerLives > 0);
        require(msg.sender == player, "invalid caller");
        require(turn % 2 == 1, "invalid turn");
        require(_guess >= 0 && _guess <= 25, "invalid guess");

        for (uint256 i = 0; i < guesses.length; i++) {
            require(guesses[i] != _guess, "already guessed");
        }

        guesses.push(_guess);

        turn++;

        emit NextTurn(turn);
    }

    // input[0] contains the hash of the secret
    // input[1] contains the hash of the character and the secret
    // input[2] contains the character represented as an uint within the range 0-25
    function processGuess(
        uint256[2] memory _a,
        uint256[2][2] memory _b,
        uint256[2] memory _c,
        uint256[3] memory _input
    ) external gameNotOver {
        require(msg.sender == host, "invalid caller");
        require(turn != 0 && turn % 2 == 0, "invalid turn");
        require(_input[2] == guesses[guesses.length - 1], "invalid character");
        require(_input[0] == secretHash, "invalid secret");
        require(guessVerifier.verifyProof(_a, _b, _c, _input), "invalid proof");

        // check if player has made an incorrect guess
        bool incorrectGuess = true;

        for (uint256 i = 0; i < characterHashes.length; i++) {
            if (_input[1] == characterHashes[i]) {
                revealedChars[i] = _input[2];
                incorrectGuess = false;
                correctGuesses++; // this is fine since the player cannot guess the same character twice
            }
        }

        if (incorrectGuess) {
            playerLives -= 1;
        }

        // check if game is over
        if (correctGuesses == characterHashes.length) {
            gameOver = true;
        }

        turn++;

        emit NextTurn(turn);
    }
}
