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
        populate(type: nil, operatingSystem: "iOS")
    }
    
    init(operatingSystem: String) {
        populate(type: nil, operatingSystem: operatingSystem)
    }
    
    init(type: String?, operatingSystem: String) {
        populate(type: type, operatingSystem: operatingSystem)
    }
    
    func populate(type: String?, operatingSystem: String) {
        if type == "actions" {
            mcArray.append(contentsOf: populateActions(os: operatingSystem))
        }
        else if type == "morse_code" {
            mcArray.append(contentsOf: populateMorseCodeAlphanumeric())
        }
        else {
            mcArray.append(contentsOf: populateActions(os: operatingSystem))
            mcArray.append(contentsOf: populateMorseCodeAlphanumeric())
        }
        
        
        //mcArray.append(MorseCodeCell(english: ".", morseCode: ".-.-.-"))
        //mcArray.append(MorseCodeCell(english: "+", morseCode: ".-.-."))
        //mcArray.append(MorseCodeCell(english: "-", morseCode: "-....-"))
        //mcArray.append(MorseCodeCell(english: "/", morseCode: "-..-."))
        
        
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
    
    func populateActions(os: String) -> [MorseCodeCell] {
        var array : [MorseCodeCell] = []
        array.append(MorseCodeCell(english: "TIME", morseCode: ".", type: "action"))
        array.append(MorseCodeCell(english: "DATE", morseCode: "..", type: "action"))
        if os == "iOS" {
            array.append(MorseCodeCell(english: "CAMERA", morseCode: "...", type: "action"))
        }
        else if os == "watchOS" {
            array.append(MorseCodeCell(english: "1-to-1", morseCode: "....", type: "action"))
        }
        
        return array
    }
    
    func populateMorseCodeAlphanumeric() -> [MorseCodeCell] {
        var array : [MorseCodeCell] = []
        array.append(MorseCodeCell(english: "A", morseCode: ".-"))
        array.append(MorseCodeCell(english: "B", morseCode: "-..."))
        array.append(MorseCodeCell(english: "C", morseCode: "-.-."))
        array.append(MorseCodeCell(english: "D", morseCode: "-.."))
        array.append(MorseCodeCell(english: "E", morseCode: "."))
        array.append(MorseCodeCell(english: "F", morseCode: "..-."))
        array.append(MorseCodeCell(english: "G", morseCode: "--."))
        array.append(MorseCodeCell(english: "H", morseCode: "...."))
        array.append(MorseCodeCell(english: "I", morseCode: ".."))
        array.append(MorseCodeCell(english: "J", morseCode: ".---"))
        array.append(MorseCodeCell(english: "K", morseCode: "-.-"))
        array.append(MorseCodeCell(english: "L", morseCode: ".-.."))
        array.append(MorseCodeCell(english: "M", morseCode: "--"))
        array.append(MorseCodeCell(english: "N", morseCode: "-."))
        array.append(MorseCodeCell(english: "O", morseCode: "---"))
        array.append(MorseCodeCell(english: "P", morseCode: ".--."))
        array.append(MorseCodeCell(english: "Q", morseCode: "--.-"))
        array.append(MorseCodeCell(english: "R", morseCode: ".-."))
        array.append(MorseCodeCell(english: "S", morseCode: "..."))
        array.append(MorseCodeCell(english: "T", morseCode: "-"))
        array.append(MorseCodeCell(english: "U", morseCode: "..-"))
        array.append(MorseCodeCell(english: "V", morseCode: "...-"))
        array.append(MorseCodeCell(english: "W", morseCode: ".--"))
        array.append(MorseCodeCell(english: "X", morseCode: "-..-"))
        array.append(MorseCodeCell(english: "Y", morseCode: "-.--"))
        array.append(MorseCodeCell(english: "Z", morseCode: "--.."))
        //array.append(MorseCodeCell(english: "1", morseCode: ".----"))
        //array.append(MorseCodeCell(english: "2", morseCode: "..---"))
        //array.append(MorseCodeCell(english: "3", morseCode: "...--"))
        //array.append(MorseCodeCell(english: "4", morseCode: "....-"))
        //array.append(MorseCodeCell(english: "5", morseCode: "....."))
        //array.append(MorseCodeCell(english: "6", morseCode: "-...."))
        //array.append(MorseCodeCell(english: "7", morseCode: "--..."))
        //array.append(MorseCodeCell(english: "8", morseCode: "---.."))
        //array.append(MorseCodeCell(english: "9", morseCode: "----."))
        //array.append(MorseCodeCell(english: "0", morseCode: "-----"))
        //array.append(MorseCodeCell(english: "Space (␣)", morseCode: ".......", displayChar: "␣"))
        return array
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
        
        if currentNode?.parent?.action != nil {
            nearestMatches.append("Delete the last character to get: " + currentNode!.parent!.action! + "\n")
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
            matches.append("Add a dot to get: " + currentNode!.dotNode!.alphabet! + ".")
        }
        if currentNode?.dashNode?.alphabet != nil {
            matches.append("Add a dash to get: " + currentNode!.dashNode!.alphabet! + ".")
        }
        return matches
    }
    
    func getNextActionMatches(currentNode : MCTreeNode?) -> [String] {
        var matches : [String] = []
        if currentNode?.dotNode?.action != nil {
            matches.append("Add a dot to get: " + currentNode!.dotNode!.action! + ".")
        }
        if currentNode?.dashNode?.action != nil {
            matches.append("Add a dash to get: " + currentNode!.dashNode!.action! + ".")
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
                    else if node.dotNode!.character == nil {
                        //It exists as a dummy node but has no character
                        node.dotNode!.character = "."
                        node.dotNode!.parent = node
                    }
                    
                    //Error condition:
                    //Additional empty terminating node is created. If there is no dash for this node, we will allow the user to enter the character and move to this node. Then we will notify the user that no additional characters are around. Every character, if it does not have a dash, will have this empty node.
                    if node.dashNode == nil {
                        node.dashNode = MCTreeNode()
                        node.dashNode!.parent = node
                    }
                    
                    //The dot node is the valid node. Move to it
                    node = node.dotNode!
                }
                else if morseCodeChar == "-" {
                    if node.dashNode == nil {
                        node.dashNode = MCTreeNode(character: "-")
                        node.dashNode!.parent = node
                    }
                    else if node.dashNode!.character == nil {
                        //It exists as a dummy node but has no character
                        node.dashNode!.character = "."
                        node.dashNode!.parent = node
                    }
                    
                    //Error condition:
                    //Additional empty terminating node is created. If there is no dot for this node, we will allow the user to enter the character and move to this node. Then we will notify the user that no additional characters are around. Every character, if it does not have a dot, will have this empty node.
                    if node.dotNode == nil {
                        node.dotNode = MCTreeNode()
                        node.dotNode!.parent = node
                    }
                    
                    //This dash node is the valid node. Move to it.
                    node = node.dashNode!
                }
                
                //a node can be both an action and a character
                if i == (morseCode.count - 1) {
                    node.alphabet = morseCodeCell.displayChar != nil ? morseCodeCell.displayChar : morseCodeCell.english
                    if node.action == nil && morseCodeCell.type == "action" {
                        node.action = morseCodeCell.english
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
