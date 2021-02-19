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
            finalInstructionStringArray.append("+5 min")
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
            finalInstructionStringArray.append("+1 days")
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
}
