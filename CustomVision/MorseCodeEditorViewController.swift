//
//  MorseCodeEditorViewController.swift
//  Suno
//
//  Created by Adarsh Hasija on 04/03/20.
//  Copyright © 2020 Adam Behringer. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import FirebaseAnalytics

public class MorseCodeEditorViewController : UIViewController {
    
    var hapticManager : HapticManager?
    lazy var supportsHaptics: Bool = {
        return (UIApplication.shared.delegate as? AppDelegate)?.supportsHaptics ?? false
    }()
    var whiteSpeechViewControllerProtocol : WhiteSpeechViewControllerProtocol?
    
    var defaultInstructions = "Tap or Swipe Right to begin typing"
    var noMoreMatchesString = "No more matches found for this morse code"
    var scrollStart = "Swipe right with 2 fingers to read"
    var stopReadingString = "Swipe left once with 1 finger to stop reading and type"
    var keepTypingString = "Keep typing"
    var morseCodeString : String = ""
    var englishString : String = ""
    var englishStringIndex = -1
    var morseCodeStringIndex = -1
    var morseCode = MorseCode()
    var synth : AVSpeechSynthesizer?
    var isUserTyping : Bool = false
    
    @IBOutlet weak var mainStackVIew: UIStackView!
    @IBOutlet weak var dictionaryButton: UIButton!
    @IBOutlet weak var englishTextLabel: UILabel!
    @IBOutlet weak var morseCodeTextLabel: UILabel!
    @IBOutlet weak var instructionsLabel: UILabel!
    @IBOutlet weak var exitInstructionLabel: UILabel!
    
    
    @IBAction func tapGesture(_ sender: Any) {
        morseCodeInput(input: ".")
    }
    @IBAction func longPressGesture(_ sender: Any) {
        Analytics.logEvent("se3_morse_long_press", parameters: [:])
        try? hapticManager?.hapticForResult(success: true)
        navigationController?.popViewController(animated: true)
    }
    @IBAction func swipeGesture(_ sender: UISwipeGestureRecognizer) {
        if sender.direction == UISwipeGestureRecognizerDirection.right {
            morseCodeInput(input: "-")
        }
        else if sender.direction == UISwipeGestureRecognizerDirection.up {
            if synth?.isSpeaking == true {
                Analytics.logEvent("se3_morse_swipe_up", parameters: [
                    "state" : "is_speaking"
                ])
                return
            }
            if morseCodeString.count > 0 {
                if morseCodeString.last == "|" {
                    
                    let mathResult = performMathCalculation(inputString: englishString) //NSExpression(format:englishString).expressionValue(with: nil, context: nil) as? Int //This wont work if the string also contains alphabets
                    var isMath = false
                    if mathResult != nil {
                        isMath = true
                        englishString = String(mathResult!)
                        englishTextLabel?.text = englishString
                        updateMorseCodeForActions()
                    }
                    if isMath {
                        Analytics.logEvent("se3_morse_swipe_up", parameters: [
                            "state" : "speak_math"
                        ])
                    }
                    else {
                        Analytics.logEvent("se3_morse_scroll_up", parameters: [
                            "state" : "speak"
                        ])
                    }
                    synth = AVSpeechSynthesizer.init()
                    synth?.delegate = self
                    let speechUtterance: AVSpeechUtterance = AVSpeechUtterance(string: englishString)
                    synth?.speak(speechUtterance)
                    exitInstructionLabel.isHidden = true
                    instructionsLabel?.isHidden = true
                    morseCodeTextLabel?.isHidden = true
                    dictionaryButton?.isHidden = true
                    changeEnteredTextSize(inputString: englishString, textSize: 40)
                }
                else if let letterOrNumber = morseCode.mcTreeNode?.alphabet {
                    //first deal with space. Remove the visible space character and replace with an actual space to make it look more normal. Space character was just there for visual clarity
                    Analytics.logEvent("se3_morse_swipe_up", parameters: [
                        "state" : "mc_2_alphanumeric",
                        "text" : letterOrNumber
                    ])
                    if englishString.last == "␣" {
                        englishString.removeLast()
                        englishString += " "
                    }
                    englishString += letterOrNumber
                    englishTextLabel.text = englishString
                    englishTextLabel.isHidden = false
                    morseCodeString += "|"
                    morseCodeTextLabel.text = morseCodeString
                    try? hapticManager?.hapticForResult(success: true) //successfully got a letter/number
                    instructionsLabel.text = "Keep Typing\nor\nSwipe up again to complete"
                    while morseCode.mcTreeNode?.parent != nil {
                        morseCode.mcTreeNode = morseCode.mcTreeNode!.parent
                    }
                }
                else if let action = morseCode.mcTreeNode?.action {
                    Analytics.logEvent("se3_morse_swipe_up", parameters: [
                        "state" : "action_"+action
                    ])
                    if action == "TIME" {
                        let hh = (Calendar.current.component(.hour, from: Date()))
                        let mm = (Calendar.current.component(.minute, from: Date()))
                        let hourString = hh < 10 ? "0" + String(hh) : String(hh)
                        let minString = mm < 10 ? "0" + String(mm) : String(mm)
                        englishString = hourString + minString
                        englishTextLabel?.text = englishString
                        englishTextLabel?.isHidden = false
                        englishStringIndex = -1
                    }
                    else if action == "DATE" {
                        let day = (Calendar.current.component(.day, from: Date()))
                        let weekdayInt = (Calendar.current.component(.weekday, from: Date()))
                        let weekdayString = Calendar.current.weekdaySymbols[weekdayInt - 1]
                        englishString = String(day) + weekdayString.prefix(2).uppercased()
                        englishTextLabel?.text = englishString
                        englishTextLabel?.isHidden = false
                        englishStringIndex = -1
                    }
                    updateMorseCodeForActions()
                }
                else {
                    Analytics.logEvent("se3_morse_swipe_up", parameters: [
                        "state" : "no_result"
                    ])
                    //did not get a letter/number
                    try? hapticManager?.hapticForResult(success: false)
                    let nearestMatches : [String] = morseCode.getNearestMatches(currentNode: morseCode.mcTreeNode)
                    var nearestMatchesString = ""
                    for match in nearestMatches {
                        nearestMatchesString += "\n" + match
                    }
                    instructionsLabel.text = nearestMatchesString
                }
            }
        }
        else if sender.direction == UISwipeGestureRecognizerDirection.left {
            if morseCodeString.count > 0 {
                if morseCodeString.last != "|" {
                    //Should not be a character separator
                    Analytics.logEvent("se3_morse_swipe_left", parameters: [
                        "state" : "last_morse_code"
                    ])
                    morseCodeString.removeLast()
                    morseCodeTextLabel.text = morseCodeString
                    isAlphabetReached(input: "b") //backspace
                    try? hapticManager?.hapticForResult(success: true)
                }
                else {
                    //If it is a normal letter/number, delete the last english character and corresponding morse code characters
                    Analytics.logEvent("se3_morse_swipe_left", parameters: [
                        "state" : "last_alphanumeric"
                    ])
                    if let lastChar = englishString.last {
                        if let lastCharMorseCodeLength = (morseCode.alphabetToMCDictionary[String(lastChar)])?.count {
                            morseCodeString.removeLast(lastCharMorseCodeLength + 1) //+1 to include both the morse code part and the ending pipe "|"
                            morseCodeTextLabel.text = morseCodeString
                        }
                    }
                    englishString.removeLast()
                    if englishString.last == " " {
                        //If the last character is now is space, replace it with the carrat so that it can be seen
                        englishString.removeLast()
                        englishString.append("␣")
                    }
                    englishTextLabel.text = englishString
                    try? hapticManager?.hapticForResult(success: true)
                }
            }
            else {
                print("nothing to delete")
                Analytics.logEvent("se3_morse_swipe_left", parameters: [
                    "state" : "nothing_to_delete"
                ])
                try? hapticManager?.hapticForResult(success: false)
            }
            
            if morseCodeString.count == 0 && englishString.count == 0 {
                instructionsLabel.text = defaultInstructions
            }
        }
    }
    
    
    @IBAction func swipeGestureDouble(_ sender: UISwipeGestureRecognizer) {
        if sender.direction == UISwipeGestureRecognizerDirection.left {
            morseCodeStringIndex -= 1
            
            if morseCodeStringIndex < 0 {
                Analytics.logEvent("se3_morse_dswipe_left", parameters: [
                    "state" : "index_less_0"
                ])
                try? hapticManager?.hapticForResult(success: false)
                setInstructionLabelForMode(mainString: scrollStart, readingString: stopReadingString, writingString: keepTypingString)
                
                if morseCodeStringIndex < 0 {
                    morseCodeTextLabel.text = morseCodeString //If there is still anything highlighted green, remove the highlight and return everything to default color
                    englishStringIndex = -1
                    englishTextLabel.text = englishString
                }
                morseCodeStringIndex = -1 //If the index has gone behind the string by some distance, bring it back to -1
                return
            }

            Analytics.logEvent("se3_morse_dswipe_left", parameters: [
                "state" : "scrolling"
            ])
            MorseCodeUtils.setSelectedCharInLabel(inputString: morseCodeString, index: morseCodeStringIndex, label: morseCodeTextLabel, isMorseCode: true, color : UIColor.green)
            hapticManager?.playSelectedCharacterHaptic(inputString: morseCodeString, inputIndex: morseCodeStringIndex)
            
            if MorseCodeUtils.isPrevMCCharPipe(input: morseCodeString, currentIndex: morseCodeStringIndex, isReverse: true) {
                //Need to change the selected character of the English string
                englishStringIndex -= 1
                Analytics.logEvent("se3_morse_dswipe_left", parameters: [
                    "state" : "index_alpha_change"
                ])
                //FIrst check that the index is within bounds. Else isEngCharSpace() will crash
                if englishStringIndex > -1 && MorseCodeUtils.isEngCharSpace(englishString: englishString, englishStringIndex: englishStringIndex) {
                    let start = englishString.index(englishString.startIndex, offsetBy: englishStringIndex)
                    let end = englishString.index(englishString.startIndex, offsetBy: englishStringIndex + 1)
                    englishString.replaceSubrange(start..<end, with: "␣")
                }
                else {
                    englishString = englishString.replacingOccurrences(of: "␣", with: " ")
                }
                
                if englishStringIndex > -1 {
                    //Ensure that the index is within bounds
                    MorseCodeUtils.setSelectedCharInLabel(inputString: englishString, index: englishStringIndex, label: englishTextLabel, isMorseCode: false, color: UIColor.green)
                }
                
            }
            
        }
        else if sender.direction == UISwipeGestureRecognizerDirection.right {
            morseCodeStringIndex += 1
            
            if morseCodeStringIndex >= morseCodeString.count {
                Analytics.logEvent("se3_morse_dswipe_right", parameters: [
                    "state" : "index_greater_equal_0"
                ])
                morseCodeTextLabel.text = morseCodeString //If there is still anything highlighted green, remove the highlight and return everything to default color
                englishTextLabel.text = englishString
                try? hapticManager?.hapticForResult(success: true)
                setInstructionLabelForMode(mainString: "Swipe left with 2 fingers to scroll back", readingString: stopReadingString, writingString: keepTypingString)
                morseCodeStringIndex = morseCodeString.count //If the index has overshot the string length by some distance, bring it back to string length
                englishStringIndex = englishString.count
                return
            }
            
            Analytics.logEvent("se3_morse_dswipe_right", parameters: [
                "state" : "scrolling"
            ])
            setInstructionLabelForMode(mainString: "Keep swiping right with 2 fingers to read all the characters", readingString: stopReadingString, writingString: keepTypingString)
            MorseCodeUtils.setSelectedCharInLabel(inputString: morseCodeString, index: morseCodeStringIndex, label: morseCodeTextLabel, isMorseCode: true, color: UIColor.green)
            hapticManager?.playSelectedCharacterHaptic(inputString: morseCodeString, inputIndex: morseCodeStringIndex)
            
            if MorseCodeUtils.isPrevMCCharPipe(input: morseCodeString, currentIndex: morseCodeStringIndex, isReverse: false) || englishStringIndex == -1 {
                //Need to change the selected character of the English string
                englishStringIndex += 1
                if englishStringIndex >= englishString.count {
                    try? hapticManager?.hapticForResult(success: false)
                    return
                }
                if MorseCodeUtils.isEngCharSpace(englishString: englishString, englishStringIndex: englishStringIndex) {
                    let start = englishString.index(englishString.startIndex, offsetBy: englishStringIndex)
                    let end = englishString.index(englishString.startIndex, offsetBy: englishStringIndex + 1)
                    englishString.replaceSubrange(start..<end, with: "␣")
                }
                else {
                    englishString = englishString.replacingOccurrences(of: "␣", with: " ")
                }
                Analytics.logEvent("se3_morse_dswipe_right", parameters: [
                    "state" : "index_alpha_change"
                ])
                MorseCodeUtils.setSelectedCharInLabel(inputString: englishString, index: englishStringIndex, label: englishTextLabel, isMorseCode: false, color : UIColor.green)
            }
        }
    }
    
    
    public override func viewDidLoad() {
        if supportsHaptics {
            hapticManager = HapticManager()
        }
        englishTextLabel?.text = ""
        morseCodeTextLabel?.text = ""
        instructionsLabel?.text = defaultInstructions
    }
    
