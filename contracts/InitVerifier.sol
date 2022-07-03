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
            [11993322853676351218760597690676669466237977273902541663981507471262009542187,
             20236853468054281230980810569741989642693921881672770506531411477771648975884],
            [1152753492514405393537240292469740823831722845016811469848569056610966815271,
             3473838277755973785502414061740961077173942136500016342627057216911263293398]
        );
        vk.IC = new Pairing.G1Point[](28);
        
        vk.IC[0] = Pairing.G1Point( 
            10306114424344009605157518631742866837447227379089319633615123292143238545507,
            281760844424820885154553520207461776328368318623942787896496071097180197980
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            4729713343453829020978804918293309740728215452982256363800631211095303907703,
            5668124645574996015557299389620957354804570820400664639937765964964388492996
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            9966469824264224792640741030510612338532821542250337158750010473103468033700,
            78493886100046385991598971413792789359778004499730446987196005791721531093
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            11499910711735930551031885398613507258732141546193846067446059240722025446913,
            6548406684454276003847503283893931153957208709104995063215850747786124849905
        );                                      
        
        vk.IC[4] = Pairing.G1Point( 
            17731390468048419441701311271251353836541713370300531790935581342756771285676,
            15366959648557062862233960621418069016042487604297225321982314907621762165847
        );                                      
        
        vk.IC[5] = Pairing.G1Point( 
            17916301726443562332022058444470981939947461620477358126932238067270471789600,
            19837006107021730937939205183649177319496229634262666405800389739570406223056
        );                                      
        
        vk.IC[6] = Pairing.G1Point( 
            6782424950947785637075165897823516863784657176260797383154902815303463764390,
            11500660490339328518444066644069784824650457960492397019590551181385230668852
        );                                      
        
        vk.IC[7] = Pairing.G1Point( 
            21010552193832777181911135478535764857617261357065185853243336012180867429132,
            11748581745236784985188474245301061638707803568575942819571873894370154318604
        );                                      
        
        vk.IC[8] = Pairing.G1Point( 
            2016927152313853162691649545945889719107331936450788743622025337862991517613,
            4111739142671574819418116655655971047433146359699133251662020454484137487693
        );                                      
        
        vk.IC[9] = Pairing.G1Point( 
            20068834230034752684650017667291168608513666068567603068240649541002167199477,
            19731388822454054965615154042434751273190194717561121202547420107071272040596
        );                                      
        
        vk.IC[10] = Pairing.G1Point( 
            5092074577089672781328789834419003855577949643571606018502141816574805729118,
            4605551693796885324501123774767030221929284935128628953588590309967946491410
        );                                      
        
        vk.IC[11] = Pairing.G1Point( 
            17513027705751866403386395363779380849309933014869178586453243557457821846431,
            16505280304569508715614257761790521844735066327964916712883496763236224329393
        );                                      
        
        vk.IC[12] = Pairing.G1Point( 
            925837678055065983413531858055397499166362550327190012066116870943102159060,
            15780245574059146994791727625927813448901006286146403999340725808107094355398
        );                                      
        
        vk.IC[13] = Pairing.G1Point( 
            4553590826661266124533649976586644274741686682338233063748058338063235176611,
            5046002175269716230548381835409052034601798409214797852597497415101354972958
        );                                      
        
        vk.IC[14] = Pairing.G1Point( 
            15964714028244020006960789860782558671405190620000952677679036453718518832330,
            19062802867876508241470775711355331366310408148287890673493858194497179054411
        );                                      
        
        vk.IC[15] = Pairing.G1Point( 
            4340378674033781829244493531769285201497440996417168170736660358874526972001,
            18893548035733456724552014289545792224979951328536375593045225230841608017167
        );                                      
        
        vk.IC[16] = Pairing.G1Point( 
            10263164498294123888288684292717095835394393894804552420748750267659301051536,
            21295118165969397205338462050465157947638205188066482029527765395101970058297
        );                                      
        
        vk.IC[17] = Pairing.G1Point( 
            6480941044265331210418873542912984379345626788888728839728870962976769192043,
            12325025773237178665338592524861492259397952216226800922700441001816212189404
        );                                      
        
        vk.IC[18] = Pairing.G1Point( 
            709194410141841570142797100976307622002573789387131262310882791978472583286,
            18058310323736885259117371966205726442931979683966273239721541828418603574872
        );                                      
        
        vk.IC[19] = Pairing.G1Point( 
            6000067828955534335348356187698925395896131827455316964756657715815188499391,
            12155427376116766191842791114936531164733379169402526803192083010378914008414
        );                                      
        
        vk.IC[20] = Pairing.G1Point( 
            19985458361669364857254640802464162588025938435966706214565157139827371735651,
            611409697680633002478091054689819933179934709011319664601903709269904709830
        );                                      
        
        vk.IC[21] = Pairing.G1Point( 
            17985952441742593906559751893796059966363883749959003013333558978546437954971,
            14634072581035291537965157164553927078581716685539348511141681366536999274938
        );                                      
        
        vk.IC[22] = Pairing.G1Point( 
            6774746270306596588850588471079769748701494264153791967453830587544651987897,
            5221083261175519224141894858985916922817807687303666278941688621844318067964
        );                                      
        
        vk.IC[23] = Pairing.G1Point( 
            15833724111791724837984055661789594890167394825200146900707561336877894290880,
            14160498676726994186336417625523216672709639475733197678150067167067536882111
        );                                      
        
        vk.IC[24] = Pairing.G1Point( 
            4015897146832611309019810040764096983808501603145815610353853749170129221313,
            17367689459638670318043030504225768240790179109885127116893298488955035320794
        );                                      
        
        vk.IC[25] = Pairing.G1Point( 
            10854259972865029172841863760715040028959477748759704708187218743450332464095,
            16521817304360493367308288132280775506561260726675087201955418561438176931323
        );                                      
        
        vk.IC[26] = Pairing.G1Point( 
            16567413756868026115995222470242536937146780568119557945515065922647610564986,
            19788942878797098719309829136995745632768097623376241059036162492117328279613
        );                                      
        
        vk.IC[27] = Pairing.G1Point( 
            13866959092403878393561869674808779558657527897910518828696514703849336204268,
            1051306685265015705494715720086108340432516176799700012234427696154820063415
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
            uint[27] memory input
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
