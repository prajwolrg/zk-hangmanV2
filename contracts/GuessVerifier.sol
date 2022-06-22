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
pragma solidity ^0.6.11;
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
contract Verifier {
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
            [12682260658385296828419589821010671867868637844492532875812551197949828319030,
             11216682127583608555162082577849943470067747716948291796251552780191979385241],
            [17883810267160722716792200478319855607341712822540371679326227772605035685393,
             20348680612796422037930929403077234521837320448180428461103341372469068531230]
        );
        vk.IC = new Pairing.G1Point[](27);
        
        vk.IC[0] = Pairing.G1Point( 
            9994217275930800034848980247445496269078199133202446163222326297580510377327,
            7236570202661205087844458263731496429214360912773739914445316922399498662872
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            6578911905920611012255484264489519140644258304720916953906143218704096582270,
            18966964497779922097164728315439486277240571043529531560701891083372230319997
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            16269904043843156646713488736774721416421000170444628153106217942254438006679,
            16894751777824829234306207236404910910908775520304012999295638228351649001738
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            5119880301166229953248309716300681114952978600640962283819749253668640636425,
            21564221905733713697671664969548873434281100761558701526337880911440957002330
        );                                      
        
        vk.IC[4] = Pairing.G1Point( 
            11375345112982971533508062350875208878885068861966374443649745659571376759696,
            11526812970463089202357032880042794346662125638225435735551336843046960735756
        );                                      
        
        vk.IC[5] = Pairing.G1Point( 
            1937743886176833368569615296853051349849537339824110873901215820113083292569,
            10406577386454434674367115324221288890102446796191150945050454439557568806915
        );                                      
        
        vk.IC[6] = Pairing.G1Point( 
            16557259656784768555878877649327185731696883300933257439945834982557964341384,
            712938769859477549851449324642878999554077314399513336376809103392599409641
        );                                      
        
        vk.IC[7] = Pairing.G1Point( 
            17433143851062934020284801337816753754858017876654152928246283431295141163902,
            17229662973385808434521855392210610924281966153792115232253608606840997757969
        );                                      
        
        vk.IC[8] = Pairing.G1Point( 
            1722917205293091058258218868051223927100188050717584998195416257519820186172,
            11242411081971786725638564162326830151702005079484510002898773864628062943190
        );                                      
        
        vk.IC[9] = Pairing.G1Point( 
            19038501743999141549339209934952344419661038481412946112247592301272030025298,
            8819198638501456519461063389328727543155779707893508631277407488672315388851
        );                                      
        
        vk.IC[10] = Pairing.G1Point( 
            5913911390554938333138309798784436879299688407670847320384526013465055498875,
            16721520479177285180891494322078352986213535258946740953460007828528929221161
        );                                      
        
        vk.IC[11] = Pairing.G1Point( 
            9711463887673056848451600473930547279606802326045530341843807080092469966594,
            8896359889482645423681172147933983797542887664301313749834416389788894046707
        );                                      
        
        vk.IC[12] = Pairing.G1Point( 
            6740129538785267506082383371016160794329355794443740038597430568521108765887,
            14597931203037920312990713816952688372602951425957684378632588038495969676729
        );                                      
        
        vk.IC[13] = Pairing.G1Point( 
            20800917661277654233014412179107281169033988814791893706428032396372704904544,
            18249817448914889035054728846019187007780116148708661368644050217779157098914
        );                                      
        
        vk.IC[14] = Pairing.G1Point( 
            8639041431778812853526147603643645258884276576894829558348112095282821455748,
            318569309131477567862441520219184273099018363387706180718259577494959178180
        );                                      
        
        vk.IC[15] = Pairing.G1Point( 
            19758841996748791410890690793587695559030725522207894744758610287716152389292,
            16937239863827133551435833573550281531413929055669501998538581435962312015145
        );                                      
        
        vk.IC[16] = Pairing.G1Point( 
            5764933548099785067513839542306978039247121414195934487123543216429081631064,
            10613948754015362966206099747415331532912353230940153711985193853914889044278
        );                                      
        
        vk.IC[17] = Pairing.G1Point( 
            13740768016081094885766057984200785496090551306360977550924368136702277933543,
            10172715277817818074008859795681451396094215662546760053436581091360143940241
        );                                      
        
        vk.IC[18] = Pairing.G1Point( 
            11861473367268754749446117398526517293964566944860423820977522023234557642783,
            9667401872071672945322905974534115004686704925262210425472331763669433607429
        );                                      
        
        vk.IC[19] = Pairing.G1Point( 
            2262762133218367757706605443733437317351447980360941510631769639118266946609,
            15624454847109697570995998846022605359684974854389330691512949806331242079586
        );                                      
        
        vk.IC[20] = Pairing.G1Point( 
            1575051143479856978099018640035044401718580350811356421280082064578285968660,
            15130742695808094996051037207285732582463629113157154866744561203509715629808
        );                                      
        
        vk.IC[21] = Pairing.G1Point( 
            17271847209001463232369118950267179806495851107804944756536169744931706037838,
            17131263107667198538922599611216778738876410757320423923921320626340061070904
        );                                      
        
        vk.IC[22] = Pairing.G1Point( 
            8944628024461609684854723533681632078156165227403838425866770932316447907983,
            13566329721430843450771052248905504961956475528709826932051710291550753134445
        );                                      
        
        vk.IC[23] = Pairing.G1Point( 
            12692772368087640699876139730802169541901309645802133969617297320708237622176,
            8848754066748755813092224758790503730664111770996039048106369590095597529939
        );                                      
        
        vk.IC[24] = Pairing.G1Point( 
            1145389571210994509534058876598789894515684911643882176086000980315280103915,
            6085046700383568704618832421786415254842311687219996738698566697727894934409
        );                                      
        
        vk.IC[25] = Pairing.G1Point( 
            11325432552770463419941971269827608336282894528586641651702703989905028078447,
            1671767428495883078408144696456963679136557495442817474080498962208217230910
        );                                      
        
        vk.IC[26] = Pairing.G1Point( 
            1193935835022243680557674925255463109521014550723474221210153139194693655021,
            1330828390242708160019742503198520292558069567793058891350107986411727808260
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
