//
//  HapticManager.swift
//  Suno
//
//  Created by Adarsh Hasija on 09/05/20.
//  Copyright © 2020 Adam Behringer. All rights reserved.
//

import Foundation
import CoreHaptics
import AVFoundation
import UIKit

class HapticManager {
    
    let MC_DOT   = "MC_DOT"
    let MC_DASH  = "MC_DASH"
    let RESULT_SUCCESS  = "RESULT_SUCCESS"
    let RESULT_FAILURE  = "RESULT_FAILURE"
    
    private let supportsHaptics : Bool
    var chHapticEngine : CHHapticEngine?
    private var engineNeedsStart = true
    
    init(supportsHaptics : Bool) {
        self.supportsHaptics = supportsHaptics
        if supportsHaptics {
            createAndStartHapticEngine()
        }
    }
    
    private func createAndStartHapticEngine() {
        // Create and configure a haptic engine.
        do {
            chHapticEngine = try CHHapticEngine()
        } catch let error {
            fatalError("Engine Creation Error: \(error)")
        }

        // The stopped handler alerts engine stoppage.
        chHapticEngine?.stoppedHandler = { reason in
            print("Stop Handler: The engine stopped for reason: \(reason.rawValue)")
            switch reason {
            case .audioSessionInterrupt: print("Audio session interrupt")
            case .applicationSuspended: print("Application suspended")
            case .idleTimeout: print("Idle timeout")
            case .notifyWhenFinished: print("Finished")
            case .systemError: print("System error")
            @unknown default:
                print("Unknown error")
            }
            
            // Indicate that the next time the app requires a haptic, the app must call engine.start().
            self.engineNeedsStart = true
        }

        // The reset handler notifies the app that it must reload all its content.
        // If necessary, it recreates all players and restarts the engine in response to a server restart.
        chHapticEngine?.resetHandler = {
            print("The engine reset --> Restarting now!")
            
            // Tell the rest of the app to start the engine the next time a haptic is necessary.
            self.engineNeedsStart = true
        }

        // Start haptic engine to prepare for use.
        do {
            try chHapticEngine?.start()

            // Indicate that the next time the app requires a haptic, the app doesn't need to call engine.start().
            engineNeedsStart = false
        } catch let error {
            print("The engine failed to start with error: \(error)")
        }
    }
    
    func playSelectedCharacterHaptic(inputString : String, inputIndex : Int) {
        let index = inputString.index(inputString.startIndex, offsetBy: inputIndex)
        let char = String(inputString[index])
        if char == "." || char == "x" {
            //try? hapticForMorseCode(isDash: false)
            generateHaptic(code: MC_DOT)
        }
        if char == "-" || char == "o" {
            //try? hapticForMorseCode(isDash: true)
            generateHaptic(code: MC_DASH)
        }
        if char == "|" {
            //WKInterfaceDevice.current().play(.success)
            generateHaptic(code: RESULT_SUCCESS)
        }
    }
    
