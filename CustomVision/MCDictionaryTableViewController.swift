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
    var type : String? = nil
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Dictionary"
        
        let morseCode = MorseCode()
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
        var finalString = "To type this out you must "
        for char in morseCodeCell.morseCode {
            if char == "." {
                finalString += "tap"
            }
            else if char == "-" {
                finalString += "swipe right"
            }
            
            finalString += ","
        }
        finalString.removeLast() //Removes the last comma
        
        
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
