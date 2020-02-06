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
    // _1 = User is not HI or VI
    // _2 = User is HI
    
    // Properties
    var inputUserProfileOption : String?
    var whiteSpeechViewControllerProtocol : WhiteSpeechViewControllerProtocol?
    var hiSwitchOnExplanationString = "Will type out messages and show the other person"
    var hiSwitchOffExplanationString = "Will speak and show the written text to the hearing-impaired person"
    var hiViString = "Use on Apple Watch.\niOS version for deaf and blind coming in a future update!"
    var HiWillTypeString = "Hearing-impaired:\nWill type"
    var noAilmentsWillTalkString = "No ailments:\nWill talk"
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
        
        pickerData.append(contentsOf: ["Hearing-impaired", /*"Deaf-blind",*/ "No ailments"])
        hostPickerView.delegate = self
        hostPickerView.dataSource = self
        errorMessageLabel?.text = ""
        
        //oneViImageView?.alpha = 0.25
        //twoViImageView?.alpha = 0.25
        
        if inputUserProfileOption == nil
            || inputUserProfileOption == "_0"
            || inputUserProfileOption == "_2" {
            //No input = deaf
            // _2 = Deaf
            hostHiImageView?.alpha = 1
            guestHiImageView?.alpha = 0.25
            hostRoleLabel?.text = HiWillTypeString
            guestRoleLabel?.text = noAilmentsWillTalkString
            hostPickerView?.selectRow(0, inComponent: 0, animated: false)
        }
        else if inputUserProfileOption == "_1" {
            // _1 = normal
            hostHiImageView?.alpha = 0.25
            guestHiImageView?.alpha = 1
            hostRoleLabel?.text = noAilmentsWillTalkString
            guestRoleLabel?.text = HiWillTypeString
            hostPickerView?.selectRow(1, inComponent: 0, animated: false)
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        let userType = hostPickerView.selectedRow(inComponent: 0) == 0 ? "_2" : "_1"
        UserDefaults.standard.set(userType, forKey: "SE3_IOS_USER_TYPE")
        whiteSpeechViewControllerProtocol?.userProfileOptionSet(se3UserType: userType)
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
        if component == 0 && row == 0 {
            hostRoleLabel?.text = HiWillTypeString
            guestRoleLabel?.text = noAilmentsWillTalkString
            hostHiImageView?.alpha = 1
            guestHiImageView?.alpha = 0.25
        }
        else if component == 0 && row == 1 {
            hostRoleLabel?.text = noAilmentsWillTalkString
            guestRoleLabel?.text = HiWillTypeString
            hostHiImageView?.alpha = 0.25
            guestHiImageView?.alpha = 1
        }
    }
    
}
