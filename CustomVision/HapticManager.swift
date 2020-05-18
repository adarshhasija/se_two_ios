//
//  HapticManager.swift
//  Suno
//
//  Created by Adarsh Hasija on 09/05/20.
//  Copyright © 2020 Adam Behringer. All rights reserved.
//

import Foundation
import CoreHaptics

class HapticManager {
    
    let MC_DOT   = "MC_DOT"
    let MC_DASH  = "MC_DASH"
    let RESULT_SUCCESS  = "RESULT_SUCCESS"
    let RESULT_FAILURE  = "RESULT_FAILURE"
    
    var chHapticEngine : CHHapticEngine?
    private var engineNeedsStart = true
    
    init() {
        createAndStartHapticEngine()
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
        if char == "." {
            //try? hapticForMorseCode(isDash: false)
            generateHaptic(code: MC_DOT)
        }
        if char == "-" {
            //try? hapticForMorseCode(isDash: true)
            generateHaptic(code: MC_DASH)
        }
        if char == "|" {
            //WKInterfaceDevice.current().play(.success)
            generateHaptic(code: RESULT_SUCCESS)
        }
    }
    
    func generateHaptic(code : String?) {
        var hapticPlayer : CHHapticPatternPlayer? = nil
        do {
            if code == MC_DOT {
                hapticPlayer = try hapticForMorseCode(isDash: false)
            }
            else if code == MC_DASH {
                hapticPlayer = try hapticForMorseCode(isDash: true)
            }
            else if code == RESULT_SUCCESS {
                hapticPlayer = try hapticForResult(success: true)
            }
            else if code == RESULT_FAILURE {
                hapticPlayer = try hapticForResult(success: false)
            }
            
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

        let sharpness : Float = 0.5 //Success/failure haptics are more dull than morse code haptics
        let intensity : Float = 1.0
        let duration = success == true ? TimeInterval(0.5) : TimeInterval(1.0) //Success/failure haptics are more drawn out
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
        //For dash, its 2 pings
        let hapticDash1 = CHHapticEvent(eventType: .hapticTransient, parameters: [
            CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
            CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
        ], relativeTime: 0)
        let hapticDash2 = CHHapticEvent(eventType: .hapticTransient, parameters: [
            CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
            CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
        ], relativeTime: 0.5)
        
        //For dot its a single ping
        let hapticDot = CHHapticEvent(eventType: .hapticTransient, parameters: [
            CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
            CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
        ], relativeTime: 0)
        
        let hapticEvents = isDash == true ? [hapticDash1, hapticDash2] : [hapticDot]

        let pattern = try CHHapticPattern(events: hapticEvents, parameters: [])
        return try chHapticEngine?.makePlayer(with: pattern)
    }
    
    func linearInterpolation(alpha: Float, min: Float, max: Float) -> Float {
        return min + alpha * (max - min)
    }
}
