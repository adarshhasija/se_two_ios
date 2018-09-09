/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The primary view controller. The speach-to-text engine is managed an configured here.
*/

import UIKit
import Speech
import MultipeerConnectivity
import SystemConfiguration

public class SpeechViewController: UIViewController, SFSpeechRecognizerDelegate, MCSessionDelegate, MCBrowserViewControllerDelegate, MCNearbyServiceBrowserDelegate {

    // MARK: Properties
    var isConnected = false
    var seconds = 60
    var timer = Timer()
    var isTimerRunning = false
    
    // MARK: Multipeer Connectivity Properties
    var peerID: MCPeerID!
    var mcSession: MCSession!
    var mcAdvertiserAssistant: MCAdvertiserAssistant!
    var mcNearbyServiceBrowser: MCNearbyServiceBrowser!
    var isReceiving = false
    
    // MARK: Speech Recognition Properties
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // MARK: UI Properties
    @IBOutlet var mainView : UIView?
    @IBOutlet var textViewTop : UITextView?
    @IBOutlet var textViewBottom : UITextView!
    @IBOutlet var recordButton : UIButton?
    @IBOutlet weak var longPressLabel: UILabel?
    @IBOutlet weak var recordLabel: UILabel?
    @IBOutlet weak var timerLabel: UILabel?
    
    // MARK: Interface Builder actions
    
