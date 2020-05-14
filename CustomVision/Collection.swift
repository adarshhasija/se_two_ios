//
//  Collection.swift
//  Suno
//
//  Created by Adarsh Hasija on 14/05/20.
//  Copyright © 2020 Adam Behringer. All rights reserved.
//

import Foundation

extension Collection {
    
    /// Returns the element at the specified index if it is within bounds, otherwise the last element in the collection.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
