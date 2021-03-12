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
    
    let delegate = WKExtension.shared().delegate as! ExtensionDelegate
    
    var delegateActionsList : ActionsListControllerProtocol? = nil
    
    @IBOutlet weak var mainLabel: WKInterfaceLabel!
    @IBOutlet weak var cancelButton: WKInterfaceButton!
    
    
    @IBAction func cancelTapped() {
        //pop()
        //WorkoutTracking.shared.startWorkOut()
        //WorkoutTracking.shared.delegate = self
        delegate.workoutManager?.startWorkout()
    }
    
    override func awake(withContext context: Any?) {
        let dictionary = context as? NSDictionary
        if dictionary != nil {
            delegateActionsList = dictionary!["actions_list_delegate"] as? ActionsListControllerProtocol
        }
        delegate.workoutManager = WorkoutManager()
        delegate.workoutManager?.requestAuthorization()
        //WorkoutTracking.authorizeHealthKit()
        //WorkoutTracking.shared.startWorkOut()
        //WorkoutTracking.shared.delegate = self
    }
    
    override func didDeactivate() {
        //WorkoutTracking.shared.stopWorkOut()
        delegate.workoutManager?.endWorkout()
    }
}

extension HRCalculatorController : WorkoutTrackingDelegate {
    
    func healthKitAuthorizationReceived(success: Bool) {

    }
    
    func didReceiveHealthKitHeartRate(_ heartRate: Double) {
        print("************"+String(Int(heartRate)))
        let heartRateString = String(Int(heartRate))
        mainLabel.setText(heartRateString)
        WorkoutTracking.shared.stopWorkOut()
        delegateActionsList?.setVibrationsForHeartRate(heartRate: heartRateString)
    }
}
