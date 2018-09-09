//
//  ViewController.swift
//
//
//  Created by Adarsh Hasija on 07/08/18.
//  Copyright © 2018 Adam Behringer. All rights reserved.
//

import Cocoa
import MultipeerConnectivity
import SystemConfiguration

class SpeechMacViewController: NSViewController, MCSessionDelegate, MCBrowserViewControllerDelegate, NSTextViewDelegate {
    
    /// MARK:- Private properties
    var isHosting = false
    var isConnected = false
    var isListening = false
    
    /// MARK:- Multipeer Connectivity
    var mPeerID: MCPeerID!
    var mcSession: MCSession!
    var mcAdvertiserAssistant: MCAdvertiserAssistant!
    
    /// MARK:- UI properties
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet var mainTextView: NSTextView!
    @IBOutlet weak var searchDevicesLabel: NSTextField!
    @IBOutlet weak var recordLabel: NSTextField!
    @IBOutlet weak var timerLabel: NSTextField!
    
    /// MARK:- Interface Builder actions
    @IBAction func clickGesture(_ sender: Any) {
        
    }
    
    @IBAction func pressGesture(_ sender: NSPressGestureRecognizer) {
        if sender.state == NSGestureRecognizer.State.ended {
            toggleMCSession()
        }
    }
    
    private func toggleMCSession() {
        if isHosting || isConnected {
            sendText(text: "\n\n")
            self.mainTextView?.string = "Session ended"
            mcSession.disconnect()
            stopHosting()
        }
        else {
            if hasInternetConnection() {
                self.mainTextView?.string = "Session started, please connect to this session from your iPhone app"
                startHosting()
            }
            else {
                let answer = dialogOK(question: "Alert", text: "No internet connection")
            }
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        mPeerID = MCPeerID(displayName: Host.current().localizedName!)
        mcSession = MCSession(peer: mPeerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self
        
        mainTextView.delegate = self
        
        toggleMCSession()
    }
    
    override func viewDidDisappear() {
        mcSession.disconnect()
        stopHosting()
        NSApplication.shared.terminate(self) //Removes the app from the background and closes the top menu
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    
    /// MARK:- Mutipeer Connectivity Helpers
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let text = String(data: data, encoding: .utf8) {
            DispatchQueue.main.async { [unowned self] in
                if self.isListening {
                    if text == "\n" {
                        self.mainTextView?.string = "Your partner finished talking. Start typing..."
                        self.mainTextView?.isEditable = true
                        self.isListening = false
                    }
                    else {
                        self.mainTextView?.string = text
                    }
                }
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case MCSessionState.connected:
            DispatchQueue.main.async { [unowned self] in
                self.mainTextView?.string = "Connected. Type your message. Press enter when you have finished in order to start listening. Start typing..."
                self.mainTextView?.isEditable = true
                self.searchDevicesLabel.stringValue = "Connected to: \(peerID.displayName)" + "\n" + "Click and hold here to disconnect"
                print("Connected: \(peerID.displayName)")
                self.isConnected = true
                self.mcAdvertiserAssistant.stop()
            }
            
            
        case MCSessionState.connecting:
            DispatchQueue.main.async { [unowned self] in
                self.mainTextView?.string = "Connecting..."
                self.searchDevicesLabel.stringValue = "Connecting to: \(peerID.displayName)"
                print("Connecting: \(peerID.displayName)")
            }
            
            
        case MCSessionState.notConnected:
            DispatchQueue.main.async { [unowned self] in
                self.mainTextView?.string = "Connection Lost"
                self.searchDevicesLabel?.stringValue = "Click and hold to connect to an iOS device"
                print("Not Connected: \(peerID.displayName)")
                self.isConnected = false
            }
            
        }
    }
    
    /// MARK:- MCBrowserViewControllerDelegate
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(true)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(true)
    }
    
    
    
    
    
    /// MARK:- Private Helpers
    
    func hasInternetConnection() -> Bool {
        guard let reachability = SCNetworkReachabilityCreateWithName(nil, "www.google.com") else { return false }
        var flags = SCNetworkReachabilityFlags()
        SCNetworkReachabilityGetFlags(reachability, &flags)
        if !isNetworkReachable(with: flags) {
            // Device doesn't have internet connection
            return false
        }
        return true
    }
    
    func dialogOK(question: String, text: String) -> Bool {
        let alert = NSAlert()
        alert.informativeText = text
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        return alert.runModal() == .alertFirstButtonReturn
    }
    
    func isNetworkReachable(with flags: SCNetworkReachabilityFlags) -> Bool {
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        let canConnectAutomatically = flags.contains(.connectionOnDemand) || flags.contains(.connectionOnTraffic)
        let canConnectWithoutUserInteraction = canConnectAutomatically && !flags.contains(.interventionRequired)
        
        return isReachable && (!needsConnection || canConnectWithoutUserInteraction)
    }
    
    // Send text to connected peeers
    func sendText(text: String?) {
        if mcSession.connectedPeers.count > 0 {
            if let textData = text?.data(using: .utf8) {
                do {
                    try mcSession.send(textData, toPeers: mcSession.connectedPeers, with: .reliable)
                } catch let error as NSError {
                    self.mainTextView?.string = error.localizedDescription
                    print("Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func startHosting() {
        mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "hws-kb", discoveryInfo: nil, session: mcSession)
        mcAdvertiserAssistant.start()
        searchDevicesLabel.stringValue = "Click and hold to end connection"
        isHosting = true
    }
    
    func stopHosting() {
        mcAdvertiserAssistant?.stop()
        searchDevicesLabel?.stringValue = "Click and hold to connect to an iOS device"
        isHosting = false
    }
    
    func joinSession() {
        let mcBrowser = MCBrowserViewController(serviceType: "hws-kb", session: mcSession)
        mcBrowser.delegate = self
        //present(mcBrowser, animated: true)
    }
    
    func didPeerCloseConnection(text: String) -> Bool {
        var result = false
        if text.count >= 2 {
            if text.hasSuffix("\n\n") {
                result = true
            }
        }
        return result
    }
    
    /// NSTextViewDelegate
    func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else { return }
        if !isListening {
            if self.didPeerCloseConnection(text: textView.string) {
                self.isConnected = false
                self.mainTextView?.string = "The other user has ended the session. Thank you."
                return
            }
            if textView.string.last == "\n" {
                //If its an ENTER CHARACTER, go into listening mode
                self.mainTextView?.string = "Waiting for other person to talk"
                self.mainTextView?.isEditable = false
                isListening = true
                sendText(text: "\n")
                return
            }
            if textView.string.isEmpty {
                //User deleted all the text
                self.mainTextView?.string = "Connected. Type your message. Press enter when you have finished in order to start listening. Start typing..."
                sendText(text: "\0")
                return
            }
            
            
            if textView.string.contains("typing...") == true {
                //If its the first character, clear the field and set
                self.mainTextView?.string = String(textView.string.last!)
            }
            if mcSession.connectedPeers.count > 0 {
                sendText(text: textView.string)
            }
        }
    }


}

