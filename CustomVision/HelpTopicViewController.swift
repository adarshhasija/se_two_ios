//
//  File.swift
//  Suno
//
//  Created by Adarsh Hasija on 22/09/18.
//  Copyright © 2018 Adam Behringer. All rights reserved.
//

import Foundation
import UIKit

public class HelpTopicViewController: UIViewController {
    
    var answer: String = ""
    
    @IBOutlet weak var mainTextView: UITextView!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        mainTextView?.text = answer
    }
}
