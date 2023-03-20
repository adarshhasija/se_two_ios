//
//  Braille.swift
//  CustomVision
//
//  Created by Adarsh Hasija on 13/02/23.
//  Copyright © 2023 Adam Behringer. All rights reserved.
//

import Foundation

class Braille {
    
    var alphabetToBrailleDictionary : [String : String] = [:] //used for quick access
    
    ///indexes used in UI
    var arrayBrailleGridsForCharsInWord : [BrailleCell] = []
    var arrayWordsInString : [String] = []
    var arrayWordsInStringIndex = 0
    var arrayBrailleGridsForCharsInWordIndex = 0 //in the case of braille
    var alphanumericHighlightStartIndex = 0 //Cannot use braille grids array index as thats not a 1-1 relation
    var alphanumericStringIndex = -1
    var morseCodeStringIndex = -1
    
    func resetIndexes() {
        arrayWordsInStringIndex = 0
        arrayBrailleGridsForCharsInWordIndex = 0
        alphanumericHighlightStartIndex = 0
        alphanumericStringIndex = -1
        morseCodeStringIndex = -1
    }
    
    func populateGridsArrayForWord(word: String) {
        arrayBrailleGridsForCharsInWord.removeAll()
        arrayBrailleGridsForCharsInWord.append(contentsOf: convertAlphanumericToBrailleWithContractions(alphanumericString: word))
    }
    
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
        var brailleArray: [BrailleCell] = [] //keeping this append code just so we dont have to rewrite  it. May need  it in  future if we have to display all this in  a list
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
        brailleArray.append(BrailleCell(english: "^", brailleDots: "6"))
        brailleArray.append(BrailleCell(english: "#", brailleDots: "3456"))
        brailleArray.append(BrailleCell(english: ".", brailleDots: "256"))
        brailleArray.append(BrailleCell(english: ",", brailleDots: "2"))
        brailleArray.append(BrailleCell(english: ";", brailleDots: "23"))
        brailleArray.append(BrailleCell(english: ":", brailleDots: "25"))
        brailleArray.append(BrailleCell(english: "?", brailleDots: "26"))
        brailleArray.append(BrailleCell(english: "!", brailleDots: "235"))
        brailleArray.append(BrailleCell(english: "-", brailleDots: "36"))
        brailleArray.append(BrailleCell(english: "can", brailleDots: "14"))
        brailleArray.append(BrailleCell(english: "ing", brailleDots: "346"))
        brailleArray.append(BrailleCell(english: "com", brailleDots: "36"))
        
        
        //We actually need it in dictionary form for easy retrieval
        for brailleCell in brailleArray {
            alphabetToBrailleDictionary[brailleCell.english] = brailleCell.brailleDots
        }
        brailleArray.removeAll()
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

