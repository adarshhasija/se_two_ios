//
//  MCReaderButtonsViewController.swift
//  Suno
//
//  Created by Adarsh Hasija on 21/10/20.
//  Copyright © 2020 Adam Behringer. All rights reserved.
//

import Foundation
import UIKit
import Speech
import FirebaseAnalytics
import WatchConnectivity
import IntentsUI

//Morse code reader with buttons, no gestures
class MCReaderButtonsViewController : UIViewController {
    
    var siriShortcut: SiriShortcut? = nil
    var inputMode: Action? = nil //Used when a request comes in from a watch. Need to validate type of request
    var inputAlphanumeric : String? = nil
    var inputMorseCode : String? = nil //Customized morse code is sent it. If this is nil, we will use standard morse code dictionary
    var inputMCExplanation : [String] = []
    
    lazy var supportsHaptics: Bool = {
            return (UIApplication.shared.delegate as? AppDelegate)?.supportsHaptics ?? false
        }()
    //var hapticManager : HapticManager?  //This global variable caused a bug. If the phone locked and then we unlocked, haaptics stopped working. So this is now a local variable in this screen
    
    var alphanumericStringIndex = -1
    var morseCodeStringIndex = -1
    var arrayBrailleGridsForCharsInWord : [String] = []
    var arrayBrailleGridsForCharsInWordIndex = 0 //in the case of braille
    var arrayWordsInString : [String] = []
    var arrayWordsInStringIndex = 0
    var morseCode = MorseCode()
    var braille = Braille()
    var synth = AVSpeechSynthesizer()
    var indicesOfPipes : [Int] = [] //This is needed when highlighting morse code when the user taps on the screen to play audio
    var isAutoPlayOn = false
    var isAudioRequestedByUser = false
    var isBrailleSwitchedToHorizontal = false
    var autoPlayTimer : Timer? = nil
    
    @IBOutlet weak var middleBigTextView: UILabel!
    @IBOutlet weak var stackViewMain: UIStackView!
    @IBOutlet weak var alphanumericLabel: UILabel!
    @IBOutlet weak var morseCodeLabel: UILabel!
    @IBOutlet weak var braillelLabel: UILabel!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var audioButton: UIButton! //Audio descriptions during autoplay
    @IBOutlet weak var previousCharacterButton: UIButton!
    @IBOutlet weak var nextCharacterButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var switchBrailleDirectionButton: UIButton!
    @IBOutlet weak var fullTextButton: UIButton!
    @IBOutlet weak var middleStackView: UIStackView!
    @IBOutlet weak var appleWatchImageView: UIImageView!
    @IBOutlet weak var scrollMCLabel: UILabel!
    var siriButton : INUIAddVoiceShortcutButton!
    var backTapLabels : [UILabel] = []

    
    
    override func viewDidLoad() {
        //hapticManager = HapticManager(supportsHaptics: supportsHaptics)
        if inputAlphanumeric == nil {
            alphanumericLabel?.text = "Error\nSomething went wrong"
            alphanumericLabel?.textColor = .red
            morseCodeLabel?.isHidden = true
            playPauseButton?.isHidden = true
            return
        }
        alphanumericLabel.text = inputAlphanumeric
        //let morseCodeText = inputMorseCode != nil ? inputMorseCode : convertAlphanumericToMC(alphanumericString: inputAlphanumeric ?? "")
        var brailleText = ""
        if inputMorseCode != nil {
            brailleText = inputMorseCode!
            morseCodeLabel.text = brailleText
        }
        else {
            arrayWordsInString.append(contentsOf: inputAlphanumeric?.components(separatedBy: " ") ?? [])
            arrayBrailleGridsForCharsInWord.append(contentsOf: braille.convertAlphanumericToBraille(alphanumericString: arrayWordsInString.first ?? "") ?? [])
            fullTextButton.isHidden = false
            alphanumericLabel.text = arrayWordsInString.first
            brailleText = (arrayBrailleGridsForCharsInWord.first)!
            morseCodeLabel.text = brailleText
        }
        //sendEnglishAndMCToWatch(alphanumeric: inputAlphanumeric ?? "", morseCode: brailleText) //The Watch may already be waiting for camera input.
        sendEnglishAndBrailleToWatch()
        if WCSession.isSupported() {
            let session = WCSession.default
            if session.isWatchAppInstalled {
                appleWatchImageView.image = UIImage(systemName: "applewatch.watchface")
                appleWatchImageView.isHidden = false
                scrollMCLabel.text = "You can also try it on your Apple Watch app"
                scrollMCLabel.isHidden = false
            }
            else {
                appleWatchImageView.image = UIImage(systemName: "applewatch.slash")
                appleWatchImageView.isHidden = false
                scrollMCLabel.text = "You can try it on your Apple Watch\nYou must install the watch app"
                scrollMCLabel.isHidden = false
            }
        }
        if siriShortcut != nil { addSiriButton(shortcutForButton: siriShortcut!, to: middleStackView) }
        alphanumericStringIndex = -1
        morseCodeStringIndex = -1
        audioButton?.setTitleColor(.gray, for: .disabled)
        audioButton?.isHidden = true //UIAccessibility.isVoiceOverRunning == false ? true : false
        audioButton?.titleLabel?.numberOfLines = 0
        audioButton?.titleLabel?.textAlignment = .center
        audioButton?.setTitle("Play Audio.\nEnabled when autoplay is ON", for: .disabled)
        audioButton?.isEnabled = false
        //playPauseButtonTapped(1) //dummy parameter
        //setUpButtonScalable(button: autoplayButton, title: isAutoPlayOn == true ? "Stop Autoplay" : "Replay")
    }
    
