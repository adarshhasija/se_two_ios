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
                if action == Action.TIME.rawValue {
                    aboutLabel.setText("We give the time in 12 hour format")
                    blindLabel.setHidden(false)
                    blindInstructionsLabel.setText("After getting the result, tap the screen to play audio")
                    blindInstructionsLabel.setHidden(false)
                    deafBlindLabel.setHidden(false)
                    deafBlindInstructionsLabel.setText("After getting the result, rotate the digital crown down to feel the vibrations.\nThere are 3 Sets.\nSet 1 is the hour.\n1 Long vibration = 1 Dash = 5 hours.\n1 Short vibration = 1 Dot = 1 hour.\nEx: 1 long vibration and 1 short vibration = 6 hrs.\nSet 2 is the minute.\n1 long vibration = 1 dash = 5 minutes.\n1 short vibration = 1 dot = 1 minute.\nEx: 1 long vibration and 1 short  vibration = 6 minutes\nSet 3 is AM or PM\n1 Long vibration = 1 Dash = PM.\n1 short vibration = 1 dot = AM")
                    deafBlindInstructionsLabel.setHidden(false)

                }
                else if action == Action.DATE.rawValue {
                    aboutLabel.setText("We give you the date and day of the week")
                    blindLabel.setHidden(false)
                    blindInstructionsLabel.setText("After getting the result, tap the screen to play audio")
                    blindInstructionsLabel.setHidden(false)
                    deafBlindLabel.setHidden(false)
                    deafBlindInstructionsLabel.setText("After getting the result, rotate the digital crown down to feel the vibrations.\nThere are 2 Sets.\nSet 1 is the date.\n1 Long vibration = 1 Dash = 5 hours.\n1 Short vibration = 1 dot = 1 hour.\nEx: 1 long vibration and 1 short vibration = 6th.\nSet 2 is the number of days after Sunday.\n1 short vibration = Sunday.\n2 short vibrations = Monday")
                    deafBlindInstructionsLabel.setHidden(false)
                }
                else if action == "1-to-1" {
                    aboutLabel.setText("To get chat mode, you must tap 4 times and swipe up. In chat mode, you can chat with someone sitting next to you using this app. You can type out a message in morse code and we will convert it to English so you can show it to your partner. They can reply in English and we will convert it to morse code for you")
                }
            }
            else if let morseCodeCell = dictionary!["object"] as? MorseCodeCell {
                let finalString = "You must rotate the digital crown downwards to type out this morse code combination: " + morseCodeCell.morseCode + "\n\nTyping Instructions:\n\nRotate digital crown:\nDown to type a dot.\nDown quickly to type a dash.\nUpwards to delete last character.\n\nDouble tap the Apple Watch screen to confirm a character."
                titleLabel.setText(morseCodeCell.english)
                aboutLabel.setText(finalString)
                blindLabel.setHidden(true)
                blindInstructionsLabel.setHidden(true)
                deafBlindLabel.setHidden(true)
                deafBlindInstructionsLabel.setHidden(true)
            }
        }
        else {
            titleLabel.setText("Error")
            aboutLabel.setText("Something went wrong")
        }
    }
}