    func generateHaptic(code : String?) {
        if supportsHaptics == false {
            if code == MC_DOT {
                // 'Peek' feedback (weak boom)
                //let peek = SystemSoundID(1519)
                //AudioServicesPlaySystemSound(peek)
                
                // 'Pop' feedback (strong boom)
                let pop = SystemSoundID(1520)
                AudioServicesPlaySystemSound(pop)
            }
            else if code == MC_DASH {
                // 'Try Again' feedback (week boom then strong boom)
                let tryAgain = SystemSoundID(1102)
                AudioServicesPlaySystemSound(tryAgain)
            }
            else if code == RESULT_SUCCESS {
                AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
            }
            return
        }
        
        var hapticPlayer : CHHapticPatternPlayer? = nil
        do {
            if code == MC_DOT {
                hapticPlayer = try hapticForMorseCode(isDash: false)
            }
            else if code == MC_DASH {
                hapticPlayer = try hapticForMorseCode(isDash: true)
            }
            else if code == RESULT_SUCCESS {
                //hapticPlayer = try hapticForResult(success: true)
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
            else if code == RESULT_FAILURE {
                //hapticPlayer = try hapticForResult(success: false)
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
            }
            
            try hapticPlayer?.start(atTime: CHHapticTimeImmediate)
        } catch let error {
            print("Generate haptic error is: \(error)")
        }
        
    }
    
    func hapticsForEndofEntireAlphanumeric() {
        if supportsHaptics == false {
            AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
            return
        }
        
        var hapticPlayer : CHHapticPatternPlayer? = nil
        do {
            //hapticPlayer = try hapticForResult(success: true)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            try hapticPlayer?.start(atTime: CHHapticTimeImmediate)
        } catch let error {
            print("Generate haptic error is: \(error)")
        }

    }
    
    
    private func hapticForResult(success : Bool) throws -> CHHapticPatternPlayer? {
        let volume = linearInterpolation(alpha: 1, min: 0.1, max: 0.4)
        let decay: Float = linearInterpolation(alpha: 1, min: 0.0, max: 0.1)
        let audioEvent = CHHapticEvent(eventType: .audioContinuous, parameters: [
            CHHapticEventParameter(parameterID: .audioPitch, value: -0.15),
            CHHapticEventParameter(parameterID: .audioVolume, value: volume),
            CHHapticEventParameter(parameterID: .decayTime, value: decay),
            CHHapticEventParameter(parameterID: .sustained, value: 0)
            ], relativeTime: 0)

        let sharpness : Float = success == true ? 0.5 : 1.0 //Success haptics is more dull. Failure haptic is more sharp
        let intensity : Float = 1.0
        let duration = TimeInterval(2.0) //Success/failure haptics are more drawn out. Based on testing, 2 seconds can be identified as longer
        let hapticEvent = CHHapticEvent(eventType: .hapticTransient, parameters: [
            CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
            CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
            ], relativeTime: 0, duration: duration)

        let pattern = try CHHapticPattern(events: [/*audioEvent,*/ hapticEvent], parameters: [])
        return try chHapticEngine?.makePlayer(with: pattern)
    }
    
    private func hapticForMorseCode(isDash : Bool) throws -> CHHapticPatternPlayer? {
        let volume = linearInterpolation(alpha: 1, min: 0.1, max: 0.4)
        let decay: Float = linearInterpolation(alpha: 1, min: 0.0, max: 0.1)
        let audioEvent = CHHapticEvent(eventType: .audioContinuous, parameters: [
            CHHapticEventParameter(parameterID: .audioPitch, value: -0.15),
            CHHapticEventParameter(parameterID: .audioVolume, value: volume),
            CHHapticEventParameter(parameterID: .decayTime, value: decay),
            CHHapticEventParameter(parameterID: .sustained, value: 0)
            ], relativeTime: 0)

        let sharpness : Float = 1.0
        let intensity : Float = 1.0
        //For dash, a longer ping
        let duration = TimeInterval(0.25)
        let hapticDash = CHHapticEvent(eventType: .hapticContinuous, parameters: [
            CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
            CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
        ], relativeTime: 0, duration: duration)
     /*   //For dash, its 2 pings
        let hapticDash1 = CHHapticEvent(eventType: .hapticTransient, parameters: [
            CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
            CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
        ], relativeTime: 0)
        let hapticDash2 = CHHapticEvent(eventType: .hapticTransient, parameters: [
            CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
            CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
        ], relativeTime: 0.5)   */
        
        //For dot its a single ping
        let hapticDot = CHHapticEvent(eventType: .hapticTransient, parameters: [
            CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
            CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
        ], relativeTime: 0)
        
        let hapticEvents = isDash == true ? [/*hapticDash1, hapticDash2*/hapticDash] : [hapticDot]

        let pattern = try CHHapticPattern(events: hapticEvents, parameters: [])
        return try chHapticEngine?.makePlayer(with: pattern)
    }
    
    func linearInterpolation(alpha: Float, min: Float, max: Float) -> Float {
        return min + alpha * (max - min)
    }
}
