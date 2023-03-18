//
//  Braille.swift
//  CustomVision
//
//  Created by Adarsh Hasija on 13/02/23.
//  Copyright © 2023 Adam Behringer. All rights reserved.
//

import Foundation

class Braille {
    
    
    var brailleArray: [BrailleCell] = [] //incase we want it in order, for a list
    var alphabetToBrailleDictionary : [String : String] = [:] //used for quick access
    
    //Braille grid
    //1 4
    //2 5
    //3 6
    //String indexes
    //01\n34\n67
    static let mappingBrailleGridToStringIndex : [Int : Int] = [ //this is used when setting up dots in a string. Based on its grid number, it has to be placed at a specific index in  the string
           1 : 0,
           2 : 3,
           3 : 6,
           4 : 1,
           5 : 4,
           6 : 7,
                  ]
    
    //Braille grid
    //1 4  7 10
    //2 5  8 11
    //3 6  9 12
    //String indexes for numbers (2 grids)
    //01 34\n67 9(10)\n(12)(13) (14)(15)
    static let mappingBrailleGridNumbersToStringIndex : [Int : Int] = [ //numbers use 2 grids
           1 : 0,
           2 : 6,
           3 : 12,
           4 : 1,
           5 : 7,
           6 : 13,
           7 : 3,
           8 : 9,
           9 : 15,
           10 : 4,
           11 : 10,
           12 : 16,
                  ]
    static let brailleIndexOrderForVerticalReading : [Int : Int] = [ //Simillar to map above except that this is using standard index traversal when the reaaader parses through it
        0 : 0,
        1 : 3,
        2 : 6,
        3 : 1,
        4 : 4,
        5 : 7,
    ]
    static let brailleIndexOrderForNumbersVerticalReading : [Int : Int] = [ //numbers use 2 grids
           0 : 0,
           1 : 6,
           2 : 12,
           3 : 1,
           4 : 7,
           5 : 13,
           6 : 3,
           7 : 9,
           8 : 15,
           9 : 4,
           10 : 10,
           11 : 16,
                  ]
    static let brailleIndexOrderForHorizontalReading : [Int : Int] = [ //Simillar to map above except that this is using standard index traversal when the reaaader parses through it
        0 : 0,
        1 : 1,
        2 : 3,
        3 : 4,
        4 : 6,
        5 : 7,
    ]
    static let brailleIndexOrderForNumbersHorizontalReading : [Int : Int] = [ //numbers use 2 grids
           0 : 0,
           1 : 1,
           2 : 6,
           3 : 7,
           4 : 12,
           5 : 13,
           6 : 3,
           7 : 4,
           8 : 9,
           9 : 10,
           10 : 15,
           11 : 16,
                  ]
    
    
    init() {
        populateBrailleAlphanumeric()
    }
    
        deinit {
        //destroyTree()
    }
    
    
    
