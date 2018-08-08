//
//  ViewController.swift
//  MacApp
//
//  Created by Adarsh Hasija on 07/08/18.
//  Copyright © 2018 Adam Behringer. All rights reserved.
//

import Cocoa

class SpeechMacViewController: NSViewController {
    
    
    
    @IBOutlet weak var textViewBottom: NSScrollView!
    @IBOutlet weak var searchDevicesLabel: NSTextField!
    @IBOutlet weak var recordLabel: NSTextField!
    @IBOutlet weak var timerLabel: NSTextField!
    
    
    @IBAction func recordButtonClicked(_ sender: Any) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

