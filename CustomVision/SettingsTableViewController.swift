//
//  SettingsTableViewController.swift
//  Suno
//
//  Created by Adarsh Hasija on 21/05/20.
//  Copyright © 2020 Adam Behringer. All rights reserved.
//

import Foundation
import UIKit
import WatchConnectivity
import FirebaseAnalytics

class SettingsTableViewController : UITableViewController {
    
    
    @IBOutlet weak var isAppInstalledLabel: UILabel!
    @IBOutlet weak var sendToWatchExplanationLabel: UILabel!
    
    override func viewDidLoad() {
        setupSectionSendToWatch()
    }
    
    private func setupSectionSendToWatch() {
        if isWatchAppInstalled() {
            isAppInstalledLabel?.text = "Apple Watch app installed"
            sendToWatchExplanationLabel?.text = "You can use the Apple Watch app to type and read morse code. You can also read morse code on your Apple Watch by transferring the message from your phone to your watch. To do this, simply open the app on your Apple Watch and swipe down"
            
            /*   let session = WCSession.default
             if session.isReachable {
             session.sendMessage(["request": "user_type"], replyHandler: nil, errorHandler: nil)
             }   */
        }
        else {
            isAppInstalledLabel?.text = "Apple Watch app not installed"
            sendToWatchExplanationLabel?.text = "The Apple Watch app also allows a deaf-blind person to communicate using morse code. You can also send morse code from your iPhone app to your Watch app and read it there"
        }
    }
    
    func isWatchAppInstalled() -> Bool {
        if WCSession.isSupported() {
            let session = WCSession.default
            if session.isWatchAppInstalled {
                return true
            }
        }
        return false
    }
}
