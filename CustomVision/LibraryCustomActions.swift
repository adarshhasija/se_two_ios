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
    
    static func getCurrentTimeInDotsDashes() -> String {
        let hh24 = (Calendar.current.component(.hour, from: Date()))
        let hh12 = hh24 > 12 ? hh24 - 12 : hh24 == 0 ? 12 : hh24
        let amPm = hh24 > 11 ? "PM" : "AM"
        let hoursDashes : Int = hh12/5
        let hoursDots = hh12 - (hoursDashes*5)
        let mm = (Calendar.current.component(.minute, from: Date()))
        let minsDashes : Int = mm/5
        let minsDots = mm - (minsDashes*5)
        var finalString = ""
        var i = 0
        while (i < hoursDashes) {
            finalString = finalString + "-"
            i = i + 1
        }
        i = 0
        while (i < hoursDots) {
            finalString = finalString + "."
            i = i + 1
        }
        finalString = finalString + "|"
        i = 0
        while i < minsDashes {
            finalString = finalString + "-"
            i = i + 1
        }
        i = 0
        while i < minsDots {
            finalString = finalString + "."
            i = i + 1
        }
        finalString = finalString + "|"
        finalString = finalString + (amPm == "PM" ? "-" : ".")
        finalString = finalString + "|"
        return finalString
    }
    
    static func getCurrentDateInDotsDashes() -> String {
        let day = (Calendar.current.component(.day, from: Date()))
        let dayDashes : Int = day/5
        let dayDots : Int = day - (dayDashes*5)
        let weekdayInt = (Calendar.current.component(.weekday, from: Date()))
        var finalString = ""
        var i = 0
        while (i < dayDashes) {
            finalString = finalString + "-"
            i = i + 1
        }
        i = 0
        while (i < dayDots) {
            finalString = finalString + "."
            i = i + 1
        }
        finalString = finalString + "|"
        i = 0
        while (i < weekdayInt) {
            finalString = finalString + "."
            i = i + 1
        }
        return finalString
    }
}
