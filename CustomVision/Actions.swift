//
//  Actions.swift
//  Suno
//
//  Created by Adarsh Hasija on 30/10/18.
//  Copyright © 2018 Adam Behringer. All rights reserved.
//

import Foundation

enum Action :String{
    case AppOpened
    case Tap
    case SpeakerDidSpeak
    case PressAndHold
    case ReleaseHold
    case SwipeUp //Open keyboard
    case SwipeLeft //Open help topics
    case BarButtonHelpTapped
    case LongPress //Start Multipeer session
    
    case ReceivedStatusFromWatch
    case ReceivedContentFromWatch
    case WatchUserStopped
    case WatchNotReachable
    
    case UserPrmoptCancelled
    case UserSelectedTyping
    case UserSelectedSpeaking
    
    case BrowserCancelled
    case ReceivedConnection
    case TypistStartedTyping
    case TypistDeletedAllText
    case TypistFinishedTyping
    case PartnerCompleted
    case PartnerEndedSession
    case LostConnection
    
    //Opening of new view controller
    case OpenedEditingModeForTyping
    case OpenedEditingModeForSpeaking
    case OpenedChatLogForReading
    
    //Closing of new view controller
    case CompletedEditing
    case CancelledEditing
    case SpeakerCancelledSpeaking
    
    case ChatLogsCleared
    case UserProfileButtonTapped
    case AppleWatchButtonTapped
}
