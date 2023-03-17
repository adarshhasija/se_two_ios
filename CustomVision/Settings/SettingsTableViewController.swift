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
        //UserDefaults.standard.set(TIME_DIFF_MILLIS, forKey: LibraryCustomActions.STRING_FOR_USER_DEFAULTS) //Using App Group instead as that will keep the value in sync between phone and  watch
        updateUserDefaults()
        sendUpdateToWatch()
    }
    
    
    @IBAction func plusButtonTapped(_ sender: Any) {
        let hapticManager = HapticManager(supportsHaptics: supportsHaptics)
        hapticManager.generateStandardResponseHaptic()
        errorLabel?.text = ""
        TIME_DIFF_MILLIS += 1000
        setTimeLabel()
        //UserDefaults.standard.set(TIME_DIFF_MILLIS, forKey: LibraryCustomActions.STRING_FOR_USER_DEFAULTS) //Using App Group instead as that will keep the value in sync between phone and  watch
        updateUserDefaults()
        sendUpdateToWatch()
    }
    
    
    override func viewDidLoad() {
        updateTime()
        errorLabel?.text = ""
    }
    
    func updateTime() {
        let userDefault = UserDefaults.standard
        TIME_DIFF_MILLIS = userDefault.value(forKey: LibraryCustomActions.STRING_FOR_USER_DEFAULTS) as? Int ?? 1000 //Using App Group instead as that will keep the value in sync between phone and  watch
        //let appGroupName = LibraryCustomActions.APP_GROUP_NAME
        //let appGroupUserDefaults = UserDefaults(suiteName: appGroupName)!
        //TIME_DIFF_MILLIS = appGroupUserDefaults.value(forKey: LibraryCustomActions.STRING_FOR_USER_DEFAULTS) as? Int ?? 1000
        setTimeLabel()
    }
    
    private func setTimeLabel() {
        let mins = ((TIME_DIFF_MILLIS/1000)/60)
        let secs = ((TIME_DIFF_MILLIS/1000)%60)
        let minsString = mins > 0 ? String(mins) + "m" : ""
        let secsString = secs > 0 ? String(secs) + "s" : ""
        let finalString = minsString + " " + secsString
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, finalString)
        timeLabel?.text = finalString
    }
    
    private func updateUserDefaults() {
        let appGroupName = LibraryCustomActions.APP_GROUP_NAME
        let appGroupUserDefaults = UserDefaults(suiteName: appGroupName)!
        appGroupUserDefaults.set(NSNumber(value: TIME_DIFF_MILLIS), forKey: LibraryCustomActions.STRING_FOR_USER_DEFAULTS)
        appGroupUserDefaults.synchronize()
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

extension SettingsTableViewController : WCSessionDelegate  {
    
    private func sendUpdateToWatch() {
        if WCSession.isSupported() { //makes sure it's not an iPad or iPod
            let watchSession = WCSession.default
            watchSession.delegate = self
            watchSession.activate()
            if watchSession.isPaired && watchSession.isWatchAppInstalled {
                do {
                    try watchSession.updateApplicationContext(["TIME_DIFF_MILLIS": TIME_DIFF_MILLIS])
                } catch let error as NSError {
                    print(error.description)
                }
            }
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
}
