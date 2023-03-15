//
//  String.swift
//  CustomVision
//
//  Created by Adarsh Hasija on 15/03/23.
//  Copyright © 2023 Adam Behringer. All rights reserved.
//

import Foundation

extension String {

    func removeExtraSpaces() -> String {
        return self.replacingOccurrences(of: "[\\s\n]+", with: " ", options: .regularExpression, range: nil)
    }

}
