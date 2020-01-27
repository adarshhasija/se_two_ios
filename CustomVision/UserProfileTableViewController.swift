//
//  UserProfileTableViewController.swift
//  Suno
//
//  Created by Adarsh Hasija on 27/01/20.
//  Copyright © 2020 Adam Behringer. All rights reserved.
//

import Foundation
import UIKit

public class UserProfileTableViewController : UITableViewController {
    
    class UserProfile {
        var myAbilitiesDescription: String
        var partnerAbilitiesDescription: String
        
        init(myAbilitiesDescription: String, partnerAbilitiesDescription: String) {
            self.myAbilitiesDescription = myAbilitiesDescription
            self.partnerAbilitiesDescription = partnerAbilitiesDescription
        }
    }
    
    // Properties
    var inputUserProfileOption : String?
    var whiteSpeechViewControllerProtocol : WhiteSpeechViewControllerProtocol?
    var userProfileOptions : [UserProfile] = []
    var selectedIndex : IndexPath?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Choose One"
        if inputUserProfileOption == nil {
            navigationItem.hidesBackButton = true
        }
        
        
        userProfileOptions.append(UserProfile(myAbilitiesDescription: "I can see, hear and speak", partnerAbilitiesDescription: "I will use this app to talk to someone who cannot hear and speak"))
        
        userProfileOptions.append(UserProfile(myAbilitiesDescription: "I cannot hear or speak", partnerAbilitiesDescription: "I will use this app to talk to someone who can hear and speak"))
        
        if inputUserProfileOption == "_1" {
            selectedIndex = IndexPath(row: 0, section: 0)
        }
        else if inputUserProfileOption == "_2" {
            selectedIndex = IndexPath(row: 1, section: 0)
        }
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.userProfileOptions.count
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // create a new cell if needed or reuse an old one
        let cell:UserProfileOptionTableViewCell = self.tableView.dequeueReusableCell(withIdentifier: "UserProfileOptionCell") as! UserProfileOptionTableViewCell!
        
        // set the text from the data model
        cell.myAbiltiesDescriptionLabel?.text = self.userProfileOptions[indexPath.row].myAbilitiesDescription
        cell.partnerAbilitiesDescriptionLabel?.text = self.userProfileOptions[indexPath.row].partnerAbilitiesDescription
        
        if selectedIndex == indexPath {
            cell.accessoryType = .checkmark
        }
        else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    public override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .checkmark
        }
        navigationItem.hidesBackButton = false
        
        if selectedIndex != nil {
            if let cell = tableView.cellForRow(at: selectedIndex!) {
                cell.accessoryType = .none
            }
        }
        
        selectedIndex = indexPath
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        var type = ""
        if selectedIndex?.row == 0 {
            type = "_1"
        }
        else if selectedIndex?.row == 1 {
            type = "_2"
        }
        UserDefaults.standard.set(type, forKey: "SE3_IOS_USER_TYPE")
        
        whiteSpeechViewControllerProtocol?.userProfileOptionSet(se3UserType: type)
    }
}
