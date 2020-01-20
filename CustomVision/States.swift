//
//  States.swift
//  Suno
//
//  Created by Adarsh Hasija on 30/10/18.
//  Copyright © 2018 Adam Behringer. All rights reserved.
//

import Foundation

enum State :String{
    case SubscriptionNotPaid
    case ControllerLoaded
    case Idle
    case PromptUserRole         //Ask the user if they are typing or speaking
    case Hosting
    case BrowsingForPeers       //This is when the app has quietly initiated browsing for peers. No UI shown
    case OpenedSessionBrowser   //This is when the user has initiated browsing for peers
    
    case ConnectedTyping
    case ConnectedSpeaking
    
    case EditingMode //Opened a new view controller for typing/speaking
    
    case Typing
    case TypingStarted
    case Speaking
    case Listening              //Listening to other person speaking
    case Reading                //Reading what the other person is typing
    
    case ReceivingFromWatch
}
