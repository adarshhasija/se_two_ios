//
//  TextInterfaceController.swift
//  Suno-Watch Extension
//
//  Created by Adarsh Hasija on 09/03/23.
//  Copyright © 2023 Adam Behringer. All rights reserved.
//

import Foundation
import WatchKit
import WatchConnectivity

class TextInterfaceController : WKInterfaceController {
    
    @IBOutlet weak var label: WKInterfaceLabel!
    
    var braille : Braille? = nil
    var startIndexForHighlighting : Int = -1
    var endIndexForHighlighting : Int = -1
    var fullText : String = ""
    
    ///Digital crown related
    let expectedMoveDelta = 0.523599 //Here, current delta value = 30° Degree, Set delta value according requirement.
    var crownRotationalDelta = 0.0
    var startTimeNanos : UInt64 = 0 //Used to calculate speed of crown rotation
    var quickScrollTimeThreshold = 700000000 //If the digital crown is scrolled 30 degrees within this many nano seconds, we go into autoplay
    
    override func awake(withContext context: Any?) {
        let dictionary = context as? NSDictionary
        if dictionary != nil {
            fullText = dictionary!["text"] as? String ?? ""
            startIndexForHighlighting = dictionary!["start_index"] as? Int ?? -1
            endIndexForHighlighting = dictionary!["end_index"] as? Int ?? -1
            if startIndexForHighlighting < 0 || startIndexForHighlighting >= fullText.count {
                label.setText(fullText)
                return
            }
            setSelectedCharInLabel(inputString: fullText, index: startIndexForHighlighting, length: endIndexForHighlighting - startIndexForHighlighting, label: label, isMorseCode: false, color: UIColor.green)
            
            braille = dictionary!["braille"] as? Braille ?? Braille()
        }
    }
    
    override func willActivate() {
    //    self.crownSequencer.delegate = self //It works but it is also impacting previous screen because we are using the Braille object
    //    self.crownSequencer.focus()
    }
    
    func goToPreviousCharacterOrContraction() {
        if endIndexForHighlighting > fullText.count {
            //At the end or way beyond the end
            let exactWord = braille?.arrayBrailleGridsForCharsInWord.last?.english ?? ""
            startIndexForHighlighting = (fullText.count - exactWord.count)
            endIndexForHighlighting = fullText.count
        }
        else if startIndexForHighlighting <= 0 {
            //before the start
            label.setText(fullText) //remove highlights
            startIndexForHighlighting = 0
            endIndexForHighlighting = 0
            WKInterfaceDevice.current().play(.success)
            return
        }
        else {
            //we have convered the ends in above conditions. so we should not hit index out of bounds
            let prevIndex = startIndexForHighlighting - 1
            let isPrevCharSpace = fullText[fullText.index(fullText.startIndex, offsetBy: prevIndex)].isWhitespace
            if isPrevCharSpace {
                let dictionary = braille?.getPreviousWord() ?? [:]
                let alphanumericString = dictionary["alphanumeric_string"] ?? ""
                let lastCharacterOrContractionInWord = braille?.arrayBrailleGridsForCharsInWord[braille?.arrayBrailleGridsForCharsInWordIndex ?? 0].english ?? ""
                startIndexForHighlighting -= 1 //there will be a space so account for that
                startIndexForHighlighting -= lastCharacterOrContractionInWord.count //move back by the word length
                endIndexForHighlighting = startIndexForHighlighting + lastCharacterOrContractionInWord.count
            }
            else {
                //in the middle of a word. move to the previous character
                braille?.goToPreviousCharacterOrContraction() //This does the processing. we dont need the result
                let lastCharacterOrContraction = braille?.arrayBrailleGridsForCharsInWord[braille?.arrayBrailleGridsForCharsInWordIndex ?? 0].english ?? ""
                startIndexForHighlighting -= lastCharacterOrContraction.count
                endIndexForHighlighting = startIndexForHighlighting + lastCharacterOrContraction.count
            }
        }
        setSelectedCharInLabel(inputString: fullText, index: startIndexForHighlighting, length: endIndexForHighlighting - startIndexForHighlighting, label: label, isMorseCode: false, color: UIColor.green)
        WKInterfaceDevice.current().play(.start)
    }
    
