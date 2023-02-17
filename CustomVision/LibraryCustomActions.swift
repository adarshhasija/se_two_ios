//
//  LibraryCustomActions.swift
//  Suno
//
//  Created by Adarsh Hasija on 21/10/20.
//  Copyright © 2020 Adam Behringer. All rights reserved.
//

import Foundation


class LibraryCustomActions {
    
    static func getCurrentTimeInAlphanumeric(format : String) -> String {
        var hh = (Calendar.current.component(.hour, from: Date()))
        let mm = (Calendar.current.component(.minute, from: Date()))
        var alphanumericString = ""
        if format == "12" {
            let amPm = hh > 11 ? "PM" : "AM"
            hh = hh > 12 ? hh - 12 : hh == 0 ? 12 : hh
            let minString = mm < 10 ? "0" + String(mm) : String(mm)
            alphanumericString = String(hh) + ":" + minString + " " + amPm
        }
        else if format == "24" {
            let hourString = hh < 10 ? "0" + String(hh) : String(hh)
            let minString = mm < 10 ? "0" + String(mm) : String(mm)
            alphanumericString = hourString + minString
        }
        
        return alphanumericString
    }
    
    //Currently we need only the date and day of week
    static func getCurrentDateInAlphanumeric() -> String {
        let day = (Calendar.current.component(.day, from: Date()))
        let weekdayInt = (Calendar.current.component(.weekday, from: Date()))
        let weekdayString = Calendar.current.weekdaySymbols[weekdayInt - 1]
        //let alphanumericString = String(day) + weekdayString.prefix(2).uppercased() //Use this if converting it to morse code as wel want a shorter string
        let alphanumericString = String(day) + " " + weekdayString.uppercased() //Use this if converting it to customized dots and dashes
        return alphanumericString
    }
    
    static func getCurrentTimeInDotsDashes() -> [String:Any] {
        let hh24 = (Calendar.current.component(.hour, from: Date()))
        let hh12 = hh24 > 12 ? hh24 - 12 : hh24 == 0 ? 12 : hh24
        let amPm = hh24 > 11 ? "PM" : "AM"
        let hoursDashes : Int = hh12/5
        let hoursDots = hh12 - (hoursDashes*5)
        let mm = (Calendar.current.component(.minute, from: Date()))
        let minsDashes : Int = mm/5
        let minsDots = mm - (minsDashes*5)
        var finalMorseCodeString = ""
        var finalInstructionStringArray : [String] = []
        var i = 0
        while (i < hoursDashes) {
            finalMorseCodeString = finalMorseCodeString + "-"
            finalInstructionStringArray.append("+5 hrs")
            i = i + 1
        }
        i = 0
        while (i < hoursDots) {
            finalMorseCodeString = finalMorseCodeString + "."
            finalInstructionStringArray.append("+1 hr")
            i = i + 1
        }
        finalMorseCodeString = finalMorseCodeString + "|"
        finalInstructionStringArray.append("= " + String(hh12) + " " + "hrs")
        i = 0
        while i < minsDashes {
            finalMorseCodeString = finalMorseCodeString + "-"
            finalInstructionStringArray.append("+5 mins")
            i = i + 1
        }
        i = 0
        while i < minsDots {
            finalMorseCodeString = finalMorseCodeString + "."
            finalInstructionStringArray.append("+1 min")
            i = i + 1
        }
        finalMorseCodeString = finalMorseCodeString + "|"
        finalInstructionStringArray.append("= " + String(mm) + " " + "mins")
        finalMorseCodeString = finalMorseCodeString + (amPm == "PM" ? "-" : ".")
        finalInstructionStringArray.append(amPm)
        finalMorseCodeString = finalMorseCodeString + "|"
        finalInstructionStringArray.append("✓")
        return
                [
                    "morse_code" : finalMorseCodeString,
                    "instructions" : finalInstructionStringArray
                ]
    }
    
    static func getCurrentDateInDotsDashes() -> [String:Any] {
        let day = (Calendar.current.component(.day, from: Date()))
        let dayDashes : Int = day/5
        let dayDots : Int = day - (dayDashes*5)
        let weekdayInt = (Calendar.current.component(.weekday, from: Date()))
        var finalMorseCodeString = ""
        var finalInstructionStringArray : [String] = []
        var i = 0
        while (i < dayDashes) {
            finalMorseCodeString = finalMorseCodeString + "-"
            finalInstructionStringArray.append("+5 days")
            i = i + 1
        }
        i = 0
        while (i < dayDots) {
            finalMorseCodeString = finalMorseCodeString + "."
            finalInstructionStringArray.append("+1 day")
            i = i + 1
        }
        finalMorseCodeString = finalMorseCodeString + "|"
        finalInstructionStringArray.append("= " + String(day))
        i = 0
        while (i < weekdayInt) {
            finalMorseCodeString = finalMorseCodeString + "."
            i = i + 1
            finalInstructionStringArray.append(((i <= 1) ? "Sunday" : "Sunday + " + String(i-1))) //Sunday is 1, so need to -1
        }
        finalMorseCodeString = finalMorseCodeString + "|"
        let weekdayString = Calendar.current.weekdaySymbols[weekdayInt - 1]
        finalInstructionStringArray.append("= " + weekdayString)
        return
            [
                "morse_code" : finalMorseCodeString,
                "instructions" : finalInstructionStringArray
            ]
    }
    
