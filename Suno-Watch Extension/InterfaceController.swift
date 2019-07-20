//
//  InterfaceController.swift
//  Suno-Watch Extension
//
//  Created by Adarsh Hasija on 23/10/18.
//  Copyright © 2018 Adam Behringer. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity
import AVFoundation

class InterfaceController: WKInterfaceController {
    
    // MARK: States
    enum State :String{
        case SubscriptionNotPaid
        case Idle
        case Typing
        case Receiving
    }
    
    enum Action :String{
        case AppOpened
        case TapTypingButton
        case TypingCancelledByUser
        case TapStopButton
        case TapPlayAudioButton
        case TypistFinishedTyping
        case ReceivedUserStatusActionStart
        case ReceivedUserStatusActionEnd
        case PhoneCompletedSending
        case PhoneNotReachable
    }
    
    /// UI Properties
    @IBOutlet weak var mainText: WKInterfaceLabel!
    @IBOutlet weak var statusText: WKInterfaceLabel!
    @IBOutlet weak var typeButton: WKInterfaceButton!
    @IBOutlet weak var stopButton: WKInterfaceButton! //If the user is waiting for a response from iPhone and wants to stop waiting
    @IBOutlet weak var playAudioButton: WKInterfaceButton!
    
    @IBAction func typeButtonTapped() {
        changeState(action: Action.TapTypingButton)
    }
    @IBAction func stopButtonTapped() {
        changeState(action: Action.TapStopButton)
    }    
    @IBAction func playAudioButtonTapped() {
        changeState(action: Action.TapPlayAudioButton)
    }
    
    /// Private Properties
    var currentState : [State] = []
    let synth = AVSpeechSynthesizer()
    var currentText : String? = nil
    
