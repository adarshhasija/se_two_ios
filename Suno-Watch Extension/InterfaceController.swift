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
    }
    
    enum Action :String{
        case AppOpened
        case TapTypingButton
        case TypistFinishedTyping
    }
    
    /// UI Properties
    @IBOutlet weak var mainText: WKInterfaceLabel!
    @IBOutlet weak var typeButton: WKInterfaceButton!
    
    
    @IBAction func typeButtonTapped() {
        changeState(action: Action.TapTypingButton)
    }
    
    /// Private Properties
    var currentState : [State] = []
    
    /// State Machine
    func changeState(action: Action) {
        if action == Action.AppOpened {
            currentState.append(State.Idle)
            goToStateIdle()
        }
        else if action == Action.TapTypingButton && currentState.last == State.Idle {
            currentState.append(State.Typing)
            goToStateTyping()
        }
        else if action == Action.TypistFinishedTyping {
            //go back to idle state
            while currentState.last != State.Idle {
                currentState.popLast()
            }
        }
    }

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
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
    func goToStateIdle() {
        mainText?.setHidden(false)
        mainText?.setText("Tap the button above to type a message. You can either show the watch to someone so they can read the message, or open the Suno app on your iPhone and show the message there. The other person can reply on your iPhone and the message will appear on your watch. Note that the message will not appear on the iPhone if the phone is connected to another device in a conversation session.")
    }
    
    func goToStateTyping() {
        presentTextInputController(withSuggestions: ["I am hearing-impaired. I have a doubt. Can I ask you?", "Sorry I did not understand that"], allowedInputMode: WKTextInputMode.plain, completion: { (result) -> Void in
            
            if let input = (result as [Any]?)?[0] as? String {
                self.mainText?.setText(input)
                self.mainText?.setHidden(false)
                self.changeState(action: Action.TypistFinishedTyping)
                if WCSession.isSupported() {
                    let session = WCSession.default
                    session.sendMessage(["request":input], replyHandler: { response in
                        //self.mainText?.setText("Success")
                        //self.mainText?.setHidden(false)
                    }, errorHandler: { error in
                        self.mainText?.setText("Failure")
                        self.mainText?.setHidden(false)
                    })
                }
            }
        })
    }

}
