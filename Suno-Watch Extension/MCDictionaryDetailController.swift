//
//  MCDictionaryDetailController.swift
//  Suno-Watch Extension
//
//  Created by Adarsh Hasija on 14/06/20.
//  Copyright © 2020 Adam Behringer. All rights reserved.
//

import Foundation
import WatchKit

class MCDictionaryDetailController : WKInterfaceController {
    
    
    @IBOutlet weak var titleLabel: WKInterfaceLabel!
    @IBOutlet weak var aboutLabel: WKInterfaceLabel!
    @IBOutlet weak var blindLabel: WKInterfaceLabel!
    @IBOutlet weak var blindInstructionsLabel: WKInterfaceLabel!
    @IBOutlet weak var deafBlindLabel: WKInterfaceLabel!
    @IBOutlet weak var deafBlindInstructionsLabel: WKInterfaceLabel!
    
    override func awake(withContext context: Any?) {
        let dictionary = context as? NSDictionary
        if dictionary != nil {
            if let action = dictionary!["action"] as? String {
                titleLabel.setText(action)
                if action == "TIME" {
                    aboutLabel.setText("To get the time in morse code, you must tap once and swipe up. You will get the current time in 24 hour format")
                    blindInstructionsLabel.setText("After getting the result, tap the screen to play audio")
                    deafBlindInstructionsLabel.setText("After getting the result, swipe right with 2 fingers to read the morse code. We will communicate it through vibrations\n\nDot(.) : 1 vibration\nDash(-) : 2 vibration")

                }
                else if action == "DATE" {
                    aboutLabel.setText("To get the date in morse code, you must tap twice and swipe up. You will get the date and the first 2 letters of the day of the week\nExample: If date is 17 and 17 is a Wednesday, you will get 17WE")
                    blindInstructionsLabel.setText("After getting the result, tap the screen to play audio")
                    deafBlindInstructionsLabel.setText("After getting the result, swipe right with 2 fingers to read the morse code. We will communicate it through vibrations\n\nDot(.) : 1 vibration\nDash(-) : 2 vibration")
                }
                else {
                    aboutLabel.setText("In chat mode, you can chat with someone sitting next to you using this app. You can type out a message in morse code and we will convert it to English so you can show it to your partner. They can reply in English and we will convert it to morse code for you")
                    blindLabel.setHidden(true)
                    blindInstructionsLabel.setHidden(true)
                    deafBlindLabel.setHidden(true)
                    deafBlindInstructionsLabel.setHidden(true)
                }
                
            }
        }
    }
}
