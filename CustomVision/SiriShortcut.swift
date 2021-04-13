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
    
    static let intentToActionMap : [String : Action] =
            [
                "com.starsearth.three.getTimeIntent" : Action.TIME,
                "com.starsearth.three.getDateDayOfWeekIntent" : Action.DATE,
                "com.starsearth.three.getCameraIntent" : Action.CAMERA_OCR,
                "com.starsearth.three.getBatteryLevelIntent" : Action.BATTERY_LEVEL
            ]
    
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
                                                "activity_type": "com.starsearth.three.getCameraIntent"
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
    
    static func createUserActivityFromSiriShortcut(siriShortcut : SiriShortcut) -> NSUserActivity {
        let activity = NSUserActivity(activityType: siriShortcut.activityType)
        activity.title = siriShortcut.title
        //activity.userInfo = siriShortcut.dictionary //BUG: We are not sending this as any modifications made to the dictionary breaks Add To Siri button. Any modifications to this dictionary breaks Add to Siri button. It does not capture the shortcut even if it exists. However the shortcut continues to work from the shortcut app
        activity.suggestedInvocationPhrase = siriShortcut.invocation
        activity.persistentIdentifier = siriShortcut.activityType
        activity.isEligibleForHandoff = true
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        activity.becomeCurrent()
        return activity
    }
    
    //Using acitivites instead of intents as Siri opens app directly for activity. For intents, it shows button to open app, which we do not want s
    //This is being used in this file as it could be used by multiple targets (eg: iOS and watchOS)
    //This has to be called from the View Controller where it takes place because the Add to Siri button must be setup there
    // isAccessibilityElement is not set here because it is an iOS thing. It is set in iOS controllers
    static func createINShortcutAndAddToSiriWatchFace(siriShortcut: SiriShortcut) -> INShortcut {
        let activity = createUserActivityFromSiriShortcut(siriShortcut: siriShortcut)
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
    //var messageOnOpen: String //Not recommended to put text that can be changed often into the Shortcut. Modifying the text breaks the Add to Siri button
    var dictionary: [String: Any] {
        return [
                "title": title,
                "action": action,
                "invocation": invocation,
                "activity_type": activityType
        ]
    }
    var nsDictionary: NSDictionary {
        return dictionary as NSDictionary
    }
    
    init(dictionary: NSDictionary) {
        //None can be nil. It breaks complications
        self.title = dictionary["title"] as? String ?? ""
        self.action = dictionary["action"] as? String ?? Action.UNKNOWN.rawValue
        self.invocation = dictionary["invocation"] as? String ?? ""
        self.activityType = dictionary["activity_type"] as? String ?? ""
    }
}
