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
    
    var TIME_DIFF_MILLIS : Int = -1
    lazy var supportsHaptics: Bool = {
            return (UIApplication.shared.delegate as? AppDelegate)?.supportsHaptics ?? false
        }()
    
    @IBOutlet weak var minusButton: UIButton!
    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var errorLabel: UILabel!
    
    
    @IBAction func minusButtonTapped(_ sender: Any) {
        if TIME_DIFF_MILLIS <= 1000 {
            let hapticManager = HapticManager(supportsHaptics: supportsHaptics)
            hapticManager.generateErrorHaptic()
            let errorMessage = "Timer cannot go lower"
            errorLabel?.text = errorMessage
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, // announce
            errorMessage);
            return
        }
        let hapticManager = HapticManager(supportsHaptics: supportsHaptics)
        hapticManager.generateStandardResponseHaptic()
        errorLabel?.text = ""
        TIME_DIFF_MILLIS -= 1000
        setTimeLabel()
        UserDefaults.standard.set(TIME_DIFF_MILLIS, forKey: LibraryCustomActions.STRING_FOR_USER_DEFAULTS)
    }
    
    
    @IBAction func plusButtonTapped(_ sender: Any) {
        let hapticManager = HapticManager(supportsHaptics: supportsHaptics)
        hapticManager.generateStandardResponseHaptic()
        errorLabel?.text = ""
        TIME_DIFF_MILLIS += 1000
        setTimeLabel()
        UserDefaults.standard.set(TIME_DIFF_MILLIS, forKey: LibraryCustomActions.STRING_FOR_USER_DEFAULTS)
    }
    
    
    override func viewDidLoad() {
        let userDefault = UserDefaults.standard
        TIME_DIFF_MILLIS = userDefault.value(forKey: LibraryCustomActions.STRING_FOR_USER_DEFAULTS) as? Int ?? 1000
        setTimeLabel()
        errorLabel?.text = ""
    }
    
    private func setTimeLabel() {
        let mins = ((TIME_DIFF_MILLIS/1000)/60)
        let secs = ((TIME_DIFF_MILLIS/1000)%60)
        let minsString = mins > 0 ? String(mins) + "m" : ""
        let secsString = secs > 0 ? String(secs) + "s" : ""
        timeLabel?.text = minsString + " " + secsString
    }
    
    private func setupSectionSendToWatch() {
        if isWatchAppInstalled() {
            //isAppInstalledLabel?.text = "Apple Watch app installed"
            //sendToWatchExplanationLabel?.text = "You can use the Apple Watch app to type and read morse code. You can also read morse code on your Apple Watch by transferring the message from your phone to your watch. For example: If you got text from your camera and wish to read it on your watch, you can do so.\n\nTo do this, simply open the app on your Apple Watch and swipe down"
            
            /*   let session = WCSession.default
             if session.isReachable {
             session.sendMessage(["request": "user_type"], replyHandler: nil, errorHandler: nil)
             }   */
        }
        else {
            //isAppInstalledLabel?.text = "Apple Watch app not installed"
            //sendToWatchExplanationLabel?.text = "We offer these features on our Apple Watch app as well. Additionally, you can also send morse code from your iPhone app to your Watch app and read it there\n\nIf you have installed the Watch app, ensure your Watch is switched ON and is close to your phone"
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
