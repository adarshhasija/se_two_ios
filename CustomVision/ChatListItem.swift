//
//  ChatListItem.swift
//  Suno
//
//  Created by Adarsh Hasija on 10/04/19.
//  Copyright © 2019 Adam Behringer. All rights reserved.
//

import Foundation

class DummyChatListItem { }

class ChatListItem : DummyChatListItem {
    
    var text : String
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
        super.init()
    }
    
    convenience init(text: String, origin: String) {
        self.init(text: text, time: nil, origin: origin, mode: nil)
     /*   self.text = text
        self.origin = origin
        self.mode = nil
        
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"
        let date12Hour = dateFormatter.string(from: date)
        self.time = date12Hour  */
    }
    
    convenience init(text: String, origin: String, mode: String?) {
        self.init(text: text, time: nil, origin: origin, mode: mode)
    /*    self.text = text
        self.origin = origin
        self.mode = mode
        
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"
        let date12Hour = dateFormatter.string(from: date)
        self.time = date12Hour  */
    }
}
