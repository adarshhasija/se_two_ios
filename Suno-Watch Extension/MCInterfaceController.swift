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
    
    enum MorseCode {
        case dot
        case dash
    }
    
    var mcTempBuffer : String = ""
    var englishString : String = ""
    var morseCodeDictionary : [String : String] = [
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
    ]
    
    @IBOutlet weak var englishTextLabel: WKInterfaceLabel!
    @IBOutlet weak var morseCodeTextLabel: WKInterfaceLabel!
    @IBOutlet weak var welcomeLabel: WKInterfaceLabel!
    
    
    @IBAction func tapGesture(_ sender: Any) {
        print("tap")
        welcomeLabel.setHidden(true)
        mcTempBuffer += "."
        morseCodeTextLabel.setText(mcTempBuffer)
        WKInterfaceDevice.current().play(.click)
    }
    
    @IBAction func rightSwipe(_ sender: Any) {
        print("right swipe")
        welcomeLabel.setHidden(true)
        mcTempBuffer += "-"
        morseCodeTextLabel.setText(mcTempBuffer)
        
        WKInterfaceDevice.current().play(.click)
        let ms = 1000
        usleep(useconds_t(50 * ms)) //will sleep for 50 milliseconds
        WKInterfaceDevice.current().play(.click)
    }
    
    
    @IBAction func downSwipe(_ sender: Any) {
        print("down swipe")
        if mcTempBuffer.count > 0 {
            if let letterOrNumber = morseCodeDictionary[mcTempBuffer] {
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
        }
        else {
            let synth : AVSpeechSynthesizer = AVSpeechSynthesizer.init()
            synth.delegate = self as? AVSpeechSynthesizerDelegate
            let speechUtterance: AVSpeechUtterance = AVSpeechUtterance(string: englishString)
            synth.speak(speechUtterance)
            WKInterfaceDevice.current().play(.success) //successfully played audio
        }
    }
    
    
    @IBAction func upSwipe(_ sender: Any) {
        if mcTempBuffer.count > 0 {
            mcTempBuffer.removeLast()
            morseCodeTextLabel.setText(mcTempBuffer)
        }
        else if englishString.count > 0 {
            englishString.removeLast()
            englishTextLabel.setText(englishString)
            if englishString.count == 0 {
                welcomeLabel.setHidden(false)
            }
        }
        else {
            print("nothing to delete")
            WKInterfaceDevice.current().play(.failure)
        }
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

