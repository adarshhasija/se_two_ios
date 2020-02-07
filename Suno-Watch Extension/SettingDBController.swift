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
    
    @IBOutlet weak var instructionLabel: WKInterfaceLabel!
    @IBOutlet weak var picker: WKInterfacePicker!
    
    var se3UserType : String?
    var instructionDeafBlind = "You will type in morse code"
    var instructionNotDeafBlind = "You will type or speak in normal English"
    var delegate : MCInterfaceControllerProtocol?
    
    
    @IBAction func pickerValueChanged(_ value: Int) {
        if value == 0 {
            se3UserType = "_2"
            instructionLabel.setText(instructionDeafBlind)
        }
        else if value == 1 {
            se3UserType = "_1"
            instructionLabel.setText(instructionNotDeafBlind)
        }
    }
    
    override func awake(withContext context: Any?) {
        self.delegate = context as? MCInterfaceControllerProtocol
        
        var pickerItems : [WKPickerItem] = []
        let piDeafBlind = WKPickerItem()
        piDeafBlind.title = "Deaf-blind"
        pickerItems.append(piDeafBlind)
        let piNoAilments = WKPickerItem()
        piNoAilments.title = "Not impaired"
        pickerItems.append(piNoAilments)
        picker.setItems(pickerItems)
        
        se3UserType = UserDefaults.standard.string(forKey: "SE3_WATCHOS_USER_TYPE")
        if se3UserType == "_2" {
            picker.setSelectedItemIndex(0)
            instructionLabel.setText(instructionDeafBlind)
        }
        else if se3UserType == "_1" {
            picker.setSelectedItemIndex(1)
            instructionLabel.setText(instructionNotDeafBlind)
        }
        else {
            picker.setSelectedItemIndex(0)
            instructionLabel.setText(instructionDeafBlind)
        }
        
    }
    
    override func willDisappear() {
        if se3UserType == nil {
            //We have no value stored and user tapped on back without changing the value. Therefore set it to deaf-blind
            se3UserType = "_2"
        }
        UserDefaults.standard.set(se3UserType, forKey: "SE3_WATCHOS_USER_TYPE")
        if se3UserType != nil {
            delegate?.settingDeafBlindChanged(se3UserType: se3UserType!)
        }
    }
    
}
