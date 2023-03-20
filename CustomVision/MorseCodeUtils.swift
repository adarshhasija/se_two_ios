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
    static func setSelectedCharInLabel(inputString : String, index : Int, length: Int, label : UILabel, isMorseCode : Bool, color : UIColor) {
      /*  let range = NSRange(location:index,length:1) // specific location. This means "range" handle 1 character at location 2
        
        //The replacement of space with visible space only applies to english strings
        let attributedString = NSMutableAttributedString(string: inputString, attributes: nil)
        // here you change the character to green color
        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: range)
        if isMorseCode {
            attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 25), range: range)
        }
        label.attributedText = attributedString */
        label.attributedText = getSelectedAttributedString(inputString: inputString, index: index, length: length, isMorseCode: isMorseCode, color: color)
    }
    
    //Sets the particular character to green to indicate selected
    //If the index is out of bounds, the entire string will come white. eg: when index = -1
    static func setSelectedCharInTextView(inputString : String, index : Int, textView : UITextView, length: Int?, isMorseCode : Bool, color : UIColor) {
      /*  let range = NSRange(location:index,length:1) // specific location. This means "range" handle 1 character at location 2
        
        //The replacement of space with visible space only applies to english strings
        let attributedString = NSMutableAttributedString(string: inputString, attributes: nil)
        // here you change the character to green color
        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: range)
        if isMorseCode {
            attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 25), range: range)
        }
        textView.attributedText = attributedString  */
        textView.attributedText = getSelectedAttributedString(inputString: inputString, index: index, length: length != nil ? length : 1, isMorseCode: isMorseCode, color: color)
    }
    
    static func getSelectedAttributedString(inputString : String, index : Int, length: Int?, isMorseCode : Bool, color : UIColor) -> NSAttributedString {
        let range = NSRange(location:index,length: length != nil ? length! : 1) // specific location. This means "range" handle 1 character at location 2
        
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
    
    //This function tells us if the previous char was a pipe or space.
    //In normal scrolling mode we use pipes
    //In Autoplay we use space, as we do not want to play haptic for end of character
    //It is a sign to change the character in the English string
    static func isPrevMCCharPipeOrSpace(input : String, currentIndex : Int, isReverse : Bool) -> Bool {
        var retVal = false
        var isCurAlphanumericZero = false //A zero does not have have a dot/dash. Pipe followed by pipe or space followed by space
        //isReverse is not really used in iOS at the moment but we are keeping it just in case
        if isReverse {
            if currentIndex < input.count - 1 {
                //To ensure the next character down exists
                let index = input.index(input.startIndex, offsetBy: currentIndex)
                let char = String(input[index])
                let prevIndex = input.index(input.startIndex, offsetBy: currentIndex + 1)
                let prevChar = String(input[prevIndex])
                retVal = (char != "|" && prevChar == "|") || (char != " " && prevChar == " ")
                isCurAlphanumericZero = (char == "|" && prevChar == "|") || (char == " " && prevChar == " ")
            }
        }
        else if currentIndex > 0 {
            //To ensure the previous character exists
            let index = input.index(input.startIndex, offsetBy: currentIndex)
            let char = String(input[index])
            let prevIndex = input.index(input.startIndex, offsetBy: currentIndex - 1)
            let prevChar = String(input[prevIndex])
            retVal = (char != "|" && prevChar == "|") || (char != " " && prevChar == " ")
            
            isCurAlphanumericZero = (char == "|" && prevChar == "|") || (char == " " && prevChar == " ")
        }
        
        return retVal || isCurAlphanumericZero
    }

}
