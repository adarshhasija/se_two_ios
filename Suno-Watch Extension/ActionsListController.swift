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
        
        actionsList.append(ActionsCell(action: "Time", cellType: Action.TIME))
                actionsList.append(ActionsCell(action: "Date and Day of week", cellType: Action.DATE))
        actionsList.append(ActionsCell(action: "Get text read by iPhone camera", cellType: Action.GET_IOS))
        
        
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
        
        var params : [String:Any] = [:]
        params["mode"] = actionCell.cellType.rawValue
    /*    if actionCell == 0 {
            params["mode"] = "from_iOS"
        }
        else if rowIndex == 1 {
            params["mode"] = "TIME"
        }
        else if rowIndex == 2 {
            params["mode"] = "DATE"
        }
        else if rowIndex == 3 {
            params["mode"] = "chat"
        }   */
        
        sendAnalytics(eventName: "se3_watch_row_tap", parameters: [
                    "screen" : params["mode"] as? String
                ])
        pushController(withName: "MCInterfaceController", context: params)
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
    
}