    func populateBrailleAlphanumeric() {
        brailleArray.append(BrailleCell(english: "can", brailleDots: "14"))
        brailleArray.append(BrailleCell(english: "ing", brailleDots: "346"))
        brailleArray.append(BrailleCell(english: "com", brailleDots: "36"))
        brailleArray.append(BrailleCell(english: "a", brailleDots: "1"))
        brailleArray.append(BrailleCell(english: "b", brailleDots: "12"))
        brailleArray.append(BrailleCell(english: "c", brailleDots: "14"))
        brailleArray.append(BrailleCell(english: "d", brailleDots: "145"))
        brailleArray.append(BrailleCell(english: "e", brailleDots: "15"))
        brailleArray.append(BrailleCell(english: "f", brailleDots: "124"))
        brailleArray.append(BrailleCell(english: "g", brailleDots: "1245"))
        brailleArray.append(BrailleCell(english: "h", brailleDots: "125"))
        brailleArray.append(BrailleCell(english: "i", brailleDots: "24"))
        brailleArray.append(BrailleCell(english: "j", brailleDots: "245"))
        brailleArray.append(BrailleCell(english: "k", brailleDots: "13"))
        brailleArray.append(BrailleCell(english: "l", brailleDots: "123"))
        brailleArray.append(BrailleCell(english: "m", brailleDots: "134"))
        brailleArray.append(BrailleCell(english: "n", brailleDots: "1345"))
        brailleArray.append(BrailleCell(english: "o", brailleDots: "135"))
        brailleArray.append(BrailleCell(english: "p", brailleDots: "1234"))
        brailleArray.append(BrailleCell(english: "q", brailleDots: "12345"))
        brailleArray.append(BrailleCell(english: "r", brailleDots: "1235"))
        brailleArray.append(BrailleCell(english: "s", brailleDots: "234"))
        brailleArray.append(BrailleCell(english: "t", brailleDots: "2345"))
        brailleArray.append(BrailleCell(english: "u", brailleDots: "136"))
        brailleArray.append(BrailleCell(english: "v", brailleDots: "1236"))
        brailleArray.append(BrailleCell(english: "w", brailleDots: "2456"))
        brailleArray.append(BrailleCell(english: "x", brailleDots: "1346"))
        brailleArray.append(BrailleCell(english: "y", brailleDots: "13456"))
        brailleArray.append(BrailleCell(english: "z", brailleDots: "1356"))
        brailleArray.append(BrailleCell(english: "1", brailleDots: "1")) //3456 nummber extension is added in the function
        brailleArray.append(BrailleCell(english: "2", brailleDots: "12"))
        brailleArray.append(BrailleCell(english: "3", brailleDots: "14"))
        brailleArray.append(BrailleCell(english: "4", brailleDots: "145"))
        brailleArray.append(BrailleCell(english: "5", brailleDots: "15"))
        brailleArray.append(BrailleCell(english: "6", brailleDots: "124"))
        brailleArray.append(BrailleCell(english: "7", brailleDots: "1245"))
        brailleArray.append(BrailleCell(english: "8", brailleDots: "125"))
        brailleArray.append(BrailleCell(english: "9", brailleDots: "24"))
        brailleArray.append(BrailleCell(english: "0", brailleDots: "245"))
        brailleArray.append(BrailleCell(english: ".", brailleDots: "256"))
        brailleArray.append(BrailleCell(english: ",", brailleDots: "2"))
        brailleArray.append(BrailleCell(english: ";", brailleDots: "23"))
        brailleArray.append(BrailleCell(english: ":", brailleDots: "25"))
        brailleArray.append(BrailleCell(english: "?", brailleDots: "26"))
        brailleArray.append(BrailleCell(english: "!", brailleDots: "235"))
        brailleArray.append(BrailleCell(english: "-", brailleDots: "36"))
        
        
        //We actually need it in dictionary form for easy retrieval
        for brailleCell in brailleArray {
            alphabetToBrailleDictionary[brailleCell.english] = brailleCell.brailleDots
        }
        
    }
    
    func getNextIndexForBrailleTraversal(brailleStringLength: Int, currentIndex : Int, isDirectionHorizontal : Bool) -> Int {
        if isDirectionHorizontal == false {
            if brailleStringLength > 10 {
                return Braille.brailleIndexOrderForNumbersVerticalReading[currentIndex] ?? -1
            }
            else {
                return Braille.brailleIndexOrderForVerticalReading[currentIndex] ?? -1
            }
        }
        else {
            if brailleStringLength > 10 {
                return Braille.brailleIndexOrderForNumbersHorizontalReading[currentIndex] ?? -1
            }
            else {
                return Braille.brailleIndexOrderForHorizontalReading[currentIndex] ?? -1
            }
        }
    }
    
    func isMidpointReachedForNumber(brailleStringLength: Int, brailleStringIndexForNextItem: Int) -> Bool {
        if brailleStringLength > 10 {
            let b = Braille.mappingBrailleGridNumbersToStringIndex.filter { $0.value == brailleStringIndexForNextItem }
            let brailleGridNumberForNextItem = b.count > 0 ? b.keys.first! : -1
            //
            
            if brailleGridNumberForNextItem == 7 {
                return true
            }
        }
        return false
    }
    
    func isEndpointReaached(brailleStringLength: Int, brailleStringIndexForNextItem: Int) -> Bool {
        if brailleStringLength > 10 {
            let b = Braille.mappingBrailleGridNumbersToStringIndex.filter { $0.value == brailleStringIndexForNextItem }
            let brailleGridNumberForNextItem = b.keys.first!
            //
            
            if brailleGridNumberForNextItem == 13 {
                return true
            }
        }
        else {
            let b = Braille.mappingBrailleGridToStringIndex.filter { $0.value == brailleStringIndexForNextItem }
            let brailleGridNumberForNextItem = b.keys.first!
            //
            
            if brailleGridNumberForNextItem == 7 {
                return true
            }
        }
        return false
    }
    
