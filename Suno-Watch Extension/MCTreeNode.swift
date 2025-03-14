//
//  MCTreeNode.swift
//  Suno-Watch Extension
//
//  Created by Adarsh Hasija on 03/10/19.
//  Copyright © 2019 Adam Behringer. All rights reserved.
//

import Foundation

class MCTreeNode {
    
    var character : String?
    var alphabet : String?
    var action : String?  //Cannot have both an alphabet and an action
    var parent : MCTreeNode?
    var dotNode : MCTreeNode?
    var dashNode : MCTreeNode?
    
    init() {
        
    }
    
    init(alphabet : String) {
        self.alphabet = alphabet
    }
    
    init(character : String) {
        self.character = character
    }
    
    init(character : String, alphabet : String) {
        self.character = character
        self.alphabet = alphabet
    }
    
}
