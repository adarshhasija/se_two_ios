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
    
    var defaultInstruction = "Tap or Swipe Right to begin typing morse code\n\nOr\n\nForce press for morse code dictionary"
    var dcScrollStart = "Rotate the digital crown down to read the morse code"
    var stopReadingString = "Swipe left once to stop reading and start typing"
    var keepTypingString = "Keep typing"
    var noMoreMatchesString = "No more matches found for this morse code"
    var typingSuggestions : [String ] = [/*"Yes", "No"*/]
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
    var synth : AVSpeechSynthesizer?
    
    @IBOutlet weak var englishTextLabel: WKInterfaceLabel!
    @IBOutlet weak var morseCodeTextLabel: WKInterfaceLabel!
    @IBOutlet weak var instructionsLabel: WKInterfaceLabel!
    
    
    @IBAction func tapGesture(_ sender: Any) {
        morseCodeInput(input: ".")
    }
    
    @IBAction func rightSwipe(_ sender: Any) {
        morseCodeInput(input: "-")
    }
    
    
    @IBAction func upSwipe(_ sender: Any) {
        if isReading() == true {
            //Should not be permitted when user is reading
            return
        }
        if synth?.isSpeaking == true {
            return
        }
        if morseCodeString.count > 0 {
            if morseCodeString.last == "|" {
                synth = AVSpeechSynthesizer.init()
                synth?.delegate = self
                let speechUtterance: AVSpeechUtterance = AVSpeechUtterance(string: englishString)
                synth?.speak(speechUtterance)
                WKInterfaceDevice.current().play(.success)
                instructionsLabel.setText("System is speaking the text...")
            }
            else if let letterOrNumber = morseCode.mcTreeNode?.alphabet {
                //first deal with space. Remove the visible space character and replace with an actual space to make it look more normal. Space character was just there for visual clarity
                if englishString.last == "␣" {
                    englishString.removeLast()
                    englishString += " "
                }
                englishString += letterOrNumber
                englishTextLabel.setText(englishString)
                englishTextLabel.setHidden(false)
                morseCodeString += "|"
                morseCodeTextLabel.setText(morseCodeString)
                WKInterfaceDevice.current().play(.success) //successfully got a letter/number
                instructionsLabel.setText("Keep Typing\nor\nSwipe up again to play audio. Ensure your watch is not on Silent Mode.")
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
                    nearestMatchesString += "\n" + match
                }
                instructionsLabel.setText(nearestMatchesString)
            }
        }
    }
    
    
    @IBAction func leftSwipe(_ sender: Any) {
        if isReading() == true {
            englishString = ""
            englishTextLabel.setText("")
            morseCodeString = ""
            morseCodeTextLabel.setText("")
            instructionsLabel.setText(defaultInstruction)
            return
        }
        if morseCodeString.count > 0 {
            if morseCodeString.last != "|" {
                //Should not be a character separator
                morseCodeString.removeLast()
                morseCodeTextLabel.setText(morseCodeString)
                isAlphabetReached(input: "b") //backspace
                WKInterfaceDevice.current().play(.success)
            }
            else {
                //If it is a normal letter/number, delete the last english character and corresponding morse code characters
                if let lastChar = englishString.last {
                    if let lastCharMorseCodeLength = (morseCode.alphabetToMCDictionary[String(lastChar)])?.count {
                        morseCodeString.removeLast(lastCharMorseCodeLength + 1) //+1 to include both the morse code part and the ending pipe "|"
                        morseCodeTextLabel.setText(morseCodeString)
                    }
                }
                englishString.removeLast()
                englishTextLabel.setText(englishString)
                WKInterfaceDevice.current().play(.success)
            }
        }
        else {
            print("nothing to delete")
            WKInterfaceDevice.current().play(.failure)
        }
        
        if morseCodeString.count == 0 && englishString.count == 0 {
            instructionsLabel.setText(defaultInstruction)
        }
    }
    
    
    @IBAction func longPress(_ sender: Any) {
        self.presentTextInputController(withSuggestions: self.typingSuggestions, allowedInputMode: .plain, completion: { (answers) -> Void in
            if var answer = answers?[0] as? String {
                self.isUserTyping = false
                self.morseCodeStringIndex = -1
                self.englishStringIndex = -1
                while self.morseCode.mcTreeNode?.parent != nil {
                    self.morseCode.mcTreeNode = self.morseCode.mcTreeNode?.parent
                }
                
                answer = answer.uppercased().trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "'", with: "")
                if answer.count < 1 {
                    return
                }
                self.englishString = answer
                self.morseCodeString = ""
                self.englishTextLabel.setText(answer)
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
                
                self.instructionsLabel.setText(self.dcScrollStart)
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
        instructionsLabel.setText(defaultInstruction)
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
        //morseCode.destroyTree()
    }
}

extension MCInterfaceController : AVSpeechSynthesizerDelegate {
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        var finalString = "Lightly long press to reply by talking"
        if typingSuggestions.count > 0 {
            finalString += " or typing"
        }
        instructionsLabel.setText(finalString)
        WKInterfaceDevice.current().play(.success)
        synth = nil
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        var finalString = "Lightly long press to reply by talking"
        if typingSuggestions.count > 0 {
            finalString += " or typing"
        }
        instructionsLabel.setText(finalString)
        WKInterfaceDevice.current().play(.failure)
        synth = nil
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
                setInstructionLabelForMode(mainString: "Rotate the crown upwards to scroll back", readingString: stopReadingString, writingString: keepTypingString)
                return
            }
            
            
            setInstructionLabelForMode(mainString: "Scroll to the end to read all the characters", readingString: stopReadingString, writingString: keepTypingString)
            setSelectedCharInLabel(inputString: morseCodeString, index: morseCodeStringIndex, label: morseCodeTextLabel)
            playSelectedCharacterHaptic(inputString: morseCodeString, inputIndex: morseCodeStringIndex)
            
            if isPrevMCCharPipe(input: morseCodeString, currentIndex: morseCodeStringIndex, isReverse: false) || englishStringIndex == -1 {
                //Need to change the selected character of the English string
                englishStringIndex += 1
                if englishStringIndex >= englishString.count {
                    WKInterfaceDevice.current().play(.failure)
                    return
                }
                if isEngCharSpace() {
                    let start = englishString.index(englishString.startIndex, offsetBy: englishStringIndex)
                    let end = englishString.index(englishString.startIndex, offsetBy: englishStringIndex + 1)
                    englishString.replaceSubrange(start..<end, with: "␣")
                }
                else {
                    englishString = englishString.replacingOccurrences(of: "␣", with: " ")
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
                setInstructionLabelForMode(mainString: dcScrollStart, readingString: stopReadingString, writingString: keepTypingString)
                
                if morseCodeStringIndex < 0 {
                    morseCodeTextLabel.setText(morseCodeString) //If there is still anything highlighted green, remove the highlight and return everything to default color
                    englishStringIndex = -1
                    englishTextLabel.setText(englishString)
                }
                return
            }
            
            setSelectedCharInLabel(inputString: morseCodeString, index: morseCodeStringIndex, label: morseCodeTextLabel)
            playSelectedCharacterHaptic(inputString: morseCodeString, inputIndex: morseCodeStringIndex)
            
            if isPrevMCCharPipe(input: morseCodeString, currentIndex: morseCodeStringIndex, isReverse: true) {
                //Need to change the selected character of the English string
                englishStringIndex -= 1
                if isEngCharSpace() {
                    let start = englishString.index(englishString.startIndex, offsetBy: englishStringIndex)
                    let end = englishString.index(englishString.startIndex, offsetBy: englishStringIndex + 1)
                    englishString.replaceSubrange(start..<end, with: "␣")
                }
                else {
                    englishString = englishString.replacingOccurrences(of: "␣", with: " ")
                }
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

    //This function tells us if the previous char was a pipe. It is a sign to change the character in the English string
    func isPrevMCCharPipe(input : String, currentIndex : Int, isReverse : Bool) -> Bool {
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
    
    func isEngCharSpace() -> Bool {
        let index = englishString.index(englishString.startIndex, offsetBy: englishStringIndex)
        let char = String(englishString[index])
        if char == " " {
            return true
        }
        return false
    }
    
    
    //Sets the particular character to green to indicate selected
    //If the index is out of bounds, the entire string will come white. eg: when index = -1
    func setSelectedCharInLabel(inputString : String, index : Int, label : WKInterfaceLabel) {
        let range = NSRange(location:index,length:1) // specific location. This means "range" handle 1 character at location 2
        
        //The replacement of space with visible space only applies to english strings
        let attributedString = NSMutableAttributedString(string: inputString, attributes: nil)
        // here you change the character to green color
        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.green, range: range)
        label.setAttributedText(attributedString)
    }
    
    func setSelectedCharsInLabel(inputString : String, index : Int, label : WKInterfaceLabel, range : Int) {
        let range = NSRange(location:index,length:1) // specific location. This means "range" handle 1 character at location 2
        
        //The replacement of space with visible space only applies to english strings
        let attributedString = NSMutableAttributedString(string: inputString, attributes: nil)
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
                setRecommendedActionsText()
            }
        }
        else if input == "-" {
            if morseCode.mcTreeNode?.dashNode != nil {
                morseCode.mcTreeNode = morseCode.mcTreeNode?.dashNode
                setRecommendedActionsText()
            }
        }
        else if input == "b" {
            //backspace
            if morseCode.mcTreeNode?.parent != nil {
                morseCode.mcTreeNode = morseCode.mcTreeNode?.parent
                setRecommendedActionsText()
            }
        }
    }
    
    
    func setRecommendedActionsText() {
        var instructionsString = "" //"\n" + "Force press for morse code dictionary"
        if morseCodeString.count == 1 {
            //We will only show this when the user has typed 1 character
            instructionsString += "\n" + "Swipe left to delete last character"
        }
        
        if morseCode.mcTreeNode?.alphabet != nil {
            //welcomeLabel.setText("Swipe up to set\n\n"+morseCode.mcTreeNode!.alphabet!)
            var recommendations = ""
            recommendations += "Swipe up to set: " + morseCode.mcTreeNode!.alphabet! + "\n"
            let nextCharMatches = morseCode.getNextCharMatches(currentNode: morseCode.mcTreeNode)
            for nextMatch in nextCharMatches {
                recommendations += "\n" + nextMatch
            }
            instructionsString.insert(contentsOf: recommendations + "\n", at: instructionsString.startIndex)
            
        }
        else if isNoMoreMatchesAfterThis() == true {
            //The haptic for dot will be played so no failure haptic
            //Only want to display the message that there are no more matches
            instructionsString.insert(contentsOf: noMoreMatchesString + "\n", at: instructionsString.startIndex)
        }
        else {
            
        }
        
        instructionsLabel.setText(instructionsString)
    }
    
    
    //Returns true if there are no more matches to be found in the morse code dictionary no matter what the user types
    func isNoMoreMatchesAfterThis() -> Bool? {
        //Current node is empty
        //does not have a dot or a dash after
        return morseCode.mcTreeNode?.character == nil &&
                morseCode.mcTreeNode?.dotNode == nil &&
                morseCode.mcTreeNode?.dashNode == nil
    }
    
    //2 strings for writing mode and reading mode
    func setInstructionLabelForMode(mainString: String, readingString: String, writingString: String) {
        var instructionString = mainString
        if !isUserTyping {
            instructionString += "\nOr\n" + readingString
        }
        else {
            instructionString += "\nOr\n" + writingString
        }
        self.instructionsLabel.setText(instructionString)
    }
    
    
    func morseCodeInput(input : String) {
        if isReading() == true {
            //We do not want the user to accidently delete all the text by tapping
            return
        }
        if isNoMoreMatchesAfterThis() == true {
            //Prevent the user from entering another character
            instructionsLabel.setText(noMoreMatchesString)
            WKInterfaceDevice.current().play(.failure)
            return
        }
        englishStringIndex = -1
        morseCodeStringIndex = -1
        if isUserTyping == false {
            userIsTyping(firstCharacter: input)
        }
        else {
            morseCodeString += input
        }
        isAlphabetReached(input: input)
        morseCodeTextLabel.setText(morseCodeString)
        englishTextLabel.setText(englishString) //This is to ensure that no characters are highlighted
        if input == "." {
            WKInterfaceDevice.current().play(.start)
        }
        else if input == "-" {
            WKInterfaceDevice.current().play(.stop)
            //WKInterfaceDevice.current().play(.start)
            //let ms = 1000
            //usleep(useconds_t(750 * ms)) //will sleep for 50 milliseconds
            //WKInterfaceDevice.current().play(.start)
        }
    }
    
    
}

