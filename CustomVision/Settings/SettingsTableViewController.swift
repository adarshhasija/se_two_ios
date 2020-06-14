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
    
    @IBAction func rightBarButtonItemTapped(_ sender: Any) {
        
    }
    
    override func viewDidLoad() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(rightBarButtonItemTapped))
        setupSectionSendToWatch()
    }
    
    private func setupSectionSendToWatch() {
        if isWatchAppInstalled() {
            isAppInstalledLabel?.text = "Apple Watch app installed"
            sendToWatchExplanationLabel?.text = "You can use the Apple Watch app to type and read morse code. You can also read morse code on your Apple Watch by transferring the message from your phone to your watch. For example: If you got text from your camera and wish to read it on your watch, you can do so.\n\nTo do this, simply open the app on your Apple Watch and swipe down"
            
            /*   let session = WCSession.default
             if session.isReachable {
             session.sendMessage(["request": "user_type"], replyHandler: nil, errorHandler: nil)
             }   */
        }
        else {
            isAppInstalledLabel?.text = "Apple Watch app not installed"
            sendToWatchExplanationLabel?.text = "We offer these features on our Apple Watch app as well. Additionally, you can also send morse code from your iPhone app to your Watch app and read it there\n\nIf you have installed the Watch app, ensure your Watch is switched ON and is close to your phone"
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
