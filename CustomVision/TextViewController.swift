//
//  TextViewController.swift
//  CustomVision
//
//  Created by Adarsh Hasija on 10/03/23.
//  Copyright © 2023 Adam Behringer. All rights reserved.
//

import Foundation
import UIKit
import WatchConnectivity

//Morse code reader with buttons, no gestures
class TextViewController : UIViewController {
    
    var mText : String =  ""
    var mStartIndexForHighlighting : Int = -1
    var mEndIndexForHighlighting : Int = -1
    var braille : Braille? = nil //This is only used incase we get a Get from iPhone request on this screen from the watch
    lazy var supportsHaptics: Bool = {
            return (UIApplication.shared.delegate as? AppDelegate)?.supportsHaptics ?? false
        }()
    
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var previousCharacterButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var nextCharacterButton: UIButton!
    
    
    @IBAction func previousCharacterButtonTapped(_ sender: Any) {
        goToPreviousCharacterOrContraction()
    }
    
    
    @IBAction func doneButtonTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    @IBAction func nextCharacterButtonTapped(_ sender: Any) {
        goToNextCharacterOrContraction()
    }
    
    override func viewDidLoad() {
        if mStartIndexForHighlighting <= -1 || mStartIndexForHighlighting >= mText.count {
            mainLabel.text = mText
            return
        }
        if mEndIndexForHighlighting <= mStartIndexForHighlighting {
            mainLabel.text = mText
            return
        }
        
        MorseCodeUtils.setSelectedCharInLabel(inputString: mText, index: mStartIndexForHighlighting, length: (mEndIndexForHighlighting - mStartIndexForHighlighting), label: mainLabel, isMorseCode: false, color : UIColor.green)
    }
    
    func receivedRequestForAlphanumericsAndMCFromWatch(mode: String?) {
        sendEnglishAndBrailleToWatch()
    }
    
    func sendEnglishAndBrailleToWatch() {
        //If autoplay is on, we only send that. If its not on, we send all the indices to replicate on the watch
        if WCSession.isSupported() {
            let session = WCSession.default
            if session.isWatchAppInstalled && session.isReachable {
                session.sendMessage(braille?.getMapToSendToWatch() ?? [:], replyHandler: nil, errorHandler: nil)
            }
        }
    }
    
    func goToPreviousCharacterOrContraction() {
        //WE DONT WANT THIS RIGHT NOW as we dont want the user to go offf the end. Where they end up will then be setup on the previous screen so we dont want that
     /*   if startIndexForHighlighting <= 0 {
            //before the start
            label.setText(fullText) //remove highlights
            startIndexForHighlighting = 0
            endIndexForHighlighting = 0
            WKInterfaceDevice.current().play(.success)
            return
        }   */
        
        let fullText : String = mainLabel.text ?? ""
        if mStartIndexForHighlighting <= 0 {
            //reached the start
            let hapticManager = HapticManager(supportsHaptics: supportsHaptics)
            hapticManager.generateErrorHaptic()
            return
        }
        else if mEndIndexForHighlighting > fullText.count {
            //At the end or way beyond the end
            let exactWord = braille?.arrayBrailleGridsForCharsInWord.last?.english ?? ""
            mStartIndexForHighlighting = (fullText.count - exactWord.count)
            mEndIndexForHighlighting = fullText.count
        }
        else {
            //we have convered the ends in above conditions. so we should not hit index out of bounds
            let prevIndex = mStartIndexForHighlighting - 1
            let isPrevCharSpace = fullText[fullText.index(fullText.startIndex, offsetBy: prevIndex)].isWhitespace
            if isPrevCharSpace {
                let dictionary = braille?.getPreviousWord() ?? [:]
                let alphanumericString = dictionary["alphanumeric_string"] ?? ""
                let lastCharacterOrContractionInWord = braille?.arrayBrailleGridsForCharsInWord[braille?.arrayBrailleGridsForCharsInWordIndex ?? 0].english ?? ""
                mStartIndexForHighlighting -= 1 //there will be a space so account for that
                mStartIndexForHighlighting -= lastCharacterOrContractionInWord.count //move back by the word length
                mEndIndexForHighlighting = mStartIndexForHighlighting + lastCharacterOrContractionInWord.count
            }
            else {
                //in the middle of a word. move to the previous character
                braille?.goToPreviousCharacterOrContraction() //This does the processing. we dont need the result
                let lastCharacterOrContraction = braille?.arrayBrailleGridsForCharsInWord[braille?.arrayBrailleGridsForCharsInWordIndex ?? 0].english ?? ""
                mStartIndexForHighlighting -= lastCharacterOrContraction.count
                mEndIndexForHighlighting = mStartIndexForHighlighting + lastCharacterOrContraction.count
            }
        }
        MorseCodeUtils.setSelectedCharInLabel(inputString: fullText, index: mStartIndexForHighlighting, length: mEndIndexForHighlighting - mStartIndexForHighlighting, label: mainLabel, isMorseCode: false, color: UIColor.green)
        let hapticManager = HapticManager(supportsHaptics: supportsHaptics)
        hapticManager.generateStandardResponseHaptic()
        braille?.mIndex = 0 //doing this because when we go back to previous screen it will set the user at the top left off the grid
    }
    
