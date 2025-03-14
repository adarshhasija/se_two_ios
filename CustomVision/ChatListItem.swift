//
//  ChatListItem.swift
//  Suno
//
//  Created by Adarsh Hasija on 10/04/19.
//  Copyright © 2019 Adam Behringer. All rights reserved.
//

import Foundation


class ChatListItem {
    
    var text : String
    var morseCodeText : String?
    var time : String
    var origin : String
    var mode : String?
    
    init(text: String, time: String?, origin: String, mode: String?) {
        self.text = text
        self.origin = origin //Device or status
        self.mode = mode
        
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"
        let date12Hour : String = dateFormatter.string(from: date)
        self.time = time ?? date12Hour
    }
    
    convenience init(text: String, morseCodeText: String, origin: String, mode: String?) {
        self.init(text : text, origin: origin, mode : mode)
        self.morseCodeText = morseCodeText
    }
    
    convenience init(text: String, origin: String) {
        self.init(text: text, time: nil, origin: origin, mode: nil)
    }
    
    convenience init(text: String, origin: String, mode: String?) {
        self.init(text: text, time: nil, origin: origin, mode: mode)
    }
}
