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
    
    //SE3_USER_TYPE: 0 = NOT SET, 1 = DEAF BLIND, 2 = NOT DEAF BLIND

    
    @IBOutlet weak var deafBlindSwitch: WKInterfaceSwitch!
    @IBOutlet weak var instructionLabel: WKInterfaceLabel!
    
    var isDeafBlind = 0
    var instructionDeafBlind = "Set to ON if the user of the watch is deaf-blind. We will modify the experience accordingly"
    var instructionNotDeafBlind = "Set to OFF if the user of the watch is not deaf-blind. We will modify the experience accordingly"
    var delegate : MCInterfaceControllerProtocol?
    
    
    @IBAction func switchValueChange(_ value: Bool) {
        isDeafBlind = value ? 1 : 2
        UserDefaults.standard.set(isDeafBlind, forKey: "SE3_USER_TYPE")
        instructionLabel.setText(value ? instructionNotDeafBlind : instructionDeafBlind)
        delegate?.settingDeafBlindChanged(isDeafBlind: value ? 1 : 2)
    }
    
    override func awake(withContext context: Any?) {
        self.delegate = context as? MCInterfaceControllerProtocol
        isDeafBlind = UserDefaults.standard.integer(forKey: "SE3_USER_TYPE")
        if isDeafBlind == 1 {
            deafBlindSwitch.setOn(true)
            instructionLabel.setText(instructionNotDeafBlind)
        }
        else if isDeafBlind == 2 {
            deafBlindSwitch.setOn(false)
            instructionLabel.setText(instructionDeafBlind)
        }
        else {
            deafBlindSwitch.setOn(false)
            instructionLabel.setText(instructionDeafBlind)
        }
        
    }
    
    override func willDisappear() {
        let userDefaultsValue = UserDefaults.standard.integer(forKey: "SE3_USER_TYPE")
        if userDefaultsValue == 0 {
            if isDeafBlind == 0 {
                //We have no value stored and user tapped on back without changing the value
                isDeafBlind = 2
            }
            UserDefaults.standard.set(2, forKey: "SE3_USER_TYPE")
            delegate?.settingDeafBlindChanged(isDeafBlind: isDeafBlind)
        }
    }
    
}
