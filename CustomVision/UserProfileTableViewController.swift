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
    let nameOfImage = "se3_profile_pic.jpg"
    var isPicExists = false
    var whiteSpeechViewControllerProtocol : WhiteSpeechViewControllerProtocol?
    
    
    @IBOutlet weak var profilePicImageView: UIImageView!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Your Profile"
        
        loadImage()
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
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        
        let se3UserType = UserDefaults.standard.string(forKey: "SE3_IOS_USER_TYPE") ?? ""
        whiteSpeechViewControllerProtocol?.userProfileOptionSet(se3UserType: se3UserType)
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
            self.present(optionMenu, animated: true, completion: nil)
        }
        else if indexPath.section == 2 && indexPath.row == 0 {
            guard let storyBoard : UIStoryboard = self.storyboard else {
                return
            }
            let userProfileOptionsViewController = storyBoard.instantiateViewController(withIdentifier: "TwoPeopleProfileOptions") as! TwoPeopleSettingsViewController
               userProfileOptionsViewController.inputUserProfileOption = UserDefaults.standard.string(forKey: "SE3_IOS_USER_TYPE")
               userProfileOptionsViewController.whiteSpeechViewControllerProtocol = whiteSpeechViewControllerProtocol
               //self.present(userProfileOptionsViewController, animated: true, completion: nil)
               if let navigationController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController {
                   navigationController.pushViewController(userProfileOptionsViewController, animated: true)
               }
        }
    }
}

extension UserProfileTableViewController : UIImagePickerControllerDelegate {
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
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