    func convertAlphanumericToBraille(alphanumericString : String) -> [String]? {
        var brailleStringArray : [String] = []
        var brailleCharacterString = ""
        let isStringANumber = alphanumericString.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
        for (index, character) in alphanumericString.enumerated() {
            guard var brailleDotsString : String = alphabetToBrailleDictionary[String(character).lowercased()] else {
                return nil
            }
            if character.isUppercase { brailleDotsString = "6 " + brailleDotsString }
            if (isStringANumber && index == 0) //This is the first character in a number
                || (isStringANumber == false && character.isNumber) { //This is a number in an  alphanumeric string
                brailleDotsString = "3456 " + brailleDotsString
            }
            let brailleDotsArray = brailleDotsString.components(separatedBy: " ") //if its for a number its 2 braille grids
            if brailleDotsArray.count > 1 {
                //means its a number, and it needs 2 braille grids
                brailleCharacterString = "xx xx\nxx xx\nxx xx"
            }
            else {
                brailleCharacterString = "xx\nxx\nxx"
            }
            if brailleDotsArray.count > 1 {
                for number in brailleDotsArray[0] {
                    let numberAsInt = number.wholeNumberValue!
                    let index = brailleCharacterString.index(brailleCharacterString.startIndex, offsetBy: Braille.mappingBrailleGridNumbersToStringIndex[numberAsInt]!)
                    brailleCharacterString.replaceSubrange(index...index, with: "o")
                }
                for number in brailleDotsArray[1] {
                    let numberAsInt = number.wholeNumberValue!
                    let index = brailleCharacterString.index(brailleCharacterString.startIndex, offsetBy: Braille.mappingBrailleGridNumbersToStringIndex[numberAsInt + 6]!) //Because it will be part of the second set of 6 in the string
                    brailleCharacterString.replaceSubrange(index...index, with: "o")
                }
            }
            else {
                for number in brailleDotsArray[0] {
                    let numberAsInt = number.wholeNumberValue!
                    let index = brailleCharacterString.index(brailleCharacterString.startIndex, offsetBy: Braille.mappingBrailleGridToStringIndex[numberAsInt]!)
                    brailleCharacterString.replaceSubrange(index...index, with: "o")
                }
            }
            brailleStringArray.append(brailleCharacterString)
        }
        //let abc = convertAlphanumericToBrailleDobara(alphanumericString: alphanumericString)
        return brailleStringArray
    }
    
    func convertAlphanumericToBrailleDobara(alphanumericString : String) -> [BrailleCell]? {
        var brailleFinalArray : [BrailleCell] = []
        var brailleCharacterString = ""
        let isStringANumber = alphanumericString.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
        var brailleDotsString = ""
        var index = -1
        var subString = ""
        for (startIndex, character) in alphanumericString.enumerated() {
            index = index > startIndex ? index : startIndex
            if index >= alphanumericString.count {
                break
            }
            subString = ""
            for endIndex in /*(index ..< alphanumericString.count).reversed()*/stride(from: alphanumericString.count, through: index, by: -1) {
                let sIndex = alphanumericString.index(alphanumericString.startIndex, offsetBy: index)
                let eIndex = alphanumericString.index(alphanumericString.startIndex, offsetBy: endIndex)
                let range = sIndex..<eIndex
                let finalPrefixedString = alphanumericString[range]
                print(finalPrefixedString)
                brailleDotsString = alphabetToBrailleDictionary[String(finalPrefixedString).lowercased()] ?? ""
                if brailleDotsString.isEmpty == false {
                    index += finalPrefixedString.count
                    subString = String(finalPrefixedString)
                    break
                }
            }

            if brailleDotsString.isEmpty {
                brailleDotsString = alphabetToBrailleDictionary[String(character).lowercased()]!
            }
            if subString.count == 1 {
                if Character(subString).isUppercase { brailleDotsString = "6 " + brailleDotsString }
            }
            
            let brailleDotsArray = brailleDotsString.components(separatedBy: " ") //if its for a number its 2 braille grids
            if brailleDotsArray.count > 1 {
                //means its a number, and it needs 2 braille grids
                brailleCharacterString = "xx xx\nxx xx\nxx xx"
            }
            else {
                brailleCharacterString = "xx\nxx\nxx"
            }
            if brailleDotsArray.count > 1 {
                for number in brailleDotsArray[0] {
                    let numberAsInt = number.wholeNumberValue!
                    let index = brailleCharacterString.index(brailleCharacterString.startIndex, offsetBy: Braille.mappingBrailleGridNumbersToStringIndex[numberAsInt]!)
                    brailleCharacterString.replaceSubrange(index...index, with: "o")
                }
                for number in brailleDotsArray[1] {
                    let numberAsInt = number.wholeNumberValue!
                    let index = brailleCharacterString.index(brailleCharacterString.startIndex, offsetBy: Braille.mappingBrailleGridNumbersToStringIndex[numberAsInt + 6]!) //Because it will be part of the second set of 6 in the string
                    brailleCharacterString.replaceSubrange(index...index, with: "o")
                }
            }
            else {
                for number in brailleDotsArray[0] {
                    let numberAsInt = number.wholeNumberValue!
                    let index = brailleCharacterString.index(brailleCharacterString.startIndex, offsetBy: Braille.mappingBrailleGridToStringIndex[numberAsInt]!)
                    brailleCharacterString.replaceSubrange(index...index, with: "o")
                }
            }
            brailleFinalArray.append(BrailleCell(english: subString, brailleDots: brailleCharacterString))
        }
        return brailleFinalArray
    }
    