    @IBAction func fullTextButtonTapped(_ sender: Any) {
        //We do this to retain the state when we return from viewing the full text
        UserDefaults.standard.set(arrayWordsInStringIndex, forKey: "INDEX_IN_FULL_STRING")
        UserDefaults.standard.set(arrayBrailleGridsForCharsInWordIndex, forKey: "INDEX_IN_WORD")
        UserDefaults.standard.set(morseCodeStringIndex, forKey: "INDEX_IN_GRID")  //braille index is obtained from this
        let storyBoard : UIStoryboard = UIStoryboard(name: "MorseCode", bundle:nil)
        let textViewController = storyBoard.instantiateViewController(withIdentifier: "TextViewController") as! TextViewController
        var text = ""
        var startIndexForHighlighting = 0
        var endIndexForHighlighting = 0
        for word in arrayWordsInString {
            text += word
            text += " "
        }
        text = text.trimmingCharacters(in: .whitespacesAndNewlines) //Trim the last space at the end from the for loop above
        for (index, element) in arrayWordsInString.enumerated() {
            if index < arrayWordsInStringIndex {
                startIndexForHighlighting += arrayWordsInString[index].count //Need to increment by length of  the word that was completed
                startIndexForHighlighting += 1 //account for space after the word
            }
        }
        startIndexForHighlighting += arrayBrailleGridsForCharsInWordIndex
        endIndexForHighlighting = morseCodeStringIndex > -1 ? startIndexForHighlighting + 1 : startIndexForHighlighting //If we have not started traversing the grid, we dont want to highlight
        textViewController.mText = text
        textViewController.mStartIndexForHighlighting = startIndexForHighlighting
        textViewController.mEndIndexForHighlighting = endIndexForHighlighting
        self.navigationController?.pushViewController(textViewController, animated: true)
    }
    
    @IBAction func audioButtonTapped(_ sender: Any) {
        Analytics.logEvent("se3_ios_audio_btn", parameters: [:])
        isAudioRequestedByUser = !isAudioRequestedByUser
        audioButton?.setTitle(isAudioRequestedByUser == false ? "Play Audio" : "Stop Audio", for: .normal)
        audioButton?.setTitleColor(isAudioRequestedByUser == false ? UIColor.blue : UIColor.red, for: .normal)
    }
    
    
    @IBAction func switchBrailleButtonTapped(_ sender: Any) {
        isBrailleSwitchedToHorizontal = !isBrailleSwitchedToHorizontal
        if isBrailleSwitchedToHorizontal == false {
            switchBrailleDirectionButton?.setTitle("Switch to reading braille sideways", for: .normal)
        }
        else {
            switchBrailleDirectionButton?.setTitle("Switch to reading braille up down", for: .normal)
        }
    }
    
    
    @IBAction func playPauseButtonTapped(_ sender: Any) {
        isAutoPlayOn = !isAutoPlayOn
        if isAutoPlayOn == true {
            morseCodeAutoPlay(direction: "right")
        }
        else {
            pauseAutoPlay()
        }
        playPauseButtonTappedUIChange()
    }
    
