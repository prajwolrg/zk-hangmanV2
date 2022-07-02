pragma circom 2.0.0;

include "../circomlib/mimcsponge.circom";

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

    // calculate character hash which is hash(char, secret)

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

