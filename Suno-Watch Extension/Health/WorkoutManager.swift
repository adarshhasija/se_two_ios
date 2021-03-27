//
//  WorkoutManager.swift
//  Suno-Watch Extension
//
//  Created by Adarsh Hasija on 11/03/21.
//  Copyright © 2021 Adam Behringer. All rights reserved.
//

import Foundation
import HealthKit

class WorkoutManager : NSObject {
    
    weak var delegate: WorkoutManagerDelegate?
    
    /// - Tag: DeclareSessionBuilder
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession!
    var builder: HKLiveWorkoutBuilder!
    
    // Publish the following:
    // - heartrate
    // - active calories
    // - distance moved
    // - elapsed time
    
    /// - Tag: Publishers
    @Published var heartrate: Double = 0
    //@Published var activeCalories: Double = 0
    //@Published var distance: Double = 0
    //@Published var elapsedSeconds: Int = 0
    
    // The app's workout state.
    var running: Bool = false
    
    // Request authorization to access HealthKit.
    func requestAuthorization() {
        // Requesting authorization.
        /// - Tag: RequestAuthorization
        // The quantity type to write to the health store.
        let typesToShare: Set = [
            HKQuantityType.workoutType()
        ]
        
        // The quantity types to read from the health store.
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            //HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            //HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        ]
        
        // Request authorization for those quantity types.
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
            // Handle error.
            if success {
                print("Authorization healthkit success")
                self.delegate?.didReceiveAuthorizationResult(result: true)
                
            } else if let error = error {
                print("*****HEALTHKIT AUTHORIZATION ERROR: " + error.localizedDescription)
                self.delegate?.didReceiveAuthorizationResult(result: false)
            }
        }
    }
    
    // Provide the workout configuration.
    func workoutConfiguration() -> HKWorkoutConfiguration {
        /// - Tag: WorkoutConfiguration
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .running
        configuration.locationType = .outdoor
        
        return configuration
    }
    
    // Start the workout.
    func startWorkout() {
        // Create the session and obtain the workout builder.
        /// - Tag: CreateWorkout
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: self.workoutConfiguration())
            builder = session.associatedWorkoutBuilder()
        } catch {
            // Handle any exceptions.
            return
        }
        
        // Setup session and builder.
        session.delegate = self
        builder.delegate = self
        
        // Set the workout builder's data source.
        /// - Tag: SetDataSource
        builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
                                                     workoutConfiguration: workoutConfiguration())
        
        // Start the workout session and begin data collection.
        /// - Tag: StartSession
        session.startActivity(with: Date())
        builder.beginCollection(withStart: Date()) { (success, error) in
            // The workout has started.
            if success {
                print("BEGIN COLLECTION success")
                self.delegate?.didWorkoutStart(result: true)
                
            }
            if let error = error {
                print("*****BEGIN COLLECTION ERROR: " + error.localizedDescription)
                self.delegate?.didWorkoutStart(result: false)
            }
        }
    }
    
    func endWorkout() {
        // End the workout session.
        session.end()
    }
    
    // MARK: - Update the UI
    // Update the published values.
    func updateForStatistics(_ statistics: HKStatistics?) {
        guard let statistics = statistics else { return }
        
        DispatchQueue.main.async {
            switch statistics.quantityType {
            case HKQuantityType.quantityType(forIdentifier: .heartRate):
                /// - Tag: SetLabel
                let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                let value = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit)
                let roundedValue = Double( round( 1 * value! ) / 1 )
                self.heartrate = roundedValue
                print("*****HEART RATE: "+String(Int(self.heartrate)))
                self.delegate?.didReceiveHealthKitHeartRate(self.heartrate)
            case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
                return
            case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning):
                return
            default:
                return
            }
        }
    }
    
    //We are assuming that there will be 1 read and 1 write
    func isWriteHealthPermissionReceived(workoutType : HKWorkoutType) -> Bool? {
        let status = healthStore.authorizationStatus(for: workoutType)
        
        return status == HKAuthorizationStatus.sharingAuthorized ? true
                        : status == HKAuthorizationStatus.sharingDenied ? false : nil
    }
}

// MARK: - HKWorkoutSessionDelegate
extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState, date: Date) {
        // Wait for the session to transition states before ending the builder.
        /// - Tag: SaveWorkout
        if toState == .ended {
            builder.endCollection(withEnd: Date()) { (success, error) in
                self.builder.finishWorkout { (workout, error) in
                    // Optionally display a workout summary to the user.
                    print("The workout has now ended.")
                    self.delegate?.didWorkoutStop(result: true)
                }
            }
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        
    }
}

// MARK: - WorkoutManagerDelegate
protocol WorkoutManagerDelegate: class {
    func didReceiveAuthorizationResult(result : Bool)
    func didWorkoutStart(result: Bool)
    func didWorkoutStop(result: Bool)
    func didReceiveHealthKitHeartRate(_ heartRate: Double)
}

// MARK: - HKLiveWorkoutBuilderDelegate
extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        let counnt = workoutBuilder.dataSource?.typesToCollect.count
    }
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else {
                return // Nothing to do.
            }
            
            /// - Tag: GetStatistics
            let statistics = workoutBuilder.statistics(for: quantityType)
            
            // Update the published values.
            updateForStatistics(statistics)
        }
    }
}