    //This is used when the user has just completed entering a message in morse code and is ready for the watch to say it aloud.
    func changeEnteredTextSize(inputString : String, textSize: Int) {
        let range = NSRange(location:0,length:inputString.count) // specific location. This means "range" handle 1 character at location 2
        
        //The replacement of space with visible space only applies to english strings
        let attributedString = NSMutableAttributedString(string: inputString, attributes: nil)
        
        attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: CGFloat(textSize)), range: range)
        englishTextLabel.attributedText = attributedString
    }
    
    //Only used for TIME, DATE, Maths
    func updateMorseCodeForActions() {
        morseCodeString = ""
        for character in englishString {
            morseCodeString += morseCode.alphabetToMCDictionary[String(character)] ?? ""
            morseCodeString += "|"
        }
        morseCodeTextLabel.text = morseCodeString
        morseCodeStringIndex = -1
        isUserTyping = false
        setInstructionLabelForMode(mainString: scrollStart, readingString: stopReadingString, writingString: keepTypingString)
        //WKInterfaceDevice.current().play(.success)
        while morseCode.mcTreeNode?.parent != nil {
            morseCode.mcTreeNode = morseCode.mcTreeNode!.parent
        }
    }
    
    //If there is a result, returns string of result
    //If there is no result, returns null
    //Only accepts format x +-x/ y
    func performMathCalculation(inputString: String) -> String? {
        let variablesPlus = inputString.split(separator: "+")
        let variablesMinus = inputString.split(separator: "-")
        let variablesMultiply = inputString.split(separator: "X")
        let variablesDivide = inputString.split(separator: "/")
        
        
        if variablesPlus.count == 2 {
            let variable0 = Int(variablesPlus[0])
            let variable1 = Int(variablesPlus[1])
            if variable0 != nil && variable1 != nil {
                let result = variable0! + variable1!
                return String(result)
            }
        }
        if variablesMinus.count == 2 {
            let variable0 = Int(variablesMinus[0])
            let variable1 = Int(variablesMinus[1])
            if variable0 != nil && variable1 != nil {
                let result = variable0! - variable1!
                return String(result)
            }
        }
        if variablesMultiply.count == 2 {
            let variable0 = Int(variablesMultiply[0])
            let variable1 = Int(variablesMultiply[1])
            if variable0 != nil && variable1 != nil {
                let result = variable0! * variable1!
                return String(result)
            }
        }
        if variablesDivide.count == 2 {
            let variable0 = Int(variablesDivide[0])
            let variable1 = Int(variablesDivide[1])
            if variable0 != nil && variable1 != nil {
                if variable0! < 1 || variable1! < 1 {
                    //It will throw a divide by 0 error
                    return nil
                }
                let result = variable0! / variable1!
                return String(result)
            }
        }
        
        return nil
    }
    
    func morseCodeInput(input : String) {
        if isNoMoreMatchesAfterThis() == true {
            //Prevent the user from entering another character
            MorseCodeUtils.setSelectedCharInLabel(inputString: morseCodeString, index: morseCodeString.count - 1, label: morseCodeTextLabel, isMorseCode: true, color: UIColor.red)
            setRecommendedActionsText()
            //WKInterfaceDevice.current().play(.failure)
            try? hapticManager?.hapticForResult(success: false)
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
        morseCodeTextLabel.text = morseCodeString
        englishTextLabel.text = englishString //This is to ensure that no characters are highlighted
        morseCodeTextLabel.textColor = .none
        englishTextLabel.textColor = .none
        if input == "." {
            //WKInterfaceDevice.current().play(.start)
            try? hapticManager?.hapticForMorseCode(isDash: false)
        }
        else if input == "-" {
            //WKInterfaceDevice.current().play(.stop)
            try? hapticManager?.hapticForMorseCode(isDash: true)
        }
    }
    
    func userIsTyping(firstCharacter: String) {
        //Its the first character. Dont append. Overwrite what is there
        morseCodeString = firstCharacter
        englishString = ""
        englishTextLabel.text = englishString
        isUserTyping = true
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
        instructionsLabel.text = instructionsString
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
        self.instructionsLabel.text = instructionString
    }
}


