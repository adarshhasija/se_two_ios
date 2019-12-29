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
    var mcArray: [MorseCodeCell] = []
    var alphabetToMCDictionary : [String : String] = [:]
 /*   var mcToAlphabetDictionary : [String : String] = [
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
    ]   */
    
    init() {
        mcArray.append(MorseCodeCell(english: "A", morseCode: ".-"))
        mcArray.append(MorseCodeCell(english: "B", morseCode: "-..."))
        mcArray.append(MorseCodeCell(english: "C", morseCode: "-.-."))
        mcArray.append(MorseCodeCell(english: "D", morseCode: "-.."))
        mcArray.append(MorseCodeCell(english: "E", morseCode: "."))
        mcArray.append(MorseCodeCell(english: "F", morseCode: "..-."))
        mcArray.append(MorseCodeCell(english: "G", morseCode: "--."))
        mcArray.append(MorseCodeCell(english: "H", morseCode: "...."))
        mcArray.append(MorseCodeCell(english: "I", morseCode: ".."))
        mcArray.append(MorseCodeCell(english: "J", morseCode: ".---"))
        mcArray.append(MorseCodeCell(english: "K", morseCode: "-.-"))
        mcArray.append(MorseCodeCell(english: "L", morseCode: ".-.."))
        mcArray.append(MorseCodeCell(english: "M", morseCode: "--"))
        mcArray.append(MorseCodeCell(english: "N", morseCode: "-."))
        mcArray.append(MorseCodeCell(english: "O", morseCode: "---"))
        mcArray.append(MorseCodeCell(english: "P", morseCode: ".--."))
        mcArray.append(MorseCodeCell(english: "Q", morseCode: "--.-"))
        mcArray.append(MorseCodeCell(english: "R", morseCode: ".-."))
        mcArray.append(MorseCodeCell(english: "S", morseCode: "..."))
        mcArray.append(MorseCodeCell(english: "T", morseCode: "-"))
        mcArray.append(MorseCodeCell(english: "U", morseCode: "..-"))
        mcArray.append(MorseCodeCell(english: "V", morseCode: "...-"))
        mcArray.append(MorseCodeCell(english: "W", morseCode: ".--"))
        mcArray.append(MorseCodeCell(english: "X", morseCode: "-..-"))
        mcArray.append(MorseCodeCell(english: "Y", morseCode: "-.--"))
        mcArray.append(MorseCodeCell(english: "Z", morseCode: "--.."))
        mcArray.append(MorseCodeCell(english: "1", morseCode: ".----"))
        mcArray.append(MorseCodeCell(english: "2", morseCode: "..---"))
        mcArray.append(MorseCodeCell(english: "3", morseCode: "...--"))
        mcArray.append(MorseCodeCell(english: "4", morseCode: "....-"))
        mcArray.append(MorseCodeCell(english: "5", morseCode: "....."))
        mcArray.append(MorseCodeCell(english: "6", morseCode: "-...."))
        mcArray.append(MorseCodeCell(english: "7", morseCode: "--..."))
        mcArray.append(MorseCodeCell(english: "8", morseCode: "---.."))
        mcArray.append(MorseCodeCell(english: "9", morseCode: "----."))
        mcArray.append(MorseCodeCell(english: "0", morseCode: "-----"))
        mcArray.append(MorseCodeCell(english: "Space (␣)", morseCode: ".......", displayChar: "␣"))
        mcArray.append(MorseCodeCell(english: "TIME", morseCode: ".........."))
        
        for morseCodeCell in mcArray {
            if morseCodeCell.displayChar != nil {
                alphabetToMCDictionary[morseCodeCell.displayChar!] = morseCodeCell.morseCode
            }
            else {
                alphabetToMCDictionary[morseCodeCell.english] = morseCodeCell.morseCode
            }
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
        
        if currentNode?.parent?.dotNode?.action != nil {
            nearestMatches.append("Replace the last character with a dot to get: " + currentNode!.parent!.dotNode!.action! + "\n")
        }
        if currentNode?.parent?.dashNode?.action != nil {
            nearestMatches.append("Replace the last character with a dash to get: " + currentNode!.parent!.dashNode!.action! + "\n")
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
        if currentNode?.dotNode?.action != nil {
            matches.append("Add a dot to get: " + currentNode!.dotNode!.action!)
        }
        if currentNode?.dashNode?.alphabet != nil {
            matches.append("Add a dash to get: " + currentNode!.dashNode!.alphabet!)
        }
        if currentNode?.dashNode?.action != nil {
            matches.append("Add a dash to get: " + currentNode!.dashNode!.action!)
        }
        return matches
    }
    
    func createTree() -> MCTreeNode? {
        var i = 0
        var node = mcTreeNode ?? MCTreeNode()
        for morseCodeCell in mcArray {
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
                        node.alphabet = morseCodeCell.displayChar
                    }
                    else if morseCodeCell.english == "TIME" {
                        node.action = "TIME"
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
