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
        actionsList.append(ActionsCell(action: "Manual", forWho: "Deaf-blind", explanation: "Enter a number of at most 6 digits and we will translate it into vibrations", cellType: Action.MANUAL))
        actionsList.append(ActionsCell(action: "Camera", forWho: "Blind and Deaf-blind", explanation: "Point the camera at a sign, like a flat number. We will read it and convert it into vibrations for you ", cellType: Action.CAMERA_OCR))
        actionsList.append(ActionsCell(action: "Battery Level", forWho: "Blind and Deaf-blind", explanation: "Of this device as a percentage", cellType: Action.BATTERY_LEVEL))
        
        
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
        else if actionItem.cellType == Action.MANUAL {
            openManualEntryPopup()
            tableView.deselectRow(at: indexPath, animated: false) //It remains in grey selected state. got to remove that
        }
        else if actionItem.cellType == Action.BATTERY_LEVEL {
            UIDevice.current.isBatteryMonitoringEnabled = true
            let level = String(Int(UIDevice.current.batteryLevel * 100)) //int as we do not decimal
            UIDevice.current.isBatteryMonitoringEnabled = false
            openMorseCodeReadingScreen(inputAction: actionItem.cellType, alphanumericString: level)
        }
        else {
            openMorseCodeReadingScreen(inputAction: actionItem.cellType, alphanumericString: nil)
        }
    }
    
    
    private func openCamera() {
        let storyBoard : UIStoryboard = UIStoryboard(name: "MainVision", bundle:nil)
        let visionMLViewController = storyBoard.instantiateViewController(withIdentifier: "VisionMLViewController") as! VisionMLViewController
        visionMLViewController.siriShortcut = SiriShortcut.shortcutsDictionary[Action.CAMERA_OCR]
        visionMLViewController.delegateActionsTable = self
        hapticManager?.generateHaptic(code: hapticManager?.RESULT_SUCCESS)
        //self.navigationController?.present(visionMLViewController, animated: true, completion: nil)
        self.navigationController?.pushViewController(visionMLViewController, animated: true)
    }
    
    @IBAction func textFieldDidChange(_ sender: UITextField) {
        //Current controlled by maxlength. Use this if needed
    }
    
    private func openManualEntryPopup() {
        let maxLength = 7
        let alert = UIAlertController(title: "Enter a number", message: "Max " + String(maxLength) + " characters", preferredStyle: .alert)

        //2. Add the text field. You can configure it however you need.
        alert.addTextField { (textField) in
            textField.placeholder = "Enter here"
            textField.maxLength = maxLength
            textField.keyboardType = .numberPad
            //textField.addTarget(self, action: #selector(self.textFieldDidChange), for: .editingChanged) //Currently controller by maxLength. Use this if needed
        }

        // 3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            if textField?.text?.isEmpty == false {
                let text : String = textField!.text!
                Analytics.logEvent("se3_manual_success", parameters: [:]) //returned from camera
                let textFiltered = text.uppercased().trimmingCharacters(in: .whitespacesAndNewlines).filter("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".contains)
                self.openMorseCodeReadingScreen(inputAction : Action.MANUAL, alphanumericString : textFiltered)
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
    
    private func openMorseCodeReadingScreen(inputAction : Action, alphanumericString : String?) {
     /*   let storyBoard : UIStoryboard = UIStoryboard(name: "MorseCode", bundle:nil)
        let actionsMCViewController = storyBoard.instantiateViewController(withIdentifier: "ActionsMCViewController") as! ActionsMCViewController
        actionsMCViewController.mInputAction = inputAction
        if alphanumericString != nil {
            actionsMCViewController.mInputAlphanumeric = alphanumericString
        }
        hapticManager?.generateHaptic(code: hapticManager?.RESULT_SUCCESS)
        self.navigationController?.pushViewController(actionsMCViewController, animated: true)  */
        
        let storyBoard : UIStoryboard = UIStoryboard(name: "MorseCode", bundle:nil)
        let mcReaderButtonsViewController = storyBoard.instantiateViewController(withIdentifier: "MCReaderButtonsViewController") as! MCReaderButtonsViewController
        if alphanumericString != nil {
            mcReaderButtonsViewController.siriShortcut = inputAction == Action.BATTERY_LEVEL ? SiriShortcut.shortcutsDictionary[inputAction] : nil //In CAMERA mode we give the alphanumeric string directly, but we do not want a siri shortcut passed in for that
            mcReaderButtonsViewController.inputMode = inputAction
            mcReaderButtonsViewController.inputAlphanumeric = alphanumericString
        }
        else {
            mcReaderButtonsViewController.siriShortcut = SiriShortcut.shortcutsDictionary[inputAction]
            let inputs = SiriShortcut.getInputs(action: Action(rawValue: inputAction.rawValue)!)
            mcReaderButtonsViewController.inputAlphanumeric = inputs[SiriShortcut.INPUT_FIELDS.input_alphanumerics.rawValue] as? String
            mcReaderButtonsViewController.inputMorseCode = inputs[SiriShortcut.INPUT_FIELDS.input_morse_code.rawValue] as? String
            mcReaderButtonsViewController.inputMCExplanation.append(contentsOf: inputs[SiriShortcut.INPUT_FIELDS.input_mc_explanation.rawValue] as? [String] ?? []
            )
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
        Analytics.logEvent("se3_ios_cam_ret", parameters: [:]) //returned from camera
        hapticManager?.generateHaptic(code: hapticManager?.RESULT_SUCCESS) //This is just to notify the user that camera recognition is complete
        if english.count > 0 {
            self.navigationController?.popViewController(animated: false)
            Analytics.logEvent("se3_ios_cam_success", parameters: [:]) //returned from camera
            let englishFiltered = english.uppercased().trimmingCharacters(in: .whitespacesAndNewlines).filter("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".contains)
            openMorseCodeReadingScreen(inputAction : Action.CAMERA_OCR, alphanumericString : englishFiltered)
        }
    }

}