extension MorseCodeEditorViewController : AVSpeechSynthesizerDelegate {
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        let mutableAttributedString = NSMutableAttributedString(string: utterance.speechString)
        mutableAttributedString.addAttribute(.foregroundColor, value: UIColor.blue, range: characterRange)
        let font = englishTextLabel?.font
        let alignment = englishTextLabel?.textAlignment
        englishTextLabel?.attributedText = mutableAttributedString //all attributes get ovverridden here. necessary to save it before hand
        englishTextLabel?.font = font
        if alignment != nil { englishTextLabel?.textAlignment = alignment! }
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        //try? hapticManager?.hapticForResult(success: true) //done at the receiver end
        englishTextLabel?.textColor = .none
        synth = nil
        dictionaryButton?.isHidden = false
        morseCodeTextLabel?.isHidden = false
        changeEnteredTextSize(inputString: englishString, textSize: 16)
        whiteSpeechViewControllerProtocol?.setMorseCodeMessage(englishInput: englishString, morseCodeInput: morseCodeString)
        self.navigationController?.popViewController(animated: true)
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        try? hapticManager?.hapticForResult(success: false)
        synth = nil
        dictionaryButton?.isHidden = false
        morseCodeTextLabel?.isHidden = false
        instructionsLabel?.isHidden = false
        exitInstructionLabel?.isHidden = false
        changeEnteredTextSize(inputString: englishString, textSize: 16)
        //self.navigationController?.popViewController(animated: true)
    }
}
