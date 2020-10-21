//
//  ActionsCell.swift
//  Suno-Watch Extension
//
//  Created by Adarsh Hasija on 11/10/20.
//  Copyright © 2020 Adam Behringer. All rights reserved.
//

import Foundation

class ActionsCell {
    
    var action : String
    var explanation : String?
    
    init(action : String) {
        self.action = action
        self.explanation = nil
    }
    
    init(action : String, explanation : String) {
        self.action = action
        self.explanation = explanation
    }
}
