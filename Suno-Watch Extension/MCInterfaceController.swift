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
import WatchConnectivity

class MCInterfaceController : WKInterfaceController {
    
    var defaultInstructions = "Tap to start typing"
    var deafBlindInstructions = "Tap or Swipe Right to begin typing morse code\n\nOr\n\nForce press for more options"
    var notDeafBlindInstructions = "Long press to talk or type out a message\n\nOr\n\nForce press for more options"
    var dcScrollStart = "Rotate the digital crown to read"
    var stopReadingString = "Swipe left once to stop reading and type"
    var keepTypingString = "Keep typing"
    var noMoreMatchesString = "No more matches found for this morse code"
    var typingSuggestions : [String ] = ["Hi", "Yes", "No"]
    var isUserTyping : Bool = false
    var morseCodeString : String = ""
    var englishString : String = ""
    var alphabetToMcDictionary : [String : String] = [:]
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
        sendAnalytics(eventName: "se3_watch_tap", parameters: [:])
        morseCodeInput(input: ".")
    }
    
    @IBAction func rightSwipe(_ sender: Any) {
        sendAnalytics(eventName: "se3_watch_swipe_right", parameters: [:])
        morseCodeInput(input: "-")
    }
    
    
    @IBAction func upSwipe(_ sender: Any) {
        if isReading() == true {
            sendAnalytics(eventName: "se3_watch_swipe_up", parameters: [
                "state" : "reading"
            ])
            //Should not be permitted when user is reading
            return
        }
        if synth?.isSpeaking == true {
            sendAnalytics(eventName: "se3_watch_swipe_up", parameters: [
                "state" : "is_speaking"
            ])
            return
        }
        if morseCodeString.count > 0 {
            if morseCodeString.last == "|" {
                sendAnalytics(eventName: "se3_watch_swipe_up", parameters: [
                    "state" : "start_speaking",
                    "text" : self.englishString
                ])
                synth = AVSpeechSynthesizer.init()
                synth?.delegate = self
                let speechUtterance: AVSpeechUtterance = AVSpeechUtterance(string: englishString)
                synth?.speak(speechUtterance)
                //instructionsLabel.setText("System is speaking the text...")
                instructionsLabel.setText("")
                morseCodeTextLabel?.setHidden(true)
                changeEnteredTextSize(inputString: englishString, textSize: 40)
            }
            else if let letterOrNumber = morseCode.mcTreeNode?.alphabet {
                //first deal with space. Remove the visible space character and replace with an actual space to make it look more normal. Space character was just there for visual clarity
                sendAnalytics(eventName: "se3_watch_swipe_up", parameters: [
                    "state" : "mc_2_alphanumeric",
                    "text" : letterOrNumber
                ])
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
            else if let action = morseCode.mcTreeNode?.action {
                if action == "TIME" {
                    let hh = (Calendar.current.component(.hour, from: Date()))
                    let mm = (Calendar.current.component(.minute, from: Date()))
                    let hourString = hh < 10 ? "0" + String(hh) : String(hh)
                    let minString = mm < 10 ? "0" + String(mm) : String(mm)
                    englishString = hourString + minString
                    englishTextLabel?.setText(englishString)
                    englishTextLabel?.setHidden(false)
                    englishStringIndex = -1
                }
                else if action == "DATE" {
                    let day = (Calendar.current.component(.day, from: Date()))
                    let weekdayInt = (Calendar.current.component(.weekday, from: Date()))
                    let weekdayString = Calendar.current.weekdaySymbols[weekdayInt - 1]
                    englishString = String(day) + weekdayString.prefix(2).uppercased()
                    englishTextLabel?.setText(englishString)
                    englishTextLabel?.setHidden(false)
                    englishStringIndex = -1
                }
                morseCodeString = ""
                for character in englishString {
                    morseCodeString += morseCode.alphabetToMCDictionary[String(character)] ?? ""
                    morseCodeString += "|"
                }
                morseCodeTextLabel.setText(morseCodeString)
                morseCodeStringIndex = -1
                isUserTyping = false
                setInstructionLabelForMode(mainString: dcScrollStart, readingString: stopReadingString, writingString: keepTypingString)
                WKInterfaceDevice.current().play(.success)
                while morseCode.mcTreeNode?.parent != nil {
                    morseCode.mcTreeNode = morseCode.mcTreeNode!.parent
                }
            }
            else {
                sendAnalytics(eventName: "se3_watch_swipe_up", parameters: [
                    "state" : "no_result"
                ])
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
            sendAnalytics(eventName: "se3_watch_swipe_left", parameters: [
                "state" : "reading"
                ])
            englishString = ""
            englishTextLabel.setText("")
            morseCodeString = ""
            morseCodeTextLabel.setText("")
            instructionsLabel.setText(defaultInstructions)
            WKInterfaceDevice.current().play(.success)
            return
        }
        if morseCodeString.count > 0 {
            if morseCodeString.last != "|" {
                //Should not be a character separator
                sendAnalytics(eventName: "se3_watch_swipe_left", parameters: [
                    "state" : "last_morse_code"
                ])
                morseCodeString.removeLast()
                morseCodeTextLabel.setText(morseCodeString)
                isAlphabetReached(input: "b") //backspace
                WKInterfaceDevice.current().play(.success)
            }
            else {
                //If it is a normal letter/number, delete the last english character and corresponding morse code characters
                sendAnalytics(eventName: "se3_watch_swipe_left", parameters: [
                    "state" : "last_alphanumeric"
                ])
                if let lastChar = englishString.last {
                    if let lastCharMorseCodeLength = (morseCode.alphabetToMCDictionary[String(lastChar)])?.count {
                        morseCodeString.removeLast(lastCharMorseCodeLength + 1) //+1 to include both the morse code part and the ending pipe "|"
                        morseCodeTextLabel.setText(morseCodeString)
                    }
                }
                englishString.removeLast()
                if englishString.last == " " {
                    //If the last character is now is space, replace it with the carrat so that it can be seen
                    englishString.removeLast()
                    englishString.append("␣")
                }
                englishTextLabel.setText(englishString)
                WKInterfaceDevice.current().play(.success)
            }
        }
        else {
            print("nothing to delete")
            sendAnalytics(eventName: "se3_watch_swipe_left", parameters: [
                "state" : "nothing_to_delete"
            ])
            WKInterfaceDevice.current().play(.failure)
        }
        
        if morseCodeString.count == 0 && englishString.count == 0 {
            instructionsLabel.setText(defaultInstructions)
        }
    }
    
    
    @IBAction func longPress(_ sender: Any) {
        sendAnalytics(eventName: "se3_watch_long_press", parameters: [:])
        openTalkTypeMode()
    }
    
    @IBAction func tappedFAQs() {
      /*  presentAlert(withTitle: "About App", message: "This Apple Watch app is designed to help the deaf-blind communicate via touch. Deaf-blind can type using morse-code  and the app will speak it out in English. The other person can then speak and the app will convert the speech into morce-code taps that the deaf-blind can feel", preferredStyle: .alert, actions: [
        WKAlertAction(title: "OK", style: .default) {}
        ])  */
        sendAnalytics(eventName: "se3_watch_faq_tap", parameters: [:])
        pushController(withName: "FAQs", context: nil)
    }
    
    
    @IBAction func tappedDictionary() {
        sendAnalytics(eventName: "se3_watch_dictionary_tap", parameters: [:])
        pushController(withName: "Dictionary", context: nil)
    }
    
    
    @IBAction func tappedTalkType() {
        sendAnalytics(eventName: "se3_watch_talktype_tap", parameters: [:])
        openTalkTypeMode()
    }
    
    
    @IBAction func tappedSettingsDeafBlind() {
        sendAnalytics(eventName: "se3_watch_settings_db_tap", parameters: [:])
        pushController(withName: "SettingsDeafBlind", context: self)
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        WKInterfaceDevice.current().play(.success) //successfully launched app
        instructionsLabel.setText(defaultInstructions)
        if alphabetToMcDictionary.count < 1 {
            let morseCode : MorseCode = MorseCode()
            for morseCodeCell in morseCode.mcArray {
                if morseCodeCell.morseCode == "......." {
                    //space
                    alphabetToMcDictionary[" "] = morseCodeCell.morseCode
                }
                else {
                    alphabetToMcDictionary[morseCodeCell.english] = morseCodeCell.morseCode
                }
                
            }
        }
        
        //UserDefaults.standard.removeObject(forKey: "SE3_IS_DEAF_BLIND")
        let isDeafBlind = UserDefaults.standard.integer(forKey: "SE3_IS_DEAF_BLIND")
        if isDeafBlind == 0 {
            pushController(withName: "SettingsDeafBlind", context: self)
        }
        else {
            if isDeafBlind == 1 {
                defaultInstructions = deafBlindInstructions
            }
            if isDeafBlind == 2 {
                defaultInstructions = notDeafBlindInstructions
            }
            instructionsLabel.setText(defaultInstructions)
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
        var finalString = ""
        if isUserTyping == true {
            finalString.append("Lightly long press to reply by talking")
            if typingSuggestions.count > 0 {
                finalString += " or typing"
            }
            instructionsLabel.setText(finalString)
        }
        else {
            setInstructionLabelForMode(mainString: dcScrollStart, readingString: stopReadingString, writingString: keepTypingString)
        }
        
        WKInterfaceDevice.current().play(.success)
        synth = nil
        morseCodeTextLabel?.setHidden(false)
        changeEnteredTextSize(inputString: englishString, textSize: 16)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        var finalString = ""
        if isUserTyping == true {
            finalString.append("Lightly long press to reply by talking")
            if typingSuggestions.count > 0 {
                finalString += " or typing"
            }
            instructionsLabel.setText(finalString)
        }
        else {
            setInstructionLabelForMode(mainString: dcScrollStart, readingString: stopReadingString, writingString: keepTypingString)
        }
        
        WKInterfaceDevice.current().play(.failure)
        synth = nil
        morseCodeTextLabel?.setHidden(false)
        changeEnteredTextSize(inputString: englishString, textSize: 16)
    }
}

extension MCInterfaceController : WKCrownDelegate {
    
    func crownDidRotate(_ crownSequencer: WKCrownSequencer?, rotationalDelta: Double) {
        crownRotationalDelta  += rotationalDelta
        
        if crownRotationalDelta < -expectedMoveDelta {
            //downward scroll
            morseCodeStringIndex += 1
            crownRotationalDelta = 0.0
            
            if morseCodeStringIndex >= morseCodeString.count {
                sendAnalytics(eventName: "se3_watch_scroll_down", parameters: [
                    "state" : "index_greater_equal_0",
                    "is_reading" : self.isReading()
                ])
                morseCodeTextLabel.setText(morseCodeString) //If there is still anything highlighted green, remove the highlight and return everything to default color
                englishTextLabel.setText(englishString)
                WKInterfaceDevice.current().play(.success)
                setInstructionLabelForMode(mainString: "Rotate the crown upwards to scroll back", readingString: stopReadingString, writingString: keepTypingString)
                morseCodeStringIndex = morseCodeString.count //If the index has overshot the string length by some distance, bring it back to string length
                englishStringIndex = englishString.count
                return
            }
            
            sendAnalytics(eventName: "se3_watch_scroll_down", parameters: [
                "state" : "scrolling",
                "isReading" : self.isReading()
            ])
            setInstructionLabelForMode(mainString: "Scroll to the end to read all the characters", readingString: stopReadingString, writingString: keepTypingString)
            setSelectedCharInLabel(inputString: morseCodeString, index: morseCodeStringIndex, label: morseCodeTextLabel, isMorseCode: true, color: UIColor.green)
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
                sendAnalytics(eventName: "se3_watch_scroll_down", parameters: [
                    "state" : "index_alpha_change",
                    "is_reading" : self.isReading()
                ])
                setSelectedCharInLabel(inputString: englishString, index: englishStringIndex, label: englishTextLabel, isMorseCode: false, color : UIColor.green)
            }
        }
        else if crownRotationalDelta > expectedMoveDelta {
            //upward scroll
            morseCodeStringIndex -= 1
            crownRotationalDelta = 0.0
            
            if morseCodeStringIndex < 0 {
                sendAnalytics(eventName: "se3_watch_scroll_up", parameters: [
                    "state" : "index_less_0",
                    "is_reading" : self.isReading()
                ])
                WKInterfaceDevice.current().play(.failure)
                setInstructionLabelForMode(mainString: dcScrollStart, readingString: stopReadingString, writingString: keepTypingString)
                
                if morseCodeStringIndex < 0 {
                    morseCodeTextLabel.setText(morseCodeString) //If there is still anything highlighted green, remove the highlight and return everything to default color
                    englishStringIndex = -1
                    englishTextLabel.setText(englishString)
                }
                morseCodeStringIndex = -1 //If the index has gone behind the string by some distance, bring it back to -1
                return
            }
            
            sendAnalytics(eventName: "se3_watch_scroll_up", parameters: [
                "state" : "scrolling",
                "is_reading" : self.isReading()
            ])
            setSelectedCharInLabel(inputString: morseCodeString, index: morseCodeStringIndex, label: morseCodeTextLabel, isMorseCode: true, color : UIColor.green)
            playSelectedCharacterHaptic(inputString: morseCodeString, inputIndex: morseCodeStringIndex)
            
            if isPrevMCCharPipe(input: morseCodeString, currentIndex: morseCodeStringIndex, isReverse: true) {
                //Need to change the selected character of the English string
                englishStringIndex -= 1
                sendAnalytics(eventName: "se3_watch_scroll_up", parameters: [
                    "state" : "index_alpha_change",
                    "is_reading" : self.isReading()
                ])
                //FIrst check that the index is within bounds. Else isEngCharSpace() will crash
                if englishStringIndex > -1 && isEngCharSpace() {
                    let start = englishString.index(englishString.startIndex, offsetBy: englishStringIndex)
                    let end = englishString.index(englishString.startIndex, offsetBy: englishStringIndex + 1)
                    englishString.replaceSubrange(start..<end, with: "␣")
                }
                else {
                    englishString = englishString.replacingOccurrences(of: "␣", with: " ")
                }
                
                if englishStringIndex > -1 {
                    //Ensure that the index is within bounds
                    setSelectedCharInLabel(inputString: englishString, index: englishStringIndex, label: englishTextLabel, isMorseCode: false, color: UIColor.green)
                }
                
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
    
    
    //This is used when the user has just completed entering a message in morse code and is ready for the watch to say it aloud.
    func changeEnteredTextSize(inputString : String, textSize: Int) {
        let range = NSRange(location:0,length:inputString.count) // specific location. This means "range" handle 1 character at location 2
        
        //The replacement of space with visible space only applies to english strings
        let attributedString = NSMutableAttributedString(string: inputString, attributes: nil)
        
        attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: CGFloat(textSize)), range: range)
        englishTextLabel.setAttributedText(attributedString)
    }
    
    
    //Sets the particular character to green to indicate selected
    //If the index is out of bounds, the entire string will come white. eg: when index = -1
    func setSelectedCharInLabel(inputString : String, index : Int, label : WKInterfaceLabel, isMorseCode : Bool, color : UIColor) {
        let range = NSRange(location:index,length:1) // specific location. This means "range" handle 1 character at location 2
        
        //The replacement of space with visible space only applies to english strings
        let attributedString = NSMutableAttributedString(string: inputString, attributes: nil)
        // here you change the character to green color
        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: range)
        if isMorseCode {
            attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 25), range: range)
        }
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
        //if morseCodeString.count == 1 {
            //We will only show this when the user has typed 1 character
            //instructionsString += "\n" + "Swipe left to delete last character"
        //}
        
        
        var recommendations = ""
        if morseCode.mcTreeNode?.alphabet != nil || morseCode.mcTreeNode?.action != nil {
            //welcomeLabel.setText("Swipe up to set\n\n"+morseCode.mcTreeNode!.alphabet!)
            if morseCode.mcTreeNode?.alphabet != nil {
                recommendations += "Swipe up to set: " + morseCode.mcTreeNode!.alphabet! + "\n"
            }
            else if morseCode.mcTreeNode?.action != nil {
                recommendations += "Swipe up to get: " + morseCode.mcTreeNode!.action! + "\n"
            }
        }
        let nextCharMatches = morseCode.getNextCharMatches(currentNode: morseCode.mcTreeNode)
        for nextMatch in nextCharMatches {
            recommendations += "\n" + nextMatch
        }
        instructionsString.insert(contentsOf: recommendations + "\n", at: instructionsString.startIndex)
            
        
        
        if isNoMoreMatchesAfterThis() == true {
            //The haptic for dot/dash will be played so no failure haptic
            //Only want to display the message that there are no more matches
            instructionsString.insert(contentsOf: noMoreMatchesString + "\n", at: instructionsString.startIndex)
        }
        
        instructionsString += "\n" + "Swipe left to delete last character"
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
            instructionString += "\n\nOr\n\n" + readingString
        }
        else {
            instructionString += "\n\nOr\n\n" + writingString
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
            setSelectedCharInLabel(inputString: morseCodeString, index: morseCodeString.count - 1, label: morseCodeTextLabel, isMorseCode: true, color: UIColor.red)
            setRecommendedActionsText()
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
    
    func openTalkTypeMode() {
        self.presentTextInputController(withSuggestions: self.typingSuggestions, allowedInputMode: .plain, completion: { (answers) -> Void in
            if var answer = answers?[0] as? String {
                self.sendAnalytics(eventName: "se3_watch_reply", parameters: [
                    "text" : answer.prefix(100)
                ])
                self.isUserTyping = false
                self.morseCodeStringIndex = -1
                self.englishStringIndex = -1
                while self.morseCode.mcTreeNode?.parent != nil {
                    self.morseCode.mcTreeNode = self.morseCode.mcTreeNode?.parent
                }
                
                answer = answer.uppercased().trimmingCharacters(in: .whitespacesAndNewlines).filter("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ".contains) //Remove anything that is not alphanumeric
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
                //self.morseCodeString.removeLast() //Remove the last "|"
                self.morseCodeTextLabel.setText(self.morseCodeString)
                self.morseCodeTextLabel?.setHidden(true)
                self.instructionsLabel.setText("")
                self.changeEnteredTextSize(inputString: self.englishString, textSize: 40)
                self.synth = AVSpeechSynthesizer.init()
                self.synth?.delegate = self
                let speechUtterance: AVSpeechUtterance = AVSpeechUtterance(string: self.englishString)
                self.synth?.speak(speechUtterance)
            }
            
        })
    }
    
    
}

///Protocol
protocol MCInterfaceControllerProtocol {
    func settingDeafBlindChanged(isDeafBlind: Int)
}

extension MCInterfaceController : MCInterfaceControllerProtocol {
    func settingDeafBlindChanged(isDeafBlind: Int) {
        if isDeafBlind == 1 {
            defaultInstructions = deafBlindInstructions
        }
        else if isDeafBlind == 2 {
            defaultInstructions = notDeafBlindInstructions
        }
        instructionsLabel.setText(defaultInstructions)
    }
}

