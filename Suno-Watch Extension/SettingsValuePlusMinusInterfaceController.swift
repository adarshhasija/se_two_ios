//
//  ValuePlusMinusInterfaceController.swift
//  Suno-Watch Extension
//
//  Created by Adarsh Hasija on 16/03/23.
//  Copyright © 2023 Adam Behringer. All rights reserved.
//

import Foundation
import WatchKit
import WatchConnectivity

class SettingsValuePlusMinusInterfaceController : WKInterfaceController {
    
    //equivalent of SettingsTableViewController on the iOS side
    
    var TIME_DIFF_MILLIS : Int = -1
    let expectedMoveDelta = 0.523599 //Here, current delta value = 30° Degree, Set delta value according requirement.
    var crownRotationalDelta = 0.0
    var startTimeNanos : UInt64 = 0 //Used to calculate speed of crown rotation
    var quickScrollTimeThreshold = 700000000 //If the digital crown is scrolled 30 degrees within this many nano seconds, we go into autoplay
    
    
    @IBOutlet weak var topLabel: WKInterfaceLabel!
    @IBOutlet weak var minusButton: WKInterfaceButton!
    @IBOutlet weak var plusButton: WKInterfaceButton!
    @IBOutlet weak var timeLabel: WKInterfaceLabel!
    @IBOutlet weak var errorLabel: WKInterfaceLabel!
    
    
    @IBAction func minusButtonTapped() {
        if TIME_DIFF_MILLIS <= 500 {
            errorLabel?.setText("Timer cannot go lower")
            errorLabel?.setHidden(false)
            WKInterfaceDevice.current().play(.failure)
            return
        }
        WKInterfaceDevice.current().play(.start)
        errorLabel?.setHidden(true)
        TIME_DIFF_MILLIS -= 500
        setTimeLabel()
        UserDefaults.standard.set(TIME_DIFF_MILLIS, forKey: LibraryCustomActions.STRING_FOR_USER_DEFAULTS)
        //updateUserDefaults()
        sendUpdateToPhone()
        
    }
    
    
    @IBAction func plusButtonTapped() {
        if TIME_DIFF_MILLIS >= 2000 {
            errorLabel?.setText("Timer cannot go higher")
            errorLabel?.setHidden(false)
            WKInterfaceDevice.current().play(.failure)
            return
        }
        WKInterfaceDevice.current().play(.start)
        errorLabel.setHidden(true)
        TIME_DIFF_MILLIS += 500
        setTimeLabel()
        UserDefaults.standard.set(TIME_DIFF_MILLIS, forKey: LibraryCustomActions.STRING_FOR_USER_DEFAULTS)
        //updateUserDefaults()
        sendUpdateToPhone()
    }
    
    override func awake(withContext context: Any?) {
        updateTime()
        errorLabel.setHidden(true)
     }
    
    override func willActivate() {
        self.crownSequencer.delegate = self
        self.crownSequencer.focus()
    }
    
    func updateTime() {
        let userDefault = UserDefaults.standard
        TIME_DIFF_MILLIS = userDefault.value(forKey: LibraryCustomActions.STRING_FOR_USER_DEFAULTS) as? Int ?? 1000
        //let appGroupName = LibraryCustomActions.APP_GROUP_NAME
        //let appGroupUserDefaults = UserDefaults(suiteName: appGroupName)!
        //TIME_DIFF_MILLIS = appGroupUserDefaults.value(forKey: LibraryCustomActions.STRING_FOR_USER_DEFAULTS) as? Int ?? 1000
        setTimeLabel()
    }
    
    private func setTimeLabel() {
        let mins = ((TIME_DIFF_MILLIS/1000)/60)
        let secs = ((TIME_DIFF_MILLIS/1000)%60)
        let millis = TIME_DIFF_MILLIS%1000
        let secsString = String(secs) + (millis > 0 ? ".5" : "") + "s"
        timeLabel?.setText(secsString)
    }
    
    //This was used when trying App Groups. And it didnt work
    private func updateUserDefaults() {
        let appGroupName = LibraryCustomActions.APP_GROUP_NAME
        let appGroupUserDefaults = UserDefaults(suiteName: appGroupName)!
        appGroupUserDefaults.set(NSNumber(value: TIME_DIFF_MILLIS), forKey: LibraryCustomActions.STRING_FOR_USER_DEFAULTS)
        appGroupUserDefaults.synchronize()
    }
    
}

extension SettingsValuePlusMinusInterfaceController : WKCrownDelegate {
    
    func crownDidRotate(_ crownSequencer: WKCrownSequencer?, rotationalDelta: Double) {
        crownRotationalDelta  += rotationalDelta
        
        if crownRotationalDelta < -expectedMoveDelta {
            //downward scroll
            crownRotationalDelta = 0.0
            let endTime = DispatchTime.now()
            let diffNanos = endTime.uptimeNanoseconds - startTimeNanos
            if diffNanos > quickScrollTimeThreshold {
                //30 degree completed
                startTimeNanos = DispatchTime.now().uptimeNanoseconds //Update this so we can do a check on the next rotation
                minusButtonTapped()
            }
        }
        else if crownRotationalDelta > expectedMoveDelta {
            crownRotationalDelta = 0.0
            let endTime = DispatchTime.now()
            let diffNanos = endTime.uptimeNanoseconds - startTimeNanos
            if diffNanos > quickScrollTimeThreshold {
                startTimeNanos = DispatchTime.now().uptimeNanoseconds //Update this so we can do a check on the next rotation
                plusButtonTapped()
            }
        }
    }
}

extension SettingsValuePlusMinusInterfaceController : WCSessionDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    
    private func sendUpdateToPhone() {
        if WCSession.isSupported() { //makes sure it's not an iPad or iPod
            let watchSession = WCSession.default
            watchSession.delegate = self
            watchSession.activate()
            do {
                try watchSession.updateApplicationContext(["TIME_DIFF_MILLIS": TIME_DIFF_MILLIS])
            } catch let error as NSError {
                print(error.description)
            }
        }
    }
    
    
}
