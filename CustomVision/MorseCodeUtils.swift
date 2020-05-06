//
//  MorseCodeUtils.swift
//  Suno
//
//  Created by Adarsh Hasija on 19/03/20.
//  Copyright © 2020 Adam Behringer. All rights reserved.
//

import Foundation
import UIKit

class MorseCodeUtils {
    
    //Sets the particular character to green to indicate selected
    //If the index is out of bounds, the entire string will come white. eg: when index = -1
    static func setSelectedCharInLabel(inputString : String, index : Int, label : UILabel, isMorseCode : Bool, color : UIColor) {
      /*  let range = NSRange(location:index,length:1) // specific location. This means "range" handle 1 character at location 2
        
        //The replacement of space with visible space only applies to english strings
        let attributedString = NSMutableAttributedString(string: inputString, attributes: nil)
        // here you change the character to green color
        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: range)
        if isMorseCode {
            attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 25), range: range)
        }
        label.attributedText = attributedString */
        label.attributedText = getSelectedAttributedString(inputString: inputString, index: index, isMorseCode: isMorseCode, color: color)
    }
    
    //Sets the particular character to green to indicate selected
    //If the index is out of bounds, the entire string will come white. eg: when index = -1
    static func setSelectedCharInTextView(inputString : String, index : Int, textView : UITextView, isMorseCode : Bool, color : UIColor) {
      /*  let range = NSRange(location:index,length:1) // specific location. This means "range" handle 1 character at location 2
        
        //The replacement of space with visible space only applies to english strings
        let attributedString = NSMutableAttributedString(string: inputString, attributes: nil)
        // here you change the character to green color
        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: range)
        if isMorseCode {
            attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 25), range: range)
        }
        textView.attributedText = attributedString  */
        textView.attributedText = getSelectedAttributedString(inputString: inputString, index: index, isMorseCode: isMorseCode, color: color)
    }
    
    static func getSelectedAttributedString(inputString : String, index : Int, isMorseCode : Bool, color : UIColor) -> NSAttributedString {
        let range = NSRange(location:index,length:1) // specific location. This means "range" handle 1 character at location 2
        
        //The replacement of space with visible space only applies to english strings
        let attributedString = NSMutableAttributedString(string: inputString, attributes: nil)
        // here you change the character to green color
        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: range)
        if isMorseCode {
            attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 40), range: range)
        }
        
        return attributedString
    }
    
    static func isEngCharSpace(englishString : String, englishStringIndex : Int) -> Bool {
        let index = englishString.index(englishString.startIndex, offsetBy: englishStringIndex)
        let char = String(englishString[index])
        if char == " " {
            return true
        }
        return false
    }
    
    //This function tells us if the previous char was a pipe. It is a sign to change the character in the English string
    static func isPrevMCCharPipe(input : String, currentIndex : Int, isReverse : Bool) -> Bool {
        var retVal = false
        if isReverse {
            if currentIndex < input.count - 1 {
                //To ensure the next character down exists
                let index = input.index(input.startIndex, offsetBy: currentIndex)
                let char = String(input[index])
                let prevIndex = input.index(input.startIndex, offsetBy: currentIndex + 1)
                let prevChar = String(input[prevIndex])
                retVal = char != "|" && prevChar == "|"
            }
        }
        else if currentIndex > 0 {
            //To ensure the previous character exists
            let index = input.index(input.startIndex, offsetBy: currentIndex)
            let char = String(input[index])
            let prevIndex = input.index(input.startIndex, offsetBy: currentIndex - 1)
            let prevChar = String(input[prevIndex])
            retVal = char != "|" && prevChar == "|"
        }
        
        return retVal
    }
    
    static func playSelectedCharacterHaptic(inputString : String, inputIndex : Int) {
        let index = inputString.index(inputString.startIndex, offsetBy: inputIndex)
        let char = String(inputString[index])
        if char == "." {
            //WKInterfaceDevice.current().play(.start)
        }
        if char == "-" {
            //WKInterfaceDevice.current().play(.stop)
        }
        if char == "|" {
            //WKInterfaceDevice.current().play(.success)
        }
    }
}
