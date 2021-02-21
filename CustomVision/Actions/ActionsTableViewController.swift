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
        actionsList.append(ActionsCell(action: "Camera", forWho: "Blind and Deaf-blind", explanation: "Point the camera at a sign, like a flat number. We will read it and convert it into vibrations for you ", cellType: Action.CAMERA_OCR))
        
        
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
        else {
            openMorseCodeReadingScreen(inputAction: actionItem.cellType, alphanumericString: nil)
        }
     /*   let selectedIndex = indexPath.row
        if selectedIndex == 0 {
            openCamera()
        }
        else if selectedIndex == 1 {
            openMorseCodeReadingScreen(inputAction: "DATE", alphanumericString: nil)
        }
        else if selectedIndex == 2 {
            openMorseCodeReadingScreen(inputAction: "TIME", alphanumericString: nil)
        }   */
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
            let englishFiltered = english.uppercased().trimmingCharacters(in: .whitespacesAndNewlines).filter("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ".contains)
            openMorseCodeReadingScreen(inputAction : Action.INPUT_ALPHANUMERIC, alphanumericString : englishFiltered)
        }
    }

}
