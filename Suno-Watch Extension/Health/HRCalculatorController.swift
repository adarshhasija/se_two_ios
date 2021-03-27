//
//  HRCalculatorController.swift
//  Suno-Watch Extension
//
//  Created by Adarsh Hasija on 10/03/21.
//  Copyright © 2021 Adam Behringer. All rights reserved.
//

import Foundation
import WatchKit
import HealthKit

//heart rate calculator
class HRCalculatorController : WKInterfaceController {
    
    var heartrate: Double? = nil
    var isWorkoutInProgress : Bool = false
    
    let extensionDelegate = WKExtension.shared().delegate as! ExtensionDelegate
    
    @IBOutlet weak var label: WKInterfaceLabel!
    @IBOutlet weak var button: WKInterfaceButton!
    
    @IBAction func buttonTapped() {
        if isWorkoutInProgress == true {
            extensionDelegate.workoutManager?.endWorkout()
            pop()
        }
        else {
            //It should be just a GO BACK button
            pop()
        }
    }
    
    override func awake(withContext context: Any?) {
        if HKHealthStore.isHealthDataAvailable() == false {
            label.setText("Healthkit not available on this device. This maybe because there are other securities that are restricting its use")
            label.setHidden(false)
            button.setHidden(true)
            return
        }
        extensionDelegate.workoutManager = WorkoutManager()
        extensionDelegate.workoutManager?.delegate = self
        extensionDelegate.workoutManager?.requestAuthorization()
        
    }
    
    override func didAppear() {
        if heartrate != nil {
            pop()
        }
    }
    
    override func didDeactivate() {
        if isWorkoutInProgress == true {
            extensionDelegate.workoutManager?.endWorkout()
        }
    }
    
    //This is called if requestaurthorization or start workout fails
    //It will not fail if READ is denied. Only if WRITE is denied
    func writePermissionDenied() {
        //let isWriteAuthorized = extensionDelegate.workoutManager?.isWriteHealthPermissionReceived(workoutType: HKObjectType.workoutType())
        label.setText("WORKOUT STOPPED\nYou may have denied some permissions. We need both read and write permissions to give you this feature. You can go to Settings -> Health -> Apps and grant all permissions to this app")
        label.setHidden(false)
        button.setHidden(true)
    }
    
    func showPopupPermissionsError(message: String){
        let action1 = WKAlertAction(title: "OK", style: .default) {}

        presentAlert(withTitle: "Error", message: message, preferredStyle: .actionSheet, actions: [action1])

    }
}

extension HRCalculatorController : WorkoutManagerDelegate {
    func didReceiveAuthorizationResult(result: Bool) {
        if result == true {
            if extensionDelegate.workoutManager != nil {
                label.setText("Starting workout")
                button.setTitle("Stop Workout and Go Back")
                button.setBackgroundColor(UIColor.red)
                button.setHidden(false)
            }
            extensionDelegate.workoutManager?.startWorkout()
            
        }
        else {
            //READ does not trigger a failure. It has to be WRITE
            writePermissionDenied()
        }
    }
    
    func didReceiveHealthKitHeartRate(_ heartRate: Double) {
        self.heartrate = heartRate
        let heartRateString = String(Int(heartRate))
        extensionDelegate.workoutManager?.endWorkout()
        var params : [String:Any] = [:]
        params["mode"] = Action.HEART_RATE.rawValue
        params["alphanumeric"] = heartRateString
        self.pushController(withName: "MCInterfaceController", context: params)
        //pop() //this is done on the return, in didAppear
    }
    
    func didWorkoutStart(result: Bool) {
        if result == true {
            self.isWorkoutInProgress = result
            label.setText("Workout Started. Getting heart rate. Please wait. Workout will be stopped automatically when we get the heart rate")
            button.setTitle("Stop Workout and Go Back")
            button.setBackgroundColor(UIColor.red)
            button.setHidden(false)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                let watchDelegate = WKExtension.shared().delegate as? ExtensionDelegate
                if watchDelegate?.visibleInterfaceController is HRCalculatorController {
                    watchDelegate?.workoutManager?.endWorkout()
                    WKInterfaceDevice.current().play(.failure)
                    self.label?.setText("WORKOUT STOPPED\nCould not get the reading. You may have declined the READ permission. We need all permissions in order to proceed. Please to the Settings app -> Health -> Apps, and grant this app all permissions to this app")
                    self.label?.setHidden(false)
                    self.button?.setTitle("Go Back")
                    self.button?.setBackgroundColor(UIColor.red)
                }
            }
            
        }
        else {
            //READ does not trigger a failure. So it has to be WRITE
            writePermissionDenied()
        }
    }
    
    func didWorkoutStop(result: Bool) {
        //Only used when the timeout happens and we could not get a value
        self.isWorkoutInProgress = false
    }
}
