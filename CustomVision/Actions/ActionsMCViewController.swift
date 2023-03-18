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
import WatchConnectivity

class ActionsMCViewController : UIViewController {
    
    var mInputAction : String? = nil
    var mInputAlphanumeric : String? = nil
    
    var hapticManager : HapticManager?
    lazy var supportsHaptics: Bool = {
        return (UIApplication.shared.delegate as? AppDelegate)?.supportsHaptics ?? false
    }()
    var englishStringIndex = -1
    var morseCodeStringIndex = -1
    var morseCode = MorseCode()
    var synth = AVSpeechSynthesizer()
    var isUserTyping : Bool = false
    var indicesOfPipes : [Int] = [] //This is needed when highlighting morse code when the user taps on the screen to play audio
    var startTimeNanos : UInt64 = 0 //Used to calculate speed of crown rotation
    var quickSwipeTimeThreshold = 1000000000 //If two 2-finger swipes happen within this many nano seconds, we go into autoplay
    var isAutoPlayOn : Bool = false
    
    var defaultInstructions = "Tap screen to type a dot"
    var noMoreMatchesString = "No more matches found for this morse code"
    var scrollStart = "Swipe right with 2 fingers to read"
    var stopReadingString = "Swipe left once to stop reading and type"
    var keepTypingString = "Keep typing"
    
