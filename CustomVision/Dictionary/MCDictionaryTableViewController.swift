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
        let storyBoard : UIStoryboard = UIStoryboard(name: "Dictionary", bundle:nil)
        let dictionaryDetailViewController = storyBoard.instantiateViewController(withIdentifier: "MCDictionaryDetailViewController") as! MCDictionaryDetailViewController
        dictionaryDetailViewController.morseCodeCell = morseCodeCell
        self.navigationController?.pushViewController(dictionaryDetailViewController, animated: true)
    }
}
