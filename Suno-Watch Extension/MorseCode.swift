//
//  MorseCode.swift
//  Suno-Watch Extension
//
//  Created by Adarsh Hasija on 03/10/19.
//  Copyright © 2019 Adam Behringer. All rights reserved.
//

import Foundation

class MorseCode {
    
    var mcTreeNode : MCTreeNode?
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
        dictionary.append(MorseCodeCell(english: "Space (␣)", morseCode: ".......", displayChar: "␣"))
        
        for (morseCode, alphabet) in mcToAlphabetDictionary {
            alphabetToMCDictionary[alphabet] = morseCode
        }
        
        mcTreeNode = createTree()
        var i = 0
    }
    
    func getNearestMatches(inputMorseCode : String) -> [String] {
        var nearestMatches : [String] = []
        var node = createTree()
        
        for input in inputMorseCode {
            if input == "." && node?.dotNode != nil {
                node = node?.dotNode!
            }
            else if input == "-" && node?.dashNode != nil {
                node = node?.dashNode!
            }
        }
        //We have reached the final node. This function is only called when there is no match so clearly there was not a match
        if node?.parent?.alphabet != nil {
            //take it
        }
        if node?.dotNode != nil && node?.dotNode?.character != nil {
            //take it
        }
        if node?.dashNode != nil && node?.dashNode?.character != nil {
            //take it
        }
        
        
        if destroyTree(node: node) {
            node = nil
        }
        return nearestMatches
        
    }
    
    func createTree() -> MCTreeNode? {
        var i = 0
        var node = mcTreeNode ?? MCTreeNode()
        for morseCodeCell in dictionary {
            let morseCode = morseCodeCell.morseCode
            i = 0
            for morseCodeChar in morseCode {
                if morseCodeChar == "." {
                    if node.dotNode == nil {
                        node.dotNode = MCTreeNode(character : ".")
                    }
                    node.dotNode!.parent = node
                    node = node.dotNode!
                }
                else if morseCodeChar == "-" {
                    if node.dashNode == nil {
                        node.dashNode = MCTreeNode(character: "-")
                    }
                    node.dashNode!.parent = node
                    node = node.dashNode!
                }
                
                if i == (morseCode.count - 1) {
                    if morseCodeCell.displayChar != nil {
                        node.alphabet = "␣"
                    }
                    else {
                        
                        node.alphabet = morseCodeCell.english
                    }
                }
                i+=1
            }
            while node.parent != nil {
                node = node.parent! //Go back to the root so that we can traverse the next character
            }
        }
        return node
    }
    
    func destroyTree() {
        if destroyTree(node: mcTreeNode) {
            mcTreeNode = nil
        }
    }
    
    func destroyTree(node : MCTreeNode?) -> Bool {
        if node?.dotNode != nil {
            if destroyTree(node: node?.dotNode) {
                node?.dotNode = nil
            }
        }
        else if node?.dashNode != nil {
            if destroyTree(node: node?.dashNode) {
                node?.dashNode = nil
            }
        }
        //node = nil //This line does not work so we are returning a bool instead
        return true
    }
}
