//
//  MorecodeInterfaceController.swift
//  Suno-Watch Extension
//
//  Created by Adarsh Hasija on 28/09/19.
//  Copyright © 2019 Adam Behringer. All rights reserved.
//

import Foundation
import WatchKit
import AVFoundation

class MCInterfaceController : WKInterfaceController {
    
    var mcTempBuffer : String = ""
    var englishString : String = ""
    var alphabetToMcDictionary : [String : String] = [:]
    var mcToAlphabetDictionary : [String : String] = [:]
    
    @IBOutlet weak var englishTextLabel: WKInterfaceLabel!
    @IBOutlet weak var morseCodeTextLabel: WKInterfaceLabel!
    @IBOutlet weak var welcomeLabel: WKInterfaceLabel!
    
    
    @IBAction func tapGesture(_ sender: Any) {
        print("tap")
        welcomeLabel.setHidden(true)
        mcTempBuffer += "."
        morseCodeTextLabel.setText(mcTempBuffer)
        WKInterfaceDevice.current().play(.start)
    }
    
    @IBAction func rightSwipe(_ sender: Any) {
        print("right swipe")
        welcomeLabel.setHidden(true)
        mcTempBuffer += "-"
        morseCodeTextLabel.setText(mcTempBuffer)
        
        WKInterfaceDevice.current().play(.stop)
        //WKInterfaceDevice.current().play(.start)
        //let ms = 1000
        //usleep(useconds_t(750 * ms)) //will sleep for 50 milliseconds
        //WKInterfaceDevice.current().play(.start)
    }
    
    
    @IBAction func upSwipe(_ sender: Any) {
        print("up swipe")
        if mcTempBuffer.count > 0 {
            if let letterOrNumber = mcToAlphabetDictionary[mcTempBuffer] {
                //first deal with space. Remove the visible space character and replace with an actual space to make it look more normal. Space character was just there for visual clarity
                if englishString.last == "␣" {
                    englishString.removeLast()
                    englishString += " "
                }
                englishString += letterOrNumber
                englishTextLabel.setText(englishString)
                englishTextLabel.setHidden(false)
                mcTempBuffer.removeAll()
                morseCodeTextLabel.setText("")
                WKInterfaceDevice.current().play(.success) //successfully got a letter/number
            }
            else {
                //did not get a letter/number
                WKInterfaceDevice.current().play(.failure)
                let morseCode = MorseCode()
                
                
            }
        }
        else {
            let synth : AVSpeechSynthesizer = AVSpeechSynthesizer.init()
            synth.delegate = self as? AVSpeechSynthesizerDelegate
            let speechUtterance: AVSpeechUtterance = AVSpeechUtterance(string: englishString)
            synth.speak(speechUtterance)
            WKInterfaceDevice.current().play(.success) //successfully played audio
        }
    }
    
    
    @IBAction func leftSwipe(_ sender: Any) {
        if mcTempBuffer.count > 0 {
            mcTempBuffer.removeLast()
            morseCodeTextLabel.setText(mcTempBuffer)
            WKInterfaceDevice.current().play(.success)
        }
        else if englishString.count > 0 {
            englishString.removeLast()
            englishTextLabel.setText(englishString)
            WKInterfaceDevice.current().play(.success)
            if englishString.count == 0 {
                welcomeLabel.setHidden(false)
            }
        }
        else if englishString.count == 0 {
            WKInterfaceDevice.current().play(.success)
            if englishString.count == 0 {
                welcomeLabel.setHidden(false)
            }
        }
        else {
            print("nothing to delete")
            WKInterfaceDevice.current().play(.failure)
        }
    }
    
    
    @IBAction func longPress(_ sender: Any) {
        self.presentTextInputController(withSuggestions: [], allowedInputMode: .plain, completion: { (answers) -> Void in
            if var answer = answers?[0] as? String {
                answer = answer.uppercased()
                self.englishTextLabel.setText(answer)
                self.englishTextLabel.setHidden(false)
                self.morseCodeTextLabel.setText("")
                var morseCodeString = ""
                for char in answer {
                    let charAsString : String = String(char)
                    if let morseCode = self.alphabetToMcDictionary[charAsString] {
                        morseCodeString += morseCode
                    }
                }
                self.morseCodeTextLabel.setText(morseCodeString)
                self.morseCodeTextLabel.setHidden(false)
                self.welcomeLabel.setHidden(true)
                for morseCodeItem in morseCodeString {
                    if morseCodeItem == "." {
                        WKInterfaceDevice.current().play(.start)
                    }
                    else if morseCodeItem == "-" {
                        WKInterfaceDevice.current().play(.stop)
                    }
                    else {
                        //space between characters
                        
                    }
                }
            }
            
        })
    }
    
    @IBAction func tappedAbout() {
        presentAlert(withTitle: "About App", message: "This Apple Watch app is designed to help the deaf-blind communicate via touch. Deaf-blind can type using morse-code  and the app will speak it out in English. The other person can then speak and the app will convert the speech into morce-code taps that the deaf-blind can feel", preferredStyle: .alert, actions: [
        WKAlertAction(title: "OK", style: .default) {}
        ])
    }
    
    
    @IBAction func tappedDictionary() {
        pushController(withName: "Dictionary", context: nil)
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        WKInterfaceDevice.current().play(.success) //successfully launched app
        if mcToAlphabetDictionary.count < 1 && alphabetToMcDictionary.count < 1 {
            let morseCode : MorseCode = MorseCode()
            for morseCodeCell in morseCode.dictionary {
                if morseCodeCell.morseCode == "......." {
                    //space
                    alphabetToMcDictionary[" "] = morseCodeCell.morseCode
                    
                    mcToAlphabetDictionary[morseCodeCell.morseCode] = morseCodeCell.displayChar
                }
                else {
                    alphabetToMcDictionary[morseCodeCell.english] = morseCodeCell.morseCode
                    
                    mcToAlphabetDictionary[morseCodeCell.morseCode] = morseCodeCell.english
                }
                
            }
        }
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
}

