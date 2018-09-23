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
    
    // MARK: States
    enum State :String{
        case SubscriptionNotPaid
        case Idle
        case PromptUserRole         //Ask the user if they are typing or speaking
        case Hosting
        case BrowsingForPeers       //This is when the app has quietly initiated browsing for peers. No UI shown
        case OpenedSessionBrowser   //This is when the user has initiated browsing for peers
        
        case ConnectedTyping
        case ConnectedSpeaking
        
        case Typing
        case TypingStarted
        case Speaking
        case Listening              //Listening to other person speaking
        case Reading                //Reading what the other person is typing
    }
    
    enum Action :String{
        case AppOpened
        case Tap
        case LongPress
        
        case ReceivedConnection
        case TypistStartedTyping
        case TypistDeletedAllText
        case TypistFinishedTyping
        case PartnerCompleted
        case PartnerEndedSession
        case LostConnection
    }
    
    /// MARK:- Private properties
    var currentState: [State] = []
    
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
        if sender.state == NSGestureRecognizer.State.began {
            //toggleMCSession()
            changeState(action: Action.LongPress)
        }
    }
    
    private func toggleMCSession() {
     /*   if isHosting || isConnected {
            sendText(text: "\n\n")
            self.mainTextView?.string = "Session ended"
            mcSession.disconnect()
            stopHosting()
        }
        else {
            if hasInternetConnection() {
                self.mainTextView?.string = "Session started, please connect to this session from your iPhone or iPad app"
                startHosting()
            }
            else {
                let answer = dialogOK(question: "Alert", text: "No internet connection")
            }
            
        }   */
    }
    
    /// MARK:- State Machine
    func changeState(action: Action) {
        if action == Action.AppOpened {
            enterStateIdle()
        }
        else if action == Action.LongPress && currentState.last == State.Idle {
            currentState.append(State.Hosting)
            enterStateHosting()
        }
        else if action == Action.LongPress && (currentState.contains(State.ConnectedTyping) || currentState.contains(State.Hosting))  {
            //connected state
            while currentState.last != State.Idle {
                currentState.popLast()
            }
            sendText(text: "\n\n")
            exitStateHosting()
            exitStateConnected()
            enterStateIdle()
            dialogOK(question: "Alert", text: "Connection Closed")
        }
        else if action == Action.ReceivedConnection {
            while currentState.last != State.Idle {
                currentState.popLast()
            }
            currentState.append(State.ConnectedTyping)
            currentState.append(State.Typing)
            enterStateTyping()
        }
        else if action == Action.TypistStartedTyping {
            currentState.append(State.TypingStarted)
        }
        else if action == Action.TypistDeletedAllText {
            while currentState.last != State.Typing {
                currentState.popLast()
            }
        }
        else if action == Action.TypistFinishedTyping && currentState.contains(State.ConnectedTyping) {
            while currentState.last != State.ConnectedTyping {
                currentState.popLast()
            }
            currentState.append(State.Listening)
            sendText(text: "\n")
            enterStateListening()
        }
        else if action == Action.PartnerCompleted && currentState.last == State.Listening {
            while currentState.last != State.ConnectedTyping {
                currentState.popLast()
            }
            currentState.append(State.Typing)
            enterStateTyping()
        }
        else if action == Action.LostConnection || action == Action.PartnerEndedSession {
            while currentState.last != State.Idle {
                currentState.popLast()
            }
            exitStateConnected()
            exitStateHosting()
            enterStateIdle()
            dialogConnectionLost()
        }
    }
   
    
    
    /// MARK:- NSViewController
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        mPeerID = MCPeerID(displayName: Host.current().localizedName!)
        mcSession = MCSession(peer: mPeerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self
        
        mainTextView.delegate = self
        
        //toggleMCSession()
        currentState.append(State.SubscriptionNotPaid)
        currentState.append(State.Idle)
        changeState(action: Action.AppOpened)
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
                if self.didPeerCloseConnection(text: text) {
                    self.changeState(action: Action.PartnerEndedSession)
                }
                else if text.last! == "\0" {
                    self.changeState(action: Action.TypistDeletedAllText)
                }
                else if text.last! == "\n" {
                    self.changeState(action: Action.PartnerCompleted)
                }
                else if self.currentState.last == State.Listening || self.currentState.last == State.Reading {
                    self.mainTextView?.string = text
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
                self.changeState(action: Action.ReceivedConnection)
                //self.mainTextView?.string = "Connected. Type your message. Press enter when you have finished in order to start listening. Start typing..."
                //self.mainTextView?.isEditable = true
                self.searchDevicesLabel.stringValue = "Connected to: \(peerID.displayName)" + "\n" + "Click and hold here to disconnect"
                print("Connected: \(peerID.displayName)")
            }
            
            
        case MCSessionState.connecting:
            DispatchQueue.main.async { [unowned self] in
                self.mainTextView?.string = "Connecting..."
                self.searchDevicesLabel.stringValue = "Connecting to: \(peerID.displayName)"
                print("Connecting: \(peerID.displayName)")
            }
            
            
        case MCSessionState.notConnected:
            DispatchQueue.main.async { [unowned self] in
                self.changeState(action: Action.LostConnection)
                //self.mainTextView?.string = "Connection Lost"
                //self.searchDevicesLabel?.stringValue = "Click and hold to connect to an iOS device"
                print("Not Connected: \(peerID.displayName)")
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
    
    
    /// MARK:- State Machine Helpers
    func enterStateIdle() {
        self.searchDevicesLabel?.stringValue = "Click and hold to connect to an iOS device"
        self.mainTextView?.string = "If you are hearing-impaired, you can use this Mac app to have a conversation with someone holding an iOS device that has the Suno app for iOS. You can type using the Mac while the other person speaks using their device. Click and hold near the bottom of the app the start a session. Ensure that WiFi and Bluetooth are ON on the iOS device and that it is connected to the internet. Then use it to connect to this Mac. Note that the Mac can only be connected to 1 iOS device at a time for a conversation session."
        self.mainTextView?.isEditable = false
    }
    
    private func enterStateHosting() {
        if hasInternetConnection() {
            self.mainTextView?.string = "Session started, please connect to this session from your iPhone or iPad app"
            startHosting()
        }
        else {
            let answer = dialogOK(question: "Alert", text: "No internet connection")
        }
    }
    
    private func exitStateHosting() {
        stopHosting()
    }
    
    private func exitStateConnected() {
        mcSession.disconnect()
    }
    
    func enterStateTyping() {
        self.mainTextView?.string = "Connected. Type your message. Press enter when you have finished in order to start listening. Start typing..."
        self.mainTextView?.isEditable = true
    }
    
    func enterStateListening() {
        self.mainTextView?.string = "Waiting for other person to talk"
        self.mainTextView?.isEditable = false
    }
    
    
    /// MARK:- Private Helpers
    
    func hasInternetConnection() -> Bool {
      /*  guard let reachability = SCNetworkReachabilityCreateWithName(nil, "www.google.com") else { return false }
        var flags = SCNetworkReachabilityFlags()
        SCNetworkReachabilityGetFlags(reachability, &flags)
        if !isNetworkReachable(with: flags) {
            // Device doesn't have internet connection
            return false
        }   */
        return true
    }
    
    func dialogOK(question: String, text: String) -> Bool {
        let alert = NSAlert()
        alert.informativeText = text
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        return alert.runModal() == .alertFirstButtonReturn
    }
    
    func dialogConnectionLost() -> Bool {
        let alert = NSAlert()
        alert.informativeText = "Connection Lost"
        alert.alertStyle = .informational
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
    }
    
    func stopHosting() {
        mcAdvertiserAssistant?.stop()
        searchDevicesLabel?.stringValue = "Click and hold to connect to an iOS device"
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
        var str = textView.string
        if currentState.last == State.TypingStarted && str.last == "\n" {
            //If its an ENTER CHARACTER, typing over
            changeState(action: Action.TypistFinishedTyping)
            //sendText(text: "\n")
            return
        }
        
        if currentState.last == State.Typing && str.last == "\n" {
            //User has only pressed enter. We do not want to end typing session. EDGE CASE
            return
        }
        
        if currentState.last == State.Typing && str.last != "\n" {
            //It is the first character
            changeState(action: Action.TypistStartedTyping)
            str = String(str.last!)
            self.mainTextView?.string = str
            sendText(text: str)
            return
        }
        
        if str.isEmpty {
            //User deleted all the text
            changeState(action: Action.TypistDeletedAllText)
            sendText(text: "\0")
            return
        }
        
        sendText(text: str)
    }


}