    func goToNextCharacterOrContraction() {
        //WE DONT WANT THIS RIGHT NOW as we dont want the user to go offf the end. Where they end up will then be setup on the previous screen so we dont want that
    /*    if endIndexForHighlighting >= fullText.count {
            //We are way beyond the end.
            braille?.arrayBrailleGridsForCharsInWordIndex = braille?.arrayBrailleGridsForCharsInWord.count ?? 0 //This is needed else app crashes when scrolling backwards
            label.setText(fullText)
            startIndexForHighlighting = fullText.count
            endIndexForHighlighting = fullText.count
            WKInterfaceDevice.current().play(.success)
            return
        }   */
        let fullText : String = mainLabel.text ?? ""
        if mEndIndexForHighlighting > fullText.count - 1 {
            //we are at the end
            let hapticManager = HapticManager(supportsHaptics: supportsHaptics)
            hapticManager.generateErrorHaptic()
            return
        }
        else if mStartIndexForHighlighting < 0 {
            //before the start
            mStartIndexForHighlighting = 0
            let exactWordOrContraction = braille?.arrayBrailleGridsForCharsInWord.first?.english ?? ""
            mEndIndexForHighlighting = mStartIndexForHighlighting + exactWordOrContraction.count
        }
        else if mStartIndexForHighlighting == 0
                    && mStartIndexForHighlighting == mEndIndexForHighlighting {
            // cursor is at first character. user likely went to braille screen then came directly here
            let exactWordOrContraction = braille?.arrayBrailleGridsForCharsInWord.first?.english ?? ""
            mEndIndexForHighlighting = mStartIndexForHighlighting + exactWordOrContraction.count
        }
        else {
            //we have convered the ends in above conditions. so we should not hit index out of bounds
            let isNextCharSpace = fullText[fullText.index(fullText.startIndex, offsetBy: mEndIndexForHighlighting)].isWhitespace
            if isNextCharSpace {
                //end of word. move to next word
                let dictionary = braille?.getNextWord() ?? [:]
                let alphanumericString = dictionary["alphanumeric_string"] ?? ""
                let firstCharacterOrContractionInWord = braille?.arrayBrailleGridsForCharsInWord.first?.english ?? ""
                mStartIndexForHighlighting +=
                                    (mEndIndexForHighlighting - mStartIndexForHighlighting) //the contraction that was currently highlighted
                                    + 1 //space at the end of the word
                mEndIndexForHighlighting = mStartIndexForHighlighting + firstCharacterOrContractionInWord.count //cover the distance of the contraction
            }
            else {
                //in the middle of a word. move to the next contraction
                braille?.goToNextCharacterOrContraction() //This does the processing. we dont need the result
                let nextCharacterOrContraction = braille?.arrayBrailleGridsForCharsInWord[braille?.arrayBrailleGridsForCharsInWordIndex ?? 0].english ?? ""
                let prevWordLength = mEndIndexForHighlighting - mStartIndexForHighlighting
                mStartIndexForHighlighting += prevWordLength
                mEndIndexForHighlighting = mStartIndexForHighlighting + nextCharacterOrContraction.count
            }
        }
        MorseCodeUtils.setSelectedCharInLabel(inputString: fullText, index: mStartIndexForHighlighting, length: mEndIndexForHighlighting - mStartIndexForHighlighting, label: mainLabel, isMorseCode: false, color: UIColor.green)
        let hapticManager = HapticManager(supportsHaptics: supportsHaptics)
        hapticManager.generateStandardResponseHaptic()
        braille?.mIndex = 0 //doing this because when we go back to previous screen it will set the user at the top left off the grid
    }
    
}
