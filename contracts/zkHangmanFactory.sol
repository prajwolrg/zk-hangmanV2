// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./zkHangman.sol";

contract zkHangmanFactory {
    address[] public games;

    event GameCreated(
        address indexed host,
        address gameAddress,
        address initVerifier,
        address guessVerifier,
        uint256 totalChars
    );

    function createGame(
        address _initVerifier,
        address _guessVerifier,
        uint256[2] memory _a,
        uint256[2][2] memory _b,
        uint256[2] memory _c,
        uint256[27] memory _input,
        uint256 _totalChars
    ) public {
        zkHangman _game = new zkHangman(
            _initVerifier,
            _guessVerifier,
            _a,
            _b,
            _c,
            _input,
            _totalChars
        );
        games.push(address(_game));

        emit GameCreated(
            msg.sender,
            address(_game),
            _initVerifier,
            _guessVerifier,
            _totalChars
        );
    }
}