    func playPauseButtonTappedUIChange() {
        if isAutoPlayOn == true {
            let image = UIImage(systemName: "pause.fill")
            playPauseButton?.setImage(image, for: .normal)
            playPauseButton?.accessibilityLabel = "Pause Button"
            playPauseButton?.accessibilityLabel = "Pause Button"
            previousCharacterButton?.isHidden = true
            nextCharacterButton?.isHidden = true
            resetButton?.isHidden = true
            fullTextButton?.isHidden = true
            switchBrailleDirectionButton?.isHidden = true
            audioButton?.isEnabled = false //We were previously hiding it. We do not want to do that as VoiceOver may/may not lose focus of the element
            appleWatchImageView.isHidden = true
            scrollMCLabel.isHidden = true
            siriButton?.isHidden = true
            if UIAccessibility.isVoiceOverRunning {
                audioButton?.setTitle(isAudioRequestedByUser == false ? "Play Audio" : "Stop Audio", for: .normal)
                audioButton?.setTitleColor(isAudioRequestedByUser == false ? UIColor.blue : UIColor.red, for: .normal)
                audioButton?.isEnabled = true
            }
            appleWatchImageView.isHidden = true
            scrollMCLabel.isHidden = true
            siriButton?.isHidden = true
            for backTapLabel in backTapLabels {
                backTapLabel.isHidden = true
            }
        }
        else {
            let image = UIImage(systemName: "play.fill")
            playPauseButton?.setImage(image, for: .normal)
            playPauseButton?.accessibilityLabel = "Play Button"
            playPauseButton?.accessibilityHint = "Play Button"
            previousCharacterButton?.isHidden = false
            nextCharacterButton?.isHidden = false
            resetButton?.isHidden = false
            fullTextButton?.isHidden = false
            //switchBrailleDirectionButton?.isHidden = false
            audioButton?.isEnabled = false //We were previously hiding it. We do not want to do that as VoiceOver may/may not lose focus of the element
            appleWatchImageView.isHidden = false
            scrollMCLabel.isHidden = false
            siriButton?.isHidden = false
            for backTapLabel in backTapLabels {
                backTapLabel.isHidden = false
            }
        }
    }
    
    
    @IBAction func previousCharacterButtonTapped(_ sender: Any) {
        morseCodeStringIndex -= 1
        let morseCodeString = morseCodeLabel?.text ?? ""
        if morseCodeStringIndex >= (morseCodeString.count - 1)
            && arrayBrailleGridsForCharsInWordIndex >= (arrayBrailleGridsForCharsInWord.count - 1)
            && arrayWordsInStringIndex >= (arrayWordsInString.count - 1) {
            //We are way  beyond the end
            //We are also checking Morse Code index becuase only braille index can be triggered when at the start of the grid also
            arrayWordsInStringIndex = arrayWordsInString.count - 1
            arrayBrailleGridsForCharsInWordIndex = arrayBrailleGridsForCharsInWord.count - 1
            let brailleString = morseCodeLabel?.text ?? ""
            morseCodeStringIndex = braille.getIndexInStringOfLastCharacterInTheGrid(brailleStringForCharacter: brailleString)
        }
        else if /*brailleIndex == -1*/morseCodeStringIndex <= -1
            && arrayBrailleGridsForCharsInWordIndex <= 0
            && arrayWordsInStringIndex <= 0 {
            alphanumericLabel?.text = alphanumericLabel?.text //remove highlights
            alphanumericLabel?.textColor = .label
            morseCodeLabel?.text = morseCodeLabel?.text
            let hapticManager = HapticManager(supportsHaptics: supportsHaptics)
            hapticManager.hapticsForEndofEntireAlphanumeric()
            resetButton?.isHidden = true
            return
        }
        else if /*brailleIndex == -1*/morseCodeStringIndex <= -1
                    && arrayBrailleGridsForCharsInWordIndex <= 0 {
            //end of word. move to previous word
            setupPreviousWord()
        }
        else if morseCodeStringIndex <= -1 {
            //in the middle of a word. move to the previous character
            arrayBrailleGridsForCharsInWordIndex -= 1
            let morseCodeString = arrayBrailleGridsForCharsInWord[arrayBrailleGridsForCharsInWordIndex]
            morseCodeLabel.text = morseCodeString
            morseCodeStringIndex = braille.getIndexInStringOfLastCharacterInTheGrid(brailleStringForCharacter: morseCodeString)
        }
        mcScrollLeft()
    }
    
    
    @IBAction func nextCharacterButtonTapped(_ sender: Any) {
        //appleWatchImageView.isHidden = true
        //scrollMCLabel.isHidden = true
        //siriButton?.isHidden = true
        //for backTapLabel in backTapLabels {
        //    backTapLabel.isHidden = true
        //}
        morseCodeStringIndex += 1
        let brailleStringIndex = braille.getNextIndexForBrailleTraversal(brailleStringLength: morseCodeLabel.text!.count, currentIndex: morseCodeStringIndex, isDirectionHorizontal: isBrailleSwitchedToHorizontal)
        if morseCodeStringIndex <= 0
            && arrayBrailleGridsForCharsInWordIndex <= 0
            && arrayWordsInStringIndex <= 0 {
            //we are at the beginning
            //assuming the right alphanumeric and right braille are already in place
            if isAutoPlayOn == false { resetButton?.isHidden = false } //Not available during autoplay
            arrayWordsInStringIndex = 0
            arrayBrailleGridsForCharsInWordIndex = 0
            morseCodeStringIndex = 0
        }
        else if brailleStringIndex == -1
            && arrayBrailleGridsForCharsInWordIndex >= (arrayBrailleGridsForCharsInWord.count - 1)
            && arrayWordsInStringIndex >= (arrayWordsInString.count - 1) {
            //end of word and end of string
            alphanumericLabel?.text = alphanumericLabel?.text //remove highlights
            alphanumericLabel?.textColor = .label
            morseCodeLabel?.text = morseCodeLabel?.text
            let hapticManager = HapticManager(supportsHaptics: supportsHaptics)
            hapticManager.hapticsForEndofEntireAlphanumeric()
            return
        }
        else if brailleStringIndex == -1
                    && arrayBrailleGridsForCharsInWordIndex >= (arrayBrailleGridsForCharsInWord.count - 1) {
            //end of word. move to next word
            setupNextWord()
        }
        else if brailleStringIndex == -1 {
            //end of character move to next character
            arrayBrailleGridsForCharsInWordIndex += 1
            morseCodeLabel?.text = arrayBrailleGridsForCharsInWord[arrayBrailleGridsForCharsInWordIndex]
            animateBrailleGrid()
            morseCodeStringIndex = 0
        }
        mcScrollRight()
    }
    
    
    @IBAction func resetButtonTapped(_ sender: Any) {
      /*appleWatchImageView.isHidden = false
        scrollMCLabel.isHidden = false
        siriButton?.isHidden = false
        for backTapLabel in backTapLabels {
            backTapLabel.isHidden = false
        }   */
        pauseAutoPlayAndReset()
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, // announce
        "Reset Successful");
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }
    
    @IBAction func gestureLongPress(_ sender: Any) {
        if (sender as? UIGestureRecognizer)?.state == UIGestureRecognizer.State.recognized {
            //Not used right now
            //Analytics.logEvent("se3_ios_long_press", parameters: [:])
        }
    }
    
    @objc func autoPlay(timer : Timer) {
        let dictionary : Dictionary = timer.userInfo as! Dictionary<String,String>
        let direction : String = dictionary["direction"] ?? ""
        if direction == "right" { nextCharacterButtonTapped(1) } else { nextCharacterButtonTapped(1) }
        
        let brailleString = morseCodeLabel.text ?? ""
        let brailleStringIndex = braille.getNextIndexForBrailleTraversal(brailleStringLength: brailleString.count, currentIndex: morseCodeStringIndex, isDirectionHorizontal: isBrailleSwitchedToHorizontal)
        if brailleStringIndex == -1
            && arrayBrailleGridsForCharsInWordIndex >= (arrayBrailleGridsForCharsInWord.count - 1)
            && arrayWordsInStringIndex >= (arrayWordsInString.count - 1) {
            isAutoPlayOn = false
            pauseAutoPlayAndReset()
            return
        }
        else if braille.isMidpointReachedForNumber(brailleStringLength: brailleString.count, brailleStringIndexForNextItem: brailleStringIndex) {
            //Want a pause between first and second half of number
            Thread.sleep(forTimeInterval: 0.25)
        }
        
        
    /*    else if brailleIndex == -1
                    && arrayBrailleGridsForCharsInWordIndex >= arrayBrailleGridsForCharsInWord.count {
            //end of word. move to next word
            setupNextWord()
        }
        else if braille.isMidpointReachedForNumber(brailleStringLength: count, brailleStringIndexForNextItem: brailleStringIndex) {
            //Want a pause between first and second half of number
            Thread.sleep(forTimeInterval: 0.25)
        }   */
    }
    
    func setupPreviousWord() {
        arrayWordsInStringIndex -= 1
        let alphanumericString = arrayWordsInString[arrayWordsInStringIndex]
        alphanumericLabel.text = alphanumericString
        alphanumericLabel.textColor = .label
        arrayBrailleGridsForCharsInWord.removeAll()
        arrayBrailleGridsForCharsInWord.append(contentsOf: braille.convertAlphanumericToBraille(alphanumericString: arrayWordsInString[arrayWordsInStringIndex] ) ?? []) //get the braille grids for the next word
        arrayBrailleGridsForCharsInWordIndex = alphanumericString.count - 1
        let brailleString = arrayBrailleGridsForCharsInWord.last ?? "" //set the braille grid for the last character in the word
        morseCodeLabel?.text = brailleString
        morseCodeStringIndex = braille.getIndexInStringOfLastCharacterInTheGrid(brailleStringForCharacter: brailleString)
    }
    
    func setupNextWord() {
        arrayWordsInStringIndex += 1
        alphanumericLabel.text = arrayWordsInString[arrayWordsInStringIndex]
        alphanumericLabel.textColor = .label
        arrayBrailleGridsForCharsInWord.removeAll()
        arrayBrailleGridsForCharsInWord.append(contentsOf: braille.convertAlphanumericToBraille(alphanumericString: arrayWordsInString[arrayWordsInStringIndex] ) ?? []) //get the braille grids for the next word
        morseCodeLabel?.text = arrayBrailleGridsForCharsInWord.first ?? "" //set the braille grid for the first character in the word
        morseCodeStringIndex = 0
        arrayBrailleGridsForCharsInWordIndex = 0
    }
    
    func pauseAutoPlay() {
        autoPlayTimer?.invalidate()
        playPauseButtonTappedUIChange()
    }
    
    func pauseAutoPlayAndReset() {
        pauseAutoPlay()
        resetButton?.isHidden = true
        middleBigTextView.isHidden = true
        arrayWordsInStringIndex = 0
        arrayBrailleGridsForCharsInWordIndex = 0
        alphanumericStringIndex = -1
        morseCodeStringIndex = -1
        alphanumericLabel?.text = arrayWordsInString.first
        alphanumericLabel?.textColor = .none
        arrayBrailleGridsForCharsInWord.removeAll()
        arrayBrailleGridsForCharsInWord.append(contentsOf: braille.convertAlphanumericToBraille(alphanumericString: arrayWordsInString[0] ) ?? [])
        morseCodeLabel.text = (arrayBrailleGridsForCharsInWord.first)! //Reset braille grid to first character
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, // announce
                    "Autoplay complete");
        let moreCodeString = morseCodeLabel.text
        morseCodeLabel.text = moreCodeString //This is to remove any highlighted charaacter
        morseCodeLabel?.textColor = .none
        //morseCodeLabel.text = morseCodeLabel?.text?.replacingOccurrences(of: " ", with: "|") //Autoplay complete, restore pipes //DOES NOT APPLY TO BRAILLE
    }
    
    func morseCodeAutoPlay(direction: String) {
        if morseCodeStringIndex < 0 {
            //We are not in the middle of a puased autoplay
            //Reset the labels
            alphanumericLabel?.text = arrayWordsInString.first
            alphanumericLabel?.textColor = .none //Resetting the string colors at the start of autoplay
            arrayBrailleGridsForCharsInWord.removeAll()
            arrayBrailleGridsForCharsInWord.append(contentsOf: braille.convertAlphanumericToBraille(alphanumericString: arrayWordsInString.first ?? "" ) ?? [])
            let morseCodeString = arrayBrailleGridsForCharsInWord.first
            morseCodeLabel?.text = morseCodeString?.replacingOccurrences(of: "|", with: " ") //We will not be playing pipes in autoplay
            morseCodeLabel?.textColor = .none
            
            //Reset the indexes
            arrayWordsInStringIndex = 0
            arrayBrailleGridsForCharsInWordIndex = 0
            alphanumericStringIndex = -1
            morseCodeStringIndex = -1
        }
        
        let dictionary = [
            "direction" : direction
        ]
        let userDefault = UserDefaults.standard
        let TIME_DIFF_MILLIS : Double = userDefault.value(forKey: LibraryCustomActions.STRING_FOR_USER_DEFAULTS) as? Double ?? 1000
        //let appGroupName = LibraryCustomActions.APP_GROUP_NAME
        //let appGroupUserDefaults = UserDefaults(suiteName: appGroupName)!
        //let TIME_DIFF_MILLIS : Double = appGroupUserDefaults.value(forKey: LibraryCustomActions.STRING_FOR_USER_DEFAULTS) as? Double ?? 1000
        let timeInterval = TIME_DIFF_MILLIS/1000 //direction == "down" ? 1 : 0.5
        autoPlayTimer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(MCReaderButtonsViewController.autoPlay(timer:)), userInfo: dictionary, repeats: true)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        let userDefault = UserDefaults.standard
        guard let INDEX_IN_FULL_STRING : Int = userDefault.value(forKey: "INDEX_IN_FULL_STRING") as? Int else { return }
        userDefault.removeObject(forKey: "INDEX_IN_FULL_STRING")
        guard let INDEX_IN_WORD : Int = userDefault.value(forKey: "INDEX_IN_WORD") as? Int else { return }
        userDefault.removeObject(forKey: "INDEX_IN_WORD")
        guard let INDEX_IN_GRID : Int = userDefault.value(forKey: "INDEX_IN_GRID") as? Int else { return }
        userDefault.removeObject(forKey: "INDEX_IN_GRID")
        
        //We do have values and we can process them
        arrayWordsInStringIndex = INDEX_IN_FULL_STRING
        arrayBrailleGridsForCharsInWordIndex = INDEX_IN_WORD
        morseCodeStringIndex = INDEX_IN_GRID
        let alphanumericString = arrayWordsInString[arrayWordsInStringIndex]
        alphanumericLabel?.text = alphanumericString
        arrayBrailleGridsForCharsInWord.removeAll()
        arrayBrailleGridsForCharsInWord.append(contentsOf: braille.convertAlphanumericToBraille(alphanumericString: arrayWordsInString[arrayWordsInStringIndex]) ?? [])
        let morseCodeString = (arrayBrailleGridsForCharsInWordIndex < 0 ? arrayBrailleGridsForCharsInWord[0] :  arrayBrailleGridsForCharsInWord[arrayBrailleGridsForCharsInWordIndex])
        morseCodeLabel?.text = morseCodeString
        let brailleStringIndex = braille.getNextIndexForBrailleTraversal(brailleStringLength: morseCodeString.count, currentIndex: morseCodeStringIndex, isDirectionHorizontal: isBrailleSwitchedToHorizontal)
        
        //Could call mcScrollRight here but wont as that func plays a haptic, which we dont want
        if morseCodeStringIndex == -1 {
            return //Means nothing was highlighted. Doing a highlighting will crash the app
        }
        resetButton?.isHidden = false
        MorseCodeUtils.setSelectedCharInLabel(inputString: morseCodeString, index: /*morseCodeStringIndex*/brailleStringIndex, label: morseCodeLabel, isMorseCode: true, color: UIColor.green)
        MorseCodeUtils.setSelectedCharInLabel(inputString: alphanumericString, index: arrayBrailleGridsForCharsInWordIndex, label: alphanumericLabel, isMorseCode: false, color : UIColor.green)
        animateMiddleText(text: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        pauseAutoPlayAndReset() //For when the user leaves the screen via back button
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        //playAudioButton?.sizeToFit()
    }
    
    private func convertAlphanumericToMC(alphanumericString : String) -> String {
        let english = alphanumericString.uppercased().replacingOccurrences(of: " ", with: "␣")
        var morseCodeString = ""
        var index = 0
        indicesOfPipes.removeAll()
        indicesOfPipes.append(0)
        for character in english {
            var mcChar : String = character.isWholeNumber == true ? LibraryCustomActions.getIntegerInDotsAndDashes(integer: character.wholeNumberValue ?? 0) : (morseCode.alphabetToMCDictionary[String(character)] ?? "")
            mcChar += "|"
            index += mcChar.count
            indicesOfPipes.append(index)
            morseCodeString += mcChar
        }
        
        return morseCodeString
    }
    
    
    func mcScrollLeft() {
        let alphanumericString = alphanumericLabel?.text ?? ""
        let morseCodeString = morseCodeLabel?.text ?? ""
        let brailleStringIndex = braille.getNextIndexForBrailleTraversal(brailleStringLength: morseCodeString.count, currentIndex: morseCodeStringIndex, isDirectionHorizontal: isBrailleSwitchedToHorizontal)

        Analytics.logEvent("se3_ios_mc_left", parameters: [
                "state" : "scrolling"
            ])
        highlightContent(alphanumericString: alphanumericString, morseCodeString: morseCodeString, brailleStringIndex: brailleStringIndex)
    }
    
    func mcScrollRight() {
        let alphanumericString = alphanumericLabel?.text ?? ""
        let morseCodeString = morseCodeLabel?.text ?? ""
        let brailleStringIndex = braille.getNextIndexForBrailleTraversal(brailleStringLength: morseCodeString.count, currentIndex: morseCodeStringIndex, isDirectionHorizontal: isBrailleSwitchedToHorizontal)

        highlightContent(alphanumericString: alphanumericString, morseCodeString: morseCodeString, brailleStringIndex: brailleStringIndex)

        return
    }
    
    private func highlightContent(alphanumericString: String, morseCodeString: String, brailleStringIndex: Int) {
        MorseCodeUtils.setSelectedCharInLabel(inputString: morseCodeString, index: /*morseCodeStringIndex*/brailleStringIndex, label: morseCodeLabel, isMorseCode: true, color : UIColor.green)
        let hapticManager = HapticManager(supportsHaptics: supportsHaptics)
        hapticManager.playSelectedCharacterHaptic(inputString: morseCodeString, inputIndex: /*morseCodeStringIndex*/brailleStringIndex)
   
        MorseCodeUtils.setSelectedCharInLabel(inputString: alphanumericString, index: /*alphanumericStringIndex*/arrayBrailleGridsForCharsInWordIndex, label: alphanumericLabel, isMorseCode: false, color: UIColor.green)
        
        animateMiddleText(text: inputMCExplanation[safe: morseCodeStringIndex])
    }
    
    private func sayThis(string: String) {
        let audioSession = AVAudioSession.sharedInstance()
        do { try audioSession.setCategory(AVAudioSessionCategoryPlayback) }
        catch { showToast(message: "Sorry, audio failed to play") }
        do { try audioSession.setMode(AVAudioSessionModeDefault) }
        catch { showToast(message: "Sorry, audio failed to play") }
        
        //synth.delegate = self
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
    
    func receivedRequestForAlphanumericsAndMCFromWatch(mode: String?) {
      /*  if mode == inputMode?.rawValue {
            //Mode requested by the watch has to match mode currently being viewed
            let alphanumericString = alphanumericLabel?.text ?? ""
            let morseCodeString = morseCodeLabel?.text?.replacingOccurrences(of: " ", with: "|") ?? "" //If it is on autoplay mode, there maybe no pipes. When its sent to the watch, its NOT on autoplay mode
            sendEnglishAndMCToWatch(alphanumeric: alphanumericString, morseCode: morseCodeString)
        }   */
        sendEnglishAndBrailleToWatch()
    }
    
    func sendEnglishAndMCToWatch(alphanumeric: String, morseCode: String) {
        if WCSession.isSupported() {
            let session = WCSession.default
            if session.isWatchAppInstalled && session.isReachable {
                session.sendMessage([
                                        "is_normal_morse": inputMorseCode != nil ? false : true,
                                        "mode" : inputMode?.rawValue,
                                        "english": alphanumeric,
                                        "morse_code": morseCode
                                    ], replyHandler: nil, errorHandler: nil)
            }
        }
    }
    
    func sendEnglishAndBrailleToWatch() {
        //If autoplay is on, we only send that. If its not on, we send all the indices to replicate on the watch
        if WCSession.isSupported() {
            let session = WCSession.default
            if session.isWatchAppInstalled && session.isReachable {
                session.sendMessage(isAutoPlayOn == true ?
                                    ["is_autoplay_on" : true ] :
                                    [
                                        "array_words_in_string": arrayWordsInString,
                                        "array_words_in_string_index": arrayWordsInStringIndex,
                                        "morse_code_string_index": morseCodeStringIndex,
                                        "array_braille_grids_for_chars_in_word": arrayBrailleGridsForCharsInWord,
                                        "array_braille_grids_for_chars_in_word_index": arrayBrailleGridsForCharsInWordIndex,
                                    ], replyHandler: nil, errorHandler: nil)
            }
        }
    }
    
    //Increases the size of the PlayAudio button if the user has opted for
    //Accessibility = Larger Text Sizes
    func setUpButtonScalable(button: UIButton, title: String) {
        //playAudioButton.contentEdgeInsets = UIEdgeInsets(top: 0,
        //                                                  left: 0,
        //                                                  bottom: 0,
        //                                                  right: 0)
        let font = UIFont(name: "Helvetica", size: 19)!
        let scaledFont = UIFontMetrics.default.scaledFont(for: font)
        let attributes = [NSAttributedString.Key.font: scaledFont]
        let attributedText = NSAttributedString(string: title,
                                                        attributes: attributes)
        button.titleLabel?.attributedText = attributedText
        button.setAttributedTitle(button.titleLabel?.attributedText,for: .normal)
    }
    
    // Add an "Add to Siri" button to a view.
    func addSiriButton(shortcutForButton: SiriShortcut, to view: UIStackView) {
        siriButton = INUIAddVoiceShortcutButton(style: .blackOutline)
        siriButton.translatesAutoresizingMaskIntoConstraints = false
        siriButton.isUserInteractionEnabled = true
        siriButton.shortcut = SiriShortcut.createINShortcutAndAddToSiriWatchFace(siriShortcut: shortcutForButton)
        siriButton.shortcut?.userActivity?.isAccessibilityElement = true
        siriButton.delegate = self
        
        //view.addSubview(button)
        //view.centerXAnchor.constraint(equalTo: button.centerXAnchor).isActive = true
                //view.centerYAnchor.constraint(equalTo: button.centerYAnchor).isActive = true
        view.insertArrangedSubview(siriButton, at: 0)
        
        guard (UIApplication.shared.delegate as? AppDelegate)?.isBackTapSupported() == true else {
            return
        }
        //Back tap is only supported on iPhone 8 and above
        let txt = "After creating shortcut, go to the Settings app to attach this shortcut to Back Tap"
        let sentences = txt.split(separator: ".") //Doing this to ensure blind can move over 1 sentence at a time via VoiceOver
        for sentence in sentences {
            let backTapLabel = UILabel()
            backTapLabel.text = String(sentence)
            backTapLabel.font = UIFont.preferredFont(forTextStyle: .body)
            backTapLabel.textAlignment = .center
            backTapLabel.lineBreakMode = .byWordWrapping
            backTapLabel.numberOfLines = 0
            view.insertArrangedSubview(backTapLabel, at: view.arrangedSubviews.count)
            backTapLabels.append(backTapLabel)
        }
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
    
    private func animateMiddleText(text: String?) {
        var localText : String? = text
        if localText == nil {
            //First check if it is a number
         /*   let alphanumericString = alphanumericLabel?.text ?? ""
            let currentAlphanumericChar = alphanumericString[alphanumericString.index(alphanumericString.startIndex, offsetBy:  alphanumericStringIndex >= 0 ? alphanumericStringIndex : 0)]
            if currentAlphanumericChar.isWholeNumber == true {
                let morseCodeString = morseCodeLabel?.text ?? ""
                localText = LibraryCustomActions.getInfoTextForWholeNumber(morseCodeString: morseCodeString, morseCodeStringIndex: morseCodeStringIndex, currentAlphanumericChar: String(currentAlphanumericChar))
            }
            else {
                //We are assuming its morse code
                let morseCodeString = morseCodeLabel?.text ?? ""
                localText = LibraryCustomActions.getInfoTextForMorseCode(morseCodeString: morseCodeString, morseCodeStringIndex: morseCodeStringIndex)
            }   */
            let brailleString = morseCodeLabel?.text ?? ""
            let brailleStringIndex = braille.getNextIndexForBrailleTraversal(brailleStringLength: brailleString.count, currentIndex: morseCodeStringIndex, isDirectionHorizontal: isBrailleSwitchedToHorizontal)
            localText = LibraryCustomActions.getInfoTextForBraille(brailleString: brailleString, brailleStringIndex: brailleStringIndex)
        }
        
        if localText == nil {
            //If we are in the middle of playing a morse code character, we do not want to change the label
            return
        }
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, // announce
        localText);
     /*   if isAudioRequestedByUser == true {
            if localText == "✓" {
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, // announce
                                    "Done");
            }
            else {
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, // announce
                                    localText);
            }
        }   */
        self.middleBigTextView.text = localText
        self.middleBigTextView.isHidden = false
        self.middleBigTextView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: .allowUserInteraction,
                       animations: { [weak self] in
                        self?.middleBigTextView.transform = .identity
            },
                       completion: { _ in
                            //If its the start of morse code combination, we do not want it to fade out
                            //If its autoplay, then we do want it to fade out
                            //self.middleBigTextView.isHidden = localText == "morse code" ? false : true
                       })
    }
    
    //used when we have a change of character and need to refresh the grid
    func animateBrailleGrid() {
        self.morseCodeLabel.isHidden = false
        self.morseCodeLabel.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: .allowUserInteraction,
                       animations: { [weak self] in
                        self?.morseCodeLabel.transform = .identity
            },
                       completion: { _ in
                            //If its the start of morse code combination, we do not want it to fade out
                            //If its autoplay, then we do want it to fade out
                            //self.middleBigTextView.isHidden = localText == "morse code" ? false : true
                       })
    }
}

