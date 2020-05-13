//
//  TwoPeopleSettingsViewController.swift
//  Suno
//
//  Created by Adarsh Hasija on 01/02/20.
//  Copyright © 2020 Adam Behringer. All rights reserved.
//

import Foundation
import UIKit

public class TwoPeopleSettingsViewController : UIViewController {
    
    //FYI:
    // Hi: Hearing-impaired
    // Vi: Visually-impaired
    
    // User Type:
    // nil = No selection made
    // _0 = No selection made by user. Automatic selection made by app. Eg: When user first installs and after we play loading animation
    // _1 = Host is not HI or VI. Guest is HI
    // _2 = Host is HI. Guest is not HI or VI
    // _3 = Host is Deaf-blind. Guest can be not impaired or HI
    
    // Properties
    lazy var supportsHaptics: Bool = {
        return (UIApplication.shared.delegate as? AppDelegate)?.supportsHaptics ?? false
    }()
    var inputUserProfileOption : String?
    var whiteSpeechViewControllerProtocol : WhiteSpeechViewControllerProtocol?
    var hiSwitchOnExplanationString = "Will type out messages and show the other person"
    var hiSwitchOffExplanationString = "Will speak and show the written text to the hearing-impaired person"
    var hiViString = "Use on Apple Watch.\niOS version for deaf and blind coming in a future update!"
    var HiWillTypeString = "Hearing-impaired:\nWill type"
    var noAilmentsWillTalkString = "Not impaired:\nWill talk"
    var deafBlindMorseCodeString = "Deaf-blind:\nWill type in morse code"
    var notDeafBlindWillTypeString = "Not deaf-blind:\nWill type"
    var pickerData : [String] = []
    
    @IBOutlet weak var mainStackView: UIStackView!
    @IBOutlet weak var hostProfilePicAndNameStackView: UIStackView!
    @IBOutlet weak var hostProfilePicAndDisabilityIconsStackView: UIStackView!
    @IBOutlet weak var hostDisabilityIconsStackView: UIStackView!
    @IBOutlet weak var hostHiImageView: UIImageView!
    @IBOutlet weak var hostViImageView: UIImageView!
    @IBOutlet weak var hostPersonImageView: UIImageView!
    @IBOutlet weak var hostNameLabel: UILabel!
    @IBOutlet weak var hostRoleLabel: UILabel!
    
    @IBOutlet weak var guestProfileAndNameStackView: UIStackView!
    @IBOutlet weak var guestProfilePicAndDisabilityIconsStackVIew: UIStackView!
    @IBOutlet weak var guestPersonImageVIew: UIImageView!
    @IBOutlet weak var guestDisabilityIconsStackView: UIStackView!
    @IBOutlet weak var guestHiImageView: UIImageView!
    @IBOutlet weak var guestViImageView: UIImageView!
    @IBOutlet weak var guestNameLabel: UILabel!
    @IBOutlet weak var guestRoleLabel: UILabel!
    
    @IBOutlet weak var errorMessageLabel: UILabel! //only needed when we start with deaf-blind mode
    
    @IBOutlet weak var hostPickerView: UIPickerView!
    

    
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        pickerData.append(contentsOf: ["Hearing-impaired", "Deaf-blind"/*, "Not impaired"*/])
        hostPickerView.delegate = self
        hostPickerView.dataSource = self
        errorMessageLabel?.text = ""
        
        if inputUserProfileOption == nil
            || inputUserProfileOption == "_0"
            || inputUserProfileOption == "_2" {
            //No input = deaf
            // _2 = Deaf
            hostHiImageView?.alpha = 1
            hostViImageView?.alpha = 0.25
            guestHiImageView?.alpha = 0.25
            guestViImageView?.alpha = 0.25
            hostRoleLabel?.text = HiWillTypeString
            guestRoleLabel?.text = noAilmentsWillTalkString
            hostPickerView?.selectRow(0, inComponent: 0, animated: false)
            //hostPickerView?.selectRow(1, inComponent: 1, animated: false)
        }
    /*    else if inputUserProfileOption == "_1" {
            // _1 = normal
            hostHiImageView?.alpha = 0.25
            hostViImageView?.alpha = 0.25
            guestHiImageView?.alpha = 1
            guestViImageView?.alpha = 0.25
            hostRoleLabel?.text = noAilmentsWillTalkString
            guestRoleLabel?.text = HiWillTypeString
            hostPickerView?.selectRow(1, inComponent: 0, animated: false)
            //hostPickerView?.selectRow(0, inComponent: 1, animated: false)
        }   */
        else if inputUserProfileOption == "_3" {
            // _3 = deaf-blind
            hostHiImageView?.alpha = 1
            hostViImageView?.alpha = 1
            guestHiImageView?.alpha = 0.25
            guestViImageView?.alpha = 0.25
            hostRoleLabel?.text = deafBlindMorseCodeString
            guestRoleLabel?.text = noAilmentsWillTalkString
            hostPickerView?.selectRow(1, inComponent: 0, animated: false)
            //hostPickerView?.selectRow(0, inComponent: 1, animated: false)
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        let userType = hostPickerView.selectedRow(inComponent: 0) == 0 ? "_2" :
                       hostPickerView.selectedRow(inComponent: 0) == 1 ? "_3" :
                        "_1"
        
        if userType == "_3" && supportsHaptics == false {
            dialogOK(title: "Error", message: "You cannot select deaf-blind as your device does not support our morse code functionality. Please select another option")
        }
        else {
            UserDefaults.standard.set(userType, forKey: "SE3_IOS_USER_TYPE")
            whiteSpeechViewControllerProtocol?.userProfileOptionSet(se3UserType: userType)
        }
    }
    
    func dialogOK(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            switch action.style{
            case .default:
                print("default")
                
            case .cancel:
                print("cancel")
                
            case .destructive:
                print("destructive")
                
                
            }}))
        self.present(alert, animated: true, completion: nil)
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
            //Host = HI
            hostRoleLabel?.text = HiWillTypeString
            hostHiImageView?.alpha = 1
            hostViImageView?.alpha = 0.25
            guestRoleLabel?.text = noAilmentsWillTalkString
            guestHiImageView?.alpha = 0.25
            guestViImageView?.alpha = 0.25
            //hostPickerView.reloadComponent(1) //Open up options that were previously greyed out and disable other options
        }
        else if row == 1 {
            //Host = Deaf-blind
            if supportsHaptics == false {
                errorMessageLabel?.text = "Only supported on iPhone 8 and later"
                errorMessageLabel?.isHidden = false
                return
            }
            
            hostRoleLabel?.text = deafBlindMorseCodeString
            hostHiImageView?.alpha = 1
            hostViImageView?.alpha = 1
            guestRoleLabel?.text = notDeafBlindWillTypeString //Outside the if statement as it is common for HI and normal guests if host is deaf-blind
            guestHiImageView?.alpha = 0.25
            guestViImageView?.alpha = 0.25
            //pickerView.reloadComponent(1) //Open up options that were previously greyed out and disable other options
        }
        else if row == 2 {
            //Host = Normal
            hostRoleLabel?.text = noAilmentsWillTalkString
            hostHiImageView?.alpha = 0.25
            hostViImageView?.alpha = 0.25
            guestRoleLabel?.text = HiWillTypeString
            guestHiImageView?.alpha = 1
            guestViImageView?.alpha = 0.25
            //pickerView.reloadComponent(1) //Open up options that were previously greyed out and disable other options
        }
    }
    
}
