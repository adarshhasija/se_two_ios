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
    
    var actionsList : [ActionsCell] = []
    
    override func awake(withContext context: Any?) {
        WKInterfaceDevice.current().play(.success) //successfully launched app
        
        actionsList.append(ActionsCell(action: "Time", explanation: "12 hour format", cellType: Action.TIME))
                actionsList.append(ActionsCell(action: "Date", explanation: "Date and day of the week", cellType: Action.DATE))
        actionsList.append(ActionsCell(action: "Battery Level", explanation: "Of this watch as a percentage", cellType: Action.BATTERY_LEVEL))
        actionsList.append(ActionsCell(action: "Manual", explanation: "Enter a number of at most 6 digits and we will translate it into vibrations", cellType: Action.MANUAL))
        actionsList.append(ActionsCell(action: "Camera", explanation: "Get the text that was captured by the iPhone camera", cellType: Action.CAMERA_OCR))
        
        
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
        if action == Action.MANUAL.rawValue {
            pushManualTypingController()
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
