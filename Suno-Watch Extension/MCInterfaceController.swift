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
    var mcTypingInstructions = "Rotate digital crown:\n\nDown to type a dot.\nDown quickly to type a dash.\nUpwards to delete last character."
    var notDeafBlindInstructions = "Force press for reply options"
    var dcScrollStart = "Rotate the digital crown down to feel each character"
    var dcScrollReverse = "Ratate the digital crown up to scroll back"
    var stopReadingString = "Swipe left once to stop reading and type morse code"
    var keepTypingString = "Keep typing"
    var noMoreMatchesString = "No more matches found for this morse code"
    var typingSuggestions : [String ] = ["HI", "YES", "NO"]
    var isUserTyping : Bool = false
    var brailleString : String = ""
    var alphanumericString : String = ""
    var explanationArray : [String] = []
    var alphabetToMcDictionary : [String : String] = [:]
    //var arrayBrailleGridsForCharsInWord : [BrailleCell] = []
    //var arrayBrailleGridsForCharsInWordIndex = -1
    //var alphanumericHighlightStartIndex = -1 //Cannot use braille grids array index as thats not a 1-1 relation
    //var arrayWordsInString : [String] = []
    //var arrayWordsInStringIndex = -1
    var englishStringIndex = -1
    //var mIndex = -1
    //var brailleStringIndex = -1
    var braille = Braille()
    let expectedMoveDelta = 0.523599 //Here, current delta value = 30° Degree, Set delta value according requirement.
    var crownRotationalDelta = 0.0
    var morseCode = MorseCode()
    var synth : AVSpeechSynthesizer?
    var mode : String?
    var isAutoPlayOn : Bool = false
    var isBrailleSwitchedToHorizontal = false
    var startTimeNanos : UInt64 = 0 //Used to calculate speed of crown rotation
    var isScreenActive = true
    var quickScrollTimeThreshold = 700000000 //If the digital crown is scrolled 30 degrees within this many nano seconds, we go into autoplay
    var isNormalMorse : Bool? = nil //Some functions, like TIME and DATE, can use customized vibrations and not normal morse code
    var isFromSiri = false
    var autoPlayTimer : Timer? = nil
    var TIME_DIFF_MILLIS : Double = 1000
    
    @IBOutlet weak var mainImage: WKInterfaceImage! //The default 'home' image of the application
    @IBOutlet weak var englishTextLabel: WKInterfaceLabel!
    @IBOutlet weak var morseCodeTextLabel: WKInterfaceLabel!
    @IBOutlet weak var previousCharacterButton: WKInterfaceButton!
    @IBOutlet weak var playPauseButton: WKInterfaceButton!
    @IBOutlet weak var playPauseImage: WKInterfaceImage!
    @IBOutlet weak var nextCharacterButton: WKInterfaceButton!
    @IBOutlet weak var resetButton: WKInterfaceButton!
    @IBOutlet weak var timeSettingsButton: WKInterfaceButton!
    @IBOutlet weak var instructionsLabel: WKInterfaceLabel!
    @IBOutlet weak var iphoneImage: WKInterfaceImage!
    @IBOutlet weak var bigTextLabel: WKInterfaceLabel!
    @IBOutlet weak var bigTextLabel2: WKInterfaceLabel!
    @IBOutlet weak var switchBrailleDirectionButton: WKInterfaceButton!
    @IBOutlet weak var fullTextButton: WKInterfaceButton!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        WKInterfaceDevice.current().play(.success) //successfully launched app
        let dictionary = context as? NSDictionary
        if dictionary != nil {
            mode = dictionary!["mode"] as? String
            if dictionary!["is_from_siri"] != nil {
                isFromSiri = (dictionary!["is_from_siri"] as? Bool) ?? true
            }
        }
        
        if isFromSiri == true && mode == Action.CAMERA_OCR.rawValue {
            presentAlert(withTitle: "Sorry", message: "This shortcut is not currently supported", preferredStyle: .alert, actions: [
              WKAlertAction(title: "OK", style: .default) {}
              ])
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
        
        if mode == Action.MC_TYPING.rawValue {
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
        
        //This is needed in multiple modes
        //eg: MANUAL, MC_TYPING
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
        
        if mode != nil {
            if mode == Action.GET_IOS.rawValue || mode == Action.CAMERA_OCR.rawValue {
                //these modes get data from connected iOS device
                downSwipe(1) //just a dummy parameter
            }
            else if mode == Action.MANUAL.rawValue {
                self.alphanumericString = dictionary!["alphanumeric"] as? String ?? ""
            /*    for char in englishString {
                    let charAsString : String = String(char)
                    if let morseCode = self.alphabetToMcDictionary[charAsString] {
                        self.morseCodeString += morseCode
                    }
                    else if char.isWholeNumber {
                        self.morseCodeString += LibraryCustomActions.getIntegerInDotsAndDashes(integer: char.wholeNumberValue ?? 0)
                    }
                    self.morseCodeString += "|"
                }   */
                braille.setupArraysUsingInputString(fullAlphanumeric: alphanumericString)
                alphanumericString = braille.arrayWordsInString.first ?? ""
                self.englishTextLabel.setText(alphanumericString)
                self.englishTextLabel.setHidden(false)
                brailleString = braille.arrayBrailleGridsForCharsInWord.first?.brailleDots ?? ""
                self.morseCodeTextLabel.setText(self.brailleString)
                self.morseCodeTextLabel.setHidden(false)
                isUserTyping = false
                self.defaultInstructions = dcScrollStart
                self.instructionsLabel.setText(self.defaultInstructions)
                self.switchBrailleDirectionButton.setTitle(isBrailleSwitchedToHorizontal == false ? "Read Sideways" : "Read up down")
                self.fullTextButton.setHidden(false)
                self.resetButton.setHidden(true)
                //playPauseButtonTapped()
            }
            else if mode == Action.MC_TYPING.rawValue {
                isUserTyping = true
                defaultInstructions = mcTypingInstructions
                instructionsLabel.setText(defaultInstructions)
            }
            else {
                //Only applies if it is TIME or DATE for now
                upSwipe(1) //just a dummy parameter
            }
        }
    }
    
    
    @IBAction func timeSettingsButtonTapped() {
        let params : [String: Any] = [:]
        pushController(withName: "ValuePlusMinusInterfaceController", context: params)
    }
    
    
    @IBAction func fullTextButtonTapped() {
     /*   var text = ""
        var startIndexForHighlighting = 0
        var endIndexForHighlighting = 0
        for word in arrayWordsInString {
            text += word
            text += " "
        }
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        for (index, element) in arrayWordsInString.enumerated() {
            if index < arrayWordsInStringIndex {
                startIndexForHighlighting += arrayWordsInString[index].count //Need to increment by length of  the word that was completed
                startIndexForHighlighting += 1 //account for space after the word
            }
        }
        startIndexForHighlighting += alphanumericHighlightStartIndex
        let exactWord = arrayBrailleGridsForCharsInWord[arrayBrailleGridsForCharsInWordIndex].english
        endIndexForHighlighting = startIndexForHighlighting + exactWord.count */
        var dictionary = braille.getStartAndEndIndexInFullStringOfHighlightedPortion()
        dictionary["braille"] = braille
     /*   let params : [String: Any] = [
            "text" : dictionary["text"] as! String,
            "start_index" : dictionary["start_index"] as! Int,
            "end_index" : dictionary["end_index"] as! Int,
        ]   */
        pushController(withName: "TextInterfaceController", context: dictionary)
    }
    
    @IBAction func switchBrailleDirectionButtonTapped() {
        isBrailleSwitchedToHorizontal = !isBrailleSwitchedToHorizontal
        self.switchBrailleDirectionButton.setTitle(isBrailleSwitchedToHorizontal == false ? "Read Sideways" : "Read up down")
    }
    
    
    @IBAction func previousCharacterButtonTapped() {
        braille.mIndex -= 1
        let brailleStringIndex = braille.getNextIndexForBrailleTraversal(brailleStringLength: brailleString.count, currentIndex: braille.mIndex, isDirectionHorizontal: isBrailleSwitchedToHorizontal)
        if braille.isEndOfEntireStringReached(brailleString: brailleString, brailleStringIndex: brailleStringIndex) {
            //We are way  beyond the end
            //We are also checking Morse Code index becuase only braille index can be triggered when at the start of the grid also
            braille.doIfEndOfEntireStringReachedScrollingBack(textFromAlphanumericLabel: alphanumericString, textFromBrailleLabel: brailleString)
        }
        else if braille.isBeforeStartOfStringReached() {
            englishTextLabel.setText(alphanumericString) //remove highlights
            morseCodeTextLabel.setText(brailleString)
            resetButton?.setHidden(true)
            WKInterfaceDevice.current().play(.success)
            return
        }
        else if braille.isStartOfWordReached() {
            //end of word. move to previous word
            let dictionary = braille.getPreviousWord()
            alphanumericString = dictionary["alphanumeric_string"] ?? ""
            englishTextLabel.setText(alphanumericString)
            brailleString = dictionary["braille_string"] ?? ""
            morseCodeTextLabel.setText(brailleString)
        }
        else if braille.mIndex <= -1 {
            //in the middle of a word. move to the previous character
            brailleString = braille.goToPreviousCharacterOrContraction()
            morseCodeTextLabel.setText(brailleString)
        }
        highlightContentAndPlayHaptic() //digitalCrownRotated(direction: "up")
    }
    
    
    @IBAction func playPauseButtonTapped() {
        isAutoPlayOn = !isAutoPlayOn
        if isAutoPlayOn == true {
            morseCodeAutoPlay(direction: "down")
        }
        else {
            pauseAutoPlay()
        }
        playPauseButtonTappedUIChange()
    }
    
    func playPauseButtonTappedUIChange() {
        if isAutoPlayOn == true {
            let image = UIImage(systemName: "pause.fill")
            playPauseImage?.setImage(image)
            playPauseButton?.setAccessibilityLabel("Pause Button")
            playPauseButton?.setAccessibilityLabel("Pause Button")
            previousCharacterButton?.setHidden(true)
            nextCharacterButton?.setHidden(true)
            resetButton?.setHidden(true)
            fullTextButton?.setHidden(true)
            switchBrailleDirectionButton?.setHidden(true)
            //timeSettingsButton?.setHidden(true)
        }
        else {
            let image = UIImage(systemName: "play.fill")
            playPauseImage?.setImage(image)
            playPauseButton?.setAccessibilityLabel("Play Button")
            playPauseButton?.setAccessibilityHint("Play Button")
            previousCharacterButton?.setHidden(false)
            nextCharacterButton?.setHidden(false)
            resetButton?.setHidden(false)
            fullTextButton?.setHidden(false)
            //switchBrailleDirectionButton?.setHidden(false)
            //timeSettingsButton?.setHidden(false)
        }
    }
    
    
    @IBAction func nextCharacterButtonTapped() {
        braille.mIndex += 1
        let brailleStringIndex = braille.getNextIndexForBrailleTraversal(brailleStringLength: brailleString.count, currentIndex: braille.mIndex, isDirectionHorizontal: isBrailleSwitchedToHorizontal)
        if braille.isBeforeStartOfStringReached() {
            //we are at the beginning
            //assuming the right alphanumeric and right braille are already in place
            braille.doIfBeforeStartOfStringReachedScrollingForward()
        }
        else if braille.isEndOfEntireStringReached(brailleString: brailleString, brailleStringIndex: brailleStringIndex) {
            //end of word and end of string
            englishTextLabel.setText(alphanumericString) //remove highlights
            morseCodeTextLabel.setText(brailleString)
            WKInterfaceDevice.current().play(.success)
            if isAutoPlayOn {
                isAutoPlayOn = false
                pauseAutoPlayAndReset()
            }
            return
        }
        else if braille.isEndOfWordReached(brailleStringIndex: brailleStringIndex) {
            //end of word. move to next word
            if isAutoPlayOn {
                //Thread.sleep(forTimeInterval: Double(TIME_DIFF_MILLIS + (TIME_DIFF_MILLIS/4)))
                let timeInterval = Double((TIME_DIFF_MILLIS/4)/1000)
                Thread.sleep(forTimeInterval: timeInterval /*0.25*/)
            }
            let dictionary = braille.getNextWord()
            alphanumericString = dictionary["alphanumeric_text"] ?? ""
            englishTextLabel.setText(alphanumericString)
            brailleString = dictionary["braille_text"] ?? ""
            morseCodeTextLabel.setText(brailleString)
        }
        else if brailleStringIndex == -1 {
            brailleString = braille.goToNextCharacterOrContraction()
            morseCodeTextLabel.setText(brailleString)
        }
        highlightContentAndPlayHaptic() //digitalCrownRotated(direction: "down")
        resetButton?.setHidden(isAutoPlayOn == false ? false : true) //Not available during autoplay
    }
    
    
    @IBAction func resetButtonTapped() {
        isAutoPlayOn = false
        playPauseButtonTappedUIChange()
        pauseAutoPlayAndReset()
    }
    
    //Disabled in storyboard. Do not want to assign things to tap gesture. Accidental taps are possible
    @IBAction func tapGesture(_ sender: Any) {
        sendAnalytics(eventName: "se3_watch_tap", parameters: [:])
        morseCodeInput(input: ".")
    }
    
    @IBAction func doubleTapGesture(_ sender: Any) {
        upSwipe(1)
    }
    
    //Disabled in storyboard. Swipes gestures are tough in VoiceOver
    @IBAction func rightSwipe(_ sender: Any) {
        //sendAnalytics(eventName: "se3_watch_swipe_right", parameters: [:])
        //morseCodeInput(input: "-")
    }
    
    //Disabled in storyboard. Swipe gestures are tough in VoiceOver
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
        
        if mode == Action.MC_TYPING.rawValue && brailleString.count > 0 {
            if brailleString.last == "|" {
                
                let mathResult = performMathCalculation(inputString: alphanumericString) //NSExpression(format:englishString).expressionValue(with: nil, context: nil) as? Int //This wont work if the string also contains alphabets
                var isMath = false
                if mathResult != nil {
                    isMath = true
                    alphanumericString = String(mathResult!)
                    englishTextLabel?.setText(alphanumericString)
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
                let speechUtterance: AVSpeechUtterance = AVSpeechUtterance(string: alphanumericString)
                synth?.speak(speechUtterance)
                //instructionsLabel.setText("System is speaking the text...")
                instructionsLabel.setText("")
                morseCodeTextLabel?.setHidden(true)
                changeEnteredTextSize(inputString: alphanumericString, textSize: 40)
            }
            else if let letterOrNumber = morseCode.mcTreeNode?.alphabet {
                //first deal with space. Remove the visible space character and replace with an actual space to make it look more normal. Space character was just there for visual clarity
                sendAnalytics(eventName: "se3_watch_swipe_up", parameters: [
                    "state" : "mc_2_alphanumeric",
                    "text" : letterOrNumber
                ])
                if alphanumericString.last == "␣" {
                    alphanumericString.removeLast()
                    alphanumericString += " "
                }
                alphanumericString += letterOrNumber
                englishTextLabel.setText(alphanumericString)
                englishTextLabel.setHidden(false)
                brailleString += "|"
                morseCodeTextLabel.setText(brailleString)
                WKInterfaceDevice.current().play(.success) //successfully got a letter/number
                while morseCode.mcTreeNode?.parent != nil {
                    morseCode.mcTreeNode = morseCode.mcTreeNode!.parent
                }
                instructionsLabel.setText("Character " + letterOrNumber + " confirmed. You can continue typing. Rotate the digital crown down to continue typing.")
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
            let customInputs = action == Action.BATTERY_LEVEL.rawValue ?
                (WKExtension.shared().delegate as? ExtensionDelegate)?.getBatteryLevelCustomInputs() :
                SiriShortcut.getCustomInputs(action: Action(rawValue: action) ?? Action.UNKNOWN)
            alphanumericString = customInputs?[SiriShortcut.INPUT_FIELDS.input_alphanumerics.rawValue] as? String ?? ""
            englishTextLabel.setText(alphanumericString)
            englishTextLabel.setHidden(false)
            brailleString = customInputs?[SiriShortcut.INPUT_FIELDS.input_morse_code.rawValue] as? String ?? ""
            morseCodeTextLabel.setText(brailleString)
            explanationArray.append(contentsOf:  customInputs?[SiriShortcut.INPUT_FIELDS.input_mc_explanation.rawValue] as? [String] ?? []
            )
            if action == Action.TIME.rawValue
                || action == Action.DATE.rawValue
                || action == Action.BATTERY_LEVEL.rawValue {
                isUserTyping = false
                morseCodeAutoPlay(direction: "down") //If it does not have a dependency on iPhone, it can autoplay by default
            }
            else if action == "1-to-1" {
                while morseCode.mcTreeNode?.parent != nil {
                    //Reset the tree
                    morseCode.mcTreeNode = morseCode.mcTreeNode!.parent
                }
                mainImage.setHidden(false)
                alphanumericString = ""
                englishTextLabel.setText("")
                brailleString = ""
                morseCodeTextLabel.setText("")
                instructionsLabel.setText(defaultInstructions)
                let params = [
                    "mode" : Action.MC_TYPING.rawValue
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
    
    //Disabled in storyboard. Swipe gestures are tough in VoiceOver
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
            mainImage.setHidden(mode == Action.MC_TYPING.rawValue ? true : false)
            alphanumericString = ""
            englishTextLabel.setText("")
            brailleString = ""
            morseCodeTextLabel.setText("")
            instructionsLabel.setText(defaultInstructions)
            WKInterfaceDevice.current().play(.success)
            return
        }
        if mode == Action.GET_IOS.rawValue {
            //Get from iPhone mode
            return
        }
        if brailleString.count > 0 {
            if brailleString.last != "|" {
                //Should not be a character separator
                sendAnalytics(eventName: "se3_watch_swipe_left", parameters: [
                    "state" : "last_morse_code"
                ])
                brailleString.removeLast()
                morseCodeTextLabel.setText(brailleString)
                isAlphabetReached(input: "b") //backspace
                WKInterfaceDevice.current().play(.success)
            }
            else {
                //If it is a normal letter/number, delete the last english character and corresponding morse code characters
                sendAnalytics(eventName: "se3_watch_swipe_left", parameters: [
                    "state" : "last_alphanumeric"
                ])
                if let lastChar = alphanumericString.last {
                    if let lastCharMorseCodeLength = (morseCode.alphabetToMCDictionary[String(lastChar)])?.count {
                        brailleString.removeLast(lastCharMorseCodeLength + 1) //+1 to include both the morse code part and the ending pipe "|"
                        morseCodeTextLabel.setText(brailleString)
                    }
                }
                alphanumericString.removeLast()
                if alphanumericString.last == " " {
                    //If the last character is now is space, replace it with the carrat so that it can be seen
                    alphanumericString.removeLast()
                    alphanumericString.append("␣")
                }
                englishTextLabel.setText(alphanumericString)
                WKInterfaceDevice.current().play(.success)
                isAlphabetReached(input: "b") //backspace
            }
        }
        else {
            print("nothing to delete")
            sendAnalytics(eventName: "se3_watch_swipe_left", parameters: [
                "state" : "nothing_to_delete"
            ])
            WKInterfaceDevice.current().play(.failure)
        }
        
        if brailleString.count == 0 && alphanumericString.count == 0 {
            mainImage.setHidden(mode == Action.MC_TYPING.rawValue ? true : false)
            instructionsLabel.setText(defaultInstructions)
        }
    }
    
    //Disabled in storyboard. Swipe gestures are tough in VoiceOver
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
    //Disabled in storyboard. Can cause confusion between long press and force press. Long Press is also tough with VoiceOver
    @IBAction func longPress(_ sender: WKLongPressGestureRecognizer) {
        if sender.state == .ended {
            sendAnalytics(eventName: "se3_watch_long_press", parameters: [:])
            if isAutoPlayOn == true {
                WKInterfaceDevice.current().play(.success) //A haptic to indicate that the long press has been registered
                pauseAutoPlayAndReset()
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
            && alphanumericString.isEmpty == true
            && brailleString.isEmpty == true {
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
        if isUserTyping == true {
            if brailleString.last == "|",
               let lastAlphanumeric = alphanumericString.last {
                //This is assumingn speech can only be called when the last character is a pipe (|)
                instructionsLabel.setText("Character " + String(lastAlphanumeric) + " confirmed. You can continue typing. Rotate the digital crown down to continue typing.")
            }
        }
        else {
            setInstructionLabelForMode(mainString: dcScrollStart, readingString: stopReadingString, writingString: keepTypingString, isError: false)
        }
        
        WKInterfaceDevice.current().play(.success)
        synth = nil
        englishTextLabel?.setTextColor(.none)
        morseCodeTextLabel?.setHidden(false)
        changeEnteredTextSize(inputString: alphanumericString, textSize: 16)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        if isUserTyping == true {
            if brailleString.last == "|",
               let lastAlphanumeric = alphanumericString.last {
                //This is assumingn speech can only be called when the last character is a pipe (|)
                instructionsLabel.setText("Character " + String(lastAlphanumeric) + " confirmed. You can continue typing. Rotate the digital crown down to continue typing.")
            }
        }
        else {
            setInstructionLabelForMode(mainString: dcScrollStart, readingString: stopReadingString, writingString: keepTypingString, isError: false)
        }
        
        WKInterfaceDevice.current().play(.failure)
        synth = nil
        englishTextLabel?.setTextColor(.none)
        morseCodeTextLabel?.setHidden(false)
        changeEnteredTextSize(inputString: alphanumericString, textSize: 16)
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
            //mIndex += 1 //this is now done in nextCharacterButtonTapped
            let endTime = DispatchTime.now()
            let diffNanos = endTime.uptimeNanoseconds - startTimeNanos
            if diffNanos <= quickScrollTimeThreshold {
                if isUserTyping == false {
                    //We are in reading mode
                    sendAnalytics(eventName: "se3_watch_autoplay", parameters: [:])
                    WKInterfaceDevice.current().play(.success)
                    playPauseButtonTapped()
                    startTimeNanos = 0
                }
                else {
                    //We are in typing mode.
                    //This is a quick rotation
                    //Insert a dash (-)
                    if brailleString.last == "." {
                        //Dot was enntered on the first rotation.
                        //Need to delete the dot first
                        leftSwipe(1)
                    }
                    //Enter a dash(-)
                    morseCodeInput(input: "-") //dummy parameter. Need to send something
                }
            }
            else {
                startTimeNanos = DispatchTime.now().uptimeNanoseconds //Update this so we can do a check on the next rotation
                if isUserTyping == false {
                    nextCharacterButtonTapped()
                }
                else {
                    //A single scroll down means type a dot
                    tapGesture(1)
                }
            }
        }
        else if crownRotationalDelta > expectedMoveDelta {
            //upward scroll
            //mIndex -= 1 //this is now done in previousCharacterButtonTapped
            crownRotationalDelta = 0.0
            let endTime = DispatchTime.now()
            let diffNanos = endTime.uptimeNanoseconds - startTimeNanos
            
            if isUserTyping == true {
                //If we are in typing mode, an up swipe becomes a delete
                leftSwipe(1) //Dummy parameter
            }
            else if /*isAutoPlayOn == true ||*/ diffNanos <= quickScrollTimeThreshold { //a quick up scroll means reset
                WKInterfaceDevice.current().play(.success)
                pauseAutoPlayAndReset()
                return
            }
            else {
                startTimeNanos = DispatchTime.now().uptimeNanoseconds //Update this so we can do a check on the next rotation
                if isAutoPlayOn == true {
                    //Only pausing autoplay
                    autoPlayTimer?.invalidate()
                    playPauseButtonTapped()
                    setInstructionLabelForMode(mainString: "Scroll to the end to read all the characters.\nScroll fast for autoplay", readingString: stopReadingString, writingString: keepTypingString, isError: false)
                    //mIndex += 1 //This is the negate the decrement of index that happened above when upward scroll was detected. As that decrement will not be acted on below
                    return
                }
                //Autoplay is off, scroll to read last character
                previousCharacterButtonTapped()
            }   
        }
    }
    
}

///Private Helpers
extension MCInterfaceController {
    
    func sessionReachabilityDidChange() {
        if alphanumericString.isEmpty == false && brailleString.isEmpty == false {
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
        brailleString = ""
        for character in alphanumericString {
            brailleString += morseCode.alphabetToMCDictionary[String(character)] ?? ""
            brailleString += "|"
        }
        morseCodeTextLabel.setText(brailleString)
        braille.mIndex = -1
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
        brailleString = firstCharacter
        alphanumericString = ""
        englishTextLabel.setText(alphanumericString)
        isUserTyping = true
    }
    
    func playSelectedCharacterHaptic(inputString : String, inputIndex : Int) {
        let index = inputString.index(inputString.startIndex, offsetBy: inputIndex)
        let char = String(brailleString[index])
        if char == "." || char == "x" {
            WKInterfaceDevice.current().play(.start)
        }
        if char == "-" || char == "o" {
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
                let index = brailleString.index(brailleString.startIndex, offsetBy: braille.mIndex)
                let char = String(brailleString[index])
                let prevIndex = brailleString.index(brailleString.startIndex, offsetBy: braille.mIndex + 1)
                let prevChar = String(brailleString[prevIndex])
                retVal = (char != "|" && prevChar == "|") || (char != " " && prevChar == " ")
                isCurAlphanumericZero = (char == "|" && prevChar == "|") || (char == " " && prevChar == " ")
            }
        }
        else if currentIndex > 0 {
            //To ensure the previous character exists
            let index = brailleString.index(brailleString.startIndex, offsetBy: braille.mIndex)
            let char = String(brailleString[index])
            let prevIndex = brailleString.index(brailleString.startIndex, offsetBy: braille.mIndex - 1)
            let prevChar = String(brailleString[prevIndex])
            retVal = (char != "|" && prevChar == "|") || (char != " " && prevChar == " ")
            
            isCurAlphanumericZero = (char == "|" && prevChar == "|") || (char == " " && prevChar == " ")
        }
        
        return retVal || isCurAlphanumericZero
    }
    
    func isEngCharSpace() -> Bool {
        let index = alphanumericString.index(alphanumericString.startIndex, offsetBy: englishStringIndex)
        let char = String(alphanumericString[index])
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
    func setSelectedCharInLabel(inputString : String, index : Int, length: Int?, label : WKInterfaceLabel, isMorseCode : Bool, color : UIColor) {
        let range = NSRange(location:index,length: length != nil ? length! :  1) // specific location. This means "range" handle 1 character at location 2
        
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
        return !isUserTyping && brailleString.count > 0 && alphanumericString.count > 0
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
            if brailleString.last == "|",
               let lastAlphanumeric = alphanumericString.last {
                //Overwrite the instructions label. We do not wannt to show recommended characters if the last char was a pipe(|)
                instructionsLabel.setText("Character " + String(lastAlphanumeric) + " confirmed. You can continue typing. Rotate the digital crown down to continue typing.")
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
            if mode == Action.MC_TYPING.rawValue && morseCode.mcTreeNode?.alphabet != nil {
                recommendations += "Double tap screen to confirm: " + morseCode.mcTreeNode!.alphabet! + "\n"
            }
            else if morseCode.mcTreeNode?.action != nil {
                recommendations += "Double tap screen to confirm: " + morseCode.mcTreeNode!.action! + "\n"
            }
        }
        let nextCharMatches = mode == Action.MC_TYPING.rawValue ? morseCode.getNextCharMatches(currentNode: morseCode.mcTreeNode) : morseCode.getNextActionMatches(currentNode: morseCode.mcTreeNode)
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
            let speechUtterance: AVSpeechUtterance = AVSpeechUtterance(string: alphanumericString)
            synth?.speak(speechUtterance)
            //instructionsLabel.setText("System is speaking the text...")
            instructionsLabel.setText("")
            morseCodeTextLabel?.setHidden(true)
            changeEnteredTextSize(inputString: alphanumericString, textSize: 40)
            return
        }
        if mode == Action.GET_IOS.rawValue || mode == Action.CAMERA_OCR.rawValue {
            //Get from iPhone mode
            return
        }
        if isNoMoreMatchesAfterThis() == true {
            //Prevent the user from entering another character
            setSelectedCharInLabel(inputString: brailleString, index: brailleString.count - 1, length: 1, label: morseCodeTextLabel, isMorseCode: true, color: UIColor.red)
            setRecommendedActionsText()
            WKInterfaceDevice.current().play(.failure)
            return
        }
        englishStringIndex = -1
        braille.mIndex = -1
        if isUserTyping == false {
            userIsTyping(firstCharacter: input)
        }
        else {
            brailleString += input
        }
        isAlphabetReached(input: input)
        mainImage.setHidden(true)
        morseCodeTextLabel.setText(brailleString)
        englishTextLabel.setText(alphanumericString) //This is to ensure that no characters are highlighted
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
                self.braille.mIndex = -1
                self.englishStringIndex = -1
                while self.morseCode.mcTreeNode?.parent != nil {
                    self.morseCode.mcTreeNode = self.morseCode.mcTreeNode?.parent
                }
                
                answer = answer.uppercased().trimmingCharacters(in: .whitespacesAndNewlines).filter("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789: ".contains) //Remove anything that is not alphanumeric
                if answer.count < 1 {
                    return
                }
                self.alphanumericString = answer
                self.brailleString = ""
                self.englishTextLabel.setText(answer)
                self.englishTextLabel.setHidden(false)
                self.morseCodeTextLabel.setText("")
                for char in answer {
                    let charAsString : String = String(char)
                    if let morseCode = self.alphabetToMcDictionary[charAsString] {
                        self.brailleString += morseCode
                    }
                    self.brailleString += "|"
                }
                //self.morseCodeString.removeLast() //Remove the last "|"
                self.morseCodeTextLabel.setText(self.brailleString)
                self.morseCodeTextLabel?.setHidden(true)
                self.instructionsLabel.setText("")
                self.changeEnteredTextSize(inputString: self.alphanumericString, textSize: 40)
                self.synth = AVSpeechSynthesizer.init()
                self.synth?.delegate = self
                let speechUtterance: AVSpeechUtterance = AVSpeechUtterance(string: self.alphanumericString)
                self.synth?.speak(speechUtterance)
            }
            
        })
    }
    
    func receivedMessageFromPhone(message : [String : Any]) {
     /*   if (message["mode"] as? String) != mode {
            //The modes on watch and iOS must be the same. eg: INPUT FROM CAMERA
            return
        }   */
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
            alphanumericString = english!
            brailleString = morseCode!
            englishTextLabel?.setText(alphanumericString)
            morseCodeTextLabel?.setText(brailleString)
            englishTextLabel?.setHidden(false)
            morseCodeTextLabel?.setHidden(false)
            englishStringIndex = -1
            braille.mIndex = -1
            isUserTyping = false
            mainImage?.setHidden(true)
            iphoneImage?.setHidden(true)
            setInstructionLabelForMode(mainString: dcScrollStart, readingString: stopReadingString, writingString: keepTypingString, isError: false)
            WKInterfaceDevice.current().play(.success)
        }
        else if message["is_autoplay_on"] != nil {
            let iPhoneAutoplay = message["is_autoplay_on"] as? Bool
            if iPhoneAutoplay == true {
                WKInterfaceDevice.current().play(.failure)
                setInstructionLabelForMode(mainString: "Autoplay is active on the iPhone app.\n\nTransfer is only possible when autoplay is not happening", readingString: "", writingString: "", isError: true)
                instructionsLabel?.setTextColor(.red)
                iphoneImage?.setHidden(true)
            }
        }
        else if message["array_words_in_string"] != nil
                && message["array_words_in_string_index"] != nil
                //&& message["array_braille_grids_for_chars_in_word"] != nil
                && message["array_braille_grids_for_chars_in_word_index"] != nil
                && message["alphanumeric_highlight_start_index"] != nil {
            braille.arrayWordsInString.removeAll()
            braille.arrayWordsInString = message["array_words_in_string"] as? [String] ?? []
            braille.arrayWordsInStringIndex = message["array_words_in_string_index"] as? Int ?? 0
            braille.mIndex = message["morse_code_string_index"] as? Int ?? 0
            braille.arrayBrailleGridsForCharsInWord.removeAll()
            //braille.arrayBrailleGridsForCharsInWord.append(contentsOf: message["array_braille_grids_for_chars_in_word"] as? [BrailleCell] ?? [])
            braille.arrayBrailleGridsForCharsInWordIndex = message["array_braille_grids_for_chars_in_word_index"] as? Int ?? 0
            braille.alphanumericHighlightStartIndex =  message["alphanumeric_highlight_start_index"] as? Int ?? 0
            alphanumericString = braille.arrayWordsInString[braille.arrayWordsInStringIndex]
            englishTextLabel.setText(alphanumericString)
            englishTextLabel.setHidden(false)
            braille.arrayBrailleGridsForCharsInWord.append(contentsOf: braille.convertAlphanumericToBrailleWithContractions(alphanumericString: braille.arrayWordsInString[braille.arrayWordsInStringIndex] ) )
            brailleString = braille.arrayBrailleGridsForCharsInWord.first?.brailleDots ?? ""
            self.morseCodeTextLabel.setText(self.brailleString)
            self.morseCodeTextLabel.setHidden(false)
            setInstructionLabelForMode(mainString: "Scroll to the end to read all the characters.\nScroll fast for autoplay", readingString: stopReadingString, writingString: keepTypingString, isError: false)
            fullTextButton.setHidden(false)
            iphoneImage?.setHidden(true)
            let brailleStringIndex = braille.getNextIndexForBrailleTraversal(brailleStringLength: brailleString.count, currentIndex: braille.mIndex, isDirectionHorizontal: isBrailleSwitchedToHorizontal)
            if brailleStringIndex != -1 {
                //Is it a valid index? Then highlight
                /*digitalCrownRotated(direction: "down")*/ highlightContent()
            }
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
        if direction == "down" { /*digitalCrownRotated(direction: "down")*/nextCharacterButtonTapped() } else { /*digitalCrownRotated(direction: "up")*/previousCharacterButtonTapped() }
        
   /*     let brailleStringIndex = braille.getNextIndexForBrailleTraversal(brailleStringLength: morseCodeString.count, currentIndex: braille.mIndex, isDirectionHorizontal: isBrailleSwitchedToHorizontal)
        if braille.isEndOfEntireStringReached(brailleString: morseCodeString, brailleStringIndex: brailleStringIndex) {
            isAutoPlayOn = false
            pauseAutoPlayAndReset()
            return
        }   */
     /*   let dictionary : Dictionary = timer.userInfo as! Dictionary<String,String>
        let direction : String = dictionary["direction"] ?? ""
        if self.isScreenActive == true {
            //In case the watch screen goes off, we pause
            //Resume when the user turns the watch screen ON again
            if direction.isEmpty == false {
                mIndex = direction == "down" ? mIndex + 1 : mIndex - 1
                let brailleIndex = braille.getNextIndexForBrailleTraversal(brailleStringLength: morseCodeString.count, currentIndex: mIndex, isDirectionHorizontal: false)
                if  brailleIndex == -1 && direction == "down" {
                    if arrayBrailleGridsForCharsInWordIndex >= (arrayBrailleGridsForCharsInWord.count - 1)
                        && arrayWordsInStringIndex >= (arrayWordsInString.count - 1) {
                        //end of word and end of string
                        playPauseButtonTapped()
                        pauseAutoPlayAndReset()
                        return
                    }
                    if arrayBrailleGridsForCharsInWordIndex >= (arrayBrailleGridsForCharsInWord.count - 1) {
                        //end of word only. move to next word
                        arrayWordsInStringIndex += 1
                        arrayBrailleGridsForCharsInWordIndex = 0
                        englishString = arrayWordsInString[arrayWordsInStringIndex]
                        englishTextLabel.setText(englishString)
                        arrayBrailleGridsForCharsInWord.removeAll()
                        arrayBrailleGridsForCharsInWord.append(contentsOf: braille.convertAlphanumericToBrailleWithContractions(alphanumericString: arrayWordsInString[arrayWordsInStringIndex] ) ) //get the braille grids for the next word
                        morseCodeString = arrayBrailleGridsForCharsInWord.first?.brailleDots ?? "" //set the braille grid for the first character in the word
                        morseCodeTextLabel.setText(morseCodeString)
                        mIndex = -1
                        alphanumericHighlightStartIndex = 0
                        return
                    }
                    let exactWord = arrayBrailleGridsForCharsInWord[arrayBrailleGridsForCharsInWordIndex].english
                    alphanumericHighlightStartIndex += exactWord.count
                    arrayBrailleGridsForCharsInWordIndex += 1
                    morseCodeString = arrayBrailleGridsForCharsInWord[arrayBrailleGridsForCharsInWordIndex].brailleDots
                    morseCodeTextLabel.setText(morseCodeString)
                    mIndex = 0
                }
                if  brailleIndex == -1 && direction == "up" {
                    if arrayBrailleGridsForCharsInWordIndex <= 0 {
                        pauseAutoPlayAndReset()
                        return
                    }
                    arrayBrailleGridsForCharsInWordIndex -= 1
                    morseCodeString = arrayBrailleGridsForCharsInWord[arrayBrailleGridsForCharsInWordIndex].brailleDots
                    morseCodeTextLabel.setText(morseCodeString)
                    mIndex = morseCodeString.count - 1
                }
            /*    else if braille.isMidpointReachedForNumber(brailleStringLength: morseCodeString.count, brailleStringIndexForNextItem: brailleStringIndex) {
                    //Want a pause between first and second half of number
                    Thread.sleep(forTimeInterval: 0.25)
                }   */
                digitalCrownRotated(direction: direction)

                //mIndex = direction == "down" ? mIndex + 1 : mIndex - 1
            }
        }

        //if (direction == "down" && mIndex >= morseCodeString.count)
        //    || (direction == "up" && mIndex < 0) {
        //    pauseAutoPlayAndReset()
        //}
    /*    if braille.getNextIndexForBrailleTraversal(brailleStringLength: morseCodeString.count, currentIndex: mIndex, isDirectionHorizontal: false) == -1 && alphanumericArrayIndex >= alphanumericArrayForBraille.count {
            pauseAutoPlayAndReset()
        }
        else if braille.isMidpointReachedForNumber(brailleStringLength: morseCodeString.count, brailleStringIndexForNextItem: brailleStringIndex) {
            //Want a pause between first and second half of number
            Thread.sleep(forTimeInterval: 0.25)
        }   */
        */
    }
    
    func pauseAutoPlay() {
        autoPlayTimer?.invalidate()
        playPauseButtonTappedUIChange()
    }
    
    func pauseAutoPlayAndReset() {
     /*   pauseAutoPlay()
        resetButton?.setHidden(true)
        resetBigText()
        englishString = englishString.replacingOccurrences(of: "␣", with: " ")
        //morseCodeString = morseCodeString.replacingOccurrences(of: " ", with: "|") //Autoplay complete, restore pipes
        englishStringIndex = -1 //Ensuring the pointer is set correctly
        mIndex = -1
        arrayBrailleGridsForCharsInWordIndex = -1
        arrayWordsInStringIndex = -1
        brailleStringIndex = -1
        englishString = arrayWordsInString[0]
        arrayBrailleGridsForCharsInWord.removeAll()
        arrayBrailleGridsForCharsInWord.append(contentsOf: braille.convertAlphanumericToBrailleWithContractions(alphanumericString: arrayWordsInString[0] ) )
        englishTextLabel.setText(englishString)
        morseCodeString = arrayBrailleGridsForCharsInWord.first?.brailleDots ?? ""
        morseCodeTextLabel.setText(morseCodeString)
        //self.setInstructionLabelForMode(mainString: self.dcScrollStart, readingString: self.stopReadingString, writingString: self.keepTypingString, isError: false)
        instructionsLabel?.setText(dcScrollStart)   */
        pauseAutoPlay()
        braille.resetVariables()
        alphanumericString = braille.arrayWordsInString.first ?? ""
        englishTextLabel.setText(alphanumericString)
        brailleString = braille.arrayBrailleGridsForCharsInWord.first?.brailleDots ?? "" //Reset braille grid to first character
        morseCodeTextLabel.setText(brailleString)
        //morseCodeLabel.text = morseCodeLabel?.text?.replacingOccurrences(of: " ", with: "|") //Autoplay complete, restore pipes //DOES NOT APPLY TO BRAILLE
        resetButton?.setHidden(true)
        resetBigText()
    }
    
    func morseCodeAutoPlay(direction : String) {
        if braille.mIndex < 0 {
            //We are not in the middle of a puased autoplay
            //Reset the labels
            alphanumericString = braille.arrayWordsInString.first ?? ""
            englishTextLabel.setText(alphanumericString)
            braille.resetVariables()
            let morseCodeString = braille.arrayBrailleGridsForCharsInWord.first?.brailleDots
            morseCodeTextLabel.setText(morseCodeString?.replacingOccurrences(of: "|", with: " ")) //We will not be playing pipes in autoplay
            morseCodeTextLabel.setTextColor(.none)
        }
        
        let dictionary = [
            "direction" : direction
        ]
        let userDefault = UserDefaults.standard
        TIME_DIFF_MILLIS = userDefault.value(forKey: LibraryCustomActions.STRING_FOR_USER_DEFAULTS) as? Double ?? 1000
        //let appGroupName = LibraryCustomActions.APP_GROUP_NAME
        //let appGroupUserDefaults = UserDefaults(suiteName: appGroupName)!
        //let TIME_DIFF_MILLIS : Double = appGroupUserDefaults.value(forKey: LibraryCustomActions.STRING_FOR_USER_DEFAULTS) as? Double ?? 1000
        let timeInterval = TIME_DIFF_MILLIS/1000 //direction == "down" ? 1 : 0.5
        autoPlayTimer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(MCInterfaceController.autoPlay(timer:)), userInfo: dictionary, repeats: true) 
      /*  isAutoPlayOn = true
        
        
        if mIndex < 0 {
            //means autoplay is not paused.
            //Reset the text
            englishString = arrayWordsInString.first ?? ""
            arrayBrailleGridsForCharsInWord.removeAll()
            arrayBrailleGridsForCharsInWord.append(contentsOf: braille.convertAlphanumericToBrailleWithContractions(alphanumericString: arrayWordsInString.first ?? "" ) )
            morseCodeString = arrayBrailleGridsForCharsInWord.first?.brailleDots ?? ""
            englishTextLabel.setText(englishString) //Resetting the string colors at the start of autoplay
            morseCodeString = morseCodeString.replacingOccurrences(of: "|", with: " ") //We will not be playing pipes in autoplay
            morseCodeTextLabel.setText(morseCodeString)
            
            //Reset the indices
            englishStringIndex = direction == "down" ? -1 : englishString.count //If the fast rotation happens in the middle of a reading, reset the indexes for autoplay
            arrayBrailleGridsForCharsInWordIndex = direction == "down" ? 0 : arrayBrailleGridsForCharsInWord.count - 1
            arrayWordsInStringIndex = direction == "down" ? 0 : arrayWordsInString.count - 1
            mIndex = direction == "down" ? -1 : morseCodeString.count
            let exactWord = arrayBrailleGridsForCharsInWord[arrayBrailleGridsForCharsInWordIndex].english
            alphanumericHighlightStartIndex = direction == "down" ? 0 : englishString.count - exactWord.count
        }
        
        let dictionary = [
            "direction" : direction
        ]
        instructionsLabel?.setText(direction == "down" ? "Autoplaying vibrations. Rotate digital crown upwards to stop" : "Resetting, please wait...")
        let userDefault = UserDefaults.standard
        TIME_DIFF_MILLIS = userDefault.value(forKey: LibraryCustomActions.STRING_FOR_USER_DEFAULTS) as? Double ?? 1000
        //let appGroupName = LibraryCustomActions.APP_GROUP_NAME
        //let appGroupUserDefaults = UserDefaults(suiteName: appGroupName)!
        //let TIME_DIFF_MILLIS : Double = appGroupUserDefaults.value(forKey: LibraryCustomActions.STRING_FOR_USER_DEFAULTS) as? Double ?? 1000
        let timeInterval = TIME_DIFF_MILLIS/1000 //direction == "down" ? 1 : 0.5
        autoPlayTimer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(MCInterfaceController.autoPlay(timer:)), userInfo: dictionary, repeats: true)    */
    }
    
    func digitalCrownRotated(direction : String) {
      /*  if morseCodeString.isEmpty {
            WKInterfaceDevice.current().play(.failure)
            mIndex = -1
            return
        }
        brailleStringIndex = braille.getNextIndexForBrailleTraversal(brailleStringLength: morseCodeString.count, currentIndex: mIndex, isDirectionHorizontal: isBrailleSwitchedToHorizontal)
        if direction == "down" {
            sendAnalytics(eventName: "se3_watch_scroll_down", parameters: [
                "state" : "scrolling",
                "isReading" : self.isReading()
            ])
            if isAutoPlayOn == false {
                setInstructionLabelForMode(mainString: "Scroll to the end to read all the characters.\nScroll fast for autoplay", readingString: stopReadingString, writingString: keepTypingString, isError: false)
            }
            setSelectedCharInLabel(inputString: morseCodeString, index: /*mIndex*/brailleStringIndex, length: 1, label: morseCodeTextLabel, isMorseCode: true, color: UIColor.green)
            playSelectedCharacterHaptic(inputString: morseCodeString, inputIndex: /*mIndex*/brailleStringIndex)
            
            let exactWord = arrayBrailleGridsForCharsInWord[arrayBrailleGridsForCharsInWordIndex].english
            setSelectedCharInLabel(inputString: englishString, index: /*englishStringIndex*/alphanumericHighlightStartIndex, length: exactWord.count, label: englishTextLabel, isMorseCode: false, color : UIColor.green)

            animateMiddleText(text: /*mIndex < explanationArray.count ? explanationArray[mIndex] :*/ nil)
            
        }
        else if direction == "up" {
            sendAnalytics(eventName: "se3_watch_scroll_up", parameters: [
                "state" : "scrolling",
                "is_reading" : self.isReading()
            ])
            setSelectedCharInLabel(inputString: morseCodeString, index: /*mIndex*/brailleStringIndex, length: 1, label: morseCodeTextLabel, isMorseCode: true, color : UIColor.green)
            //resetBigText()
            animateMiddleText(text: nil)
            playSelectedCharacterHaptic(inputString: morseCodeString, inputIndex: /*mIndex*/brailleStringIndex)
            
            if mode == "TIME" || mode == "DATE" {
                //Custom pattern used, not morse code. So we not want to highlight alphanumerics
                return
            }
            
            let exactWord = arrayBrailleGridsForCharsInWord[arrayBrailleGridsForCharsInWordIndex].english
            setSelectedCharInLabel(inputString: englishString, index: /*englishStringIndex*/alphanumericHighlightStartIndex, length: exactWord.count, label: englishTextLabel, isMorseCode: false, color: UIColor.green)
            
        }   */
    }
    
    private func highlightContentAndPlayHaptic() {
        highlightContent()
        let brailleStringIndex = braille.getNextIndexForBrailleTraversal(brailleStringLength: brailleString.count, currentIndex: braille.mIndex, isDirectionHorizontal: isBrailleSwitchedToHorizontal)
        playSelectedCharacterHaptic(inputString: brailleString, inputIndex: /*mIndex*/brailleStringIndex)
    }
    
    private func highlightContent() {
        let brailleStringIndex = braille.getNextIndexForBrailleTraversal(brailleStringLength: brailleString.count, currentIndex: braille.mIndex, isDirectionHorizontal: isBrailleSwitchedToHorizontal)
        
        setSelectedCharInLabel(inputString: brailleString, index: /*mIndex*/brailleStringIndex, length: 1, label: morseCodeTextLabel, isMorseCode: true, color : UIColor.green)
   
        let exactWord = braille.arrayBrailleGridsForCharsInWord[braille.arrayBrailleGridsForCharsInWordIndex].english //From this we get the exact length of the word to highlight. Can be more than 1 character
        setSelectedCharInLabel(inputString: alphanumericString, index: /*alphanumericStringIndex*/braille.alphanumericHighlightStartIndex, length: exactWord.count ,label: englishTextLabel, isMorseCode: false, color: UIColor.green)
        
        animateMiddleText(text: /*inputMCExplanation[safe: braille.mIndex]*/nil)
    }
    
    private func animateMiddleText(text: String?) {
        var localText : String? = text
        if localText == nil {
            //First check if it is a number
         /*   let currentAlphanumericChar = englishString[englishString.index(englishString.startIndex, offsetBy:  englishStringIndex >= 0 ? englishStringIndex : 0)]
            if currentAlphanumericChar.isWholeNumber == true {
                localText = LibraryCustomActions.getInfoTextForWholeNumber(morseCodeString: morseCodeString, mIndex: mIndex, currentAlphanumericChar: String(currentAlphanumericChar))
            }
            else {
                //We are assuming its morse code
                localText = LibraryCustomActions.getInfoTextForMorseCode(morseCodeString: morseCodeString, mIndex: mIndex)
            }   */
            let brailleStringIndex = braille.getNextIndexForBrailleTraversal(brailleStringLength: brailleString.count, currentIndex: braille.mIndex, isDirectionHorizontal: isBrailleSwitchedToHorizontal)
            localText = LibraryCustomActions.getInfoTextForBraille(brailleString: brailleString, brailleStringIndex: brailleStringIndex)
            
        }

        if localText == nil {
            //If we are in the middle of playing a morse code character, we do not want to change the label
            return
        }
        if braille.mIndex % 2 == 0 {
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
            defaultInstructions = mcTypingInstructions
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

