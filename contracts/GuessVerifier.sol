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
contract GuessVerifier {
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
            [17241151435783319365656374079689198168990468119214574902028053397314152208035,
             12064153174170999760769277109395138781944627163502713972170776309824924609226],
            [701656272578439552809849029142177464190868432787143397360355611369476812383,
             5048501257551043619089170488535316837986402540296926771975492376272296020205]
        );
        vk.IC = new Pairing.G1Point[](28);
        
        vk.IC[0] = Pairing.G1Point( 
            17416890976286680771433308111671956488791117656710211101267799742392333708787,
            7938284041773086128086520194634598770807869833781297246995657402119184453964
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            20067679120832322310663063855367916902345243470837751877284693270257488578401,
            2249693815778633620528847117798219775573783856282739045140593740531721701290
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            15516931889091422631223594790826024134112055660793541674078133811678378091925,
            1363657392177029822205491667320103098415055081302618316363845530040396565804
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            16659237735962649238729186418617615657783799914477787117477341670407419931582,
            7943760774511902445186609270852552083405290110662838020997931023604861585102
        );                                      
        
        vk.IC[4] = Pairing.G1Point( 
            4932426331950592149660316700533743053300944653857138794102171190452709794596,
            8138548731154887754335594259979485303487745567282326478173936771582764703410
        );                                      
        
        vk.IC[5] = Pairing.G1Point( 
            1147851073501628811690748345855608093865894491758840648720800255671477548929,
            18905729875120743818990157751210942453338901292122379888478448017102974850376
        );                                      
        
        vk.IC[6] = Pairing.G1Point( 
            20609080750424962949244169068521922057337296073970268136584759290098299069083,
            7422273858589036574267575742707875873333313189834055056094470285612016549719
        );                                      
        
        vk.IC[7] = Pairing.G1Point( 
            16676366275940667258691036935469556611157291752701617600506783665898481801168,
            4211055245407700168166526686909863034430260489384570583809350539572825072228
        );                                      
        
        vk.IC[8] = Pairing.G1Point( 
            14850847527705513594744538383720581161036959790046093115599790063112170931236,
            19641570621023570143286251429099274671919647005717427698696572658914279065985
        );                                      
        
        vk.IC[9] = Pairing.G1Point( 
            7888029708154967357880024068012308337900466161912275863648039260214782085064,
            996630338789938130406295574547989902551657677898432871575188756119396875554
        );                                      
        
        vk.IC[10] = Pairing.G1Point( 
            13078403123292240677606431967894949316108947784569013039179793229016423070747,
            3336137740934096999560133545359921803814960785710268007441557523173510355327
        );                                      
        
        vk.IC[11] = Pairing.G1Point( 
            9060152324536415234580800926764875939896263805154106899520856133433311055541,
            5260013236075747671645343106915458548434821865137453416150376217245395670242
        );                                      
        
        vk.IC[12] = Pairing.G1Point( 
            10753457707444739287555467524940017576542323596139238067235833934794085539837,
            16606944434236664654665947950772502509573217976480814453216572745563731167659
        );                                      
        
        vk.IC[13] = Pairing.G1Point( 
            10384792947167636984894465459313510846124888348629391617308060688050733803867,
            1157666248386641614264443774545322049066840728366110167287949869579017760832
        );                                      
        
        vk.IC[14] = Pairing.G1Point( 
            6974322399754708062324503897277141489861465709552575932160641559529057169858,
            17185412261474568566359728266174421723793206928541302678897674484430069460155
        );                                      
        
        vk.IC[15] = Pairing.G1Point( 
            16938070076500190452088726394648989333998190206083807422797483721789585214133,
            6819059413285683389771387530117766179888466499484735618261171759580201825832
        );                                      
        
        vk.IC[16] = Pairing.G1Point( 
            18215855790085758105501941219165390775484383468367823327191503934476762858245,
            5442275071336582077716641966435061963026071145494438145818552389110988908908
        );                                      
        
        vk.IC[17] = Pairing.G1Point( 
            7972015696239091423151279247870214600801526602673397475337282207365885400350,
            13685199733170564907250385336457567731967569701484268048004546635123998729786
        );                                      
        
        vk.IC[18] = Pairing.G1Point( 
            16660544903236762617031158998266581838307784700559523912349737098319056229735,
            8035098923584097960140075584219437728843017318402889970119183406811220361937
        );                                      
        
        vk.IC[19] = Pairing.G1Point( 
            20900961438502074078461105635090722262381482136954899633408417158274087767123,
            2009675573623657070656664619390959171544373028304808163106168801147065120225
        );                                      
        
        vk.IC[20] = Pairing.G1Point( 
            19191021285164437267827992292410043049799457272391407673770194600306006280060,
            19349372275781710174222592022499002455286364428495732026446159658350382342689
        );                                      
        
        vk.IC[21] = Pairing.G1Point( 
            16214631874697148448635527647301709858333232435232087474819664302251316520500,
            12977408927942134222114216012650521733033798810287777232514331482610779824381
        );                                      
        
        vk.IC[22] = Pairing.G1Point( 
            2673732022835708330869591559148929808770088228575682182540340600180191052578,
            15374847306922899661717106362278198694854435230080663189832645982568339466761
        );                                      
        
        vk.IC[23] = Pairing.G1Point( 
            16059899897372291096319370774447157161212516602336531477783740428702765837403,
            15048157148753791779881536417720782370564746117987257205655633428728473266941
        );                                      
        
        vk.IC[24] = Pairing.G1Point( 
            12699203168311911719036376128168117506030033654968184229676668349947802876926,
            1270128321125786671025652840960967915789917146916573780262685343302985317
        );                                      
        
        vk.IC[25] = Pairing.G1Point( 
            5168700088532836787808410591558198114161838074178416113110593261702552626586,
            5197757331717949370676182982054937863909847634213295809620512913188403826766
        );                                      
        
        vk.IC[26] = Pairing.G1Point( 
            21840736552200668598575413264706936998032216896958031843279251818804185892698,
            17434949156462564363239783033889697051089876160298298884446924255107039214998
        );                                      
        
        vk.IC[27] = Pairing.G1Point( 
            7297031249337111866092855286999626624457330142819888630900376528687203615014,
            4013882944211146950306503924810615759607241489491116507849973561155926460561
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
