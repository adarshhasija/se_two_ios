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
    
    var defaultInstruction = "Tap=Dot\nSwipe right=Dash\n\nForce press=more options"
    var dcScrollStart = "Rotate the digital crown down to read the morse code\nSwipe left once to stop reading and start typing"
    var isUserTyping : Bool = false
    var morseCodeString : String = ""
    var englishString : String = ""
    var alphabetToMcDictionary : [String : String] = [:]
    var mcToAlphabetDictionary : [String : String] = [:]
    var englishStringIndex = -1
    var morseCodeStringIndex = -1
    let expectedMoveDelta = 0.523599 //Here, current delta value = 30° Degree, Set delta value according requirement.
    var crownRotationalDelta = 0.0
    var morseCode = MorseCode()
    
    @IBOutlet weak var englishTextLabel: WKInterfaceLabel!
    @IBOutlet weak var morseCodeTextLabel: WKInterfaceLabel!
    @IBOutlet weak var welcomeLabel: WKInterfaceLabel!
    
    
    @IBAction func tapGesture(_ sender: Any) {
        if isReading() == true {
            //We do not want the user to accidently delete all the text by tapping
            return
        }
        englishStringIndex = -1
        morseCodeStringIndex = -1
        if isUserTyping == false {
            userIsTyping(firstCharacter: ".")
        }
        else {
            morseCodeString += "."
        }
        isAlphabetReached(input: ".")
        morseCodeTextLabel.setText(morseCodeString)
        WKInterfaceDevice.current().play(.start)
    }
    
    @IBAction func rightSwipe(_ sender: Any) {
        if isReading() == true {
            //We do not want the user to accidently delete all the text by swiping right
            return
        }
        englishStringIndex = -1
        morseCodeStringIndex = -1
        if isUserTyping == false {
            userIsTyping(firstCharacter: "-")
        }
        else {
            morseCodeString += "-"
        }
        
        isAlphabetReached(input: "-")
        morseCodeTextLabel.setText(morseCodeString)
        
        WKInterfaceDevice.current().play(.stop)
        //WKInterfaceDevice.current().play(.start)
        //let ms = 1000
        //usleep(useconds_t(750 * ms)) //will sleep for 50 milliseconds
        //WKInterfaceDevice.current().play(.start)
    }
    
    
    @IBAction func upSwipe(_ sender: Any) {
        if isReading() == true {
            //Should not be permitted when user is reading
            return
        }
        if morseCodeString.count > 0 {
            if let letterOrNumber = mcToAlphabetDictionary[morseCodeString] {
                //first deal with space. Remove the visible space character and replace with an actual space to make it look more normal. Space character was just there for visual clarity
                if englishString.last == "␣" {
                    englishString.removeLast()
                    englishString += " "
                }
                englishString += letterOrNumber
                englishTextLabel.setText(englishString)
                englishTextLabel.setHidden(false)
                morseCodeString.removeAll()
                morseCodeTextLabel.setText("")
                WKInterfaceDevice.current().play(.success) //successfully got a letter/number
                welcomeLabel.setText("Swipe up again to play audio")
                while morseCode.mcTreeNode?.parent != nil {
                    morseCode.mcTreeNode = morseCode.mcTreeNode!.parent
                }
            }
            else {
                //did not get a letter/number
                WKInterfaceDevice.current().play(.failure)
                let nearestMatches : [String] = morseCode.getNearestMatches(currentNode: morseCode.mcTreeNode)
                var nearestMatchesString = ""
                for match in nearestMatches {
                    nearestMatchesString += match
                }
                welcomeLabel.setText(nearestMatchesString)
            }
        }
        else {
            let synth : AVSpeechSynthesizer = AVSpeechSynthesizer.init()
            synth.delegate = self as? AVSpeechSynthesizerDelegate
            let speechUtterance: AVSpeechUtterance = AVSpeechUtterance(string: englishString)
            synth.speak(speechUtterance)
            WKInterfaceDevice.current().play(.success)
            welcomeLabel.setText("Lightly long press to reply by talking or typing")
        }
    }
    
    
    @IBAction func leftSwipe(_ sender: Any) {
        if isReading() == true {
            englishString = ""
            englishTextLabel.setText("")
            morseCodeString = ""
            morseCodeTextLabel.setText("")
            welcomeLabel.setText(defaultInstruction)
            return
        }
        if morseCodeString.count > 0 {
            morseCodeString.removeLast()
            morseCodeTextLabel.setText(morseCodeString)
            isAlphabetReached(input: "b") //backspace
            WKInterfaceDevice.current().play(.success)
        }
        else if englishString.count > 0 {
            englishString.removeLast()
            englishTextLabel.setText(englishString)
            WKInterfaceDevice.current().play(.success)
        }
        else if englishString.count == 0 {
            WKInterfaceDevice.current().play(.success)
        }
        else {
            print("nothing to delete")
            WKInterfaceDevice.current().play(.failure)
        }
        
        if morseCodeString.count == 0 && englishString.count == 0 {
            welcomeLabel.setText(defaultInstruction)
        }
    }
    
    
    @IBAction func longPress(_ sender: Any) {
        self.presentTextInputController(withSuggestions: ["Yes", "No"], allowedInputMode: .plain, completion: { (answers) -> Void in
            if var answer = answers?[0] as? String {
                self.isUserTyping = false
                self.morseCodeStringIndex = -1
                self.englishStringIndex = -1
                
                answer = answer.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
                if answer.count < 1 {
                    return
                }
                self.englishString = answer
                self.morseCodeString = ""
                self.englishTextLabel.setText(answer.replacingOccurrences(of: " ", with: "␣")) //We want to put a visible space for the viewer
                self.englishTextLabel.setHidden(false)
                self.morseCodeTextLabel.setText("")
                for char in answer {
                    let charAsString : String = String(char)
                    if let morseCode = self.alphabetToMcDictionary[charAsString] {
                        self.morseCodeString += morseCode
                    }
                    self.morseCodeString += "|"
                }
                self.morseCodeString.removeLast() //Remove the last "|"
                self.morseCodeTextLabel.setText(self.morseCodeString)
                self.morseCodeTextLabel.setHidden(false)
                
                self.welcomeLabel.setText(self.dcScrollStart)
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
        welcomeLabel.setText(defaultInstruction)
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
        self.crownSequencer.delegate = self
        self.crownSequencer.focus()
    }
    
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
}

extension MCInterfaceController : WKCrownDelegate {
    
    func crownDidRotate(_ crownSequencer: WKCrownSequencer?, rotationalDelta: Double) {
        crownRotationalDelta  += rotationalDelta
        
        if crownRotationalDelta < -expectedMoveDelta {
            //downward scroll
            morseCodeStringIndex += 1
            crownRotationalDelta = 0.0
            
            if morseCodeStringIndex < 0 {
                WKInterfaceDevice.current().play(.failure)
                return
            }
            if morseCodeStringIndex >= morseCodeString.count {
                WKInterfaceDevice.current().play(.success)
                self.welcomeLabel.setText("Rotate the crown upwards to scroll back\nOr\nSwipe left once to stop reading and start typing")
                return
            }
            
            setSelectedCharInLabel(inputString: morseCodeString, index: morseCodeStringIndex, label: morseCodeTextLabel)
            playSelectedCharacterHaptic(inputString: morseCodeString, inputIndex: morseCodeStringIndex)
            self.welcomeLabel.setText("You can also rotate the crown upwards to scroll back\nOr\nSwipe left once to stop reading and start typing")
            
            if isSpace(input: morseCodeString, currentIndex: morseCodeStringIndex, isReverse: false) || englishStringIndex == -1 {
                englishStringIndex += 1
                if englishStringIndex >= englishString.count {
                    WKInterfaceDevice.current().play(.failure)
                    return
                }
                setSelectedCharInLabel(inputString: englishString, index: englishStringIndex, label: englishTextLabel)
            }
        }
        else if crownRotationalDelta > expectedMoveDelta {
            //upward scroll
            morseCodeStringIndex -= 1
            crownRotationalDelta = 0.0
            
            if morseCodeStringIndex < 0 || morseCodeStringIndex >= morseCodeString.count {
                WKInterfaceDevice.current().play(.failure)
                welcomeLabel.setText(dcScrollStart)
                
                if morseCodeStringIndex < 0 {
                    morseCodeTextLabel.setText(morseCodeString) //If there is still anything highlighted green, remove the highlight and return everything to default color
                    englishStringIndex = -1
                    englishTextLabel.setText(englishString)
                }
                return
            }
            
            setSelectedCharInLabel(inputString: morseCodeString, index: morseCodeStringIndex, label: morseCodeTextLabel)
            playSelectedCharacterHaptic(inputString: morseCodeString, inputIndex: morseCodeStringIndex)
            
            if isSpace(input: morseCodeString, currentIndex: morseCodeStringIndex, isReverse: true) {
                englishStringIndex -= 1
                setSelectedCharInLabel(inputString: englishString, index: englishStringIndex, label: englishTextLabel)
            }
            
            
        }
            
        
    }
    
}

///Private Helpers
extension MCInterfaceController {
   
    func userIsTyping(firstCharacter: String) {
        //Its the first character. Dont append. Overwrite what is there
        morseCodeString = firstCharacter
        englishString = ""
        englishTextLabel.setText(englishString)
        isUserTyping = true
    }
    
    func playSelectedCharacterHaptic(inputString : String, inputIndex : Int) {
        let index = inputString.index(inputString.startIndex, offsetBy: inputIndex)
        let char = String(morseCodeString[index])
        if char == "." {
            WKInterfaceDevice.current().play(.start)
        }
        if char == "-" {
            WKInterfaceDevice.current().play(.stop)
        }
        if char == "|" {
            WKInterfaceDevice.current().play(.success)
        }
    }

    
    func isSpace(input : String, currentIndex : Int, isReverse : Bool) -> Bool {
        var retVal = false
        if isReverse {
            if currentIndex < input.count - 1 {
                //To ensure the next character down exists
                let index = morseCodeString.index(morseCodeString.startIndex, offsetBy: morseCodeStringIndex)
                let char = String(morseCodeString[index])
                let prevIndex = morseCodeString.index(morseCodeString.startIndex, offsetBy: morseCodeStringIndex + 1)
                let prevChar = String(morseCodeString[prevIndex])
                retVal = char != "|" && prevChar == "|"
            }
        }
        else if currentIndex > 0 {
            //To ensure the previous character exists
            let index = morseCodeString.index(morseCodeString.startIndex, offsetBy: morseCodeStringIndex)
            let char = String(morseCodeString[index])
            let prevIndex = morseCodeString.index(morseCodeString.startIndex, offsetBy: morseCodeStringIndex - 1)
            let prevChar = String(morseCodeString[prevIndex])
            retVal = char != "|" && prevChar == "|"
        }
        
        return retVal
    }
    
    
    //Sets the particular character to green to indicate selected
    //If the index is out of bounds, the entire string will come white. eg: when index = -1
    func setSelectedCharInLabel(inputString : String, index : Int, label : WKInterfaceLabel) {
        let range = NSRange(location:index,length:1) // specific location. This means "range" handle 1 character at location 2
        
        //The replacement of space with visible space only applies to english strings
        let attributedString = NSMutableAttributedString(string: inputString.replacingOccurrences(of: " ", with: "␣"), attributes: nil)
        // here you change the character to green color
        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.green, range: range)
        label.setAttributedText(attributedString)
    }
    
    
    func isReading() -> Bool {
        return !isUserTyping && morseCodeString.count > 0 && englishString.count > 0
    }
    
    func isAlphabetReached(input: String) {
        if input == "." {
            if morseCode.mcTreeNode?.dotNode != nil {
                morseCode.mcTreeNode = morseCode.mcTreeNode?.dotNode
                if morseCode.mcTreeNode?.alphabet != nil {
                    welcomeLabel.setText("Swipe up to set\n\n"+morseCode.mcTreeNode!.alphabet!)
                }
                else {
                    welcomeLabel.setText("")
                }
            }
        }
        else if input == "-" {
            if morseCode.mcTreeNode?.dashNode != nil {
                morseCode.mcTreeNode = morseCode.mcTreeNode?.dashNode
                if morseCode.mcTreeNode?.alphabet != nil {
                    welcomeLabel.setText("Swipe up to set\n\n"+morseCode.mcTreeNode!.alphabet!)
                }
                else {
                    welcomeLabel.setText("")
                }
            }
        }
        else if input == "b" {
            //backspace
            if morseCode.mcTreeNode?.parent != nil {
                morseCode.mcTreeNode = morseCode.mcTreeNode?.parent
                if morseCode.mcTreeNode?.alphabet != nil {
                    welcomeLabel.setText("Swipe up to set\n\n"+morseCode.mcTreeNode!.alphabet!)
                }
                else {
                    welcomeLabel.setText("")
                }
            }
        }
    }
    
    
}

