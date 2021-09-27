// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;



// IMPORTS //

/**
 * @dev ERC721 token standard
 */
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @dev Modifier 'onlyOwner' becomes available where owner is the contract deployer
 */
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Verification of Merkle trees
 */
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @dev Generates words etc
 */
import "./Gen.sol";


// LIBRARIES //

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}





//  CONTRACT //  

contract Lootlang is ERC721, Ownable, Gen {
    
    
    // VARIABLES //
    
    uint public enabled;
    uint internal mints; 
    uint internal claims; 
    uint internal nextTokenId;
    uint public contractBalance;
    string internal contractURIstring;
    uint public freezeBlock;
    uint internal freezeBlockChanges;
    bytes32 internal root;

    
    constructor() Ownable() ERC721('Lootlang', 'LANG') {

        nextTokenId = 1;
        
        freezeBlock = 13487654;
        
        contractURIstring = "https://lootlang.com/metadata.json";
        
        mapChars(); // maps characters to uints
        
    }


    // EVENTS //
    
    event Shuffled(uint tokenId);



    // ONLY OWNER FUNCTIONS //
    
    /**
     * @dev Set the root for Merkle Proof
     */
    function setRoot(bytes32 _newRoot) external onlyOwner {
        root = _newRoot;
    }
    
    
    /**
     * @dev Set the new block number to freeze shuffling. Can only be called once.
     */
    function setFreezeBlock(uint _newFreezeBlockNumber) external onlyOwner {
        require(freezeBlockChanges < 1, "Freeze block already changed");
        freezeBlock = _newFreezeBlockNumber;
        freezeBlockChanges++;
    }
    

    /**
     * @dev Withdraw '_amount' of Ether to address '_to'. Only contract owner can call.
     * @param _to - address Ether will be sent to
     * @param _amount - amount of Ether, in Wei, to be withdrawn
     */
    function withdrawFunds(address payable _to, uint _amount) external onlyOwner {
        require(_amount <= contractBalance, "Withdrawal amount greater than balance");
        contractBalance -= _amount;
        _to.transfer(_amount);
    }


    /**
     * @dev activates/deactivates the minting functionality - only the contract owner can call
     * @param _enabled where 1 = enabled and 0 = not
     */
    function setEnable(uint _enabled) external onlyOwner {
        enabled = _enabled;
    }
    
    
    /**
     * @dev Set the contract's URI
     * @param _contractURIstring - web address containing data read by OpenSea
     */
    function setContractURI(string memory _contractURIstring) external onlyOwner {
        contractURIstring = _contractURIstring;
    }
    

    // USER FUNCTIONS // 
    

    /**
     * @dev Mint an ERC721 token. 
     */
    function mint() external payable {
        require(enabled == 1, "Minting is yet to be enabled");
        require(nextTokenId <= 10000 && mints <= 9700, "All NFTs have been minted");
        require(msg.value >= (2*10**16), "Insufficient funds provided"); // 0.02 eth (cost of minting an NFT) // SET MINT PRICE

        mints++;
        contractBalance += msg.value;
        sharedMintCode();
    }
    
    /**
     * @dev Claim and mint an ERC721 token.
     */
    function claim(bytes32[] memory proof) external { 
        require(enabled == 1, "Minting is yet to be enabled");
        require(hasClaimed[msg.sender] == false, "Already claimed");
        require(nextTokenId <= 10000 && claims <= 300, "All NFTs have been minted");

        require(MerkleProof.verify(proof, root, keccak256(abi.encodePacked(msg.sender))) == true, "Not on pre-approved claim list");

        claims++;
        hasClaimed[msg.sender] = true;
        sharedMintCode();
    }
    
    /**
     * @dev Shared code used by both 'mint()' and 'claim()' functions.
     */
    function sharedMintCode() internal {
        uint tokenId = nextTokenId;
        nextTokenId++;
        tokenIdToSeed[tokenId] = uint(keccak256(abi.encodePacked(tokenId, msg.sender, block.timestamp)))%1000000;
        _safeMint(msg.sender, tokenId);
    }


    /**
     * @dev Shuffles up to 8 words. Set input params as 1 to shuffle word, and 0 to leave it. 
     *      E.g. shuffle(243,1,0,0,0,0,0,0,1) shuffles the 1st and 8th word of token 243.
     */
    function shuffle(uint _tokenId, uint one, uint two, uint three, uint four, uint five, uint six, uint seven, uint eight) external {
        require(ownerOf(_tokenId) == msg.sender, "Must be NFT owner");
        require(shuffleCount[_tokenId] < 5, "Shuffled max amount already");
        require(block.number < freezeBlock, "Shuffling has been frozen!");
        require((one+two+three+four+five+six+seven+eight) > 0, "No words selected to be shuffled"); 
       
        uint randomish = uint(keccak256(abi.encodePacked(block.number)))%1000000;
        uint[8] memory indexesToChange = [one, two, three, four, five, six, seven, eight];
        
        for (uint i=0; i<8; i++) {
            if (indexesToChange[i] > 0) {
                tokenIdToShuffleShift[_tokenId][i] += randomish;
            }
        }
        
        shuffleCount[_tokenId]++;
        emit Shuffled(_tokenId);
    }
    



    // VIEW FUNCTIONS //
    
    
    /**
     * @dev View total number of minted tokens
     */
    function totalSupply() external view returns(uint) {
        return mints+claims;
    }
    
    /**
     * @dev View the contract URI.
     */
    function contractURI() public view returns (string memory) {
        return contractURIstring;
    }

    /**
     * @dev Internal function used by function 'tokenURI()' to format word lengths for .json file output
     */
    function getMetaText(string memory word) internal pure returns(string memory) {
        string memory length = string(abi.encodePacked("\"", toString(stringLength(word)), " letters", "\""));
        return length;
    }
    
    /**
     * @dev Internal function used by function 'tokenURI()' to format words for .json file output
     */
    function getMetaWord(string memory word) internal pure returns(string memory) {
        string memory length = string(abi.encodePacked("\"", word, "\""));
        return length;
    }
    
    /**
     * @dev Creates seed passed in to 'generateWord()' function for seeding randomness
     */
    function totalSeedGen(uint tokenId, uint wordNum) internal view returns(uint) {
        return uint(keccak256(abi.encodePacked(uint(wordNum), tokenIdToSeed[tokenId], tokenIdToShuffleShift[tokenId][wordNum-1])));
    }
    
    /**
     * @dev View tokenURI of 'tokenId'. 
     */
    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        
        require(_exists(tokenId), "URI query for nonexistent token");

        string[17] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 20px; }</style><rect width="100%" height="100%" fill="black" /><text x="15" y="30" class="base">';
        parts[1] = generateWord(tokenId, totalSeedGen(tokenId, 1));
        parts[2] = '</text><text x="15" y="65" class="base">';
        parts[3] = generateWord(tokenId, totalSeedGen(tokenId, 2));
        parts[4] = '</text><text x="15" y="100" class="base">';
        parts[5] = generateWord(tokenId, totalSeedGen(tokenId, 3));
        parts[6] = '</text><text x="15" y="135" class="base">';
        parts[7] = generateWord(tokenId, totalSeedGen(tokenId, 4));
        parts[8] = '</text><text x="15" y="170" class="base">';
        parts[9] = generateWord(tokenId, totalSeedGen(tokenId, 5));
        parts[10] = '</text><text x="15" y="205" class="base">';
        parts[11] = generateWord(tokenId, totalSeedGen(tokenId, 6));
        parts[12] = '</text><text x="15" y="240" class="base">';
        parts[13] = generateWord(tokenId, totalSeedGen(tokenId, 7));
        parts[14] = '</text><text x="15" y="275" class="base">';
        parts[15] = generateWord(tokenId, totalSeedGen(tokenId, 8));
        parts[16] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));
        
        string memory json = string(abi.encodePacked('{"name": "Pack #', toString(tokenId), '", "description": "Pack of 8 Lootlang words", "attributes": [{"trait_type": "Shuffles Used", "value":', getMetaWord(toString(shuffleCount[tokenId])), '}, {"trait_type": "Word Length", "value":', getMetaText(parts[1]), '}, {"trait_type": "Word Length", "value":', getMetaText(parts[3]), '}, {"trait_type": "Word Length", "value":', getMetaText(parts[5]), '}, {"trait_type": "Word Length", "value":', getMetaText(parts[7]), '}, {"trait_type": "Word Length", "value":', getMetaText(parts[9]), '}, {"trait_type": "Word Length", "value":', getMetaText(parts[11]), '}, {"trait_type": "Word Length", "value":', getMetaText(parts[13]), '}, {"trait_type": "Word Length", "value":', getMetaText(parts[15]), '}'));
        json = Base64.encode(bytes(string(abi.encodePacked(json, ', {"trait_type": "Word", "value":', getMetaWord(parts[1]), '}, {"trait_type": "Word", "value":', getMetaWord(parts[3]), '}, {"trait_type": "Word", "value":', getMetaWord(parts[5]), '}, {"trait_type": "Word", "value":', getMetaWord(parts[7]), '}, {"trait_type": "Word", "value":', getMetaWord(parts[9]), '}, {"trait_type": "Word", "value":', getMetaWord(parts[11]), '}, {"trait_type": "Word", "value":', getMetaWord(parts[13]), '}, {"trait_type": "Word", "value":', getMetaWord(parts[15]), '}], "image": "data:image/svg+xml;base64, ', Base64.encode(bytes(output)), '"}'))));
        
        output = string(abi.encodePacked('data:application/json;base64,', json));
        return output;
    }
    

}
