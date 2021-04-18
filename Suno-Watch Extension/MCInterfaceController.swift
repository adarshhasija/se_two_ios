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
    
    var defaultInstructions = ""
    var tapToTypeInstructions = "Tap screen to type a dot"
    var f2fInstructions = "FACE-TO-FACE\nCHAT\n\nTap or Lightly long press to begin typing morse code"
    var notDeafBlindInstructions = "Force press for reply options"
    var dcScrollStart = "Rotate the digital crown down to feel each character"
    var dcScrollReverse = "Ratate the digital crown up to scroll back"
    var stopReadingString = "Swipe left once to stop reading and type morse code"
    var keepTypingString = "Keep typing"
    var noMoreMatchesString = "No more matches found for this morse code"
    var typingSuggestions : [String ] = ["HI", "YES", "NO"]
    var isUserTyping : Bool = false
    var morseCodeString : String = ""
    var englishString : String = ""
    var explanationArray : [String] = []
    var alphabetToMcDictionary : [String : String] = [:]
    var englishStringIndex = -1
    var morseCodeStringIndex = -1
    let expectedMoveDelta = 0.523599 //Here, current delta value = 30° Degree, Set delta value according requirement.
    var crownRotationalDelta = 0.0
    var morseCode = MorseCode()
    var synth : AVSpeechSynthesizer?
    var mode : String?
    var isAutoPlayOn : Bool = false
    var startTimeNanos : UInt64 = 0 //Used to calculate speed of crown rotation
    var isScreenActive = true
    var quickScrollTimeThreshold = 700000000 //If the digital crown is scrolled 30 degrees within this many nano seconds, we go into autoplay
    var isNormalMorse : Bool? = nil //Some functions, like TIME and DATE, can use customized vibrations and not normal morse code
    var autoPlayTimer : Timer? = nil
    
    @IBOutlet weak var mainImage: WKInterfaceImage!
    @IBOutlet weak var englishTextLabel: WKInterfaceLabel!
    @IBOutlet weak var morseCodeTextLabel: WKInterfaceLabel!
    @IBOutlet weak var instructionsLabel: WKInterfaceLabel!
    @IBOutlet weak var iphoneImage: WKInterfaceImage!
    @IBOutlet weak var bigTextLabel: WKInterfaceLabel!
    @IBOutlet weak var bigTextLabel2: WKInterfaceLabel!
    @IBOutlet weak var aboutButton: WKInterfaceButton!
    
    
    @IBAction func aboutButtonTapped() {
        var params : [String:Any] = [:]
        params["action"] = mode
        pushController(withName: "DictionaryDetail", context: params)
    }
    
    @IBAction func tapGesture(_ sender: Any) {
        sendAnalytics(eventName: "se3_watch_tap", parameters: [:])
        morseCodeInput(input: ".")
    }
    
    @IBAction func rightSwipe(_ sender: Any) {
        //sendAnalytics(eventName: "se3_watch_swipe_right", parameters: [:])
        //morseCodeInput(input: "-")
    }
    
    
    @IBAction func upSwipe(_ sender: Any) {
        if isAutoPlayOn == true {
            //Swipe up cannot interrupt Autoplay
            return
        }
        //This is not needed. In reading mode user can swipe up as many times as he likes to repeat the audio
        if isReading() == true {
            //sendAnalytics(eventName: "se3_watch_swipe_up", parameters: [
            //    "state" : "reading"
            //])
            //Should not be permitted when user is reading
            return
        }
        if mode == Action.GET_IOS.rawValue || mode == Action.CAMERA_OCR.rawValue {
            //Get from iPhone mode
            return
        }
        if synth?.isSpeaking == true {
            sendAnalytics(eventName: "se3_watch_swipe_up", parameters: [
                "state" : "is_speaking"
            ])
            return
        }
        
        if mode == "chat" && morseCodeString.count > 0 {
            if morseCodeString.last == "|" {
                
                let mathResult = performMathCalculation(inputString: englishString) //NSExpression(format:englishString).expressionValue(with: nil, context: nil) as? Int //This wont work if the string also contains alphabets
                var isMath = false
                if mathResult != nil {
                    isMath = true
                    englishString = String(mathResult!)
                    englishTextLabel?.setText(englishString)
                    updateMorseCodeForActions()
                }
                if isMath {
                    sendAnalytics(eventName: "se3_watch_swipe_up", parameters: [
                        "state" : "speak_math"
                    ])
                }
                else {
                    sendAnalytics(eventName: "se3_watch_swipe_up", parameters: [
                        "state" : "speak"
                    ])
                }
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
        else if let action = mode != nil ? mode : morseCode.mcTreeNode?.action {
            sendAnalytics(eventName: "se3_watch_swipe_up", parameters: [
                "state" : "action_"+action
            ])
            if let siriShortcut = SiriShortcut.shortcutsDictionary[Action(rawValue: action) ?? Action.UNKNOWN] {
                SiriShortcut.createINShortcutAndAddToSiriWatchFace(siriShortcut: siriShortcut) //Return value is used for Add To Siri button, which does not apply to watchOS at the moment
                //(WKExtension.shared().delegate as? ExtensionDelegate)?.setRelevantShortcuts(newShortcuts: relevantShortcuts)
            }
            let customInputs = SiriShortcut.getCustomInputs(action: Action(rawValue: action) ?? Action.UNKNOWN)
            englishString = customInputs[SiriShortcut.INPUT_FIELDS.input_alphanumerics.rawValue] as? String ?? ""
            englishTextLabel.setText(englishString)
            englishTextLabel.setHidden(false)
            morseCodeString = customInputs[SiriShortcut.INPUT_FIELDS.input_morse_code.rawValue] as? String ?? ""
            morseCodeTextLabel.setText(morseCodeString)
            explanationArray.append(contentsOf:  customInputs[SiriShortcut.INPUT_FIELDS.input_mc_explanation.rawValue] as? [String] ?? []
            )
            if action == "TIME" || action == "DATE" {
                isUserTyping = false
                morseCodeAutoPlay(direction: "down") //If it does not have a dependency on iPhone, it can autoplay by default
            }
            else if action == "1-to-1" {
                while morseCode.mcTreeNode?.parent != nil {
                    //Reset the tree
                    morseCode.mcTreeNode = morseCode.mcTreeNode!.parent
                }
                mainImage.setHidden(false)
                englishString = ""
                englishTextLabel.setText("")
                morseCodeString = ""
                morseCodeTextLabel.setText("")
                instructionsLabel.setText(mode == "chat" ? f2fInstructions : defaultInstructions)
                let params = [
                    "mode" : "chat"
                ]
                pushController(withName: "MCInterfaceController", context: params)
            }
            else {
                //Its an error. Action = UNKNOWN
                englishTextLabel.setHidden(true)
                morseCodeTextLabel.setHidden(true)
                setInstructionLabelForMode(mainString: "There was an error. You may have used a faulty complication. Please remove the complication from your watch face and add it again", readingString: "", writingString: "", isError: true)
                instructionsLabel.setHidden(false)
            }
        }
    }
    
    
    @IBAction func leftSwipe(_ sender: Any) {
     /*   if isAutoPlayOn == true {
            isAutoPlayOn = false //All reformatting will be done in autoplay timer
            WKInterfaceDevice.current().play(.success) //A haptic to indicate that the left swipe has been registered
            return
        }   */
        if isReading() == true {
            if mode != nil {
                //It means this is not the root screen
                return
            }
            
            sendAnalytics(eventName: "se3_watch_swipe_left", parameters: [
                "state" : "reading"
                ])
            mainImage.setHidden(mode == "chat" ? true : false)
            englishString = ""
            englishTextLabel.setText("")
            morseCodeString = ""
            morseCodeTextLabel.setText("")
            instructionsLabel.setText(mode == "chat" ? f2fInstructions : defaultInstructions)
            WKInterfaceDevice.current().play(.success)
            return
        }
        if mode == Action.GET_IOS.rawValue {
            //Get from iPhone mode
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
            mainImage.setHidden(mode == "chat" ? true : false)
            instructionsLabel.setText(mode == "chat" ? f2fInstructions : defaultInstructions)
        }
    }
    
    //Disabled in the storyboard. Re-enable if down swipe is required
    @IBAction func downSwipe(_ sender: Any) {
        //Swipe down to get text from the iPhone. We designed this in case user cannot read morse code on an older iPhone and wanted to transfer it to the watch.
        //Not using this functionality right now. We found a way to play haptics on older iPhones (6, 6S) using system vibrations
        
        sendAnalytics(eventName: "se3_watch_swipe_down", parameters: [:])
        //let watchDelegate = WKExtension.shared().delegate as? ExtensionDelegate
        //watchDelegate?.sendMessage()
        //Making this call to see if there is any morse code to get from the iPhone app
        if WCSession.isSupported() {
            setInstructionLabelForMode(mainString: "Get from iPhone mode", readingString: "", writingString: "", isError: false) //This is just to make sure screen has some text when feature is activated
            let session = WCSession.default
            if session.isReachable {
                if session.isCompanionAppInstalled == false {
                                setInstructionLabelForMode(mainString: "Update from phone failed:\n\niPhone app not installed", readingString: "", writingString: "", isError: true)
                    return
                }
                if mode == Action.CAMERA_OCR.rawValue {
                    setInstructionLabelForMode(mainString: "Getting from iPhone.\nPlease use the camera in the iPhone app to read text", readingString: "", writingString: "", isError: false)
                    iphoneImage?.setImage(UIImage(systemName: "iphone"))
                    iphoneImage?.setIsAccessibilityElement(true)
                    iphoneImage?.setAccessibilityLabel("iPhone")
                    iphoneImage?.setTintColor(UIColor.white)
                    iphoneImage?.setHidden(false)
                }
                else {
                    setInstructionLabelForMode(mainString: "Getting from iPhone.\nPlease ensure the iPhone is near the Watch and the app is open on it", readingString: "", writingString: "", isError: false)
                    iphoneImage?.setImage(UIImage(systemName: "iphone"))
                    iphoneImage?.setIsAccessibilityElement(true)
                    iphoneImage?.setAccessibilityLabel("iPhone")
                    iphoneImage?.setTintColor(UIColor.white)
                    iphoneImage?.setHidden(false)
                }
                var message : [String : Any] = [:]
                message["request_morse_code"] = true
                message["mode"] = mode
                // In your WatchKit extension, the value of this property is true when the paired iPhone is reachable via Bluetooth.
                session.sendMessage(message, replyHandler: nil, errorHandler: nil)
            }
            else {
                setInstructionLabelForMode(mainString: "Update from phone failed:\n\niPhone is not reachable", readingString: "", writingString: "", isError: true)
                iphoneImage?.setImage(UIImage(systemName: "iphone.slash"))
                iphoneImage?.setIsAccessibilityElement(true)
                iphoneImage?.setAccessibilityLabel("iPhone with slash")
                iphoneImage?.setTintColor(UIColor.red)
                iphoneImage?.setHidden(false)
                WKInterfaceDevice.current().play(.failure)
            }
        }
        else {
            setInstructionLabelForMode(mainString: "Update not possible", readingString: "", writingString: "", isError: true)
            WKInterfaceDevice.current().play(.failure)
        }
    }
    
    //Original minDuration = 0.5
    @IBAction func longPress(_ sender: WKLongPressGestureRecognizer) {
        if sender.state == .ended {
            sendAnalytics(eventName: "se3_watch_long_press", parameters: [:])
            if isAutoPlayOn == true {
                WKInterfaceDevice.current().play(.success) //A haptic to indicate that the long press has been registered
                stopAutoPlay()
                return
            }
            if isUserTyping == false {
                morseCodeAutoPlay(direction: "down")
                return
            }
            morseCodeInput(input: "-") //Shorten minDuration for morse code typing
        }
        
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
        let params = [
            "type" : "morse_code"
        ]
        pushController(withName: "Dictionary", context: params)
    }
    
    
    @IBAction func tappedTalkType() {
        sendAnalytics(eventName: "se3_watch_talktype_tap", parameters: [:])
        openTalkTypeMode()
    }
    
    
    @IBAction func tappedSettingsDeafBlind() {
        sendAnalytics(eventName: "se3_watch_settings_db_tap", parameters: [:])
        pushController(withName: "SettingsDeafBlind", context: self)
    }
    
    @IBAction func tappedActionsDictionary() {
        sendAnalytics(eventName: "se3_watch_actions_tap", parameters: [:])
        let params = [
            "type" : "actions"
        ]
        pushController(withName: "Dictionary", context: params)
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        WKInterfaceDevice.current().play(.success) //successfully launched app
        let dictionary = context as? NSDictionary
        if dictionary != nil {
            mode = dictionary!["mode"] as? String
        }
        instructionsLabel.setText(mode == "chat" ? f2fInstructions : defaultInstructions)
        if alphabetToMcDictionary.count < 1 {
            //let morseCode : MorseCode = MorseCode(type: mode ?? "actions", operatingSystem: "watchOS")
            morseCode = MorseCode(operatingSystem: "watchOS")
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
        
        //UserDefaults.standard.removeObject(forKey: "SE3_WATCHOS_USER_TYPE")
      /*  let se3UserType = UserDefaults.standard.string(forKey: "SE3_WATCHOS_USER_TYPE")
        if se3UserType == nil {
            pushController(withName: "SettingsDeafBlind", context: self)
        }
        else {
            if se3UserType == "_2" {
                defaultInstructions = deafBlindInstructions
            }
            if se3UserType == "_1" {
                defaultInstructions = notDeafBlindInstructions
            }
            instructionsLabel.setText(defaultInstructions)
        }   */
        
        if mode == "chat" {
            mainImage.setHidden(true)
            if let talkTypeImage = UIImage(systemName: "pencil") {
                addMenuItem(with: talkTypeImage, title: "Talk/Type", action: #selector(tappedTalkType))
            }
            if let bookImage = UIImage(systemName: "book.fill") {
                addMenuItem(with: bookImage, title: "Morse Code Dictionary", action: #selector(tappedDictionary))
            }
        }
        else {
            //mainImage.setHidden(false)
            //addMenuItem(with: WKMenuItemIcon.info, title: "Actions", action: #selector(tappedActionsDictionary))
        }
        
        if mode != nil {
            if mode == Action.GET_IOS.rawValue || mode == Action.CAMERA_OCR.rawValue {
                //these modes get data from connected iOS device
                downSwipe(1) //just a dummy parameter
            }
            else if mode == Action.MANUAL.rawValue
                        || mode == Action.BATTERY_LEVEL.rawValue {
                
                if mode == Action.BATTERY_LEVEL.rawValue {
                    if let siriShortcut = SiriShortcut.shortcutsDictionary[Action.BATTERY_LEVEL] {
                        SiriShortcut.createINShortcutAndAddToSiriWatchFace(siriShortcut: siriShortcut) //Return value is used for Add To Siri button on iOS. Does not apply here for now
                        //(WKExtension.shared().delegate as? ExtensionDelegate)?.setRelevantShortcuts(newShortcuts: relevantShortcuts)
                    }
                }
                self.englishString = dictionary!["alphanumeric"] as? String ?? ""
                self.englishTextLabel.setText(self.englishString)
                self.englishTextLabel.setHidden(false)
                for char in englishString {
                    let charAsString : String = String(char)
                    if let morseCode = self.alphabetToMcDictionary[charAsString] {
                        self.morseCodeString += morseCode
                    }
                    else if char.isWholeNumber {
                        self.morseCodeString += LibraryCustomActions.getIntegerInDotsAndDashes(integer: char.wholeNumberValue ?? 0)
                    }
                    self.morseCodeString += "|"
                }
                self.morseCodeTextLabel.setText(self.morseCodeString)
                self.morseCodeTextLabel.setHidden(false)
                isUserTyping = false
                self.defaultInstructions = dcScrollStart
                self.instructionsLabel.setText(self.defaultInstructions)
                morseCodeAutoPlay(direction: "down")
            }
            else {
                //Only applies if it is TIME or DATE for now
                upSwipe(1) //just a dummy parameter
            }
        }
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user.
        //It is also triggered when the user has typed or said text. After that message is composed, this controller is called again
        super.willActivate()
        WKInterfaceDevice.current().play(.success) //This is used to notify a deaf-blind user that the app is active
        self.crownSequencer.delegate = self
        self.crownSequencer.focus()
        self.instructionsLabel?.setTextColor(UIColor.gray)
        isScreenActive = true
        
        //Incase the user lowers his/her wrist and lifts it again
        //Then the screen will go OFF and ON
        if (mode == Action.GET_IOS.rawValue || mode == Action.CAMERA_OCR.rawValue)
            && englishString.isEmpty == true
            && morseCodeString.isEmpty == true {
            downSwipe(1)
        }
    }
    
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        isScreenActive = false
        //morseCode.destroyTree()
    }
}

extension MCInterfaceController : AVSpeechSynthesizerDelegate {
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        var finalString = ""
        if isUserTyping == true {
            finalString.append("Force press to see reply options")
            //if typingSuggestions.count > 0 {
                //finalString += " or typing"
            //}
            instructionsLabel.setText(finalString)
        }
        else {
            setInstructionLabelForMode(mainString: dcScrollStart, readingString: stopReadingString, writingString: keepTypingString, isError: false)
        }
        
        WKInterfaceDevice.current().play(.success)
        synth = nil
        englishTextLabel?.setTextColor(.none)
        morseCodeTextLabel?.setHidden(false)
        changeEnteredTextSize(inputString: englishString, textSize: 16)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        var finalString = ""
        if isUserTyping == true {
            finalString.append("Rotate the digital crown upwards quickly to reply by talking")
            if typingSuggestions.count > 0 {
                finalString += " or typing"
            }
            instructionsLabel.setText(finalString)
        }
        else {
            setInstructionLabelForMode(mainString: dcScrollStart, readingString: stopReadingString, writingString: keepTypingString, isError: false)
        }
        
        WKInterfaceDevice.current().play(.failure)
        synth = nil
        englishTextLabel?.setTextColor(.none)
        morseCodeTextLabel?.setHidden(false)
        changeEnteredTextSize(inputString: englishString, textSize: 16)
    }
}

extension MCInterfaceController : WKCrownDelegate {
    
    func crownDidRotate(_ crownSequencer: WKCrownSequencer?, rotationalDelta: Double) {
        crownRotationalDelta  += rotationalDelta
        
        if crownRotationalDelta < -expectedMoveDelta {
            //downward scroll
            crownRotationalDelta = 0.0
            if isAutoPlayOn == true {
                return
            }
            morseCodeStringIndex += 1
            let endTime = DispatchTime.now()
            let diffNanos = endTime.uptimeNanoseconds - startTimeNanos
            if diffNanos <= quickScrollTimeThreshold {
                sendAnalytics(eventName: "se3_watch_autoplay", parameters: [:])
                WKInterfaceDevice.current().play(.success)
                morseCodeAutoPlay(direction: "down")
                startTimeNanos = 0
            }
            else {
                startTimeNanos = DispatchTime.now().uptimeNanoseconds //Update this so we can do a check on the next rotation
                digitalCrownRotated(direction: "down")
            }
        }
        else if crownRotationalDelta > expectedMoveDelta {
            //upward scroll
            morseCodeStringIndex -= 1
            crownRotationalDelta = 0.0
            if isAutoPlayOn == true {
                WKInterfaceDevice.current().play(.success)
                stopAutoPlay()
                return
            }
            else {
                digitalCrownRotated(direction: "up")
            }
        }
    }
    
}

///Private Helpers
extension MCInterfaceController {
    
    func sessionReachabilityDidChange() {
        if englishString.isEmpty == false && morseCodeString.isEmpty == false {
            //Means we have already received the input
            return
        }
        if mode == Action.GET_IOS.rawValue || mode == Action.CAMERA_OCR.rawValue {
            //these modes get data from connected iOS device
            //refresh the screen
            downSwipe(1) //just a dummy parameter
        }
    }
    
    //Only used for TIME, DATE, Maths
    func updateMorseCodeForActions() {
        morseCodeString = ""
        for character in englishString {
            morseCodeString += morseCode.alphabetToMCDictionary[String(character)] ?? ""
            morseCodeString += "|"
        }
        morseCodeTextLabel.setText(morseCodeString)
        morseCodeStringIndex = -1
        isUserTyping = false
        setInstructionLabelForMode(mainString: dcScrollStart, readingString: stopReadingString, writingString: keepTypingString, isError: false)
        WKInterfaceDevice.current().play(.success)
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
            //WKInterfaceDevice.current().play(.stop) //2 taps
            WKInterfaceDevice.current().play(.retry) //single longer haptic
        }
        if char == "|" {
            WKInterfaceDevice.current().play(.success)
        }
    }

    //This function tells us if the previous char was a pipe or space.
    //Pipe = manual reading
    //Space = Autoplay. We do not play pipes in autoplay
    //It is a sign to change the character in the English string
    func isPrevMCCharPipeOrSpace(input : String, currentIndex : Int, isReverse : Bool) -> Bool {
        var retVal = false
        var isCurAlphanumericZero = false //A zero does not have have a dot/dash. Pipe followed by pipe or space followed by space
        if isReverse {
            if currentIndex < input.count - 1 {
                //To ensure the next character down exists
                let index = morseCodeString.index(morseCodeString.startIndex, offsetBy: morseCodeStringIndex)
                let char = String(morseCodeString[index])
                let prevIndex = morseCodeString.index(morseCodeString.startIndex, offsetBy: morseCodeStringIndex + 1)
                let prevChar = String(morseCodeString[prevIndex])
                retVal = (char != "|" && prevChar == "|") || (char != " " && prevChar == " ")
                isCurAlphanumericZero = (char == "|" && prevChar == "|") || (char == " " && prevChar == " ")
            }
        }
        else if currentIndex > 0 {
            //To ensure the previous character exists
            let index = morseCodeString.index(morseCodeString.startIndex, offsetBy: morseCodeStringIndex)
            let char = String(morseCodeString[index])
            let prevIndex = morseCodeString.index(morseCodeString.startIndex, offsetBy: morseCodeStringIndex - 1)
            let prevChar = String(morseCodeString[prevIndex])
            retVal = (char != "|" && prevChar == "|") || (char != " " && prevChar == " ")
            
            isCurAlphanumericZero = (char == "|" && prevChar == "|") || (char == " " && prevChar == " ")
        }
        
        return retVal || isCurAlphanumericZero
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
            if mode == "chat" && morseCode.mcTreeNode?.alphabet != nil {
                recommendations += "Swipe up to set: " + morseCode.mcTreeNode!.alphabet! + "\n"
            }
            else if morseCode.mcTreeNode?.action != nil {
                recommendations += "Swipe up to get: " + morseCode.mcTreeNode!.action! + "\n"
            }
        }
        let nextCharMatches = mode == "chat" ? morseCode.getNextCharMatches(currentNode: morseCode.mcTreeNode) : morseCode.getNextActionMatches(currentNode: morseCode.mcTreeNode)
        for nextMatch in nextCharMatches {
            recommendations += "\n" + nextMatch
        }
        instructionsString.insert(contentsOf: recommendations + "\n", at: instructionsString.startIndex)
            
        
        
        if isNoMoreMatchesAfterThis() == true {
            //The haptic for dot/dash will be played so no failure haptic
            //Only want to display the message that there are no more matches
            instructionsString.insert(contentsOf: noMoreMatchesString + "\n", at: instructionsString.startIndex)
        }
        
        //instructionsString += "\n" + "Swipe left to delete last character"
        instructionsLabel.setText(instructionsString)
        self.instructionsLabel.setTextColor(UIColor.gray)
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
    func setInstructionLabelForMode(mainString: String, readingString: String, writingString: String, isError: Bool?) {
        let instructionString = mainString
        if !isUserTyping && readingString.isEmpty == false {
            //instructionString += "\nOr\n" + readingString
        }
        else if writingString.isEmpty == false {
            //instructionString += "\nOr\n" + writingString
        }
        self.instructionsLabel.setText(instructionString)
        self.instructionsLabel.setTextColor(isError == true ? UIColor.red : UIColor.gray)
    }
    
    func morseCodeInput(input : String) {
        if isAutoPlayOn == true {
            //A tap does not interrupt autoplay
            return
        }
        if isReading() == true {
            //We do not want the user to accidently delete all the text by tapping
            synth = AVSpeechSynthesizer.init()
            synth?.delegate = self
            let speechUtterance: AVSpeechUtterance = AVSpeechUtterance(string: englishString)
            synth?.speak(speechUtterance)
            //instructionsLabel.setText("System is speaking the text...")
            instructionsLabel.setText("")
            morseCodeTextLabel?.setHidden(true)
            changeEnteredTextSize(inputString: englishString, textSize: 40)
            return
        }
        if mode == Action.GET_IOS.rawValue || mode == Action.CAMERA_OCR.rawValue {
            //Get from iPhone mode
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
        mainImage.setHidden(true)
        morseCodeTextLabel.setText(morseCodeString)
        englishTextLabel.setText(englishString) //This is to ensure that no characters are highlighted
        if input == "." {
            WKInterfaceDevice.current().play(.start)
        }
        else if input == "-" {
            WKInterfaceDevice.current().play(.retry) //single longer haptic
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
    
    func receivedMessageFromPhone(message : [String : Any]) {
        if (message["mode"] as? String) != mode {
            //The modes on watch and iOS must be the same. eg: INPUT FROM CAMERA
            return
        }
        if message["english"] != nil && message["morse_code"] != nil {
            let english = message["english"] as? String
            let morseCode = message["morse_code"] as? String
            if english?.isEmpty == true || morseCode?.isEmpty == true {
                WKInterfaceDevice.current().play(.failure)
                setInstructionLabelForMode(mainString: "Update from phone failed.\n\nNo content was received", readingString: "", writingString: "", isError: true)
                instructionsLabel?.setTextColor(.red)
                iphoneImage?.setHidden(true)
                return
            }
            isNormalMorse = message["is_normal_morse"] as? Bool
            englishString = english!
            morseCodeString = morseCode!
            englishTextLabel?.setText(englishString)
            morseCodeTextLabel?.setText(morseCodeString)
            englishTextLabel?.setHidden(false)
            morseCodeTextLabel?.setHidden(false)
            englishStringIndex = -1
            morseCodeStringIndex = -1
            isUserTyping = false
            mainImage?.setHidden(true)
            iphoneImage?.setHidden(true)
            setInstructionLabelForMode(mainString: dcScrollStart, readingString: stopReadingString, writingString: keepTypingString, isError: false)
            WKInterfaceDevice.current().play(.success)
        }
        else {
            WKInterfaceDevice.current().play(.failure)
            setInstructionLabelForMode(mainString: "Update from phone failed.\n\nNothing was received", readingString: "", writingString: "", isError: true)
            instructionsLabel?.setTextColor(.red)
            iphoneImage?.setHidden(true)
        }
    }
    
    @objc func autoPlay(timer : Timer) {
        let dictionary : Dictionary = timer.userInfo as! Dictionary<String,String>
        let direction : String = dictionary["direction"] ?? ""
        if self.isScreenActive == true {
            //In case the watch screen goes off, we pause
            //Resume when the user turns the watch screen ON again
            if direction.isEmpty == false {
                digitalCrownRotated(direction: direction)
                morseCodeStringIndex = direction == "down" ? morseCodeStringIndex + 1 : morseCodeStringIndex - 1
            }
        }

        if (direction == "down" && morseCodeStringIndex >= morseCodeString.count)
            || (direction == "up" && morseCodeStringIndex < 0) {
            stopAutoPlay()
        }
    }
    
    func stopAutoPlay() {
        autoPlayTimer?.invalidate()
        englishString = englishString.replacingOccurrences(of: "␣", with: " ")
        morseCodeString = morseCodeString.replacingOccurrences(of: " ", with: "|") //Autoplay complete, restore pipes
        englishTextLabel.setText(englishString)
        morseCodeTextLabel.setText(morseCodeString)
        englishStringIndex = -1 //Ensuring the pointer is set correctly
        morseCodeStringIndex = -1
                    //self.setInstructionLabelForMode(mainString: self.dcScrollStart, readingString: self.stopReadingString, writingString: self.keepTypingString, isError: false)
                    instructionsLabel?.setText(dcScrollStart)
                    resetBigText()
                    //aboutButton?.setHidden(mode == "TIME" || mode == "DATE" ? false : true)
        isAutoPlayOn = false
    }
    
    func morseCodeAutoPlay(direction : String) {
        isAutoPlayOn = true
        englishTextLabel.setText(englishString) //Resetting the string colors at the start of autoplay
        morseCodeString = morseCodeString.replacingOccurrences(of: "|", with: " ") //We will not be playing pipes in autoplay
        morseCodeTextLabel.setText(morseCodeString)
        instructionsLabel?.setText(direction == "down" ? "Autoplaying vibrations. Rotate digital crown upwards to stop" :
                                    "Resetting, please wait...")
        if mode == "TIME" || mode == "DATE" {
            //It means About button is visible
            aboutButton?.setHidden(true)
        }
        
        let dictionary = [
            "direction" : direction
        ]
        englishStringIndex = direction == "down" ? -1 : englishString.count //If the fast rotation happens in the middle of a reading, reset the indexes for autoplay
        morseCodeStringIndex = direction == "down" ? 0 : morseCodeString.count - 1
        let timeInterval = direction == "down" ? 1 : 0.5
        autoPlayTimer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(MCInterfaceController.autoPlay(timer:)), userInfo: dictionary, repeats: true)
    /*    Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if self.isScreenActive == true {
                //In case the watch screen goes off, we pause
                //Resume when the user turns the watch screen ON again
                self.digitalCrownRotated(direction: "down")
                self.morseCodeStringIndex += 1
            }

            if self.morseCodeStringIndex > self.morseCodeString.count || self.isAutoPlayOn == false {
                timer.invalidate()
                self.isAutoPlayOn = false
                self.morseCodeString = self.morseCodeString.replacingOccurrences(of: " ", with: "|") //Autoplay complete, restore pipes
                self.englishTextLabel.setText(self.englishString)
                self.morseCodeTextLabel.setText(self.morseCodeString)
                self.morseCodeStringIndex = -1
                self.englishStringIndex = -1
                //self.setInstructionLabelForMode(mainString: self.dcScrollStart, readingString: self.stopReadingString, writingString: self.keepTypingString, isError: false)
                self.instructionsLabel?.setText(self.stopReadingString)
            }
        }   */
    }
    
    func digitalCrownRotated(direction : String) {
        if morseCodeString.isEmpty {
            WKInterfaceDevice.current().play(.failure)
            morseCodeStringIndex = -1
            return
        }
        if direction == "down" {
            if morseCodeStringIndex >= morseCodeString.count {
                sendAnalytics(eventName: "se3_watch_scroll_down", parameters: [
                    "state" : "index_greater_equal_0",
                    "is_reading" : self.isReading()
                ])
                morseCodeTextLabel.setText(morseCodeString) //If there is still anything highlighted green, remove the highlight and return everything to default color
                englishTextLabel.setText(englishString)
                WKInterfaceDevice.current().play(.success)
                //setInstructionLabelForMode(mainString: "Rotate the crown upwards to scroll back", readingString: stopReadingString, writingString: keepTypingString, isError: false)
                instructionsLabel?.setText(dcScrollReverse)
                resetBigText()
                morseCodeStringIndex = morseCodeString.count //If the index has overshot the string length by some distance, bring it back to string length
                englishStringIndex = englishString.count
                return
            }
            
            sendAnalytics(eventName: "se3_watch_scroll_down", parameters: [
                "state" : "scrolling",
                "isReading" : self.isReading()
            ])
            if isAutoPlayOn == false {
                setInstructionLabelForMode(mainString: "Scroll to the end to read all the characters.\nScroll fast for autoplay", readingString: stopReadingString, writingString: keepTypingString, isError: false)
            }
            setSelectedCharInLabel(inputString: morseCodeString, index: morseCodeStringIndex, label: morseCodeTextLabel, isMorseCode: true, color: UIColor.green)
            playSelectedCharacterHaptic(inputString: morseCodeString, inputIndex: morseCodeStringIndex)
            
            if isPrevMCCharPipeOrSpace(input: morseCodeString, currentIndex: morseCodeStringIndex, isReverse: false) || englishStringIndex == -1 {
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
                if (mode != "TIME" && mode != "DATE") || isNormalMorse == true {
                    //Its morse code, not a custom pattern. So we want to highlight alphanumerics
                    setSelectedCharInLabel(inputString: englishString, index: englishStringIndex, label: englishTextLabel, isMorseCode: false, color : UIColor.green)
                }
            }
            animateMiddleText(text: morseCodeStringIndex < explanationArray.count ? explanationArray[morseCodeStringIndex] : nil)
            
        }
        else if direction == "up" {
            if morseCodeStringIndex < 0 {
                sendAnalytics(eventName: "se3_watch_scroll_up", parameters: [
                    "state" : "index_less_0",
                    "is_reading" : self.isReading()
                ])
                WKInterfaceDevice.current().play(.failure)
                setInstructionLabelForMode(mainString: dcScrollStart, readingString: stopReadingString, writingString: keepTypingString, isError: false)
                morseCodeTextLabel.setText(morseCodeString) //If there is still anything highlighted green, remove the highlight and return everything to default color
                morseCodeStringIndex = -1 //If the index has gone behind the string by some distance, bring it back to -1
                englishStringIndex = -1
                englishTextLabel.setText(englishString)
                resetBigText()
                return
            }
            
            sendAnalytics(eventName: "se3_watch_scroll_up", parameters: [
                "state" : "scrolling",
                "is_reading" : self.isReading()
            ])
            setSelectedCharInLabel(inputString: morseCodeString, index: morseCodeStringIndex, label: morseCodeTextLabel, isMorseCode: true, color : UIColor.green)
            resetBigText()
            if isAutoPlayOn == false {
                //This means we are doing a manual scroll
                playSelectedCharacterHaptic(inputString: morseCodeString, inputIndex: morseCodeStringIndex)
            }
            else {
                //We just want a short tap every time we are passing a character
                WKInterfaceDevice.current().play(.start)
            }
            
            if mode == "TIME" || mode == "DATE" {
                //Custom pattern used, not morse code. So we not want to highlight alphanumerics
                return
            }
            
            if isPrevMCCharPipeOrSpace(input: morseCodeString, currentIndex: morseCodeStringIndex, isReverse: true) {
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
    
    private func animateMiddleText(text: String?) {
        var localText : String? = text
        if localText == nil {
            //First check if it is a number
            let currentAlphanumericChar = englishString[englishString.index(englishString.startIndex, offsetBy:  englishStringIndex >= 0 ? englishStringIndex : 0)]
            if currentAlphanumericChar.isWholeNumber == true {
                localText = LibraryCustomActions.getInfoTextForWholeNumber(morseCodeString: morseCodeString, morseCodeStringIndex: morseCodeStringIndex, currentAlphanumericChar: String(currentAlphanumericChar))
            }
            else {
                //We are assuming its morse code
                localText = LibraryCustomActions.getInfoTextForMorseCode(morseCodeString: morseCodeString, morseCodeStringIndex: morseCodeStringIndex)
            }
            
        }
        
        if localText == nil {
            //If we are in the middle of playing a morse code character, we do not want to change the label
            return
        }
        if morseCodeStringIndex % 2 == 0 {
            self.bigTextLabel.setText(localText)
            self.bigTextLabel2.setText("")
            animate(withDuration: 1.0, animations: {
                self.bigTextLabel.setAlpha(1.0)
                self.bigTextLabel2.setAlpha(0.0)
            })
        }
        else {
            self.bigTextLabel.setText("")
            self.bigTextLabel2.setText(localText)
            animate(withDuration: 1.0, animations: {
                self.bigTextLabel.setAlpha(0.0)
                self.bigTextLabel2.setAlpha(1.0)
            })
        }
    }
    
    func resetBigText() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            //We give it 1.1 seconds to give time for the final character to animate. If we do it before 1 second, that last animation does not happen
            self.bigTextLabel.setText("")
            self.bigTextLabel.setAlpha(0.0)
            self.bigTextLabel2.setText("")
            self.bigTextLabel2.setAlpha(0.0)
        }
    }
}

///Protocol
protocol MCInterfaceControllerProtocol {
    func settingDeafBlindChanged(se3UserType: String)
}

extension MCInterfaceController : MCInterfaceControllerProtocol {
    func settingDeafBlindChanged(se3UserType: String) {
        if se3UserType == "_2" {
            sendAnalytics(eventName: "se3_watch_settings_change", parameters: [
                "is_deaf_blind": true
            ])
            defaultInstructions = f2fInstructions
        }
        else if se3UserType == "_1" {
            sendAnalytics(eventName: "se3_watch_settings_change", parameters: [
                "is_deaf_blind": false
            ])
            defaultInstructions = notDeafBlindInstructions
        }
        instructionsLabel.setText(defaultInstructions)
    }
}

