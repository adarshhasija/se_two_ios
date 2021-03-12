//
//  WorkoutTracking.swift
//  Suno-Watch Extension
//
//  Created by Adarsh Hasija on 11/03/21.
//  Copyright © 2021 Adam Behringer. All rights reserved.
//

import Foundation
import HealthKit

class WorkoutTracking : NSObject {
    static let shared = WorkoutTracking()
    let healthStore = HKHealthStore()
    let configuration = HKWorkoutConfiguration()
    var workoutSession: HKWorkoutSession!
    var workoutBuilder: HKLiveWorkoutBuilder!
        
    weak var delegate: WorkoutTrackingDelegate?
        
    override init() {
        super.init()
    }
}

protocol WorkoutTrackingDelegate: class {
    func didReceiveHealthKitHeartRate(_ heartRate: Double)
    //func didReceiveHealthKitStepCounts(_ stepCounts: Double)
}

protocol WorkoutTrackingProtocol {
    static func authorizeHealthKit()
    func startWorkOut()
    func stopWorkOut()
    //func fetchStepCounts()
}

extension WorkoutTracking {
    
    private func handleSendStatisticsData(_ statistics: HKStatistics) {
        switch statistics.quantityType {
        case HKQuantityType.quantityType(forIdentifier: .heartRate):
            let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
            let value = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit)
            let roundedValue = Double( round( 1 * value! ) / 1 )
            delegate?.didReceiveHealthKitHeartRate(roundedValue)
        
        case HKQuantityType.quantityType(forIdentifier: .stepCount):
            return
        
        default:
            return
        }
    }
    
    private func configWorkout() {
            //let configuration = HKWorkoutConfiguration()
            configuration.activityType = .walking
            
            do {
                workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
                workoutBuilder = workoutSession?.associatedWorkoutBuilder()
            } catch {
                return
            }
            
            workoutSession.delegate = self
            workoutBuilder.delegate = self
            
            workoutBuilder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
        }
    
}

extension WorkoutTracking: WorkoutTrackingProtocol {
    
    static func authorizeHealthKit() {
            if HKHealthStore.isHealthDataAvailable() {
                let infoToRead = Set([
                    //HKSampleType.quantityType(forIdentifier: .stepCount)!,
                    HKSampleType.quantityType(forIdentifier: .heartRate)!,
                    //HKSampleType.workoutType()
                    ])
                
                let infoToShare = Set([
                    //HKSampleType.quantityType(forIdentifier: .stepCount)!,
                    HKSampleType.quantityType(forIdentifier: .heartRate)!,
                    //HKSampleType.workoutType()
                    ])  
                
                HKHealthStore().requestAuthorization(toShare: infoToShare, read: infoToRead) { (success, error) in
                    if success {
                        print("Authorization healthkit success")
                        
                    } else if let error = error {
                        print("*****HEALTHKIT AUTHORIZATION ERROR: " + error.localizedDescription)
                    }
                }
            } else {
                print("HealthKit not avaiable")
            }
        }
    
    func startWorkOut() {
            print("Start workout")
            configWorkout()
            workoutSession?.startActivity(with: Date())
            workoutBuilder?.beginCollection(withStart: Date()) { (success, error) in
                print("********SUCCESS: "+String(success))
                if let error = error {
                    print("*******ERROR: "+error.localizedDescription)
                }
            }
        }
    
    func stopWorkOut() {
            print("Stop workout")
            workoutSession?.stopActivity(with: Date())
            workoutSession?.end()
          /*  workoutBuilder.endCollection(withEnd: Date()) { (success, error) in
                    
            }   */
        }
}

extension WorkoutTracking : HKLiveWorkoutBuilderDelegate {
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        //print("GET DATA: \(Date())")
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else {
                return
            }
                    
            if let statistics = workoutBuilder.statistics(for: quantityType) {
                handleSendStatisticsData(statistics)
            }
        }
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        
    }
}

extension WorkoutTracking : HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        // Wait for the session to transition states before ending the builder.
        if toState == .ended {
            print("The workout has now ended.")
            workoutBuilder?.endCollection(withEnd: Date()) { (success, error) in
                print("****END COLLECTION SUCCESS: "+String(success))
                self.workoutBuilder?.finishWorkout { (workout, error) in
                    // Optionally display a workout summary to the user.
                    //self.resetWorkout()
                }
            }
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("******HKWorkoutSession Error: "+error.localizedDescription)
    }
}
