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
        
        actionsList.append(ActionsCell(action: "Text On Door", forWho: "Blind and Deaf-blind", explanation: "Tapping this will open the camera. Then simply point your phone at the door where the text is written. Wait for a few seconds and the app will read the text. Blind users can then tap for audio. Deaf-blind users can scroll through the morse code ", cellType: Action.CAMERA_OCR))
        actionsList.append(ActionsCell(action: "Current Time", forWho: "Deaf-blind", explanation: "Deaf-blind person can get the current time through vibrations from the phone", cellType: Action.TIME))
        actionsList.append(ActionsCell(action: "Date And Day Of Week", forWho: "Deaf-blind", explanation: "Deaf-blind person can get the date and day of the week through vibrations from the phone", cellType: Action.DATE))
        
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
        if actionItem.explanation != nil { cell.explanationLabel?.text = "How: " + actionItem.explanation! }
                
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let actionItem = actionsList[indexPath.row]
        if actionItem.cellType == Action.CAMERA_OCR {
            openCamera()
        }
        else {
            openMorseCodeReadingScreen(inputAction: actionItem.cellType.rawValue, alphanumericString: nil)
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
        visionMLViewController.delegateActionsTable = self
        hapticManager?.generateHaptic(code: hapticManager?.RESULT_SUCCESS)
        //self.navigationController?.present(visionMLViewController, animated: true, completion: nil)
        self.navigationController?.pushViewController(visionMLViewController, animated: true)
    }
    
    private func openMorseCodeReadingScreen(inputAction : String, alphanumericString : String?) {
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
        else if inputAction == "TIME" {
            mcReaderButtonsViewController.inputAlphanumeric = LibraryCustomActions.getCurrentTimeInAlphanumeric(format: "12")
            mcReaderButtonsViewController.inputMorseCode = LibraryCustomActions.getCurrentTimeInDotsDashes()
            mcReaderButtonsViewController.inputMCExplanation = "Explanation:\nThere are 3 sets of characters.\nSet 1 is the hour.\nDash = long vibration = 5 hours.\nDot = short vibration = 1 hour.\nExample: 1 long vibration and 1 short vibration = 6.\nSet 2 is the minute.\nDash = 1 long vibration = 5 mins.\nDot = 1 short vobration = 1 min.\nExample: 1 long vibration and 1 short vibration = 6 minutes.\nLast set is AM or PM.\nShort vibration = AM.\nLong vibration = PM."
        }
        else if inputAction == "DATE" {
            mcReaderButtonsViewController.inputAlphanumeric = LibraryCustomActions.getCurrentDateInAlphanumeric()
            mcReaderButtonsViewController.inputMorseCode = LibraryCustomActions.getCurrentDateInDotsDashes()
            mcReaderButtonsViewController.inputMCExplanation = "Explanation:\nThere are 2 sets of characters.\nSet 1 is the date.\nDash = long vibration = 5 days.\nDot = short vibration = 1 day.\nExample: 1 long vibration and 1 short vibration = 6th.\nSet 2 is the day of the week.\nEvery dot is number of days after Sunday.\nExample: 2 short vibrations = Monday."
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
            openMorseCodeReadingScreen(inputAction : "INPUT_ALPHANUMERIC", alphanumericString : englishFiltered)
        }
    }

}
