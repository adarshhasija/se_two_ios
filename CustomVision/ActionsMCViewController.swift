//
//  ActionsMCViewController.swift
//  Suno
//
//  Created by Adarsh Hasija on 12/06/20.
//  Copyright © 2020 Adam Behringer. All rights reserved.
//

import Foundation
import UIKit
import AudioToolbox.AudioServices
import AVFoundation
import FirebaseAnalytics

class ActionsMCViewController : UIViewController {
    
    var hapticManager : HapticManager?
    lazy var supportsHaptics: Bool = {
        return (UIApplication.shared.delegate as? AppDelegate)?.supportsHaptics ?? false
    }()
    var morseCodeString : String = ""
    var englishString : String = ""
    var englishStringIndex = -1
    var morseCodeStringIndex = -1
    var morseCode = MorseCode()
    var synth : AVSpeechSynthesizer?
    var isUserTyping : Bool = false
    
    var defaultInstructions = "Start typing code for an action\nTap screen to type a dot"
    var noMoreMatchesString = "No more matches found for this morse code"
    var scrollStart = "Swipe right with 2 fingers to read"
    var stopReadingString = "Swipe left once with 1 finger to stop reading and type"
    var keepTypingString = "Keep typing"
    
    @IBOutlet weak var alphanumericLabel: UILabel!
    @IBOutlet weak var morseCodeLabel: UILabel!
    
    @IBOutlet weak var instructionsImageView: UIImageView!
    @IBOutlet weak var instructionsLabel: UILabel!
    
    
    
    @IBAction func gestureTap(_ sender: Any) {
        morseCodeInput(input: ".")
    }
    
    
    @IBAction func gestureSwipe(_ sender: UISwipeGestureRecognizer) {
        if sender.direction == UISwipeGestureRecognizerDirection.up {
            swipeUp()
        }
        else if sender.direction == UISwipeGestureRecognizerDirection.left  && sender.numberOfTouchesRequired == 1 {
            swipeLeft()
        }
        else if sender.direction == UISwipeGestureRecognizerDirection.left && sender.numberOfTouchesRequired == 2 {
            swipeLeft2Finger()
        }
        else if sender.direction == UISwipeGestureRecognizerDirection.right && sender.numberOfTouchesRequired == 2 {
            swipeRight2Finger()
        }
    }
    
    @IBAction func rightBarButtonItemTapped(_ sender: Any) {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let dictionaryViewController = storyBoard.instantiateViewController(withIdentifier: "UITableViewController-HHA-Ce-gYY") as! MCDictionaryTableViewController
        dictionaryViewController.typeToDisplay = "actions"
        self.navigationController?.pushViewController(dictionaryViewController, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Actions", style: .plain, target: self, action: #selector(rightBarButtonItemTapped))
        
        hapticManager = HapticManager(supportsHaptics: supportsHaptics)
        alphanumericLabel?.text = ""
        morseCodeLabel?.text = ""
        instructionsLabel?.text = defaultInstructions
    }
}

///All private helpers
extension ActionsMCViewController {
    
    func isReading() -> Bool {
        return !isUserTyping && morseCodeString.count > 0 && englishString.count > 0
    }
    
    func morseCodeInput(input : String) {
        if isReading() == true {
            //We do not want the user to accidently delete all the text by tapping
            return
        }
        if isNoMoreMatchesAfterThis() == true {
            //Prevent the user from entering another character
            MorseCodeUtils.setSelectedCharInLabel(inputString: morseCodeString, index: morseCodeString.count - 1, label: morseCodeLabel, isMorseCode: true, color: UIColor.red)
            setRecommendedActionsText()
            //try? hapticManager?.hapticForResult(success: false)
            hapticManager?.generateHaptic(code: hapticManager?.RESULT_FAILURE)
            return
        }
        englishStringIndex = -1
        morseCodeStringIndex = -1
        if isUserTyping == false {
            userHasBegunTyping(firstCharacter: input)
        }
        else {
            morseCodeString += input
        }
        isAlphabetReached(input: input)
        morseCodeLabel.text = morseCodeString
        alphanumericLabel.text = englishString //This is to ensure that no characters are highlighted
        morseCodeLabel.textColor = .none
        alphanumericLabel.textColor = .none
        if input == "." {
            //try? hapticManager?.hapticForMorseCode(isDash: false)
            hapticManager?.generateHaptic(code: hapticManager?.MC_DOT)
        }
        else if input == "-" {
            //try? hapticManager?.hapticForMorseCode(isDash: true)
            hapticManager?.generateHaptic(code: hapticManager?.MC_DASH)
        }
    }
    