    @IBOutlet weak var alphanumericLabel: UILabel!
    @IBOutlet weak var morseCodeLabel: UILabel!
    @IBOutlet weak var instructionsImageView: UIImageView!
    @IBOutlet weak var instructionsLabel: UILabel!
    
    
    @IBAction func gestureTap(_ sender: UITapGestureRecognizer) {
        if isAutoPlayOn == true {
            //Animate instructions to indicate interruption is not allowed
            instructionsLabel.transform = CGAffineTransform(translationX: 20, y: 0)
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.2, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
                self.instructionsLabel.transform = CGAffineTransform.identity
            }, completion: nil)
            return
        }
        if sender.numberOfTouches == 1 {
            morseCodeInput(input: ".")
        }
    }
    
    
    @IBAction func gestureSwipe(_ sender: Any?) {
        var direction : String?
        if (sender as? UISwipeGestureRecognizer)?.state == .recognized {
            if (sender as! UISwipeGestureRecognizer).direction == UISwipeGestureRecognizerDirection.up {
                direction = "up"
            }
            else if (sender as! UISwipeGestureRecognizer).direction == UISwipeGestureRecognizerDirection.left {
                let endTime = DispatchTime.now()
                let diffNanos = endTime.uptimeNanoseconds - startTimeNanos
                if diffNanos <= quickSwipeTimeThreshold {
                    direction = "left_quick_swipe"
                }
                else {
                    direction = "left"
                    startTimeNanos = DispatchTime.now().uptimeNanoseconds
                }
            }
            else if (sender as! UISwipeGestureRecognizer).direction == UISwipeGestureRecognizerDirection.right {
                let endTime = DispatchTime.now()
                let diffNanos = endTime.uptimeNanoseconds - startTimeNanos
                if diffNanos <= quickSwipeTimeThreshold {
                    direction = "right_quick_swipe"
                }
                else {
                    direction = "right"
                    startTimeNanos = DispatchTime.now().uptimeNanoseconds
                }
            }
        }
        else if (sender is UIAccessibilityScrollDirection) {
            if (sender as! UIAccessibilityScrollDirection) == UIAccessibilityScrollDirection.down {
                direction = "up" //scroll down means swipe up
            }
            else if (sender as! UIAccessibilityScrollDirection) == UIAccessibilityScrollDirection.left {
                direction = "left"
            }
            else if (sender as! UIAccessibilityScrollDirection) == UIAccessibilityScrollDirection.right {
                direction = "right"
            }
        }
        
        if isAutoPlayOn == true {
            if direction == "left" {
                swipeLeft()
            }
            else {
                //Animate instructions to indicate interruption is not allowed
                instructionsLabel.transform = CGAffineTransform(translationX: 20, y: 0)
                UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.2, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
                    self.instructionsLabel.transform = CGAffineTransform.identity
                }, completion: nil)
            }
        }
        else {
            //Autoplay = FALSE
            if direction == "up" {
                //swipeUp()
            }
            else if direction == "left" {
                swipeLeft()
            }
            else if direction == "right" {
                swipeRight()
            }
            else if direction == "right_quick_swipe" {
                Analytics.logEvent("se3_ios_autoplay", parameters: [:])
                hapticManager?.generateHaptic(code: hapticManager?.RESULT_SUCCESS)
                englishStringIndex = -1
                morseCodeStringIndex = -1
                morseCodeAutoPlay(direction: "right")
            }
            else if direction == "left_quick_swipe" {
                Analytics.logEvent("se3_ios_autoplay_reverse", parameters: [:])
                hapticManager?.generateHaptic(code: hapticManager?.RESULT_SUCCESS)
                englishStringIndex = alphanumericLabel?.text?.count ?? -1
                morseCodeStringIndex = morseCodeLabel.text?.count ?? -1
                morseCodeAutoPlay(direction: "left")
            }
        }
        
    }
    
    @IBAction func rightBarButtonItemTapped(_ sender: Any) {
        Analytics.logEvent("se3_ios_right_bar_btn", parameters: [:])
        let storyBoard : UIStoryboard = UIStoryboard(name: "Dictionary", bundle:nil)
        if UIDevice.current.userInterfaceIdiom == .pad {
            let dictionaryNavController = storyBoard.instantiateViewController(withIdentifier: "DictionaryNavigationController") as! UINavigationController
            (dictionaryNavController.topViewController as? MCDictionaryTableViewController)?.typeToDisplay = "actions"
            dictionaryNavController.modalPresentationStyle = .popover
            let popover : UIPopoverPresentationController? = dictionaryNavController.popoverPresentationController
            popover?.barButtonItem = sender as? UIBarButtonItem
            present(dictionaryNavController, animated: true, completion: nil)
        }
        else {
            let dictionaryViewController = storyBoard.instantiateViewController(withIdentifier: "UITableViewController-HHA-Ce-gYY") as! MCDictionaryTableViewController
            dictionaryViewController.typeToDisplay = "actions"
            self.navigationController?.pushViewController(dictionaryViewController, animated: true)
        }
        
        
    }
    
    @IBAction func leftBarButtonItemTapped(_ sender: Any) {
        Analytics.logEvent("se3_ios_left_bar_btn", parameters: [:])
        let storyBoard : UIStoryboard = UIStoryboard(name: "Settings", bundle:nil)
        let settingsController = storyBoard.instantiateViewController(withIdentifier: "SettingsNavigationController") as! UINavigationController
        self.navigationController?.present(settingsController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hapticManager = HapticManager(supportsHaptics: supportsHaptics)
        if mInputAction != nil {
            swipeUp(inputAction: mInputAction)
            return
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Actions", style: .plain, target: self, action: #selector(rightBarButtonItemTapped))
        //navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), style: .plain, target: self, action: #selector(leftBarButtonItemTapped))
        
        alphanumericLabel?.text = ""
        morseCodeLabel?.text = ""
        instructionsImageView?.image = UIImage(systemName: "largecircle.fill.circle")
        animateImageEnlarge(image: instructionsImageView)
        instructionsLabel?.text = defaultInstructions
        view.accessibilityLabel = defaultInstructions
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, // announce
        defaultInstructions);
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //Notify a deaf-blind user that the app is open
        hapticManager?.generateHaptic(code: hapticManager?.RESULT_SUCCESS)
    }
    
}

///All private helpers
extension ActionsMCViewController {
    
    func isReading() -> Bool {
        let alphanumericString = alphanumericLabel?.text ?? ""
        let morseCodeString = morseCodeLabel?.text ?? ""
        return !isUserTyping && morseCodeString.count > 0 && alphanumericString.count > 0
    }
    
