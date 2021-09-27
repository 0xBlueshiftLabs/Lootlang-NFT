 // SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

 
contract Gen {

    

    // MAPPINGS //    
    mapping(string => uint) internal charsMap; // maps characters to numbers for easier access in 'generateWord()' function
    mapping(uint => uint) internal tokenIdToSeed; // initial seed for each tokenId minted
    mapping(uint => uint[8]) internal tokenIdToShuffleShift; // tokenId => array of inexes for words to be shifted as a result of shuffling
    mapping(uint => uint) internal shuffleCount; // tokenId => number of shuffles tokenId has had
    mapping(address => bool) internal hasClaimed; // keeps track of addresses that have claimed a mint
    

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    
    
    // VARIABLES //
    
    
    uint16[297] ps = [
        1000, 1889, 2889, 3556, 5223, 6223, 7334, 8778, 9334, 9556, 10000,
        381, 952, 1428, 1809, 2761, 4856, 6094, 7523, 9523, 9809, 10000,
        198, 792, 1584, 2079, 2574, 3267, 3366, 5643, 7029, 9900, 10000,
        714, 1071, 1607, 2232, 2945, 4285, 5178, 6516, 7856, 9195, 10000,
        385, 1348, 3467, 5201, 6163, 7127, 9824, 9920, 9939, 9958, 10000,
        135, 405, 1081, 1216, 1892, 2703, 4325, 5541, 7568, 9730, 10000,
        2443, 2932, 3421, 3910, 4561, 5212, 6677, 8470, 9936, 9985, 10000,
        1239, 1770, 2655, 4071, 5310, 6726, 7257, 9912, 9947, 9982, 10000,
        268, 281, 294, 328, 1668, 4751, 7432, 9979, 9986, 9993, 10000,
        291, 679, 1164, 1649, 2329, 3106, 3689, 4951, 6504, 9708, 10000,
        353, 706, 1923, 3510, 5097, 7672, 8818, 9964, 9982, 9991, 10000, 
        755, 1227, 1416, 1605, 1888, 2077, 2171, 3114, 9246, 9812, 10000,
        695, 721, 747, 834, 851, 3023, 5195, 6846, 9974, 9991, 10000,
        103, 308, 513, 821, 1437, 2566, 3901, 7289, 9958, 9979, 10000,
        294, 588, 735, 750, 1337, 2071, 2805, 4127, 6183, 8239, 10000,
        88, 1148, 2561, 2738, 3975, 4682, 4859, 5389, 7156, 9983, 10000,
        325, 760, 1303, 1629, 1955, 3367, 4670, 6624, 8253, 9990, 10000,
        4955, 9910, 9920, 9930, 9940, 9950, 9960, 9970, 9980, 9990, 10000,
        214, 428, 641, 663, 1197, 1411, 1454, 2522, 3590, 4658, 10000,
        196, 784, 2548, 3332, 4312, 5488, 7644, 9800, 9996, 9998, 10000,
        475, 1424, 1661, 2848, 4272, 5933, 8544, 9256, 9968, 9992, 10000,
        515, 618, 1133, 1442, 2267, 3298, 4947, 6493, 7730, 9483, 10000,
        202, 1412, 3025, 5444, 7662, 9880, 9920, 9940, 9960, 9980, 10000,
        23, 252, 480, 2657, 2886, 4719, 7354, 9645, 9874, 9885, 10000,
        433, 866, 1732, 3464, 5195, 8659, 9525, 9698, 9871, 9958, 10000,
        601, 901, 1502, 2103, 3605, 4806, 6007, 9010, 9310, 9400, 10000,
        204, 511, 613, 714, 1737, 3782, 9917, 9968, 9978, 9988, 10000];
    


    string[] nextChars = [
        "fbrwsaltpzj",
        "gmldslrtnkb",
        "blriiluoaey",
        "rliktauhooe",
        "ruaoiiegfws",
        "mfteladsnrg",
        "luaarreioyw",
        "luiraohezgy",
        "urryoiaejlw",
        "gredlocstnb",
        "iieaaouuytf",
        "aollarsieut",
        "ussdyoaielf",
        "smmupioaeyn",
        "aauyiosetgd",
        "zolwtmfurny",
        "tupiilaores",
        "uuaeiosrfyw",
        "nudytslaioe",
        "puhaoietwyq",
        "usraieohhty",
        "ebgzplsntrm",
        "uoaieeyvxrl",
        "snnoheaiuyr",
        "oaueeityxth",
        "lmaiseeouvx",
        "uyooiaelzrl"];

    

    
    /**
     * @dev Maps characters in 'chars' to numbers for easier comparison in 'generateWord()' function
     */
    function mapChars() internal {
        string[27] memory chars = [" ", "a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"];
        for (uint i=0; i<27; i++) {
            charsMap[chars[i]] = i;
        }
    }

    
    /**
     * @dev Returns length of a string '_string'.
     */
    function stringLength(string memory _string) internal pure returns(uint) {
        return bytes(_string).length;
    }

    
    /**
     * @dev Gets character from 'nextChars'.
     */
    function getChar(uint row, uint col) internal view returns(string memory) {
        bytes memory line = bytes(nextChars[row]);
        string memory temp = new string(1);
        bytes memory output = bytes(temp);
        output[0] = line[col];
        return string(output); 
    }
    
    
    
    /**
     * @dev Generates word length (1-16) using a distribution
     */
    function determineWordLength(uint rand) internal pure returns(uint) {
        
        uint16[16] memory cumulativeDistribution = [2,99,761,1929,3175,4694,6291,7654,8744,9328,9678,9872,9938,9976,9991,10000];
        
        uint i = 0;
        while (i <= 15) { 
            if (rand <= cumulativeDistribution[i]) {
                break;
            }
            i++;
        }
        return i+1;  // returns word length
    }
    
    
    
    /**
     * @dev Generates a random word of length 1-16, given a '_tokenId' and '_totalSeed' as a seed of randomness
     */
    function generateWord(uint256 _tokenId, uint _totalSeed) internal view returns(string memory) { // change visibility

        require(_tokenId >= 1 && _tokenId <= 10000, "Invalid tokenId.");

        string memory word;
        string memory char;
        
        uint lengthRand = (uint(keccak256(abi.encodePacked(_tokenId, _totalSeed)))% 10000); // gets random number between 0 and 10,000
        uint rand = (uint(keccak256(abi.encodePacked(_tokenId, lengthRand, _totalSeed)))% 10000) + 1; // gets random number between 1 and 10,000

        // generates word
        for (uint n=1; n <= determineWordLength(lengthRand); n++) {
            
            // generates letter
            uint i = 0;
            while (i < 11) { // indexStart of ps[] to indexEnd
                if (rand <= ps[(charsMap[char]*11)+i]) {
                    break;
                }
                i++;
            }
            char = getChar(charsMap[char], i);
            
            word = string(abi.encodePacked(word, char)); // appends letter to word
            rand = (uint(keccak256(abi.encodePacked(_tokenId, rand, word, n, _totalSeed)))% 10000) + 1; // gets new random number between 1 and 10,000
        }
        return word;
    }
    
    
}
