pragma circom 2.0.0;

include "../circomlib/mimcsponge.circom";
include "../circomlib/comparators.circom";

template guess(n) {
    signal input char;
    signal input secret;

    signal output secretHash;
    signal output charHash[n];

    // calculate secret hash

    component mimcSecret = MiMCSponge(1, 220, 1);
    mimcSecret.ins[0] <== secret;
    mimcSecret.k <== 0;
    secretHash <== mimcSecret.outs[0];


	// Verify that the character is valid
    // Check that : 1 <= char <= 26

    component leqt = LessEqThan(5);
    component geqt = GreaterEqThan(5);

    // In LessEqThan(n), n is the no of bits
    // no of bits can be calculated by taking ceiling(log2(n))
    // for n=25, log2(n) = 4.6438, so ceiling(log2(n)) = 5

    leqt.in[0] <== char;
    leqt.in[1] <== 26; 

    // Verify char <= 26
    leqt.out === 1;

    // Similarly, in GreaterEqThan(n), n is the no of bits

    geqt.in[0] <== char;
    geqt.in[1] <== 1; 

    // Verify char >= 1 
    geqt.out === 1;

    // Calculate char hash for each index
    // charHash = hash(char, secret, index)
    component charMimc[n];

    for (var i = 0; i < n; i++) {
        charMimc[i] = MiMCSponge(3, 220, 1);

        charMimc[i].ins[0] <== char;
        charMimc[i].ins[1] <== secret;
        charMimc[i].ins[2] <== i;
        charMimc[i].k <== 0;
        
        charHash[i] <== charMimc[i].outs[0];
    }

}

component main {public [char] } = guess(25);

