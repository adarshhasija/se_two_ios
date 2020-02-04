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
    
    // Properties
    var inputUserProfileOption : String?
    var whiteSpeechViewControllerProtocol : WhiteSpeechViewControllerProtocol?
    var hiSwitchOnExplanationString = "Will type out messages and show the other person"
    var hiSwitchOffExplanationString = "Will speak and show the written text to the hearing-impaired person"
    var hiViString = "Use on Apple Watch.\niOS version for deaf and blind coming in a future update!"
    
    @IBOutlet weak var mainStackView: UIStackView!
    @IBOutlet weak var oneView: UIView!
    @IBOutlet weak var oneProfileAndSettingsStackView: UIStackView!
    @IBOutlet weak var oneProfilePicAndNameStackView: UIStackView!
    @IBOutlet weak var oneProfilePicAndDisabilityIconsStackView: UIStackView!
    @IBOutlet weak var oneDisabilityIconsStackView: UIStackView!
    @IBOutlet weak var oneHiImageView: UIImageView!
    @IBOutlet weak var oneViImageView: UIImageView!
    @IBOutlet weak var onePersonImageView: UIImageView!
    @IBOutlet weak var oneNameLabel: UILabel!
    @IBOutlet weak var oneSettingsStackView: UIStackView!
    @IBOutlet weak var oneSettingsHiAndExplanationStackView: UIStackView!
    @IBOutlet weak var oneSettingsHiSwitchStackView: UIStackView!
    @IBOutlet weak var oneHiLabel: UILabel!
    @IBOutlet weak var oneHiSwitch: UISwitch!
    @IBOutlet weak var oneHiExplanationLabel: UILabel!
    @IBOutlet weak var oneSettingsViAndExplanationStackView: UIStackView!
    @IBOutlet weak var oneSettingsViSwitchStackVIew: UIStackView!
    @IBOutlet weak var oneViLabel: UILabel!
    @IBOutlet weak var oneViSwitch: UISwitch!
    @IBOutlet weak var oneViExplanationLabel: UILabel!
    
    
    @IBOutlet weak var twoView: UIView!
    @IBOutlet weak var twoProfileAndSettingsStackView: UIStackView!
    @IBOutlet weak var twoProfileAndNameStackView: UIStackView!
    @IBOutlet weak var twoProfilePicAndDisabilityIconsStackVIew: UIStackView!
    @IBOutlet weak var twoPersonImageVIew: UIImageView!
    @IBOutlet weak var twoDisabilityIconsStackView: UIStackView!
    @IBOutlet weak var twoHiImageView: UIImageView!
    @IBOutlet weak var twoViImageView: UIImageView!
    @IBOutlet weak var twoNameLabel: UILabel!
    @IBOutlet weak var twoSettingsStackView: UIStackView!
    @IBOutlet weak var twoSettingsHiAndExplanationStackView: UIStackView!
    @IBOutlet weak var twoSettingsHiSwitchStackView: UIStackView!
    @IBOutlet weak var twoHiLabel: UILabel!
    @IBOutlet weak var twoHiSwitch: UISwitch!
    @IBOutlet weak var twoHiExplanationLabel: UILabel!
    @IBOutlet weak var twoSettingsViAndExplanationStackView: UIStackView!
    @IBOutlet weak var twoSettingsViSwitchStackVIew: UIStackView!
    @IBOutlet weak var twoViLabel: UILabel!
    @IBOutlet weak var twoViSwitch: UISwitch!
    @IBOutlet weak var twoViExplanationLabel: UILabel!
    
    
    
    @IBAction func oneHiSwitchValueChanged(_ sender: Any) {
        if oneHiSwitch.isOn {
            oneHiExplanationLabel?.text = hiSwitchOnExplanationString
            oneHiImageView?.alpha = 1
            twoHiSwitch?.isOn = false
            twoHiExplanationLabel?.text = hiSwitchOffExplanationString
            twoHiImageView?.alpha = 0.25
            
            self.oneHiImageView?.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            UIView.animate(withDuration: 1.0,
                           delay: 0,
                           usingSpringWithDamping: 0.2,
                           initialSpringVelocity: 6.0,
                           options: .allowUserInteraction,
                           animations: { [weak self] in
                            self?.oneHiImageView.transform = .identity
                },
                           completion: nil)
        }
        else {
            oneHiImageView?.alpha = 0.25
            oneHiExplanationLabel?.text = hiSwitchOffExplanationString
            twoHiSwitch?.isOn = true
            twoHiExplanationLabel?.text = hiSwitchOnExplanationString
            twoHiImageView?.alpha = 1
            
            self.twoHiImageView?.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            UIView.animate(withDuration: 1.0,
                           delay: 0,
                           usingSpringWithDamping: 0.2,
                           initialSpringVelocity: 6.0,
                           options: .allowUserInteraction,
                           animations: { [weak self] in
                            self?.twoHiImageView.transform = .identity
                },
                           completion: nil)
        }
    }
    @IBAction func oneViSwitchValueChanged(_ sender: Any) {
        oneViSwitch?.isOn = false
        self.oneViExplanationLabel.transform = CGAffineTransform(translationX: 20, y: 0)
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.2, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
            self.oneViExplanationLabel.transform = CGAffineTransform.identity
        }, completion: nil)
    }
    @IBAction func twoHiSwitchValueChanged(_ sender: Any) {
        twoHiSwitch?.isOn = !twoHiSwitch.isOn //Switch back to the old value
        
        //Indicate the it is the switch for Person 1 that should be changed in order to change this. Cannot change this directly
        self.oneHiSwitch?.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: .allowUserInteraction,
                       animations: { [weak self] in
                        self?.oneHiSwitch.transform = .identity
            },
                       completion: nil)
    }
    @IBAction func twoViSwitchValueChanged(_ sender: Any) {
        twoViSwitch?.isOn = false
        self.twoViExplanationLabel.transform = CGAffineTransform(translationX: 20, y: 0)
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.2, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
            self.twoViExplanationLabel.transform = CGAffineTransform.identity
        }, completion: nil)
    }
    
    
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        oneViExplanationLabel?.text = hiViString
        twoViExplanationLabel?.text = hiViString
        oneViImageView?.alpha = 0.25
        twoViImageView?.alpha = 0.25
        
        if inputUserProfileOption == nil
            || inputUserProfileOption == "_0"
            || inputUserProfileOption == "_2" {
            //No input = deaf
            // _2 = Deaf
            oneHiSwitch?.isOn = true
            oneHiExplanationLabel?.text = hiSwitchOnExplanationString
            oneHiImageView?.alpha = 1
            twoHiSwitch?.isOn = false
            twoHiExplanationLabel?.text = hiSwitchOffExplanationString
            twoHiImageView?.alpha = 0.25
        }
        else if inputUserProfileOption == "_1" {
            // _1 = normal
            oneHiSwitch?.isOn = false
            oneHiExplanationLabel?.text = hiSwitchOffExplanationString
            oneHiImageView?.alpha = 0.25
            twoHiSwitch?.isOn = true
            twoHiExplanationLabel?.text = hiSwitchOnExplanationString
            twoHiImageView?.alpha = 1
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        let userType = oneHiSwitch.isOn ? "_2" : "_1"
        UserDefaults.standard.set(userType, forKey: "SE3_IOS_USER_TYPE")
        whiteSpeechViewControllerProtocol?.userProfileOptionSet(se3UserType: userType)
    }
}
