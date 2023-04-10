//
//  Actions.swift
//  Suno
//
//  Created by Adarsh Hasija on 30/10/18.
//  Copyright © 2018 Adam Behringer. All rights reserved.
//


//These are actions used by the state machine in WhiteSpeechViewController

import Foundation

enum Action :String{
    
    case UNKNOWN
    
    //Now using this class for actions related to visually-impaired and deaf-blind
    case INPUT_ALPHANUMERIC //Used when we already have an alphanumeric to pass in
    case CAMERA_OCR
    case TIME
    case DATE
    case MANUAL
    case CONTENT
    case BATTERY_LEVEL
    case NEARBY_INTERACTION
    case MC_TYPING //watchOS only as deaf-blind can already attach keyboards to iPhone
    case MC_DICTIONARY
    case GET_IOS //Used by the watch to get morse code from iPhone
    case SETTINGS
    //
    
    case AppOpened
    case Tap
    case SpeakerDidSpeak
    case PressAndHold
    case ReleaseHold
    case SwipeUp //Open keyboard
    case SwipeLeft //Open chat log
    case SwipeRight //Morse code dash
    case SwipeLeft2Finger
    case SwipeRight2Finger
    case TalkButtonTapped
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
    case UserProfileChanged
    case SettingsButtonTapped
    
    case UserProfileButtonLongPress
    case UserProfileAnimationComplete

}
