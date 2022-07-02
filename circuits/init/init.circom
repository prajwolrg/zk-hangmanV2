pragma circom 2.0.0;

include "../circomlib/mimcsponge.circom";
include "../circomlib/comparators.circom";
include "../circomlib/mux1.circom";

// This circuit is used for the initializaiton of hangman game.
// The hangman game can have a word of maximum 'n' size.
// 'n' is passed as the parameter for the init template

// Alphabets in the game are represented as digits between 1-26 inclusive.
// A=1 B=2 C=3 ... Z=26

// It is assumed that the length of the word is less than or equal to 'n'
// If the word length is less than 'n', the remaining are represented as digit 0.

// For example for A-P-P-L-E and n=25,
// char[0] -> 1  (A)
// char[1] -> 16 (P)
// char[2] -> 16 (P)
// char[3] -> 16 (L)
// char[4] -> 10 (E)
// char[5] -> 0  (null)
// char[6] -> 0  (null)
// ....
// char[25] -> 0 (null)

template init(n) {

    signal input secret;
    signal input char[n];

    signal output secretHash;
    signal output wordLength;
    signal output charHash[n];

    component leqt[n];
    component geqt[n];

    var endOfWordFlag = 0;

	// Verify that the characters are valid
    // Check that : 0 <= char <= 26

    for (var i = 0; i < n; i++) {

        // In LessEqThan(n), n is the no of bits
        // no of bits can be calculated by taking ceiling(log2(n))
        // for n=25, log2(n) = 4.6438, so ceiling(log2(n)) = 5

        leqt[i] = LessEqThan(5);
        leqt[i].in[0] <== char[i];
        leqt[i].in[1] <== 26; 

		// Verify char <= 26
        leqt[i].out === 1;

        // Similarly, in GreaterEqThan(n), n is the no of bits

        geqt[i] = GreaterEqThan(5);
        geqt[i].in[0] <== char[i];
        geqt[i].in[1] <== 0; 

		// Verify char >= 0
        geqt[i].out === 1;
    }

    // Calculate hash of the secret input
    component mimcSecret = MiMCSponge(1, 220, 1);
    mimcSecret.ins[0] <== secret;
    mimcSecret.k <== 0;
    secretHash <== mimcSecret.outs[0];


    component isZero[n];
    component charMimc[n];
    component muxChar[n];
    component muxLength[n];

    var length = 0;
    for (var i = 0; i < n; i++) {

        isZero[i] = IsZero();
        charMimc[i] = MiMCSponge(3, 220, 1);
        muxChar[i] = Mux1();
        muxLength[i] = Mux1();

		// Check if the char is 0 (null)
        isZero[i].in <== char[i];

		// If null character is previously encountered, the word has already ended
        // and there can be no valid character later
        if (endOfWordFlag == 1) {
            isZero[i].out === 1;
        }
        endOfWordFlag = isZero[i].out;

        // Calculate hash of each character
        // charHash = hash(char, secret, index)

        // Without the use of index, charHash for the same letter will be same
        // That might reveal some information
        // For example in A-P-P-L-E, charHash of P would be same in both 2nd and 3rd index
        charMimc[i].ins[0] <== char[i];
        charMimc[i].ins[1] <== secret;
        charMimc[i].ins[2] <== i;
        charMimc[i].k <== 0;

        // If char is null, output should also be 0 and not the charHash
        muxChar[i].c[0] <== charMimc[i].outs[0];
        muxChar[i].c[1] <== 0;
        muxChar[i].s <== isZero[i].out;

        charHash[i] <== muxChar[i].out;

		// Calculate the length of the word
        muxLength[i].c[0] <== length + 1;
        muxLength[i].c[1] <== length;
        muxLength[i].s <== isZero[i].out;
        length = muxLength[i].out;

    }

    wordLength <== length;

}

component main = init(25);
