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
    var forWho : String? //iOS version only for now
    var explanation : String?
    var cellType : Action
    var accessibilityLabel : String
    
    init(action : String, cellType : Action) {
        self.action = action
        self.explanation = " " //This is set to space character so that the row height is OK (empty string wont work)
        self.cellType = cellType
        self.accessibilityLabel = action
    }
    
    init(action : String, explanation : String, cellType : Action) {
        self.action = action
        self.explanation = explanation
        self.cellType = cellType
        self.accessibilityLabel = action + "." + explanation
    }
    
    init(action : String, forWho: String, explanation : String, cellType : Action) {
        self.action = action
        self.forWho = forWho
        self.explanation = explanation
        self.cellType = cellType
        self.accessibilityLabel = action
                                    + "."
                                    //+ "for: " + forWho
                                    + ". " + explanation
    }
}
