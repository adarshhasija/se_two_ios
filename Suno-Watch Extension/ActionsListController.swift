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
    
    override func awake(withContext context: Any?) {
        actionsListTable.setNumberOfRows(4, withRowType: "ActionRow")
        
        let row0 = actionsListTable.rowController(at: 0) as! ActionsListRowController
        row0.actionLabel.setText("Morse Code From iPhone")
        let row1 = actionsListTable.rowController(at: 1) as! ActionsListRowController
        row1.actionLabel.setText("TIME")
        let row2 = actionsListTable.rowController(at: 2) as! ActionsListRowController
        row2.actionLabel.setText("DATE")
        let row3 = actionsListTable.rowController(at: 3) as! ActionsListRowController
        row3.actionLabel.setText("1-to-1 CHAT")
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        sendAnalytics(eventName: "se3_watch_row_tap", parameters: [
            "screen" : "mc_actions"
        ])
        
        var params : [String:Any] = [:]
        if rowIndex == 0 {
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
        }
         
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
