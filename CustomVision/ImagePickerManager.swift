//
//  ImagePickerManager.swift
//  Suno
//
//  Created by Adarsh Hasija on 27/03/23.
//  Copyright © 2023 Adam Behringer. All rights reserved.
//

import Foundation

import UIKit

class ImagePickerManager: NSObject {
  static let shared = ImagePickerManager()
  
  //Initializer access level change now
  private override init() {}
  
  fileprivate var currentVC: UIViewController?
  var imagePicked: ((UIImage) -> Void)?
  var sourceType: UIImagePickerController.SourceType?
  var completion: ((_ image: UIImage, _ sourceType: UIImagePickerController.SourceType) -> Void)?
  
  func showActionSheet(vc: UIViewController,
                       completion: @escaping (_ image: UIImage,
                                              _ sourceType: UIImagePickerController.SourceType) -> Void) {
    self.currentVC = vc
    self.completion = completion

    // Title ActionSheet
    let actionSheet = UIAlertController(title: "Upload Photo",
                                        message: nil,
                                        preferredStyle: .actionSheet)
    
    // Take Photo ActionSheet
    let photoAction = UIAlertAction(title: "Take Photo", style: .default) { action -> Void in
      self.sourceType = .camera
      self.getImage(fromSourceType: .camera)
    }
    actionSheet.addAction(photoAction)
    
    // Choose from Gallery ActionSheet
    let galleryAction = UIAlertAction(title: "Choose from Gallery", style: .default) { action -> Void in
      self.sourceType = .photoLibrary
      self.getImage(fromSourceType: .photoLibrary)
    }
    actionSheet.addAction(galleryAction)
    
    // Cancel ActionSheet
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
    actionSheet.addAction(cancelAction)
    
    currentVC?.present(actionSheet, animated: true)
  }
  
  private func getImage(fromSourceType sourceType: UIImagePickerController.SourceType) {
    //Check is source type available
    if UIImagePickerController.isSourceTypeAvailable(sourceType) {
      let imagePickerController = UIImagePickerController()
      imagePickerController.delegate = self
      imagePickerController.sourceType = sourceType
      currentVC?.present(imagePickerController, animated: true)
    }
  }
}

extension ImagePickerManager: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  func imagePickerController(_ picker: UIImagePickerController,
                             didFinishPickingMediaWithInfo info: [String : Any]) {

    if let image = info[UIImagePickerControllerOriginalImage] as? UIImage,
      let sourceType = self.sourceType {
      self.imagePicked?(image)
      self.completion?(image, sourceType)
        picker.dismiss(animated: true)
    } else {
      print("Something went wrong")
    }
  }
}