    func morseCodeInput(input : String) {
        let alphanumericString = alphanumericLabel?.text ?? ""
        var morseCodeString = morseCodeLabel?.text ?? ""
        if isReading() == true {
            //isReading already checks that englishString and morseCodeString are present!
            sayThis(string: alphanumericString)
            
            //We do not want the user to accidently delete all the text by tapping
            return
        }
        if isNoMoreMatchesAfterThis() == true {
            //Prevent the user from entering another character
            MorseCodeUtils.setSelectedCharInLabel(inputString: morseCodeString, index: morseCodeString.count - 1, length: 1, label: morseCodeLabel, isMorseCode: true, color: UIColor.red)
            setRecommendedActionsText()
            //try? hapticManager?.hapticForResult(success: false)
            hapticManager?.generateHaptic(code: hapticManager?.RESULT_FAILURE)
            return
        }
        englishStringIndex = -1
        morseCodeStringIndex = -1
        if isUserTyping == false {
            //animate first character
            morseCodeLabel?.text = input
            userHasBegunTyping(firstCharacter: input)
        }
        else {
            morseCodeString += input
            morseCodeLabel?.text = morseCodeString
            //animate instructions
            animateInstructions()
        }
        isAlphabetReached(input: input)
        alphanumericLabel.text = alphanumericString //This is to ensure that no characters are highlighted
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
        //morseCodeString = firstCharacter
        //englishString = ""
        alphanumericLabel.text = ""
        isUserTyping = true
        animateLabelEnlarge(label: self.morseCodeLabel)
    }
    
    func animateLabelEnlarge(label : UILabel?) {
        let transform = label?.transform.scaledBy(x: 20, y: 20)
        UIView.animate(withDuration: 1.0) {
            label?.transform = transform ?? CGAffineTransform()
            
            let transform2 = label?.transform.scaledBy(x: 1/20, y: 1/20)
            UIView.animate(withDuration: 1.0) {
                label?.transform = transform2 ?? CGAffineTransform()
            }
        }
    }
    
    func animateImageEnlarge(image: UIImageView) {
        let scale : CGFloat = 10.0
        let transform = image.transform.scaledBy(x: scale, y: scale)
        UIView.animate(withDuration: 1.0) {
            image.transform = transform
            
            let transform2 = image.transform.scaledBy(x: 1/scale, y: 1/scale)
            UIView.animate(withDuration: 1.0) {
                image.transform = transform2
            }
        }
    }
    