    func goToNextCharacterOrContraction() {
        if endIndexForHighlighting >= fullText.count {
            //We are way beyond the end
            braille?.arrayBrailleGridsForCharsInWordIndex = braille?.arrayBrailleGridsForCharsInWord.count ?? 0 //This is needed else app crashes when scrolling backwards
            label.setText(fullText)
            startIndexForHighlighting = fullText.count
            endIndexForHighlighting = fullText.count
            WKInterfaceDevice.current().play(.success)
            return
        }
        else if startIndexForHighlighting < 0 {
            //before the start
            startIndexForHighlighting = 0
            let exactWordOrContraction = braille?.arrayBrailleGridsForCharsInWord.first?.english ?? ""
            endIndexForHighlighting = startIndexForHighlighting + exactWordOrContraction.count
        }
        else if startIndexForHighlighting == 0
                    && startIndexForHighlighting == endIndexForHighlighting {
            // cursor is at first character. user likely went to braille screen then came directly here
            let exactWordOrContraction = braille?.arrayBrailleGridsForCharsInWord.first?.english ?? ""
            endIndexForHighlighting = startIndexForHighlighting + exactWordOrContraction.count
        }
        else {
            //we have convered the ends in above conditions. so we should not hit index out of bounds
            let isNextCharSpace = fullText[fullText.index(fullText.startIndex, offsetBy: endIndexForHighlighting)].isWhitespace
            if isNextCharSpace {
                //end of word. move to next word
                let dictionary = braille?.getNextWord() ?? [:]
                let alphanumericString = dictionary["alphanumeric_string"] ?? ""
                let firstCharacterOrContractionInWord = braille?.arrayBrailleGridsForCharsInWord.first?.english ?? ""
                startIndexForHighlighting +=
                                    (endIndexForHighlighting - startIndexForHighlighting) //the contraction that was currently highlighted
                                    + 1 //space at the end of the word
                endIndexForHighlighting = startIndexForHighlighting + firstCharacterOrContractionInWord.count //cover the distance of the contraction
            }
            else {
                //in the middle of a word. move to the next contraction
                braille?.goToNextCharacterOrContraction() //This does the processing. we dont need the result
                let nextCharacterOrContraction = braille?.arrayBrailleGridsForCharsInWord[braille?.arrayBrailleGridsForCharsInWordIndex ?? 0].english ?? ""
                let prevWordLength = endIndexForHighlighting - startIndexForHighlighting
                startIndexForHighlighting += prevWordLength
                endIndexForHighlighting = startIndexForHighlighting + nextCharacterOrContraction.count
            }
        }
        setSelectedCharInLabel(inputString: fullText, index: startIndexForHighlighting, length: endIndexForHighlighting - startIndexForHighlighting, label: label, isMorseCode: false, color: UIColor.green)
        WKInterfaceDevice.current().play(.start)
    }
    
    //Sets the particular character to green to indicate selected
    //If the index is out of bounds, the entire string will come white. eg: when index = -1
    func setSelectedCharInLabel(inputString : String, index : Int, length: Int?, label : WKInterfaceLabel, isMorseCode : Bool, color : UIColor) {
        let range = NSRange(location:index,length: length != nil ? length! : 1) // specific location. This means "range" handle 1 character at location 2
        
        //The replacement of space with visible space only applies to english strings
        let attributedString = NSMutableAttributedString(string: inputString, attributes: nil)
        // here you change the character to green color
        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: range)
        if isMorseCode {
            attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 25), range: range)
        }
        label.setAttributedText(attributedString)
    }
}

extension TextInterfaceController : WKCrownDelegate {
    
    func crownDidRotate(_ crownSequencer: WKCrownSequencer?, rotationalDelta: Double) {
        crownRotationalDelta  += rotationalDelta
        
        if crownRotationalDelta < -expectedMoveDelta {
            //downward scroll
            crownRotationalDelta = 0.0
            let endTime = DispatchTime.now()
            let diffNanos = endTime.uptimeNanoseconds - startTimeNanos
            if diffNanos > quickScrollTimeThreshold {
                //30 degree completed
                startTimeNanos = DispatchTime.now().uptimeNanoseconds //Update this so we can do a check on the next rotation
                goToNextCharacterOrContraction()
            }
        }
        else if crownRotationalDelta > expectedMoveDelta {
            crownRotationalDelta = 0.0
            let endTime = DispatchTime.now()
            let diffNanos = endTime.uptimeNanoseconds - startTimeNanos
            if diffNanos > quickScrollTimeThreshold {
                startTimeNanos = DispatchTime.now().uptimeNanoseconds //Update this so we can do a check on the next rotation
                goToPreviousCharacterOrContraction()
            }
        }
    }
}
