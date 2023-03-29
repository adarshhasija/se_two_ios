//
//  MainMenuTableViewController.swift
//  Suno
//
//  Created by Adarsh Hasija on 11/10/20.
//  Copyright © 2020 Adam Behringer. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAnalytics
import NearbyInteraction
import Vision

class ActionsTableViewController : UITableViewController {
    
    var hapticManager : HapticManager?
    lazy var supportsHaptics: Bool = {
        return (UIApplication.shared.delegate as? AppDelegate)?.supportsHaptics ?? false
    }()
    var actionsList : [ActionsCell] = []
    
    override func viewDidLoad() {
        hapticManager = HapticManager(supportsHaptics: supportsHaptics)
        
        actionsList.append(ActionsCell(action: "Time", forWho: "Deaf-blind", explanation: "12 hour format", cellType: Action.TIME))
        actionsList.append(ActionsCell(action: "Date", forWho: "Deaf-blind", explanation: "Date and day of the week", cellType: Action.DATE))
        actionsList.append(ActionsCell(action: "Battery Level", forWho: "Blind and Deaf-blind", explanation: "Of this device as a percentage", cellType: Action.BATTERY_LEVEL))
        actionsList.append(ActionsCell(action: "Text in Image", forWho: "Blind and Deaf-blind", explanation: "Select an image with text in it and we will tell you in braille what the text is", cellType: Action.INPUT_IMAGE))
        //actionsList.append(ActionsCell(action: "Find someone nearby", forWho: "Blind and Deaf-blind", explanation: "We will help you find someone who is nearby. If they have an iPhone with this app installed. This app must be open on their phone and they must also be in thos mode", cellType: Action.NEARBY_INTERACTION))
        actionsList.append(ActionsCell(action: "Manual", forWho: "Deaf-blind", explanation: "Enter letters and we will translate it into braille vibrations", cellType: Action.MANUAL))
        //actionsList.append(ActionsCell(action: "Camera", forWho: "Blind and Deaf-blind", explanation: "Point the camera at a sign, like a flat number. We will read it and convert it into vibrations for you", cellType: Action.CAMERA_OCR))
        //actionsList.append(ActionsCell(action: "Morse Code Dictionary", forWho: "Blind and Deaf-blind", explanation: "To be used as reference when using Morse Code Typing feature in the Apple Watch app", cellType: Action.MC_DICTIONARY))
        
        setupNavBar()
    }
    
    @IBAction func settingsButtonTapped(_ sender: Any) {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Settings", bundle:nil)
        let settingsTableViewController = storyBoard.instantiateViewController(withIdentifier: "SettingsTableViewController") as! SettingsTableViewController
        if let navigationController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController {
            navigationController.pushViewController(settingsTableViewController, animated: true)
        }
    }
    
