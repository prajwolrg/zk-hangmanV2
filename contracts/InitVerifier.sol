//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.6
//      fixed linter warnings
//      added requiere error messages
//
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() internal pure returns (G2Point memory) {
        // Original code point
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );

/*
        // Changed by Jordi point
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
*/
    }
    /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) internal pure returns (G1Point memory r) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-add-failed");
    }
    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"pairing-mul-failed");
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length,"pairing-lengths-failed");
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-opcode-failed");
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}
contract InitVerifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }
    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(
            20491192805390485299153009773594534940189261866228447918068658471970481763042,
            9383485363053290200918347156157836566562967994039712273449902621266178545958
        );

        vk.beta2 = Pairing.G2Point(
            [4252822878758300859123897981450591353533073413197771768651442665752259397132,
             6375614351688725206403948262868962793625744043794305715222011528459656738731],
            [21847035105528745403288232691147584728191162732299865338377159692350059136679,
             10505242626370262277552901082094356697409835680220590971873171140371331206856]
        );
        vk.gamma2 = Pairing.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = Pairing.G2Point(
            [12495435589969770956496171055219774569804855590450287044073338224045694141307,
             17736339139644322733781313516155163871574978742452842178498877042942680390514],
            [11976350287016867640237998091025387200079897732921165438641067613281666435729,
             2765988105754776914521783991133574936947526308104329035492142213281609125275]
        );
        vk.IC = new Pairing.G1Point[](27);
        
        vk.IC[0] = Pairing.G1Point( 
            6577637107524670221936520477049517379562524563738742494095491907027189741046,
            9463545037852684967836787339897345447301044052494958929176403603750795232633
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            12278534745101244341961779462601287941190301651355110682049842551185927194852,
            14480644543023395810851905953760811939279655984859166159422070728491527715809
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            6089437478250246336347714620645735082824203947420881604334456144828578890571,
            10775516462598459512053021763524520105954850522508278180628219894239237116031
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            18405178819868622105499316766733594609848626624360139674984901734119148427675,
            7710106593988675098791338759345111272937663987470155382827539012388879875724
        );                                      
        
        vk.IC[4] = Pairing.G1Point( 
            8490999796667750437931113844156467705630328097481497654693099613043665704544,
            19778796911253678773087928446002349518511626851100605344009538877645496825123
        );                                      
        
        vk.IC[5] = Pairing.G1Point( 
            20596655585728523055329947009383550084636742305318834267756081861121134246742,
            754656283666840581836891824211588586551585645873050862817762346439598238005
        );                                      
        
        vk.IC[6] = Pairing.G1Point( 
            20303299417191380023608434504692761825741447154214770921251679167439082417848,
            402387163712816550611762506902604875907523711297938668181395933278180112319
        );                                      
        
        vk.IC[7] = Pairing.G1Point( 
            7262464235341890332703406112834273874761091377704715515557439651956517052444,
            14106776553786656128467608065778795485691734525209403215530655307152496007601
        );                                      
        
        vk.IC[8] = Pairing.G1Point( 
            2424522253373705663665824633996589377167136562840492532385545496691809308576,
            5369915358158095998656550841776640499657970307341633382862666691192718260392
        );                                      
        
        vk.IC[9] = Pairing.G1Point( 
            11542665631077306601995397021685442273074692026536418839694130789702337020535,
            17278982325405363899970407350211975483353694915269099815963959530634779637158
        );                                      
        
        vk.IC[10] = Pairing.G1Point( 
            17107317427981437096033271493825885947093623267119212159274469646081011818839,
            5822980068747523386590355938229654784781847932492350628713732774691431463373
        );                                      
        
        vk.IC[11] = Pairing.G1Point( 
            8256463127690606235774518933044780070798253859680354715398386100664756848321,
            16864413326824862383528183954664099387404034606612817748162266020089199140367
        );                                      
        
        vk.IC[12] = Pairing.G1Point( 
            17909175756035487711044353386358456243391176383801045451792147057537078344591,
            2718192126332154701911066079206208908420525775543865702467218413108310222397
        );                                      
        
        vk.IC[13] = Pairing.G1Point( 
            8628291918452083961928249763895746028118364124776667191192047676092106288993,
            6632549543358614569796141760139245475364081592253747116104367041956315227739
        );                                      
        
        vk.IC[14] = Pairing.G1Point( 
            12526483397314450527761969976513960109528364589024880555984824787645974260337,
            16284396243120299641974702722370912438171716872787983838395620485790089513051
        );                                      
        
        vk.IC[15] = Pairing.G1Point( 
            16811569721855694290517848437294999451505347893358167961210717950436050566244,
            20252143328312253306474480226201805304496840876395732670319784720652339635556
        );                                      
        
        vk.IC[16] = Pairing.G1Point( 
            3212560915954057314822521310765467538743254443277952966403621342843046368379,
            10592826115015222831956627661832806156997124627166244452050219686104659268992
        );                                      
        
        vk.IC[17] = Pairing.G1Point( 
            15969988366064626832558854236772005343239924142265852712680254028685320221498,
            19384874893943021338467065693880087693180107221289480315885770482362321375060
        );                                      
        
        vk.IC[18] = Pairing.G1Point( 
            7726226587180507483977686898339896104646925657731674848393513959238688504385,
            5474124547759721261722918535128140645750270271086635025648830192466638778793
        );                                      
        
        vk.IC[19] = Pairing.G1Point( 
            15735142022337247563435207516527569890819401360549469427594852954943031104860,
            16912003856266423825131356802200974838174434300548408509789993195140694943844
        );                                      
        
        vk.IC[20] = Pairing.G1Point( 
            21567122506318649090279026203685829309110578334827983209937947687742693682796,
            7716162475139886856499630308108973244965936643819223460907361839470494888360
        );                                      
        
        vk.IC[21] = Pairing.G1Point( 
            12585311206568805784503886984761126569573744744675455771086514452322960028083,
            17353020041822491077678482739707025492369693548784455896004638070557801775228
        );                                      
        
        vk.IC[22] = Pairing.G1Point( 
            8442926918879774157465163307455516546077016730340633786365972951193479808862,
            11094354966188948990578812514978001871151881989623879667981118573539305377958
        );                                      
        
        vk.IC[23] = Pairing.G1Point( 
            3745739125995186807451048512708308755953609426365204618059306855853443266676,
            15073647428077863445709741840139059415733459762783619260210631310162079071387
        );                                      
        
        vk.IC[24] = Pairing.G1Point( 
            15102424224500302052889759024790745061164664492267821441954667639895474324200,
            20371022384619965918572012702016097970214256361664529432518424440905328639507
        );                                      
        
        vk.IC[25] = Pairing.G1Point( 
            6073929948112461226532819192811117430547741237339933139503826339830810423382,
            6801282386133163360258170722038109368847039047524014322648686148358954192997
        );                                      
        
        vk.IC[26] = Pairing.G1Point( 
            15956326976141188476683871184363992515745213833544721572896668182253976085715,
            17610349251562776386567166454159201466766301958030470787654301536360096125892
        );                                      
        
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (!Pairing.pairingProd4(
            Pairing.negate(proof.A), proof.B,
            vk.alfa1, vk.beta2,
            vk_x, vk.gamma2,
            proof.C, vk.delta2
        )) return 1;
        return 0;
    }
    /// @return r  bool true if proof is valid
    function verifyProof(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[26] memory input
        ) public view returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}