extension MCReaderButtonsViewController : INUIAddVoiceShortcutButtonDelegate {
    func present(_ addVoiceShortcutViewController: INUIAddVoiceShortcutViewController, for addVoiceShortcutButton: INUIAddVoiceShortcutButton) {
        Analytics.logEvent("se3_add_to_siri_tapped", parameters: [
            "os_version": UIDevice.current.systemVersion,
            "mode": "add",
            "shortcut": siriShortcut?.action.prefix(100) ?? ""
            ])
        
        addVoiceShortcutViewController.delegate = self
        addVoiceShortcutViewController.modalPresentationStyle = .formSheet
        present(addVoiceShortcutViewController, animated: true, completion: nil)
    }
    
    func present(_ editVoiceShortcutViewController: INUIEditVoiceShortcutViewController, for addVoiceShortcutButton: INUIAddVoiceShortcutButton) {
        Analytics.logEvent("se3_add_to_siri_tapped", parameters: [
            "os_version": UIDevice.current.systemVersion,
            "mode": "edit",
            "shortcut": siriShortcut?.action.prefix(100) ?? ""
            ])
        
        editVoiceShortcutViewController.delegate = self
        editVoiceShortcutViewController.modalPresentationStyle = .formSheet
        present(editVoiceShortcutViewController, animated: true, completion: nil)
    }
}

