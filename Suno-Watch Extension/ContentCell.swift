//
//  ActionsCell.swift
//  Suno-Watch Extension
//
//  Created by Adarsh Hasija on 11/10/20.
//  Copyright © 2020 Adam Behringer. All rights reserved.
//

import Foundation

class ContentCell {
    
    var action : String
    var tags : [String]
    var explanation : String?
    var cellType : Action
    var accessibilityLabel : String
    var textForSearch : String
    
    init(action : String, cellType : Action) {
        self.action = action
        self.explanation = " " //This is set to space character so that the row height is OK (empty string wont work)
        self.cellType = cellType
        self.accessibilityLabel = action
        self.textForSearch = action
        self.tags = []
    }
    
    init(action : String, explanation : String, cellType : Action) {
        self.action = action
        self.tags = []
        self.explanation = explanation
        self.cellType = cellType
        self.accessibilityLabel = action + "." + explanation
        self.textForSearch = action + " " + explanation
    }
    
    init(action : String, tags: [String], explanation : String, cellType : Action) {
        self.action = action
        self.tags = tags
        self.explanation = explanation
        self.cellType = cellType
        self.accessibilityLabel = action + "." + explanation
        var tagsString = ""
        for tag in tags {
            tagsString += tag + " "
        }
        self.textForSearch = action + " " + explanation + " " + tagsString
    }
}
