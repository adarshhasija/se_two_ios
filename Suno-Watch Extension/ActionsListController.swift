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
        WKInterfaceDevice.current().play(.success) //successfully launched app
        actionsListTable.setNumberOfRows(3, withRowType: "ActionRow")
        
        let row0 = actionsListTable.rowController(at: 0) as! ActionsListRowController
        let txt0 = "Get From iPhone"
        let txt0Explanation = "Use the digital crown to scroll through dots and dashes one by one"
        let finalString0 = txt0 + "." + txt0Explanation
        row0.mainGroup.setAccessibilityLabel(finalString0)
        row0.actionLabel.setText(txt0)
        row0.actionExplanationLabel.setText(txt0Explanation)
        row0.actionExplanationLabel.setHidden(false)
        let row1 = actionsListTable.rowController(at: 1) as! ActionsListRowController
        let txt1 = "TIME"
        row1.mainGroup.setAccessibilityLabel(txt1)
        row1.actionLabel.setText(txt1)
        let row2 = actionsListTable.rowController(at: 2) as! ActionsListRowController
        let txt2 = "DATE"
        row2.mainGroup.setAccessibilityLabel(txt2)
        row2.actionLabel.setText(txt2)
        //let row3 = actionsListTable.rowController(at: 3) as! ActionsListRowController
        //let txt3 = "1-to-1 CHAT"
        //row3.mainGroup.setAccessibilityLabel(txt3)
        //row3.actionLabel.setText(txt3)
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
