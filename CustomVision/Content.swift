//
//  Content.swift
//  CustomVision
//
//  Created by Adarsh Hasija on 07/04/23.
//  Copyright © 2023 Adam Behringer. All rights reserved.
//

import Foundation

class Content {
    
    var id : String
    var title : String
    var content: String
    
    init(id: String, title: String, content: String) {
        self.id = id
        self.title = title
        self.content = content
    }
}
