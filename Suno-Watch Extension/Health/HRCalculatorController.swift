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
        }
        pop()
    }
    
  /*  @IBAction func buttonTapped() {
        if isWorkoutInProgress == true {
            extensionDelegate.workoutManager?.endWorkout()
        }
        pop()
    }   */
    
    override func awake(withContext context: Any?) {
        label.setText("Opening permission dialog")
        button.setHidden(true)
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
    
    func showPopupPermissionsError(){
        let action1 = WKAlertAction(title: "OK", style: .default) {}

        presentAlert(withTitle: "Error", message: "Something went wrong. You may have declined the read or write permission", preferredStyle: .actionSheet, actions: [action1])

    }
}

extension HRCalculatorController : WorkoutManagerDelegate {
    func didReceiveAuthorizationResult(result: Bool) {
        if result == true {
            extensionDelegate.workoutManager?.startWorkout()
            label.setText("Starting workout")
            button.setTitle("Stop Workout")
            button.setBackgroundColor(UIColor.red)
            button.setHidden(false)
        }
        else {
            //pop()
            label.setText("Authorization failed. Please see Heart Rate section of iPhone app")
            button.setHidden(true)
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
            label.setText("Getting heart rate. Please wait")
            button.setTitle("Stop Workout and Go Back")
            button.setBackgroundColor(UIColor.red)
            button.setHidden(false)
        }
        else {
            //pop()
            //showPopupPermissionsError()
            label.setText("Something went wrong. You may have declined some of the permissions. Please see the Heart Rate section of the iPhone app")
            button.setHidden(true)
        }
    }
}
