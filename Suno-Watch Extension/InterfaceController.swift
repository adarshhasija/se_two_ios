//
//  InterfaceController.swift
//  Suno-Watch Extension
//
//  Created by Adarsh Hasija on 23/10/18.
//  Copyright © 2018 Adam Behringer. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {
    
    // MARK: States
    enum State :String{
        case SubscriptionNotPaid
        case Idle
        case Typing
        case Hosting
        case ConnectedTyping
    }
    
    enum Action :String{
        case AppOpened
        case TapTypingButton
        case TapStartSessionButton
        case TypistFinishedTyping
    }
    
    /// UI Properties
    @IBOutlet weak var mainText: WKInterfaceLabel!
    @IBOutlet weak var typeButton: WKInterfaceButton!
    @IBOutlet weak var startSessionButton: WKInterfaceButton!
    
    
    @IBAction func typeButtonTapped() {
        changeState(action: Action.TapTypingButton)
    }
    
    
    @IBAction func startSessionButtonTapped() {
        changeState(action: Action.TapStartSessionButton)
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
        else if action == Action.TypistFinishedTyping && currentState.contains(State.ConnectedTyping) {
            
        }
        else if action == Action.TypistFinishedTyping {
            //go back to idle state
            while currentState.last != State.Idle {
                currentState.popLast()
            }
        }
        else if action == Action.TapStartSessionButton && currentState.last == State.Idle {
            currentState.append(State.Hosting)
            goToStateHosting()
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
        mainText?.setHidden(true)
    }
    
    func goToStateTyping() {
        presentTextInputController(withSuggestions: ["I am hearing-impaired. I have a doubt. Can I ask you?", "Sorry I did not understand that"], allowedInputMode: WKTextInputMode.plain, completion: { (result) -> Void in
            
            if let choice = (result as [Any]?)?[0] as? String {
                self.mainText?.setText(choice)
                self.mainText?.setHidden(false)
                self.changeState(action: Action.TypistFinishedTyping)
            }
        })
    }
    
    func goToStateHosting() {
      /*  if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }   */
    }

}
