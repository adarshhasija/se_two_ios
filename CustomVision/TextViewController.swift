//
//  TextViewController.swift
//  CustomVision
//
//  Created by Adarsh Hasija on 10/03/23.
//  Copyright © 2023 Adam Behringer. All rights reserved.
//

import Foundation
import UIKit

//Morse code reader with buttons, no gestures
class TextViewController : UIViewController {
    
    var mText : String =  ""
    var mStartIndexForHighlighting : Int = -1
    var mEndIndexForHighlighting : Int = -1
    
    @IBOutlet weak var mainLabel: UILabel!
    
    override func viewDidLoad() {
        if mStartIndexForHighlighting <= -1 || mStartIndexForHighlighting >= mText.count {
            mainLabel.text = mText
            return
        }
        if mEndIndexForHighlighting <= mStartIndexForHighlighting {
            mainLabel.text = mText
            return
        }
        
        MorseCodeUtils.setSelectedCharInLabel(inputString: mText, index: mStartIndexForHighlighting, label: mainLabel, isMorseCode: false, color : UIColor.green)
        
        
    }
    
}
