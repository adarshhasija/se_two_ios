//
//  Braille.swift
//  CustomVision
//
//  Created by Adarsh Hasija on 13/02/23.
//  Copyright © 2023 Adam Behringer. All rights reserved.
//

import Foundation

class Braille {
    
    
    var brailleArray: [BrailleCell] = []
    var alphabetToBrailleDictionary : [String : String] = [:]
    
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
        brailleArray.append(BrailleCell(english: "A", brailleDots: "1"))
        brailleArray.append(BrailleCell(english: "B", brailleDots: "12"))
        brailleArray.append(BrailleCell(english: "C", brailleDots: "14"))
        brailleArray.append(BrailleCell(english: "D", brailleDots: "145"))
        brailleArray.append(BrailleCell(english: "E", brailleDots: "15"))
        brailleArray.append(BrailleCell(english: "F", brailleDots: "124"))
        brailleArray.append(BrailleCell(english: "G", brailleDots: "1245"))
        brailleArray.append(BrailleCell(english: "H", brailleDots: "125"))
        brailleArray.append(BrailleCell(english: "I", brailleDots: "24"))
        brailleArray.append(BrailleCell(english: "J", brailleDots: "245"))
        brailleArray.append(BrailleCell(english: "K", brailleDots: "13"))
        brailleArray.append(BrailleCell(english: "L", brailleDots: "123"))
        brailleArray.append(BrailleCell(english: "M", brailleDots: "134"))
        brailleArray.append(BrailleCell(english: "N", brailleDots: "1345"))
        brailleArray.append(BrailleCell(english: "O", brailleDots: "135"))
        brailleArray.append(BrailleCell(english: "P", brailleDots: "1234"))
        brailleArray.append(BrailleCell(english: "Q", brailleDots: "12345"))
        brailleArray.append(BrailleCell(english: "R", brailleDots: "1235"))
        brailleArray.append(BrailleCell(english: "S", brailleDots: "234"))
        brailleArray.append(BrailleCell(english: "T", brailleDots: "2345"))
        brailleArray.append(BrailleCell(english: "U", brailleDots: "136"))
        brailleArray.append(BrailleCell(english: "V", brailleDots: "1236"))
        brailleArray.append(BrailleCell(english: "W", brailleDots: "2456"))
        brailleArray.append(BrailleCell(english: "X", brailleDots: "1346"))
        brailleArray.append(BrailleCell(english: "Y", brailleDots: "13456"))
        brailleArray.append(BrailleCell(english: "Z", brailleDots: "1356"))
        brailleArray.append(BrailleCell(english: "1", brailleDots: "3456 1"))
        brailleArray.append(BrailleCell(english: "2", brailleDots: "3456 12"))
        brailleArray.append(BrailleCell(english: "3", brailleDots: "3456 14"))
        brailleArray.append(BrailleCell(english: "4", brailleDots: "3456 145"))
        brailleArray.append(BrailleCell(english: "5", brailleDots: "3456 15"))
        brailleArray.append(BrailleCell(english: "6", brailleDots: "3456 124"))
        brailleArray.append(BrailleCell(english: "7", brailleDots: "3456 1245"))
        brailleArray.append(BrailleCell(english: "8", brailleDots: "3456 125"))
        brailleArray.append(BrailleCell(english: "9", brailleDots: "3456 24"))
        brailleArray.append(BrailleCell(english: "0", brailleDots: "3456 245"))
        brailleArray.append(BrailleCell(english: ",", brailleDots: "2"))
        brailleArray.append(BrailleCell(english: ";", brailleDots: "23"))
        brailleArray.append(BrailleCell(english: ":", brailleDots: "25"))
        brailleArray.append(BrailleCell(english: "?", brailleDots: "26"))
        brailleArray.append(BrailleCell(english: "!", brailleDots: "235"))
        brailleArray.append(BrailleCell(english: "-", brailleDots: "36"))
        
        
        //Dunno why  we doing it this way but we keep it like this for now
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
        let english = alphanumericString.uppercased().trimmingCharacters(in: .whitespacesAndNewlines).filter("ABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890 ".contains).replacingOccurrences(of: " ", with: "␣")
        var brailleCharacterString = ""
        for character in english {
            guard let brailleDotsString : String = alphabetToBrailleDictionary[String(character)] else {
                return nil
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
        
        return brailleStringArray
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
