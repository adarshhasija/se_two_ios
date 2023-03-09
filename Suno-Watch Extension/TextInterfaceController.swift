//
//  TextInterfaceController.swift
//  Suno-Watch Extension
//
//  Created by Adarsh Hasija on 09/03/23.
//  Copyright © 2023 Adam Behringer. All rights reserved.
//

import Foundation
import WatchKit
import WatchConnectivity

class TextInterfaceController : WKInterfaceController {
    
    @IBOutlet weak var label: WKInterfaceLabel!
    
    override func awake(withContext context: Any?) {
        let dictionary = context as? NSDictionary
        if dictionary != nil {
            guard let text = dictionary!["text"] as? String else { return }
            guard let startIndexForHighlighting = dictionary!["start_index"] as? Int else { return }
            let endIndexForHighlighting = dictionary!["end_index"] as? Int ?? 1
            if startIndexForHighlighting < 0 || startIndexForHighlighting >= text.count {
                label.setText(text)
                return
            }
            setSelectedCharInLabel(inputString: text, index: startIndexForHighlighting, label: label, isMorseCode: false, color: UIColor.green)
        }
    }
    
    //Sets the particular character to green to indicate selected
    //If the index is out of bounds, the entire string will come white. eg: when index = -1
    func setSelectedCharInLabel(inputString : String, index : Int, label : WKInterfaceLabel, isMorseCode : Bool, color : UIColor) {
        let range = NSRange(location:index,length:1) // specific location. This means "range" handle 1 character at location 2
        
        //The replacement of space with visible space only applies to english strings
        let attributedString = NSMutableAttributedString(string: inputString, attributes: nil)
        // here you change the character to green color
        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: range)
        if isMorseCode {
            attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 25), range: range)
        }
        label.setAttributedText(attributedString)
    }
}
