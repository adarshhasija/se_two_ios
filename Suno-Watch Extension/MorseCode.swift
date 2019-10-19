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
    }
    
    deinit {
        //destroyTree()
    }
    
    func getNearestMatches(currentNode : MCTreeNode?) -> [String] {
        var nearestMatches : [String] = []
        nearestMatches.append(contentsOf: getNextCharMatches(currentNode: currentNode))
        if currentNode?.parent?.alphabet != nil {
            nearestMatches.append("Delete the last character to get: " + currentNode!.parent!.alphabet! + "\n")
        }
        if currentNode?.parent?.dotNode?.alphabet != nil {
            nearestMatches.append("Replace the last character with a dot to get: " + currentNode!.parent!.dotNode!.alphabet! + "\n")
        }
        if currentNode?.parent?.dashNode?.alphabet != nil {
            nearestMatches.append("Replace the last character with a dash to get: " + currentNode!.parent!.dashNode!.alphabet! + "\n")
        }
        
        if nearestMatches.count == 0 {
            nearestMatches.insert(" " + "No matches found", at: 0)
        }
        else if nearestMatches.count > 0 {
            nearestMatches.insert("No matches found. Please try :-\n", at: 0)
        }
        
        return nearestMatches
        
    }
    
    func getNextCharMatches(currentNode : MCTreeNode?) -> [String] {
        var matches : [String] = []
        if currentNode?.dotNode?.alphabet != nil {
            matches.append("Add a dot to get: " + currentNode!.dotNode!.alphabet!)
        }
        if currentNode?.dashNode?.alphabet != nil {
            matches.append("Add a dash to get: " + currentNode!.dashNode!.alphabet!)
        }
        return matches
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
                        node.dotNode!.parent = node
                    }
                    node = node.dotNode!
                }
                else if morseCodeChar == "-" {
                    if node.dashNode == nil {
                        node.dashNode = MCTreeNode(character: "-")
                        node.dashNode!.parent = node
                    }
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
            //Still on the final ./- node of the character
            
            //Additional empty node is created as a terminating node. The purpose of this is to allow the user to enter an additional character and we can verify that there are no additional morse code characters to be met. Then we can prompt the user to stop typing
            if node.dotNode == nil {
                node.dotNode = MCTreeNode()
                node.dotNode!.parent = node
            }
            if node.dashNode == nil {
                node.dashNode = MCTreeNode()
                node.dashNode!.parent = node
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