    //Returns true if there are no more matches to be found in the morse code dictionary no matter what the user types
    func isNoMoreMatchesAfterThis() -> Bool? {
        //Current node is empty
        //does not have a dot or a dash after
        return morseCode.mcTreeNode?.character == nil &&
                morseCode.mcTreeNode?.dotNode == nil &&
                morseCode.mcTreeNode?.dashNode == nil
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
    
    func userHasBegunTyping(firstCharacter: String) {
        //Its the first character. Dont append. Overwrite what is there
        morseCodeString = firstCharacter
        englishString = ""
        alphanumericLabel.text = englishString
        isUserTyping = true
    }
    
    //We only want to show suggestions for actions
    func setRecommendedActionsText() {
        var instructionsString = ""
        //if morseCodeString.count == 1 {
            //We will only show this when the user has typed 1 character
            //instructionsString += "\n" + "Swipe left to delete last character"
        //}
        
        
        var recommendations = ""
        if morseCode.mcTreeNode?.action != nil {
            recommendations += "Swipe up for\n" + morseCode.mcTreeNode!.action! + "\n"
        }
        let nextCharMatches = morseCode.getNextActionMatches(currentNode: morseCode.mcTreeNode)
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
    
    func swipeUp() {
        if synth?.isSpeaking == true {
            Analytics.logEvent("se3_morse_swipe_up", parameters: [
                "state" : "is_speaking"
            ])
            return
        }
        
        if let action = morseCode.mcTreeNode?.action {
            Analytics.logEvent("se3_morse_swipe_up", parameters: [
                "state" : "action_"+action
            ])
            if action == "TIME" {
                let hh = (Calendar.current.component(.hour, from: Date()))
                let mm = (Calendar.current.component(.minute, from: Date()))
                let hourString = hh < 10 ? "0" + String(hh) : String(hh)
                let minString = mm < 10 ? "0" + String(mm) : String(mm)
                englishString = hourString + minString
                alphanumericLabel?.text = englishString
                alphanumericLabel?.isHidden = false
                englishStringIndex = -1
                hapticManager?.generateHaptic(code: hapticManager?.RESULT_SUCCESS)
                isUserTyping = false
            }
            else if action == "DATE" {
                let day = (Calendar.current.component(.day, from: Date()))
                let weekdayInt = (Calendar.current.component(.weekday, from: Date()))
                let weekdayString = Calendar.current.weekdaySymbols[weekdayInt - 1]
                englishString = String(day) + weekdayString.prefix(2).uppercased()
                alphanumericLabel?.text = englishString
                alphanumericLabel?.isHidden = false
                englishStringIndex = -1
                hapticManager?.generateHaptic(code: hapticManager?.RESULT_SUCCESS)
                isUserTyping = false
            }
            else if action == "CAMERA" {
                hapticManager?.generateHaptic(code: hapticManager?.RESULT_SUCCESS)
                isUserTyping = false
            }
            updateMorseCodeForActions()
        }
    }
    
    func swipeLeft() {
        if isReading() == true {
            Analytics.logEvent("se3_swipe_left", parameters: [
                "state" : "reading"
                ])
            englishString = ""
            alphanumericLabel?.text = ""
            morseCodeString = ""
            morseCodeLabel?.text = ""
            instructionsLabel?.text = defaultInstructions
            hapticManager?.generateHaptic(code: hapticManager?.RESULT_SUCCESS)
            return
        }
        if morseCodeString.count > 0 {
            Analytics.logEvent("se3_morse_swipe_left", parameters: [
                "state" : "last_morse_code"
            ])
            morseCodeString.removeLast()
            morseCodeLabel.text = morseCodeString
            isAlphabetReached(input: "b") //backspace
            //try? hapticManager?.hapticForResult(success: true)
            hapticManager?.generateHaptic(code: hapticManager?.RESULT_SUCCESS)
        }
        else {
            print("nothing to delete")
            Analytics.logEvent("se3_morse_swipe_left", parameters: [
                "state" : "nothing_to_delete"
            ])
            //try? hapticManager?.hapticForResult(success: false)
            hapticManager?.generateHaptic(code: hapticManager?.RESULT_FAILURE)
        }
        
        if morseCodeString.count == 0 && englishString.count == 0 {
            instructionsLabel.text = defaultInstructions
        }
    }
    
    func swipeLeft2Finger() {
        let morseCodeString = morseCodeLabel.text ?? ""
        var englishString = alphanumericLabel.text ?? ""
        morseCodeStringIndex -= 1
        if morseCodeStringIndex < 0 {
                Analytics.logEvent("se3_morse_scroll_left", parameters: [
                    "state" : "index_less_0"
                ])
                //try? hapticManager?.hapticForResult(success: false)
                hapticManager?.generateHaptic(code: hapticManager?.RESULT_FAILURE)
               
               setInstructionLabelForMode(mainString: scrollStart, readingString: stopReadingString, writingString: keepTypingString)
               if morseCodeStringIndex < 0 {
                   morseCodeLabel.text = morseCodeString //If there is still anything highlighted green, remove the highlight and return everything to default color
                   englishStringIndex = -1
                   alphanumericLabel.text = englishString
               }
               morseCodeStringIndex = -1 //If the index has gone behind the string by some distance, bring it back to -1
               return
           }

            Analytics.logEvent("se3_morse_scroll_left", parameters: [
                "state" : "scrolling"
            ])
           instructionsLabel?.text = "Swipe left with 2 fingers to go back"
           MorseCodeUtils.setSelectedCharInLabel(inputString: morseCodeString, index: morseCodeStringIndex, label: morseCodeLabel, isMorseCode: true, color : UIColor.green)
           hapticManager?.playSelectedCharacterHaptic(inputString: morseCodeString, inputIndex: morseCodeStringIndex) // TODO: Find out which call is the right call
             //hapticManager?.generateHaptic(code: String(morseCodeString[morseCodeString.index(morseCodeString.startIndex, offsetBy: morseCodeStringIndex)]) == "." ? hapticManager?.MC_DOT : hapticManager?.MC_DASH)
           
           if MorseCodeUtils.isPrevMCCharPipe(input: morseCodeString, currentIndex: morseCodeStringIndex, isReverse: true) {
               //Need to change the selected character of the English string
               englishStringIndex -= 1
                Analytics.logEvent("se3_morse_scroll_left", parameters: [
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
                   MorseCodeUtils.setSelectedCharInLabel(inputString: englishString, index: englishStringIndex, label: alphanumericLabel, isMorseCode: false, color: UIColor.green)
               }
               
           }
    }
    
    func swipeRight2Finger() {
        let morseCodeString = morseCodeLabel.text ?? ""
        var englishString = alphanumericLabel.text ?? ""
        morseCodeStringIndex += 1
        if morseCodeStringIndex >= morseCodeString.count {
            Analytics.logEvent("se3_morse_scroll_right", parameters: [
                "state" : "index_greater_equal_0"
            ])
            instructionsLabel?.text = "Swipe left with 2 fingers to go back"
            morseCodeLabel.text = morseCodeString //If there is still anything highlighted green, remove the highlight and return everything to default color
            alphanumericLabel.text = englishString
            //WKInterfaceDevice.current().play(.success)
            morseCodeStringIndex = morseCodeString.count //If the index has overshot the string length by some distance, bring it back to string length
            englishStringIndex = englishString.count
            return
        }
        instructionsLabel?.text = "Swipe right with 2 fingers to read morse code"
        MorseCodeUtils.setSelectedCharInLabel(inputString: morseCodeString, index: morseCodeStringIndex, label: morseCodeLabel, isMorseCode: true, color: UIColor.green)
        hapticManager?.playSelectedCharacterHaptic(inputString: morseCodeString, inputIndex: morseCodeStringIndex)  // TODO: Still need to see which version is the right version
        //hapticManager?.generateHaptic(code: String(morseCodeString[morseCodeString.index(morseCodeString.startIndex, offsetBy: morseCodeStringIndex)]) == "." ? hapticManager?.MC_DOT : hapticManager?.MC_DASH)
        
        if MorseCodeUtils.isPrevMCCharPipe(input: morseCodeString, currentIndex: morseCodeStringIndex, isReverse: false) || englishStringIndex == -1 {
            //Need to change the selected character of the English string
            englishStringIndex += 1
            if englishStringIndex >= englishString.count {
                //WKInterfaceDevice.current().play(.failure)
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
            Analytics.logEvent("se3_morse_scroll_right", parameters: [
                "state" : "index_alpha_change"
            ])
            MorseCodeUtils.setSelectedCharInLabel(inputString: englishString, index: englishStringIndex, label: alphanumericLabel, isMorseCode: false, color : UIColor.green)
        }
    }
    
    //Only used for TIME, DATE, Maths
    func updateMorseCodeForActions() {
        morseCodeString = ""
        for character in englishString {
            morseCodeString += morseCode.alphabetToMCDictionary[String(character)] ?? ""
            morseCodeString += "|"
        }
        morseCodeLabel.text = morseCodeString
        hapticManager?.generateHaptic(code: hapticManager?.RESULT_SUCCESS)
        morseCodeStringIndex = -1
        isUserTyping = false
        setInstructionLabelForMode(mainString: scrollStart, readingString: stopReadingString, writingString: keepTypingString)
        while morseCode.mcTreeNode?.parent != nil {
            morseCode.mcTreeNode = morseCode.mcTreeNode!.parent
        }
        //WKInterfaceDevice.current().play(.success)
        //whiteSpeechViewControllerProtocol?.setMorseCodeMessage(englishInput: englishString, morseCodeInput: morseCodeString)
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