    private func traverseString(inputString: String) -> [BrailleCell] {
        print(inputString)
        var brailleAlphaAndCellsArray : [BrailleCell] = []
        guard var brailleDotsString : String = alphabetToBrailleDictionary[inputString.lowercased()] else {
            let prefixSubString = inputString.prefix(inputString.count - 1)
            brailleAlphaAndCellsArray.insert(contentsOf: traverseString(inputString: String(prefixSubString)), at: 0)
            let suffixIndex = inputString.index(inputString.startIndex, offsetBy: 1)
            let suffixSubstring = inputString.suffix(from: suffixIndex)
            brailleAlphaAndCellsArray.append(contentsOf: traverseString(inputString: String(suffixSubstring)))
            return brailleAlphaAndCellsArray
        }
        if (inputString.count == 1) {
            let character = Character(inputString)
            if character.isUppercase { brailleDotsString = "6 " + brailleDotsString }
            
        }
        var brailleCharacterString = ""
        let brailleDotsArray = brailleDotsString.components(separatedBy: " ") //if its for a number its 2 braille grids
        if brailleDotsArray.count > 1 {
            //means its a number, and it needs 2 braille grids
            brailleCharacterString = "xx xx\nxx xx\nxx xx"
        }
        else {
            brailleCharacterString = "xx\nxx\nxx"
        }
        if brailleDotsArray.count > 1 {
            for number in brailleDotsArray[0] {
                let numberAsInt = number.wholeNumberValue!
                let index = brailleCharacterString.index(brailleCharacterString.startIndex, offsetBy: Braille.mappingBrailleGridNumbersToStringIndex[numberAsInt]!)
                brailleCharacterString.replaceSubrange(index...index, with: "o")
            }
            for number in brailleDotsArray[1] {
                let numberAsInt = number.wholeNumberValue!
                let index = brailleCharacterString.index(brailleCharacterString.startIndex, offsetBy: Braille.mappingBrailleGridNumbersToStringIndex[numberAsInt + 6]!) //Because it will be part of the second set of 6 in the string
                brailleCharacterString.replaceSubrange(index...index, with: "o")
            }
        }
        else {
            for number in brailleDotsArray[0] {
                let numberAsInt = number.wholeNumberValue!
                let index = brailleCharacterString.index(brailleCharacterString.startIndex, offsetBy: Braille.mappingBrailleGridToStringIndex[numberAsInt]!)
                brailleCharacterString.replaceSubrange(index...index, with: "o")
            }
        }
        brailleAlphaAndCellsArray.append(BrailleCell(english: inputString, brailleDots: brailleCharacterString))
        return brailleAlphaAndCellsArray
    }
    
    func getIndexInStringOfLastCharacterInTheGrid(brailleStringForCharacter: String) -> Int {
        //let index2 = alphanumericString.index(alphanumericString.startIndex, offsetBy: index)
        //let alphanumeric = alphanumericString[index2]
        if brailleStringForCharacter.count >= 10 {
            return 11 //as per brailleIndexOrderForVerticalReading and brailleIndexOrderForHorizontalReading, this is the key of the last elemment in the grid
        }
        else {
            return 5 //as per brailleIndexOrderForVerticalReading and brailleIndexOrderForHorizontalReading, this is the key of the last elemment in the grid
        }
    }
    
    
    
    
    
}