    //Not in use at the moment
    func animateInstructionsImageMove(direction : String) {
        var transform : CGAffineTransform? = nil
        var transform2 : CGAffineTransform? = nil
        if direction == "up" {
            transform = instructionsImageView?.transform.translatedBy(x: 0, y: -10)
            transform2 = instructionsImageView?.transform.translatedBy(x: 0, y: 10)
        }
        else if direction == "left" {
            transform = instructionsImageView?.transform.translatedBy(x: -50, y: 0)
            transform2 = instructionsImageView?.transform.translatedBy(x: 50, y: 0)
        }
        else if direction == "right" {
            transform = instructionsImageView?.transform.translatedBy(x: 50, y: 0)
            transform2 = instructionsImageView?.transform.translatedBy(x: -50, y: 0)
        }
        
        UIView.animate(withDuration: 1.0, animations: {
            self.instructionsImageView?.transform = transform ?? CGAffineTransform()
        }, completion: { _ in
            UIView.animate(withDuration: 1.0, animations: {
                self.instructionsImageView?.center.y -= 10
                self.instructionsImageView?.transform = transform2 ?? CGAffineTransform()
            }, completion: { _ in
                self.instructionsImageView?.center.y += 10
            })
        })
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
            instructionsImageView?.image = UIImage(systemName: "chevron.up")
            recommendations += "Swipe up for\n" + morseCode.mcTreeNode!.action! + "\n"
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, // announce
                "Swipe up for " + morseCode.mcTreeNode!.action!);  // actual text
            //animateInstructionsImageMove(direction: "up")
        }
        else {
            instructionsImageView?.image = UIImage(systemName: "largecircle.fill.circle")
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
        view.accessibilityLabel = instructionsString
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, // announce
        instructionsString);
    }
    
    func animateInstructions() {
        UIView.animate(withDuration: 1.0) {
            self.instructionsImageView.alpha = 0.0
            self.instructionsLabel.alpha = 0.0
            
            UIView.animate(withDuration: 2.0) {
                self.instructionsImageView.alpha = 1.0
                self.instructionsLabel.alpha = 1.0
            }
        }
    }
    
    func swipeUp(inputAction : String?) {
        if synth.isSpeaking == true {
            Analytics.logEvent("se3_ios_swipe_up", parameters: [
                "state" : "is_speaking"
            ])
            return
        }
        
        if let action = inputAction != nil ? inputAction : morseCode.mcTreeNode?.action {
            Analytics.logEvent("se3_ios_swipe_up", parameters: [
                "state" : "action_"+action
            ])
            if action == "TIME" {
                let hh = (Calendar.current.component(.hour, from: Date()))
                let mm = (Calendar.current.component(.minute, from: Date()))
                let hourString = hh < 10 ? "0" + String(hh) : String(hh)
                let minString = mm < 10 ? "0" + String(mm) : String(mm)
                let alphanumericString = hourString + minString
                alphanumericLabel?.text = alphanumericString
                alphanumericLabel?.isHidden = false
                englishStringIndex = -1
                hapticManager?.generateHaptic(code: hapticManager?.RESULT_SUCCESS)
                isUserTyping = false
                updateMorseCodeForActions(alphanumericString: alphanumericString)
                animateLabelEnlarge(label: self.alphanumericLabel)
            }
            else if action == "DATE" {
                let day = (Calendar.current.component(.day, from: Date()))
                let weekdayInt = (Calendar.current.component(.weekday, from: Date()))
                let weekdayString = Calendar.current.weekdaySymbols[weekdayInt - 1]
                let alphanumericString = String(day) + weekdayString.prefix(2).uppercased()
                alphanumericLabel?.text = alphanumericString
                alphanumericLabel?.isHidden = false
                englishStringIndex = -1
                hapticManager?.generateHaptic(code: hapticManager?.RESULT_SUCCESS)
                isUserTyping = false
                updateMorseCodeForActions(alphanumericString: alphanumericString)
                animateLabelEnlarge(label: self.alphanumericLabel)
            }
            else if action == "INPUT_ALPHANUMERIC" && mInputAlphanumeric != nil {
                isUserTyping = false
                alphanumericLabel?.text = mInputAlphanumeric
                updateMorseCodeForActions(alphanumericString: mInputAlphanumeric!)
            }
            else if action == "CAMERA" {
                hapticManager?.generateHaptic(code: hapticManager?.RESULT_SUCCESS)
                isUserTyping = false
                openCamera()
            }
        }
    }
    
    func swipeLeft() {
        if isAutoPlayOn == true {
            isAutoPlayOn = false //All reformatting will be done in autoplay timer
            hapticManager?.generateHaptic(code: hapticManager?.RESULT_SUCCESS) //A haptic to indicate that the left swipe has been registered
            return
        }
        let alphanumericString = alphanumericLabel?.text ?? ""
        var morseCodeString = morseCodeLabel?.text ?? ""
        if isReading() == true {
            Analytics.logEvent("se3_swipe_left", parameters: [
                "state" : "reading"
                ])
            while morseCode.mcTreeNode?.parent != nil {
                morseCode.mcTreeNode = morseCode.mcTreeNode!.parent
            }
         /*   alphanumericLabel?.text = ""
            morseCodeLabel?.text = ""
            instructionsLabel?.text = defaultInstructions
            view.accessibilityLabel = defaultInstructions
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, // announce
            defaultInstructions);
            instructionsImageView?.image = UIImage(systemName: "largecircle.fill.circle")
            hapticManager?.generateHaptic(code: hapticManager?.RESULT_SUCCESS)  */
            if isAutoPlayOn == true {
                isAutoPlayOn = false
                englishStringIndex = -1
                morseCodeStringIndex = -1
                return
            }
            mcScrollLeft()
            return
        }
        if morseCodeString.count > 0 {
            Analytics.logEvent("se3_ios_swipe_left", parameters: [
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
            Analytics.logEvent("se3_ios_swipe_left", parameters: [
                "state" : "nothing_to_delete"
            ])
            //try? hapticManager?.hapticForResult(success: false)
            hapticManager?.generateHaptic(code: hapticManager?.RESULT_FAILURE)
        }
        
        if morseCodeString.count == 0 && alphanumericString.count == 0 {
            instructionsLabel.text = defaultInstructions
            view.accessibilityLabel = defaultInstructions
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, // announce
            defaultInstructions);
            isUserTyping = false
        }
    }
    
    func swipeRight() {
        mcScrollRight()
    }
    
    func mcScrollLeft() {
        var alphanumericString = alphanumericLabel?.text ?? ""
        let morseCodeString = morseCodeLabel?.text ?? ""
        morseCodeStringIndex -= 1
        if morseCodeStringIndex < 0 {
                Analytics.logEvent("se3_ios_mc_left", parameters: [
                    "state" : "index_less_0"
                ])
                //try? hapticManager?.hapticForResult(success: false)
                hapticManager?.generateHaptic(code: hapticManager?.RESULT_FAILURE)
               
               if morseCodeStringIndex < 0 {
                   morseCodeLabel.text = morseCodeString //If there is still anything highlighted green, remove the highlight and return everything to default color
                   englishStringIndex = -1
                   alphanumericLabel.text = alphanumericString
               }
               morseCodeStringIndex = -1 //If the index has gone behind the string by some distance, bring it back to -1
               return
           }

            Analytics.logEvent("se3_ios_mc_left", parameters: [
                "state" : "scrolling"
            ])
           MorseCodeUtils.setSelectedCharInLabel(inputString: morseCodeString, index: morseCodeStringIndex, length: 1, label: morseCodeLabel, isMorseCode: true, color : UIColor.green)
        if isAutoPlayOn == false {
            hapticManager?.playSelectedCharacterHaptic(inputString: morseCodeString, inputIndex: morseCodeStringIndex)
        }
        else {
            //When resetting, We just want a short tap every time we are passing a character
            hapticManager?.generateHaptic(code: hapticManager?.MC_DOT)
        }
           
           
           if MorseCodeUtils.isPrevMCCharPipeOrSpace(input: morseCodeString, currentIndex: morseCodeStringIndex, isReverse: true) {
               //Need to change the selected character of the English string
               englishStringIndex -= 1
                Analytics.logEvent("se3_ios_mc_left", parameters: [
                    "state" : "index_alpha_change"
                ])
               //FIrst check that the index is within bounds. Else isEngCharSpace() will crash
               if englishStringIndex > -1 && MorseCodeUtils.isEngCharSpace(englishString: alphanumericString, englishStringIndex: englishStringIndex) {
                   let start = alphanumericString.index(alphanumericString.startIndex, offsetBy: englishStringIndex)
                   let end = alphanumericString.index(alphanumericString.startIndex, offsetBy: englishStringIndex + 1)
                   alphanumericString.replaceSubrange(start..<end, with: "␣")
               }
               else {
                   alphanumericString = alphanumericString.replacingOccurrences(of: "␣", with: " ")
               }
               
               if englishStringIndex > -1 {
                   //Ensure that the index is within bounds
                   MorseCodeUtils.setSelectedCharInLabel(inputString: alphanumericString, index: englishStringIndex, length: 1, label: alphanumericLabel, isMorseCode: false, color: UIColor.green)
               }
               
           }
    }
    
    func mcScrollRight() {
        var alphanumericString = alphanumericLabel?.text ?? ""
        let morseCodeString = morseCodeLabel?.text ?? ""
        morseCodeStringIndex += 1
        if morseCodeStringIndex >= morseCodeString.count {
            Analytics.logEvent("se3_ios_mc_right", parameters: [
                "state" : "index_greater_equal_0"
            ])
            morseCodeLabel.text = morseCodeString //If there is still anything highlighted green, remove the highlight and return everything to default color
            alphanumericLabel.text = alphanumericString
            //WKInterfaceDevice.current().play(.success)
            morseCodeStringIndex = morseCodeString.count //If the index has overshot the string length by some distance, bring it back to string length
            englishStringIndex = alphanumericString.count
            return
        }
        MorseCodeUtils.setSelectedCharInLabel(inputString: morseCodeString, index: morseCodeStringIndex, length: 1, label: morseCodeLabel, isMorseCode: true, color: UIColor.green)
        hapticManager?.playSelectedCharacterHaptic(inputString: morseCodeString, inputIndex: morseCodeStringIndex)
        
        if MorseCodeUtils.isPrevMCCharPipeOrSpace(input: morseCodeString, currentIndex: morseCodeStringIndex, isReverse: false) || englishStringIndex == -1 {
            //Need to change the selected character of the English string
            englishStringIndex += 1
            if englishStringIndex >= alphanumericString.count {
                //WKInterfaceDevice.current().play(.failure)
                return
            }
            if MorseCodeUtils.isEngCharSpace(englishString: alphanumericString, englishStringIndex: englishStringIndex) {
                let start = alphanumericString.index(alphanumericString.startIndex, offsetBy: englishStringIndex)
                let end = alphanumericString.index(alphanumericString.startIndex, offsetBy: englishStringIndex + 1)
                alphanumericString.replaceSubrange(start..<end, with: "␣")
            }
            else {
                alphanumericString = alphanumericString.replacingOccurrences(of: "␣", with: " ")
            }
            Analytics.logEvent("se3_ios_mc_right", parameters: [
                "state" : "index_alpha_change"
            ])
            MorseCodeUtils.setSelectedCharInLabel(inputString: alphanumericString, index: englishStringIndex,  length: 1, label: alphanumericLabel, isMorseCode: false, color : UIColor.green)
        }
        return
    }
    
    @objc func autoPlay(timer : Timer) {
        let dictionary : Dictionary = timer.userInfo as! Dictionary<String,String>
        let direction : String = dictionary["direction"] ?? ""
        if direction == "right" { mcScrollRight() } else { mcScrollLeft() }

        let count = morseCodeLabel.text?.count ?? -1
        if (direction == "right" && morseCodeStringIndex >= count)
            || (direction == "left" && morseCodeStringIndex < 0)
            || isAutoPlayOn == false {
            timer.invalidate()
            isAutoPlayOn = false
            alphanumericLabel?.textColor = .none
            morseCodeLabel?.textColor = .none
            morseCodeLabel.text = morseCodeLabel?.text?.replacingOccurrences(of: " ", with: "|") //Autoplay complete, restore pipes
            //instructionsImageView?.image = direction == "right" ? UIImage(systemName: "hand.point.left") : UIImage(systemName: "hand.point.right")
            //instructionsLabel?.text = direction == "down" ? "Swipe left quickly quickly to reset" : stopReadingString
            setInstructionLabel()
        }
    }
    
    func morseCodeAutoPlay(direction: String) {
        isAutoPlayOn = true
        alphanumericLabel?.textColor = .none //Resetting the string colors at the start of autoplay
        let morseCodeString = morseCodeLabel?.text
        morseCodeLabel?.text = morseCodeString?.replacingOccurrences(of: "|", with: " ") //We will not be playing pipes in autoplay
        morseCodeLabel?.textColor = .none
        instructionsImageView?.image = nil
        instructionsLabel?.text = direction == "right" ? "Autoplaying morse code...\nSwipe left to stop" : "Resetting...\nPlease wait"
                
        
        let dictionary = [
            "direction" : direction
        ]
        let timeInterval = direction == "right" ? 1 : 0.5
        Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(ActionsMCViewController.autoPlay(timer:)), userInfo: dictionary, repeats: true)
     /*   Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            let result = self.swipeRight2Finger()

            if result == false || self.isAutoPlayOn == false {
                timer.invalidate()
                self.isAutoPlayOn = false
                let morseCodeString = self.morseCodeLabel.text ?? ""
                self.morseCodeLabel?.text = morseCodeString.replacingOccurrences(of: " ", with: "|") //Autoplay complete, restore pipes
                self.alphanumericLabel?.textColor = .none
                self.morseCodeLabel?.textColor = .none
                self.morseCodeStringIndex = -1
                self.englishStringIndex = -1
                self.instructionsImageView?.image = UIImage(systemName: "hand.point.right")
                self.setInstructionLabel(mainString: self.scrollStart, readingString: self.stopReadingString, writingString: self.keepTypingString)
            }
        }   */
    }
    
    //Only used for TIME, DATE, Maths
    func updateMorseCodeForActions(alphanumericString: String) {
        //morseCodeString = ""
      /*  for character in englishString {
            morseCodeString += morseCode.alphabetToMCDictionary[String(character)] ?? ""
            morseCodeString += "|"
        }   */
        let morseCodeString = convertEnglishToMC(englishString: alphanumericString)
        morseCodeLabel.text = morseCodeString
        hapticManager?.generateHaptic(code: hapticManager?.RESULT_SUCCESS)
        morseCodeStringIndex = -1
        isUserTyping = false
        setInstructionLabel()
        //instructionsImageView?.image = UIImage(systemName: "hand.point.right")
        while morseCode.mcTreeNode?.parent != nil {
            morseCode.mcTreeNode = morseCode.mcTreeNode!.parent
        }
        //WKInterfaceDevice.current().play(.success)
        //whiteSpeechViewControllerProtocol?.setMorseCodeMessage(englishInput: englishString, morseCodeInput: morseCodeString)
    }
    
    //2 strings for writing mode and reading mode
    func setInstructionLabel() {
        var fullString = "Visually-impaired users:\nTap to hear text\n\n"
                        + "Deaf-blind users:\nSwipe right to read morse code. The phone will vibrate for each character.\n1 short vibration = dot\n1 long vibration = dash\n2 short vibrations = end of character"
        if WCSession.isSupported() {
            let session = WCSession.default
            if session.isWatchAppInstalled {
                fullString += "\n\nApple Watch:\nTo read this on your Apple Watch,open your watch app and select the option Morse Code From iPhone"
            }
        }
        self.instructionsLabel.text = fullString
        self.view.accessibilityLabel = fullString
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, // announce
        fullString);
    }
    
    private func convertEnglishToMC(englishString : String) -> String {
        let english = englishString.uppercased().trimmingCharacters(in: .whitespacesAndNewlines).filter("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ".contains).replacingOccurrences(of: " ", with: "␣")
        var morseCodeString = ""
        var index = 0
        indicesOfPipes.removeAll()
        indicesOfPipes.append(0)
        for character in english {
            var mcChar = morseCode.alphabetToMCDictionary[String(character)] ?? ""
            mcChar += "|"
            index += mcChar.count
            indicesOfPipes.append(index)
            morseCodeString += mcChar
        }
        
        return morseCodeString
    }
    
    func showToast(message : String) {
        
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 75, y: self.view.frame.size.height-100, width: 150, height: 60))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(1.0) //0.6
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center;
        toastLabel.numberOfLines = 2
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
    
    private func openCamera() {
        let storyBoard : UIStoryboard = UIStoryboard(name: "MainVision", bundle:nil)
        let visionMLViewController = storyBoard.instantiateViewController(withIdentifier: "VisionMLViewController") as! VisionMLViewController
        visionMLViewController.delegateActions = self
        hapticManager?.generateHaptic(code: hapticManager?.RESULT_SUCCESS)
        self.navigationController?.present(visionMLViewController, animated: true, completion: nil)
    }
    
    func receivedRequestForEnglishAndMCFromWatch() {
        let alphanumericString = alphanumericLabel?.text ?? ""
        let morseCodeString = morseCodeLabel?.text ?? ""
        sendEnglishAndMCToWatch(english: alphanumericString, morseCode: morseCodeString)
    }
    
    func sendEnglishAndMCToWatch(english: String, morseCode: String) {
        if WCSession.isSupported() {
            let session = WCSession.default
            if session.isWatchAppInstalled && session.isReachable {
                session.sendMessage(["is_english_mc": true, "english": english, "morse_code": morseCode], replyHandler: nil, errorHandler: nil)
            }
        }
    }
    
    //We do not set the delegate. This ensures that alphanumeric and morse code text are not replaced when the delegate methods are called
    private func sayThisInstruction(string: String) {
        let audioSession = AVAudioSession.sharedInstance()
        do { try audioSession.setCategory(AVAudioSessionCategoryPlayback) }
        catch { showToast(message: "Sorry, audio failed to play") }
        do { try audioSession.setMode(AVAudioSessionModeDefault) }
        catch { showToast(message: "Sorry, audio failed to play") }
        
        synth.delegate = nil
        let utterance = AVSpeechUtterance(string: string)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        if synth.isSpeaking {
            synth.stopSpeaking(at: AVSpeechBoundary.immediate)
            synth.speak(utterance)
        }
        if synth.isPaused {
            synth.continueSpeaking()
        }
        else if !synth.isSpeaking {
            synth.speak(utterance)
        }
    }
    
    private func sayThis(string: String) {
        let audioSession = AVAudioSession.sharedInstance()
        do { try audioSession.setCategory(AVAudioSessionCategoryPlayback) }
        catch { showToast(message: "Sorry, audio failed to play") }
        do { try audioSession.setMode(AVAudioSessionModeDefault) }
        catch { showToast(message: "Sorry, audio failed to play") }
        
        synth.delegate = self
        let utterance = AVSpeechUtterance(string: string)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        if synth.isSpeaking {
            synth.stopSpeaking(at: AVSpeechBoundary.immediate)
            synth.speak(utterance)
        }
        if synth.isPaused {
            synth.continueSpeaking()
        }
        else if !synth.isSpeaking {
            synth.speak(utterance)
        }
    }
}

