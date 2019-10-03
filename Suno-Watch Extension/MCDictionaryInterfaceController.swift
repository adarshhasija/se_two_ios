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
    
    var morseCode = MorseCode()
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        morseCodeDictionaryTable.setNumberOfRows(morseCode.dictionary.count, withRowType: "MorseCodeRow")

        for (index, morseCode) in morseCode.dictionary.enumerated() {
            let row = morseCodeDictionaryTable.rowController(at: index) as! MCDictionaryRowController
            row.englishLabel.setText(morseCode.english)
            row.morseCodeLabel.setText(morseCode.morseCode)
        }
        
        
        
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        let morseCodeCell = morseCode.dictionary[rowIndex]
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
