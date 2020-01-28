//
//  SettingDBController.swift
//  Suno-Watch Extension
//
//  Created by Adarsh Hasija on 30/12/19.
//  Copyright © 2019 Adam Behringer. All rights reserved.
//

import Foundation
import WatchKit

class SettingDBController: WKInterfaceController {
    /*
     User Type:
     0: Not set
     1: Normal person
     2: Deaf-Blind
     */
    
    @IBOutlet weak var deafBlindSwitch: WKInterfaceSwitch!
    @IBOutlet weak var instructionLabel: WKInterfaceLabel!
    
    var se3UserType : String?
    var instructionDeafBlind = "Set to ON if the user of the watch is deaf-blind. We will modify the experience accordingly"
    var instructionNotDeafBlind = "Set to OFF if the user of the watch needs to communicate with a deaf-blind person. We will modify the experience accordingly"
    var delegate : MCInterfaceControllerProtocol?
    
    
    @IBAction func switchValueChange(_ value: Bool) {
        se3UserType = value ? "_2" : "_1"
        UserDefaults.standard.set(se3UserType, forKey: "SE3_WATCHOS_USER_TYPE")
        instructionLabel.setText(value ? instructionNotDeafBlind : instructionDeafBlind)
        if se3UserType != nil {
            delegate?.settingDeafBlindChanged(se3UserType: se3UserType!)
        }
    }
    
    override func awake(withContext context: Any?) {
        self.delegate = context as? MCInterfaceControllerProtocol
        se3UserType = UserDefaults.standard.string(forKey: "SE3_WATCHOS_USER_TYPE")
        if se3UserType == "_2" {
            deafBlindSwitch.setOn(true)
            instructionLabel.setText(instructionNotDeafBlind)
        }
        else if se3UserType == "_1" {
            deafBlindSwitch.setOn(false)
            instructionLabel.setText(instructionDeafBlind)
        }
        else {
            deafBlindSwitch.setOn(false)
            instructionLabel.setText(instructionDeafBlind)
        }
        
    }
    
    override func willDisappear() {
        let userDefaultsValue = UserDefaults.standard.string(forKey: "SE3_WATCHOS_USER_TYPE")
        if userDefaultsValue == nil {
            if se3UserType == nil {
                //We have no value stored and user tapped on back without changing the value
                se3UserType = "_1"
            }
            UserDefaults.standard.set(se3UserType, forKey: "SE3_WATCHOS_USER_TYPE")
            if se3UserType != nil {
                delegate?.settingDeafBlindChanged(se3UserType: se3UserType!)
            }
        }
    }
    
}
