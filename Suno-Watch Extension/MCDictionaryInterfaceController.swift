//
//  MCDictionaryInterfaceController.swift
//  Suno-Watch Extension
//
//  Created by Adarsh Hasija on 01/10/19.
//  Copyright © 2019 Adam Behringer. All rights reserved.
//

import Foundation
import WatchKit

class MCDictionaryInterfaceController : WKInterfaceController {
    
    
    @IBOutlet weak var morseCodeDictionaryTable: WKInterfaceTable!
    
    var morseCodeDictionary: [MorseCodeCell] = []
    
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        morseCodeDictionary.append(MorseCodeCell(english: "A", morseCode: ".-"))
        morseCodeDictionary.append(MorseCodeCell(english: "B", morseCode: "-..."))
        morseCodeDictionary.append(MorseCodeCell(english: "C", morseCode: "-.-."))
        morseCodeDictionary.append(MorseCodeCell(english: "D", morseCode: "-.."))
        morseCodeDictionary.append(MorseCodeCell(english: "E", morseCode: "."))
        morseCodeDictionary.append(MorseCodeCell(english: "F", morseCode: "..-."))
        morseCodeDictionary.append(MorseCodeCell(english: "G", morseCode: "--."))
        morseCodeDictionary.append(MorseCodeCell(english: "H", morseCode: "...."))
        morseCodeDictionary.append(MorseCodeCell(english: "I", morseCode: ".."))
        morseCodeDictionary.append(MorseCodeCell(english: "J", morseCode: ".---"))
        morseCodeDictionary.append(MorseCodeCell(english: "K", morseCode: "-.-"))
        morseCodeDictionary.append(MorseCodeCell(english: "L", morseCode: ".-.."))
        morseCodeDictionary.append(MorseCodeCell(english: "M", morseCode: "--"))
        morseCodeDictionary.append(MorseCodeCell(english: "N", morseCode: "-."))
        morseCodeDictionary.append(MorseCodeCell(english: "O", morseCode: "---"))
        morseCodeDictionary.append(MorseCodeCell(english: "P", morseCode: ".--."))
        morseCodeDictionary.append(MorseCodeCell(english: "Q", morseCode: "--.-"))
        morseCodeDictionary.append(MorseCodeCell(english: "R", morseCode: ".-."))
        morseCodeDictionary.append(MorseCodeCell(english: "S", morseCode: "..."))
        morseCodeDictionary.append(MorseCodeCell(english: "T", morseCode: "-"))
        morseCodeDictionary.append(MorseCodeCell(english: "U", morseCode: "..-"))
        morseCodeDictionary.append(MorseCodeCell(english: "V", morseCode: "...-"))
        morseCodeDictionary.append(MorseCodeCell(english: "W", morseCode: ".--"))
        morseCodeDictionary.append(MorseCodeCell(english: "X", morseCode: "-..-"))
        morseCodeDictionary.append(MorseCodeCell(english: "Y", morseCode: "-.--"))
        morseCodeDictionary.append(MorseCodeCell(english: "Z", morseCode: "--.."))
        morseCodeDictionary.append(MorseCodeCell(english: "1", morseCode: ".----"))
        morseCodeDictionary.append(MorseCodeCell(english: "2", morseCode: "..---"))
        morseCodeDictionary.append(MorseCodeCell(english: "3", morseCode: "...--"))
        morseCodeDictionary.append(MorseCodeCell(english: "4", morseCode: "....-"))
        morseCodeDictionary.append(MorseCodeCell(english: "5", morseCode: "....."))
        morseCodeDictionary.append(MorseCodeCell(english: "6", morseCode: "-...."))
        morseCodeDictionary.append(MorseCodeCell(english: "7", morseCode: "--..."))
        morseCodeDictionary.append(MorseCodeCell(english: "8", morseCode: "---.."))
        morseCodeDictionary.append(MorseCodeCell(english: "9", morseCode: "----."))
        morseCodeDictionary.append(MorseCodeCell(english: "0", morseCode: "-----"))
        morseCodeDictionary.append(MorseCodeCell(english: "Space (␣)", morseCode: "......."))
        
        morseCodeDictionaryTable.setNumberOfRows(morseCodeDictionary.count, withRowType: "MorseCodeRow")

        for (index, morseCode) in morseCodeDictionary.enumerated() {
            let row = morseCodeDictionaryTable.rowController(at: index) as! MCDictionaryRowController
            row.englishLabel.setText(morseCode.english)
            row.morseCodeLabel.setText(morseCode.morseCode)
        }
        
        
        
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        let morseCodeCell = morseCodeDictionary[rowIndex]
        var finalString = ""
        for char in morseCodeCell.morseCode {
            if char == "." {
                finalString += "tap"
            }
            else if char == "-" {
                finalString += "swipe"
            }
            
            finalString += ","
        }
        finalString.removeLast() //Removes the last comma
        
        presentAlert(withTitle: "", message: "To type this out you must " + finalString, preferredStyle: .alert, actions: [
        WKAlertAction(title: "OK", style: .default) {}
        ])
    }
    
}
