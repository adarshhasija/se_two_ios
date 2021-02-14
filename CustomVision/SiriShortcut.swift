//
//  SiriShortcut.swift
//  Suno
//
//  Created by Adarsh Hasija on 13/02/21.
//  Copyright © 2021 Adam Behringer. All rights reserved.
//

import Foundation

class SiriShortcut {
    
    static var shortcutsDictionary : [Action : SiriShortcut] =
            [
                Action.TIME : SiriShortcut(dictionary:
                                            [
                                            "title": "Get the time in vibrations",
                                            "action": Action.TIME.rawValue,
                                            "invocation": "Get the current time in vibrations",
                                            "activityType": "com.starsearth.three.getTimeIntent"
                                            ]
                                    ),
                Action.DATE : SiriShortcut(dictionary:
                                            [
                                                "title": "Get the date in vibrations",
                                                "action": Action.DATE.rawValue,
                                                "invocation": "Get the date and day of the week in vibrations",
                                                "activityType": "com.starsearth.three.getDateDayOfWeekIntent"
                                            ]
                                    ),
                Action.CAMERA_OCR : SiriShortcut(dictionary:
                                            [
                                                "title": "Open the camera for text",
                                                "action": Action.CAMERA_OCR.rawValue,
                                                "invocation": "Get the text from the camera feed and read the text using vibrations",
                                                "activityType": "com.starsearth.three.getCameraIntent",
                                                "messageOnOpen": "Point your camera at the text\nWe will try to read it"
                                            ]
                                    )
            ]
    
    static func getInputs(action: Action) -> [String: String] {
        return
            [
                "inputAlphanumeric" : action == Action.TIME ? LibraryCustomActions.getCurrentTimeInAlphanumeric(format: "12") : LibraryCustomActions.getCurrentDateInAlphanumeric(),
                "inputMorseCode" : action == Action.TIME ? LibraryCustomActions.getCurrentTimeInDotsDashes() : LibraryCustomActions.getCurrentDateInDotsDashes(),
                "inputMCExplanation" : action == Action.TIME ? "Explanation:\nThere are 3 sets of characters.\nSet 1 is the hour.\nDash = long vibration = 5 hours.\nDot = short vibration = 1 hour.\nExample: 1 long vibration and 1 short vibration = 6.\nSet 2 is the minute.\nDash = 1 long vibration = 5 mins.\nDot = 1 short vobration = 1 min.\nExample: 1 long vibration and 1 short vibration = 6 minutes.\nLast set is AM or PM.\nShort vibration = AM.\nLong vibration = PM." : "Explanation:\nThere are 2 sets of characters.\nSet 1 is the date.\nDash = long vibration = 5 days.\nDot = short vibration = 1 day.\nExample: 1 long vibration and 1 short vibration = 6th.\nSet 2 is the day of the week.\nEvery dot is number of days after Sunday.\nExample: 2 short vibrations = Monday."
            ]
    }
    
    var title: String
    var action: String
    var invocation: String
    var activityType: String
    var messageOnOpen: String?
    var dictionary: [String: Any] {
        return [
                "title": title,
                "action": action,
                "invocation": invocation,
                "activity_type": activityType,
                "messageOnOpen": messageOnOpen
        ]
    }
    var nsDictionary: NSDictionary {
        return dictionary as NSDictionary
    }
    
 /*   init(title: String, action: String, invocation: String, activityType: String) {
        self.title = title
        self.action = action
        self.invocation = invocation
        self.activityType = activityType
    }   */
    
    init(dictionary: NSDictionary) {
        self.title = dictionary["title"] as? String ?? "Get the current time in vibrations"
        self.action = dictionary["action"] as? String ?? "TIME"
        self.invocation = dictionary["invocation"] as? String ?? "Get time in vibrations"
        self.activityType = dictionary["activity_type"] as? String ?? "com.starsearth.three.getTimeIntent"
        self.messageOnOpen = dictionary["message_on_open"] as? String
    }
}
