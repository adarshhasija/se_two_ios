//
//  UserProfileTableViewController.swift
//  Suno
//
//  Created by Adarsh Hasija on 27/01/20.
//  Copyright © 2020 Adam Behringer. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAnalytics

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
    let nameOfImage = "se3_profile_pic.jpg"
    var peerIDName: String!
    var mName : String?
    var isPicExists = false
    var whiteSpeechViewControllerProtocol : WhiteSpeechViewControllerProtocol?
    
    
    @IBOutlet weak var profilePicImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var fromDeviceLabel: UILabel!
    @IBOutlet weak var ailmentLabel: UILabel!
    @IBOutlet weak var ailmentInstructionLabel: UILabel!
    
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Your Profile"
        
        loadImage()
        let userName = UserDefaults.standard.string(forKey: "SE3_IOS_USER_NAME")
        updateName(name: userName)
        //let userType = UserDefaults.standard.string(forKey: "SE3_IOS_USER_TYPE")
        //updateAilmentLabels(type: userType)
        
    }
    
    private func loadImage() {
        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
        let nsUserDomainMask    = FileManager.SearchPathDomainMask.userDomainMask
        let paths               = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
        if let dirPath          = paths.first
        {
           let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(nameOfImage)
           let image    = UIImage(contentsOfFile: imageURL.path)
           // Do whatever you want with the image
            if image != nil {
                profilePicImageView.image = image
                isPicExists = true
            }
        }
    }
    
    private func deleteImage() {
        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
        let nsUserDomainMask    = FileManager.SearchPathDomainMask.userDomainMask
        let paths               = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
        if let dirPath          = paths.first
        {
           let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(nameOfImage)
           let fileManager = FileManager.default
            do {
                try fileManager.removeItem(at: imageURL)
                profilePicImageView?.image = UIImage(named: "se_person")
                whiteSpeechViewControllerProtocol?.userProfilePicSet(image: nil)
                isPicExists = false
            } catch {
                print(error)
            }
        }
    }
    
    private func updateAilmentLabels(type: String?) {
        if type == "_2" {
            ailmentLabel?.text = "Hearing-impaired"
            ailmentInstructionLabel?.text = "On the main screen, tap the Type button to type out a message and show it to your partner. They will read it and then reply by typing or talking. You can then read their message"
        }
        else if type == "_3" {
            ailmentLabel?.text = "Deaf-blind"
            ailmentInstructionLabel?.text = "On the main screen, long press to open morse code. Type out your message in morse code. We will convert it to alphabets that your partner can read. Then can tap the Type button to reply. We will convert their message to morse code that you can read\n\nMorse code functionality is also available on our Apple Watch app"
        }
        else if type == "_1" {
            ailmentLabel?.text = "Not impaired"
            ailmentInstructionLabel?.text = "You do not have any ailment. You can type or speak a message. If you are communicating with a hearing-impaired person, just give them the phone so they can read it. If you are communicating with a deaf-blind person, we convert your message to morse code for them to read"
        }
        else {
            ailmentLabel?.text = "Ailment not declared"
            ailmentInstructionLabel?.text = "You must declare if you are deaf-blind or hearing-impaired and we will guide you accordingly"
        }
    }
    
    private func updateName(name: String?) {
        Analytics.logEvent("se3_user_name", parameters: [
            "name": name
        ])
        if name != nil {
            mName = name
            nameLabel?.text = mName
            fromDeviceLabel?.isHidden = true
        }
        else {
            mName = nil
            nameLabel?.text = peerIDName
            fromDeviceLabel?.isHidden = false
        }
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        
        let se3UserType = UserDefaults.standard.string(forKey: "SE3_IOS_USER_TYPE") ?? ""
        whiteSpeechViewControllerProtocol?.userProfileOptionSet(se3UserType: se3UserType)
    }
    
    public override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 && indexPath.row == 0 {
            let optionMenu = UIAlertController(title: nil, message: "Choose Option", preferredStyle: .actionSheet)
            let cameraAction = UIAlertAction(title: "Camera", style: .default) { _ in
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    let imagePicker = UIImagePickerController()
                    imagePicker.delegate = self
                    imagePicker.sourceType = .camera;
                    imagePicker.allowsEditing = false
                    self.present(imagePicker, animated: true, completion: nil)
                }
            }
            let galleryAction = UIAlertAction(title: "Photo Library", style: .default) { _ in
                if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                    let imagePicker = UIImagePickerController()
                    imagePicker.delegate = self
                    imagePicker.sourceType = .photoLibrary;
                    imagePicker.allowsEditing = true
                    self.present(imagePicker, animated: true, completion: nil)
                }
            }
            var deleteAction : UIAlertAction? = nil
            if isPicExists {
                deleteAction = UIAlertAction(title: "Remove Photo", style: .destructive) { _ in
                    self.deleteImage()
                }
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
                print("Cancel")
            }
            optionMenu.addAction(cameraAction)
            optionMenu.addAction(galleryAction)
            if deleteAction != nil { optionMenu.addAction(deleteAction!) }
            optionMenu.addAction(cancelAction)
            optionMenu.popoverPresentationController?.sourceView = profilePicImageView
            optionMenu.popoverPresentationController?.sourceRect = profilePicImageView.frame
            self.present(optionMenu, animated: true, completion: nil)
        }
        else if indexPath.section == 1 && indexPath.row == 1 {
            let alert = UIAlertController(title: "", message: "", preferredStyle: .alert)

            //2. Add the text field. You can configure it however you need.
            alert.addTextField { (textField) in
                textField.placeholder = "Your name"
                textField.text = self.mName
                textField.maxLength = 15
            }

            // 3. Grab the value from the text field, and print it when the user clicks OK.
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
                let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
                var name : String? = nil
                if textField?.text?.isEmpty == false {
                    name = textField!.text
                    UserDefaults.standard.set(name, forKey: "SE3_IOS_USER_NAME")
                }
                else {
                    UserDefaults.standard.removeObject(forKey: "SE3_IOS_USER_NAME")
                }
                self.updateName(name: name)
                self.whiteSpeechViewControllerProtocol?.userProfileNameSet(name: name)
                //print("Text field: \(textField.text)")
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak alert] (_) in
                alert?.dismiss(animated: true, completion: nil)
            }))

            // 4. Present the alert.
            self.present(alert, animated: true, completion: nil)
        }
        else if indexPath.section == 2 && indexPath.row == 0 {
            guard let storyBoard : UIStoryboard = self.storyboard else {
                return
            }
            let userProfileOptionsViewController = storyBoard.instantiateViewController(withIdentifier: "TwoPeopleProfileOptions") as! TwoPeopleSettingsViewController
            userProfileOptionsViewController.inputUserProfileOption = UserDefaults.standard.string(forKey: "SE3_IOS_USER_TYPE")
            userProfileOptionsViewController.whiteSpeechViewControllerProtocol = whiteSpeechViewControllerProtocol
            userProfileOptionsViewController.userProfileTableViewControllerProtocol = self as UserProfileTableViewControllerProtocol
            //self.present(userProfileOptionsViewController, animated: true, completion: nil)
            if let navigationController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController {
                navigationController.pushViewController(userProfileOptionsViewController, animated: true)
            }
        }

        
    }
    
    
}

///Protocol
protocol UserProfileTableViewControllerProtocol {
    func setUserProfileType(type : String)
}

extension UserProfileTableViewController : UserProfileTableViewControllerProtocol {
    func setUserProfileType(type: String) {
        updateAilmentLabels(type: type)
    }
}

extension UserProfileTableViewController : UIImagePickerControllerDelegate {
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        Analytics.logEvent("se3_user_image", parameters: [:])
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        profilePicImageView.image = image
        dismiss(animated:true, completion: nil)
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = nameOfImage
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        do {
            try UIImageJPEGRepresentation(image, 1.0)!.write(to: fileURL)
            print("Image Added Successfully")
            isPicExists = true
            whiteSpeechViewControllerProtocol?.userProfilePicSet(image: image)
        } catch {
            print(error)
        }
        
    }
}

extension UserProfileTableViewController : UINavigationControllerDelegate {
    
    
}

