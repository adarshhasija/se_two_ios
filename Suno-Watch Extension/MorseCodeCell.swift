//
//  MorseCodeCell.swift
//  Suno-Watch Extension
//
//  Created by Adarsh Hasija on 01/10/19.
//  Copyright © 2019 Adam Behringer. All rights reserved.
//

import Foundation


class MorseCodeCell {
    
    var english : String
    var displayChar : String? //In the case of space its only ␣
    var morseCode : String
    
    init(english: String, morseCode: String) {
        self.english = english
        self.displayChar = nil
        self.morseCode = morseCode
    }
    
    init(english: String, morseCode: String, displayChar: String) {
        self.english = english
        self.morseCode = morseCode
        self.displayChar = displayChar
    }
}
