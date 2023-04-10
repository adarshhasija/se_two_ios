//
//  ActionsListController.swift
//  Suno-Watch Extension
//
//  Created by Adarsh Hasija on 11/10/20.
//  Copyright © 2020 Adam Behringer. All rights reserved.
//

import Foundation
import WatchKit
import WatchConnectivity

class ActionsListController : WKInterfaceController {
    
    @IBOutlet weak var actionsListTable: WKInterfaceTable!
    
    var actionsList : [ContentCell] = []
    
    override func awake(withContext context: Any?) {
        WKInterfaceDevice.current().play(.success) //successfully launched app
        
        actionsList.append(ContentCell(action: "Settings", cellType: Action.SETTINGS))
        actionsList.append(ContentCell(action: "Time", explanation: "12 hour format", cellType: Action.TIME))
        actionsList.append(ContentCell(action: "Date", explanation: "Date and day of the week", cellType: Action.DATE))
        actionsList.append(ContentCell(action: "Battery Level", explanation: "Of this watch as a percentage", cellType: Action.BATTERY_LEVEL))
        actionsList.append(ContentCell(action: "Manual", explanation: "Enter letters or numbers and we will translate it into vibrations", cellType: Action.MANUAL))
        actionsList.append(ContentCell(action: "Get from iPhone", explanation: "If there is braille on the iPhone app, you can read it here if you prefer", cellType: Action.GET_IOS))
        //actionsList.append(ContentCell(action: "Camera", explanation: "Get the text that was captured by the iPhone camera", cellType: Action.CAMERA_OCR))
        //actionsList.append(ContentCell(action: "Morse Code Typing", explanation: "A vibration based typing mode for deaf-blind", cellType: Action.MC_TYPING))
        
        
        actionsListTable.setNumberOfRows(actionsList.count, withRowType: "ActionRow")
        for index in 0...actionsList.count-1 {
            let row = actionsListTable.rowController(at: index) as! ActionsListRowController
            let actionCell = actionsList[index]
            row.mainGroup.setAccessibilityLabel(actionCell.accessibilityLabel)
            row.mainGroup.setAccessibilityTraits(UIAccessibilityTraits.button)
            row.actionLabel.setText(actionCell.action)
            row.actionExplanationLabel.setText(actionCell.explanation)
        }
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        let actionCell = actionsList[rowIndex]
        sendAnalytics(eventName: "se3_watch_row_tap", parameters: [
            "list_item" : actionCell.cellType.rawValue
        ])
        selectedAction(action: actionCell.cellType.rawValue)
        
    }
}


extension ActionsListController {
    
    func selectedAction(action : String) {
        if action == Action.SETTINGS.rawValue {
            let params : [String: Any] = [:]
            pushController(withName: "ValuePlusMinusInterfaceController", context: params)
        }
        else if action == Action.MANUAL.rawValue {
            pushManualTypingController()
        }
        else if action == Action.TIME.rawValue {
            let alphanumericString = LibraryCustomActions.getCurrentTimeInAlphanumeric(format: "12")
            var params : [String:Any] = [:]
            params["mode"] = Action.MANUAL.rawValue
            params["alphanumeric"] = alphanumericString
            self.pushController(withName: "MCInterfaceController", context: params)
        }
        else if action == Action.DATE.rawValue {
          //  let day = (Calendar.current.component(.day, from: Date()))
          //  let weekdayInt = (Calendar.current.component(.weekday, from: Date()))
          //  let weekdayString = Calendar.current.weekdaySymbols[weekdayInt - 1]
          //  let alphanumericString = String(day) + " " + weekdayString.uppercased() //Use this if converting it to customized dots and dashes
            let alphanumericString = LibraryCustomActions.getCurrentDateInAlphanumeric()
            var params : [String:Any] = [:]
            params["mode"] = Action.MANUAL.rawValue
            params["alphanumeric"] = alphanumericString
            self.pushController(withName: "MCInterfaceController", context: params)
        }
        else if action == Action.BATTERY_LEVEL.rawValue {
            let alphanumericString = (WKExtension.shared().delegate as? ExtensionDelegate)?.getBatteryLevelAsAlphanumericWithOutPercentageSign()
            var params : [String:Any] = [:]
            params["mode"] = Action.MANUAL.rawValue
            params["alphanumeric"] = alphanumericString
            self.pushController(withName: "MCInterfaceController", context: params)
        }
        else {
            let params = (WKExtension.shared().delegate as? ExtensionDelegate)?.getParamsForMCInterfaceController(action: Action(rawValue: action) ?? Action.UNKNOWN)
            pushController(withName: "MCInterfaceController", context: params)
        }
    }
    
    func sendAnalytics(eventName : String, parameters : Dictionary<String, Any>) {
        var message : [String : Any] = [:]
        message["event_name"] = eventName
        message["parameters"] = parameters
        if WCSession.isSupported() {
            let session = WCSession.default
            if session.isReachable {
                // In your WatchKit extension, the value of this property is true when the paired iPhone is reachable via Bluetooth.
                session.sendMessage(message, replyHandler: nil, errorHandler: nil)
            }
            
        }
    }
    
    func pushManualTypingController() {
        presentTextInputController(withSuggestions: [
            "Hi", //2 character words are priority as Watch can get through 2 chars before screen dim
            "No",
            "Yes" //This word is part of the screenshots so this stays
        ], allowedInputMode: WKTextInputMode.plain, completion: { (result) -> Void in
            
            if var input = (result as [Any]?)?[0] as? String {
                input = input.trimmingCharacters(in: .whitespacesAndNewlines).filter("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 ".contains).removeExtraSpaces() //Remove anything that is not alphanumeric
                if input.count < 1 {
                    return
                }
           /*     if input.count > 6 {
                    self.presentAlert(withTitle: "Alert", message: "Too long. Max 6 characters.", preferredStyle: .alert, actions: [
                        WKAlertAction(title: "OK", style: .default) {}
                        ])
                    return
                }   */
                var params : [String:Any] = [:]
                params["mode"] = Action.MANUAL.rawValue
                params["alphanumeric"] = input
                self.pushController(withName: "MCInterfaceController", context: params)
            }
            else {
                //User cancelled typing
                
            }
        })
    }
    
}
