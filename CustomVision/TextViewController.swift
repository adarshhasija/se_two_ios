//
//  TextViewController.swift
//  CustomVision
//
//  Created by Adarsh Hasija on 10/03/23.
//  Copyright © 2023 Adam Behringer. All rights reserved.
//

import Foundation
import UIKit
import WatchConnectivity

//Morse code reader with buttons, no gestures
class TextViewController : UIViewController {
    
    var mText : String =  ""
    var mStartIndexForHighlighting : Int = -1
    var mEndIndexForHighlighting : Int = -1
    var braille : Braille? = nil //This is only used incase we get a Get from iPhone request on this screen from the watch
    
    @IBOutlet weak var mainLabel: UILabel!
    
    override func viewDidLoad() {
        if mStartIndexForHighlighting <= -1 || mStartIndexForHighlighting >= mText.count {
            mainLabel.text = mText
            return
        }
        if mEndIndexForHighlighting <= mStartIndexForHighlighting {
            mainLabel.text = mText
            return
        }
        
        MorseCodeUtils.setSelectedCharInLabel(inputString: mText, index: mStartIndexForHighlighting, length: (mEndIndexForHighlighting - mStartIndexForHighlighting), label: mainLabel, isMorseCode: false, color : UIColor.green)
    }
    
    func receivedRequestForAlphanumericsAndMCFromWatch(mode: String?) {
        sendEnglishAndBrailleToWatch()
    }
    
    func sendEnglishAndBrailleToWatch() {
        //If autoplay is on, we only send that. If its not on, we send all the indices to replicate on the watch
        if WCSession.isSupported() {
            let session = WCSession.default
            if session.isWatchAppInstalled && session.isReachable {
                session.sendMessage(braille?.getMapToSendToWatch() ?? [:], replyHandler: nil, errorHandler: nil)
            }
        }
    }
    
}
