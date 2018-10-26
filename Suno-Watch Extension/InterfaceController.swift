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
        case TapStopButton
        case TypistFinishedTyping
        case ReceivedUserStatus
        case PhoneCompletedSending
    }
    
    /// UI Properties
    @IBOutlet weak var mainText: WKInterfaceLabel!
    @IBOutlet weak var statusText: WKInterfaceLabel!
    @IBOutlet weak var typeButton: WKInterfaceButton!
    @IBOutlet weak var stopButton: WKInterfaceButton! //If the user is waiting for a response from iPhone and wants to stop waiting
    
    @IBAction func typeButtonTapped() {
        changeState(action: Action.TapTypingButton)
    }
    @IBAction func stopButtonTapped() {
        changeState(action: Action.TapStopButton)
    }
    
    /// Private Properties
    var currentState : [State] = []
    
    /// State Machine
    func changeState(action: Action) {
        if action == Action.AppOpened {
            currentState.append(State.Idle)
            enterStateIdle()
        }
        else if action == Action.TapTypingButton && currentState.last == State.Idle {
            self.statusText?.setHidden(true)
            if WCSession.isSupported() {
                let session = WCSession.default
                session.sendMessage(["status":"User is entering message on watch. Please wait..."],
                                    replyHandler: { message in }, errorHandler: { error in })
            }
            currentState.append(State.Typing)
            enterStateTyping()
        }
        else if action == Action.TypistFinishedTyping {
            //go back to idle state
            while currentState.last != State.Idle {
                currentState.popLast()
            }
        }
        else if action == Action.ReceivedUserStatus && currentState.last == State.Idle {
            currentState.append(State.Receiving)
            enterStateReceiving()
        }
        else if action == Action.ReceivedUserStatus && currentState.last == State.Receiving {
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
    }

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        changeState(action: Action.AppOpened)
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    
    /// Private Helpers - State Machine
    func enterStateIdle() {
        typeButton?.setHidden(false)
        mainText?.setHidden(false)
        mainText?.setText("Tap the button above to enter a message. You can either show the watch to someone so they can read the message, or open the Suno app on your iPhone and show the message there. The other person can reply on your iPhone and the message will appear on your watch.")
        statusText?.setText("")
        statusText?.setHidden(true)
        stopButton?.setHidden(true)
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
                self.mainText?.setHidden(false)
                self.changeState(action: Action.TypistFinishedTyping)
                if WCSession.isSupported() {
                    let session = WCSession.default
                    session.sendMessage(["request":input], replyHandler: { message in
                        guard let phoneResponse = message["response"] as? String else {
                            return
                        }
                        
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
        })
    }
    
    func enterStateReceiving() {
        self.typeButton?.setHidden(true)
        self.mainText?.setHidden(false)
        self.mainText?.setText("")
        self.statusText?.setHidden(false)
        self.statusText?.setTextColor(UIColor.green)
        self.stopButton?.setHidden(false)
    }
    
    func exitStateReceiving() {
        self.typeButton?.setHidden(false)
        self.mainText?.setHidden(false)
        self.statusText?.setHidden(false)
        self.stopButton?.setHidden(true)
    }
    
    /// MARK:- Private Helpers
    func setMessageToPhoneNoReply(key: String, message: String) {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.sendMessage([key: message], replyHandler: { message in }, errorHandler: { error in })
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
        
        if let success = message["success"] as? Bool, let status = message["status"] as? String {
            self.statusText?.setTextColor(success ? UIColor.green : UIColor.red)
            self.statusText?.setText(status)
            changeState(action: Action.ReceivedUserStatus)
        } else if let response = message["response"] as? String {
            self.mainText?.setText(response)
            self.statusText?.setText("")
            changeState(action: Action.PhoneCompletedSending)
        }
    }
    
    
}
