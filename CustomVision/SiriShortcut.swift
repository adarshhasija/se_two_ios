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
                                            "activity_type": "com.starsearth.three.getTimeIntent"
                                            ]
                                    ),
                Action.DATE : SiriShortcut(dictionary:
                                            [
                                                "title": "Get the date in vibrations",
                                                "action": Action.DATE.rawValue,
                                                "invocation": "Get the date and day of the week in vibrations",
                                                "activity_type": "com.starsearth.three.getDateDayOfWeekIntent"
                                            ]
                                    ),
                Action.CAMERA_OCR : SiriShortcut(dictionary:
                                            [
                                                "title": "Open the camera for text",
                                                "action": Action.CAMERA_OCR.rawValue,
                                                "invocation": "Get the text from the camera feed and read the text using vibrations",
                                                "activity_type": "com.starsearth.three.getCameraIntent",
                                                "message_on_open": "Point your camera at the text\nWe will try to read it"
                                            ]
                                    )
            ]
    
    enum INPUT_FIELDS: String {
        case input_alphanumerics
        case input_morse_code
        case input_mc_explanation
    }
    
    static func getInputs(action: Action) -> [String: Any] {
        var dictionary : [String : Any] = [:]
        dictionary[INPUT_FIELDS.input_alphanumerics.rawValue] =
                            action == Action.TIME ? String(LibraryCustomActions.getCurrentTimeInAlphanumeric(format: "12")) : String(LibraryCustomActions.getCurrentDateInAlphanumeric())
        dictionary[INPUT_FIELDS.input_morse_code.rawValue] =
                            action == Action.TIME ?         LibraryCustomActions.getCurrentTimeInDotsDashes()["morse_code"] : LibraryCustomActions.getCurrentDateInDotsDashes()["morse_code"]
        dictionary[INPUT_FIELDS.input_mc_explanation.rawValue] =
                            action == Action.TIME ? LibraryCustomActions.getCurrentTimeInDotsDashes()["instructions"] : LibraryCustomActions.getCurrentDateInDotsDashes()["instructions"]
          /*  [
                "inputAlphanumeric" : action == Action.TIME ? String(LibraryCustomActions.getCurrentTimeInAlphanumeric(format: "12")) : String(LibraryCustomActions.getCurrentDateInAlphanumeric()),
                "inputMorseCode" : action == Action.TIME ? String(LibraryCustomActions.getCurrentTimeInDotsDashes()["morse_code"]) : String(LibraryCustomActions.getCurrentDateInDotsDashes()["morse_code"]),
                "inputMCExplanation" : action == Action.TIME ? Array(LibraryCustomActions.getCurrentTimeInDotsDashes()["instructions"]) : Array(LibraryCustomActions.getCurrentDateInDotsDashes()["instructions"])
            ]   */
        return dictionary
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
                "message_on_open": messageOnOpen
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
