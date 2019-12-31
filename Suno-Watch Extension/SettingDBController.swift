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

    
    @IBOutlet weak var deafBlindSwitch: WKInterfaceSwitch!
    @IBOutlet weak var instructionLabel: WKInterfaceLabel!
    
    var isDeafBlind = 0
    var instructionDeafBlind = "Set to ON if the user of the watch is deaf-blind. We will modify the experience accordingly"
    var instructionNotDeafBlind = "Set to OFF if the user of the watch is not deaf-blind. We will modify the experience accordingly"
    var delegate : MCInterfaceControllerProtocol?
    
    
    @IBAction func switchValueChange(_ value: Bool) {
        isDeafBlind = value ? 1 : 2
        UserDefaults.standard.set(isDeafBlind, forKey: "SE3_IS_DEAF_BLIND")
        instructionLabel.setText(value ? instructionNotDeafBlind : instructionDeafBlind)
        delegate?.settingDeafBlindChanged(isDeafBlind: value ? 1 : 2)
    }
    
    override func awake(withContext context: Any?) {
        self.delegate = context as? MCInterfaceControllerProtocol
        isDeafBlind = UserDefaults.standard.integer(forKey: "SE3_IS_DEAF_BLIND")
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
        let userDefaultsValue = UserDefaults.standard.integer(forKey: "SE3_IS_DEAF_BLIND")
        if userDefaultsValue == 0 {
            if isDeafBlind == 0 {
                //We have no value stored and user tapped on back without changing the value
                isDeafBlind = 2
            }
            UserDefaults.standard.set(2, forKey: "SE3_IS_DEAF_BLIND")
            delegate?.settingDeafBlindChanged(isDeafBlind: isDeafBlind)
        }
    }
    
}
