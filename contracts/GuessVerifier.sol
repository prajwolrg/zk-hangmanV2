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
            [20457890159906644955900809542333517881061851580635941200127499608095360749782,
             4809677480513390575601603992039224501130566129524098712104192721183225396069],
            [8193993451727621993706046783692509168076887898988737428583979500244705315723,
             10681440715723879892669046856085048534759789868522080977185280300074330808116]
        );
        vk.IC = new Pairing.G1Point[](28);
        
        vk.IC[0] = Pairing.G1Point( 
            19350636005379619951198081353259373361553038393175365276988167303427134056647,
            15623565511161172297501422286169224011501517088570491694895472734185248111078
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            11913096415674007859937645092592417966699372132729930109239278157539928683053,
            499456468730667607977557309348869640527806299908072688150772203025932961189
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            2754621033846337195550449125656413585708763865414956540274555495475087526151,
            20416018496637658985439075898979532826322699789451831104282074160990676930978
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            9209117051112302084218652218627824720832071289337825746632815734612961374145,
            3758601821891012505195806859143946454483882366770230551697832006554240905201
        );                                      
        
        vk.IC[4] = Pairing.G1Point( 
            14840241864946374228570759960607371422502900715021806934771424401584022700619,
            17184935574806274640382815190208267763271511041948023602141545049399041159943
        );                                      
        
        vk.IC[5] = Pairing.G1Point( 
            1201616554014043571902473638368026418042288805398508988453778318428012703297,
            14658047999148235174785608278996580072572109440697109390173158859739965128932
        );                                      
        
        vk.IC[6] = Pairing.G1Point( 
            653451379904069943530999093211544773346170322168214139782188709112805327929,
            4610275156495732931137853589766741252449932671962955081356818833809332735218
        );                                      
        
        vk.IC[7] = Pairing.G1Point( 
            850332332972183372730855546627598470114219483679464443336118487124383064598,
            2694163158400587319327764081141997824633998214469065521758209812189661948886
        );                                      
        
        vk.IC[8] = Pairing.G1Point( 
            4554814856150643629123346450423577273359475855002222767566332819148841404104,
            21681248374479804041006817074173381437808968297333812316909090001748304196840
        );                                      
        
        vk.IC[9] = Pairing.G1Point( 
            11287684578699525433652847758184319869907378750146113244324219461378835793254,
            21528974870239067912318298792506882662872100717182140412969279638037609361045
        );                                      
        
        vk.IC[10] = Pairing.G1Point( 
            16584775607866257276898157592898366075768537900057383916470414725856910920233,
            4587374702058050158185650202265298699810106987181642173348358702480088642049
        );                                      
        
        vk.IC[11] = Pairing.G1Point( 
            13674050664733913711634431330363269946590321915625974531679695906165124800272,
            10300145874352211628622468236338672370779084809922322385799691730041040126110
        );                                      
        
        vk.IC[12] = Pairing.G1Point( 
            21656275503904545810781405943297219719540965961944255700907197079613518667175,
            550109159868369371562885363233644338859030177516763262734490402836678424933
        );                                      
        
        vk.IC[13] = Pairing.G1Point( 
            5369226064573109428466834719697139390862126683018824715365892884140377449732,
            15518659260201402216296895961776485075860996858825961545247333124472822944310
        );                                      
        
        vk.IC[14] = Pairing.G1Point( 
            2605487498616227942037351787567911121624666001496307515538467058251884439896,
            8749870119037388086706748909515598444859436891947334021465102401487504623474
        );                                      
        
        vk.IC[15] = Pairing.G1Point( 
            11541976892387423113326448406270942957098444316565789043748851338322080781679,
            8255432772936482993041038112244663210812462833721765305654063199062013569426
        );                                      
        
        vk.IC[16] = Pairing.G1Point( 
            11174144849530013207471170390554960283705512311334510877609275613968675668366,
            9202757469086353055292338130605146987527965053271956053793834660402450698998
        );                                      
        
        vk.IC[17] = Pairing.G1Point( 
            6707055031786337145710699782472035295063052347141069686578985365084797426479,
            11839619062028253173697798370818116291729451101055028368596527638715992012078
        );                                      
        
        vk.IC[18] = Pairing.G1Point( 
            18744447719049613383807506586662655994933970147404353387288681036885944978292,
            20102849421411124266793336139478131763587000616329952444771560165890676040220
        );                                      
        
        vk.IC[19] = Pairing.G1Point( 
            17021474096407213510400772613619509861255002060447531688716703330639594492379,
            10088568531033594710185815939167296196360230798829637520475292640455476752543
        );                                      
        
        vk.IC[20] = Pairing.G1Point( 
            4175392845538605665563451448726570721050476621964210027404536306863271869291,
            16727505401916152113437959325309158851528898307239689919234173136432901487193
        );                                      
        
        vk.IC[21] = Pairing.G1Point( 
            8899305778685197316819404506459493957067718110289046219410310948072789986795,
            13528839081010460475625846845936560912430076701309776812853674596914401293
        );                                      
        
        vk.IC[22] = Pairing.G1Point( 
            10112751459582654448673212608965195895414598487605456954769502289925743081826,
            6521773881692389686295792800963187993343676258982896416988759742696575081047
        );                                      
        
        vk.IC[23] = Pairing.G1Point( 
            1526739676497137289609387680645546194890220479239202807305518728310776583163,
            6812990006437970352215898652215713126545064936444643914058400195569928151638
        );                                      
        
        vk.IC[24] = Pairing.G1Point( 
            20247009922074264008442422937139082950583815445032127294571158123659423157584,
            5473341330178802574656129129583916886806991666604863804421920916196065822595
        );                                      
        
        vk.IC[25] = Pairing.G1Point( 
            6990312633491709907952726113448470586405773755541366958117831988939466461814,
            16060094062701894913765716268967962067535053744046238878329889358839593324301
        );                                      
        
        vk.IC[26] = Pairing.G1Point( 
            14660659478641016958588349176884642137055724035072217640325311181135958371865,
            5612068316048680066439458806321404983328349208900364658971527138372089930122
        );                                      
        
        vk.IC[27] = Pairing.G1Point( 
            11285678823821225372278386719877704737843625252995477917133626489952471512081,
            20231426108371811962675972762598980851850409415366108856582086640308424652611
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
