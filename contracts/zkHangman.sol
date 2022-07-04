// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {InitVerifier} from "./InitVerifier.sol";
import "./GuessVerifier.sol";

// @title Implementation of Hangman Game Utilizing Zero Knowledge
// @notice This contract is deployed from zkHangmanFactory contract

// Alphabets of the word as represented as numbers as:
// A -> 1
// B -> 2
// C -> 3
// ...
// Z -> 26

// Unknown/unrevealed alphabets are represented by using the number 0.

contract zkHangman {
    InitVerifier public initVerifier;
    GuessVerifier public guessVerifier;

    address public host;
    address public player;

    uint256 public totalChars;
    uint256 public playerLives = 6;
    uint256 public secretHash;
    uint256 public correctGuesses;

    // turn is used to track if the move can be made by host/player
    uint256 public turn;

    bool public gameOver;

    uint256[] public guesses;
    uint256[] public characterHashes;
    uint256[] public revealedChars;

    event NextTurn(uint256 nextTurn);

    struct ProcessGuessParam {
        uint256[2] _a;
        uint256[2][2] _b;
        uint256[2] _c;
        uint256[27] _input;
    }


    // @notice Initializes the game after verifying the proof
    // _input is the public outputs from the init circuit.
    // input[0] contains the hash of the secret
    // input[1] contains the total characters in the word
    // input[2...26] contains the hashes of the characters

    // if 0 < wordLengh < 25, the additional hashes is 0 and is not required to be processed

    // the host can choose a word of any length < 25
    // 25 is chosen arbitrarily and the word limit can be set from the circuits.

    function initializeGame(
        uint256[2] memory _a,
        uint256[2][2] memory _b,
        uint256[2] memory _c,
        uint256[27] memory _input
    ) private gameNotOver {

        // Game can only initialized if none has played yet.
        require(turn == 0, "invalid turn");

		// Verify the circuit proof
        require(initVerifier.verifyProof(_a, _b, _c, _input), "invalid proof");

        // Total characters in the word is given in _input[1]
        totalChars = _input[1];

        // Total characters in the word must be less than the input length
        // This check can be omitted since the totalChars is set from the output of the circuit
        // and thus the relation is always true.
        require(totalChars < _input.length, "total chars must be less");

		// Save the secret hash to verify later that the same secret is being used to process guess
        secretHash = _input[0];

		// Save the character hashes of the alphabets
		// Set none of the characters are revealed.
        for (uint256 i = 0; i < totalChars; i++) {
            characterHashes.push(_input[i + 2]);
            revealedChars.push(0); 
        }

        turn++;

        emit NextTurn(turn);
    }

    // @notice Creates the game
    constructor(
        address _initVerifier,
        address _guessVerifier,
        uint256[2] memory _a,
        uint256[2][2] memory _b,
        uint256[2] memory _c,
        uint256[27] memory _input
    ) {
        host = tx.origin;
        initVerifier = InitVerifier(_initVerifier);
        guessVerifier = GuessVerifier(_guessVerifier);

        initializeGame(_a, _b, _c, _input);
    }

    modifier gameNotOver() {
        require(!gameOver, "the game is over");
        _;
    }

	// @notice Allow player to join the game
    function joinGame() public {

        // Host cannot join themselves as the player
        require(msg.sender != host, "invalid player");

        // Only one player can join the game
        require(player == address(0), "someone has already joined the game");

        // Set the player address
        player = msg.sender;
    }

    // @notice Makes a guess.
    // @param _guess Must be an alphabet [A..Z] represented as number
    function playerGuess(uint256 _guess) external gameNotOver {

        // Only player can make a guess
        require(msg.sender == player, "invalid caller");

        // Player can make guess only in their turn
        require(turn % 2 == 1, "invalid turn");

        // Guess must be a valid representation of character
        require(_guess >= 1 && _guess <= 26, "invalid guess");

		// Check if the alphabet has already been guesses.
        for (uint256 i = 0; i < guesses.length; i++) {
            require(guesses[i] != _guess, "already guessed");
        }

        // Add guessed alphabet to the list of guesses
        guesses.push(_guess);

        turn++;

        emit NextTurn(turn);
    }

    // @notice Process the player's guess

    // input[0] contains the hash of the secret
    // input[1..26] contains the hash(char, secret, index)
    // input[27] contains the character represented in the range 1-26
    function processGuess(
        uint256[2] memory _a,
        uint256[2][2] memory _b,
        uint256[2] memory _c,
        uint256[27] memory _input
    ) external gameNotOver {

        // Only host can process the guess
        require(msg.sender == host, "invalid caller");

        // Host can process the guess in his turn
        require(turn != 0 && turn % 2 == 0, "invalid turn");

        // Ensure that the host has processed the guess made by player
        require(_input[26] == guesses[guesses.length - 1], "invalid character");

        // Ensure that the host has used same secret as used in the initialization
        require(_input[0] == secretHash, "invalid secret");

        // Verify proof
        require(guessVerifier.verifyProof(_a, _b, _c, _input), "invalid proof");

        // Check if the player made right/wrong guess
        bool incorrectGuess = true;
        for (uint256 i = 0; i < characterHashes.length; i++) {
            if (_input[1+i] == characterHashes[i]) {
                revealedChars[i] = _input[26];
                incorrectGuess = false;
                correctGuesses++; // this is fine since the player cannot guess the same character twice
            }
        }

		// If wrong guess, decrease the life of player
        if (incorrectGuess) {
            playerLives -= 1;
        }

        // Check if the game is over
        if (correctGuesses == characterHashes.length || playerLives == 0) {
            gameOver = true;
        }

        turn++;

        emit NextTurn(turn);
    }

	// @notice Reveals the unguessed alphabets by the host
	// @notice Similar to the processGuess function
    function reveal(ProcessGuessParam[] memory params) external {
        require(gameOver, "game must be over");
        require(msg.sender == host, "invalid caller");

        for (uint256 i=0; i<params.length; i++) {
            require(params[i]._input[0] == secretHash, "invalid secret");
            require(guessVerifier.verifyProof(params[i]._a, params[i]._b, params[i]._c, params[i]._input), "invalid proof");

            for (uint256 j = 0; j < characterHashes.length; j++) {
                if (params[i]._input[1+j] == characterHashes[j]) {
                    revealedChars[j] = params[i]._input[26];
                }
            }
        }
        turn ++;
        emit NextTurn(turn);
    }

    // @notice Returns the information about the game
    function getGameInfo() public view returns (
        address _host,
        address _player,
        uint256 _playerLives,
        bool _gameOver,
        uint256 _correctGuesses, 
        uint256 _turn,
        uint256 _totalChars,
        uint256[] memory _guesses,
        uint256[] memory _characterHashes,
        uint256[] memory _revealedChars
    ) {
        _host = host;
        _player = player;
        _playerLives = playerLives;
        _gameOver = gameOver;
        _correctGuesses = correctGuesses;
        _turn = turn;
        _totalChars = totalChars;
        _guesses = guesses;
        _characterHashes = characterHashes;
        _revealedChars = revealedChars;
    }
}
