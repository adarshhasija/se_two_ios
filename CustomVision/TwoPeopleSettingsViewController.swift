//
//  TwoPeopleSettingsViewController.swift
//  Suno
//
//  Created by Adarsh Hasija on 01/02/20.
//  Copyright © 2020 Adam Behringer. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAnalytics

public class TwoPeopleSettingsViewController : UIViewController {
    
    //FYI:
    // Hi: Hearing-impaired
    // Vi: Visually-impaired
    
    // User Type:
    // nil = No selection made
    // _1 = Host is not HI or VI.
    // _2 = Host is HI.
    // _3 = Host is deaf-blind
    
    // Properties
    lazy var supportsHaptics: Bool = {
        return (UIApplication.shared.delegate as? AppDelegate)?.supportsHaptics ?? false
    }()
    var inputUserProfileOption : String?
    var whiteSpeechViewControllerProtocol : WhiteSpeechViewControllerProtocol?
    var userProfileTableViewControllerProtocol : UserProfileTableViewControllerProtocol?
    var hiSwitchOnExplanationString = "Will type out messages and show the other person"
    var hiSwitchOffExplanationString = "Will speak and show the written text to the hearing-impaired person"
    var hiViString = "Use on Apple Watch.\niOS version for deaf and blind coming in a future update!"
    var HiWillTypeString = "You will type"
    var deafBlindMorseCodeString = "You will type in morse code"
    var noAilmentsWillTalkString = "You can type or talk"
    var warningCoreHaptics = "Warning: You may not be able to feel the morse code vibrations on this device"
    var pickerData : [String] = []
    
    @IBOutlet weak var hostRoleLabel: UILabel!
    @IBOutlet weak var errorMessageLabel: UILabel! //only needed when we start with deaf-blind mode
    @IBOutlet weak var hostPickerView: UIPickerView!
    

    
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        pickerData.append(contentsOf: ["Deaf-blind","Hearing-impaired", /* "Not impaired"*/])
        hostPickerView.delegate = self
        hostPickerView.dataSource = self
        errorMessageLabel?.text = ""
        
        if inputUserProfileOption == "_2" {
            //No input = deaf
            // _2 = Deaf
            hostRoleLabel?.text = HiWillTypeString
            hostPickerView?.selectRow(1, inComponent: 0, animated: false)
            errorMessageLabel?.isHidden = false
        }
        else if inputUserProfileOption == "_3" {
            // _3 = deaf-blind
            hostRoleLabel?.text = deafBlindMorseCodeString
            hostPickerView?.selectRow(0, inComponent: 0, animated: false)
            errorMessageLabel?.text = warningCoreHaptics
            errorMessageLabel?.isHidden = supportsHaptics
        }
        else {
            //If no selection is made, assume its deaf-blind
            hostRoleLabel?.text = deafBlindMorseCodeString
            hostPickerView?.selectRow(0, inComponent: 0, animated: false)
            errorMessageLabel?.text = warningCoreHaptics
            errorMessageLabel?.isHidden = supportsHaptics
        }
    /*    else if inputUserProfileOption == "_1" {
            // _1 = normal
            hostRoleLabel?.text = noAilmentsWillTalkString
            hostPickerView?.selectRow(2, inComponent: 0, animated: false)
        }   */
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        let userType = hostPickerView.selectedRow(inComponent: 0) == 0 ? "_3" : "_2"
        Analytics.logEvent("se3_user_type", parameters: [
            "type": userType
        ])
        UserDefaults.standard.set(userType, forKey: "SE3_IOS_USER_TYPE")
        whiteSpeechViewControllerProtocol?.userProfileOptionSet(se3UserType: userType)
        userProfileTableViewControllerProtocol?.setUserProfileType(type: userType)
    }
}

extension TwoPeopleSettingsViewController : UIPickerViewDataSource {
    
    //number of columns
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = UILabel()
        label.lineBreakMode = .byWordWrapping;
        label.numberOfLines = 0;
        label.text = pickerData[row]
        label.sizeToFit()
        return label;
    }
}

extension TwoPeopleSettingsViewController : UIPickerViewDelegate {
    
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        errorMessageLabel?.isHidden = true
        if row == 0 {
            //Host = Deaf-blind
            hostRoleLabel?.text = deafBlindMorseCodeString
            if supportsHaptics == false {
                errorMessageLabel?.text = warningCoreHaptics
                errorMessageLabel?.isHidden = false
            }
        }
        else if row == 1 {
            //Host = HI
            hostRoleLabel?.text = HiWillTypeString
            errorMessageLabel?.text = ""
            errorMessageLabel?.isHidden = true
        }
        else if row == 2 {
            //Host = Normal
            hostRoleLabel?.text = noAilmentsWillTalkString
            errorMessageLabel?.text = ""
            errorMessageLabel?.isHidden = true
        }
    }
    
}
