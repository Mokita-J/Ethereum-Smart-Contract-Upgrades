// ////-License-Identifier: MIT

pragma solidity 0.8.7;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
contract Proxy {

    address implementation_;
    address public admin;

    constructor(address impl) {
        implementation_ = impl;
        admin = msg.sender;
    }

    function setImplementation(address newImpl) public {
        require(msg.sender == admin);
        implementation_ = newImpl;
    }

    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view returns (address) {
        return implementation_;
    }

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }
}

// : Unlicense
pragma solidity 0.8.7;

contract InventoryManager {

    address impl_;
    address public manager;

    enum Part { body, helm, mainhand, offhand, unique }

    mapping(uint8 => address) public bodies;
    mapping(uint8 => address) public helms;
    mapping(uint8 => address) public mainhands;
    mapping(uint8 => address) public offhands;
    mapping(uint8 => address) public uniques;


    string public constant header = '<svg id="orc" width="100%" height="100%" version="1.1" viewBox="0 0 60 60" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">';
    string public constant footer = '<style>#orc{shape-rendering: crispedges; image-rendering: -webkit-crisp-edges; image-rendering: -moz-crisp-edges; image-rendering: crisp-edges; image-rendering: pixelated; -ms-interpolation-mode: nearest-neighbor;}</style></svg>';

    function getSVG(uint8 body_, uint8 helm_, uint8 mainhand_, uint8 offhand_) public view returns(string memory) {

        // it's a unique!
        if (helm_ > 40) return string(abi.encodePacked(header, get(Part.unique, body_), footer));

        return string(abi.encodePacked(
            header,
            get(Part.body, body_), 
            helm_     > 4 ? get(Part.helm, helm_)         : "",
            mainhand_ > 0 ? get(Part.mainhand, mainhand_) : "",
            offhand_  > 4 ? get(Part.offhand, offhand_)   : "",
            footer ));
    }


    constructor() { manager = msg.sender;}


    function getTokenURI(uint16 id_, uint8 body_, uint8 helm_, uint8 mainhand_, uint8 offhand_, uint16 level_, uint16 zugModifier_) public view returns (string memory) {

        string memory svg = Base64.encode(bytes(getSVG(body_,helm_,mainhand_,offhand_)));

        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"Orc #',toString(id_),'", "description":"EtherOrcs is a collection of 5050 Orcs ready to pillage the blockchain. With no IPFS or API, these Orcs are the very first role-playing game that takes place 100% on-chain. Spawn new Orcs, battle your Orc to level up, and pillage different loot pools to get new weapons and gear which upgrades your Orc metadata. This Horde of Orcs will stand the test of time and live on the blockchain for eternity.", "image": "',
                                'data:image/svg+xml;base64,',
                                svg,
                                '",',
                                getAttributes(body_, helm_, mainhand_, offhand_, level_, zugModifier_),
                                '}'
                            )
                        )
                    )
                )
            );
    }
    
    /*///////////////////////////////////////////////////////////////
                    INVENTORY MANAGEMENT
    //////////////////////////////////////////////////////////////*/


    function setBodies(uint8[] calldata ids, address source) external {
        require(msg.sender == manager, "not manager");

        for (uint256 index = 0; index < ids.length; index++) {
            bodies[ids[index]] = source; 
        }
    }

     function setHelms(uint8[] calldata ids, address source) external {
        require(msg.sender == manager, "not manager");

        for (uint256 index = 0; index < ids.length; index++) {
            helms[ids[index]] = source; 
        }
    }

    function setMainhands(uint8[] calldata ids, address source) external {
        require(msg.sender == manager, "not manager");

        for (uint256 index = 0; index < ids.length; index++) {
            mainhands[ids[index]] = source; 
        }
    }

    function setOffhands(uint8[] calldata ids, address source) external {
        require(msg.sender == manager, "not manager");

        for (uint256 index = 0; index < ids.length; index++) {
            offhands[ids[index]] = source; 
        }
    }

    function setUniques(uint8[] calldata ids, address source) external {
        require(msg.sender == manager, "not manager");

        for (uint256 index = 0; index < ids.length; index++) {
            uniques[ids[index]] = source; 
        }
    }

    /*///////////////////////////////////////////////////////////////
                    INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function call(address source, bytes memory sig) internal view returns (string memory svg) {
        (bool succ, bytes memory ret)  = source.staticcall(sig);
        require(succ, "failed to get data");
        svg = abi.decode(ret, (string));
    }

    function get(Part part, uint8 id) internal view returns (string memory data_) {
        address source = 
            part == Part.body     ? bodies[id]    :
            part == Part.helm     ? helms[id]     :
            part == Part.mainhand ? mainhands[id] :
            part == Part.offhand  ? offhands[id]  : uniques[id];

        data_ = wrapTag(call(source, getData(part, id)));
    }
    
    function wrapTag(string memory uri) internal pure returns (string memory) {
        return string(abi.encodePacked('<image x="1" y="1" width="60" height="60" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,', uri, '"/>'));
    }

    function getData(Part part, uint8 id) internal pure returns (bytes memory data) {
        string memory s = string(abi.encodePacked(
            part == Part.body     ? "body"     :
            part == Part.helm     ? "helm"     :
            part == Part.mainhand ? "mainhand" :
            part == Part.offhand  ? "offhand"  : "unique",
            toString(id),
            "()"
        ));
        
        return abi.encodeWithSignature(s, "");
    }

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

    function getAttributes(uint8 body_, uint8 helm_, uint8 mainhand_, uint8 offhand_, uint16 level_, uint16 zugModifier_) internal pure returns (string memory) {
       return string(abi.encodePacked(
           '"attributes": [',
            getBodyAttributes(body_),         ',',
            getHelmAttributes(helm_),         ',',
            getMainhandAttributes(mainhand_), ',',
            getOffhandAttributes(offhand_), 
            ',{"trait_type": "level", "value":', toString(level_),
            '},{"display_type": "boost_number","trait_type": "zug bonus", "value":', 
            toString(zugModifier_),'}]'));
    }

    function getBodyAttributes(uint8 body_) internal pure returns(string memory) {
        return string(abi.encodePacked('{"trait_type":"Body","value":"',getBodyName(body_),'"}'));
    }

    function getHelmAttributes(uint8 helm_) internal pure returns(string memory) {
        return string(abi.encodePacked('{"trait_type":"Helm","value":"',getHelmName(helm_),'"},{"display_type":"number","trait_type":"HelmTier","value":',toString(getTier(helm_)),'}'));
    }

    function getMainhandAttributes(uint8 mainhand_) internal pure returns(string memory) {
        return string(abi.encodePacked('{"trait_type":"Mainhand","value":"',getMainhandName(mainhand_),'"},{"display_type":"number","trait_type":"MainhandTier","value":',toString(getTier(mainhand_)),'}'));
    }

    function getOffhandAttributes(uint8 offhand_) internal pure returns(string memory) {
        return string(abi.encodePacked('{"trait_type":"Offhand","value":"',getOffhandName(offhand_),'"},{"display_type":"number","trait_type":"OffhandTier","value":',toString(getTier(offhand_)),'}'));
    }

    function getTier(uint16 id) internal pure returns (uint16) {
        if (id > 40) return 100;
        if (id == 0) return 0;
        return ((id - 1) / 4 );
    }

    // Here, we do sort of a Binary Search to find the correct name. Not the pritiest code I've wrote, but hey, it works!

    function getBodyName(uint8 id) public pure returns (string memory) {
        if (id > 40) return getUniqueName(id);
        if (id < 20) {
            if ( id < 10) {
                if (id < 5) {
                    if (id < 3) {
                        return id == 1 ? "Green Orc 1" : "Green Orc 2";
                    }
                    return id == 3 ? "Green Orc 3" : "Dark Green Orc 1";
                }
                if (id < 7) return id == 5 ? "Dark Green Orc 2" : "Dark Green Orc 3"; 
                return id == 7 ? "Red Orc 1" : id == 8 ? "Red Orc 2" : "Red Orc 3";
            }
            if (id <= 15) {
                if (id < 13) {
                    return id == 10 ? "Blood Red Orc 1" : id == 11 ? "Blood Red Orc 2" : "Blood Red Orc 3";
                }
                return id == 13 ? "Clay Orc 1" : id == 14 ? "Clay Orc 2" : "Clay Orc 3";
            }
            if (id < 18) return id == 16 ? "Dark Clay Orc 1" : "Dark Clay Orc 2";
            return id == 18 ? "Dark Clay Orc 3" :  "Blue Orc 1";
        }

        if ( id < 30) {
            if (id < 25) {
                if (id < 23) {
                    return id == 20 ? "Blue Orc 2" : id == 21 ? "Blue Orc 3" : "Midnight Blue Orc 1";
                }
                return id == 23 ? "Midnight Blue Orc 2" : "Midnight Blue Orc 3";
            }

            if (id < 27) return id == 25 ? "Albino Orc 1" : "Albino Orc 2"; 
            return "Albino Orc 3";
        }
    }

    function getHelmName(uint8 id) public pure returns (string memory) {
        if (id > 40) return getUniqueName(id);
        if (id < 20) {
            if ( id < 10) {
                if (id < 5) {
                    if (id < 3) {
                        return id == 1 ? "None" : "None";
                    }
                    return id == 3 ? "None" : "None";
                }
                if (id < 7) return id == 5 ? "Leather Helm +1" : "Orcish Helm +1"; 
                return id == 7 ? "Leather Cap +1" : id == 8 ? "Iron Helm +1" : "Bone Helm +2";
            }
            if (id <= 15) {
                if (id < 13) {
                    return id == 10 ? "Full Orc Helm +2" : id == 11 ? "Chainmail Cap +2" : "Strange Helm +2";
                }
                return id == 13 ? "Full Plate Helm +3" : id == 14 ? "Chainmail Coif +3" : "Boar Head +3";
            }
            if (id < 18) return id == 16 ? "Orb of Protection +3" : "Royal Thingy +4";
            return id == 18 ? "Dark Iron Helm +4" :  "Cursed Hood +4";
        }

        if ( id < 30) {
            if (id < 25) {
                if (id < 23) {
                    return id == 20 ? "Red Bandana +4" : id == 21 ? "Thorned Helm +5" : "Demon Skull +5";
                }
                return id == 23 ? "Treasure Chest +5" : "Cursed Hood +5";
            }

            if (id < 27) return id == 25 ? "Blue Knight Helm +6" : "Parasite +6"; 
            return id == 27 ? "Dragon Eyes +6" : id == 28 ? "Horned Cape +6" : "Nether Blindfold +7";
        }
        if (id <= 35) {
            if (id < 33) {
                return id == 30 ? "Lightning Crown +7" : id == 31 ? "Master Warlock Cape +7" : "Red Knight Helm +7";
            }
            return id == 33 ? "Beholder Head +8" : id == 34 ? "Ice Crown +8" : "Band of the Dark Lord +8";
        }
        if (id < 38) return id == 36 ? "Helm of Evil +8" : "Blazing Horns +9";
        return id == 38 ? "Possessed Helm +9" : id == 39 ? "Molten Crown +9" : "Helix Helm +9";
    }

    function getMainhandName(uint8 id) public pure returns (string memory) {
        if (id > 40) return getUniqueName(id);
        if (id < 20) {
            if ( id < 10) {
                if (id < 5) {
                    if (id < 3) {
                        return id == 1 ? "Pickaxe" : "Torch";
                    }
                return id == 3 ? "Club" : "Pleb Staff";
            }
                if (id < 7) return id == 5 ? "Short Sword +1" : "Dagger +1"; 
                return id == 7 ? "Simple Axe +1" : id == 8 ? "Fiery Poker +1" : "Large Axe +2";
            }
            if (id <= 15) {
                if (id < 13) {
                    return id == 10 ? "Iron Hammer +2" : id == 11 ? "Iron Mace +2" : "Jagged Axe +2";
                }
                return id == 13 ? "Enchanted Poker +3" : id == 14 ? "Curved Sword +3" : "Ultra Mallet +3";
            }
            if (id < 18) return id == 16 ? "Disciple Staff +3" : "Assassin Blade +4";
            return id == 18 ? "Swamp Staff +4" :  "Simple Wand +4";
        }

        if ( id < 30) {
            if (id < 25) {
                if (id < 23) {
                    return id == 20 ? "Royal Blade +4" : id == 21 ? "Skull Shield +5" : "Skull Crusher Axe +5";
                }
                return id == 23 ? "Flaming Staff +5" : "Flaming Royal Blade +5";
            }

            if (id < 27) return id == 25 ? "Berserker Sword +6" : "Necromancer Staff +6"; 
            return id == 27 ? "Flaming Skull Shield +6" : id == 28 ? "Frozen Scythe +6" : "Blood Sword +7";
        }
        if (id <= 35) {
            if (id < 33) {
                return id == 30 ? "Dark Lord Staff +7" : id == 31 ? "Bow of Artemis +7" : "Ice Sword +7";
            }
            return id == 33 ? "Cryptic Staff +8" : id == 34 ? "Nether Lance +8" : "Demonic Axe +8";
        }
        if (id < 38) return id == 36 ? "Old Moon Sword +8" : "Lightning Lance +9";
        return id == 38 ? "Molten Hammer +9" : id == 39 ? "Possessed Great Staff +9" : "Helix Lance +9";
    }

    function getOffhandName(uint8 id) public pure returns (string memory) {
        if (id > 40) return getUniqueName(id);
        if (id < 20) {
            if ( id < 10) {
                if (id < 5) {
                    if (id < 3) {
                        return id == 1 ? "None" : "None";
                    }
                    return id == 3 ? "None" : "None";
                }
                if (id < 7) return id == 5 ? "Wooden Shield +1" : "Paper Hands Shield +1"; 
                return id == 7 ? "Dagger +1" : id == 8 ? "Pirate Hook +1" : "Offhand Axe +2";
            }
            if (id <= 15) {
                if (id < 13) {
                    return id == 10 ? "Offhand Slasher +2" : id == 11 ? "Large Shield +2" : "Bomb +2";
                }
                return id == 13 ? "Offhand Poker +3" : id == 14 ? "Reinforced Shield +3" : "War Banner +3";
            }
            if (id < 18) return id == 16 ? "Hand Cannon +3" : "Metal Kite Shield +4";
            return id == 18 ? "Crossbow +4" :  "Cursed Skull +4";
        }

        if ( id < 30) {
            if (id < 25) {
                if (id < 23) {
                    return id == 20 ? "Spiked Shield +4" : id == 21 ? "Cursed Totem +5" : "Grimoire +5";
                }
                return id == 23 ? "Offhand Glaive +5" : "Frost Side Sword +5";
            }

            if (id < 27) return id == 25 ? "Magic Shield +6" : "Enchanted Glaive +6"; 
            return id == 27 ? "Burning Wand +6" : id == 28 ? "Burning Shield +6" : "Burning Blade +7";
        }
        if (id <= 35) {
            if (id < 33) {
                return id == 30 ? "Holy Scepter +7" : id == 31 ? "Possessed Skull +7" : "Demonic Grimoire +7";
            }
            return id == 33 ? "Scepter of Frost +8" : id == 34 ? "Demonic Scythe +8" : "Lightning Armband of Power +8";
        }
        if (id < 38) return id == 36 ? "Ice Staff +8" : "Nether Shield +9";
        return id == 38 ? "Molten Scimitar +9" : id == 39 ? "Staff of the Dark Lord +9" : "Helix Scepter +9";
    }

    function getUniqueName(uint8 id) internal pure returns (string memory) {
        if(id < 47) {
            if(id < 44) {
                return id == 41 ? "Cthulhu" : id == 42 ? "Vorgak The War Chief" : "Gromlock The Destroyer";
            } 
            return id == 44 ? "Yuckha The Hero" : id == 45 ? "Orgug The Master Warlock" : "Hoknuk The Demon Tamer";
        }
        if (id < 50) {
            return id == 47 ? "Lava Man" : id == 48 ? "hagra the Zombie" : "Morzul The Ice Warrior";
        }
        return id == 50 ? "T4000 The MechaOrc" : id == 51 ? "Slime Orc The Forgotten" : "Mouse God";
    }
}

/// @title Base64
/// @author Brecht Devos - <brecht@loopring.org>
/// @notice Provides a function for encoding some bytes in base64
/// @notice NOT BUILT BY ETHERORCS TEAM. Thanks Bretch Devos!
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

// : GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Bodies1 {

string public constant body1 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAKlBMVEUAAAAMDA0HBRElTUoycE1DGitDjEZSITNsLzKCqFmGQjzRtpj78Nr////3F57UAAAAAnRSTlMAAHaTzTgAAAJ0SURBVHhe7dQ/btswFAbwJCeIeAJTIux21WOVoRvfA1EPvYRFPEDo5haVD1DAQudCAIEeIPABMmUOUKBrx96lj7IU/0v3Dv04ePjx8aMNg1f/aP4nG5JLdDbmgtVm23Xrv/Ji93XXbfUZX4vsh+93uzR+ybfyedN1u3vhqev2+oQXX97d+7B5kW/y/JVn38TQyvUvmdhwjLHnzzGuLg8vbA1NrIEj2tklG3j/q+I3v/saXC45YZXnuIzMTezBFtbHPj9iZQjMj9jIeiJniWMM+sAFByx/Rsn3J1f4INy7Z1aWCeHxgZkfH9BzSCVhdmASftvI9AdGZvIsOTAQAdheZiIHIhD3XE5c0MDDz+KF0aYCN7FJZwN44eCF0IZTtlQxEnMglE2h5CNWFoiq2GPqEO0Ts0c9sgyTbcQhKTOWnploYhQGLx449iwVpZEamu25ACBnWFKLJdaK6JhBqwToB0Vtmn7iG4tQZkqEwA7usrlcEEcmH1yWzRnT4V5ay+y1sLuamElnCoEDMwChHricmJhynRXWB+m9a1utGuHZxBLvVNsNadt1qo48sfWE1aq42yTdth8xj5Iw8rXxXFtn4a6VfKorXvY+9qvbI4aSALfCVRD+tpSLT1wQByzIovRuPMtKrCdWnsiZmrDbtJ1vAoeqieGIuS7nQbhru3nTc5gzr7JnthzcnjdbI8xm2R84vSnaMJXyzdbKR+aq6d2BUwyhXqSnwzCTk/2nXBCUarPOhn+1k4EzBiizhRa2L7FKrMaa8pxVnng8xwZ9xgYtgh7YBMvlKSuLNLLywu6M6cAcgFfnDAQTI/iRp6g8Zc95ynj1PzvXIzG9J6eDAAAAAElFTkSuQmCC';
string public constant body10 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAJ1BMVEUAAAAMDA0HBREWGisuOko3CDs9VF9XE0GBJUOuN0bRtpj78Nr///+uf4lfAAAAAnRSTlMAAHaTzTgAAAJxSURBVHhe7dRPjtMwFAbwmTnBxCeoUyKXbVME+0aw9+jJEetRD2Dx9FyJVaXKL1yAWFxgpLnAIHasORTPmYT+G/Ys+LJIlJ/tz4miXP2j+Z9iSCnRxZgLVqt10yz/yvPN+02z1md8nWmYfL/Z5OmXfCvnm6bZ3AtPXbfXJzz/8Ok+xNWLfFOWrwKHLsVatn/JxIZTSj2/S2l3uXjl9tClPXBCN7tkA59/tmx/9XvwpeSEVVniNjF3qQdXuZD68oiVITDfUyfHE3lHnFLUB644ov2RJN+efBWicO//sHJMCI8PzPz4gIFjLomzA5Pwx05mf2FkpsCSAwMRgOtlTuIo1+KB7cQVDTy8liCMLhf4iU1eGyAIxyCELp6yo5aRmCOhDIqWj1g56W5Tj7lDtM/MAfXI5IhcJz4UMKMNzEQTozAE8cipZ6mwRmpo9swVAHnDkr1YZq2Ijhm0yoBhUNSm6ye+cQi2UCIEbnBfLGSDODKF6ItiwZgXD9Jqi9fC/mpiJl0oBI7MAIR6YDsxMZW6qFyI0ntX11p1wrOJJcGruhlS18tcnXhiFwjbXXW3yrqu32CZJHHkaxN477yDu1rydt/ytg+p390eMVgCXAu3UfjrVjY+cUUcsSKH0rsKLEdmPbEKRN7sCZtV3YQucmy7FI+Y93YRhZu6WXQ9xwXzrvjDjqN/5tXaCLPZ9gfO/xRtmKw82VKFxNx2vT9wjiHU8/zrMMzkZfwpVwRWrZbF8FV7uXHGALaYa2H3EqvMaqyx56zKzOM6LuozNugQ9MAmOranrBzSyCoI+zOmA3ME3p0zEEyMEEaeosqcgZ8vx63/BonNWyIQPbgXAAAAAElFTkSuQmCC';
string public constant body11 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAJ1BMVEUAAAAMDA0HBREWGisuOko3CDs9VF9XE0GBJUOuN0bRtpj78Nr///+uf4lfAAAAAnRSTlMAAHaTzTgAAAJnSURBVHhe7dQ/jtQwFAbwhRNsfILNLJGHdjMI+omgz+rJI+rVHMDi6XkpR4r8hQsQi44KwQUW0dFxK57DZP4uPQVfGks/Pz/nny/+0fxPMWamKYttztgslk1z81e+Xr9eN8vyhJ9kGovv1utd+Tk3zfpuz8XlMV+/eXcX4uJRNrPZs4DQp1jr9s9ZYJFSGvAqpc0ZX1auoz51hMTu6pwtvf+8Qvt16MjPNEesrfn+J7D5NZCrXEjD7ICNFbLfU6/Xg3gnSCmWe64QmX4kzacHX4WoPPgdGwdh+vYFwLcvHBDRpyFe7VmU3/Za/QEMSIBmzyRC5AatSYg6Vg9oJ65k5PGxBGV2uYGf2Oa1iYJyDErs4jE7WYEFiMI6KbY4YONIZJUGzj1Uh8wIfLVlLRbXq1NWgNsAiEzMyhTUI9IAILYWcccVkXgLTYcxsTQih0ylycBhVC5tP0z81DG1hVERcqP7Yq4b5C1LiL4o5mB0QECUtniu7C8mhpSFYUIEiITLkduJBaI/T+VCROTbui5Nr3w1sSZ4Uzdj6vomt06Y2AXh1aa6XWRd1i94ljS7920DOucd3daal90K90NIw+bygKkV4qXyKip/vD/4mCpB5Eoca99FgF6Zy4lNEPG2E24WdRP6iLjqUzxgdO08Kjd1M+8HxDmwKXbsEP0fXiytMuz9sOd8ppQW0uqd3ZiQgFU/+D3nWOHyOh8dFhCv84+5EmpN/vcNiXgtOGGitrguld1jbDKbbZv2/PDIvF3HxfKELTumcmQbHdpjNo5lyyYo+xOWPSMSNqdMQhMzhS1PMbOckf8Mt/wbNGNcM08aRf4AAAAASUVORK5CYII=';
string public constant body12 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAJFBMVEUAAAAMDA0XFCUHBREWGisuOko3CDtXE0GBJUOuN0bRtpj78NpMomIeAAAAA3RSTlMAAAD6dsTeAAACP0lEQVR4Xu3TTW7bMBQEYBc+gaCLSFUgKuvI7QXsEzB49F4AH7M2YI7aZRehjlD0Bs3lOlSs+CfNBYqONwI+kCNaj6t/N/+zbpjqFj4VRTFzNzGHj3g9Zn6uPmAuZtLn1yXXzN77mTHwBd6zopsVYP87XrWu3U9JBJN31Xs2cmhxtF2KMjTMFbPaHzrgxz0XNy5Mqbng0qiYMU1pfjen7I/VmVtELyON8W2I5DS8cemgXl4AfH+ZYkDEOKVYnVnJv7g0/U5HQAOYM4uqyDfQf8LzmR5gF241857lSDHv5HLBsLDJe4uQU8zkXbxmp3uoA6JK4KEsLrh07OY/ytZZU2YEX51Y2edGumQFvA2A6sKeLIEeMSUA0RrEN25FdDBgjrTM1Vr1kqVaZ/BhVl+ZMS28dl7sak1RcbMPebCSP7GGyEN08HnzwFa7uj9/EzLYs/aCCIior2a2Cyu0qYvWhcjex76vy5FcLcyEoex3c/r+oWD1hIVdUL8/tI+brNv+i28m5u17m4CjG5w89szX4x5PicN2WF2wWBW/Je8j+fnpYphaRfStOs/eTQB/mauFy6A6mKP63abfhTEicjLiBef5j+Rdv+vGhNgBrF7YIQ6vvNkaMsxTOnPBO1MbqOXJHsowAfsxDWfOMerru922LgygvGXVNbcqttw8FPNUD7yUNyxii7ua7P7GZebyVGNvuWwyn/Zxsb5h452XemYTHew1l87rictAHm5Yz4woONyyqCzsJZAvUzY5M78+nvgPc5VkmwGxpe0AAAAASUVORK5CYII=';
string public constant body13 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAJ1BMVEUAAAAMDA0HBREqL0c9U2NRcnxgIy6fPTKxaT3RtpjUn1778Nr///+K88C9AAAAAnRSTlMAAHaTzTgAAAJxSURBVHhe7dRPjtMwFAbwmTnBxCeoUxRXLJsK2DeIC0wv4JGey9ZC71kVqy7iR04w0hyAyFxgBDvWHIrnTEL/DXsWfFkkys/250RRrv7R/E8xpJToYswFq9W6aZZ/5fnm/aZZ6zO+zjRMvtts8vRLvpXzTdNs7oSnrtvrE55/+HQX4upFvinLV4FDl2It279kYsMppZ7fpbS/XLxyLXSpBU7oZpds4PPPLdtffQu+lJywKkvcJeYu9eAqF1JfHrEyBOZ76uR4Iu+IU4r6wBVHtD+S5NuTr0IU7v0fVo4J4fGBmR8fMHDMJXF2YBL+2MnsL4zMFFhyYCACcL3MSRzlWjywnbiigYfXEoTR5QI/sclrAwThGITQxVN2tGUk5kgog6LlI1ZOurepx9wh2mfmgHpkckSuEx8KmNEGZqKJURiCeOTUs1RYIzU0e+YKgLxhSSuWWSuiYwatMmAYFLXp+olvHIItlAiBG9wXC9kgjkwh+qJYMObFg7Ta4rWwv5qYSRcKgSMzAKEe2E5MTKUuKhei9N7XtVad8GxiSfCqbobU9TJXJ57YBcLtvrpfZV3Xb7BMkjjytQncOu/gvpa8bbe860Pq97dHDJYA18LbKPx1JxufuCKOWJFD6V0FliOznlgFIm9awmZVN6GLHLddikfMrV1E4aZuFl3PccG8L/6w4+ifebU2wmx2/YHzP0UbJitPtlQhMW+73h84xxDqef51GGbyMv6UKwKrVsti+Kq93DhjAFvMtbB7iVVmNdbYc1Zl5nEdF/UZG3QIemATHdtTVg5pZBWE/RnTgTkC788ZCCZGCCNPUWXOwM+X49Z/A1WcaDsbs7kvAAAAAElFTkSuQmCC';
string public constant body14 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAJ1BMVEUAAAAMDA0HBREqL0c9U2NRcnxgIy6fPTKxaT3RtpjUn1778Nr///+K88C9AAAAAnRSTlMAAHaTzTgAAAJnSURBVHhe7dQ/jtQwFAZw4AQbn2Azi+IR5WYE9BPEBXYukJWeh9ZC75ktp4g/UlKBOACRucAKOkpOxXN2Mn+XnoIvjaWfn5/zz0/+0fxPMWamKYttztgslk1z/Ve+Wr1ZNcvyhJ9mGotvVqtd+Tk3zepmz8XFMV+9fX8T4uJRNrPZ84DQp1jr9s9ZYJFSGvA6pc0ZX1Suoz51hMTu8pwtffi0Rvtl6MjPNEesrfnuF7D5PZCrXEjD7ICNFbI/Uq/XvXgnSCmWe64QmX4mzfd7X4WoPPgdGwdh+voZwNfPHBDRpyFe7lmU3/Va/REMSIBmzyRC5AatSYg6Vg9oJ65k5PGxBGV2uYGf2Oa1iYJyDErs4jE7WYMFiMI6KbY4YONIZJ0Gzj1Uh8wIfLllLRbXq1NWgNsAiEzMyhTUI9IAILYWcccVkXgLTYcxsTQih0ylycBhVC5tP0z8zDG1hVERcqP7Yq4b5C1LiL4o5mB0QECUtnih7J9MDCkLw4QIEAmXI7cTC0R/nsqFiMi3dV2aXvlyYk3wpm7G1PV1bp0wsQvC6011u8i6rF/yLGl279sGdM47uq01r7o17oaQhs3FAVMrxEvldVT+dnfwMVWCyJU41r6LAL0ylxObIOJtJ9ws6ib0EXHdp3jA6Np5VG7qZt4PiHNgU+zYIfoHXiytMuzdsOd8ppQW0uqdXZuQgHU/+D3nWOHyKh8dFhCv84+5EmpN/vcNiXgtOGGitrgqld1jbDKbbZv2/PDIvF3HxfKELTumcmQbHdpjNo5lyyYo+xOWPSMSNqdMQhMzhS1PMbOckR+GW/4D0zNpCQF5gDcAAAAASUVORK5CYII=';
string public constant body15 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAJFBMVEUAAAAMDA0XFCUHBREqL0c9U2NgIy6fPTKxaT3RtpjUn1778NrKz+9kAAAAA3RSTlMAAAD6dsTeAAACRElEQVR4Xu3STW7bMBQEYBe+QARdRKoC0cg2cnsB+wQKHr0nwEdka8Ccqjdol12E0A2KXK5DxfJf2gsEHW0IfiZHtLj4uPmfZcNUt/CpKIqJVyOz/xcvh8wv1Tx9d81czKTP89wls/dhYji+wHtWTNUA2P+OF61td2MSweht9Z6N7Fsc+lWK4hrmilnt9yvg1wMXNzaMqbng0qiYIY0ptzur7I/1mVtELwON8W2I5OROXFqol1cA31/HGBAxjClWZ1byTy5Nv9MB0ADmzKIq8g30H/Ac0wP6mVvNvGM5Usw72VzgZjacERFyipm8jddsdQe1QFQJPFSPCy4tu/mPsnXSlBnBV0dW9tmBLlkB3wdAdWZPlkCPGBOA2BvEE7ci6gyYAy1ztVS9ZKmWGXyY1FdmSDMvrZd+saSo2MldvljJH1lD5CFW8HnzwNZ+8UB2i5nBnqUXREBEfTVxP7NCm7pobYjsfeq6uhzI1cxMcGW3ndJ1jwWrR8xsg/rdvn1aZ910X3wzMqfvbQIO1ll56pivhx2eUxjT/u6CpVfxG/Iukl+eLy5Tq4i+VevZuw7gk7meuQyqzhzUb9fdNgwRkTcjXnC+/5G87barISGugH1xYovo3ni9MWSY53Tmomma2kB7nuyxDCOwG5I7c45RX99vN3VhAHX8/TW3Kn25fiymW+04ccMifXFfk+3fuMxcHmv6Wy6bzMd9bKxv2HjrpZ7YRIv+mkvr9chlILsb1jMjCva3LCozewlHnlM2ORO/DfOI8Acb+XAdYpJl1wAAAABJRU5ErkJggg==';
string public constant body16 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAJFBMVEUKCgoHBREMDhQeKjAxRUk+EhtlJx2FSSerbDTRtpj78Nr/+vpFIU9bAAAAAXRSTlMAQObYZgAAAklJREFUeF7t1DGO00AUBuDMDcZBntDGEdDHiAtsLuCV3liUFnpvIlGl8PzmAnjEBVbaCyyio+ZyPGdjbJxNT8HvJtKn53+sPM3qn87/ZBp7U81uX5bbm7w+vD+Ue3tz+O5wuD1uyvJwd5vXHz7dhbh7kU2WvQoIXYqFHv+aBQ4ppR7vUjpdj+e+pS61hMTeXrOjzz9rVL/6lppMs6zmYwK61JPPfUj93I0Tct9Tp8+TNF6QUrSzYkSufiTNt6cmD1G5b6ZhD2F6fADw+MABcSiJdmJR/tjp9BcwIAGaiUmEyPc6kxBFSD2gGjmXMyNpZVBmPxQ0IzsRJqKgHIMS+/g3e6nBAkThkFKsMGPjSaROPQ8dqv3ACGwvrMPiO3UaFOAqACIjszIF9YjUA4iVQ/zDOZE0DpoW50RrROZM1gzA4axsXdePbDxTtTIqQv7szWqjB+QLS4j6ERswWiAgSrV6Pf0nytAew4QIEAnbM1cjCySzuk4hIvJ9UVjTKduRNaExRXlOUWyH6oSRfRCuT/n9btB98YYz1WldXEDrG0/3heZtW+PYh9SfVjOmSoj3ynVU/nqcLVMuiJyLZ+3dBegz8LQsQaRxrXC5K8rQRcS6S3HGaKtNVC6LctP1iBvgNF/U2Dzzbu+U4Y698uxOsQ5S6ZdtTUhA3Y0nG+OE7Xq4OhwgzdUVlAtVZrd93uphdMFE1Wptlf1LbAY2l5rqSjPl8T0+2gU79kz2zC56LMaNZ7mwCcrNgmViRMJpySQ0MlNYcjbETj8v8Bs7mRlGCf3DNgAAAABJRU5ErkJggg==';
string public constant body17 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAJFBMVEUKCgoHBREMDhQeKjAxRUk+EhtlJx2FSSerbDTRtpj78Nr/+vpFIU9bAAAAAXRSTlMAQObYZgAAAkxJREFUeF7t1DGu00AQBuDsDdZBdmjjCOhjxAVeLuAnzVqUFprZUKbwjrkAXtFRPfEu8BAdHcfj37w4NgnpKRg3lj6P/7E98uKfrv+VoexNNZttVa1v8nL3dldt7c3mu93udrupqt3dbV6++3Dnw+avbLLshVffx1Bi/GsWLTTGOOibGA/X7bnrqI8daWRnr7mgj18brb8NHbUZ6jKa9z9VD78GcrnzcZi7KYSK77HH8SStE0wR7CxYA9OPiPry1OY+gId2anYqTI8Pqvr4wF6D9nEIdmIBv+/R/UlZVbyiJiYRIjegJ2rAOdxrfY6WIx9fiwezSwHn8EIQTeTBwYPYhT/ZSaMsqkEYF4VaZ2wcsps4cMqADonVsz0xmsX1cEqqyrVXFRmZweThQeOgiKgLDWfOiaQtFNXBElsjMmeyJgH7o7It+mFk45jqhYEIueSYeYUB+cTiAx5ipZxu7pFaL15O3wSsyDFMGlSJhO2R65FFJbNYJx+Qe1+W1vRgOzLKt6asjlWW6xQddWTnhZtDfr9Jui1fcQad1qXw2rnW0X2Jet01uh+wbIfFjKkW4i24CeDP+9ky5aKBc3GM3I1XHImnZfEibdEJV5uy8j3Gb/oYZqxdvQrgqqxW/aBhpXqYL2pon3mzLcBa7DHZ/J9iC5UaT7Y2Pqo2/TjZtFBsl+nXUahKe/ULyoVqs1k/b3VqvWDCV11asPsbm8TmFFNfaQYe7+OCveCCHZN9Pg1OL9qNYzmx8eD2gmViDaSHSyahkZn8JWep7HR6gt+CFhlYAsKSOAAAAABJRU5ErkJggg==';
string public constant body18 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAHlBMVEUKCgoHBREMDhQeKjA+EhtlJx2FSSerbDTRtpj78Nq/Q00PAAAAAXRSTlMAQObYZgAAAh5JREFUeF7t1EFu2zAQBVDzBnQg2uvI7QXsEygYai9ghlkL8Hy1yy5CHqHoDZrbdqhYlWsnPUDRvxLwMBwK+tDm383/uK3Ff8i7Yhk/HJ4qv/i/DZfsP9i7nxmDXeCeBfM0gHf3N7HpSyZC4ejvOdDY4NztstKwtdyu5nEHfNvb8Damkq/dBaEw5ZLnu0VBKepXbqBMU5nDTVLjPKzDEcL0CuDra9EExVSy+pXF+IeN5p/5DEiCZWUSIfoC8+9gETJP6BZupHJvy5G1nhTrgmHhUM8mMs5aiaP+yVF6SARUKJWiHa7YRRLpS2aRWXNlJPYXtmGJkzlVBbhLgMjCbEzJXFEyAO0C9Dc3RDIEWM6Yo96JXDN5V4HTrOzDlBd2kanbOBOhOPtQi5X5wpJ0sKqB6+EJKt1mv34TY9gexwQFiIT9zN3CArH6NzEplJ/a1rvJ2C9sSYNrT3Pa9nHuNBaOSbgfm6dD1WP7ibema11CwjkOkZ5ay+dzj+ecSh43V0ydEB+NezV+eb4qUyNQbiSy7T0kJKTKa1mSyBDOwqdDe0qTQq0ZesW1/2p8ak+7KUN3wHhdVB3e+HAMxgjPeeVN/SkESGdv9uhSAfppudlaKPYPp6PfBECGu59II9S5w+Nbq+voDRN1mwdvHN9jV9ld1nR3ujVezonqbzhwZPIzB424GXeR5cIuGQ83LCtDCeMtk9DCTOmWtzV+fbzAL1C98ZPm59jjAAAAAElFTkSuQmCC';
string public constant body19 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAKlBMVEUAAAAMDA0HBREtJUA1PmNDGitFRSJIaH9RXzJgeUFgm5LRtpj78Nr///+9UF/4AAAAAnRSTlMAAHaTzTgAAAJySURBVHhe7dS/itwwEAbwu3uCs55gZYvdkNKjnIt0mgGFhbzEJjhbrwUDThsW5w1u+4BBpL/m+oOQNmXeJSOvffvv0qfIp8LFz6NPNsZX/2j+JxuSS3Q25oLVett1q7/yfPd11231GV+L7Ifvd7s0fsm3cr3put298NR1e33C8y/v7n1Yv8g3ef7Ks29jqOX4l0xsOMbY86cYN5ebF7aBNjbAEe3skg28/1Xxm999Ay6XnLDKc1xG5jb2YAvrY58fsTIE5kdsZT2Rs8QxBn3gggOWP6Pk+5MrfBDu3TMry4Tw+MDMjw/oOaSSMDswCb9tZfozIzN5lhwYiABsLzORAxGIey4nLmjg4bV4YbSpwE1s0t4AXjh4IbThlC1VjMQcCOWmUPIRKwtEVewxdYj2idmjHlmGybbikJQZS89MNDEKgxcPHHuWitJIDc32XACQMyxpxBJrRXTMoFUC9IOiNm0/8Y1FKDMlQmAHd9lCDogjkw8uyxaMaXMvrWX2WthdTcykM4XAgRmAUA9cTkxMuc4K64P03tW1Vq3wbGKJd6ruhtT1KlVHnth6wmpT3K2TbusPmEdJGPnaeG6ss3BXSz42FS97H/vN7RFDSYBb4SoIf1vKwScuiAMWZFF6155lJdYTK0/kTEPYrevOt4FD1cZwxNyUiyDc1d2i7TksmDfZM1sObs/rrRFms+wPnP4p2jCV8mQr5SNz1fbuwCmGUM/Tr8Mwk5P7T7kgKNV6lQ1ftZOBMwYos7kWti+xSqzGmvKcVZ543McGfcYGLYIe2ATL5SkrizSy8sLujOnAHIA35wwEEyP4kaeoPGXPecp49D8JjjL/IUjL1QAAAABJRU5ErkJggg==';
string public constant body2 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAMFBMVEUAAAAMDA0HBRElTUoxDiYycE1DGitDjEZSITNsLzKCqFmGQjy51O7Rtpj78Nr///8fK+DDAAAAAnRSTlMAAHaTzTgAAAJuSURBVHhe7dS/jtQwEAZw4AkufoLLRtYelBmsvYaX8GhkceIpNjKfFInmECL7AEgbUaNILuhP21LS09GeREFJQcU4bPYv9BR8aSz9PB7nnx/8o/mfYsxMUxbbnLFZrfv+9q98tXm/6dflCT/MNBbfbTa78nPu+83dnouLY7569/wuxNUf2cxmjwNCm2Kn2z9ngUVKacDblJZnfFG5htrUEBK7y3O29OLTAk8/Dw35meaItTXf/ABe/hzIVS6kYXbAxgrZb6nV6168E6QUyz1XiEzfk+bjva9CVB78jo2DMH39AuDrFw6IaNMQL/csys9arX4FBiRAs2cSIXKD1iREHasH1BNXMvL4WIIyu9zAT2zz2kRBOQYldvGYnSzAAkRhnRRrHLBxJLJIA+ceqkNmBL7cshaLa9UpK8B1AEQmZmUK6hFpABBri7jjiki8habBmFgakUOm0mTgMCqXth0mfuSY6sKoCLnRfTHXDfKWJURfFHMwGiAgSl08UfYPJoaUhWFCBIiEy5HriQWiP0/lQkTk664rTat8ObEmeNP1Y7ruNrdOmNgF4cWyul5lXXeveZY0u/dtAxrnHV13mjfNAjdDSMPy4oCpFuK18iIqf7g5+JgqQeRKHGvfVYBemcuJTRDxthHuV10f2oi4aFM8YDT1PCr3XT9vB8Q5sCx27BD9b16trTLszbDnfKaUFlLrnd2akIBFO/g951jh8iofHRYQr/OPuRKqTf73DYl4LThhorq4KpXdn9hkNts29fnhkXm7jovlCVt2TOXINjrUx2wcy5ZNUPYnLHtGJCxPmYQmZgpbnmJmOSP/Hm75F5kCSrfTKpRrAAAAAElFTkSuQmCC';
string public constant body20 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAMFBMVEUAAAAMDA0HBREtJUAxDiY1PmNDGitFRSJIaH9RXzJgeUFgm5K51O7Rtpj78Nr////ACsCMAAAAAnRSTlMAAHaTzTgAAAJySURBVHhe7dQ/ihsxFAbwJCfY0Qk8HsQ6pJsXsW5yCT0eKGxOsSFM3NoofDCkDGZyg3UfGBCkSpkDbLX1QiBlmjR5mvXYXnvTp8inRvCbpzf/pCf/aP6nGDLVlMU2J2wW6667+iufbz5vunV5xE9V7ouvN5td+Sl33eZ6z8XZQz7/9Po6xMWjbKbT5wGhTbHR2z9lgUVKqcf7lJYnfFa5FbVpRUjsJqds6c23OV5+71fkp5pDzq358hfw4XdPrnIh9dMDNlbI/kitjjvxTpBSLPdcITL9TJqvd74KUbn3OzYOwnR7A+D2hgMi2tTHyZ5F+VWr1R/BgARo9kwiRK7XmoSoc/WAeuRKBh5eS1Bmlxv4kW1emygox6DELj5kJ3OwAFFYL4o1Dtg4EpmnnnMP1T4zAk+2LE7EteqUFeA6ACIjszIF9YjUA4i1RdxxRSTeQrNSy1wakUOm0mTgMCiXtu1HfuaY6sKoCLnBfTHTG+QtS4i+KGbgvHhAlLp4oeyfjAwpC8OECBAJlwPXIwtEN0/lQkTki6YpTas82bFI8KbphjTNVW6dMLILwvNldbHIum7e8lQ17b63DVg57+ii0bxbzXHZh9Qvzw6YaiFeK8+j8pfLg5+pEkSuxLH2XQToyFyObIKItyvhbtF0oY2I8zbFA8aqnkXlrulmbY84A5bFjh2iv+fF2irDXvZ7zmdKaSG1PtmVCQmYt73fc44VLs/z0WEB8Xr9Q66EapP3viERrwVHTFQX56Wye4xNZrNtU58eHpm367hYHrFlx1QObKND/ZCNY9myCcr+iGXPiITlMZPQyExhy2PMNGfg++mW/wDQL1pjMGSBkAAAAABJRU5ErkJggg==';

}

contract Bodies2 {

string public constant body21 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAKlBMVEUAAAAMDA0XFCUHBREtJUAxDiY1PmNDGitFRSJIaH9RXzJgm5LRtpj78NpmB1zFAAAAA3RSTlMAAAD6dsTeAAACUklEQVR4Xu3SQYrbMBgF4Ay5wBhfxK6NmDBL/xWTfXddWvwg5gSznlJMtklVHm73IQeYInyE0ht07tInT1wnmfYCpW8l/i/Sk4MW/27+Z1kxxSVcZVk28mpgtn/jZZ/4qZjG11dnzM1MfDPNTpm9tyOj5QVes2KsBsD+V7yobb0eoggGZ4vXbOTzO+zePsQgbcWcMavdpwfg23turqwfYnXCuVExfRzieDer7A/lzDWCk57GuNoHcmx/c26hTp4BfH0egkdAP8RQzKzkH9waf8YdoB7MzKIq8gX073Bc0z2aiWtNvGY5Ykgn2VTQTmw4ERFyDImcDedsdQ21QFDx/KgGJ5xbdvMfZeuoMTG8K4+s7LM9XZICrvGA6sSOLJ4eMEQAoTGs0eKFaxFtDZgdLXGxVD1lKZYJnB/VFaaPEy+tk2axpKjY0dv0sKI7svrQ8qnBpcM9W5vFLZmzI4M9SycIgIi6YuRmYoVWZVZbH9h713Vl3pOLiRnf5t1hTNc9ZqweMLH16tbb+m6TdN99cNXAhCNfGY+dba3cdczH3Rr30Q9xe33C0qi4PXkdyE/3vPjEtSK4Wq1j78bDwycuJ869amt26g6b7uD7gMCXEWZmd7MK5EN3WPURYQVss99sEdoX3uwNGeY+zpxVVVUaaMMve8z9AKz72M6cYtSVN4d9mRlAW/7+nGuVJt88ZuOrbjm4YJEmuynJ9k+cJ86PNc0l51Xi4zk2lBdsnHVSjmyCRXPOuXV65NyT2wvWmREE20sWlYmd+JnH5FXKyC/LtCL8Al/neo8gyvdyAAAAAElFTkSuQmCC';
string public constant body22 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAJ1BMVEUAAAAMDA0HBRENDCAaHTQtOFA3CDtAWGpXE0GBJUPRtpj78Nr///9LdwXWAAAAAnRSTlMAAHaTzTgAAAJxSURBVHhe7dQ/btswFAbwJCeIeAJTot3OfHSGjnyPcIdOFh8EdExbwQeowKFrYag3iA+QKXPQoVvnHqqPslT/S/cO/TRI0I/kRwmCrv7R/E8xpJToYswFq8227+//yovdt12/1Wd8LbKf/LDb5emXfCvnm77fPQhPXbfXJ7z4+vYhxM2LfFOWrwOHJsVWtn/JxIZTSh1/Sml9uXjlamhSDZzQzS7ZwLufS7a/uhp8KTlhVZa4SsxN6sBVLqSuPGJlCMz31MjxTN4RpxT1gSuOaH8kyZdnX4Uo3Pk/rBwTwtMjMz89YuCYS+LswCT8ppHZ7xmZKbDkwEAE4DqZkzjKtXhgO3FFAw+vJQijywV+YpPXBgjCMQihi6fsaMlIzJFQBkXLR6ycdC9Th7lDtMvMAfXI5IhcIz4UMKMNzEQTozAE8cipY6mwRmpotucKgLxhSS2WWSuiYwatMmAYFLVpuolvHIItlAiBG9wXc9kgjkwh+qKYM+bFg7Ta4pWwv5qYSRcKgSMzAKEe2E5MTKUuKhei9N61rVaN8GxiSfCq7Ye07X2uTjyxC4TLdXW3ybptP2CZJHHkaxO4dt7BXSv5WC951YXUrW+PGCwBboWXUfjzSjY+cUUcsSKH0rsJLEdmPbEKRN7UhP2m7UMTOS6bFI+YazuPwn3bz5uO45x5Xfxhx9HvebM1wmxW3YHzP0UbJitPdq9CYl42nT9wjiHUi/zrMMzkZfwpVwRWbe6L4av2cuOMAWyx0MLuJVaZ1Vhjz1mVmcd1XNRnbNAh6IFNdGxPWTmkkVUQ9mdMB+YIvD5nIJgYIYw8RZU5A+8vx63/BuOwBpEXjEwbAAAAAElFTkSuQmCC';
string public constant body23 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAJ1BMVEUAAAAMDA0HBRENDCAaHTQtOFA3CDtAWGpXE0GBJUPRtpj78Nr///9LdwXWAAAAAnRSTlMAAHaTzTgAAAJoSURBVHhe7dS9jtQwEAfwgye4+AnOG+9CnXGuoPSMtYhy41EkygOifQAsF7RoFd7gtkW6hqtPFHQ0vBbjXLKfdz0F/zSRfhnP5MsX/2j+pxgyk+hizBmr9abvb57lxfbbtt/oE36RaSi+3W6l/Dnu++3tnovLY158fXvrw/pJVrPZa8++TaGT8c+Z2HBKKfKnlFZnfFnaBtrUACe0V+ds4N33mqsfsQE3kxyxtMblb+bVnwi2tD7F2QErQ2B+plaOB3KWOKWg91xyQPiVJF8eXOmDcHQ7VpYJ4f6Ome/v0HPgNsVwtWcSftNK9XtGZvIs2TMQAdgoNYkDEYh7riYuaeDhsXhhtLmBm9jktQG8cPBCaMMxW6oZiTkQykWh4gNWFojqFDH3EI2Z2ePVyFJMthWHrMxYeWaiiVEYvHjgFJk5VIbDjksAcoYljVhmrYgOGbTKgH5Q1KaNE7+0CFWhRAjs4K6Yy4A4MvngimLOmBf3HKgqXgm7i4mZdKEQODADEOqBq4mJaaaL0vrAAa+7TqtW+GpiiXeq64d03U1unXhi6wnrVXm9zrrpPuAsSXbv23hurLNw3Uk+NjUvo09xdXnAUBHgRrgOwp+XBx9TSRywJIvSd+1Zjsx6YuWJnGkI+3XX+zZwqNsUDpibah6E+66ft5HDnHlV7NhycI+83hhhNsu457ynaMNUyZ3dKJ+Y6za6PecYQr3IW4dhJifXH3NJUKn87ysgclJwwgBVsdDC9ilWmdXYpjrfPDKP69igT9igRdADm2C5OmZlkUZWXtidMO2ZA/DqlIFgYgQ/8hQ1yxn48XTkv7LlB+ReM+zgAAAAAElFTkSuQmCC';
string public constant body24 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAJFBMVEUAAAAMDA0XFCUHBRENDCAaHTQtOFA3CDtAWGpXE0HRtpj78NpO583sAAAAA3RSTlMAAAD6dsTeAAACQ0lEQVR4Xu3SwW3bMBgFYBdeIAIXkSrRyV0/nQHEn8jd5oPQHtNC8LkIoQ0Mb1CgGzTL9VG1YtlpFyj6fCH4mXyixNW/m/9Z10x5Cx+Koph4MzK7v/G6z/xSztN318zFTPo4zy2ZvQ8To+MDvGfFVA2A/e941bhmOyYRjN6V79nKrsG+3aQoXc1cMav9bgN8e+Di2oUx1Qs2VsX2aUzTszllf6wu3CB66WmMb0Ikp+6NjYN6eQXw+XWMARH9mGJ5YSX/4NL0M+0BDWAuLKoin0D/Ds8xPaCdudHMW5YjxbyTywXdzJYzIkJOMZN38ZqdbqEOiCqBh2qxYOPYzTfK1klTZgRfnlnZ53q6ZAV8GwDVmT1ZAj1iTABiaxHfuBHRzoLZ0zKXa9UlS7nO4MOkvrR9mnntvLSrNUXFTd7li5X8mTVEHmIDnzcPbG1XD2TOnRnsWXtBBETUlxO3Myu0rorGhcjex2GoTE8uZ2ZCZ4bTlGF4Llg9YmYX1G93zeMh63H44uuRefveNmDvOiePA/N1v8VTCmPa3S1YWhV/JG8j+eVpcZkaRfSNOs/eQwB/mauZTVDt7F796TCcQh8ReTPigvP9j+TTcNr0CXED7Io3dojdbz4cLRn2KV24qOu6stCWJ3s2YQS2feounGPVV/enY1VYQDv+/5obldYcnovpVnecuGGRtrivyO5PbDKbc017y6bOfN7HxeqGrXdeqoltdGiv2TivZzaB3N2wXhhRsLtlUZnZS1hwjqlzJv49zCPCL7LLLAG58SauAAAAAElFTkSuQmCC';
string public constant body25 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAJFBMVEUAAAAMDA0HBRFubZSRm7GYFUvO1tzRtpjWJyfvY0778Nr////PB9XoAAAAAnRSTlMAAHaTzTgAAAJtSURBVHhe7dS/btswEAbwJE8Q8QlCiTYKdNMxamfegSjgza0KzRZxHbRnyFwD6hvEL5ChXQuhKF+uR1mK/6V7h34cPPx4/GjD4NU/mv/JxuQSnU25YNVs+379V17svu36rT7ja5H98NNul8Yv+VY+b/p+9yQ8d91en/Di64cnH5pX+SbP33j2XQy1XP+SiQ3HGAf+HOPm8vDCttDFFjiivbtkA6tfFb+PQwsul5ywynNcReYuDmAL6+OQH7EyBOZH7GQ9k7PEMQZ94IIDlt+j5PezK3wQHtwLK8uE8PjAzI8P6DmkknB3YBJ+18n0F0Zm8iw5MBAB2EFmIgciEPdczlzQyOPP4oXRpgI3s0lnA3jh4IXQhlO2VDEScyCUTaHkI1YWiKo4YOoQHRKzRz2xDJPtxCEpM5aemWhmFAYvHjgOLBWlkRq623MBQM6wpBVLrBXRMYNWCdCPitp0w8w3FqHMlAiBHd1lS7kgTkw+uCxbMqbDvbSW2VthdzUzk84UAgdmAEI9cjkzMeU6K6wP0ntf11p1wnczS7xTdT+mrtepOvLM1hNWm+K+SbqtP2IeJWHia+O5tc7CfS351Fa8GnwcNrdHDCUBboWrIPxzJRefuSAOWJBF6W08y0qsZ1aeyJmWsG/q3neBQ9XFcMTclssg3Nf9shs4LJk32QtbDm7PzdYIs1kNB05vijZMpXyztfKRueoGd+AUQ6gX6ekwzORk/ykXBKVq1tn4r3YycMYAZbbQwvY1VonVVFOes8oTT+fYoM/YoEXQI5tguTxlZZEmVl7YnTEdmAPw5pyBYGYEP/EclafsOU+Zrv4HuHQoc2DWqEsAAAAASUVORK5CYII=';
string public constant body26 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAJ1BMVEUAAAAMDA0HBRFubZSRm7GYFUu51O7O1tzRtpjWJyfvY0778Nr////FAx/1AAAAAnRSTlMAAHaTzTgAAAJrSURBVHhe7dRNjtMwFAfwgRNMfIKmcVUhscpzFdZ+T1hIXQ1EqAeAAzSWHkjZz2K2dBFuML3ALGCJZCF8KJ4zSdOPmT0L/tlU+vn53y/76h/N/2R95pI8G3LBarPruptnebH/vu92+Rm/SNQP3+/3Mv4cd93+fuLs+pQX397dO795ktV8/sqxa6Ov5e1fMrHmGGPgjzFuL/i6MA20sQGOaGaXrOHtp4pXn0MDdi45YanG9W/mrzGAKYyLYX7EShPon7GV54GsIY7R5xMX7BF+RMmfB1s4LxzsgZVhQri7Zea7W3TsuY3BzyYm4TetTH9hZCbHkomBCMAEmYnsiUDccTlyQT33X4sTRpMK7Mg67Q3ghL0TQuNP2VDFSMyeUBb5ko9YGSCqYsDUIRoSs8PZwDJMphWHpMxYOmaikVEYnLjnGFgqSs3+wAUAWc2SRixxroiOGXKVAF2vmOs2jPzSIJSZEiEwvdtsGWPAgcl5m2VLxrS5k9Yyey1sr0ZmyjOFwJ4ZgDDvuRyZmOTwFMZ56V3Vda5a4dnIEmdV3fWp65tUHXlk4wirbbHaJN3V73EeJYffWztujDWwqiUfmorXwcWwvT5iKAlwJ1x54V/roz9TQeyxIIPSu3EsT+J8ZOWIrG4Iu03dudazr9roj5ibcumFu7pbtoH9knmbHdiwt4+82Wlh1uswcbpTcs1UbuR0KxeZqzbYiVM0Yb5IV4dmJivrT7kgKFU6+wqIrAycMUCZLXJh8xSrxGqoKS8vj8TDPsbnZ6zRIOQ9a2+4PGVlkAZWTtieMU3MHnh7zkAwMoIbeIyap/T8+HLgv28WPxlIzBAbAAAAAElFTkSuQmCC';
string public constant body27 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAJFBMVEUAAAAMDA0XFCUHBRFubZSRm7GYFUvO1tzRtpjWJyf78Nr////56wh1AAAAA3RSTlMAAAD6dsTeAAACTElEQVR4Xu3SQW7bMBAFUAe+QARdRKrEeJGlhtYBxAEXWSYVYHRpTX9b3aDdO/ANiuwDouDlOlSk2HHaCxT92hDzRH0K4Orfzf+sK01xCVdZlk28iZr933g9Jn4ulvH11YmXzTF8WGbnrL23E6PTA7xnxlQNQPvf8aq2dRsDEaKzxXs29PUBw/YxCHWV5g1rtfv8CPz6pJsr62Oozjg3TGYMMUxns6z9Up64hjga4xRXe1EO3SvnFuzoCcC3pygegjEGKU7Myt91a/gZBoA9NCcmZqIvUP8Bp2t1j2bhmhO3Wo4g6Us2FXQLG50QkXKQRM7KW7bcgi0gTD5GaXDGuSXmNgZtnTQkhnflzKx9dlSnpIBrPMC8sFMmry6IAYA0BsJcvHBNxJ2BZsAUKdbM50zFOoHzk7rCjGHhtXXUrNYqTHbyLl2s4GZmL51eNTgMgIdws7pV1tnM0J61IwhAxK6YuFmYwVWZ1dYLxG37vsxH5WJhje/y/jil7+8zrY5Y2Hp27b7e7pIe+gdXRY3MfGU8BttZ2vaaj0OLu+Bj2F+fMTVM7qDcivLznR584ZohrmbrtHfnoU/icuHcM3dmYHfc9Uc/CqQdo5wxhmYjysf+uBkDZAPss1e2kO6FdwejDHMXTpxVVVUacKN/dp/7CLRj6E6cYtiVN8dDmRmAO33/LddMTb67z6Zb3enggoma7KZUtn/iPHE+1zSXnFeJ5+9YKS/YOOuonNiIRfOWc+t45twrdxfMJ4YQ9pdMTAs78jMvyauUiV+WaaXwG3I9TwKOLqhNAAAAAElFTkSuQmCC';
string public constant body3 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAKlBMVEUAAAAMDA0XFCUHBRElTUoxDiYycE1DGitDjEZSITNsLzKCqFnRtpj78NrvTYAXAAAAA3RSTlMAAAD6dsTeAAACUUlEQVR4Xu3ST2rcMBQG8AlzgRhfxK6NmJClX4Wz765Li4cgF8h+3NcP3K5SCp4bzBwgFegIpTdo7tInx+78SXuB0s8b8X6WPxm0+nfzP+tKU1zCVZZlE2+iZvs3Xg+Jn4plfH115GVzDG+W2Slr7+3E6PQAr5kxVQPQ/le8qm3dxkCE6Gzxmg19fIf+7UMQ6irNGWu1+/AAfHuvmyvrY6hOODdMZggxTGezrP1SHrmGOBriFFd7UQ7db84t2NEzgM/PUTwEQwxSHJmVf+jW8DP0AHtojkzMRJ+g/h1O1+oezcI1J261HEHSl2wq6BY2OiEi5SCJnJVzttyCLSBMPkZpcMK5JeY2Bm2dNCSGd+XMrH12UKekgGs8wLywUyavLogBgDQGwly8cE3EnYGmxxQp1synTMU6gfOTusIMYeG1ddSs1ipMdvIuXazgZmYvnV41OPSAh3CzulXW2czQnrUjCEDErpi4WZjBVZnV1gvE3Y1jmQ/KxcIa3+XjYco4PmZaHbGw9ezabX23S7ofv7gqamTmK+PR287S3aj52re4Dz6G7fUJU8Pk9sqtKD/d68EXrhniarZOe3ce+iQuF849c2d6dofdePCDQNohygmjbzaifBgPmyFANsA2+80W0r3wbm+UYe7DkbOqqkoDbvTPHnMfgXYI3ZFTDLvy5rAvMwNwp++fc83U5LvHbLrVnQ4umKjJbkpl+yfOE+dzTXPJeZV4/o6V8oKNs47KiY1YNOecW8cz5165u2A+MoSwvWRiWtiRn3lJXqVM/LJMK4VfrI1vwBYXC+IAAAAASUVORK5CYII=';
string public constant body4 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAKlBMVEUAAAAMDA0HBREQIB4fDxIhPTMzWT05Ih5DGitTOC1WdUnRtpj78Nr///+BuKYLAAAAAnRSTlMAAHaTzTgAAAJzSURBVHhe7dS/btswEAbwJE8Q8QlMyXSBjrpQKNDNVeudh2MBA10s8AZ1dSH0SQI/QDUQnTNlzlD0Abr0XXqUpfhfunfox8HDj8ePNgxe/aP5n2xILtHZmAtWq23XLf/K893XXbfVZ3wtsh++3+3S+CXfyudN1+3uhaeu2+sTnn/5eO/D6kW+yfNXnn0bQy3Xv2RiwzHGnj/EuLk8vLANtLEBjmhnl2zg06+K3/zuG3C55IRVnuM6MrexB1tYH/v8iJUhMD9iK+uJnCWOMegDFxyw/Bkl359c4YNw755ZWSaExwdmfnxAzyGVhNmBSfhtK9OfGZnJs+TAQARge5mJHIhA3HM5cUEDDz+LF0abCtzEJp0N4IWDF0IbTtlSxUjMgVA2hZKPWFkgqmKPqUO0T8we9cgyTLYVh6TMWHpmoolRGLx44NizVJRGami25wKAnGFJI5ZYK6JjBq0SoB8UtWn7iW8sQpkpEQI7uMsWckEcmXxwWbZgTId7aS2z18LuamImnSkEDswAhHrgcmJiynVWWB+k966utWqFZxNLvFN1N6Sul6k68sTWE1ab4m6VdFu/wzxKwsjXxnNjnYW7WvK+qXjd+9hvbo8YSgLcCldB+NtaLj5xQRywIIvSu/IsK7GeWHkiZxrCblV3vg0cqjaGI+amXAThru4Wbc9hwbzJntlycHtebY0wm3V/4PSmaMNUyjdbKh+Zq7Z3B04xhHqeng7DTE72n3JBUKrVMhv+1U4GzhigzOZa2L7EKrEaa8pzVnni8Rwb9BkbtAh6YBMsl6esLNLIygu7M6YDcwDenDMQTIzgR56i8pQ95ynj1f8A1fIr05BMlj4AAAAASUVORK5CYII=';
string public constant body5 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAALVBMVEUAAAAMDA0HBREQIB4fDxIhPTMxDiYzWT05Ih5DGitTOC1WdUnRtpj78Nr///8eGeFyAAAAAnRSTlMAAHaTzTgAAAJsSURBVHhe7dQ/jtQwFAZw4AQbn2AzWWuQ6PLWTEO1BDG1n56MtJxiIusTCuUgRZxkNT1KYdFCA/UWiAMgLsFzmMxf6Cn40lj6+fk5//zgH83/FGNmmrLY5ozNct33N3/lq837Tb8uT/hhprH4brPZlZ9z32/u9lxcHPPVu1d3IS7/yGY2exwQuhQb3f45CyxSSgNeprQ644vKtdSllpDYXZ6zpdefFnj6ZWjJzzRHrK359gfw5udArnIhDbMDNlbIfkudXvfinSClWO65QmT6njQf730VovLgd2wchOnrZwBfP3NARJeGeLlnUX7WafVbMCABmj2TCJEbtCYh6lg9oJ64kpHHxxKU2eUGfmKb1yYKyjEosYvH7GQBFiAK66RY44CNI5FFGjj3UB0yI/DllrVYXKdOWQGuAyAyMStTUI9IA4BYW8QdV0TiLTQtxsTSiBwylSYDh1G5tN0w8SPHVBdGRciN7ou5bpC3LCH6opiD0QIBUeriibJ/MDGkLAwTIkAkXI5cTywQ/XkqFyIiXzdNaTrly4k1wZumH9M0N7l1wsQuCC9W1fUy67p5zrOk2b1vG9A67+i60bxoF7gdQhpWFwdMtRCvlRdR+cPtwcdUCSJX4lj7LgP0ylxObIKIt61wv2z60EXERZfiAaOt51G5b/p5NyDOgVWxY4fof/NybZVhb4c95zOltJBa7+zGhAQsusHvOccKl1f56LCAeJ1/zJVQbfK/b0jEa8EJE9XFVans/sQms9m2qc8Pj8zbdVwsT9iyYypHttGhPmbjWLZsgrI/YdkzImF1yiQ0MVPY8hQzyxn593DLvwCyCENlyTNdMgAAAABJRU5ErkJggg==';
string public constant body6 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAKlBMVEUAAAAMDA0XFCUHBREQIB4fDxIhPTMxDiYzWT05Ih5DGitWdUnRtpj78NoEgfraAAAAA3RSTlMAAAD6dsTeAAACUklEQVR4Xu3ST27UMBgF8KnmAo1ykYSk1khd5quZfQnSrGN9stQtO5YzMk8ElrOYG/QElUWOgLgBvQvPacL8KVwA8bKx/Iv9nMiLfzf/s6yY4hKusiwbeTUw27/xsk/8VMzT11dnzMVMfDPPnTJ7b0dGxwO8ZsVYDYD9r3hR23o9RBEMzhav2cjnD9i9fYxBuoo5Y1a7T4/At49cXFk/xOqEc6Ni+jjE8WxW2R/KI9cITnoa42ofyLH7zbmFOnkG8PV5CB4B/RBDcWQl/+DS+DPuAPVgjiyqIl9A/w7HMd2jmbnWxGuWI4a0k00F3cyGMyJCjiGRs+Gcra6hFggqnh/V4IRzy27+UbaOGhPDu3JiZZ/t6ZIUcI0HVGd2ZPH0gCECCI1hjRYvXItoZ8DsaImLpeopS7FM4PyorjB9nHlpnTSLJUXFjt6lixXdxOpDx6sGlzb3bG0Wt2TOTQz2LJ0gACLqipGbmRValVltfWDvXduWeU8uZmZ8l7eHMW17n7F6wMzWq1tv67tN0n37zlUDEya+Mh4721m5a5n3uzUeoh/i9vqEpVFxe/I6kJ8eePCZa0VwtVrH3o0Hn8TlzLlX7cxO3WHTHnwfEHgzwglj16wC+dAeVn1EWAHb7DdbhO6FN3tDhnmIR86qqioNtOGX3ed+ANZ97I6cYtSVN4d9mRlAO75/zrVKk2/us/FWd5y4YJEmuynJ9k+cJ86nmuaS8yrxtI8N5QUbZ52UI5tg0Zxzbp1OnHtyd8F6ZATB9pJFZWYnfuI5eZUy8sswjQi/AP1pZ1fvLM0lAAAAAElFTkSuQmCC';
string public constant body7 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAJ1BMVEUAAAAMDA0HBRFCOjtYGSRmVFd4Ki6FaWaPRUCwaFjRtpj78Nr///8k03LpAAAAAnRSTlMAAHaTzTgAAAJwSURBVHhe7dRPitswFAbwmTnBWCeIHFek27gpXWsewnQb3O7F60OBbofsQxDPPUCx6AUG5gJTuuu6h+qTx27+TfcF+gmIyE/SpwTjq380/1MMKSW6GHPBarVu2+Vfeb79uG3X+oyvMw2b77fbvP2Sb+Xzpm2398JT1+31Cc8/fLoPcfUi35Tlq8ChS7GW618yseGUUs/vUtpdHl65PXRpD5zQzS7ZwOefDdtf/R58KTlhVZa4Scxd6sFVLqS+PGJlCMz31Ml4Iu+IU4r6wBVHtD+S5NuTr0IU7v0fVo4J4fGBmR8fMHDMJXF2YBJ+38nuL4zMFFhyYCACcL3sSRxlLh7YTlzRwMPfEoTR5QI/sclnAwThGITQxVN21DAScySURdHyESsn3U3qMXeI9pk5oB6ZHJHrxIcCZrSBmWhiFIYgHjn1LBXWSA3NnrkCIG9YshfLrBXRMYNWGTAMitp0/cQ3DsEWSoTADe6LhVwQR6YQfVEsGPPhQVpt8VrYX03MpAuFwJEZgFAPbCcmplIXlQtReu/qWqtOeDaxJHhVt0PqepmrE0/sAmGzq+5WWdf1GyyTJI58bQLvnXdwV0ve7hve9CH1u9sjBkuAa+EmCn/dyMUnrogjVuRQeleBZWTWE6tA5M2esF3Vbegix6ZL8Yh5bxdRuK3bRddzXDDvij/sOPpnXq2NMJtNf+D8TtGGycovW6qQmJuu9wfOMYR6nl8dhpm8rD/lisCq1bIYnmovX5wxgC3mWti9xCqzGmvsOasy83iOi/qMDToEPbCJju0pK4c0sgrC/ozpwByBd+cMBBMjhJGnqDJn4OfpePXfzOtJzPnZNQUAAAAASUVORK5CYII=';
string public constant body8 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAJ1BMVEUAAAAMDA0HBRFCOjtYGSRmVFd4Ki6FaWaPRUCwaFjRtpj78Nr///8k03LpAAAAAnRSTlMAAHaTzTgAAAJpSURBVHhe7dS/btswEAbwtE8Q8QkiRyXcNaqLzsqBMLoaanfiemC6B94NgfjUByhEdOsUNC+Qolu3vlWPqmU7drp36KeFwI/Ho/7x7B/N/xRjZpqy2OaEzWLVtld/5cv1+3W7Ko/4Waax+Ha93pWfctuub/dcnD/my3cfbkNcPMlmNnsREPoUa93+KQssUkoD3qS0OeHzynXUp46Q2F2csqWPX5dovg0d+ZnmkHNrvvkJbH4N5CoX0jA7YGOF7PfU6/Ug3glSiuWeK0SmH0nz5cFXISoPfsfGQZju7wDc33FARJ+GeLFnUX7ba/UnMCABmj2TCJEbtCYh6lg9oJm4kpHHxxKU2eUGfmKb1yYKyjEosYuP2ckSLEAU1kmxwQEbRyLLNHDuoTpkRuCLLWuxuF6dsgLcBEBkYlamoB6RBgCxsYg7rojEW2g6jImlETlkKk0GDqNyafth4ueOqSmMipAb3Rdz3SBvWUL0RTEHowMCojTFS2V/NjGkLAwTIkAkXI7cTCwQ/XkqFyIiX9d1aXrli4k1wZu6HVPXV7l1wsQuCC831fUi66p+xbOk2b1vG9A57+i61rzulrgZQho25wdMjRCvlJdR+fPNwcdUCSJX4lj7LgL0ylxObIKIt51wu6jb0EfEZZ/iAaNr5lG5rdt5PyDOgU2xY4fo//BiZZVhb4Y95zOltJBG7+zKhAQs+8HvOccKl5f56LCAeJ3/mCuhxuR/35CI14IjJmqKy1LZPcUms9m2aU4Pj8zbdVwsj9iyYypHttGheczGsWzZBGV/xLJnRMLmmEloYqaw5SlmljPyn+GWfwNzTkrccdA4rAAAAABJRU5ErkJggg==';
string public constant body9 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAJFBMVEUAAAAMDA0XFCUHBRFCOjtYGSRmVFd4Ki6PRUCwaFjRtpj78NoEPKnVAAAAA3RSTlMAAAD6dsTeAAACRElEQVR4Xu3Sz23bMBgFcBdeIIIWkaoIdM5R3QGUD/QAhhcgiI85Gwaf2mMPoUYoukGzXB8Vy//SLhD06ULwZ/KJFhcfN/+zbJjqFj4VRTHxamT2/+LlkPmlmqfvrpmLmfR5nrtk9j5MDMcXeM+KqRoA+9/xorXtZkwiGL2t3rORfYtDv0pRXMNcMav9fgX8eODixoYxNRdcGhUzpDHldmeV/bE+c4voZaAxvg2RnNyJSwv18grg++sYAyKGMcXqzEr+xaXpdzoAGsCcWVRFvoH+E55jekA/c6uZNyxHinknmwvczIYzIkJOMZO38ZqtbqAWiCqBh+pxwaVlN/9Rtk6aMiP46sjKPjvQJSvg+wCozuzJEugRYwIQe4N44lZEnQFzoGWulqqXLNUygw+T+soMaeal9dIvlhQVO7nLFyv5I2uIPMQKPm8e2NovHshuMTPYs/SCCIiorybuZ1ZoUxetDZG9T11XlwO5mpkJrux2U7rusWD1iJltUL/Zt0/rrNvui29G5vS9TcDBOitPHfP1sMFzCmPa312w9Cp+S95E8svzxWVqFdG3aj171wF8Mtczl0HVmYP63brbhSEi8mbEC873P5J33W41JMQVsC9ObBHdG6+3hgzznM5cNE1TG2jPkz2WYQQ2Q3JnzjHq6/vdti4MoI6/v+ZWpS/Xj8V0qx0nblikL+5rsv0bl5nLY01/y2WT+biPjfUNG2+91BObaNFfc2m9HrkMZHfDemZEwf6WRWVmL+HIc8omZ+K3YR4R/gBQcWJ1Nj2FZQAAAABJRU5ErkJggg==';

}

contract Helms1 {

string public constant helm1 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8AQMAAAAAMksxAAAAA1BMVEX///+nxBvIAAAAAXRSTlMAQObYZgAAAA5JREFUeF5jwAFGwSgAAAIcAAGbMYQTAAAAAElFTkSuQmCC';
string public constant helm10 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAHlBMVEUAAAAXFCUxJUdLR15hYniDh5mui2W6nXXdxqHu3bstsOngAAAAAXRSTlMAQObYZgAAAM1JREFUeF7t0DFuAjEQhtGxkgPYEivYcnMDdhA1yfxOj7w+gAvgBoiaAnEDctxMUkXetTuaaL/2zYwl03/PVtXsa8PKlWHlD1tl+cvNO2WtkoL7SWexzrm9WXIR3L9Zaq82Z/NIqgHCnfk6j5ja8wF+A91f3hONMvcBAkCOF10et4oIiMPn6ZZoIsMcPPP2kuwkb8AMSK86xTsCiF47KvFvz2F6Amdvv5TY1xlRkaXEAzgAXGBqvHLhyzUTxHPvqNRCEDsqZpxz+em5ublvhvskZwfu5XkAAAAASUVORK5CYII=';
string public constant helm11 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAG1BMVEUAAAAuLi5MTExzc3OEhISVlZW8vLzNzc309PQDCwFCAAAAAXRSTlMAQObYZgAAAKhJREFUeF7tzj0OwjAMBeD4BnH4aVdChVgjoMylErCihsCKUNlzhN4cQTLantjoWyz5U/yifpAxoEUtBwHRVI5nY3evyCpWPlzPXDksD6tj3T7Y0+HZ+W3keBPqvvcNxw4RbdfS5WA/e7QnhhffMd0znNaG6YY8nMyNzBeaJ5kjzbPMN01zXhc0m8SwprnIfGeOD+LPIcqcXhuGVeqcayWllBnUv2XMmDd/BRLUPsxs0gAAAABJRU5ErkJggg==';
string public constant helm12 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAJ1BMVEUAAAADBg0HCBQoERpMJClxQTuaQDmlelHHakXQwnTnl1D/02n//eK4RMhyAAAAAXRSTlMAQObYZgAAAMdJREFUeF5jGMxgFAiCgAAuWUYT19DQUEdc0sIuoaHl5SECeDSHV5Ya4pB2NnYJDQ0txWG6sDFQOxAYYzddBKQ5vDzEFLtuUZNVq3efORIcgEPaqklJSWmNcwF2aRELJSDQJiDtgsNwYSv80l5gaVdXAezS3iCndYXiCjWXFUCfLcUV5mIiLqBQK2zELi2RDJQNLzdbiEN6sbGJi4uzBQ5psRXGxi4uxt04DGfsWgHUvXoXrtQk2LVq954zgniTIrrsKBgFowAAvAw1FigAR10AAAAASUVORK5CYII=';
string public constant helm13 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAElBMVEUAAAAXFCVLR15hYniDh5mosLvFvqvcAAAAAXRSTlMAQObYZgAAAJtJREFUeF7t0rENwjAQheFDWcBIWQDDAvGRHuWdF7B9+68ChA7xXITWf/vpyVdY/mt0Ou8FwrO7G+JCxvmtKV7Dbzb3mm5QxntHuX04EV53BzsNqzfTqIQzVJW//WiouU2LEJapihzlVSaI4EIYDpgltjbVEhWUcy1qnK2WO2WZrW5dRunzZqZdhgZht6FiH5M5Xhq6H/1bR6PRExw2KU+rNlvHAAAAAElFTkSuQmCC';
string public constant helm14 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAG1BMVEUAAAAuLi5NTU1zc3OEhISVlZW8vLzNzc309PQuVDnCAAAAAXRSTlMAQObYZgAAAMJJREFUeF7tz7EOgjAQgOG7N+iBPACtAVdagVlJ1FWL6KoEdxYfwCdXhbFXJwcT/uWS+3I0wM+bIuFBJBl7PJD5rWeV5nVz3HHnqNbJpqgu7Keb1tbLnmPTFF1XrzjOiEjaSjgV5XtPcstw/BmzkuFhHTBv4zgyP3+53rs5HLl3czTySbhZDJy6OcBhLNyMhgQgpWeGHyamQGvuv+9aSVO2MbgLE6W1NoJhfFmhCIA9v6oM2NDagwC+KCfwhAR/2dTUEwijF8b44v6gAAAAAElFTkSuQmCC';
string public constant helm15 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAJFBMVEUAAAAWFhY6OjpMTExVFBRzc3OUMTGVlZW8vLzg4ODtd3f/oaFq4qwYAAAAAXRSTlMAQObYZgAAAPFJREFUeF7tkTFOxDAQRWNOkPEoYunisZBCaVthD7EVsUbOCWioWGRlWxfRpuYG21BwBPZypF+7gjLP5dP/XxpXf2cD1ldC1NCDKWqUfvWqLjVz+ghRFvQdjhOf2EBhuo9xnIOnOq99mE9h9pDXuB+n8xKsyYcxLvHYRZcrB3iAeA5Pj35witqbZpPUHI+fYfGWpxstVFI7HtL7zmmXWYek7rlrAAfKjYsXzVOHwI6gymnaxwa5t5C/mXzlBq1XbVa75+s3Gl24SoWHt6+LkU7ltThcfy5S2+J3A0i9hotaEpEsaQFABG1VjsNq/5ONjY1fWE0wjT+DHzEAAAAASUVORK5CYII=';
string public constant helm16 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAAPFBMVEUAAAAHBREkBAT+63X/wmb/9rymMxvKby39d039l00eIShEUlhyJRQvNz8rMjn9Xz3+2HUaHSPdYz3xjUS6Udw1AAAAAXRSTlMAQObYZgAAAIVJREFUeF7tz8sKwzAMRFGNJDvvPv//XyuvUjC0yexKdZeCwyD58bIsyzJ8OH4N6DkO43uHweH9ROnd8pjW2M7gC9jhCDPebRvmpjEftf2X2BbIybBAW4SNoOvVpqogrOj6mNzGqsLgZs1HDoctdnMOD1aK+UBhUQ/7DMtq2oZWlX8py7IX22AC0PYnv8cAAAAASUVORK5CYII=';
string public constant helm17 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAG1BMVEUAAABdBy2aQDmoDyzHakXnl1D/Sjf/02n//eI6POuWAAAAAXRSTlMAQObYZgAAAFxJREFUeF5jGNxgFAgw4AaMAoyFQAKndKBoq4AobulS8XbBcFzSgoLt4uaCFQKMglilhRQ7wtNDOxyFFBmwAteKcvPy9lAXBuyAJbyio700RIFhKINRMApGwSgAAGhYDYt5GPoqAAAAAElFTkSuQmCC';
string public constant helm18 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAFVBMVEUAAAADBhwGAwYaFRctKSpIQ0RoYWKTzoFKAAAAAnRSTlMAW4oqRUQAAADNSURBVHhe7dDREYIwDAZgYAJhAgztAjQuQBoGwIQBPOn+I1hO73ww9dUH+a9v3zX90+rHOQIA3zRgLHsTUFX6Eg/EsqalxI6uvKZ74XqDiKppKzFdWFV0Kj2NmkOjvbKLgWU/AJ/zHavESKwpWcs1gQlwBLdKmKxi2fbMhFZ392K2LtdtR08W81vb1tGufptOJg8s4DTNN4PrzIHBU1xt7ihmRk7a24yZo8pcqCYIPkTOwy3vvIBDXc6Vnc5r2iBryQHgPdkqWP1fjhx5APQ5MAHDrRQyAAAAAElFTkSuQmCC';
string public constant helm19 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAG1BMVEUAAAADBg0TDConFD1EIFVoLnScQZefAGP/AELXMYnKAAAAAXRSTlMAQObYZgAAANNJREFUeF7tkkFuxCAMRSc3yCep1C1JDxCw5wBTPico9AY9QHc9fplMdmO66TZPXoCeDJa+L//lBI2+hTKXrh80LZLL2NFuUVJr6DQvWlkrbx29UkQ/S7Jfd2tcWXllR4sHoIne/jqiMVGDZeEC7lAAPOtL9Lu+bvfLE2PEK1q9pHa2JsPPd6v5YzOaByeP7rlssAYX7Mx59YaOemiNpuahJVlaDj1FBisQDbuWNzNxJ+8PndNo5ile621S2vuAFmj+IkNnm+CUCWjWZrCy+puTk5NfoFojhO+CBtEAAAAASUVORK5CYII=';
string public constant helm2 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8AQMAAAAAMksxAAAAA1BMVEX///+nxBvIAAAAAXRSTlMAQObYZgAAAA5JREFUeF5jwAFGwSgAAAIcAAGbMYQTAAAAAElFTkSuQmCC';
string public constant helm20 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAElBMVEUAAAAXFCVIACdwCjqSHD22NEINTYKeAAAAAXRSTlMAQObYZgAAAGFJREFUeF5jGKlgFAiCJBgFBbHLMhoLAoGwkpIAdmlnY2MTFxcXXNIuQGBsbKiMXZpBEAKcBRjwAEYypVlDQZjRCa9u3NIg3QFk6UYAEcUBlDakSNqRhtKMAgzDDIyCUQAAYtALVbw+/yQAAAAASUVORK5CYII=';
string public constant helm21 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAGFBMVEUAAAADBg0ZGB8uMDZTWF5+hozN2Nz/AEIqDDVEAAAAAXRSTlMAQObYZgAAAOtJREFUeF7t0cFtwzAMRmFxA/0inZ6ZZAHaygBCJN+L2F0g7v4r1EGRU6kFCr+LDh8IEWD4/9Ebos/x/fqsvyodHvFSXl0mygqA2xbJ45j4lmutFuCxUn7W9XOKZP7XbWtfRYyLx5nnBw9F2rfHgeVU66Nwu0dnOJDNtofFAjmLUz3VtYCX6KxOijKzACIG+8uT5mGf/hiWthZncbMbMyCybs50smmoUtDu2Vsd2KeRIAL4FxsuOmHsHVSvagpln0MSPWMvdJgtAanHBAPA2mPVF8fQCSlBr11OSOfRQi+6TNVi6AbA1X5HR0c/KZYh8ZycMO4AAAAASUVORK5CYII=';
string public constant helm22 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAMFBMVEUAAAAAAAAWFhYXFCUlTUoycE02JV5DjEZTIZ1/WLmCqFmizHaxbNTDAADViuXsufdBk1lWAAAAAXRSTlMAQObYZgAAAXpJREFUeF7t0LFKw0AYwPGaN+jkWj7aNBeKgr5BCbiXhoDjDYeiXYohEFy8oVzWTjkIDgUNXLcODu3moFRu7gPkAeLsYr1KvAopBcXBof8puV++cHyV/50BWw8Rq5UZPX0dGjEtDydYP3Ja+zHrn5sxNSz4RkDVhSQu3s6ZBYxB8fXxUUtmADQZ6psxGjF286l7jpR5Jhm91GxxymNGq1WA6v51nucHucz0dISSoZzHTQcA6kH+ulweLvNsTgs+Q/JRype0rfREKFX83opxwQQxyqJnceU4QTh745wjfrtepWnxYRTbYtV4kkg5b8m5NdBsqptzezxNxXg24VLGiFOy3hohxOK2eZGGD3iKeIwZw2S9SCDEpGFv0ez3FvbIGmBCABRoBxOHK1KcdpQVqDMa4T0e2SYWwldWqhHcedAOXJH6tU3sBl6973u+625iADcQIvA7AIo3BKdCpB1tpeww9LWWa3qeu4Xr3W7399MN1RY2VJU/bdeuXR+fnp19BPSz9gAAAABJRU5ErkJggg==';
string public constant helm23 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAKlBMVEUAAAADBg0iEQ41IBdAQmRRNyRjboNxVTSJlZ+fAGOii0+3wcX/AEL///9s5/3iAAAAAXRSTlMAQObYZgAAAVZJREFUeF7t0jFrwkAUwHHzDbwiIUId+q6UQCfv9URwMkr3Eh4RnJrY4heQ21soQib37t1LESE4dOwH6CR+l/qEtvTu3Dv4X39597gktX9UILiDdIKEF8O6i0yoAKSaDPuuAoe71AQcDhKdMkmiTgJX9ukNntSUEULsclAQpYofITPKXc6BZ415mdE4lzaHOiMar5EIqedhPnt1/5kZUnEuOzaD1jQPH1CnepScTyyONBmaXt9lRNQd9hs2S7W/GEK1WfaFyxjPy6rabm7FrtDeXVZP4jd7t/hTlNQ9H3MhRHPPb8Bsz78LccraKtouD5ofQjwvdrzUjgaN9vd09Jq6XPzsbhU3NQ9zZbXdroszl8uKX8tKG+oVdZcfiQxx6nLg4QdAnZkZZbNu4uGp5klAhLhfc4tAopJIhkZe5t80BXlgOkyYECn1cpAjKhD7fOyHY8eOfQFDWmUTJuDdIQAAAABJRU5ErkJggg==';
string public constant helm24 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAJFBMVEUAAAADBg0TDConFD1EIFVoLnScQZefAGPmddL/AEL/vuH////mQVUgAAAAAXRSTlMAQObYZgAAAWBJREFUeF7t0TFugzAUgOHHZpklJunQdAJ6gICdA6Q8TlDoDXqAjt0YK3oJZ4vwQrbK73I1lMm4Q6WO+WVYPj1bYPin2PR0v7KeYNAMeEg7DQNp+GCaB7bguucdt/MuAWbALgDxCHD5/XBmNHzqgA2ajwO5dEwWek859DEt6Vgz7TMzZIXLEMAIHscanCqsG2E0WNt5wzTQVVWZrJu95V/eNI97skmmEFVb0LDa3ABdM9Vi2+LJ0Oj/Vwt0zlFK9dJUD2TI4xEoycscWzzinmw/esxtIlMhhKowJQ0eGzpnpXBtURWGtMdwFkkhplC6F4DPUKYzHw8A0Yr5phT3wq27CmADqxIp3t/c2j0fom6lkeN5etccBKw5k2JuV+dpgEu1sCqDjAvLKsRy4W2JRYBzVcwsH5sNhD7s6YfrKsRRLlPVnrYKCwgl3IXWr4jFBsKeKKyEcBoumu7qb926desbgrFvLgJRKRoAAAAASUVORK5CYII=';
string public constant helm25 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAJ1BMVEUAAAADBg0GCBQKCR8iIFAzQnM+YpdHiL9LUWlduOR6hZnL09n///90L6wDAAAAAXRSTlMAQObYZgAAAQ9JREFUeF7t0rFOwzAQBuDcG9gSRlVGSzRi4yFIBzaqxoYxUdMgNjLElM0Lqty9FaM3q2HJmvQN+lKYuec8Qf710/mk8x/5TAEyyrNRBhNm6vlEQgtA+7d7SiKw6FobQTyIZwI9Nh530c3TpVI5DAjDvoN0f1E/B3q2CLcdK9tBbY8v5w7h325Rngalju8Dxq0VjfPcfPUI01ZnG9dXSpre0ms2erXYuVK8Gmf1FUOsi7u37yWXxmGXn+klFyXn1c5R7KiefTzrhxFuPin+Y+W/zhUlKMOm4XzbSBbgtSySQyZuA7xK6/t1lkucI/ZYJ6lkHx7w8TrJchGsGysSwfJwUYt5TkeqTADHcKZMmfIHP2VPk5uFMEwAAAAASUVORK5CYII=';
string public constant helm26 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAJ1BMVEUAAAADBg1SDS9TWF53Fzd+hoysJ0LN2NzsSUn/AAD/nYr/qMP///8Ii8QAAAAAAXRSTlMAQObYZgAAANhJREFUeF5jIAhGAaOgoAAeaREnpUTc8oxq2mfUHHFLu5w5c6xDAKfNQnvmbOtqxCEt5KLovdstrU0Au2aVtIwUl4y0DEXsmp1cU1JTwtzcHLFrDlI3CjcqVk1xEsAmrVqoGmgaGKpu5ILVcuZg4UBRw2DRQBz+MjU0EBYwFDVkwA4EBQQYGQSEBRjwAUEGQoARu5ggVLMiNmkFRpCbhQUZWLD620kYJC0aLIQ91NTMwdKladjDXCLUEOz7Fuw+E1EGiwsl4vCOIoRyxBsgjAIMdAOjYBSMAgAjfSEKlDmZ0AAAAABJRU5ErkJggg==';
string public constant helm27 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAG1BMVEUAAAAmADlYC36CDb2kNty9T/TYiv/ZpfPuy//WQDRVAAAAAXRSTlMAQObYZgAAAGlJREFUeF7tzbEJhFAQhOH/LZovVvCOa0BNzAXzA/FMDdRStG1tYDAy2w8mGpjhXSHzJCFZAhypAkMzcL3uDsn09QdSln3VOtagfMd8xxGKtWfYMsJ0/PgfC0J3buV81gjlfmfidSGEcAHuPwk/qDpBQgAAAABJRU5ErkJggg==';



}

contract Helms2 {

string public constant helm28 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAALVBMVEUAAAD///8DBg0HBREuMDY0BCVTWF5UCDB7EC5+hoyfAGOzGzPN2Nz/AEL/XEjXdhzNAAAAAnRSTlMAAHaTzTgAAAFOSURBVHhe7dDBSsNAEAbgpT5B8gR2bJqCCIUi3ssaKXgKLCt4KzVQ8JSy7EBvFdmB3IoUAp68ezYQ8OjJN/El3DQF3EbrC+RngBk+ZoBh3sH8zy2Dzd8MSFkBvzFA1/PRCJ0VtgFw2Y+SrhcIJMIy9XyedB3uJVPPF1hSWdLKjtHU5Y09KUlrfC+MbSdNDqSSVNKSKl67nFvWMQCgodjzrxvsCwU2IWHa3L5fg0ihCmmA3mTKHI4+k8t4y0vNOX92uc/nmzs4A1unJpnnH2OHO0+cX8Hri63BW5Tns5PRT2b9Gdf19qDoJbMxPjjcAdCwzSCLAcJs6PC5ULhjVEKaEXP4SCnasTa3tGAuswu941ARLYb73JFYv0XfFMbqHrNAP9acmQVrckfqGMtViJQOf2EGUsnsiyg9Zk2uPEAyALU2ufoNWHD5YFjLLbf8DU1gxwBtCOX4AAAAAElFTkSuQmCC';
string public constant helm29 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAIVBMVEUAAABGDQ1VFxdXGBhcFxddGhpzICBzJCSOLCzZjv//y/ru+SHkAAAAAXRSTlMAQObYZgAAAJFJREFUeF5jGBRgFLBlNDDgBiyC4hV45B0FBUXUsctzMTAwCjIwCBZgkeMESzMICIq4eGDXyrCAgYFRUFDQBYvhEyDSggwMDILuDBwdDChgwQSQARNYGEBAJLy8A9WEhZbOaVbl0yGuYhQNLUd1n1SniJvFSnMGHEBylaCgF25pRjMGBkbjBAZag1EwCkbBKAAAMuUVoaTOH2MAAAAASUVORK5CYII=';
string public constant helm3 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8AQMAAAAAMksxAAAAA1BMVEX///+nxBvIAAAAAXRSTlMAQObYZgAAAA5JREFUeF5jwAFGwSgAAAIcAAGbMYQTAAAAAElFTkSuQmCC';
string public constant helm30 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAHlBMVEUAAAAAAAAXFCUAAADqlAD/0gp+YQD/8Jf////Gqkq6haOJAAAAAnRSTlMAApidrBQAAACvSURBVHhe7dGxCsIwEMfhkLyAjxDO1t4oNtLOJtW9GnSvBJxrwbmi9bFN91zAzSG/9ePPBcJ+ScSZxxlldFp4XhNcST5IJmAR5lryh+eRkfzx3MfXLXEc59tCTH1Q+QCeN3AmuMlze6zg8qQYrd7KilifMrxrJdUu+DY0GTYzH4JcXDM0WnUkm5XpnFYmzM64vfPdggwv+3aTteOSBSvLegAA+st5y6JJ9velUqnUF/Y9Ir32GyuPAAAAAElFTkSuQmCC';
string public constant helm31 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAAM1BMVEUAAABUCDB+/4sAs1IDBg00BCV7EC5TWF7///+zGzMuMDZ+howHBRHN2Nz/AEKfAGP/XEjcwp37AAAAAXRSTlMAQObYZgAAAaJJREFUeF7t08tugzAUBFDuwy8gSf//aztju3IagUV3XTALQ7gcjwjJ8q9iHZj93eo4U21b6eVarSxnbeUGqXatVnm3GkDVvdauSdb1opwbHpKjE8u696e2Vm5cu4XWw1Yj40wzjrmFsB7Iaq0dWDNoZd2SR8YGgJwdRlutUROo9/ATQLuMiiOMG0jIG5WIlBLJlbTGDl/5aGMDqYQgQk79MwI90Eq7ppScJwEwMtTidYYh9HJS3azhBJSVgFxZna3pDHuEF183WEULa4WJ5QtaoNXqmPZQd6wsFpbXdoHmVeINzSfhFNic1lsEOsbgFT821zmGDc0OLW69eTnHCXs7sY8At48rnmqGoR8prSH4iBSRtWZ7zHCC3raUaJ/ufS1RUsJ12BX4VG+tQtxfz5f3NRbBngjsvu+T7kQrb83E0dfECb+9fdLNVDwSYwnOwJaJ3QNfk8TfWKIEBIcddqIFOH5iav7WSOda5AMLtyOlnccDiz7sqL2iwzuGFdqrWoLDlFgtah32oiYPof+ZSZ3gMqfvzid04ufueu7cuXPnzp1vQmsR+UYFzQcAAAAASUVORK5CYII=';
string public constant helm32 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAJFBMVEUAAAD///8PABQsASguMDZTWF5VBDV7CjR+hoyoDyzN2Nz/Sjd5QYo+AAAAAnRSTlMAAHaTzTgAAAE4SURBVHhe7dAxasMwFAbgZ5/A8Qks1VFqOpYmu5Fp5mBByOiAhVclKGSvQbNpa0Tmgm8QQi9XmXaJIvsAJf/w9MTHD0IwGc0/5wB+40d/i+fkeJT9bJzZAPsYG4nrfva7xTHLI/CnihfmoCy95jBjKcDDS3fUAiDOanTNS2Za82Wnv899Xdm8joDItdKnS2G4s1lF/kIypfVFuNoqxbzNDbcNnt5w1qlVecjroz6c2dvN0+jma7Vd0Fxy/k7pxuY8UytB9q8FLj+Y6vJrDh4pTQvMJTa8VnVqfyrruY/cM0aRxZ6BX/6UZkwsBpiEsteZxsjcHHxoMT61FRngXSWSc8lnETh5O2+edqWonAweeW6SeUWawMkQbpukFByBmz0iEk5EMMAQipnACIbYQyEKwOLRwJ3vfOcfz4Kw6EohAzQAAAAASUVORK5CYII=';
string public constant helm33 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAHlBMVEUAAAAAAAAHBRGSNXG5Dja9UYLPdJLsttL/qLj///+nSlA5AAAAAXRSTlMAQObYZgAAAYpJREFUeF7t071q6zAUB3BxnkSoOPZdLRTa8UIXrxZSe1cZCXctborXhAhlDZeketseJYuTyH2B5j84kJ/Ph7BNbsPo+ZIP+CSL9Qw//KOU0OqVzvATM2Cqpzl+XLRMV8sZLsRmGfhWzDBI+3bYdi2ZSeGG6OxtMTAMxZ/haNitFn0IwWBZucoMTpo8tblV0MG5PsQvOrORHeMh7GK2HLR7+R8jlntKKkczxUMTv3A6BV+YK144+/m3iQdkA2u4YtC+S/yhQ1gXe9B0qoz1Xr48j0er0PW6GM1Udb/zXAxxpZzVoTdls590xv82QvIUgd7TcnyfbF2zwgqbVKWbNIVPOnmEFBtw7a1K4QLnsknx2CJLyU+mlajJNOW4J6Ct4AJbaystveTmnYByKqX3atldMu6BrCWqdkq+Xr9HjCBbKVSKcJknCsJJfnJhM0yKvuPJpdJZ1luenCuX5TZ0HCOkz/FD++cgkVWdnQ0thOCskkxmuSZMO1UzaKcwPfz5I6nJTwFKflfuuecbo8CGPSA/BEIAAAAASUVORK5CYII=';
string public constant helm34 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAHlBMVEUAAAAAP3UB6v8WFCU7OmZNZbRNm+aP0//D6/zl9/+nNpvrAAAAAXRSTlMAQObYZgAAALVJREFUeF7tzLEOgjAUheGbXJ8Ao7ASJ7cacotjX6Eh0tlg2u5EYDUlkccWB7dbVx36r1/OgX8Jv/NZRWnzYRVdyhkAbzyvVE8KpGfnNCl0ywyy4HnoUPsZdRk4xlxQlis0Bc9lQD0GHK1geR/IjIGGHtikr2oXyPGMF9sMvpJjALZTa65Lb6ZC8POdzfK7exyA51YfS2ue2wg3lOUdmT7CArUVSDEGoOZ9ArFQrCDgt6VSqdQLeXEm6xWvf50AAAAASUVORK5CYII=';
string public constant helm35 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAMFBMVEUAAAADBg0HBREfDxI5Ih5AQmRjboOJlZ+KEi63wcXGRi/ILzffezr/h23/yE3////2vGgJAAAAAXRSTlMAQObYZgAAAZBJREFUeF7tz7FLAlEcwPHHtR2H8JZSHDwuBHGSlKAIgjxoa7S5xZs18DiEQIcKT4UakjcpTWK32FCCGWKL2OE/0BTnICgR1HIEXe+izd8zGtr8Hu+3fPjx49Afqv0MOL7xG8+tRj+etUuNcqMGq4C6vHsAviAYNZNuNihD+4aAjHoDDejrApdNxPN5KSzVCzzAQp8XLlejW5u9ggGxbgiDaMwwBmGzOMuelnk1fJDNx2Gvfw9wcdq5s2R3TMpotumk1LZkOkbjTwQ01ltWjI7R3ivEL3r5LUrH+w6C8owdlRyNnRjMyHnGGDuWvAbzOqYtH8YR3H6OsvciwuBMi7KusTjVyWHvk4/J/ib2NwMsPsBudFuEOeWqL7J0DimnnFEOEHkX5KD2zba8zWD3+Iodr6YhDmWwSipY2/gQodP6STKp2WqlWroG+UZTVLXq2DrIp8cKcRybED0P3k4oqqIRUgmJEHNBJZPViJ3mEBiXUDq3pCIiRlK21FYlxCykt9jq/lwezSskzmUO/VeLFn0B9WSZdFhv6pUAAAAASUVORK5CYII=';
string public constant helm36 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAANlBMVEUAAAADBg0vNz8eIShTWF5EUlhLy1guMDZ+hoy0byrhnjzN2NxienwZGB+MRxwSExr/4p9pKBJsLoVuAAAAAXRSTlMAQObYZgAAAQpJREFUeF7t0ctqBSEQhOFUdXud28n7v2xKEzibWdhZJvMjCI3fCM7H/+wJ6m60Eoo7FmZ34fCKmy/WFa1j97iGMH6a+FjDOlYmMiZTF9Sxin1zL00siSemVspxlG0NF99q9W4UVF1UszXspXit9UXuafTyqrZahFf0ofo3Zu5l6GmXtHjjxCRzK+4uuxpOsyysmHmegOxysGyUNMvaTDSGYYmXIUPXh7GUXci/wxsou2Vwj2IiT5wBBm+G0QC7oEyYQAgnCu3jb5lwC2HxgcZCogXx8AmiBHlGseJcwrIB/Il3Rovh0+L2jT/NQIDDdtmYbm0+NVuXDYbBBV8dsuEwE/07PT09PT19AQUrCKizxpuBAAAAAElFTkSuQmCC';
string public constant helm37 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAIVBMVEUAAABdBy2FADvGRi/HakXfezrnl1D/yE3/02n//eL///8q32TyAAAAAXRSTlMAQObYZgAAAOdJREFUeF7t0UFKxDAUx+E0J5ggFJfxleJ6JuQAgidIKFkLRbpVCH/IAWR6Az1Br2kYjcW+MODGVX/L9wUeScRPkkjkiLSo1ZnLXJpTTaX9HndeMyzTco7Vr+y4yrBy1JxhChv8mftl5cSX3y+2sE+vFR7KvYcaY3CiuawZsGX5xe2hsP7Nukf0+jaztAFObvgkAX+cHvJqC+huw55Cisf5iciEJZLdcPA9lsydRYJjz5oRsZ1HFQAkOPYjeFHT+XlUNwHgf0J0N80f7+c3RTlRSbXTo1IFeE2+2LXaw1VuxH+0t7e39wkyjjnlIZ/jTAAAAABJRU5ErkJggg==';
string public constant helm38 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAASFBMVEUAAAAgJB02MzxUTltrY3V8SheYkqDE/1pr/wgdHR1bPSa0bypGQk3olEA2MztAPUWyrbhc5wBmXnFFLRr9/4tOwAEUFyB96TgLCgM5AAAAAXRSTlMAQObYZgAAAPRJREFUeF7tzUlyxSAMRVGrp3Xv//e/0wjvQBkmXKCKyam3/LtmszXnvK7bb2j2UPdt6zlsJQMi6b5L36I6ywVIp6r0fX91HJ8q1dd7yIpUQGznyUVYtUsEX9ew5BiL1FpKBAPA2ohOBkQsBTGEnwdWHwb/YGMN4nQAMUBKD8as48MsEYCZHVEMAMdtBHYPyxzEXiPAEavrIEbHrRGzJuYe0Dk11y9lVWOK4a+ia/aSEdYIBvhaUtPxLBFG7JIh2X3fNm5i7BLCF/BX7d2O2oGR9T0MddigfkNy+1mC5VJkaInboZ0XkfoZNt7nbflDzWaz2ewHVrsK0WrfnxMAAAAASUVORK5CYII=';
string public constant helm39 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAG1BMVEUAAAAaEQY2DgBkGwCGIwSuPwfnXwv71Df+/b2198ebAAAAAXRSTlMAQObYZgAAALBJREFUeF7tzLEOgjAQh/FTeACpsisW5hKjOhID6qrpuUsifQAHmIXBxxbpYuIVFweHfssNv/wPfpmbmCTtuDGo04FTGeYHvVvXNG/0bHX/kPev0UOQXArN1ZTiofrCdS8XN4BFAlFJ81kJRzXtMXCR9zCEV4xUNUcD+yhbXmJB8wBTX+455jMgm2xfnJ3CET1nvtyxNMhoBhbLPPaC7ELzGDwO4PKjYa2PgL/OZrPZnsoeIUZyevg7AAAAAElFTkSuQmCC';
string public constant helm4 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8AQMAAAAAMksxAAAAA1BMVEX///+nxBvIAAAAAXRSTlMAQObYZgAAAA5JREFUeF5jwAFGwSgAAAIcAAGbMYQTAAAAAElFTkSuQmCC';
string public constant helm40 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAAflBMVEUAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAhFBQAAAAgFBRYExGOJiLcJyHzTFD/h4rAMjXPPkJpHBroRUCnIBywJyP/yMjJNzvMUk5UCwp0HBrrcHJ0IB4PDQzsQj3MKSRdFRN/IB9kEhGSLC74XlofGxf/r7H/tbY/CwowJbPDAAAAC3RSTlMAES42PUxXepmZshhUcsgAAAEnSURBVHhe7dHJTsQwEIRhM8AEUt22s84e9u39X5AyQRBxcs9IHEapQ+TLl9+S3bkNp9gV/h/jD4bFvpAhrqjtd8BdwiEeg6HE0AmOBtz5hO9/NMIKlvA3JsKYNoW32gdq4JHe85Bbpga//XoNbJ8A0ZCbhnTeDwO0Xw9pr8K/BThLmrkQAEiyKZyfVtHex/1m0xH7kHB++su+xarqpOGlgwEfVMX797hvaZsu1PnWQQ6A9m1bgWtEamfBggJaVSiKokSjsGDaC2rcLJy7KqU2YueolwlclhJMmIyallsUpbfhaWBxCnZlfRLWo/UtVGCxH796CVHkYzyI4HpifR0NerejHjmt1raHfqYe4yBN1qgVYziA1qYh1MmO1MwxebR58+bNmzfvE609FvUrBM6xAAAAAElFTkSuQmCC';
string public constant helm5 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAFVBMVEUAAAADBg0tFBFGKSBnQjGJZEe9mGKArRaYAAAAAXRSTlMAQObYZgAAAGxJREFUeF7tjLENgDAMBGGDfMwCUSYI8QJRnAEoMgL7rwAIiSqmQzS+xsX5b/oaA3BvNlDQ7RwDV31OQtI3dcyVpO3a3MvqWVrS2jhhKUobMbEA2Y11TgBJh6KDuxJLL2Pt7kOP1t5+xTAM4wCPqwrW/LzCSAAAAABJRU5ErkJggg==';
string public constant helm6 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAHlBMVEUAAAABAAFhYniDh5mosLuui2W6nXXO19vdxqHu3bvSFpKnAAAAAXRSTlMAQObYZgAAAIxJREFUeF7t0LENwjAQheHzBnkgBdIeXoDYUXr7FqAAiRIJmCCSJwgzZFzi/nBDg5C/4jW/rjn6d6ac2+abvL+V8ykvQLpuBhkw51WyWR7YxMkGdHOjnb/OMYr31+WpZdPe/RjFDheQBmzHIM4dSbWb+NAzB9Y/sJWUZNXrGVibcwB9gELMAPp5VVVVbysAE15kqV30AAAAAElFTkSuQmCC';
string public constant helm7 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAFVBMVEUAAAAoHxw2HxFFLyJdPy5ePy56VUB0OoV3AAAAAXRSTlMAQObYZgAAAJZJREFUeF7t0DEOwjAMBdD4BjiG7kkl9taEA9BeoBJi7/0vAVU85nuBjfzFkp9iWwk/SA+dXB12BzkWh+W25A0qP1TXF1pOz4+uOQEWPbKg6ec851EVsSRmzlray2k++jwinuoMxLUdwW6ykr7iqc3RGOwWY3C5WPvSZmvT1ec7GL67l9Pmc30dAQf781pQBp8p/Ft6et56yw9dvk2U+AAAAABJRU5ErkJggg==';
string public constant helm8 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAFVBMVEUAAAAuLi5NTU1zc3OVlZW8vLz09PTQ6SEyAAAAAXRSTlMAQObYZgAAAHBJREFUeF7tkDESQDAQRblBlrjAGnok+rAOgFm9xv2PYMwos2k0in3tm/eLn31GySFpixYS1m7+MqK2Cy58irHjhviQ8pKpZRLzYkJER6uwjXU/eMTRxLXvAMDtKOjwZABzF19/qyqkjzXZn1EURbkB2CsMU+yyQX8AAAAASUVORK5CYII=';
string public constant helm9 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAElBMVEUAAAADBg1jboOJlZ+3wcX///84ZTkDAAAAAXRSTlMAQObYZgAAALRJREFUeF7t0sENwiAYhmFIFyilCxTwXoABtHxMUNh/FTHVePix8WK88F5IeAIJAPthPfEGPhLlSwVRe7AlPNmqITpVnUeyXFrGdcreu5FxUN6EjCXrACtkpgyVYtlNyDCpwUGXULZLyggJhCdnssGWAGhEwlwZBEQAUWnLSGJeB6yMebeIkdHm5+grNpLfsV5O3yS0V79mcbr58ImvxwFym+fbwXubuT3Ynn4ncmX/q9fr3QEwyRmLpRsTnwAAAABJRU5ErkJggg==';


}

contract Mainhands1 {

string public constant mainhand1 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAIVBMVEUAAAAAAABpLipvb29zNi98QTV/f3+MWUOXl5e6urr09PQEjFlPAAAAAXRSTlMAQObYZgAAAK1JREFUeF7t0DEOgkAQhtGZG8wsq4aSxMQaKygpOACF8RwYL7CxgZoG6CzXU7qh5t/ORCNfMc3LFDP0v21tqWJj0XKEzqYqZv8QwKZuu2nqcsD2mhZONVlf11znIRCvMpfF5HNCJfPQD4KUy9dzfxa8PKoeM8Spd0S2Asr9KIEbyI4Ct4g7CWBuAtgt8x7nC2DShevAOD5FmQ5ZlHdVlG0TZRb63viDh5sf+QvuDdejHG8Nv5PXAAAAAElFTkSuQmCC';
string public constant mainhand10 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAJFBMVEUAAAAWFhYaEQY0IxU6OjpJMiBMTExWPitpTDdzc3OVlZW8vLzFCjmwAAAAAXRSTlMAQObYZgAAANJJREFUeF7t0L8KwjAQgPGk9AEMloKdiuLfSQT3gk6ODuITFFLfwjcIlEKyBbr0sopg7+V8geQWBRH6rT/uOI79tqEhQWqsRxSfwBLKwfXh8TgzDm1YsTeo/HhMMkR0nZ9jhx1iX4OfeYUIL2jB+rl0+DRgofWzbFwDoEziZ61lA50SRWBamxps6Cm81FWt0hAzoaVKqyCzVIoJhpkLNnkUjIgfcoqj/Ud8JZmtziQv7yTPaR7Ty6Mt+9emO5Jnl4LixW1E8QZJXhuSI53Tp7Mv9AaqdD1c7WK/5gAAAABJRU5ErkJggg==';
string public constant mainhand11 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAJ1BMVEUAAAAWFhYaEQY0IxU6OjpJMiBMTExWPitpTDdzc3OVlZW8vLzg4OCD2IJXAAAAAXRSTlMAQObYZgAAAKhJREFUeF5jGKFgFIwCQQZBfNKSggcdBfDoltwoI4BHVnKhNE5pQemFyyZOdMAlLTZl5+xdExlwAcZEt1W7HRlwAsHMWSuXOODWLjZz5uojuKWnpcwRdMFjuaCPAANuaQERKQEGPEByI15pRmcFfNJMphRJR+CVZtAIwiut3oRXWhW/tDB+w5kMGIYqUDLCK60c5oBPWi1bAJ+01m680poz8ce4Eh38DwAdJBy0VAIGPAAAAABJRU5ErkJggg==';
string public constant mainhand12 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAJFBMVEUAAAAHBRESExoeISgvNz9AQmREUlhienxjboOJlZ+3wcX///+gYzCNAAAAAXRSTlMAQObYZgAAAOtJREFUeF7d0TFOw0AQBdCZG8wqFmI3DRInIJzAICEuwAFoICfANR2BaqUUsVK5sfB3lQ57L0ck6vkNEgh++/SLmS8/HuMciGmQSOrpICn75fHInc9lsPRhHqeCHCeXlzOGxYYxqgufAWzr7HGIQH8Lt64R/Xrv1+82/fq183TYvWyfosdpBoYmZPewMqOx4PJY8GjmcQHwYEKZTYJ3n7WgzYyn9pnwOLXhphZ/0Z2d3LucShbCOnaMZXmgrCbVkUmq+r/ylTFeXFPWy1/kldCcyV+Nnn/nL6erzDi2HWPdc36jLClTjkZZv/gTLUNOIqK58JMAAAAASUVORK5CYII=';
string public constant mainhand13 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAFVBMVEUAAAAA/+AXEyhjboOJlZ+3wcX///81FybzAAAAAXRSTlMAQObYZgAAAJpJREFUeF7tzSESwjAQRuFdg96/IpqUoQcIN+i0F4Cmupuhuf8RCD4bg0Hk2U88+qt6vZ40lQ8WYpMvB4hgsoO2GIXFmTx4ELIYdx5miKrA4s1DAeWq8hCDBxxQZaRzKS5jnTXlrbgEqXJOe349wm22ePz6WmdyWcf9XPYgZHqM2RPZvr4L2z4lITPG9Gww8d1Ti6/SYqf0S70PQKsaNTddt8UAAAAASUVORK5CYII=';
string public constant mainhand14 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAIVBMVEUAAAALDCU6IiVAQmRUNCtjboN1SzuJlZ+UZkq3wcX///8SjTBCAAAAAXRSTlMAQObYZgAAAK5JREFUeF7t0DEKwkAQheHZG8wERGKZG4hY2O8FVMKy1mIfRJZcQGxTbBE7C4vNKcUDzAuypAj4tx9viqEf+2dEgMoyNEBTH1jXoY9rVU2q/VEfr6K7wXG4wnHbkM51iAxvdwTYtXtwe5QjA+4z+Q3Zv2gqLsf4xIBNHqcR9pCHLE5Z7N2EvKtFWNVie6isysVl87ifNTaVtZUV0li+0TxbuAZx2XaIzZMJNYOvfAC3szVWWs8c1QAAAABJRU5ErkJggg==';
string public constant mainhand15 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAJFBMVEUAAAADBg0oAhlAQmRfBR9jboOEDRyJlZ+3wcW9KirrdmH///9vErs/AAAAAXRSTlMAQObYZgAAAVhJREFUeF7N0TFLw0AYBuA7f0FCCHWUGuMcQnEXbO0Y5HqdpVy8sWC8QKcMkivZSilNRzfdAg6B+3OeDk7ffQ6l4Ls+vB/HvQQK9X2fOHN2VTa92yPBVdN7rvK4bZ+0qXxXWR62pulDHy7fm08xsXXmQbxYGaO1Nh3PoNt5863aXl8CHC9Ki+tdacLaA9/dinJ92JuqB1jI9n2Xa7lvOg2xTWl6rZsOOi53ix/Vq05Bba6UtqkbkMeMidxyYSqASTyabktdM26CAuBoJr6Vzfswgwa701opVbx0owTiiWKWuawewMkvGbflWXsND07TlLFUvmUETsDHov3YeA6m4bOQ7Ya4QofDqbTsTiwfUY5vMY7iC4yDCGOaDgnGowTlGw9lfgyHNcqDV5TPO4JydTqm8yXKKsP5hH9KGcrEJ/81Hs5BgnL4B2coD1Cm8wTl0jtm7gLn38G+AM5Odt8dbwPjAAAAAElFTkSuQmCC';
string public constant mainhand16 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAFVBMVEUAAAAaEQY0IxVTLQZgIwJ4QAaZXBEQ1NguAAAAAXRSTlMAQObYZgAAAKRJREFUeF7t0jEOgzAMBdBvTuCiuHOExA3oAdIq3QskO6j3P0NVlk7+C2JA6l+fvq1ExmnyT8f56nsTAamRDjaPm3Xj1WHTL8hImCy3ZVvhcdjG9sVhyco5As2U4CS8BP2gHksOrV8GrOSkhPNMFDInUFbKOVIunKsytnekfOd3mLDj2Q+lfOP8XMASRs51158PvD3xdofTxiLlC2cZD2S0R/EvH/ZVE7W/42QBAAAAAElFTkSuQmCC';
string public constant mainhand17 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAATlBMVEUAAAD////aM0NJEQZbGg6lDx2tQEqPFBUYFCW6bXTRhItyCQraf2fwqZaFOkHgiJDgkn3WIjOsWjyvXmXKbkzMXVYHBRHiioRDEgn/0sew2P5WAAAAAnRSTlMAAHaTzTgAAADbSURBVHhe7dI5jgMxEENRkVVaevE+6/0vOoUe2EFHFh04EfOHjxKUoA/vxwMPPPDAAw+cUgKJtN+TGDSjiMP+yjjsQcWgHb6NkHDY82cxqnidA0PD5/U0hRaxfWxpCa923dKQXjv8/K9B9H6S8Ke55NBsRBeORXqaSnbSG/vx8VZKru61H4M22ZJzrf14S9NqzAUMGmnLEhb9GATdvUW4G8fYNgsJg+1hSfTh0Lx3WyOexvu5N6r4q/7ImPYalm8GLRNJw3R/CdcLNQweWbN4c1gwXyiWQ3BX1vYH8JsQjlFDP7AAAAAASUVORK5CYII=';
string public constant mainhand18 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAHlBMVEUAAAAKTxEYxg8aEQY0IxU5mzRTLQZgIwJ4QAaZXBHxXBzGAAAAAXRSTlMAQObYZgAAANtJREFUeF7tz72KwkAUBeAzZNJP1OkzK6LlaJCkHBcLywQM2KvYLiyL2vo7L7Ds6+4T3INgJXjaj8O5F6+SdwzVT0fZNkxV/2QY5xOZE6Ce9ggrZIQ9YLOgpfkZ1ODam+UCT4waxVVHamvXZvfGiX+5ZdsNVuRl3OZIRU4WWwclv3YvGoCwV7XM1d6ntZf5UBT2S+Qyxp/MyO34Pf4g23/eOsYhJZeXRw/CycHDEN55gPCtpfzbN4R1Y2rWHtLttAsWtaasz5wDXjTJhfMGNFV4hjUfx+K5+hwP5B+8oSB2SjRDXQAAAABJRU5ErkJggg==';
string public constant mainhand19 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAKlBMVEUAAAABJQIBuwgBzCICMQMaEQY0IxVJMiBWPitl/3NmSTNpTDecbE6l/6bqIlETAAAAAXRSTlMAQObYZgAAAIRJREFUeF5joDcYBaNgFLiIBuCRZblrfhSPtOTdyTV4tMtOL8rBLc2aPP1YNR7pMqOcbjzSFWk1rXicFt7djc/lrKE78EkzMERsxSvNuicAr3Q3XmmGaPyWh+O3nLULv+UVeKUZwlPxSoclMAxiwIpXNiwVv3QpAwUBx9qOV5ohlGGgAQDLlB0An7lKiAAAAABJRU5ErkJggg==';
string public constant mainhand2 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAAWlBMVEUAAAD9Xz39l039sE0KBgJgIwJ4QAb+63X/1GX/8Zz/++C0bxxTLQYoDwr+2HVPHhR/ORODTw//9sGjSBhxJhaVOSb/xFGuZhwqGgZrQAv9d01+ORSZXBGdYhpLRBctAAAAAXRSTlMAQObYZgAAAMNJREFUeF7t0VVuRUEMA9BxMnwRHhb2v80qXYJTqT/j/yMHwp9mZAROy+PVpdWlfZDWLi4urQ4NFZpCVEDaD9GHgrSq1TDBAa2l/O4Mpri0ZsUKYuHazr4KVMAUn70VXZWZurbeTYM5WOmGK/UriDVXIf+spVVwNtzuENxvLH5ek1kq2zVtG4uX/dssid/7sbA4zscnj1NKMUS2OacYJ16/8heNU57N0nPzF7NiXv8bnm1nWjN2hH9W9ODs0cmBg8eOhB9HYgZjUPAN5AAAAABJRU5ErkJggg==';
string public constant mainhand20 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAAZlBMVEUAAAAYFCUbFABaZ3ZfRwBseIfa5uTeuC3m7u30/vz+5Qj/97Q1JwBKRVgjGgD47pf6/wBgbX2Bi5hXCgozLz//wMD/5gCcdQBqUACMlaBAMACoGhrGlADLmAD/aGjMmQDMpC59YQuZuOPEAAAAAXRSTlMAQObYZgAAALRJREFUeF7t0UcSwzAMA0CS6sU9vef/n8zETwAPOti47wigaMvZs4c1dmINTrDm2UVY89X5iON58qkDsftjhjHem93a+6DoHTW9vQqnTvFZsdm9U+o0+ACPdg1He81o33B0YkVvGKt6rzj1tYKjRx8vn1IR7Gw5xUcesKfNu/g8FBDbU8hDTwg2swl5hCwJmxBAS2KDfaL2doMtiT2fhdCICG01AsNlOX5hfH8dLd65VmqUPT/XyQoZtDVQqAAAAABJRU5ErkJggg==';
string public constant mainhand21 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAFVBMVEUAAAAGAwYNCQ0aFRctKSpIQ0RoYWJ6BEtVAAAAAXRSTlMAQObYZgAAAN9JREFUeF7t08FxxCAMhlHcgR3bKeAXFICEc/cKCvAuSgnbfwlJAWKPmRz2uz5GGg4Kf9u7d++W317w/rS6LPOIP7WY9Tx6sDOAo2v2d+wgEaDUmn0GMbGATpeZBBACfBY0U4BGXKzbjUbM6duqqJDPkGaPViVmn9vTei8SZ5+vZk0L+bzh2uqyVhSf+YznR1Soy6umdKGz/68w6XE/TEEDfqRm/YaUfb4jtQocs88FiJGo+xw2YkDiFQbMAuGvc8DrjUiGs8OkED5yGHFhFJ3DqFWLLmHY9Kuv7yj8h34A0NwtVjD5JEoAAAAASUVORK5CYII=';
string public constant mainhand22 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAHlBMVEUAAAADBg1XWqFjboNygMOJlZ+as+a3wcXX6/////+4leshAAAAAXRSTlMAQObYZgAAAO5JREFUeF7t1LFqwzAQx+G7N7izZZuOhr5AhpL5Ag1dRTGmo4oQXTOYQ2/QNUMQftu+gHQZMhXyWz8EfzQc3O3ZMySbLzYrmfxlPu/Xq8WDFmpPxqNmak/u1wZPNwJkzpqr216KZ5fSVPRa5+3wkWLQpcaYS3EpdvNS51330UknTc4ji5O3tcHqWGLfV38Vs+pFfgPjkerL1ccYAIYGb/47CBJDrWlfvJy4I6iG++bJza8tzrdPcjEy1JuKhy7J3GDUA2DqBBpNBPhzbjID4DkSGI0BrNwdFpOR4L+Gs80nMvndZvUPHA8YbEaGx/sD92A4WMM0MT8AAAAASUVORK5CYII=';
string public constant mainhand23 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAALVBMVEUAAAAaEQY0IxVTLQZgIwJxBARyISF4QAaWDg6ZXBGwCAj1Ojr+yMj/h4f///+/a1ztAAAAAXRSTlMAQObYZgAAAOpJREFUeF7V0LEKglAYxfGjUIQuFsKlTRzqBYJma5AeoN2t3QSxJ4jaIhqaJIhClxAiskcIeoF6mMam7ywS0X/98XE5Fz/ohEoZqFBGHzdLsLjiCMCUuZGe6PSUD2sYBWXz6oqoB0ZeTxyJO9hnmEisb2rjLJ2sBFbBfnlGPZTYmb+eC116XG2Xjzt2Etul+XriEAus+emtNC4y50A+9SBkzwp0exYgnWeufAyo2Pcswn5EFFrkgbJD2eccc04oqzXnAVjtASrMHlqU+5xHK7DskHNS6c97nKeU4eJvU3xZk7MWfpHR+hZ/egNoIzSQV9WxrgAAAABJRU5ErkJggg==';
string public constant mainhand24 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAAb1BMVEUAAAD/NgH9/wH/igH////a5uT0/vwbFABseIfm7u1aZ3ZfRwD+5QjeuC2Bi5j/97Q1JwCMlaBXCgr6/wAYFCWcdQAjGgD47pf/wMD/5gBgbX1AMADMmQDMpC5qUAD/aGhBO1R9YQuoGhrGlADLmADQL4H4AAAAAXRSTlMAQObYZgAAATlJREFUeF7t0reOw0AMBFAOyd1VDs7hYvj/bzxRBwNuycaFj42qh5kRlp7imOKHGBM8oP0jB1uoRKlJBOsDuAv2dmBhjk7/uAB8XxounFluWwUKh94NVW21dbXM4gnezVWyZDtWNerBw4UzCExQgHy4Miy2WIXIjTnVArqlwoVnRsqy9jbremaiuCzR9oUxV7owqpRYWNn/wgTDgrOoChHUyTEPS2+1YKHA/65SDQGBCW68ROcsDFZQECvBrFfP1puFWCg4WhhmQ71TFmFCFLMKKDpaDEdH59WGe/9h+LH1XhnHRufDNAVHb1P99jpOEVy147n+7o6x6OZlTN1xDOL23HfHA0VwMzR9tw1ZKrum74OWStu3P1F7vZqNBu/3haJXSqGnvRKGm83pM4y/3k9tvPM00WPu/34BSTMNj7JgBh0AAAAASUVORK5CYII=';
string public constant mainhand25 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAGFBMVEUAAAAGAwYLBwoaFRctKSpIQ0RoYWKhm5sepfXIAAAAAXRSTlMAQObYZgAAANlJREFUeF6t1D0SwiAQQGG4wTKSWEu8AC45AP71IQn2ThJP4P29gPMa3far9rGD+TLO0NiM7AfkZhRQWyfkDblhbrcr8pqAbV2OEXh7dpm4BOIX86OECFn2z4CLLUEEeA1OKGrYAfstHIW6nKIhPkeLfHDAtUTKdi9Kx9iUJMRjEgGe1DF7YD9rD2xnzYa4y5StdtFRl46ymfbC2S4/ZRvVOehS1NOTFtUBeNJEfNU+I98FOGnFxdOKfFv4cxoM8VuImwkZiv9jbBLkW2TOyD2GMS2zz8j2H2U+Q9cojz1SoocAAAAASUVORK5CYII=';
string public constant mainhand26 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAAV1BMVEUAAAAHBRHU1NRwcHCenp5HR0cVFRWxsbG/vb56enocHBwpKSn09PT///8nJyd9fX3p6emgoKA3Nzfh4eFjY2MhISFISEgbGxsoKCgjBgJLS0tbW1s0NDQ+M12xAAAAAXRSTlMAQObYZgAAARBJREFUeF7t1MeOxiAMBGDGhZKQ+pet7/+cG7Ql0t5srhn5wOUTIwsR/Lly5Qr+DrBb+jFYJ5ht/iWoRg3ecJ6rFecTgCbYLl4RADQEzTasB0adpgpAiTJstSFEVOvttVmxYUhKmeimQiRsXJik3MLktNT6sghHI8Z7JuBRiJmjGaMAeCMSHcfRjD8BFErMOqoVP+O3lSRqxXovRGk5bFqMNmBEKeWQWRYgmPFdRXI6bLAGMWpWyWid7RoqbZp16FnbDLNP45hBmRBcQdTzN/J099uovPa0JreeVT/8vZV77EboWFhH7VHdNiAOfhxgslfQY+OwP+HWzH67+9824qNTbx29dwQ/5h5Mboz4wv/0F0nXCDs8gAIEAAAAAElFTkSuQmCC';
string public constant mainhand27 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAANlBMVEUAAADfezofDxL/yE05Ih7nl1D/02lqWlHGRi+EeW3HakX//////eKaQDmqopRRQToHBREGAwaiMolvAAAAAXRSTlMAQObYZgAAAUhJREFUeF7tz8mO5CAQhOGJ3Ni81fu/7AS0+k6W+ujfAsmHj4R/f9vb29vb21td68vwrJXq+Q31yeP4qQLrgBx2yuMIKCKAZ5bALmbVJ65cBw962C42EVSorkXNYhuLVNDp3CCy+CbuXgUKHZRDYSJisYvPvu48iLmhShWJ2MWngrg0VgZQkcD9VIWW67pwtVsBzeCuQxuuVSv8EQ9P4LvNaFspxBGfTewdozQQg/YuOjHtHnZog3KsotzEkCOBRdvQUooO3NzFD9/GYaCbdh5xQ+L47OIebmjaGm2bdv/J1BFGqtquH+vhSVwamw+egz8JfAjKIKeFSN8fTOyHQ0eZn5qYJwZTHyFqOvjBpPsanHk0TEVtDfZPCnu4CAQGse6dNjlaxMzk99LJ0YTsXHPTupvR9ryl7j7r57J5/b1duj+0X2rSv+0/clcRKZqIe0EAAAAASUVORK5CYII=';


}

contract Mainhands2 {


string public constant mainhand28 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAALVBMVEUAAAAAIzMAR2UAmdsYFCQaEQY30P9OVl5n2/9qcnyAi5iirbPa5uT0/vz///+bK6ViAAAAAXRSTlMAQObYZgAAAN9JREFUeF7t0DEKwjAYBeAXJNBJ2gtkc3SIvYBHCIKIdRRKJjf3giCd3Fy8QnHsovYY3XUpnXoGaYc6+Od3dehbP14e+UFlyJAhgc+gCNSLUdVozekpdD+umtoeaE4SiGoXVw4eA8qmtZ252qJJ4zCcGteyrcJgcXWwiNNtAPkoHVwftQ95d7CyWx9AlM9prjQ8D7IwNLflJ2T2zSOMxFGjbWNTkr/ulrtx6mZKows5niQfzgyxrfpbR2d858PrPcGiL0iDP45kdZXz5cywfGEZiwnPBVuPrvz4jWUs8Ttvu7I0o2y+fNAAAAAASUVORK5CYII=';
string public constant mainhand29 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAG1BMVEUAAAAaHAAvHABZIgCJNACwMAD3QgD/kHD/1c6w1jDFAAAAAXRSTlMAQObYZgAAAPRJREFUeF7d0LFuwjAURmGb8AC+Du0MJlHXBhNYG0HoSpCa7E3bPACh4QFA6mN3r+TDwNZ//Qafa/Vn4xdFG1+ZL8jRzx75fIOvyB0/vj7vmfHy1XC5g9OhRz7h49HngNwNz8TNK7WN6nVPvFsdKT332Ja3HbWlLaYnzVdPXHtqi+pFS5e9OWoble4JWJeH7xvpR0x31DYp3TtwXLoG0+3jFHgrD8B6WX20xLvqAG3zUgpKLyQ3EuZMJpKaIHuJJQmy9iJ2E2ItmbhtFiyTeLmZBcusXzgxYXYzsfBrYvRU/dNpa5ATZBVXzAWyzQ3ynNtE3b9ftzQrBQgzLsoAAAAASUVORK5CYII=';
string public constant mainhand3 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAFVBMVEUAAAAHBREiEQ41IBdRNyRxVTSii0/bTTTMAAAAAXRSTlMAQObYZgAAAHNJREFUeF7t0rERgCAQBdGjA4QKgCtA0AYYxAaU/luxAjcmYNM3nyE4mazVamU2S+zPTOOzvRb4enol7ncGbjqa/ecjvg+wRvybT6kDO40D2Gihx8WVKwCb2ILgPAvOK3LCtbh95nPckI+ArFUoz2ysTN4HLKUMqqviTQkAAAAASUVORK5CYII=';
string public constant mainhand30 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAAeFBMVEUAAAAHBRFHR0fU1NRwcHC/vb6enp7/HwAVFRX/nIgpKSmgoKCxsbF6enojBgL/vTb/zsXp6el9fX0cHBxISEj09PRjY2MhISE3NzcnJyf///+jFABbW1s0NDTGMR1lFQrh4eFmHhQbGxsoKCgnCQSDFgdMEAdSFw9ELN1YAAAAAXRSTlMAQObYZgAAAUFJREFUeF7t0rdyAzEMBFAuAKbLwYrO+f//0DipcweysAthtn2zO7xzt/uXGWtwruv9m+QKO8aYK5bnGIvroeDCAbtlaPeodj7DbMccs9M47Iwa0kInaxTLzoo9tDbG64ozbMUzXL5+LZC3YWrnMardASBmb9qNETFOU8wv75sNNgylfuIpBuYgxgebOu8n74ULbFCrzgcJQZIRD/CM4dCziCQj/v786of714E5UNM0Njw8fTwiPvfciVBDNgzcJWCzoQtkxbTvmbtFbbcYrUODpe9V+rAAzoz3FILv1DrrISXyFDy2zXYNCltKrOoTbVlPZRqalYRVF/lE0l5s4Xa15c1zzWou1ieih/LdJDW2ZVQ8WMXshtQWV6/l2MFkb4cam9bjHYq1SLk9lv/bSIdK3VbsPsKVY6nBXIyR3uSX/gFO/gxCOph57AAAAABJRU5ErkJggg==';
string public constant mainhand31 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAAkFBMVEUAAAD///8AAAAAAAD///8AAAAORTIQVz4YDxMHMyMqd1zrh7Mog2MZEBQZa04YblAEHxU4pX46nntBEyhbwZ1qIkIYEBP2qMv/y+JTEzAFJhrSRYPlOIVGJyD/f7gRWD87nHoiBxMKOCgORDIHMiMPRDIaERUPRTLbZJgQRjPqXpwGKBwwHBgIMyT/vtsINCQ7zPPsAAAABnRSTlMAAQECAgNDwa4SAAABL0lEQVR4Xu3Wx27DMBBFUSqJp5BUr+5O7eX//y6MDWThTaI32wy0PbgAIQzG/Tr/82RzsF7jNODxkD4DHz+mANu272Hdbl52ywnE18mOoJVuabCCMLtlHAs3BhvhsNxEOCxa4OGkOeL4VcUZyjh2QhZseTCKjQGXeFqYSzQtxIyHiSOOlWONYyqiOIM2YCXCNXFtee8yaYxLddSdYLhSKusDhtl3WtaDQ2Z43hedeghn+SftfcU5VL4Y7m+5ksFh6fdHyt+2mF7kdyTDVqDy5SLX4eEsvP4jzrKErzLsqMtcJueHlWEC6OUbjC5MgFY5gamf5jU1DZ3w2O76mZaUWH6uMjdXs6/liDfLMHsVJr1KWrwEYJEmHEU8C7SGV8r+aBEtosoKYZdU0pZT4WS/AOLuEqSMfExmAAAAAElFTkSuQmCC';
string public constant mainhand32 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAAM1BMVEUAAAA5xuMBAQECAgJNZbTD6/yP0/8WFCWIiIhERkcvLy////8CZotNm+Z+7v9Gvf0CDD6BljT2AAAAA3RSTlMACd3T1tH+AAAA3ElEQVR4Xu3TSW7EMAwFUcefpCb3cP/ThkxygZSy6ABd8PZBMCkdf9e7dy3D1C0gbr5pN/COtbhhHHsW47QUt0gcQXHtyRuftWOcbeEIjgPjohursptT7OFOb0nzLxsUl6U4yvJxV/Cnw8pC7JYUY0/q3oj+KI3fRksbgbHFD5YQNpk9taZOgJWZVPjX2rTuUh8Eu+l+aY0xwchuJmkMTQFspp6UWOmZdhB7ai31lVQHwb1/H8vwqGMZro7/nTCcyo/iWraw7n1wPOe8HlBrjGtRfJx6XEsH7SUu2yfJbQoXjUWIqAAAAABJRU5ErkJggg==';
string public constant mainhand33 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAANlBMVEUAAAADBg0iEhZEUlgvNz9RQToeIShLy1hqWlF+hoyEeW0uMDYSExqqopTN2NxienxTWF7///8epEkyAAAAAXRSTlMAQObYZgAAAUpJREFUeF7t0ttqwzAQBFDN3nSzneT/f7Yrq9D0zatAQ0tHWBjDYRbJ6S8HwNNr0N77F+53xGx9akMNadTvuMbw8YyPGL7XnhPNoEfGBqYubaRMi4sefWjKbSaftuP6PYE+i/eslIB+v4xrrZR10L1lVfIPji/rg/JZXbLjegQsXFN+ONOx19F7GXcApI+HlrGpAuiBqX3soj53yVq0zrEDmlwWFPc+dcC69pCeWAkz17GdupWmNBQgASxioL35OouFHQc0CzXa/TERDlnXJkQb+SYiBqRQgM02yGa2TRrlAANrdHC2QcMeBhhYDICEsZgJbsIiwnHsDGzMNw7j+aMwhJlfOe1p45zF1miCOeZFDQHbjbFW7BjCsqLhkfUDS5it78D8O7G8DdtLOP1k/vOee6bWGr1giy5qQoEqrTdrWca+Fm1y+EXfnQ9TcwrSb9aQWAAAAABJRU5ErkJggg==';
string public constant mainhand34 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAAgVBMVEUAAAAdDTU4RFFKV2VLVl9TIZ2YbdexbNTS2eHcn/vu8PNxRrGAi5iIXMiXoa1EJHOuuMUqNEHG0NzHhekkKzPg5OkvFVRlcn9kb3tFMFAjD0GZZLV+i5dbZ3X14P9/jJtXQGOFkJ1CMErSkfOWorJdOXB9O57hsPqbWrxdRGrsx//akouDAAAAAXRSTlMAQObYZgAAAUhJREFUeF7t08duBCEQBFCqyUxOm3ed4/9/oNmxpfHRDZLnsn3i8lRdIMR/TJNjf7BPwp+z9hefgk2TnhxxRmeXhu2Mddgw3VITWidg6y/eRmx1RrIdNsmdoQefpL9x4Q/JuC5MBnZm0ZaJtQsL9uzOIUTcLK/3Vxnxe1EFRNwwkzFjW5moD6FhdYaDwF1tB2MgZs0YtBHTgxu8OSEJj/QcvN9CYNqwsKyBeqQ2+K3CdOJhili3o2xDUHBbFhZQJaD6aSQ4pyR4WCpJIJoClDpDMLGkDqT2FMDGURM69WFf1AQ2FujQPR7fjvcOZ8fVAHZ0Te7R9oGn0ZZXvY82ntl2F1VJ/dXxt55VGUMTByXJkKH7ZCugdQ4u0rFAFq5WwwZiJY1qtevWOZhvb7PWWxUQq/5Kn7G3v6Rp6IxkgSG9NKx9ytCvv+0XBfEOUwiWk1AAAAAASUVORK5CYII=';
string public constant mainhand35 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAAe1BMVEUAAAAAAACVlZVLbWMAAABLbmQAAAAoSkEAAAAAhmMAAAAAhmMnS0H///8AvIQAAAAAvYQA+8sAAAAA/Mz///8eHh4ARQBsbGzDw8MAh2MAogBMb2UwMDCWlpYoS0EAbwAB/ygo/yhUVFQAvYS8v72Wl5aBgYFLS0sAVwBfQwtyAAAAEnRSTlMAAQxLYmaqrLPi4+Xv8fv8/P67zkqhAAABfUlEQVR4Xu3Vt5LcMBCE4ZH37p8ZOLrdvZN5/ycUgbotpQSYqFTqANlXDbIDyL8dOGHTH6ydFLPRZiyle7P19ia7pKXhbCIDOCKCyIC1yxJRgRGcdIlZBB/C26JUTDfG0rJlBH4M4EtaSsXuyMhQMTTcW41Z0orB/Sci9A2VUgiBEMp1hvtgehjHGHR29zAj99/WgdEZfC4zzP3YELxci/u1B190K+EJ/zIvtVkPYiwtIfIgeL32fiBHwx3vjDng7nTtvCwR1PcEbrRv1h4cUdyvzq34YUxqOASMUODmVGwdU20x8mDu4HgftoZzw0LdOctRzGV7fNy10XBxshzFdeiKv6jBDsja81bYp+87fvuViZxV6Xwudht5N7VO+nCyap/z1NmDpWHk2R1LL66Mz3YCf0BGdMO8PoNfTYzjF9+Gqhvm5Rn8Zs15RLfjoyJZxvJeV0TMVAcwU8U1AxqQk+nu/h8dY0yMwfN4HcfoNA1z1nWdhjHrmXsD8lfkN7scMF6M+h02AAAAAElFTkSuQmCC';
string public constant mainhand36 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAHlBMVEUAAAAAAhwAGS8AQ1kAZ4kClq4ewNlU0d5x8f7O//94VZz0AAAAAXRSTlMAQObYZgAAAVBJREFUeF7V0jFPwlAUBeBbIOlj621RV3m00bFQiowQKDoCiQ2zVdMRwR/wDGjK1qHE+G/F1eTcycWzfsnLuSePfqUkahJMszEiKqGqxpEU4bxWZLCa+tcca1PVD3Mb+4mPVGLf5pVNOPbwMJdZupwGRbXG1X9YmLUMij3kEwTvh1EpzPZUjIywS16EuJtdX91VimA26XBPBvNssJNmjaPiFutnnOWhwh5kRSjs5q+ehd2Un0Y7ofo27WVC9c29zm8w1xJ9HRrIb8ny4wZ3s0/Vd/g7GT/VmbBLK9EPZNDrtpfoFeym1CZxz68IualN+Qxyk6z+4lHY7aU/WyzXSMt1J+ExZGN7Y44vGFU3XpdbHDjw8Ig99h3YLWJ2J4gt7rKedgnEY68/aROKG/U0O5h1m12CsdixLum/xnIdkX2RyVvIPBbZjR2RO3I3/oMBvgHT7EFpuaoNKQAAAABJRU5ErkJggg==';
string public constant mainhand37 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAJ1BMVEUAAAD//WEAAAAAAAAAAABLMQB+YQCrd0TqlAD/0gr/8Jf//GH///+tXRQ0AAAABHRSTlMAftPfUYV6WQAAAblJREFUeF6l0zFqwzAUBuAXqsGgpQfo1BMEWjp0EsQYanyIQlOnCTlCBw+huKnHEqqQMRgCGTxkKNhbTHBiHapSQyKK9LT0Tfb7+PXLg+HPlAUch4I5XilODKWFhV5Wpns6DFQUBmet9qo14pk47aiMJ2a5PtLCkNr5/JTJRv/Y3ehUAfryJGIqrBk+Wh0vyUEyLUVipgvwWrKvVXNz3upuT8Y3+zWTnKgXczyxnzN9MQvzmgqMIVvxJW1SO1KIVlxUCRZOotVw3gA6Ed/NayfzpYtzvmYSPCuHfDGcK6Z2XkiuZbj6tnbvDzFfouloMc3f1wzvftsNppIB53TbQTj6es7jwQQuEU6f837w2gWM/fUjeWEYTyB8JINtF+Pr8Ok+HjOM/bAfYkwOcTzaLW8HCO/GfJb3Oj3ZfWnhvHcTzJiijqlwkTNQTAuwzk0X7iR3WsCGjvsAV7a42pWbkWTaJiZ7kqvNULGwMPzuH2oA5D9T6yBnNi6OP776MsvptFXaAMaiLIVaEl+VGHfLhJBhfQeTm3MkNT4sTfXOA+ckLiTg1DFz8sjNQd/Jce1iCD6dTHwng+R/zw8G/7m6cWq6fwAAAABJRU5ErkJggg==';
string public constant mainhand38 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAG1BMVEUAAAAaEQY2DgBkGwCGIwSuPwfnXwv71Df+/b2198ebAAAAAXRSTlMAQObYZgAAAQxJREFUeF7t0b1ygkAUhuFlvQE1g2nx8NeqKLXZRPossOkFzvZqdm2TNLnsYL9nJzOpMuPbPvPBcGB/7949iCgJpgzEN81fkzY7MaqHjxKPe5IX11IbIF8e6tDa7krwJNTlm62lE4s465TVQ+MaA6RqQG1qdI4TfVYW37HD3rXmlW7tReERz8I1B9VggyN3F+ccng8jS+X8bp6bF1WrQcKKOcpNv1V1K90n4W2/2VZSJAQDxMVBJhV1b242O0gtySiApacVwdnt1jyZEpzCCMGOYmA3FiPTBfET87V49XK49PJ87eXE//Bgz/5rs3UBPn7MP2kFZdOIVD6IZs5ohuXM/8cbL7PQz0HEftEPI3k2esP9casAAAAASUVORK5CYII=';
string public constant mainhand39 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAAXVBMVEUAAAAdHR06OjpQVVAo2CQMLQxtdGue+2IwSC8kIBo8ZzsYThZ96TiWnpMqeygwKSIVFCk2OTeCr4E5rTUPDw8bEiMcGBMMLgtORj1+h38vLy82OjU5MytwZVlPSEH3jClGAAAAAXRSTlMAQObYZgAAAU5JREFUeF7t0UduxTAMBFAOSUnuv5b0+x8zphJ8b63ZJgQE2IuHGVHyJ8ZZWOK48HbiG3vh6Fv3QzttlZOHLu6i2pzvUlY9lKkL277ywDLBokZTaSlhrROHmrQ9mHu1kMknaGt2WK1WpGovTTZDpCzLimDaIgNE6SWlZRKotmmoqfglpYsHhrTqrXarndUwxNo7QFs0Is1UczcMHbJVfNodG2FQm7NqfJnitBtbjizA4qP2OO1tvq3oeVu87rIbQmCN3NXuD34q1RoNa3toYKtd/9oHOm+MsCA1LAPvmdL4XdYM1oa2pyaei+sNBWuFvXCVER2a8QBgNwMobArTW55JHNoyuW1TZIQleVAWo+dx33/x+PD5weOXwwuNj/3hKLwmLDn/g+sVPE6JxHcTjCPEQGkdz+dRwUWnxX1JEFYv6S5C6seDtkAc0gaoeptvAKsJG1wJSfcAAAAASUVORK5CYII=';
string public constant mainhand4 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAFVBMVEUAAAAaEQY0IxVTLQZgIwJ4QAaZXBEQ1NguAAAAAXRSTlMAQObYZgAAAG9JREFUeF7tzrEJgDAQRuHLTSCofYxqH8UBbOwTxN7C7D+CGzyENAp57cd/nHyuUqnkugpU0+KBp/VcYN7H4Q5w3OoehBqYm4uZ1/WG3HpSk3CtR4VrZuXPjEfWwGzlp5nIPPO8tTmsUbAxb+7kRQ+7eApj2JgsTgAAAABJRU5ErkJggg==';
string public constant mainhand40 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAMFBMVEUAAAAgFBRDDApJNjZYExGDFhWgHhqiJCLUJiXcJyHnMTXzTFD/enb/h4r/npv/yMgpZEV0AAAAAXRSTlMAQObYZgAAAOpJREFUeF7VzyFOA1EURuF7d3AhL3kMbZp0B28LIwiCBssCsDWT1FUiwKKbwRMCyctUEEQNsrJLqEBUINgAdwP3EBIMf4771C+/XfFi1b3HvIvZTQfgyrwpXszPRR+An0x7k3CjvRfz6Q+882JuBg+4esCb0rzAs96PM/fMK+CVNW8W89ImjzFLbg/3Ei+lDwPWy4p8OLoGzus0L8BV51/EMgJOSyPW824GLKn9rMA62ZrAxmvkfIacrpB1UZBnzFvmV0O+ZV4MyBfvQhvfIJ90yLlFTlNkNfmvO54yt8jaMd8ZemZOzCp/sG+SETsUtHQqAgAAAABJRU5ErkJggg==';
string public constant mainhand5 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAAVFBMVEUAAAAbGh8bFAAfFwIjGgBBIgV5gYuSkpKaoqyzv73O2tjPz89qcXva5uQnKixENQpERETq8fD0/vwzLz/ExMRXY2dXXWW+z8xfZmhjNQynsrFmZmaCLjYsAAAAAXRSTlMAQObYZgAAAINJREFUeF7tkEcOhEAMBPHkSGbj//8JL9hD9wGt5LqX3OXhB4qiKIowbidsyYQtqRByyCtsS0sLLj8SF71uRPTCRHci+o9343YozO583+4n9e8ig0F3h1ykonb7vGJ16Okj7g6tHr/RWdA1l+tB2cyzs3YAMcCjFevfEyH7iTht74pWTnNQBJwNSpzpAAAAAElFTkSuQmCC';
string public constant mainhand6 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAG1BMVEUAAAAYFCUlFBRseIeFWUaLlqWirbPa5uT0/vzAlmiMAAAAAXRSTlMAQObYZgAAAF1JREFUeF5joAsYBaNgFIwCRkEBvNIRjXilU8sF8EmbhTcyMOKWF04rF5AQwKs9XACf9op0AXy2lxcy4AGipXjdnoZXs1i4AP5gZSAImPBLqyjg1eyCV5pBiWEkAwA1VAruYfenCQAAAABJRU5ErkJggg==';
string public constant mainhand7 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAAPFBMVEUAAAAfFwLDx8uus7mTmJ3l5eWus7dxQxhBIgXO0dOco6lRKwnJztOPXCz6+/y9wcZjNQzS0tImHADOzs7rDghKAAAAAXRSTlMAQObYZgAAAIBJREFUeF7tzzkKA0EMBVGVep/N2/3v6h6cOJ3vyKAChQ++7GJRFEVRFEWATnMqoqbt+BA1vVEG8uyq2zpyBdUuOdMUzWOktGTWHcEWv52YtXHZHts2dcaua44ysZ94akzQH2zzBO1pwaSgvDxhJnPH5Pi2T9Prd2RL77+98HdFbw7OAsavhnpWAAAAAElFTkSuQmCC';
string public constant mainhand8 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAHlBMVEUAAAAXFCUiID1AN1dkUXaFADuacqHGRi/fezr/yE1UT2V7AAAAAXRSTlMAQObYZgAAAHlJREFUeF7tzbEJgDAQhWELr1edQJzAEdQFIiip3UAQyZU2kriB2dY4wL30kr/9eHfZr0qlUgoqYdaQiRU6T05RhDfAz0GnAsz62mT2xtqpkNkarmS+veVW5iX4GFhqYTcEln1fM9SMOe8g19/rRuTygx7s41yKknoBAh8XQSP8e7MAAAAASUVORK5CYII=';
string public constant mainhand9 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAIVBMVEUAAAAHBREiEQ41IBdRNyRjboNxVTSJlZ+ii0+3wcX////eKRstAAAAAXRSTlMAQObYZgAAAMRJREFUeF7t0TEKwkAQBdDJDbKgyqYSPIEq9iGL1jaKZdCQeiFk9RgpTNjtUkjYnNLCer5FsBDy28cwnxn6ZcaMCUSIOKrgsDuGiDu9Ai69TsD2yD/VHLFVsuKbOaumLcu98/szYNvvDhVgd8+bkGdb5w+eja0znp0xZXbhmKLGFGnDc2eKWIObmzIWRHy3U4r+3cwAk3xNriEY9+IGmIRQiCn4wgnmDeY1wSzoXxMsB91lO+Qn80Qjlq6FuzFTVEGWn2pvq3Mye93AvgMAAAAASUVORK5CYII=';


}

contract Offhands1 {

string public constant offhand1 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8AQMAAAAAMksxAAAAA1BMVEX///+nxBvIAAAAAXRSTlMAQObYZgAAAA5JREFUeF5jwAFGwSgAAAIcAAGbMYQTAAAAAElFTkSuQmCC';
string public constant offhand10 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAAQlBMVEUAAAAXHhtZa2BPY1s8UkooPzcjMi0hHh99kYmYqqPN1c7+/v0jNzAAKG0aKSQuQjsTQ5YuYbgvKi86OjocMipCYFVnfnjfAAAAAXRSTlMAQObYZgAAAJlJREFUeF7t08kNAzEMQ1GRktdZsvffalIDBQRz8L8/EAZku3Kr1eqWwchozITGqLqNrk8jOGoCy9MI9z6risk+IdqgU8XFnRzbR5yms6u4OH+4ipg6NrhzbEgcCSyBq4oL+5bAI4MnEr8qMRwdlsBVxpHChKlhj8STz/1UNc4IJqYJkwPsD62e79Jk/DoOHbf7Q8fWml251Rc1RwPYZstpkgAAAABJRU5ErkJggg==';
string public constant offhand11 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAIVBMVEUAAAAWFhYaEQY0IxU6OjpJMiBMTExzc3OVlZW8vLzg4ODMk8wmAAAAAXRSTlMAQObYZgAAAKZJREFUeF7t0zEOgkAQRmHiCTgCAWWsNfRUGG9BaDaWEhJYO4mJ1sYEd0sKk91TeoJ9jY0Fr/2Kv5mJfm5paSktSVenBFk/kQ8mIa7MTNxoWxMr/wFu84uvw9ylvSvD/MrEANtMbBzmYyYeuJqZrTjgtZ4McKMmS5z3tN3ueke8F9rumNsCeSzkDde43ciDuFG3KFw+qite8nAmVgP+idxj4lUa/WNfIQQp8j7FGkoAAAAASUVORK5CYII=';
string public constant offhand13 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAG1BMVEUAAAADBg0iID1AN1dkUXaacqHGRi/fezr/yE16hFSoAAAAAXRSTlMAQObYZgAAAHZJREFUeF5jGBZgFIyCUSCAX1oQv7SYAF6jxRPxGi1eiEc6Ea+0QCFjeiMezWXieKQFxcrKMnBLC4mnpVXglhZWT6toL8Qt7VbRUSiI23D38kQ8gcYYjE+WgTEEnywDowkDXiCMUzejAojALe0MliBTGtPcUQAAK64Q9QL1EWsAAAAASUVORK5CYII=';
string public constant offhand14 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAJ1BMVEUAAAAWFhYaEQY0IxVJMiBMTExWPitpTDdzc3OVlZWcbE68vLz09PSEs3P5AAAAAXRSTlMAQObYZgAAAIlJREFUeF5jGORgFIyCUWCMV5a53IACaSHzxfikpY2rDPBJK3vh0y5xyG2VAR7pOSbpCjhlGXfMPIxPuqdzcxYe6c6ZhymQ7ojEZzeDRORmPNKMopF4Dd/aiVd3N37pTrzSDJKdm93xSIt2muCT1pip4oZHmknJJYkBj7QxXmkGZZDZ+ExnGIIAAOUDJQmg9zU1AAAAAElFTkSuQmCC';
string public constant offhand15 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAJ1BMVEUAAAAWFhYzHhVJMiBSITNsLzKGQjyTfoWdgoTDsLDLtbTRtpj78No+UeagAAAAAXRSTlMAQObYZgAAANBJREFUeF7F1SESwkAMRuHkBtnusoY6JKrDCZhZELjM7GLQFZXcAQ7Qo1SgcFg4FBXY/BVMp7HfvExc6DeO4NRim4xs59wQX54CuFYHmN97AsurAfFu6wBT5RiyIOYN5AoyvzxiN3gJJnMR35jM9UMY8CeMnOwaMq1HDjY7zJSUE+JzypDbKc4zshabDxN8bPWOuVxtjriOHeZWb7DuEZ+6PqPLuz79wa0mAVwmOCOOJQebORYFTKspFsgqDJh1RMS0GJOQF+QzcwOZl2Tjy30BXO88+ndif0AAAAAASUVORK5CYII=';
string public constant offhand16 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAGFBMVEUAAAAXFCUhGy4rJDU+NUZRRFZiVWV/boFF7Q+WAAAAAXRSTlMAQObYZgAAAHlJREFUeF7tz7EJgDAQheHLBgnBBYIL6Gn64CNO4ACCYC24PxbW90pt8rcfeVzkr1qtVisEqgBxpwC8yXHCiWIzUO9Ct1d4xrg5o1CuhVz+rjPmt0EHtq7nRX6+ZKzefK56JJtdzGOqJoubx34Xu043T9htQVhBPu8Bps4Y0S9hyNoAAAAASUVORK5CYII=';
string public constant offhand17 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAFVBMVEUAAAAXFCUxJUdLR15hYniDh5mosLsDb9zEAAAAAXRSTlMAQObYZgAAAH5JREFUeF7t0cEJwzAMRmF5A5l2g2zQqBNU0j1gejdo/xk6QV4hUCjgd/3gByH5davVqqO2h3Yl7jaB9w3ZdjuIX45snkrj5bMDR8Vbz9mjkthHEKdPuc7hB90dqcTFXIE8kNOnAAe97G6w/Z2ftC23EUrsyA23pYUK1eUv+wAY7R2VFAyEsAAAAABJRU5ErkJggg==';
string public constant offhand18 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAMFBMVEUAAAAHBREiEQ41IBdRNyRjboNxVTSJlZ+cbE6ii0+3wcXHakXnl1D/02n//eL///91h2BOAAAAAXRSTlMAQObYZgAAALlJREFUOMtjYBgFo2DoAEZBAXzSgh14pWXv4JWWuygoiNtowbpX63/hkhes+r/21f//37HLC0atWlV7UVB81VJs8ozhpYKCMrcFGAXFS7G4TzQQqEnwDFCGUTQQm7tARuwRgDHRgTxIozWI+Ig1QIGijM4CEHXYtTOmCODQDNbOmCmASzNIO6ObAC7NIO2MLgI4NQO1C5oI4tQM0m6IRzMwQJwYRgHJgNFIAK+0IwMNpQ3xS+N12QABAIRuI755zbOIAAAAAElFTkSuQmCC';
string public constant offhand19 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAAQlBMVEUAAAARERRVVVUtKSpoYWKEfH0/OzwyMjIzMzOWlparq6sbGhodCwsNCQ1gXV5HR0dIRUaFKyuIhIUqDw+cMTFdV1n8aTgAAAAAAXRSTlMAQObYZgAAALdJREFUeF7t0TmOAzEMRFFVkdTann3uf1WzGzYmcUKFA34xfahA5VVZlmVZlmV4tmVFvTlnnAMUqo0x4hpoemnb0JDWSFHPx2Ma4rhRhtmp5wzhKk1uIjKG0a7tOO4LcE4ggqWSjt0eh+n3gRLClXLTheNnUddnEAuFSted2oPL5zSp12+Z2gxq59U13xU2HYd0fax3BdyGgudcqeAfjs2z8wxlR7/5ky/dwxUfwC/KTsB15X+V3QEXvAUYhCf98AAAAABJRU5ErkJggg==';
string public constant offhand2 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8AQMAAAAAMksxAAAAA1BMVEX///+nxBvIAAAAAXRSTlMAQObYZgAAAA5JREFUeF5jwAFGwSgAAAIcAAGbMYQTAAAAAElFTkSuQmCC';
string public constant offhand20 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAAM1BMVEUAAABzc3MuLi5KSkqwsLC6uromJiZkZGRoaGjZ2dmGhoZHR0eLi4u8vLyirbPAwMA+Pj4mKO8tAAAAAXRSTlMAQObYZgAAAJhJREFUeF7t0UkOAkEMQ9Gyk9TUE/c/LWrEBXAWCFHef3nxyt9tbW1tbW3b9JbH0GviSMSWuKZBrwfgLtaxG+b0QaG9GnDHQUmqGaaLcaEhdjmuV4MP9bmyqbEDlWIcAGaVqcxdprIvU4VOZTLVmaDaU1TnD1ONDBVEKvRKD5HKPEFlPUPVM1RdpyovKojx402l1ncrj5+3T9RSBUwv7NH0AAAAAElFTkSuQmCC';
string public constant offhand21 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAJFBMVEUAAAAaEQYxAEo0IxVFAGdJMiBWPitZAIZlAJhmSTN4ALScbE5fc0btAAAAAXRSTlMAQObYZgAAAHhJREFUeF5jIA6MglEwClzwS3s50FBaA7+0Fl5ppooW/NJFeKXd8UkLCrs4CwrglBabHRQ9Dbc0Y+bunYm4ZYVN01KNBXFKh002NZ4WiNtpYTOnBQrgcXooPlkGBlG8sgyMAgxDFTDilTQ2xCttGsiADwgKMIwsAABr/BH8e2EtHAAAAABJRU5ErkJggg==';
string public constant offhand22 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAAYFBMVEUAAABbPmRmRm9xVXk9LRIYEiVgYGAnJycrIAvExMTf399RPx2Hh4djShpYWFiObS6TeGKioqK7oH3SuJfdxqmehnKtiEKAaVYzHzjV1dVVPxVrV0YzJg/arlo4Ij54WyRHD0X0AAAAAXRSTlMAQObYZgAAAMVJREFUeF7t0UduRTEIQNEPuPvVXn7K/ncZLCULgGHEnR8B9uvfZVmWZVmW1fe92rplWfpvLXbrtiq5T2Otm5L745P1quL+gtYfl+KLEOmXb1LtQymsqS0/fYivzncpBHz6dMpxyMyJDqcY7GPDSHVX4KGLIRcCN73lOM4x8mQUbu1bQ5jnXADrfopwep6vIXYh34Ak3jqNCF3MwJac+J9SQuwA2db9nV7SEjHl3KTAPByIDn6uZjV8HN3ZBiv5rraNC6y2H6vdC4pHygahAAAAAElFTkSuQmCC';
string public constant offhand23 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAAUVBMVEUAAAAOjhsUrSQXHhtFyFMjMi2nrafAycF9kIl9kYklFBRKSUhofHU2PDmGxI0UDQtBT0koKChjY2MIKAg6OjpPOjY8UkqwubEuQjsaKSQJQwmu9BCAAAAAAXRSTlMAQObYZgAAAKlJREFUeF7t01cOAyEUQ1Hs9yjTJ73sf6FhtmCUfETc/yMDEuG79Xq9ZxNu0TE36JhiA0bDtKFh2jjI01aIHGUMZpOxI8l4ptdLyxiUMVx+MRsI8iHimXSoGARFbIWgI5l6akDDNsDpWDU8A8SaKxankaOGg5Xj0CrekWOwIOKSWrDJ1pZd/syn62tZdD3dJxlXfViZh5/UG7dtk+14k204vyvW9SX8bb0PpYEFbfH+j+EAAAAASUVORK5CYII=';
string public constant offhand24 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAALVBMVEUAAAAAL0MAQl8Ac6UAd6oAmdsMHyUOVHMRPUpApMNn2/9w0vGv2Oq17f/M5/M6nApVAAAAAXRSTlMAQObYZgAAAItJREFUeF5jgIFRMApGAS9+6Qv4pXfzbscnzbszHa/2bc/xSk97gVc6C790XjU+f7HFVV/A6TneDWxrOvfi1n179qpOfN6euXk2HumdqbM3bMApmzYt6hgezSlpUcvwSYdEJeCRZnMNxSfNkOS6DJ90ohp+0xPSEhiGIGDDHygpIfilw/AbnsAw7AAAn18jn2dPvJ0AAAAASUVORK5CYII=';
string public constant offhand25 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAAM1BMVEUAAABVqv+q//9VVar///+S2/+U1/+u5P/D6/yP0/9Nm+ZNZbQWFCU7OmZISncmLEwoMVWXR3vbAAAACHRSTlMAAwMDAwcTE7WQ+WUAAACdSURBVHhe7dNNCgJBDEThHn+rkox6/9OaaTzBEwShH5DdR60yftRqtVqtVqfruJ44r3HDusx1pVvfLxBPPThWUexD7xQrJaarJdUTR6YMcYTDEMfEotgOUWyL4sM2djGsxv4Ki2F1KYhTbmyMnabYE+8Ui2MdOPBPRgbBW08rItuS6pEcj8q2ifB5PB9Jh7vXHN7Y9KgdD2+f+y+9AducCZPerhk5AAAAAElFTkSuQmCC';
string public constant offhand26 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAAXVBMVEUAAAAOjhsUrSQXHhsYxyoRqCAd8DMjMi0m3DhFyFN9kImnrafAycEuQjtofHUUDQt9kYk2PDlBT0lKSUglFBSGxI08UkpjY2MoKCgJQwkaKSQIKAhPOjawubE6Ojqv8samAAAAAXRSTlMAQObYZgAAAORJREFUeF7t0kd2BCEMRVF9ScRQobudw/6XaewlfCYe1GN8jxAHWegqLum8YpewLGFf0Tz2v8PzBT2pszi45CAsFh+89jBGFI4Hz6kPZ2fn1BL7ZCEm9EFij4aWYmCxHuzWblXRE/fDs1Vot0jhaLWgmZB40zKXziyGkjgYiqInCtuhUP1KkRq8qRawGAolsdVpC5o5gzdVgMN2oGjBE4c3QPHUmwXhRqMnDovV30uz+IaeZFoO1zaxsNhoa+eNpGKv3+/nyev7853GU5vQGWGZrh77vtP28UlbeXmbmNcf8p+7+gEpnAhIvwhduwAAAABJRU5ErkJggg==';
string public constant offhand27 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAAP1BMVEUAAAAaEQY0IxVJMiBWPitnAABmSTO5HR39Xz2cbE5KAADLPyHuNDSoGRn/hkK0AAD9sE3+2HX+63WGAAD/jUw9F7d7AAAAAXRSTlMAQObYZgAAAIhJREFUeF7t0jcSAzEMQ1GBQWGj0/3PaukIBjsPf/8GLFiiZVmWZZ+A7SWCr2dEP1489oj2+wrgHsB7yB7O25PHfeKT1XtvR9vou729OQxA3F0AENjq0E1HNRROD84CImpmKoKfOdTq5CLVFMT05HXRZRmui5JBUfgYy5eBhiISwBr4EgDlL8u+pYgDSqXOmooAAAAASUVORK5CYII=';


}

contract Offhands2 {


string public constant offhand28 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAAWlBMVEUAAAD9Xz3+63X/86f9sE3/0FjYSCkWFhb/322LJRH/wknsojPpZBXpnzX78NqdPwdqKCrKigztSyi7TArcmhZJEwjOPiFOGyv5tVH7tErShhn8ykjZISHZZxQqPAuJAAAAAXRSTlMAQObYZgAAAQFJREFUeF7t0kduxDAUA9D8Jsm9TU25/zXD0QECmF4MApgQtHui2sdfOXPmjLzJuh/A8aYzy0FL4grFhbbAIZT1OlHVlQGHCoPDYSsWAhfgEkI8tkTRugB15xLibuHQortxZ65WSoj4brxKp6FjUa/Fu7U/bUS1q+/Wt3Xt1ExdjcE5d8U8Rgbf8j13HmrEthtg6DCDZfA85y+zx358/a64A25Y/GNK4Jwq7rV9XCkMm9p2IHCf77A0zn2fmrb9zASutmmHjcGwOTcDh1N6nZrDLzsDX4DZd74cxpwGXiYeL8dwtdQHTct2AG8Th1PCmIBJnZorLIdhgUmNXlgyoP8ov6eXDk5FNLR6AAAAAElFTkSuQmCC';
string public constant offhand29 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAAq1BMVEUAAAAZGRn9Xz3+63X9sE3+2HX9l01BQUFXHDAoKCj/hkJUVFT88vamNCu6tLfJtLzPyszu3uTwTUDwjTL07O/28PP4urZyQ03+x1t4Lkd5eXmKXmjj3d87KmdLS0toU57n1sLrbTgmGUjv4MF6eno+EyHz2LeNMUr13pCTk5OUgYj50EhoKSStmaAvLy9JFif97tL+rEk0Dhv+2FvRQTbS0dHg2Nv/t2D/7K6ez8tdAAAAAXRSTlMAQObYZgAAASdJREFUeF7t1sVuBEEMBNAu2z20zBRmZvr/L4t7slKumdooymHr/lRykzr8fuTPra5xVLL2MmlTqnivXevY1Iq6HX8kLRVhHV/UuKnNYo2f2yeNbRD7xo0jmWnC144ZHTVgPG+3AqMtKo5ZnBkG8we3nHY8IXGQGiupMXjfDOemLH6c5BmPd3L2OuMsYVOueHTQEotc8dvoVcyUxJKxNkiyUXmqylPNSev0sJ8ztkq2x+HaojcksIiZasDUMTkxbofTO+4Jsui475ga2tZYqOV23KWak8bVi2Ph9Bc2RsNxp4vAaJwCq84SQSKDC8xulqhMm1ejWDhewaKKBEKX5QwiyTJ6UQLkNwyJnyNwgfOicE37n9pt8AQe457H2N3nMY5c/9vzsc0nq1wSZ2JZvnUAAAAASUVORK5CYII=';
string public constant offhand3 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8AQMAAAAAMksxAAAAA1BMVEX///+nxBvIAAAAAXRSTlMAQObYZgAAAA5JREFUeF5jwAFGwSgAAAIcAAGbMYQTAAAAAElFTkSuQmCC';
string public constant offhand30 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAMFBMVEUAAAAAAAAADgAbGxs0QABfX19meQCHh4ejpAC1tbXExMTX1wDf39///Fz//Mr///8/TGl4AAAAAXRSTlMAQObYZgAAAPxJREFUeF5jIBmMglHwgJa6P+CV5fuHT5Lv//9/fLjlmfb9c2DAI70bv3T3W9zSjAJqHXe3MBvgki5S63i7SR6PdMbtTfq4pZ3SdnvoCOCSDnJRcunQxCXNIK6SltZ0EJdmQdEStwyfYGMD7NLlE8Urzx+0+W+Aw2z3iYKCkicm4jK9JH3O/2OdAjhkBQXdMqdlCAob4NDsNnPm+T8Z/bjsrhSc0iM48zBOnzFO6REQFGDABSTdMiYyMOCWXpJzEI80o9RCAQZ88nhkaQ/wW86CT5rRxQOvbrFGBnxASBGfrGD5HGM80uJFnpPxSDNqP8HrNIkt+L3twEADAADQNz7aS4lKgwAAAABJRU5ErkJggg==';
string public constant offhand31 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAKlBMVEUAAAAFCA8GAwYNCQ0aFRcbNTItKSowTj9FbkZIQ0RLy1hoYWKhm5v///+QBsuGAAAAAXRSTlMAQObYZgAAAOlJREFUeF7tzLFqwkAcx/G7PIEVUle9lpYM2cQnEMExtjW6HulBcDpoODM6iHvw/vA3S+kYcS1I+hQ+kXmA+7tX8l0//H7sf9fW1uYJ8SNofk4RgXRvmpbHGvrfxNgAVn9nSaxfFsv0gAjutZfE+apCLAnev41U9avOFL+PZBWoA8FzNZSnyzgkeVyEFxVKJ/N8PgEhlCjcnH2kdYI1Ery2SwQscOZmM8kBUQZZx30+2CaIT8HOzZqbxFoA4+aIm0drv/YEd3jc/cw2Mm7Ymd8daN1/pbg5iDTrNUz1oJl/g3nEeMP0nN1XV6JDRv215aJNAAAAAElFTkSuQmCC';
string public constant offhand32 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAAZlBMVEUAAAAEEAd96Tie+2IJJwxl4jkKMw8aTR8o2CQFIQQBCQMBCAItjyo6rDdOx0sbdRiAaVaTeGKf/527oH0YEiVs6mkQs2XSuJfdxqkNGA6ehnJrV0YAPSASShAKeUQOLRUBXDEm2YNrPch+AAAAAXRSTlMAQObYZgAAAR9JREFUeF7t1LdywzAQBFBcQmSmcrL9/z/pg2T1OsuFC+wMyze3ywLuf6elpaWlpaUlxjesuHcw/aEmk9beiE8SbTqKIAA8eJTooklTWdcVPpAkiqufJVjK/rB/8LrCFMk7gMMPd8Zsbl+q9w9OYrNHz97zk5MjEz5yCOrv/AC26pvNuF1Ucy0/A1pX98OysNfp8wQkxtljr5z5VurhGKOpd1K8DQynGUiBCXddGvst+zKfQUxWcRpSGpYQamuLq7mOw9AvPsBpAnrdUr5c/DV1Y7VcWxNa9GfwXeq9Wi4ToMjLiyNSziF0auu/Pme9K4bnjzBzUMpBW2cyvkFaPXvmG5ymjCJmjTnvdmXSw+Kis6by++Jn7FwX/zaILx3+BkCRDqIFVcTQAAAAAElFTkSuQmCC';
string public constant offhand33 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAARVBMVEUAAABKNVhQf4aKrbL////D6e4eEyV8WZM1I0GiytAHBRHk+PsbQ0kVDBsZHyDy/f8tHjYrGTdQN2E/LUpgRnJCdHuEtr08JWR4AAAAAXRSTlMAQObYZgAAARRJREFUeF7t1UduxDAUA9Bf1V0m7f5HjTWYJOtPZTNIuH+gLQoQ/XbqCnacVjevEFxoVq/4P4sr/L3q3Sp6wDIxesAT6wQeb1Z/YDcPbyQTW8W2+sGQnVgJ0zBWVRrDDdH3lTiPsPWHVr60UK01YO2hj1HyTmrWI/prqVE4i/UenlmJRi4l+xWJWlManApnkqiVftjgkrZL78j1GPncKBXeqYb1yJyILp3Vovobs3YDNJ8T7+69K8Uy9nNWJ5boWj55O09KpTRxCVnzibcyh24kyOvULsuNsLSNZzGqy1ujP4dfFvBtCb8u4PSkOOGYGmD/A09V2rNhv2NMu03d8GaSj3dCI+4mKFb3Y0UfsCVxITwx+wlYhQoamhNiQQAAAABJRU5ErkJggg==';
string public constant offhand34 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAArlBMVEUAAAAHBREYDxNMfz9eOyV6eWV9TSqE222jXi1aJA8cEQ1tQCAeNxchRBkjEwid6omio5QTEgyth1Gw/Z3AiVLIy7fv8t3/zm1vu0D7qFqaWCYxZyM2YCx/0mkKFAVipzghHxIqRhnSkVHaiT3aikCMzmT2s3FZnUiPTyGsaz0VFAsVJAu4bTeHt2FowFILHwfY/86UZ0uYg3XtnVJtp0pYijn2/+8tVST/yJMuLB2c1sARAAAAAXRSTlMAQObYZgAAASRJREFUeF7t0jVyBDEUBFAhDDMtMpiZ7n8xa6dcztUKHHg7f9Wt0id/lku4F176aIu90vu8WePYI0cPz3vSw/ioiT7Cv6wznaHFy6zKNHwi1WOF4jnPKj2fY5hP+X5/zzG8Tvgrf1sTLA/JNLkhaBYL2DJWK4barapViLWy7a3aKAFotnsZrpQ6QHbolBBGiFMQQtZY/Hlyt7tOGGNEaQ4mCN2LrSylNBvj3twpS/NcijoN3VefadM8izR1nc0GJS1t86cUwWXetC2lZ+uMuzK3lFgcRc7FnWyoBTQyE+O+WrYjDqJoAjzZ2lEHlLhi+YMJXQGYEhgbL/wr6BeOrXbFhBE4lxQ4HY/kHcf45utVAduPGb9DdREnyQyvjmNrYW3tP8g3jRsSlM/V3QwAAAAASUVORK5CYII=';
string public constant offhand35 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAGFBMVEUAAABAAADpkwAAAADqlAD/0gr//GH///9lfYUpAAAAA3RSTlMABPrDchrYAAAAVElEQVR4Xu3LsQmAMBBA0Q+eqd3C1iapA2aQA1EXCGZ9J7hbIPfaz2dqIQRlxSFU7wXE6elRxSLpHt+B6R1tv7CU0ZATQyp9w1Zzx5MrnsXPyjTCD62nCcv5auYuAAAAAElFTkSuQmCC';
string public constant offhand36 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAAV1BMVEUAAAAAAAAAAAAAYZgAAAAAAABNZbSP0//D6/xNm+ZD6foDBwRFRUUHBREvLy5pAACQkJAAY5r///85rNI7AAACZYpXAADAOzr9/f03qtFxGBeO7f9PDQ3C7G+GAAAABXRSTlMAAQLs/tGd1kEAAADwSURBVHhe7dPJDsIwDATQsnhLSzda9v//TpxSbpUqJohcmPvTOLFcfC9EmTCx0m9x97Ysn+swW2P5VHehD92Exa0S1uyWTQl482bP0ZpCH75njhbDNFtZwd0yNscmazgsYjVVi3htNbulZnW8vujr8tivYkXeXNBkmcCzYLcKYmExQ7FbVRib4jhafGw1w/CWZozoDfFEBbyq110IhF1ztOCu+qqqnGK49lABa9zGuanI01zlai6bJgGfT9maU/AjvTkkNIcLpMtbU+LNw+AYTQlYPP8ccHk8JuB7Ch5HGB/avm1xXdeYxXH+sfsfruoJsHcM5FNqVgsAAAAASUVORK5CYII=';
string public constant offhand37 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAJFBMVEUAAAAOAhsUAyQXBSkrAlQ7CmtFDn1ZGJlyKLytYfq4cf/Jk/9Lq2IaAAAAAXRSTlMAQObYZgAAALhJREFUeF7t07ENwjAQhWFLsVJAT42QndrikiNl4KxMkAnwiQmssAAKGzADY8ICfh0V+dtPT3Zz5l9aW7OYxwGONSKuyaL5GAPixGIBqyTA9qwcAvjZTgBXfNZkitEsSmXuT+raUOSFMuIHZd/ty2tBvHmluSnz9v1lRrwA3rwgm0UgM80ecIu5v2fvy1w9swNcc2wB23S5ujKHkUXB21ZlAkdydIzOJB06xA3pANjeJoOK0cAG85M+ptQomUVKhVgAAAAASUVORK5CYII=';
string public constant offhand38 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAG1BMVEUAAAAaEQY2DgBkGwCGIwSuPwfnXwv71Df+/b2198ebAAAAAXRSTlMAQObYZgAAAOJJREFUeF61z7FOwzAQgOEDOOZIgZ1WdAcl6Q60YQ0Fuyuq5JgxA9h+AJT6sREP4B8W/vXT3enkLymzYR6E43hcmXUyzBY5Mvv9QGyRxUTmQDzoyOwdsPmdYbtqHK2ApwCsP/xW5rM0e+AXZGvTF/Devn8QB/+aYHn4JDYhbOJU5jE8pjKrjw2w88d1LvPo8zqXH7uI+enIPAOnbMMtsSHu89ZVRdZ+XhGv3LIrs9yYBfLD4kqA6/sK+Lx+FuqSuRWsY1b5z05Q6zucbWxFvNki9+01Mt4+Ncy7g1CHnWDLAnDfFa4+ZFRz4BkAAAAASUVORK5CYII=';
string public constant offhand39 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAAYFBMVEUAAAAMDxBKCxLtbFAlLC50ISqtFSLCLg05JSDxQhz/zKhVHh4+HwN4ICmTOTlFS0xxKipGIxsWGxz1aCprb3AeJihoNQYQFBX0rTJFGBj6iVf/yWuxXFyPQUE9ExMuNjdUrTYyAAAAAXRSTlMAQObYZgAAARRJREFUeF7tz8duAzEMRdFHUn16c035/7+MJQTwmhogjoG5C+0O9IjKjtLr8KtPTjVO0p718nz1iyWWR4slISEmD/gkNYuF0vcwrFJxtBAZmU7TZKJAG/m2heTdYVVbkx1HSPJx0OJWInvXZd6aVWdDG7vOuawlnQYdtpE7F210vktoVWdTYHi3XM6XpSw3gwZPYOdu9/P95hxDic0E+/uzBThjjQbbcrNlIBiomj+zXoq1YdDh68gAZwoer9DVULAoWUONEo+gwBlwIIxqDDLMHAJBi8f+I+tHBD1uHhg0bxk3vVJ/9Sg647FvlBhP3PSoijJGLd4I1ZXd9XoX3nbid/ya5l278ZcdGdRH2zviov9nRz9OTQpId8itigAAAABJRU5ErkJggg==';
string public constant offhand4 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8AQMAAAAAMksxAAAAA1BMVEX///+nxBvIAAAAAXRSTlMAQObYZgAAAA5JREFUeF5jwAFGwSgAAAIcAAGbMYQTAAAAAElFTkSuQmCC';
string public constant offhand40 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAAVFBMVEUAAAAgFBQHBRGiJCJYExGhOrHcJyHzTFBrGnjXZ+FDFErhb+uCHRv/npv/re3/yMi4PLvzUk2WLbBMDVx9HYz3mf+bGJ2/MCyUKpY2ED3OTdD/zPQNJczrAAAAAXRSTlMAQObYZgAAAM9JREFUeF7t0UdyxDAMRFE2wKCsyU73v6c58g0+yjs1w+5Vo8j0fzlz5sxPBG/h+g1DjLdA63xs6ufjYvj7b80IX45zYfb1uN0+E8vrUcYy3Bm+l/E5FoinoTxxs7oeJmZt1zRNX2K47R1qF8J1VVKjuElqK5zbM7bJsmo7LBzcRZvdXdnF8Bsqr1RLte0Qvy0s7rq5B6yURa0lLcI2JVZt1Q4gEbtYojFq4zjHMdeh7s7xAGaLG683q9euOb8GcLYPqm0JPJl3SG2N/DSzPL986gXgcUakSwAAAABJRU5ErkJggg==';
string public constant offhand5 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAHlBMVEUAAAAXFCU5DiJIGSZhYnhpKjCDh5mLQzuosLuwZVCVE2h5AAAAAXRSTlMAQObYZgAAAI1JREFUeF7t0E0KwkAMR/HkBlEoroVOcwFrz+H4MfQA4tpAkR5AXPfGnsAnWNz1bX+b/COzW1paWhmpdnfkYxhx8Yn4kkYDPnm/BS5NHg24zv0B2PMwfeZzihfzDbikeBA7c4ryO3dfmXa385ifuvNMu/fMbU0sVYOseJrIJp7EGldiWQ/IyiyVIav8pTc+9itHe/3RNQAAAABJRU5ErkJggg==';
string public constant offhand6 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAIVBMVEUAAAAXFCVIGSZLR15hYnhpKjCDh5mSHD22NELjlTTxsE5LZKXzAAAAAXRSTlMAQObYZgAAAJZJREFUeF5jGOxgFIyCUSCAV5YxEa+0iBo+7YxGU/FpF9aa5IhP86rpYbhNF4laqa4igMfslUWtiXikF1U04bacUXOlRgduyxldZ1bgla7U6FDBLW3UHq6BV3qmEp5gE2qfFYRfehGeUBUJxy+tPgtPoDIIE5RWxiPNSJm0UZEjA15pQwY8QAi/tLCyAD5pRkNCmYg2AACCCiGNDMEv5wAAAABJRU5ErkJggg==';
string public constant offhand7 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAG1BMVEUAAAAYFCUlFBRseIeFWUaLlqWirbPa5uT0/vzAlmiMAAAAAXRSTlMAQObYZgAAAGFJREFUeF7ty6ENgDAQRuH/mKAV5JCEDboCYYGa+gbDAj1GgLHxJP0F2Pvsy8M/zjkXIwi5Mwhttb9CrpLQMwW1PaBHM5uhB5shpyUQYwsgxCoYLXyP+GgGM6w8b3xf8OIeKBQLDF3l5AkAAAAASUVORK5CYII=';
string public constant offhand8 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8BAMAAADI0sRBAAAAElBMVEUAAAAXFCVpT2J/cIqbq7LH3NCc4ZOnAAAAAXRSTlMAQObYZgAAAHdJREFUeF7ty8EVQjEIBVHoIDHHAvzYgEIDRKzApP9WTAOPhbpwkdneM/Sv7Xa7Xa2pzlmwcjyHYz5HzIA7j1g75BarT5nVol8xi4V0J8SHRrcLoU6iKk54P+RuhQrwumrOTrjFj/INv1KuGbPNGyU1LRlzpV/3Bm3vEoqIwE1AAAAAAElFTkSuQmCC';
string public constant offhand9 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAAPFBMVEUAAAAiKTcZDwpXMSG3wcXU3N80IRj///9mPCowOk4RFh92gJU0IBUqGhI4QlaLlqV8TDc4QVItNUZQMySfBZ3iAAAAAXRSTlMAQObYZgAAAKZJREFUeF7t1MkKBCEMRVFfBrXmHv7/XzsF1euGF5raeHF7CBG0/Gg0Gu0ZjIxGI/UcZ2nOaSCwNVCDJ9TA7juF66MuhzVkMDEazws7MXoO3AMflsO+kzi0NwrrPXj6Lu3+4m/MDQmMQmNjsZ6YehkXduOe1Vz7eq5MYxjIfyiFN10LCpnolsN8sTSPJYXfKZxZWgjMN5IE7Tdh0c5rUc2MFin/a/QB4VIIqYZt704AAAAASUVORK5CYII=';


}

contract Uniques {

string public constant unique52 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAABSlBMVEUAAAD///8AAAABAQEAAAABAQEAAAABAQFUAAAAAAABAQEAAAAAAB6RkZEAAAD+2toAAAAAAAAAAAAAAAAAAACTk5MWEyQWFCQlIzIlJDPrlZUmJDMmJDIlIzIAAAAPDw8UFBQZGRkkJCQmJDMXFCUAAABLS0uamprSYmDn5Nv///+ZmZn29O3/zc0mJDN4eHjtl5dsLzLVoyT/GwFSITM2NjalQ0Gurq7/3NyicgCNIiCZBABjY2P/XQH/mjqOjo6NjY3g3tUaGhri39bm49r/wJ2BMTCLi4vi39cBAwKPj4/b2dGRkZH/4U/k4dnk4tkGBgY0NDQODg7/9cT8+fMYFSUFBQUgICDS0tJXV1eQkJDc2tLd2tPf3NTl4toBAAEUFBQVFRV6enqVlpaWlpaYmJh+fn7g3dVHR0cWEyQlIjD/7ZQlTUqsq6nl3NlIAAAAJHRSTlMAAAEBAgIDAwMEBAYICw0OECAmMUBw7O7z9fb9/f3+/v7+/v4EklekAAADWklEQVR4Xu3UV4/bVhCGYVFrp9lO707PzJxGUtrai2sv6b33/v9v883waJcmqYWMXOTGr4gFJOHRDAmcHRX/of8FP8QP8fiR8Wh85ulnnnv+2dHoAfG5Sz98+Ob3b19657O33l86M1oYM3NRfHDny8MLh9cv3Lp1/cdPnxwx80KYE+J/vvrt68s3vrl48fLtXxLrZ7wA5jStqpTCjXvvXfn2StBSqqpqCr0gDrkHxG98/uog3m01BzOuF6ZTxW09nU5349Wr+/v7q6tzMUfVKXXxT2l39eDgwOTdle0+NjuZqGbu4t1VpBINY1jD4ADJWDrCjfxrZeVEPDbMH0Phb8ZGDQ9Oho3Q/An6s7v2ykc60/hcDM2lCN0MDFNNVfIRtqUV0xDe3NyMHKC/M2Ox3TlwXlqxoyGMFAmbyjZPtmz4doA+EUNdu2Y6YzC7Y8VhLk4ibDbGRqd00+45e8VCwzglAWgFLMA2Vl/bwK6L/+A4USy2dxuLA86BugFMnCYTw6pTy0oAxt0aDUOYJGD0RHFZlpJmwZalYdDtEE07oftxCJwarLr8dVaJgCH39jhoDvXw7xwNoxjLMoQv8DsxKtB9Of7MTm0PE4yOZiIXcsDtHEcmuGGcmCdsO0QDTlx2GO+ccMTe2KiLbbAIJ8UNcU5EnPHmMZHuXWqdB5bXUQwNYEoUGscsyThGYNg+3uPmnRjOTsRsoVjm4KqqgIlUi2mX7ZoGzJGdOKwN28ZmSfbEeypobW251cx6fWIeOwGfGsQ7niiI6rYVJ+y97l1VTrrnmYCR98BBEETO4T2GeSISEcyAHcbNYG05W0DXYO8ry710to9Bd/wO6TPCle91OT/2Fq57/wAprw0cYA2DLysuTdMO8idgfA0cDCPFBFwGdDy57mHBXNLJ0fDfhuHJ6dFqYfKvdTB0U54sBKicCmjDs7Vr7+sOthjnnRpbQJudnRSXJ9OLr/utegDbgRZYMW3WtEYWc7F03p/v41OP4ysSax0mW/1ItTA3J+d0vfVKD59+oliCUbquzmzWKB8sgJexd2/tRwGI1jWDHaza8Ls9bJnsaXJNQg2uBzH5yuerhcn7DXt5YlTXc3C1sdFcGy1ct+MK1Y8tiutYtdvC5HExhI9r4U5PHYF/AfcYXA1pYWO9AAAAAElFTkSuQmCC';
string public constant unique43 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAAM1BMVEUAAAAAAAA3qws1AilXCy+YIkEsFkK7VRxgVH7POUJz70RELlrGsXfb17P2rS3IqLiDZH9AefmqAAAAAXRSTlMAQObYZgAAA/JJREFUeF6F1otu6zAMA9BLyXbe3f7/ay9JIfCWrZjQdWnsExrKA/n3LKje7P27sK7rg8P7/nIOxXhMFR2o4ff0uq6z9KCedpQ9Of6Gg1JlzXDM3FFWRf6rpQPxjIbqS3BNKP20EHOIo1/oKrwcfA8BPzVMq9OFX0vfVH15Fa4x84cWtVWINO1dy1JRuBuBJ77tWhi0raq3G6+3fuCyNeouEW2bqA7ifcS3/t06GFsHEkkumUigb3C09DtrzNiOBqCx/B+d4cY/NQDjGrHO1k4qIpwMt51TvusLssK3Zl2RLeNyfFniXzU57ex2u9Sw3niirwbAmPAn9kV/AjWkIr62qos4k341fqPFxwA+P9fj4O+tk3btzmxN/A3Gan2Sfnx8UCOZqLoun7XOT3+jwR2ix0rL6IXgPLfez5OZPuNcRwdxCD/sveB1pX0tC3Rh+k/W2DoORz/wAaZSk9MeB7NZzlXxu/A4hJ/Btut6vMomyBPKNW3GwRRHP4KXD8a+RBmPzybpXmHrWj91D+Hjgcc4AktJUjXdq001KomztndiR2Na48BaEMhcqTciWlC1bNItIgpLz+BjxIqCqUVS6wKV3YjRpDGkjxlNW9gHBaVjSvfC1fOtYYzYC1vP4J0YVNZbacXl1rIwDmPrbzjcSHQq55TOLqiPsacZR9xYln0UZpMiPT+bdEPqTBl3OKKilGxrTF24haJZ1u6Xk7ctatagrX5XcGluoLcU9mRrWh2MuixxxPEFR+kgbi2iYaAeuklNjFQfaR0cO/H4hoe0LSev3JBNUDfj3sKa1lkT79QAIjIiRBht655/qn+9Z+ya88TU7lVG41CC7dC6Aa2W2wPZFJ1sBJhOHYHC1PuuibnTNvgayFkYXkjbdQhi6mF8R6MB3G9LjE/Wh0obGOpkMgFo0rvtjTmoZGJa4aVu0PomPpCVLKxrBRMPbDVQFmi5VPTn0hqGdDhgA+0xJlZUd3QcLNnWllq0cOlwcEcEwcS0oehE3a1qtaPL9m69IxUceuv4jv8FWMSy6H1jtHu20G63Bmgnnm8ivnSZYKwb5OV2v4S37gG1eb6elDaugleBzbj6VRjSBsa0D2w9cb5sG7Ww7F/Yr4B+0DOa/cqU7uCIQDzx+RPTqt3CIf3E58TnxLjACZA1fhFTQyPGT4GfmJaY/SaOlC0c8RtwhTSxvlP6gzh3wIJgjwmeOmIeBJGJxTjIrIynnXhqY/gh+m9BZuwNN6Z+Yi+pmO1O24UJQNy/6HevvXbGtJ3R8BKIbx1Otn2WnYah235vwoFG3bJRhazrvd7RmbXrWUesa5XR0VEH/kMzK/3B/vhJ+5fGXYjHzwf4D6TSNv0ylTH5AAAAAElFTkSuQmCC';
string public constant unique42 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAAolBMVEX////+/n7RtphDjEWCqFkWFCQXFCUlTElDjEYXFCUycE0lTUo5OTlDjEZFNiVaXVqQkJDRtpj78NppVUAAAAAwJBYbGxs/Pz+CqFkzMzOZjoLPz88fQkA/Jgv///9FEyVLS0u0tLRsLzKBgYHt7e1SITOEYDYrUk8kJCQhLSFGjkmfkoWQWFo8PDwbGSmEZkSQclAtLS3bAgDGxsYaFyiHrGAJllh3AAAACXRSTlMAAtDu9fr8/f6YCgbaAAAEfElEQVR4Xu3V5270NhCG0U3PDGtRb9tdv5py/7eWd8i1rbVj+HeAPIJkgstjSl7A2vxX+7+qenf2Yxurd6c/tu9h6I/t+7j6GFc//PsnS/gQh5cdKvQyju/jZxDCAp477U/7/b6MYxS8Wru2ATiLG+Ccz9YjwGxvZEVZ/Arjm6j6fgGGzvZ0sXtfbLipjkuPZfEtLvqY9bK2zvllEdsf+2zfYtHVkw67VZ8/f/bhyVawP8K+1fGmBHxavF88zp13zu1gS1gUwlsMjU4u3tAvX76sd0Z//UrSCVSe/Y0WHmAjMf/+0y3z9DfjMBPfmttOMtGdxOIBrnm19PKs3oVApBSb36Y/poefH27xg03XMeYoOA/b90TLcaUr/DF6PGzRPE2MnR6UUg95SzNNK+sd9f2LrnqJ+l2JWMXu4aErRxeNUrC7nHN+pmGlYauKaNzvXYlihMpBx8jM5HL7cdSzTWmAuGDQYSAPXfwYoZ+KwJQtPh29nudhsGkgwIw3NFhLfhnBpTGEeH9/X84YAuvL/LgAp5SyLhw2Wezs/HhJh3D/fATFeix5B2wtqIUtEdkhkS8t3o9aselKpjPG6DKPBIsutGib7AU78VqBKEYYKMHIZauHYZ5nu8byzFr70qj1d/l2OsQYmO9agxc7p2GeJuhrTIPWFofWybFjNhIjx/WsS+WBZzPNayx2SLZOFlfbjYYV55RiM3Y17nRGaRA9G55eY1gLW+MaYwxwSEadqm35elKyk7UzM6+wJUVgClisokjRxRCik5Ey5knbCbd8jXtgBavsMMAaE76Fb4pCICWjEE1dp6ztxDxN17hplKozvqspGewZFH7Dt2AURhlbm2wiiwyvcXVsSDGma3R3RxxBcRZnBIsm8TjTo2F1hWG/fk0pAd8RIAMbZeBYMAM3qOtgU2Kq1ri2GtU13SFABdy2LRyGiplrgiU7dp1F/WvsvGYmItGCW+99iMxBeVRn663rhDdr3NTaOc3IMN2RD95H3/o2tl6S/y9NJzmrtTFXuG8uViljiJTa7VwbsLFv3U5SrChj62QhNcdqhck7bYxRipmwUqlP5zOe+YwYs/iIu86w0d65EY/fr7Hb+4wRMTB/ErfdnreAfMGMU/vR+xcM2zdNwXBkEysGBt+ezwcWaJERDL3AXmO37DVLROkRKzM+bM8HwfhmgWV/wf7Vzg123pfbJjLGIuDD4Qx8MDY9JtmejKQ17CtMGTOTvCCZrYXF3rhi0y6/MkluG7p5jaFLTet961lRwYftYWtlBqczBpjFyivjBcOXYCW3AYYXTNj1T48o1/TXuF9hl2tJZMa0IVeiJofVa4zKNHAp47Nowa3W3uv2HQwmctMgwjqt6RMdCJIO281GlwQDAhddcFM9YyLSDhE2pDMuW9rgvjN2BFsBXuFNVbwsQ9C7nRgSuAHW8r6Q+abaiK5WGJemqoBpWTzSeueAMswW05KmRkBfrXAlGF6WXXLAz9GiS54ykPX9ESyPnyPvSvoKl7ecc8AlUcDX0aoVfjtZNv0HLpi7khahN24AAAAASUVORK5CYII=';
string public constant unique41 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAAq1BMVEUAAAD/////ATH/ATD/ATD/ATH/ATD/ATD/ATD/ATH/ATH/ATD/ATD/ATH/ADEAAAAkZ2wAQkhcmJxjucCa9v//ATEBSE4AJi0JXWYBAQEKCgoLDAwAHSQAQUcCAgJQu8MFBQUBAAAYGBgGBgYZGRkdHR0iCxAANDwlZ2wtbXJISEgJCQkEAAEEBARlZWUKSE6dtbf2AS/2ATD6ATH8ATH9ATH+ATELCwv////42kA4AAAAD3RSTlMAtuTl5ujr7PHz+Pv8/f7xmtO1AAADjUlEQVR4Xo3W55ajWAwE4Ambe3alGwHb3RM25xze/8mmShLnDsbLdHHpQws+yvgHx09upDG7ASbHCSsI9MDCPEaDVtUrXGvOj9B/GIVtnvWzPEb/BftGBEosAdor4PfpBhu0FmXAfZ6U+tjmTAtaUGWcghNN1IeWVbT/VWjw710Tuz6y6rZU4igXxwfarWO4Auv6O4wMH2i3xMLSEc6ID7TZvBZvMYdWPfTeAlhxnrK6I56oHWMSem8DlyO8024PcB94p83+P+4dOG6vpo/wRBeWeovzqofdfOwtzgNTs2eDATdYA2vgaaocOuYOPYoDTwxwcaVlxczAXj2K6eEw50XUYbUbLqVMG0w9sEylFtg6qWqp93rPf2Fzx6SUCj1wli+GzSIZd1dcoNPlogqsesERioChS4Ye+DPimleMoCPrpbXL5R6SB2wq0HZWmMCfWHHg7BiajM9b4F2FjleUUsvHhtVx2Mm/tq61aCdRQmpGGonhDwcWNMHplNJUWPKtYrGVt6OeJsc0xB8Epq0UCdYxW3vglKBJS6UO/HzFIl4CuuKsWKCSM/Ukau8mr34AeeY4B1YVSclev9c4sYxZqwcW1tsJaClZIDySgSu0uFYNvWIaRRLG7Qysgb2Xa5IvoT3yp+H4wgQ4LLA49g1Hlfg34UdKCG/4t+GPHGOHDZz+Ba4DZ64lLSnhvikj0gx/GtieZ8Vn4Jcb3Im/wQ4z8B2x/ACMma5YVPIe/0PcpJgmboZ/l5o3WISITCllfkW4xQIM3dpNXLFxET/sMS0zMGyW82xY7Q8kSr5a5q/bks8DN1jHr1fczigm7oE78ZxkmX9syzyfHc8SdDQnYpwHVukb/KvMi52k3ePQA/tmOCVUB863sL6DCYC42UFKqmLYitMtTH0+47FQBRV4pp2hiWGJ+x57N2zO0JKArVf8hfkzTuUDTE0LjXbIxAgstUg5wEIUV7hbLfmsD/k2ppAGEffRX2SNaA1dUU49Gx660Bp2K9LWiBTHqag0ob3C1fE8G978YnadiOXEa/ZYNbDZtD274pPj3U/5lyrULFbtxFcaeDmd7pr02exO+1cN2x0PDYqcPn96J132WHrvwIpeSXqFT5IMtxfCBw47dOPYAht46HZaVBWP/NPovSpvFlFiZFuupmO+xxElZqCHXQO6DxtFSSVn+g48bFUs7nsdbwRfOTD0wClhcX8vlkfit2p7xY4ADOUyAAAAAElFTkSuQmCC';
string public constant unique51 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAAaVBMVEUAAAAAAAAAAACBp1iBp1iq0YEAAAAAAADY/7IAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAycE1DjEYlTUoAAACCqFmr0oLZ/7L////78NrRtpglTEn/IiUMDAwza0u115EzaUoKCgqPfIOeAAAAEnRSTlMAAQPS2+Dl6Ojq7fLz9vn7/f7WHydaAAADeklEQVR4Xt3W6XbrNgwEYHffbreZAUg793Z7/4csB6QUq1ZO4/7s6Mh0En8HAkzLufzf8s2Hn37+JSL+A43oXHmaD5orpZ+3w7N4PGezZTbj9mxt142R4Wol/3oCc6BPn7ywVka821ohAuxJr0n5Ct5na0xACpBX4+wt3kMB5DEUAOa/6QBY+LZcPcN8z357U0UUJjNtr9xyuxlnvt00r60VD4SMb7HldoOgVMQbPNha5jUmZvLlFvvxkmksAGc62tqN1hO/xH68ZKM6cL5R41oYszEY5yGSZt/Eg2ab2IQBgfBPKzBGYSL/qaOk8dAQILhUzxlSkpfsVOYRf301ttHC0CDlnMzuwmJWc0f9XefgUtmUIGPYQSNkgxHIx/f7+8YRCczWjfcNiaQRUEiAHm4NP7TccWPhnsU6kSvILTy0/aFl2sxh27o5spbkApDjoeEe/9iuNiPrApyEIQbiugBJrtuIQ9uRE6sCAsSOasiDEcKaWiu8a0i2C0tQgi6yD9l4m1o7bnLoNZhtykj7kDtVOKVsecRxh2lciMZWXLjyiAOYVKDYJsIcehqL0vom8F/vdA/fSWSP6MhWpdIYhdGM2ylu9VTDR0RPY09LILSARhrYiWydvNO58CUvF+OO9VGEkqY5K4tJMCk94O7Hwk0ABnGYYK7KYtO8iz/gNnHkZCxMptbuDInE+iU19bG+S9dkNHAn2BNkSnEJwNZN9bdwy4bM9S3rsgKSNJ4XBLKd42Crruo13PYbdywSAHGGo8+PE+iCUGEQwIZ9OoWPiWRSI0ZOrfBqa5iVHfdX2wVSCeTSvE5PFtbHwkjEaWFB2QubsQk77oyIiWPDudUPkkUaklckCSWB2q4heGyF9W3ZHa+9OTJ3IbqukozXHSFA/h5/Fv5qx9geacwUJaCpR4SaHWASQHwkOyAc8OF/NymNW9QUsE29RUgCD9hZmMaOIiNf8XUbuQRJcYIBkhq0UxELB2qIE8O1f/388scZBlivZX0QjBFBU4cAIjRgO8UruscCy6sbX74c8ItTLKi0sXYM2AtpnedYoDEFGA5b5a0rGgGMHxJdEgAJhWfisrCwcuw3lwUWXbZvXsr+ivnB6GzWphvGjqGE0AGfjM8erBm7sUDjmV4YUo1LCTcdO8txRNjM83iXQWFn7zzvR4bVsCSsGK/sGK/jnPhvSIWypfwzcwMAAAAASUVORK5CYII=';
string public constant unique50 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAA+VBMVEUAAAAPDw9OGSgVFhsAAAAAAAAVFhwWFx0AAAAWFx2Llrdkans9QVHZ3u1MUmYkREl5rFMYUTlAi0H///8iRkz/AUFQGyluJyeOPDz67LQtbk87jUMYGR/mxJMlckuCqlAsbkrSZ2Z6rFMpa0M/ikalABLr+/8tMDxBiEo+jT3/8Lj/8PQgRUgYHB+Ek66KlrV/kakBBAJLUWUHDgccRVRSllNTllRjaXoKFQpla3xmbHxnbX4KFgoNExAlRUkQIhCAkaoRJBEqcUMSJxMTFRkUFRowRE+8ws2+xM8DAwMXGR89hT49iT8XGh4GDgb/wdE/jUMYGiBBiESoYO3XAAAACHRSTlMAEcXJ1d/4/CxfLlIAAAOSSURBVHhe7dTXjuNGEIVhOYxdobsZlSeHzeucc875/R/Gp0pNShwOPbe+2F8CCBH4cKQGodn/qxe96Oh+QPteHWK630bR9jJHA9vcp6luTdd1DVvFA03S6H9rKsvSNSisCo3wK9O7KG9XZoU6/bYAB5oxc+ZjXJaYbLukcsyjppcvW0kiMSZtK9f81VtvvCmNJ95Q066qqusSWNK8aQSY6GdiVku8oNYtDFSW9B40jgx2/vQplutLq+ZsGx5j17b5z4PmQbXDNzc3yQ790aO6Dew2LzPzAO++cVV+c3Z25svSwoq2Vzi1334wG0K4G9Nms8FyVT0xXFetgMfYrkGvrlq3GppwF6ayNk119QT6ErUe8BXs8bHChKbRMYZ1XBTkGIHbZb3mOhwfh78Nq96x/PICdfgEem2vZ3it1yccwjHewAe/OQTDbi8uVsvlYoebk5OTZ/0LAcP/ouKN8Wq1WiygC+Aoon0xRvUV5R43fBsvwZcLx/5Yihf3+PvJ5QVauiZga4SZFZnE5RAfbZBrom00PV5+JzBSxLto5tEZbGF6SdttiKnH0mHRFAKxOMNsGODCtx03pgaYlcVxyBnvcIE2JfTCMI9SnbMY4sAWaIepdGwRleU2x0lzn+peS4TjSfxXh0U1qn6oH3+iMWtiaRTxHhfeDp9ut65PC8N53K4pMBFjWbOmPNxpfIYGLE5xgd6XEsY4Y4HmjDeU84+O8xcfWppx8Fj09ZdmjpE/N8CuOxuUpcswYdeGw5xZXpt5FBUB99sFH0ZdoHZcDXRQznj3OCttNo8fm6aYoqrfQxGjeBOBRtsJ/shR/ydygMlsAhNlx5Ixe5rrcbfs540SOUY9tt0mCjaZJePBb874An8LPIyIgjSyU3PoBvrW8gYRrYAXhBUvxhRoQY2ELz4ihXIdJjDsynEwG0SAV8D69QfvKhDYDWc7wkWxgO6X9/jLX5/rLnY8+s3Fhs7PoW/ha8Ofvf8759OaWgY+xzg1Kf05n88DosLxH9/+KDzPGraPfBkUFhjl6RRjILq+JqHvPv9J8lk73ndE5M82WYdYJOBuQaSMO1A37Ec9DA4XGAnmici+dyBkt7PFVXWEB4cXTPi20NHudrb9UU9jaGBKKVHG1NvInO2oh55piBDs4nFvZWLXFyAc+15nCXud1TBhI/LtIDS4LyLgbnnKiloPVcRxby2Fs2bT2K01wGJpsuhQ/AvVGYLuotmwVAAAAABJRU5ErkJggg==';
string public constant unique49 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAAdVBMVEX///830P8XFCUAAAAXFCUcb5YFVHgilcw3SF030P9MwvyiqK7///92kvZsLzIAM1rc6P/78NpSITMAIIev2/DGd3rRtpjb4edhanU/Cx0HY8Ov5v+L2f84VcD/1tc2BBYjls2v2/ECCxADAwMne6IbGxsCAgL5Sf7UAAAAA3RSTlMAqcuJBdhGAAADcklEQVR4Xu3U53bjRgwFYCUApg+berG9qe//iLnAUFnL4sryycnJn1w1mtYnAMOy+lfyf+if2EL/Gf7jy4aRGf/2ZVv2+wO84khfxft80Ce/w/V5bDYrHmYdn5PXHDIzzaVrLLE+YUPJuWRU5myln65sdp/xzHkf+HBgqgM9nrku2QyqWPWjxO/Y7IwDB6byAN8uBocsAi/eS9gbjvGJymxR5kFTSj6HwEw1DuWhropBCpuz+JBzSIWK4c/Crs98Pp+tqn6ib+mfxeIyl1LOInLGZwr7QzA8ECMPpEYya1UNPoFzEGAtnS5e+TK9iDjHeVQ8v0bFTOUllkKXcqF+UTP+pbo/jNBzRsMOuALTJRH0khVYw7tx51uwpdhTqbUMRClRIeEljDS8G3l+7L7jOFQiT5H8EnZmDe/YHg2HnmhdYyzD8CtRJe8+ap6Q37Vwf3Di5yQvhovagvLDACx3+LXrpkkccOihkwZWQga2rkt9ealDvMesGFz63gfXS6stsGHvEjDpJU30UmOhO/y63XZTdzz2PoXsUNvS933JwJGAK/U9xRhJbofmLSbewh57UR36Ob7ug/PAohhfongikVuMtXbTtmHvA8adr8kY8LcuMQ0nwmDYnD5iWOjjkRVvNhuPOO/tDtGwoDyWVPHb2wLuj8wrvlqxIxa/bTa/QIijVvkE3L3DP8Ma1oXgZkVs1Xz9hkaoVGGKcNMSFtPAqkGdtY1odWByTKeBUkq0hBOIAEPrL5lDnG3DruhUDSdZrCziWDnrpset17p309SWiNbAiDBsvMF2SkhCcdZD3hVmzh0CiqAhwz6JqC3xp3c4QWuHzFprxhOse3tz2lLCkVatGPrmUCUbUISdOGsVbWtJ59sCYNpTNMxG7jHCAizuFc0iE6Bc8Vr7lnuMmsBw7IDht9sJOXa2u2Eh2KT2TifRMEuCBcbcsIpL0+ge1i9ja5sZRRruDLMHgQVyXgN7j1vbt7gDFuCmHDaXMHTLiqWNjpkb/ltb23PXywEWtYZVt5+zdtiyeoQdrGuV1XM7FBo9vWn1GCOGuw7PhuWK1+tnNANa+DqKXa8UH2HmJewQ8Z/1zagwD80qEcWAwF5vCGv680d2HMXpS3ts0uxoeBRaxxLpCXyzV3fhnenB0LzbOYfXB7yzXXjHTvoxfpfFvbfgL+JnRyf3vnAGAAAAAElFTkSuQmCC';
string public constant unique48 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAAbFBMVEX///8BAQEAAAAA/v4Bqv8lTUoXFCW6PUfSZm5DjEYycE3RtpicEhz78NqCqFlSITP/srkWPDpsLzLng4psAAAcGSr/////ys694ZcQMzH8/PzMzMz/3N+oqKiioqLq6uoAJCEQPDn/vsMAAACLIMA2AAAABXRSTlMAAQICA9JshoIAAANmSURBVHhe5dbpjuM2EARg56i+KFKSr7n3SN7/HdNFy8AsYWTGCfbX1hiwTcznbrZpQbuflD8+B77Kl90vkq//w8p9hX6Y6Z0D/nv3q+fPAQxTlGv+w7cnwbwui8rdp0YW88yi+kp9VyRV16+LvS53arHHFpnkpip3nSyJ1pr3REY+e6alJwB6oDVybkLk41+TsFcBvPUA7uHWrLl84lKVUPDt23dq/355wUZu9/vbgCPx+XyGu2/PoL3mgx2H4OXlhbg/w2lVawWbIb9NPQIQQaa3DYbzRq0Fzgl63NSCR79oltjS/1tKLbRNl5ua1mk7rk+ypRKXpAj3pkoMuYFTXvHVPlV4IOMR1CyA4y3cNTJS6lP/E+7Ut/XOPQB9p7/0UyMbZdhnY8rzhjcNYlWT4bxKp8fjkRjx3AC09hZIi2uU2sbfeMdJazk6PARvfXd425rhtCGmisQWAxYEoLWa+dInGj3PCJRaS6rEunTdxnn3rmuxo6kaHsmZcChTS7CymRoiM2LWMFOYmqI1cw/33HrplV0DklqpByxYet8mYuyteQaegTJenEB0m8GPeDGNy6KoLQtdIIhLZeUOJLxBlbMbLKtwTdj3gl4ingFlUAsL09aq+iNWDfdtKxyqsTTWdfXLnmvpuBEXDYyz9ndalXC1B11XoGRqb6pbFh4wLhFySXo+HDhbjXWdmUvX3TYZMP4yiwyHKvN6NmUmnR6madpsjdZ46B8HDCgt4C4CzKbTedL9XvcHTYuASK0ltbfMWDk8A0QIAkh8mB7m+WE2dfTpZVVN6e6PxO/sFWf4BmGTTjYnTRwoHYeyqkfzEW/jhqC/wSG3qrMeVN2jFIe3sI7FfWhbwgNAiISDr2ya99Oklrh54sbmaUPkBs4AIu7QAsyH/X7e782mJF5aC3Em4YhFQB1BrEWPmG3PzA8dg+0Gh004Xgv4cQwPv6eVxL9TH6ZIzbDt21dt4m0HmaPsjHK3Px0m7giM9Ny6bRVsGBErIHa6YJu4hFqLybtGh8gVr2udINpLn3YdW0msMt5cjJi61GmSyfanE/Ehl7SUCshHt8MixDbJTk+7XT5MEyMTHvLhvRsQAfbNhQ0nTOxD7SFCGIkBmS5YJ9oLjn/HESNmYSeGu3+EkXi4uEq3iI/wu9xaHfA/nrxATzuNntUAAAAASUVORK5CYII=';
string public constant unique47 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAAyVBMVEUAAAAAAAD/AAD//wAuLi4AAAD/bQH/qwL/bgL//wH/qgIaGhobGxsAAAD//wEAAAD/bQEAAAD/bgL//////wH/qwJ2Y1ppAACiAAD/TQIBAQH/mQEtLS0/Pz9UVFT/bSVJRUWNjY3/ywL//xQnJyf/AQE5OTn//db/VAL/tyMREREqKir/hy1IAAAbGxv+/v5AHw8CAAAtCAAtLCwDAwH/cgf/cgg2NjYlEAAIBwf/sneysrLKygD29vb4awH//wL9bQH//yT+/gELlsTbAAAAEXRSTlMAAQEBCxa40tfa6fn7/Pz+/i9v7RIAAASfSURBVHhejdWHciM3EARQnWMOk7CZmdJl55z9/x/lbmDBrRUl+1risXilp2nMoko3j0bdY/355o2jwFqYuxteIf+PZhvmmrFqBFtEb0Uf3wCztecUrL111PFfo12LNTpDwl2hYRu5Bj6zuGD1sAs2vtG2b4BdidwWWuy5eQhrfa86s/Ly2XbWNg9jL1NDI3MQW+Wfn2jbFvYhXBIffpax25YxG7a0/l1nh6Zp5VjF0RYdXo4eYe6wvt3umMGHAbhvsSzauODF8sGgN9z8gECLNWja9sADH1WaDF6ueoNQVwyY5sm77UDcdbDHZ9JIlStcd2V5cLKidzunLfiltE13jd3N88GfGgKMyTW5NbE9I355H38ATA3ssEKzwm17OMjfz8S6Tu7h8Bn7zVNoYnqZ8SvDtolRu+0EYK0D2FTNDL23g/sgO+HbBXcHocU1e0yzALDbnQP7nfmMD8CtmLQCe40/yrrirMrbAHw+HzrezqNsGjxpQVb6PddFs7bgKcdQcHvm7YQW2wBa16y0yBfffMVhbI7LWTMMW2AuG7iR/X7TdodmbZ/I7pPXANRmi7XhbsvrmYUfZL+5leud4bG83ikxg/fydYfr+TtGdzw0VrZBbY69wh9zSQo94DvMLAxH3tpvgdFnjsZgjqZdY2TcUZOxubvsaC0s79sPwLQPYYZYw1XrFTXmyz/7zg5u6LuHvSVe54Ij3D1sy0B64NW/Opthcs7xePOwPkkePZAwbrT6A4ofzs0LsVt5H5PXDlaD+DQ3j6zZwSNCfsXo5sfnshcJXWFJxOFOrMDsHs5Qqk7T9yjePMd5N2IzlhnbJBLqFtB+qjoqnpBffm4UGLU9qEWmrGVK0ySw5iyO5hilSFAqLf7zDxHRXBsYZkoXLEiE60itPPg0R0ERYZS1dRwF1haM10n45xhaMefFEgfVbNEVd4TtJCXYii2lUwg/K2aXFDsPpQU2kYRmsAtOyU9x0lJEZRUCBw3i/UZO0ADTjFkCB0X4I++oadQ4d66uAkp8e0vsKWnFc4jLaPX5b6ubWajGaQzSURiU9mqBpxwpOIK4xsNV83nQb2SSJAOoeJKcJCe9udJGW7AgI76mAKYknn8hRs9LhY7Mw9xhxxGaLkd0Mg5etp2s4FH4U+KBWAQpbZCKJYR4Ulkm142xhJR/akhFnbh+XE5MnJPtBMZbWmO5pqEWaK29WODEWMEpyah20YnYTYGh59q0NbXmiZ0StJqzfMFsApuomXGNeQb6SXwsOpwLKiGJgmvtapd1G2dF1qMEkM9nxhgpuNamWbB8/qlIrm/EZTlKnIihiaFznjwhWoKPtNTEKhgWc8eM0ccD2m6FYJ2Kg5NjYo2Y91PxZMB7EXnM6kisGeck2oKdPTa3j2PqxOVD1xQ8WdJSG1XewjnXuD5ZYJ3G4GwvpakdvaOXzUb6/t2311h0Xiax8bkDiF46Ktfdt+1m0ze9fL3CeQqTZPTJMVhHkFh64SSpb63rm6b3b2VVGc6cNzvxvik/3NsIjg196Jp+HP8aZY1tVNo0UY8e15i6a4CZRZf7VCwv+aiq9zBs1n0/ZVvwv2Ax6SQC5PzNAAAAAElFTkSuQmCC';
string public constant unique46 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAAXVBMVEUAAAAMDA0XFCUbGxs9PT0nJyc5HyFNRERdLChdXV1wYmiKSDaMe4muSzjEJDD2gYehlqiJHit4EzG/b0qKWk31VV3/f1WoKDz/mnL90u0zHBxXHCddOTa/hWpPKyg3WNeTAAAAAnRSTlMAAHaTzTgAAARsSURBVHhehdYJYts6EAPQFCS1L96ztf/+x/wAhrKttGmRNDapeZ6RnMp5URCpz+LHN9Hh3XGMZ2UUypJdYGyprB4fXXvHlNZjhx7LslTzdst93+d8C+Yjfe20x6NDvK4rchabQ9/eZr1E1hHj0fhZN11H3FWNrFAzb2+zaLWsaah3Jz02DQC+gsZjUJT5jbnNfIZjHbpDQ2xbA/XUI49QHxmUnKnnm2yue9lvBkck3mlicxR8MsQ6U3I/0Z7sVrsLuia0MDVm5JxS6Qu/EzsrxbbxkHt9xzovEJecliWVkpaUuSQzwhf7vIfRU+F2A9iaTZOscGSPgfqz4rMxxHP2ieMNwL6+BkvgCO25Ey4ZNEV99YgNfmm1UgPZKQAbM8LWKRXcUIyAwgDuWDtT556xJscwTQOExWSJuYNUSlaA5Y6XlVmO1MIlTcpveBo4hK/B5yf7GVubH93aeBjAMuOUAg+DMO1R5e7s4POonYpTGoa2RbGuOBe0xJyallPaRtBT0wam5dSNdT8Lz7RDy6TAy/Fo6yD3/M3NTiGeDodDM0I8cCk4DIGlbbdAPao1nibiriGvGM0UmDqz0TMudjUpaeqReJrwHzF/jM1EnYgjz9iQzW0D21JD/5o7zr2bCz90LpkqkzKygUmmmKMxZlHfJ9g+dMrqlzKDoTZ2WuMusK5HSsMX2w7sxyAlPrdl+QM3xmCRssf69WHV4UDOizoId9KDVlxq1bYsq0VfMPsdiAdhWY86qHOjpTVoVWWMZ1wbn2HLUaTB+NpppRNivmC0wsqA8wjatuUdt+ng++Z8m3mcK5ZF1Q4PinBLCdr5pns9csn8BviZwZNBax0Yzzgujm/JmGkB0DZdx/NtgNvcgpjRtf2CJ4dDd6g3zkw0+uNrPItz3zTeK6x7fDhU/BJ0bM50Z24150YTUUfhHrf3N9A17Mlqkg2PxNQbpl4D71u78cjIN9QjLb+4hOqshZdnvLUGonPXifihLre5FdDucWQAuo1Y/mIu9HDhVvSE252Wu4hcPj4ufCL988OFjyLDfeuWGgYhPn6GvoQdyELvsPVhaltjKBcJ6l9QjGnbYd/a2HzQ/Lj4pgaPCq4yUxCN27b9U+tJkBpAES7QqCi2gSfjww5rX7vuDtb3sjkm1Z2R695YnyWcj+d3qHMj3sE2OJCiPhlzlUl7dgbqfPYbXokJzWlznfpxU/cS7+uKSdh+w694+QFzMIlTKxvurfFO+4qJ7GGNV+AHOfD66qtF3SdEUolTJmUA7Ky0OA9dr9TEPsf1XanLDNHT6XS9wjF0cHpdZRkk2ZyJHSRp45Os2T7se6Ld4dcIKja9mv7Ohd/fryhQSrrjFDumtH/WFcN/NwDXU8228y3VK9dzPibl+NCxcyT9ti1Ltyn9hwleyB2knFPf034XV/qdyTUshpP7lHptON9xh13je2uFTJ3j97vX7rdhm8I2ic1CA33F/9YIKx+YVrgUa77o33DW4NADtv/PhCmRp5T19Yz/B1qoWtHkxcTEAAAAAElFTkSuQmCC';
string public constant unique45 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAASFBMVEUAAAD///8AAAAYACAQaEwQODgijj5KGithHceDMbe4Qf/GsXd6MjuPfJqvn79hXYDf2/b/67U4NU1yzD7gAABOQUaiU0J+aWb/rhT/AAAAAnRSTlMAAHaTzTgAAATpSURBVHhetdbbbvQ2DATgZKizz3vI//5v2hnSjhOgBdqLMgvE6+y3IxGSnI//t4ATQGDct37X+Fs6nRjHpWEV458xvFy4va+GcJ2/pG90a0B//ZoNFL+xLPEs/NuO0Z1WQlXFb0s8dseVfxxifuO2F5XH5CIwLT76fkXPgfveB6/GHlby1CZxdyFntH5FK8r1wbrunvJLr/qNKZFYwq6/xh69P+zgq59tPLWK0YFREm0poYU5zhPXgy9iGBGlxwtTyxLmRCzfh4q2Ou7TwZo6YC5qtW9dhZEzrSqXZxuTf7oJS7fjaPwK1DnSgEv7mwxIllJyetIaf6YhHNlT/8DkgdUUBKuu420K+yRO7FA9KltEHNWaGnrbWwsTun0WXsckj+nGlNTEVxA1aqWuNdqcZRNxoTba2W58uD6ttDi1cGEJjwTXx3R0Y/CNqUHLSsxJsaBoiWO2ZaQE6cZF22CBgVPDMKUXwI8Cr3R84yHcORwC6dZKQmB9yWfsAUwcoYasoR5J2JIGXJC7LMt7wHtJmtAYDlqz6ZBObqdk7JkwNXLubj07sXslI7AZNexNfKSo48L8YFer0Mc4DxJ2Txnf2GT/WJ6m7MWLko3WEm18UDsKwtH/VED8Qf1+0/5BVmtVPnebLduhvdCFR99BjGdK0FJIgQXfDDbq7HPO6q3NmZh7fZBLYw2ckQt1NPCPCoyX1qBEoeBk0yS9U9MuwnRAeZ72hZX2pXQgR8GsGoPTs5BL71jXhzCtGc5uC694vSLeOU6bjPNXu6ixK9i3NyrxtUpWJnuuJDnsstNBq4xOvCiYGjZXyAq/V6cUyMbpUtaaaSvnS6sQBT8WdGHjbvu2EWuTvZEPq+kqS4k6lxMv24lrHG7DMQDGvmgTV3iqLDPt+CJdHA/s27KgBVZwj2TZl3K5oLXu9Q0HtU2lSCfIEq+Bl0rch+Pp/Z4OHIAv2CzMRD+PiyoNx+u2rowWXjYwWPV5vF7Hy8B1KYxM64n8CZsfIF6IFY3HStxHYLzZrctqJHFOTxPnTJvHtpjwY/Vo4vXGn2CFzTg3rCIFtQHGuhKvy2NxvT18tezjxEwqlw1NnghVy9gflgeIqZeFeF/Q9tGFrw+HDX1WPFp2qya8npp4wy+cAdnAjNiZEo+W3scMYteLsDrWZFXSP4O3zTM2f7S00Yfha2ANHXjFuPFPDTyi/NEyeq/gc3tAZvUBqHno31hrQXicM57nyuK4A+uR53pbt4eatrkerrnnUxrE/TOGQf5FwZVSOWzMQ4cJNd3jseGxxS4ZgZ+Ovw/Hi+th1zrp3ntr0LABGFTtwkPH2uCKhZ/yrkHNlzSrmVkDNg7dqqGxOFBqDB0Yo330BllhakmlV1MWMajjHwfvbeABRtE6DqtoSeE5i9b6FYHgXHBax6n0AdnkwZq38Fx92hmkujBHwBW8a7TIuY1+B5fAM6pnK3euXmR3tb53NoRBbbB/wredM/OEZS3q1h4N9P4suQculyWuOc/QWclEP1N5/Us3MJTdiX8JkYLSgsFM5i/AbYQDPzRKbszNtOWJa5m7rRmYwWBcVuk/ssHMZ1FwT+mJD+nwxHxb4b+kRNmBHxoZJawY7ypcdxzp7aybBKJed8sB5CzbG1hxK0pWTlj2LuKbg7R9/H3Bc24bk/63RSt8F+1/LNz1bf8C5BZYgnUfJFgAAAAASUVORK5CYII=';
string public constant unique44 = 'iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAMAAAANIilAAAAAQlBMVEUAAAAAAABLPyOdn6oiHxRzGSI1PEB8eEB1iJE1ESLM1dvPOULGsXdXbWgZCCwjIknt59qMHynBICArPnNqERGZm5lSGMcoAAAAAXRSTlMAQObYZgAABBhJREFUeF6d1AmO4koQBNDJpVav0P3vf9UfUWk8Vhs0owkBxipeZW3mV0SQX/8WEdcy/5sWL7NqKf+khdL1hoX5k3V1aHH5Qbd129Y/ePGiAuoiV7puX+vXtqKD4J+x014GLlBfwPzE189cUhlaVV94lAWFg9/gP2iZkg6MnBYCMyaGHXfyEXfT63w31lOl44WjQO0P2JArDluotby0IHc75eruVc7N5UTVuX3rWA3FFOa5KPZSfuKWnf2/MNC8hSpaoo9tcx32heXArblaN/XfGlPl+rlSIBh02C7h5MSTG7DVwJKlb+uufX8Kispz77pvq/samE5MzvXinBkZDXWXr3XfAWFnXnbidZ2kWx7eTpwSbOGwlMc0NqrveynF0YDsGIqsCbbiJWJ7feGWuERwLDSrxKmyTl3CGubskrNU2Gy9ZuLQA7NwaKF3aFfEOyyw5For3rRROLSTqbqSc3emKYmOu2jAKXGpte8oaVZZ+KJhzpRZp5Q4EByMmBCw1KVax4Bz2KsG8qjCmeMkOzW7hHU8XnmBstp7lrBXjWhofOIRHMeDfYl4xwJmkVzzqH0/4QJPqK7EmwKCg6rphPOvKqN2rgZ999DO0jNwUXJQBU4psYk6y1tNPoQWzLm8NqBbXtZ1VYZbLZID3xK6zNs8z9QsW0x1+4oFEZkd+gMWANFy2G5qpSylYJ+5caNjHOAPeA39quoY8xKz15d20E/Ywbhy3bK5LA7IiA6NdW/tveahZmnUNVdWdS2MygpNSp3eavkC9qFNFdIVgXVg15SmydVbmuR9ZRlntUdV4kIv/PNsKcUfE/qQd4WFFzfnS/duZkfhFbjB8qZRvy3MRTPrvS+9Z8vVcDVW5hmKh0ySJOq7JV6Y3LMsfBp4ExMqwDNwE+aGY+wppYbY3nvFFbeyEjtL69tTIuvAG8aE0PdcMT8msdAoXRzy7XMV5QND12wphaaN0oCfIr9tbUuzZMDwQeTEIm+r0zbitOSWK0t7OjFPGzNN9kYDp+a0jUkJUg8cT0eBREw+WG20gVUnlYgWh1bgx+Ox3LCo02qTayTnPFGgqQDjCxraRd9+jixIPvKABo5JwxGf6pu/jQT4fllczWx5tBZ/xlGqPQa26Ru5YLgD9xGjFREXLYFBH6wcOuz3BT+fpxSGxDUsZn1uvdk0RvdNDEP3BCZjPCoDIUNw+YhD91EYiHmaYSgHVLUx9RruhyWGHsVilBFMrAHXCpkrIxdMG/iwR7WcAdPxrpAGeNXyID517/+NgXLwsOz8wLFTB+5y4MfjgpkFrbGxbHh1QHtozmkYacSX0DK2wEZie0CpATkImruWoFxZmEskh87I2fbjZKNvdr7cMDXtBQe/4iX/bD81uN3arji/MO2dRwJ8bob96/wPvD86LPNf8TEAAAAASUVORK5CYII=';


}


}
