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
            [2789139649873816553597715631871398817735043682118852579864093063018108588182,
             14954851524019718838145146524448635606769220492872858096309143750386422201021],
            [10513342877891828602422766204251218864194428908074367781549568998507895479855,
             13991826713395554129491044496440740146282751491604585217126493360731826129342]
        );
        vk.IC = new Pairing.G1Point[](28);
        
        vk.IC[0] = Pairing.G1Point( 
            20035881738397154016100911527477643713444869968999189144297765285487877464880,
            11483806141415274601880233339927480542063103080717938226378026345965001692068
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            1522222112097893531768408568991666806019559699763121942320192055744339443649,
            18078017832780613709916823476595644051351281528407938094600353840823085854449
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            2991552112578872152083577770286760207605453199797977217468905588459430589149,
            1929375968412865740825521637094113471151909225264195880921643258302394566430
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            5578603338088496565144208031146267407725352538877608193720482780399888895034,
            17231923309842226899000765401875798471369719573525484772470688137034598799192
        );                                      
        
        vk.IC[4] = Pairing.G1Point( 
            17990530051282410427921439582322239538417014678700128619614591421434780876117,
            9765054215868117205346565315353707528724894318062021598591132827725615655856
        );                                      
        
        vk.IC[5] = Pairing.G1Point( 
            9257952241137232752532774374632972610951314683440612185389792771640400679296,
            12768700644854069745861757363981152689832750454468855216194650114767175157889
        );                                      
        
        vk.IC[6] = Pairing.G1Point( 
            17809523752092600236769010490194074195420133644955148892339838292068965713353,
            9077356856327915958926857437383133038415487828514150047061721745078085729184
        );                                      
        
        vk.IC[7] = Pairing.G1Point( 
            5021856595667185839866782936675315359109779621823491590323518452863428759506,
            5127965545900543229871836796114093072699144996611484220301328030849853200855
        );                                      
        
        vk.IC[8] = Pairing.G1Point( 
            1781843247337932369167790296898233925356807414500408241179299793470737350802,
            12910438857544273532175289455330822874679479025783257179902966157854131487768
        );                                      
        
        vk.IC[9] = Pairing.G1Point( 
            15168714382521667949322044717808890485945888175134365333168260357132958782705,
            393146583930489240455995695862336810017335998112182687693079662004715459839
        );                                      
        
        vk.IC[10] = Pairing.G1Point( 
            11529527674722492074031789307193361163546812779777881272345604778830089173799,
            7892179230464363427475419478379893828047988448493370071871036362586250087896
        );                                      
        
        vk.IC[11] = Pairing.G1Point( 
            19163165381228935369690894672522068084691318442071698442626357370169879267332,
            1285778415639344864640106408149026289567173097506265591204023498886042184066
        );                                      
        
        vk.IC[12] = Pairing.G1Point( 
            8737662509386940954424920793936702327703269373513092564585465079343826703839,
            19644104548983283156319523773877322941536483170144766349600742176809158512922
        );                                      
        
        vk.IC[13] = Pairing.G1Point( 
            9413181977406734155409201048506893538398898108186451467561335946860378828330,
            14674565837359950118910267453549909641109349551852828567982997851818728089413
        );                                      
        
        vk.IC[14] = Pairing.G1Point( 
            4350577617957266454729265230738725342259291054456844828151560607308069842997,
            10724666708234545679352779704405132995989751443338950439948342310396663826208
        );                                      
        
        vk.IC[15] = Pairing.G1Point( 
            16188292860428213453128911308165724267976766404545698855238170426640333721567,
            5839163400013595012064113810379765937477370578088280151850244829337906663799
        );                                      
        
        vk.IC[16] = Pairing.G1Point( 
            4486649376166785212603714958457417133899482781593264182594115104186756590218,
            12487064764302735714894745114743792286301802683430702844082026254733110133867
        );                                      
        
        vk.IC[17] = Pairing.G1Point( 
            8894229234281718521686713617230666887910413125967651025123041649825844569692,
            6671863136519037723195509476515231974138018458523332504452888556850138595267
        );                                      
        
        vk.IC[18] = Pairing.G1Point( 
            6478229153851671325074667358172010281383215074244145158926944317516946642138,
            11700976595354647259946628482399827209046719211515988376655016858961678771882
        );                                      
        
        vk.IC[19] = Pairing.G1Point( 
            18229881500927455815665197403026137237017004060894804213546704758756147737488,
            14847459080352117512018978894655946389222948204422300840584749893811250843555
        );                                      
        
        vk.IC[20] = Pairing.G1Point( 
            6285833818347347228229460106641391678042682942503089202048884739950798120494,
            12098603036829834435429290129796164857619034744378307373603844955006160626214
        );                                      
        
        vk.IC[21] = Pairing.G1Point( 
            5378395248893578175857483587157648061697807657391318401387096681498036275933,
            4507037881631055042634054085878675155196297667077527058199382668294356832182
        );                                      
        
        vk.IC[22] = Pairing.G1Point( 
            14692436021228389188176384608508765586746118272467999077910397370034493925219,
            12574930182269055987779759050241391523725916707150019323454915541603858997647
        );                                      
        
        vk.IC[23] = Pairing.G1Point( 
            20574815488612445372716903287021095293029386257276599282472118973074240405659,
            1151768302771069900184049781010856062768443395543076333802584028365154209222
        );                                      
        
        vk.IC[24] = Pairing.G1Point( 
            2611004026952581307796526228801458579940917927215834475729645939930496386319,
            7563299795518705100161123854702123551722429755408697826498231612297770764408
        );                                      
        
        vk.IC[25] = Pairing.G1Point( 
            7239510780297899981170107960278378072342890528166632257572052122192237724664,
            14971793193813001308322571715351392075757924442890069063963016690095007555037
        );                                      
        
        vk.IC[26] = Pairing.G1Point( 
            18241734258173817435415438493006155849172326689480295015461437305038651670720,
            7256126062210833479395746120148032956691048788594019436159314277692542758413
        );                                      
        
        vk.IC[27] = Pairing.G1Point( 
            19042968899527391997062440676467594259278964555224164544321475338593132185956,
            4678803372408356054946223735000858498457699070301314818413598147381777149328
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
