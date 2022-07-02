pragma circom 2.0.0;

include "../circomlib/mimcsponge.circom";
include "../circomlib/comparators.circom";

template init(n) {
    signal input secret;
    signal input char[n];

    signal output secretHash;
    signal output charHash[n];

    component leqt[n];
    component geqt[n];

    // characters are represented as digits between 0-25 inclusive

    for (var i = 0; i < n; i++) {
        leqt[i] = LessEqThan(5);
        leqt[i].in[0] <== char[i];
        leqt[i].in[1] <== 25; 

        leqt[i].out === 1;

        geqt[i] = GreaterEqThan(5);
        geqt[i].in[0] <== char[i];
        geqt[i].in[1] <== 0; 

        geqt[i].out === 1;
    }

    // calculate secret hash

    component mimcSecret = MiMCSponge(1, 220, 1);

    mimcSecret.ins[0] <== secret;
    mimcSecret.k <== 0;

    secretHash <== mimcSecret.outs[0];

    // calculate character hashes

    component charMimc[n];

    for (var i = 0; i < n; i++) {
        charMimc[i] = MiMCSponge(3, 220, 1);

        charMimc[i].ins[0] <== char[i];
        charMimc[i].ins[1] <== secret;
        charMimc[i].ins[2] <== i;
        charMimc[i].k <== 0;
        
        charHash[i] <== charMimc[i].outs[0];
    }

}

component main = init(25);
