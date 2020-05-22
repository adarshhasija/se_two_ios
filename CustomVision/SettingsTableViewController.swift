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
    
    let sendToWatchSwitchOff = "Morse code will not be sent to your watch when you open the Apple Watch app and the Apple Watch is close to your phone"
    let sendToWatchSwitchOn = "To transfer morse code from your phone to your watch, simply open the app on your Apple Watch"
    
    
    @IBOutlet weak var isAppInstalledLabel: UILabel!
    @IBOutlet weak var sendToWatchStackView: UIStackView!
    @IBOutlet weak var sendToWatchSwitch: UISwitch!
    @IBOutlet weak var sendToWatchExplanationLabel: UILabel!
    
    
    @IBAction func onSendToWatchSwitchValueChanged(_ sender: UISwitch) {
        sendToWatchExplanationLabel?.text = sender.isOn ? sendToWatchSwitchOn : sendToWatchSwitchOff
    }
    
    override func viewDidLoad() {
        setupSectionSendToWatch()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        let sendToWatch = sendToWatchSwitch?.isOn == true ? "_1" : "_0"
        Analytics.logEvent("se3_ios_s2w", parameters: [:])
        UserDefaults.standard.set(sendToWatch, forKey: "SE3_IOS_WATCH_SEND")
    }
    
    private func setupSectionSendToWatch() {
        if isWatchAppInstalled() {
            isAppInstalledLabel?.text = "Apple Watch app installed"
            sendToWatchStackView?.isHidden = false
            sendToWatchExplanationLabel?.isHidden = false
            
            let sendToWatchValue = UserDefaults.standard.string(forKey: "SE3_IOS_WATCH_SEND")
            sendToWatchSwitch?.isOn = sendToWatchValue == "_1" ? true : false
            sendToWatchExplanationLabel?.text = sendToWatchValue == "_1" ? sendToWatchSwitchOn : sendToWatchSwitchOff
            
            /*   let session = WCSession.default
             if session.isReachable {
             session.sendMessage(["request": "user_type"], replyHandler: nil, errorHandler: nil)
             }   */
        }
        else {
            isAppInstalledLabel?.isHidden = false
            isAppInstalledLabel?.text = "Apple Watch app not installed"
            sendToWatchStackView?.isHidden = false
            sendToWatchSwitch?.isOn = UserDefaults.standard.string(forKey: "SE3_IOS_WATCH_SEND") == "_1" ? true : false
            sendToWatchSwitch?.isEnabled = false
            sendToWatchExplanationLabel?.isHidden = true
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
