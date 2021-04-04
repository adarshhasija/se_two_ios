//
//  SiriShortcut.swift
//  Suno
//
//  Created by Adarsh Hasija on 13/02/21.
//  Copyright © 2021 Adam Behringer. All rights reserved.
//

import Foundation
import Intents

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
                                    ),
                Action.BATTERY_LEVEL : SiriShortcut(dictionary:
                                            [
                                                "title": "Get the battery level in vibrations",
                                                "action": Action.BATTERY_LEVEL.rawValue,
                                                "invocation": "Get the battery level in vibrations",
                                                "activity_type": "com.starsearth.three.getBatteryLevelIntent"
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
    
    //Using acitivites instead of intents as Siri opens app directly for activity. For intents, it shows button to open app, which we do not want s
    //This is being used in this file as it could be used by multiple targets (eg: iOS and watchOS)
    //This has to be called from the View Controller where it takes place because the Add to Siri button must be setup there
    // isAccessibilityElement is not set here because it is an iOS thing. It is set in iOS controllers
    static func createINShortcutAndAddToSiriWatchFace(siriShortcut: SiriShortcut) -> INShortcut {
        let activity = NSUserActivity(activityType: siriShortcut.activityType)
        activity.title = siriShortcut.title
        activity.userInfo = siriShortcut.dictionary
        activity.suggestedInvocationPhrase = siriShortcut.invocation
        activity.persistentIdentifier = siriShortcut.activityType
        activity.isEligibleForHandoff = true
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        activity.becomeCurrent()
        let inShortcut = INShortcut(userActivity: activity)
        addShortcutToSiriWatchFace(inShortcut: inShortcut)
        return inShortcut
    }
    
    static var relevantShortcuts : [INRelevantShortcut] = []
    static func addShortcutToSiriWatchFace(inShortcut: INShortcut) {
        let relevantShortcut = INRelevantShortcut(shortcut: inShortcut)
        relevantShortcut.shortcutRole = INRelevantShortcutRole.action
        
        //var relevantShortcuts : [INRelevantShortcut] = [] //Use this to override a long list of relevant shortcuts and replace them with just one
        relevantShortcuts.append(relevantShortcut)
        INRelevantShortcutStore.default.setRelevantShortcuts(relevantShortcuts) { (error) in
            if let error = error {
                print("Failed to set relevant shortcuts. \(error))")
            } else {
                print("Relevant shortcuts set.")
            }
        }
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
