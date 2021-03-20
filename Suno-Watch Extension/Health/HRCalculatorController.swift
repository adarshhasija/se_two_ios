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
    
    @IBOutlet weak var mainLabel: WKInterfaceLabel!
    @IBOutlet weak var cancelButton: WKInterfaceButton!
    
    @IBAction func cancelTapped() {
        if isWorkoutInProgress == true {
            extensionDelegate.workoutManager?.endWorkout()
        }
        pop()
    }
    
    override func awake(withContext context: Any?) {
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
        }
        else {
            pop()
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
        }
        else {
            pop()
            showPopupPermissionsError()
        }
    }
}
