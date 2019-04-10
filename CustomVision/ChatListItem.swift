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
    var time : String
    var origin : String
    
    init(text: String, time: String, origin: String) {
        self.text = text
        self.time = time
        self.origin = origin
    }
}