    /// State Machine
    func changeState(action: Action) {
        if action == Action.AppOpened {
            currentState.append(State.Idle)
            enterStateIdle()
        }
        else if action == Action.TapTypingButton && currentState.last == State.Idle {
            self.statusText?.setHidden(true)
            sendMessageToPhoneNoReply(key: "status", message: "User is entering message on watch. Please wait...")
            currentState.append(State.Typing)
            enterStateTyping()
        }
        else if action == Action.TypingCancelledByUser && currentState.last == State.Typing {
            while currentState.last != State.Idle {
                currentState.popLast()
            }
            sendMessageToPhoneNoReply(key: "user_cancelled_typing", message: "User cancelled typing on watch.")
            enterStateIdle()
        }
        else if action == Action.TypistFinishedTyping {
            //go back to idle state
            while currentState.last != State.Idle {
                currentState.popLast()
            }
        }
        else if action == Action.ReceivedUserStatusActionStart && currentState.last == State.Idle {
            currentState.append(State.Receiving)
            enterStateReceiving()
        }
        else if action == Action.ReceivedUserStatusActionEnd && currentState.last == State.Receiving {
            while currentState.last != State.Idle {
                currentState.popLast()
            }
            exitStateReceiving()
        }
        else if action == Action.PhoneCompletedSending && currentState.last == State.Receiving {
            while currentState.last != State.Idle {
                currentState.popLast()
            }
            exitStateReceiving()
        }
        else if action == Action.TapStopButton && currentState.contains(State.Receiving) {
            while currentState.last != State.Idle {
                currentState.popLast()
            }
            exitStateReceiving()
            enterStateIdle()
        }
        else if action == Action.TapPlayAudioButton && currentState.last == State.Idle {
            if currentText != nil {
                self.sayThis(string: currentText!)
            }
        }
        else if action == Action.PhoneNotReachable && currentState.contains(State.Receiving) {
            while currentState.last != State.Idle {
                currentState.popLast()
            }
            exitStateReceiving()
            enterStateIdle()
            presentAlert(withTitle: "Alert", message: "Phone not reachable", preferredStyle: .alert, actions: [
                WKAlertAction(title: "OK", style: .default) {}
                ])
        }
    }

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
        changeState(action: Action.AppOpened)
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable {
            
        }
        else if !session.isReachable {
            
        }
    }
    
    
    /// Private Helpers - State Machine
    func enterStateIdle() {
        typeButton?.setHidden(false)
        mainText?.setHidden(false)
        if currentText == nil {
            mainText?.setText("Tap the button above to enter a message and show it to your friend.")
        }
        else {
            mainText?.setText(currentText)
        }
        statusText?.setText("")
        statusText?.setHidden(true)
        stopButton?.setHidden(true)
        if currentText == nil {
            playAudioButton?.setHidden(true)
        }
        else {
            playAudioButton?.setHidden(false)
        }
    }
    
    func enterStateTyping() {
        presentTextInputController(withSuggestions: [
            "I am hearing-impaired. I have a doubt. Can I ask you?",
            "Please tap the iPhone screen to speak",
            "Please swipe up on the iPhone screen to type",
            "Sorry I did not understand that"
            ], allowedInputMode: WKTextInputMode.plain, completion: { (result) -> Void in
            
            if let input = (result as [Any]?)?[0] as? String {
                self.mainText?.setText(input)
                self.currentText = input
                self.sayThis(string: input)
                self.mainText?.setHidden(false)
                self.playAudioButton?.setHidden(false)
                if WCSession.isSupported() {
                    let session = WCSession.default
                    if session.isReachable {
                        session.sendMessage(["request":input], replyHandler: { message in
                            guard let phoneResponse = message["response"] as? String else {
                                return
                            }
                            
                            self.changeState(action: Action.TypistFinishedTyping)
                            if let status = message["status"] as? Bool {
                                self.statusText?.setTextColor(status ? UIColor.green : UIColor.red)
                            }
                            
                            self.statusText?.setText(phoneResponse)
                            self.statusText?.setHidden(false)
                            
                            
                        }, errorHandler: { error in
                            //self.statusText?.setText("Sorry, failed to send to iPhone")
                            self.statusText?.setHidden(true)
                        })
                    }
                }
            }
            else {
                //User cancelled typing
                self.changeState(action: Action.TypingCancelledByUser)
            }
        })
    }
    
    func enterStateReceiving() {
        self.typeButton?.setHidden(true)
        self.mainText?.setHidden(false)
        self.mainText?.setText("")
        self.statusText?.setHidden(false)
        self.statusText?.setTextColor(UIColor.green)
        self.stopButton?.setHidden(false)
        self.playAudioButton?.setHidden(true)
    }
    
    func exitStateReceiving() {
        self.typeButton?.setHidden(false)
        self.mainText?.setHidden(false)
        self.statusText?.setHidden(false)
        self.stopButton?.setHidden(true)
        if currentText != nil {
            playAudioButton?.setHidden(false)
        }
        else {
            playAudioButton?.setHidden(true)
        }
    }
    
    /// MARK:- Private Helpers
    func sendMessageToPhoneNoReply(key: String, message: String) {
        if WCSession.isSupported() {
            let session = WCSession.default
            if session.isReachable {
                session.sendMessage([key: message], replyHandler: { message in }, errorHandler: { error in })
            }
        }
    }

}

extension InterfaceController : WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if WKExtension.shared().applicationState != .active {
            return
        }
        
        if let beginningOfAction = message["beginningOfAction"] as? Bool, let success = message["success"] as? Bool, let status = message["status"] as? String {
            if beginningOfAction && currentState.last == State.Idle {
                //Always display if its the beginning of an action on iPhone
                self.statusText?.setTextColor(success ? UIColor.green : UIColor.red)
                self.statusText?.setText(status)
                changeState(action: Action.ReceivedUserStatusActionStart)
            }
            else if !beginningOfAction && currentState.last == State.Receiving {
                //If its end of action, only display if we are in receiving mode.
                //If the user has pressed stop, we should not display
                self.statusText?.setTextColor(success ? UIColor.green : UIColor.red)
                self.statusText?.setText(status)
                changeState(action: Action.ReceivedUserStatusActionEnd)
            }
        } else if let response = message["response"] as? String {
            if currentState.contains(State.Receiving) {
                self.mainText?.setText(response)
                self.statusText?.setText("")
            }
            changeState(action: Action.PhoneCompletedSending)
        }
    }
    
    
}

extension InterfaceController {
    func sayThis(string: String) {
        let utterance = AVSpeechUtterance(string: string)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        if synth.isPaused {
            synth.continueSpeaking()
        }
        else {
            synth.speak(utterance)
        }
    }
}
