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
    
    override func viewDidLoad() {
        hapticManager = HapticManager(supportsHaptics: supportsHaptics)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedIndex = indexPath.row
        if selectedIndex == 0 {
            openCamera()
        }
        else if selectedIndex == 1 {
            openMorseCodeReadingScreen(inputAction: "DATE", alphanumericString: nil)
        }
        else if selectedIndex == 2 {
            openMorseCodeReadingScreen(inputAction: "TIME", alphanumericString: nil)
        }
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
