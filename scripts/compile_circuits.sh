#!/bin/bash

cd circuits
if [ -f ./powersOfTau28_hez_final_17.ptau ]; then
    echo "powersOfTau28_hez_final_17.ptau already exists. Skipping."
else
    echo 'Downloading powersOfTau28_hez_final_17.ptau'
    wget https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_17.ptau
fi

cd init

echo "Compiling init.circom..."

# compile circuit
circom init.circom --r1cs --wasm --sym -o .
snarkjs r1cs info init.r1cs
cp init_js/init.wasm ../../public/

# Start a new zkey and make a contribution

snarkjs groth16 setup init.r1cs ../powersOfTau28_hez_final_17.ptau init_0000.zkey
snarkjs zkey contribute init_0000.zkey init_0001.zkey --name="1st Contributor Name" -v -e="random text"
snarkjs zkey export verificationkey init_0001.zkey init_verification_key.json
cp init_0001.zkey ../../public/
cp init_verification_key.json ../../public/

# generate solidity contract
snarkjs zkey export solidityverifier init_0001.zkey ../../contracts/InitVerifier.sol

cd ../guess

echo "Compiling guess.circom..."

# compile guess.circom and copy needed files to public
circom guess.circom --r1cs --wasm --sym -o .
snarkjs r1cs info guess.r1cs
cp guess_js/guess.wasm ../../public/

# Start a new zkey and make a contribution
snarkjs groth16 setup guess.r1cs ../powersOfTau28_hez_final_17.ptau guess_0000.zkey
snarkjs zkey contribute guess_0000.zkey guess_0001.zkey --name="PG" -v -e="random text"
snarkjs zkey export verificationkey guess_0001.zkey guess_verification_key.json
cp guess_0001.zkey ../../public/
cp guess_verification_key.json ../../public/

# generate solidity contract
snarkjs zkey export solidityverifier guess_0001.zkey ../../contracts/GuessVerifier.sol

cd ../..

# adjust solidity contracts
node scripts/adjust_solidity.js