    static func getBatteryLevelInDotsDashes(batteryLevel : Int) -> [String:Any] {
        let dashes : Int = batteryLevel/5
        let dots : Int = batteryLevel - (dashes*5)
        var finalMorseCodeString = ""
        var finalInstructionStringArray : [String] = []
        var i = 0
        while (i < dashes) {
            finalMorseCodeString = finalMorseCodeString + "-"
            finalInstructionStringArray.append("+5")
            i = i + 1
        }
        i = 0
        while (i < dots) {
            finalMorseCodeString = finalMorseCodeString + "."
            finalInstructionStringArray.append("+1")
            i = i + 1
        }
        finalMorseCodeString = finalMorseCodeString + "|"
        finalInstructionStringArray.append(String(batteryLevel) + "%") //Not using = as it takes too long for VoiceOver to say
        return
            [
                "morse_code" : finalMorseCodeString,
                "instructions" : finalInstructionStringArray
            ]
    }
    
    static func getIntegerInDotsAndDashes(integer: Int) -> String {
        let dashes : Int = integer/5
        let dots : Int = integer - (dashes*5)
        var finalMorseCodeString = ""
        var finalInstructionStringArray : [String] = [] //Not needed right now but keeping for future
        var i = 0
        while (i < dashes) {
            finalMorseCodeString = finalMorseCodeString + "-"
            i = i + 1
        }
        i = 0
        while (i < dots) {
            finalMorseCodeString = finalMorseCodeString + "."
            i = i + 1
        }
        return finalMorseCodeString
    }
    
    static func getInfoTextForWholeNumber(morseCodeString : String, morseCodeStringIndex: Int, currentAlphanumericChar : String) -> String? {
        //current character is a number
        //next set the middle text based on morse code character
        let curMCChar = morseCodeString[morseCodeString.index(morseCodeString.startIndex, offsetBy:  morseCodeStringIndex >= 0 ? morseCodeStringIndex : 0)]
        let text = curMCChar == "." ? "+1"
                    : curMCChar == "-" ? "+5"
                    : curMCChar == "|" || curMCChar == " " ? "= " + currentAlphanumericChar //Means we have reached the end of a character
                    : nil
        
        return text
    }
    
    static func getInfoTextForMorseCode(morseCodeString : String, morseCodeStringIndex: Int) -> String? {
        var text : String? = nil
        if morseCodeStringIndex == 0 {
            text = "morse code"
        }
        else {
            //We are somewhere in the middle
            let prevMCChar = morseCodeString[morseCodeString.index(morseCodeString.startIndex, offsetBy:  morseCodeStringIndex > 0 ? morseCodeStringIndex - 1 : morseCodeStringIndex)]
            if prevMCChar == "|" || prevMCChar == " " {
                //means that we are starting a new character
                text = "morse code"
            }
        }
        return text
    }
    
    static func getInfoTextForBraille(brailleString : String, brailleStringIndex: Int) -> String? {
        var text : String? = nil
        let index = brailleString.index(brailleString.startIndex, offsetBy: brailleStringIndex)
        
        //Get the braille grid number
        let b = brailleString.count > 10 ? Braille.mappingBrailleGridNumbersToStringIndex.filter {  $0.value == brailleStringIndex } : Braille.mappingBrailleGridToStringIndex.filter {$0.value == brailleStringIndex}
        let brailleGridNumber = b.keys.first!
        //
        
        let character = brailleString[index]
        if character == "x" {
            if brailleGridNumber >  6 {
                let adjustedNumber = brailleGridNumber - 6
                text = String(adjustedNumber) + " = No"
            }
            else {
                text = String(brailleGridNumber) + " = No"
            }
        }
        if character == "o" {
            if brailleGridNumber >  6 {
                let adjustedNumber = brailleGridNumber - 6
                text = String(adjustedNumber) + " = Yes"
            }
            else {
                text = String(brailleGridNumber) + " = Yes"
            }
        }
        return text
    }
    
}
