//
//  MCDictionaryInterfaceController.swift
//  Suno-Watch Extension
//
//  Created by Adarsh Hasija on 01/10/19.
//  Copyright © 2019 Adam Behringer. All rights reserved.
//

import Foundation
import WatchKit
import WatchConnectivity

class MCDictionaryInterfaceController : WKInterfaceController {
    
    
    @IBOutlet weak var morseCodeDictionaryTable: WKInterfaceTable!
    
    var morseCode = MorseCode()
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        let dictionary = context as? NSDictionary
        if dictionary != nil {
            if let type = dictionary!["type"] as? String {
                morseCode = MorseCode(type: type, operatingSystem: "watchOS")
            }
        }
        
        morseCodeDictionaryTable.setNumberOfRows(morseCode.mcArray.count, withRowType: "MorseCodeRow")

        for (index, morseCode) in morseCode.mcArray.enumerated() {
            let row = morseCodeDictionaryTable.rowController(at: index) as! MCDictionaryRowController
            row.englishLabel.setText(morseCode.english)
            row.morseCodeLabel.setText(morseCode.morseCode)
        }
        
        
        
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        let morseCodeCell = morseCode.mcArray[rowIndex]
        sendAnalytics(eventName: "se3_watch_row_tap", parameters: [
            "screen" : "mc_dictionary",
            "question" : morseCodeCell.english.prefix(100)
        ])
        
        if morseCodeCell.type == "action" {
            let params = [
                "action" : morseCodeCell.english
            ]
            pushController(withName: "DictionaryDetail", context: params)
        }
        else {
            var finalString = ""
            for char in morseCodeCell.morseCode {
                if char == "." {
                    finalString += "tap"
                }
                else if char == "-" {
                    finalString += "swipe right"
                }
                
                finalString += ","
            }
            finalString.removeLast() //Removes the last comma
            
            presentAlert(withTitle: "", message: "To type this out you must " + finalString, preferredStyle: .alert, actions: [
                WKAlertAction(title: "OK", style: .default) {}
            ])
        }
        
    }
    
}


extension MCDictionaryInterfaceController {
    
    func sendAnalytics(eventName : String, parameters : Dictionary<String, Any>) {
        var message : [String : Any] = [:]
        message["event_name"] = eventName
        message["parameters"] = parameters
        if WCSession.isSupported() {
            let session = WCSession.default
            if session.isReachable {
                // In your WatchKit extension, the value of this property is true when the paired iPhone is reachable via Bluetooth.
                session.sendMessage(message, replyHandler: nil, errorHandler: nil)
            }
            
        }
    }
    
}
