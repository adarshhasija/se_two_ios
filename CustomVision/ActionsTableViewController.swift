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

class ActionsTableViewController : UITableViewController {
    
    let searchController = UISearchController()
    var hapticManager : HapticManager?
    lazy var supportsHaptics: Bool = {
        return (UIApplication.shared.delegate as? AppDelegate)?.supportsHaptics ?? false
    }()
    //var actionsList : [ContentCell] = []
    var filteredData: [ContentCell] = []
    {
        didSet
        {
            tableView.reloadData()
        }
    }

    // once we get our data, we will put it into filtered array
    // user will interact only with filtered array
    var actionsList: [ContentCell] = []
    {
        didSet
        {
            filteredData = actionsList
        }
    }
    
    override func viewDidLoad() {
        hapticManager = HapticManager(supportsHaptics: supportsHaptics)
        
        actionsList.append(ContentCell(action: "Time", tags: ["Others"], explanation: "12 hour format", cellType: Action.TIME))
        actionsList.append(ContentCell(action: "Date", tags: ["Others"], explanation: "Date and day of the week", cellType: Action.DATE))
        actionsList.append(ContentCell(action: "Battery Level", tags: ["Others"], explanation: "Of this device as a percentage", cellType: Action.BATTERY_LEVEL))
        //actionsList.append(ContentCell(action: "Find someone nearby", explanation: "We will help you find someone who is nearby. If they have an iPhone with this app installed. This app must be open on their phone and they must also be in thos mode", cellType: Action.NEARBY_INTERACTION))
        actionsList.append(ContentCell(action: "Manual", explanation: "Enter letters and we will translate it into braille vibrations", cellType: Action.MANUAL))
        //actionsList.append(ContentCell(action: "Camera", explanation: "Point the camera at a sign, like a flat number. We will read it and convert it into vibrations for you", cellType: Action.CAMERA_OCR))
        //actionsList.append(ContentCell(action: "Morse Code Dictionary", explanation: "To be used as reference when using Morse Code Typing feature in the Apple Watch app", cellType: Action.MC_DICTIONARY))
        
        setupNavBar()
        initSearchController()
        
        if let path = Bundle.main.path(forResource: "Content", ofType: "json") {
                do {
                    let jsonData = try NSData(contentsOfFile: path, options: NSData.ReadingOptions.mappedIfSafe)
                    do {
                        let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: jsonData as Data, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                        if let allContent : [NSDictionary] = jsonResult["content"] as? [NSDictionary] {
                            for contentObj: NSDictionary in allContent {
                                let id = contentObj["id"]
                                let title = contentObj["title"] as! String
                                let tags = contentObj["tags"] as? [String] ?? []
                                let content = contentObj["content"] as! String
                                actionsList.append(ContentCell(action: title, tags: tags, explanation: content, cellType: Action.CONTENT))
                            }
                        }
                    } catch {}
                } catch {}
            }
        
        //Tried with a txt file
   /*     let path = Bundle.main.path(forResource: "OldMacDonald", ofType: "rtf") // file path for file "data.txt"
        let content = try? String(contentsOfFile: path!, encoding: String.Encoding.utf8)

        print(content) // prints the content of data.txt
        actionsList.append(ContentCell(action: "ABC", explanation: content!, cellType: Action.CONTENT)) */
    }
    
    func initSearchController() {
        searchController.loadViewIfNeeded()
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController = searchController
        searchController.searchBar.delegate = self
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
        return filteredData.count //actionsList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ActionsListCell = self.tableView.dequeueReusableCell(withIdentifier: "ActionsListCell") as! ActionsListCell
        let actionItem = filteredData[indexPath.row] //actionsList[indexPath.row]
        
        cell.accessibilityLabel = actionItem.accessibilityLabel
        cell.accessibilityTraits = UIAccessibilityTraitButton
        cell.actionsLabel?.text = actionItem.action
        if actionItem.explanation != nil { cell.explanationLabel?.text = actionItem.explanation! }
                
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let actionItem = filteredData[indexPath.row] //actionsList[indexPath.row]
        Analytics.logEvent("se3_ios_swipe_up", parameters: [
            "state" : "action_"+actionItem.cellType.rawValue
        ])
        if actionItem.cellType == Action.CONTENT {
            let text = actionItem.explanation
            self.openMorseCodeReadingScreen(alphanumericString: text, inputAction: Action.MANUAL)
        }
        else if actionItem.cellType == Action.SEARCH {
            searchController.searchBar.text = actionItem.action
            let searchText = actionItem.action.lowercased()
            search(searchText: searchText)
        }
        else if actionItem.cellType == Action.CAMERA_OCR {
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
        else {
            openMorseCodeReadingScreen(alphanumericString: nil, inputAction: actionItem.cellType)
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
                guard let alphanumericStringFiltered : String? = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    .filter("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.\n: ".contains).removeExtraSpaces() else {
                    self.showDialog(title: "Error", message: "Sorry an error occured, please try again")
                    return
                }
                self.openMorseCodeReadingScreen(alphanumericString: alphanumericStringFiltered, inputAction: Action.MANUAL)
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
    /*    guard let alphanumericStringFiltered = alphanumericString?.trimmingCharacters(in: .whitespacesAndNewlines)
            .filter("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.\n: ".contains).removeExtraSpaces() else {
            showDialog(title: "Error", message: "Sorry an error occured, please try again")
            return
        }   */
        guard let alphanumericStringFiltered = alphanumericString else {
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
    
    func search(searchText: String) {
        let filtered = actionsList.filter({ $0.textForSearch.lowercased().contains(searchText) })
        filteredData = filtered.isEmpty ? actionsList : filtered
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

extension ActionsTableViewController: UISearchBarDelegate
{
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    {
        let searchText = searchText.lowercased()
        search(searchText: searchText)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        filteredData = actionsList
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        var filtered : [ContentCell] = []
        filtered.append(ContentCell(action: "Nursery Rhymes", explanation: "", cellType: Action.SEARCH))
        filtered.append(ContentCell(action: "Others", explanation: "", cellType: Action.SEARCH))
        filteredData = filtered
        
        return true
    }
}

extension ActionsTableViewController: UISearchResultsUpdating
{
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
    }
}
