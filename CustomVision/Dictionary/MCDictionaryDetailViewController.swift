//
//  DictionaryDetailViewController.swift
//  Suno
//
//  Created by Adarsh Hasija on 14/06/20.
//  Copyright © 2020 Adam Behringer. All rights reserved.
//

import Foundation
import UIKit

class MCDictionaryDetailViewController : UIViewController {
    
    var morseCodeCell : MorseCodeCell?
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var aboutLabel: UILabel!
    @IBOutlet weak var blindLabel: UILabel!
    @IBOutlet weak var blindInstructionsLabel: UILabel!
    @IBOutlet weak var deafBlindLabel: UILabel!
    @IBOutlet weak var deafBlindInstructionsLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Ignoring the settings in storyboard for font. Setting them here
        titleLabel.font = UIFont.preferredFont(forTextStyle: .body).bold() //Not doing it in storyboard as we cannot add BOLD to textStyle. Overriding storyboard for the titles here
        
        aboutLabel?.isHidden = true
        blindLabel?.isHidden = true
        blindInstructionsLabel?.isHidden = true
        deafBlindLabel?.isHidden = true
        //aboutLabel.font = UIFont.preferredFont(forTextStyle: .body)
        //blindLabel.font = UIFont.preferredFont(forTextStyle: .body).bold()
        //blindInstructionsLabel.font = UIFont.preferredFont(forTextStyle: .body)
        //deafBlindLabel.font = UIFont.preferredFont(forTextStyle: .body).bold()
        //deafBlindInstructionsLabel.font = UIFont.preferredFont(forTextStyle: .body)
        
        titleLabel.text = morseCodeCell?.english
        if morseCodeCell?.english == "TIME" {
            aboutLabel.text = "To get the time in morse code, you must tap once and swipe up. You will get the current time in 24 hour format\n" // newline added to create space before next section
        }
        else if morseCodeCell?.english == "DATE" {
            aboutLabel.text = "To get the date in morse code, you must tap twice and swipe up. You will get the date and the first 2 letters of the day of the week\nExample: If date is 17 and 17 is a Wednesday, you will get 17WE\n"
        }
        else if morseCodeCell?.english == "CAMERA" {
            aboutLabel.text = "To open the camera and get the text on a door in front of you, you must tap three times and swipe up\n"
        }
        
        //blindInstructionsLabel.text = "After getting the result, tap the screen to play audio\n"
        deafBlindInstructionsLabel.text = "You must rotate the digital crown on the Apple Watch downwards to type out the morse code combination " + (morseCodeCell?.morseCode ?? "") + "\n\nTyping Instructions:\n\nOn the Apple Watch, rotate digital crown:\nDown to type a dot.\nDown quickly to type a dash.\nUpwards to delete last character.\n\nDouble tap the Apple Watch screen to confirm a character."
    }
}