protocol ActionsMCViewControllerProtocol {
    
    //To get text recognized by the camera
    func setTextFromCamera(english : String)
}

extension ActionsMCViewController : ActionsMCViewControllerProtocol {
    
    func setTextFromCamera(english: String) {
        Analytics.logEvent("se3_ios_cam_ret", parameters: [:]) //returned from camera
        hapticManager?.generateHaptic(code: hapticManager?.RESULT_SUCCESS) //This is just to notify the user that camera recognition is complete
        if english.count > 0 {
            Analytics.logEvent("se3_ios_cam_success", parameters: [:]) //returned from camera
            let englishFiltered = english.uppercased().trimmingCharacters(in: .whitespacesAndNewlines).filter("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ".contains)
            alphanumericLabel?.text = englishFiltered
            morseCodeLabel?.text = convertEnglishToMC(englishString: englishFiltered)
            englishStringIndex = -1
            morseCodeStringIndex = -1
            isUserTyping = false
            setInstructionLabel()
            instructionsImageView?.image = UIImage(systemName: "hand.point.right")
        }
    }
}

extension ActionsMCViewController : AVSpeechSynthesizerDelegate {
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        let mutableAttributedString = NSMutableAttributedString(string: utterance.speechString)
        mutableAttributedString.addAttribute(.foregroundColor, value: UIColor.green, range: characterRange)
        let font = alphanumericLabel?.font
        let alignment = alphanumericLabel?.textAlignment
        alphanumericLabel?.attributedText = mutableAttributedString //all attributes get ovverridden here. necessary to save it before hand
        alphanumericLabel?.font = font
        if alignment != nil { alphanumericLabel?.textAlignment = alignment! }
        
        if morseCodeLabel?.isHidden == true {
            return
        }
        let mcLowerBound = indicesOfPipes[safe: characterRange.lowerBound] ?? 0
        let mcUpperBound = indicesOfPipes[safe: characterRange.upperBound] ?? indicesOfPipes.last ?? mcLowerBound
        let mcRange = NSRange(location: mcLowerBound, length: mcUpperBound - mcLowerBound)
        let mutableAttributedStringMC = NSMutableAttributedString(string: morseCodeLabel.text ?? "")
        mutableAttributedStringMC.addAttribute(.foregroundColor, value: UIColor.green, range: mcRange)
        let fontMC = morseCodeLabel?.font
        let alignmentMC = morseCodeLabel?.textAlignment
        morseCodeLabel?.attributedText = mutableAttributedStringMC //all attributes get ovverridden here. necessary to save it before hand
        morseCodeLabel?.font = fontMC
        if alignmentMC != nil { morseCodeLabel?.textAlignment = alignmentMC! }
        
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        alphanumericLabel?.textColor = .none
        morseCodeLabel?.textColor = .none
    }
}
