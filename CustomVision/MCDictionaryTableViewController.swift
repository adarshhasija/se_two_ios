//
//  MCDictionaryTableViewController.swift
//  Suno
//
//  Created by Adarsh Hasija on 11/05/20.
//  Copyright © 2020 Adam Behringer. All rights reserved.
//

import Foundation
import UIKit

public class MCDictionaryTableViewController : UITableViewController {
    
    var morseCodeArray : [MorseCodeCell] = []
    var typeToDisplay : String? = nil
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        if typeToDisplay == "actions" {
            self.title = "Actions"
        }
        else {
            self.title = "Dictionary"
        }
        
        let morseCode = MorseCode(type: typeToDisplay, operatingSystem: "iOS")
        morseCodeArray.append(contentsOf: morseCode.mcArray)
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.morseCodeArray.count
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // create a new cell if needed or reuse an old one
        let cell:MCDiontionaryCell = self.tableView.dequeueReusableCell(withIdentifier: "MCDictionaryCell") as! MCDiontionaryCell!
        
        // set the text from the data model
        cell.englishLabel?.text = self.morseCodeArray[indexPath.row].english
        cell.morseCodeLabel?.text = self.morseCodeArray[indexPath.row].morseCode
        
        return cell
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let morseCodeCell = morseCodeArray[indexPath.row]
     /*   var finalString = "To type this out you must "
        for char in morseCodeCell.morseCode {
            if char == "." {
                finalString += "tap"
            }
            else if char == "-" {
                finalString += "swipe right"
            }
            
            finalString += ","
        }
        finalString.removeLast() //Removes the last comma   */
        var finalString = ""
        if morseCodeCell.english == "TIME" {
            finalString += "To get the time in morse code, you must tap once and swipe up. You will get the current time in 24 hour format"
        }
        else if morseCodeCell.english == "DATE" {
            finalString += "To get the date in morse code, you must tap twice and swipe up. You will get the date and the first 2 letters of the day of the week"
        }
        else if morseCodeCell.english == "CAMERA" {
            finalString += "To open the camera for camera related actions, you must tap three times and swipe up"
        }
        else {
            finalString += "This is the morse code combination for the character " + morseCodeCell.english
        }
        
        
        let alert = UIAlertController(title: morseCodeCell.english, message: finalString, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            switch action.style{
            case .default:
                print("default")
                
            case .cancel:
                print("cancel")
                
            case .destructive:
                print("destructive")
                
                
            }}))
        self.present(alert, animated: true, completion: nil)
    }
}