    private func setupNavBar() {
        let settingsButton = UIButton(type: .custom)
            settingsButton.setImage(UIImage(systemName: "gear"), for: .normal)
            settingsButton.addTarget(self, action: #selector(settingsButtonTapped), for: .touchUpInside)
        let settingsBarButtonItem = UIBarButtonItem(customView: settingsButton)
        settingsBarButtonItem.accessibilityLabel = "Settings Button"
        settingsBarButtonItem.accessibilityHint = "Settings Button"
        self.navigationItem.setRightBarButtonItems([settingsBarButtonItem], animated: true)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actionsList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ActionsListCell = self.tableView.dequeueReusableCell(withIdentifier: "ActionsListCell") as! ActionsListCell
        let actionItem = actionsList[indexPath.row]
        
        cell.accessibilityLabel = actionItem.accessibilityLabel
        cell.accessibilityTraits = UIAccessibilityTraitButton
        cell.actionsLabel?.text = actionItem.action
        if actionItem.forWho != nil { cell.forLabel?.text = "For: " + actionItem.forWho! }
        if actionItem.explanation != nil { cell.explanationLabel?.text = actionItem.explanation! }
                
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let actionItem = actionsList[indexPath.row]
        Analytics.logEvent("se3_ios_swipe_up", parameters: [
            "state" : "action_"+actionItem.cellType.rawValue
        ])
        if actionItem.cellType == Action.CAMERA_OCR {
            openCamera()
        }
        else if actionItem.cellType == Action.MC_DICTIONARY {
            let storyBoard : UIStoryboard = UIStoryboard(name: "Dictionary", bundle:nil)
            let dictionaryViewController = storyBoard.instantiateViewController(withIdentifier: "UITableViewController-HHA-Ce-gYY") as! MCDictionaryTableViewController
            dictionaryViewController.typeToDisplay = "morse_code"
            self.navigationController?.pushViewController(dictionaryViewController, animated: true)
        }
        else if actionItem.cellType == Action.MANUAL {
            openManualEntryPopup()
            tableView.deselectRow(at: indexPath, animated: false) //It remains in grey selected state. got to remove that
        }
        else if actionItem.cellType == Action.TIME {
            let alphanumericString = LibraryCustomActions.getCurrentTimeInAlphanumeric(format: "12")
            openMorseCodeReadingScreen(alphanumericString: alphanumericString, inputAction: /*actionItem.cellType*/Action.MANUAL)
        }
        else if actionItem.cellType == Action.BATTERY_LEVEL {
            UIDevice.current.isBatteryMonitoringEnabled = true
            let level = String(Int(UIDevice.current.batteryLevel * 100)) //int as we do not decimal
            UIDevice.current.isBatteryMonitoringEnabled = false
            openMorseCodeReadingScreen(alphanumericString: level, inputAction: /*actionItem.cellType*/Action.MANUAL)
        }
        else if actionItem.cellType == Action.NEARBY_INTERACTION {
            var isSupported: Bool
            if #available(iOS 16.0, *) {
                isSupported = NISession.deviceCapabilities.supportsPreciseDistanceMeasurement
            } else {
                isSupported = NISession.isSupported
            }
            if !isSupported {
                print("unsupported device")
                // Ensure that the device supports NearbyInteraction and present
                //  an error message view controller, if not.
                let storyboard = UIStoryboard(name: "ActionsList", bundle: nil)
                let unsupportedDeviceViewController : UIViewController? = storyboard.instantiateViewController(withIdentifier: "unsupportedDeviceMessage")
                if unsupportedDeviceViewController == nil { return }
                self.navigationController?.pushViewController(unsupportedDeviceViewController!, animated: true)
            }
            else {
                let viewController:UIViewController = UIStoryboard(name: "ActionsList", bundle: nil).instantiateViewController(withIdentifier: "NearbyInteractionsViewController") as UIViewController
                self.present(viewController, animated: false, completion: nil)
            }
        }
        else if actionItem.cellType == Action.DATE {
            let day = (Calendar.current.component(.day, from: Date()))
            let weekdayInt = (Calendar.current.component(.weekday, from: Date()))
            let weekdayString = Calendar.current.weekdaySymbols[weekdayInt - 1]
            //let alphanumericString = String(day) + weekdayString.prefix(2).uppercased() //Use this if converting it to morse code as wel want a shorter string
            let weekdayStringFirstLetterCapital = weekdayString.prefix(1).uppercased() + weekdayString.dropFirst().lowercased()
            let alphanumericString = String(day) + " " + weekdayStringFirstLetterCapital 
            self.openMorseCodeReadingScreen(alphanumericString: alphanumericString, inputAction: Action.MANUAL)
        }
        else if actionItem.cellType == Action.INPUT_IMAGE {
            openInputImageOptions()
        }
        else {
            openMorseCodeReadingScreen(alphanumericString: nil, inputAction: actionItem.cellType)
        }
    }
    
    private func openInputImageOptions() {
        ImagePickerManager.shared.showActionSheet(vc: self, completion: {image,sourceType in
            VisionManager.shared.getImageDescription(vc: self, originalImage: image, completion: { imageDescription in
                DispatchQueue.main.async {
                    self.openMorseCodeReadingScreen(alphanumericString: imageDescription, inputAction: Action.MANUAL)
                }
                
            })
          /*  do {
                guard let cgImage = image.cgImage else {
                    return
                }
                let classifierRequestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                try classifierRequestHandler.perform(self.classificationRequest)
            } catch {
              print(error)
            }   */
        })
    }
    
    lazy var classificationRequest: [VNRequest] = {
      do {
        // Load the Custom Vision model.
        // To add a new model, drag it to the Xcode project browser making sure that the "Target Membership" is checked.
        // Then update the following line with the name of your new model.
        //let model = try VNCoreMLModel(for: AdarshBlueBackpack().model) //try VNCoreMLModel(for: Rupees().model)
        //let classificationRequest = VNCoreMLRequest(model: model, completionHandler: self.handleClassification)
          let classificationRequest = VNRecognizeTextRequest(completionHandler: self.handleClassificationText)
        return [ classificationRequest ]
      } catch {
        fatalError("Can't load Vision ML model: \(error)")
      }
    }()
    
