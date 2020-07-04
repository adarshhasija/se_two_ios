//
//  UIView.swift
//  Suno
//
//  Created by Adarsh Hasija on 04/07/20.
//  Copyright © 2020 Adam Behringer. All rights reserved.
//

import Foundation
import UIKit

extension UIView {

//MARK: Accessibility
    
    open override func accessibilityScroll(_ direction: UIAccessibilityScrollDirection) -> Bool {
        ((self.window?.rootViewController as? UINavigationController)?.topViewController as? ActionsMCViewController)?.gestureSwipe(direction)
        return true
    }
}
