//
//  MorseCode.swift
//  Suno-Watch Extension
//
//  Created by Adarsh Hasija on 03/10/19.
//  Copyright © 2019 Adam Behringer. All rights reserved.
//

import Foundation

class MorseCode {
    
    var mcTreeNode : MCTreeNode = MCTreeNode()
    var dictionary: [MorseCodeCell] = []
    var alphabetToMCDictionary : [String : String] = [:]
    var mcToAlphabetDictionary : [String : String] = [
        ".-" : "A",
        "-..." : "B",
        "-.-." : "C",
        "-.." : "D",
        "." : "E",
        "..-." : "F",
        "--." : "G",
        "...." : "H",
        ".." : "I",
        ".---" : "J",
        "-.-" : "K",
        ".-.." : "L",
        "--" : "M",
        "-." : "N",
        "---" : "O",
        ".--." : "P",
        "--.-" : "Q",
        ".-." : "R",
        "..." : "S",
        "-" : "T",
        "..-" : "U",
        "...-" : "V",
        ".--" : "W",
        "-..-" : "X",
        "-.--" : "Y",
        "--.." : "Z",
        ".----" : "1",
        "..---" : "2",
        "...--" : "3",
        "....-" : "4",
        "....." : "5",
        "-...." : "6",
        "--..." : "7",
        "---.." : "8",
        "----." : "9",
        "-----" : "0",
        "......." : "␣"
    ]
    
    init() {
        dictionary.append(MorseCodeCell(english: "A", morseCode: ".-"))
        dictionary.append(MorseCodeCell(english: "B", morseCode: "-..."))
        dictionary.append(MorseCodeCell(english: "C", morseCode: "-.-."))
        dictionary.append(MorseCodeCell(english: "D", morseCode: "-.."))
        dictionary.append(MorseCodeCell(english: "E", morseCode: "."))
        dictionary.append(MorseCodeCell(english: "F", morseCode: "..-."))
        dictionary.append(MorseCodeCell(english: "G", morseCode: "--."))
        dictionary.append(MorseCodeCell(english: "H", morseCode: "...."))
        dictionary.append(MorseCodeCell(english: "I", morseCode: ".."))
        dictionary.append(MorseCodeCell(english: "J", morseCode: ".---"))
        dictionary.append(MorseCodeCell(english: "K", morseCode: "-.-"))
        dictionary.append(MorseCodeCell(english: "L", morseCode: ".-.."))
        dictionary.append(MorseCodeCell(english: "M", morseCode: "--"))
        dictionary.append(MorseCodeCell(english: "N", morseCode: "-."))
        dictionary.append(MorseCodeCell(english: "O", morseCode: "---"))
        dictionary.append(MorseCodeCell(english: "P", morseCode: ".--."))
        dictionary.append(MorseCodeCell(english: "Q", morseCode: "--.-"))
        dictionary.append(MorseCodeCell(english: "R", morseCode: ".-."))
        dictionary.append(MorseCodeCell(english: "S", morseCode: "..."))
        dictionary.append(MorseCodeCell(english: "T", morseCode: "-"))
        dictionary.append(MorseCodeCell(english: "U", morseCode: "..-"))
        dictionary.append(MorseCodeCell(english: "V", morseCode: "...-"))
        dictionary.append(MorseCodeCell(english: "W", morseCode: ".--"))
        dictionary.append(MorseCodeCell(english: "X", morseCode: "-..-"))
        dictionary.append(MorseCodeCell(english: "Y", morseCode: "-.--"))
        dictionary.append(MorseCodeCell(english: "Z", morseCode: "--.."))
        dictionary.append(MorseCodeCell(english: "1", morseCode: ".----"))
        dictionary.append(MorseCodeCell(english: "2", morseCode: "..---"))
        dictionary.append(MorseCodeCell(english: "3", morseCode: "...--"))
        dictionary.append(MorseCodeCell(english: "4", morseCode: "....-"))
        dictionary.append(MorseCodeCell(english: "5", morseCode: "....."))
        dictionary.append(MorseCodeCell(english: "6", morseCode: "-...."))
        dictionary.append(MorseCodeCell(english: "7", morseCode: "--..."))
        dictionary.append(MorseCodeCell(english: "8", morseCode: "---.."))
        dictionary.append(MorseCodeCell(english: "9", morseCode: "----."))
        dictionary.append(MorseCodeCell(english: "0", morseCode: "-----"))
        dictionary.append(MorseCodeCell(english: "Space (␣)", morseCode: "......."))
        
        for (morseCode, alphabet) in mcToAlphabetDictionary {
            alphabetToMCDictionary[alphabet] = morseCode
        }
    }
}