    func handleClassificationText(request: VNRequest, error: Error?) {
        if let results = request.results, !results.isEmpty {
              if let requestResults = request.results as? [VNRecognizedTextObservation] {
                  var recognizedText = ""
                  for observation in requestResults {
                      guard let candidiate = observation.topCandidates(1).first else { return }
                        recognizedText += candidiate.string
                      //recognizedText += "\n"
                  }
                  DispatchQueue.main.async {
                      //self.delegate?.setTextFromCamera(english: recognizedText)
                      //self.delegateActions?.setTextFromCamera(english: recognizedText)
                      self.openMorseCodeReadingScreen(alphanumericString: recognizedText, inputAction: Action.MANUAL)
                      self.dismiss(animated: true, completion: nil) //This is now being done in ActionsTableViewController. Uncomment this line if calling from a different view.
                  }
                  //self.bubbleLayer.string = recognizedText
              }
          }
    }
    
    
    private func openCamera() {
        let storyBoard : UIStoryboard = UIStoryboard(name: "MainVision", bundle:nil)
        let cameraViewController = storyBoard.instantiateViewController(withIdentifier: "CameraViewController") as! CameraViewController
        cameraViewController.siriShortcut = SiriShortcut.shortcutsDictionary[Action.CAMERA_OCR]
        cameraViewController.delegateActionsTable = self
        hapticManager?.generateHaptic(code: hapticManager?.RESULT_SUCCESS)
        self.navigationController?.pushViewController(cameraViewController, animated: true)
    }
    
    @IBAction func textFieldDidChange(_ sender: UITextField) {
        //Current controlled by maxlength. Use this if needed
    }
    
    /*
     The length limitation imposed is due to hardware. Observed on iPhone 12 Mini that we can get exactly 5 braille grids played before screen locks and haptics stopped. In future we will try to keep playing it in the background
     */
    private func openManualEntryPopup() {
        let maxLength = 5
        let alert = UIAlertController(title: "Enter letters or numbers only", message: "No special characters", preferredStyle: .alert)

        //2. Add the text field. You can configure it however you need.
        alert.addTextField { (textField) in
            textField.placeholder = "Enter here"
            //textField.maxLength = maxLength
            //textField.keyboardType = .numberPad
            //textField.addTarget(self, action: #selector(self.textFieldDidChange), for: .editingChanged) //Currently controller by maxLength. Use this if needed
        }

        // 3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            if textField?.text?.isEmpty == false {
                let text : String = textField!.text!
                Analytics.logEvent("se3_manual_success", parameters: [:]) //returned from camera
                self.openMorseCodeReadingScreen(alphanumericString: text, inputAction: Action.MANUAL)
                alert?.dismiss(animated: true, completion: nil)
            }
            //print("Text field: \(textField.text)")
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak alert] (_) in
            alert?.dismiss(animated: true, completion: nil)
        }))

        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
    }
    
    func showDialog(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { [weak alert] (_) in
            alert?.dismiss(animated: true, completion: nil)
        }))

        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
    }
    
    private func openMorseCodeReadingScreen(alphanumericString : String?, inputAction: Action) {
        guard let alphanumericStringFiltered = alphanumericString?.trimmingCharacters(in: .whitespacesAndNewlines)
            .filter("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789: ".contains).removeExtraSpaces() else {
            showDialog(title: "Error", message: "Sorry an error occured, please try again")
            return
        }
        
        guard let mcReaderButtonsViewController = (UIApplication.shared.delegate as? AppDelegate)?.getMorseCodeReadingScreen(inputAction: inputAction, alphanumericString: alphanumericStringFiltered) else {
            showDialog(title: "Error", message: "There was an issue opening the next screen. Please try again")
            return
        }
        
        if alphanumericStringFiltered.count < 1 {
            showDialog(title: "Error", message: "There was an issue with the text. Letters and numbers only. No special characters")
            return
        }
        hapticManager?.generateHaptic(code: hapticManager?.RESULT_SUCCESS)
        self.navigationController?.pushViewController(mcReaderButtonsViewController, animated: true)
    }
}

protocol ActionsTableViewControllerProtocol {
    
    //To get text recognized by the camera
    func setTextFromCamera(english : String)
}

extension ActionsTableViewController : ActionsTableViewControllerProtocol {
    
    func setTextFromCamera(english: String) {
        guard navigationController?.topViewController is BrailleViewController == false else {
            //If FALSE, the we have not yet displayed the camera result to user
            //If TRUE, we have displayed the camera result to user already. This is a 2nd or later call
            return
        }
        
        Analytics.logEvent("se3_ios_cam_ret", parameters: [:]) //returned from camera
        hapticManager?.generateHaptic(code: hapticManager?.RESULT_SUCCESS) //This is just to notify the user that camera recognition is complete
        if english.count > 0 {
            //self.navigationController?.popViewController(animated: false) //We are not popping here as it breaks VoiceOver. VoiceOver picks elements from this page instead of from the next page. Therefore we will be popping the camera view on the return. See viewDidAppear in CameraViewController
            Analytics.logEvent("se3_ios_cam_success", parameters: [:]) //returned from camera
            openMorseCodeReadingScreen(alphanumericString: english, inputAction: Action.CAMERA_OCR)
        }
    }

}