        return brailleStringArray
    }
    
    func convertAlphanumericToBrailleWithContractions(alphanumericString : String) -> [BrailleCell] {
        var brailleFinalArray : [BrailleCell] = []
        var brailleCharacterString = ""
        var isFirstNumberInNumberSubstringPassed = false
        var brailleDotsString = ""
        var index = -1
        var subString = ""
        for (startIndex, character) in alphanumericString.enumerated() {
            index = index > startIndex ? index : startIndex
            if index >= alphanumericString.count {
                break
            }
            subString = ""
            for endIndex in stride(from: alphanumericString.count, through: index, by: -1) {
                let sIndex = alphanumericString.index(alphanumericString.startIndex, offsetBy: index)
                let eIndex = alphanumericString.index(alphanumericString.startIndex, offsetBy: endIndex)
                let range = sIndex..<eIndex
                let adjustedString = alphanumericString[range]
                brailleDotsString = alphabetToBrailleDictionary[String(adjustedString).lowercased()] ?? ""
                if brailleDotsString.isEmpty == false {
                    subString = String(adjustedString)
                    index += adjustedString.count
                    break
                }
                //let isNumberSubstring = adjustedString.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil //Not needed but keeping it commented out for future convenience
                
            }

        /*    if brailleDotsString.isEmpty {
                brailleDotsString = alphabetToBrailleDictionary[String(character).lowercased()]!
            }   */
            if subString.count == 1 {
                if Character(subString).isUppercase { brailleDotsString = (alphabetToBrailleDictionary["^"] ?? "6") + " " + brailleDotsString }
                
                if Character(subString).isNumber && isFirstNumberInNumberSubstringPassed == false {
                    //standalone number OR first number in a sequence
                    brailleDotsString = (alphabetToBrailleDictionary["#"] ?? "3456") + " " + brailleDotsString
                    isFirstNumberInNumberSubstringPassed = true
                }
                else if Character(subString).isNumber == false {
                    //a letter or special character
                    isFirstNumberInNumberSubstringPassed = false
                }
            }
            else {
                //its a long string. a contraction. likely not a number
                isFirstNumberInNumberSubstringPassed = false
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
    
    
    
    
    
    func setupArraysUsingInputString(fullAlphanumeric: String?) {
        arrayWordsInString.append(contentsOf: fullAlphanumeric?.components(separatedBy: " ") ?? [])
        arrayBrailleGridsForCharsInWord.append(contentsOf: convertAlphanumericToBrailleWithContractions(alphanumericString: arrayWordsInString.first ?? ""))
    }
    
    func getStartAndEndIndexInFullStringOfHighlightedPortion() -> [String:Any] {
        var text = ""
        var startIndexForHighlighting = 0
        var endIndexForHighlighting = 0
        for word in arrayWordsInString {
            text += word
            text += " "
        }
        text = text.trimmingCharacters(in: .whitespacesAndNewlines) //Trim the last space at the end from the for loop above
        for (index, element) in arrayWordsInString.enumerated() {
            if index < arrayWordsInStringIndex {
                startIndexForHighlighting += arrayWordsInString[index].count //Need to increment by length of  the word that was completed
                startIndexForHighlighting += 1 //account for space after the word
            }
        }
        startIndexForHighlighting += alphanumericHighlightStartIndex
        let exactWord = arrayBrailleGridsForCharsInWord[arrayBrailleGridsForCharsInWordIndex].english
        endIndexForHighlighting = morseCodeStringIndex > -1 ? startIndexForHighlighting + exactWord.count : startIndexForHighlighting //If we have not started traversing the grid, we dont want to highlight
        
        return [
            "text": text,
            "start_index": startIndexForHighlighting,
            "end_index": endIndexForHighlighting
        ]
    }
    
    func isEndOfEntireStringReached(brailleString: String, brailleStringIndex: Int) -> Bool {
        if morseCodeStringIndex > -1 //We are past the beginning
            && brailleStringIndex == -1 //We are an an invalid index which means past the end
            && arrayBrailleGridsForCharsInWordIndex >= (arrayBrailleGridsForCharsInWord.count - 1)
            && arrayWordsInStringIndex >= (arrayWordsInString.count - 1) {
            return true
        }
        return false
    }
    
    func doIfEndOfEntireStringReachedScrollingBack(textFromAlphanumericLabel: String, textFromBrailleLabel: String) {
        arrayWordsInStringIndex = arrayWordsInString.count - 1
        arrayBrailleGridsForCharsInWordIndex = arrayBrailleGridsForCharsInWord.count - 1
        let exactWord = arrayBrailleGridsForCharsInWord[arrayBrailleGridsForCharsInWordIndex].english
        alphanumericHighlightStartIndex = textFromAlphanumericLabel.count - exactWord.count
        morseCodeStringIndex = getIndexInStringOfLastCharacterInTheGrid(brailleStringForCharacter: textFromBrailleLabel)
    }
    
    func isBeforeStartOfStringReached() -> Bool {
        if /*brailleIndex == -1*/morseCodeStringIndex <= -1
            && arrayBrailleGridsForCharsInWordIndex <= 0
        && arrayWordsInStringIndex <= 0 {
            return true
        }
        return false
    }
    
    func isStartOfWordReached() -> Bool {
        if /*brailleIndex == -1*/morseCodeStringIndex <= -1
                                    && arrayBrailleGridsForCharsInWordIndex <= 0 {
            return true
        }
        return false
    }
    
    func getPreviousWord() -> [String: String] {
        arrayWordsInStringIndex -= 1
        let alphanumericString = arrayWordsInString[arrayWordsInStringIndex]
        populateGridsArrayForWord(word: arrayWordsInString[arrayWordsInStringIndex]) //get the braille grids for the next word
        arrayBrailleGridsForCharsInWordIndex = arrayBrailleGridsForCharsInWord.count - 1
        let exactWord = arrayBrailleGridsForCharsInWord.last?.english ?? ""
        alphanumericHighlightStartIndex = alphanumericString.count - exactWord.count
        let brailleString = arrayBrailleGridsForCharsInWord.last?.brailleDots ?? "" //set the braille grid for the last character in the word
        morseCodeStringIndex = getIndexInStringOfLastCharacterInTheGrid(brailleStringForCharacter: brailleString)
        
        return [
            "alphanumeric_string": alphanumericString,
            "braille_string": brailleString
        ]
    }
    
    func goToPreviousCharacterOrContraction() -> String {
        arrayBrailleGridsForCharsInWordIndex -= 1
        let exactWord = arrayBrailleGridsForCharsInWord[arrayBrailleGridsForCharsInWordIndex].english
        alphanumericHighlightStartIndex -= exactWord.count //move the pointer backward by length of previous characters so we are ready to highlight the next characters
        let brailleGridDotsString = arrayBrailleGridsForCharsInWord[arrayBrailleGridsForCharsInWordIndex].brailleDots
        morseCodeStringIndex = getIndexInStringOfLastCharacterInTheGrid(brailleStringForCharacter: brailleGridDotsString)
        
        return brailleGridDotsString
    }
    
    func doIfBeforeStartOfStringReachedScrollingForward() {
        arrayWordsInStringIndex = 0
        arrayBrailleGridsForCharsInWordIndex = 0
        morseCodeStringIndex = 0
        alphanumericHighlightStartIndex = 0
    }
    
    func isEndOfWordReached(brailleStringIndex: Int) -> Bool {
        if brailleStringIndex == -1
            && arrayBrailleGridsForCharsInWordIndex >= (arrayBrailleGridsForCharsInWord.count - 1) {
            return true
        }
        return false
    }
    
    func getNextWord() -> [String : String] {
        arrayWordsInStringIndex += 1
        let alphanumericString = arrayWordsInString[arrayWordsInStringIndex]
        populateGridsArrayForWord(word: arrayWordsInString[arrayWordsInStringIndex]) //get the braille grids for the next word
        let brailleDotsString = arrayBrailleGridsForCharsInWord.first?.brailleDots ?? "" //set the braille grid for the first character in the word
        morseCodeStringIndex = 0
        arrayBrailleGridsForCharsInWordIndex = 0
        alphanumericHighlightStartIndex = 0
        
        return  [
            "alphanumeric_text": alphanumericString,
            "braille_text": brailleDotsString
        ]
    }
    
    func goToNextCharacterOrContraction() -> String {
        let exactWord = arrayBrailleGridsForCharsInWord[arrayBrailleGridsForCharsInWordIndex].english
        alphanumericHighlightStartIndex += exactWord.count //move the pointer forward by length of previous characters so we are ready to highlight the next characters
        
        //end of character move to next character
        arrayBrailleGridsForCharsInWordIndex += 1
        let brailleDotsString = arrayBrailleGridsForCharsInWord[arrayBrailleGridsForCharsInWordIndex].brailleDots
        morseCodeStringIndex = 0
        
        return brailleDotsString
    }
    
    func resetVariables() {
        resetIndexes()
        populateGridsArrayForWord(word: arrayWordsInString.first ?? "")
    }
    
    func getMapToSendToWatch() -> [String : Any] {
        return [
            "array_words_in_string": arrayWordsInString,
            "array_words_in_string_index": arrayWordsInStringIndex,
            "morse_code_string_index": morseCodeStringIndex,
            "array_braille_grids_for_chars_in_word": arrayBrailleGridsForCharsInWord,
            "array_braille_grids_for_chars_in_word_index": arrayBrailleGridsForCharsInWordIndex,
            "alphanumeric_highlight_start_index":
            alphanumericHighlightStartIndex
        ]
    }
    
    
    
}