extension MCReaderButtonsViewController : INUIAddVoiceShortcutViewControllerDelegate {
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        Analytics.logEvent("se3_add_to_siri_completed", parameters: [
            "os_version": UIDevice.current.systemVersion,
            "mode": "add",
            "shortcut": siriShortcut?.action.prefix(100) ?? ""
            ])
        dismiss(animated: true, completion: nil)
    }
    
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        Analytics.logEvent("se3_add_to_siri_cancelled", parameters: [
            "os_version": UIDevice.current.systemVersion,
            "mode": "add",
            "shortcut": siriShortcut?.action.prefix(100) ?? ""
            ])
        
        dismiss(animated: true, completion: nil)
    }
}


extension MCReaderButtonsViewController : INUIEditVoiceShortcutViewControllerDelegate {
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didUpdate voiceShortcut: INVoiceShortcut?, error: Error?) {
        Analytics.logEvent("se3_add_to_siri_completed", parameters: [
            "os_version": UIDevice.current.systemVersion,
            "mode": siriShortcut?.action.prefix(100) ?? ""
            ])
        
        dismiss(animated: true, completion: nil)
    }
    
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
        Analytics.logEvent("se3_add_to_siri_deleted", parameters: [
            "os_version": UIDevice.current.systemVersion,
            "mode": siriShortcut?.action.prefix(100) ?? ""
            ])
        
        dismiss(animated: true, completion: nil)
    }
    
    func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
        dismiss(animated: true, completion: nil)
    }
}
