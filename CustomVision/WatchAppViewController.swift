//
//  WatchAppViewController.swift
//  Suno
//
//  Created by Adarsh Hasija on 29/01/20.
//  Copyright © 2020 Adam Behringer. All rights reserved.
//

import Foundation
import UIKit
import WatchConnectivity

class WatchAppViewController : UIViewController {
    
    
    @IBOutlet weak var noWatchAppContainerView: UIView!
    @IBOutlet weak var yesWatchAppStackView: UIStackView!
    @IBOutlet weak var watchUserTypeLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //No logic performed in this view controller at the moment
      /*  if isWatchAppInstalled() {
            noWatchAppContainerView?.isHidden = true
            yesWatchAppStackView?.isHidden = false
            
            let session = WCSession.default
            if session.isReachable {
                session.sendMessage(["request": "user_type"], replyHandler: nil, errorHandler: nil)
            }
        }   */
    }
    
    
    func isWatchAppInstalled() -> Bool {
        if WCSession.isSupported() {
            let session = WCSession.default
            if session.isWatchAppInstalled {
                return true
            }
        }
        return false
    }
    
    func receivedUserTypeFromWatch(userType : String) {
        if userType == "_0" {
            watchUserTypeLabel?.text = "Watch app is installed on paired Apple Watch but no user type has been set. Please open the app on the watch and set declare if the user is deaf-blind"
        }
        else if userType == "_1" {
            watchUserTypeLabel?.text = "Watch app is installed on paired Apple Watch. User can see, hear and speak and uses the app to communicate with deaf-blind. If the watch user is deaf-blind, please change the status on the watch. Simply force press and choose User Profile."
        }
        else if userType == "_2" {
            watchUserTypeLabel?.text = "Watch app is installed on teh paired Apple Watch. User has been declared deaf-blind. If user is not deaf blind, please change the status on the watch. Simply force press and choose User Profile"
        }
    }
}

extension WatchAppViewController : WCSessionDelegate {
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    public func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    public func sessionDidDeactivate(_ session: WCSession) {
        
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        let userType = message["user_type"] as? String
        
    }
}
