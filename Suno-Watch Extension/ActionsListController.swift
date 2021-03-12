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
    
    @IBOutlet weak var deafBlindLabel: WKInterfaceLabel!
    @IBOutlet weak var actionsListTable: WKInterfaceTable!
    
    var actionsList : [ActionsCell] = []
    
    override func awake(withContext context: Any?) {
        WKInterfaceDevice.current().play(.success) //successfully launched app
        deafBlindLabel.setAccessibilityTraits(UIAccessibilityTraits.staticText) //Currently VoiceOver on watch is not saying Static Text.
        
        actionsList.append(ActionsCell(action: "Time", explanation: "12 hour format", cellType: Action.TIME))
                actionsList.append(ActionsCell(action: "Date", explanation: "Date and day of the week", cellType: Action.DATE))
        actionsList.append(ActionsCell(action: "Manual", explanation: "Enter a number of at most 6 digits and we will translate it into vibrations", cellType: Action.MANUAL))
        actionsList.append(ActionsCell(action: "Camera", explanation: "Get the text that was captured by the iPhone camera", cellType: Action.CAMERA_OCR))
        actionsList.append(ActionsCell(action: "Battery", explanation: "Battery level as a percentage", cellType: Action.BATTERY_LEVEL))
        actionsList.append(ActionsCell(action: "Heart Rate", explanation: "As Beats Per Minute(BPM)", cellType: Action.HEART_RATE))
        
        
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
        
        if actionCell.cellType == Action.MANUAL {
            pushManualTypingController()
        }
        else if actionCell.cellType == Action.BATTERY_LEVEL {
            WKInterfaceDevice.current().isBatteryMonitoringEnabled = true
            let level = String(Int(WKInterfaceDevice.current().batteryLevel * 100)) //int as we do not decimal
            WKInterfaceDevice.current().isBatteryMonitoringEnabled = false
            var params : [String:Any] = [:]
            params["mode"] = Action.MANUAL.rawValue
            params["alphanumeric"] = level
            self.pushController(withName: "MCInterfaceController", context: params)
        }
        else if actionCell.cellType == Action.HEART_RATE {
            var params : [String:Any] = [:]
            pushController(withName: "HRCalculatorController", context: params)
        }
        else {
            var params : [String:Any] = [:]
            params["mode"] = actionCell.cellType.rawValue
            pushController(withName: "MCInterfaceController", context: params)
        }
        
    }
}


extension ActionsListController {
    
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
            "24",
            "16",
            "17"
        ], allowedInputMode: WKTextInputMode.plain, completion: { (result) -> Void in
            
            if var input = (result as [Any]?)?[0] as? String {
                input = input.uppercased().trimmingCharacters(in: .whitespacesAndNewlines).filter("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".contains) //Remove anything that is not alphanumeric
                if input.count < 1 {
                    return
                }
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


protocol ActionsListControllerProtocol {
    
    //To get text recognized by the camera
    func setVibrationsForHeartRate(heartRate : String)
}

extension ActionsListController : ActionsListControllerProtocol {
    
    func setVibrationsForHeartRate(heartRate: String) {
        if heartRate.count > 0 {
            var params : [String:Any] = [:]
            params["mode"] = Action.HEART_RATE.rawValue
            params["alphanumeric"] = heartRate
            params["actions_list_delegate"] = self
            self.pushController(withName: "MCInterfaceController", context: params)
        }
    }

}
