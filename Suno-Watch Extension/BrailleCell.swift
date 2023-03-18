//
//  BrailleCell.swift
//  CustomVision
//
//  Created by Adarsh Hasija on 13/02/23.
//  Copyright © 2023 Adam Behringer. All rights reserved.
//

import Foundation

class BrailleCell {
    
    var english : String
    var brailleDots : String //This can be in the form of numbers or o and x. Its a string at the end. Reusable
    
    
    init(english: String, brailleDots: String) {
        self.english = english
        self.brailleDots = brailleDots
    }
    
}