    @IBAction func tapGesture() {
        if audioEngine.isRunning {
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate)) //vibration to indicate end of recording
            audioEngine.stop()
            recognitionRequest?.endAudio()
            recordButton?.isEnabled = false
            recordButton?.setTitle("Stopping", for: .disabled)
            recordLabel?.text = "Stopping"
            resetTimer()
            //textViewTop?.font = textViewTop?.font?.withSize(16)
            textViewTop?.text = ""
            //textViewBottom.font = textViewBottom.font?.withSize(16)
            textViewBottom.text = ""
            longPressLabel?.isHidden = false
            if !isConnected {
                //Browse for peers only if not connected
                mcNearbyServiceBrowser.startBrowsingForPeers()
            }
            else {
                sendText(text: "\n")
            }
        } else if !isReceiving {
            if hasInternetConnection() {
                AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate)) //vibration ONLY if not receiving
                mcNearbyServiceBrowser.stopBrowsingForPeers() //Should not be browsing for peers when recording
                try! startRecording()
                runTimer()
                recordButton?.setTitle("Stop recording", for: [])
                recordLabel?.text = "TAP SCREEN TO STOP RECORDING"
                recordLabel?.isHidden = false
                longPressLabel?.isHidden = true
            }
            else {
                dialogOK(title: "Alert", message: "No internet connection")
            }
            
        }
    }
    
    
    @IBAction func longPressGesture(_ sender: Any) {
        if isConnected {
            sendText(text: "\n\n")
            mcSession.disconnect()
            longPressLabel?.text = "Swipe up to connect to a Mac"
        }
    }
    
    
    @IBAction func swipeGesture(_ sender: UISwipeGestureRecognizer) {
        if sender.direction == UISwipeGestureRecognizerDirection.up {
            if hasInternetConnection() && !isConnected {
                joinSession()
            }
            else if !hasInternetConnection() {
                dialogOK(title: "Alert", message: "No internet connection")
            }
        }
    }
    // MARK: UIViewController
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // Disable the record buttons until authorization has been granted.
        recordButton?.isEnabled = false
        
        textViewTop?.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
        //recordLabel?.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
        //timerLabel?.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
        mainView?.accessibilityLabel = "Tap screen to start recording"
        
        //self.textViewTop?.layoutManager.allowsNonContiguousLayout = false //Allows scrolling if text is more than screen real-estate
        //self.textViewBottom.layoutManager.allowsNonContiguousLayout = false
        
        peerID = MCPeerID(displayName: UIDevice.current.name)
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self
        
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        startBrowsingForPeers()
        speechRecognizer.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { authStatus in
            /*
                The callback may not be called on the main thread. Add an
                operation to the main queue to update the record button's state.
            */
            OperationQueue.main.addOperation {
                switch authStatus {
                    case .authorized:
                        self.recordButton?.isEnabled = true

                    case .denied:
                        self.recordButton?.isEnabled = false
                        self.recordButton?.setTitle("User denied access to speech recognition", for: .disabled)
                        self.recordLabel?.text = "User has denied access to speech recognition"

                    case .restricted:
                        self.recordButton?.isEnabled = false
                        self.recordButton?.setTitle("Speech recognition restricted on this device", for: .disabled)

                    case .notDetermined:
                        self.recordButton?.isEnabled = false
                        self.recordButton?.setTitle("Speech recognition not yet authorized", for: .disabled)
                        self.recordLabel?.text = "Speech recognition not yet authorized"
                }
            }
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        mcSession.disconnect()
        mcNearbyServiceBrowser.stopBrowsingForPeers()
    }
    
    /// MARK:- Speech Recognition Helpers
    private func startRecording() throws {

        // Cancel the previous task if it's running.
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(AVAudioSessionCategoryRecord)
        try audioSession.setMode(AVAudioSessionModeMeasurement)
        try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object") }
        
        // Configure request so that results are returned before audio recording is finished
        recognitionRequest.shouldReportPartialResults = true
        
        // A recognition task represents a speech recognition session.
        // We keep a reference to the task so that it can be cancelled.
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                self.textViewTop?.text = result.bestTranscription.formattedString
                self.textViewBottom.text = result.bestTranscription.formattedString
                self.sendText(text: result.bestTranscription.formattedString)
                if self.textViewBottom.text.count > 0 {
                    let location = self.textViewBottom.text.count - 1
                    let bottom = NSMakeRange(location, 1)
                    self.textViewTop?.scrollRangeToVisible(bottom)
                    self.textViewBottom.scrollRangeToVisible(bottom)
                }
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.recordButton?.isEnabled = true
                self.recordButton?.setTitle("Start Recording", for: [])
                self.recordLabel?.text = "Tap screen to start recording"
                if self.isReceiving {
                    self.recordLabel?.isHidden = true
                }
                else {
                    self.recordLabel?.isHidden = false
                }
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        try audioEngine.start()
        
        textViewTop?.font = textViewTop?.font?.withSize(30)
        textViewTop?.text = "(Go ahead, I'm listening)"
        textViewBottom.font = textViewBottom.font?.withSize(30)
        textViewBottom.text = "You can now talk. Tap the screen when finished. Go ahead, I'm listening"
    }

    // MARK: SFSpeechRecognizerDelegate
    
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            recordButton?.isEnabled = true
            recordButton?.setTitle("Start Recording", for: [])
            recordLabel?.text = "Tap screen to start recording"
            
        } else {
            recordButton?.isEnabled = false
            recordButton?.setTitle("Recognition not available", for: .disabled)
            recordLabel?.text = "Recognition not available"
        }
    }
    
    // MARK: MCSessionDelegate
    public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case MCSessionState.connected:
            DispatchQueue.main.async { [unowned self] in
                self.textViewBottom?.text = "Connected, waiting for the other person to start typing"
                self.longPressLabel?.text = "Connected: \(peerID.displayName)" + "\n" + "Long press to disconnect"
                print("Connected: \(peerID.displayName)")
                self.mcNearbyServiceBrowser.stopBrowsingForPeers()
                self.recordLabel?.isHidden = true
                self.isConnected = true
                self.isReceiving = true
            }
            
        case MCSessionState.connecting:
            DispatchQueue.main.async { [unowned self] in
                self.longPressLabel?.text = "Connecting: \(peerID.displayName)"
                self.dismiss(animated: true)
            }
            print("Connecting: \(peerID.displayName)")
            
        case MCSessionState.notConnected:
            DispatchQueue.main.async { [unowned self] in
                self.connectionLost()
                self.startBrowsingForPeers()
            }
            print("Not Connected: \(peerID.displayName)")
        }
    }
    
    public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let text = String(data: data, encoding: .utf8) {
            DispatchQueue.main.async { [unowned self] in
                if self.didPeerCloseConnection(text: text) {
                    self.isReceiving = false
                    self.textViewBottom?.text = "The other user has ended the session. Thank you."
                }
                else if text.last! == "\0" {
                    self.textViewBottom?.text = "Connected, waiting for the other person to start typing"
                }
                else if text.last! == "\n" {
                    self.isReceiving = false
                    self.tapGesture()
                }
                else {
                    self.textViewBottom?.text = text
                }
            }
        }
    }
    
    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
    
    /// MARK:- MCBrowserViewControllerDelegate
    public func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    public func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    /// MARK:- MCNearbyServiceBrowserDelegate
    public func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        if !isConnected {
            //self.textViewBottom?.text = "A device has started a session. Swipe up to see which device and join it."
            dialogNewConnection(title: "New device found", message: "Found device with name: \(peerID.displayName). Would you like to connect to it?", peerId: peerID)
        }
    }
    
    public func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        if !isConnected {
            self.textViewBottom?.text = "Looking for a Mac to connect to."
        }
    }
    
    
    
    // MARK: Private Helpers
    
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
    
    func isNetworkReachable(with flags: SCNetworkReachabilityFlags) -> Bool {
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        let canConnectAutomatically = flags.contains(.connectionOnDemand) || flags.contains(.connectionOnTraffic)
        let canConnectWithoutUserInteraction = canConnectAutomatically && !flags.contains(.interventionRequired)
        
        return isReachable && (!needsConnection || canConnectWithoutUserInteraction)
    }
    
    func dialogOK(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            switch action.style{
            case .default:
                print("default")
                
            case .cancel:
                print("cancel")
                
            case .destructive:
                print("destructive")
                
                
            }}))
        self.present(alert, animated: true, completion: nil)
    }
    
    func dialogNewConnection(title: String, message: String, peerId : MCPeerID) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            switch action.style{
            case .default:
                self.mcNearbyServiceBrowser?.invitePeer(peerId, to: self.mcSession, withContext: nil, timeout: 30)
                
            case .cancel:
                print("cancel")
                
            case .destructive:
                print("destructive")
                
                
            }}))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            switch action.style{
            case .default:
                print("default")
                
            case .cancel:
                print("cancel")
                
            case .destructive:
                print("destructive")
                
                
            }}))
        self.present(alert, animated: true, completion: nil)
    }
    
    func startHosting() {
        mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "hws-kb", discoveryInfo: nil, session: mcSession)
        mcAdvertiserAssistant.start()
    }
    
    func stopHosting() {
        mcAdvertiserAssistant.stop()
    }
    
    func joinSession() {
        let mcBrowser = MCBrowserViewController(serviceType: "hws-kb", session: mcSession)
        mcBrowser.delegate = self
        mcBrowser.maximumNumberOfPeers = 2
        present(mcBrowser, animated: true)
    }
    
    func startBrowsingForPeers() {
        mcNearbyServiceBrowser = MCNearbyServiceBrowser(peer: peerID, serviceType: "hws-kb")
        mcNearbyServiceBrowser.delegate = self
        mcNearbyServiceBrowser.startBrowsingForPeers()
    }
    
    @objc func updateTimer() {
        seconds -= 1     //This will decrement(count down)the seconds.
        timerLabel?.text = timeString(time: TimeInterval(seconds)) //This will update the label.
        if seconds < 1 {
            resetTimer()
            tapGesture() //this should stop the recording
        }
        if seconds < 11 {
            timerLabel?.textColor = UIColor.red
        }
    }
    
    func runTimer() {
        if !isTimerRunning {
            timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(SpeechViewController.updateTimer)), userInfo: nil, repeats: true)
            isTimerRunning = true
        }
        timerLabel?.isHidden = false
    }
    
    func resetTimer() {
        timer.invalidate()
        isTimerRunning = false
        seconds = 60
        timerLabel?.textColor = UIColor.black
        timerLabel?.text = "1:00"
        timerLabel?.isHidden = true
    }
    
    func timeString(time:TimeInterval) -> String {
        
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        
        return String(format:"%01i:%02i", minutes, seconds)
        
    }
    
    func sendText(text: String?) {
        if mcSession.connectedPeers.count > 0 {
            if let textData = text?.data(using: .utf8) {
                do {
                    try mcSession.send(textData, toPeers: mcSession.connectedPeers, with: .reliable)
                } catch let error as NSError {
                    textViewBottom?.insertText(error.localizedDescription)
                    print("Error: \(error.localizedDescription)")
                }
            }
        }
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
    
    func connectionLost() {
        self.textViewBottom?.text = "Connection Lost"
        self.longPressLabel?.text = "Swipe up to connec to a Mac"
        self.dismiss(animated: true)
        self.recordLabel?.isHidden = false
        self.isConnected = false
        self.isReceiving = false
    }
    
    
}

