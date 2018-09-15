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

public class SpeechViewController: UIViewController, SFSpeechRecognizerDelegate, MCSessionDelegate, MCBrowserViewControllerDelegate, MCNearbyServiceBrowserDelegate, UITextViewDelegate {
    
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
        case Tap
        case SwipeUp
        case LongPress
        
        case UserPrmoptCancelled
        case UserSelectedTyping
        case UserSelectedSpeaking
        
        case BrowserCancelled
        case ReceivedConnection
        case TypistStartedTyping
        case TypistDeletedAllText
        case TypistFinishedTyping
        case PartnerCompleted
        case PartnerEndedSession
        case LostConnection
    }

    // MARK: Properties
    var currentState: [State] = []
    var seconds = 60
    var timer = Timer()
    var isTimerRunning = false
    
    // MARK: Multipeer Connectivity Properties
    var peerID: MCPeerID!
    var mcSession: MCSession!
    var mcAdvertiserAssistant: MCAdvertiserAssistant!
    var mcNearbyServiceBrowser: MCNearbyServiceBrowser!
    
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
        changeState(action: Action.Tap)
    }
    
    
    @IBAction func longPressGesture(_ sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.began {
           changeState(action: Action.LongPress)
        }
    }
    
    
    @IBAction func swipeGesture(_ sender: UISwipeGestureRecognizer) {
        if sender.direction == UISwipeGestureRecognizerDirection.up {
            changeState(action: Action.SwipeUp)
        }
    }
    
    // MARK: State Machine
    private func changeState(action : Action) {
        if action == Action.Tap && currentState.last == State.Idle {
            UIApplication.shared.isIdleTimerDisabled = true //Prevent the app from going to sleep
            currentState.append(State.Speaking)
            enterStateSpeaking()
        }
        else if action == Action.Tap && currentState.last == State.Speaking {
            currentState.popLast()
            exitStateSpeaking()
            if currentState.last == State.Idle {
                UIApplication.shared.isIdleTimerDisabled = false //The screen is allowed to dim
            }
            else if currentState.last == State.ConnectedTyping || currentState.last == State.ConnectedSpeaking {
                sendText(text: "\n") //Send to other other to confirm that speaking is done
                currentState.append(State.Reading)
                enterStateReading()
            }
        }
        else if action == Action.SwipeUp && currentState.last == State.Idle {
            //currentState.append(State.OpenedSessionBrowser)
            //enterStateOpenedSessionBrowser()
        }
        else if action == Action.LongPress && currentState.last == State.Idle {
            currentState.append(State.PromptUserRole)
            enterStatePromptUserRole()
        }
        else if action == Action.LongPress && currentState.last == State.Hosting {
            currentState.popLast()
            exitStateHosting()
        }
        else if action == Action.LongPress && currentState.last == State.BrowsingForPeers {
            currentState.popLast()
            exitStateBrowsingForPeers()
        }
        else if action == Action.LongPress {
            //All other states in which user does long press
            while currentState.last != State.Idle {
                currentState.popLast()
            }
            exitStateConnected()
        }
        else if action == Action.BrowserCancelled && currentState.last == State.OpenedSessionBrowser {
            while currentState.last != State.Idle {
                currentState.popLast()
            }
            exitStateOpenedSessionBrowser()
        }
        else if action == Action.UserSelectedTyping && currentState.last == State.PromptUserRole {
            currentState.popLast() //Prompt User Role
            currentState.append(State.Hosting)
            enterStateHosting()
        }
        else if action == Action.UserSelectedSpeaking && currentState.last == State.PromptUserRole {
            currentState.popLast() //Prompt User Role
            currentState.append(State.OpenedSessionBrowser)
            enterStateOpenedSessionBrowser()
        }
        else if action == Action.UserPrmoptCancelled && currentState.last == State.PromptUserRole {
            while currentState.last != State.Idle {
                currentState.popLast()
            }
        }
        else if action == Action.ReceivedConnection && currentState.last == State.Hosting {
            currentState.popLast()
            currentState.append(State.ConnectedTyping)
            currentState.append(State.Typing)
            UIApplication.shared.isIdleTimerDisabled = true //Prevent the app from going to sleep
            enterStateConnectedTyping()
            enterStateTyping()
        }
        else if action == Action.ReceivedConnection && (currentState.last == State.BrowsingForPeers || currentState.last == State.OpenedSessionBrowser) {
            currentState.popLast()
            currentState.append(State.ConnectedSpeaking)
            currentState.append(State.Reading)
            UIApplication.shared.isIdleTimerDisabled = true //Prevent the app from going to sleep
            enterStateConnectedSpeaking()
            enterStateReading()
        }
        else if action == Action.LongPress && currentState.last == State.Hosting {
            currentState.popLast()
            exitStateHosting()
        }
        else if action == Action.LongPress && (currentState.last == State.ConnectedTyping || currentState.last == State.ConnectedSpeaking)  {
            while currentState.last != State.Idle {
                currentState.popLast()
            }
            userEndedConnection()
        }
        else if action == Action.TypistDeletedAllText && currentState.last == State.TypingStarted {
            currentState.popLast()
            typistDeletedAllText()
        }
        else if action == Action.TypistDeletedAllText && currentState.last == State.Reading {
            typistDeletedAllText()
        }
        else if action == Action.TypistStartedTyping && currentState.last == State.Typing {
            currentState.append(State.TypingStarted)
        }
        else if action == Action.TypistFinishedTyping && (currentState.last == State.Typing || currentState.last == State.TypingStarted) {
            while currentState.last != State.ConnectedTyping {
                currentState.popLast()
            }
            currentState.append(State.Listening)
            exitStateTyping()
            enterStateListening()
        }
        else if action == Action.TypistFinishedTyping && currentState.last == State.Listening {
            currentState.popLast() //Pop listening
            currentState.append(State.Typing)
            enterStateTyping()
        }
        else if action == Action.LostConnection && (currentState.last == State.ConnectedTyping || currentState.last == State.ConnectedSpeaking) {
            currentState.popLast()
            exitStateConnected()
        }
        else if action == Action.PartnerEndedSession && (currentState.last == State.ConnectedTyping || currentState.last == State.ConnectedSpeaking) {
            currentState.popLast()
            exitStateConnected()
        }
        else if action == Action.PartnerCompleted && currentState.last == State.Reading {
            currentState.popLast() //pop reading
            currentState.append(State.Speaking)
            enterStateSpeaking()
        }
        else if action == Action.PartnerCompleted && currentState.last == State.Listening {
            currentState.popLast() //pop listening
            currentState.append(State.Typing)
            enterStateTyping()
        }
        else if action == Action.PartnerEndedSession && currentState.last == State.Speaking {
            currentState.popLast() //pop speaking
            changeState(action: Action.PartnerEndedSession)
            exitStateSpeaking()
        }
        else if action == Action.PartnerEndedSession && (currentState.last == State.ConnectedTyping || currentState.last == State.ConnectedSpeaking) {
            currentState.popLast()
            exitStateConnected()
        }
        else if action == Action.LostConnection && currentState.last == State.Speaking {
            currentState.popLast() //pop speaking
            changeState(action: Action.LostConnection)
            exitStateSpeaking()
        }
        else if action == Action.LostConnection && (currentState.last == State.ConnectedTyping || currentState.last == State.ConnectedSpeaking) {
            currentState.popLast() //pop connected
            exitStateConnected()
        }
        else if action == Action.LostConnection {
            while currentState.last != State.Idle {
                currentState.popLast()
            }
            exitStateTyping()
            exitStateSpeaking()
            exitStateConnected()
        }
        
    }
    
    
    // MARK: UIViewController
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        currentState.append(State.SubscriptionNotPaid)
        currentState.append(State.Idle) //Push
        
        // Disable the record buttons until authorization has been granted.
        recordButton?.isEnabled = false
        
        textViewTop?.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi)) //To turn one textView upside down
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
        textViewBottom?.delegate = self
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
                self.changeState(action: Action.ReceivedConnection)
            }
            
        case MCSessionState.connecting:
            DispatchQueue.main.async { [unowned self] in
                self.longPressLabel?.text = "Connecting: \(peerID.displayName)"
                self.dismiss(animated: true)
            }
            print("Connecting: \(peerID.displayName)")
            
        case MCSessionState.notConnected:
            DispatchQueue.main.async { [unowned self] in
                self.changeState(action: Action.LostConnection)
            }
            print("Not Connected: \(peerID.displayName)")
        }
    }
    
    public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
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
        changeState(action: Action.BrowserCancelled)
    }
    
    /// MARK:- MCNearbyServiceBrowserDelegate
    public func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        dialogNewConnection(title: "New device found", message: "Found device with name: \(peerID.displayName). Would you like to connect to it?", peerId: peerID)
    }
    
    public func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        self.textViewBottom?.text = "Looking for a device to connect to."
    }
    
    /// MARK:- UITextViewDelegate
    public func textViewDidChange(_ textView: UITextView) {
        var str = textView.attributedText.string
        if currentState.last == State.TypingStarted && str.last == "\n" {
            //If its an ENTER CHARACTER, typing over
            changeState(action: Action.TypistFinishedTyping)
            sendText(text: "\n")
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
            self.textViewBottom?.text = str
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
    
    // MARK: State Machine Private Helpers
    private func enterStatePromptUserRole() {
        dialogTypingOrSpeaking()
    }
    
    private func enterStateHosting() {
        self.textViewBottom?.text = "Started session. Ensure all devices are on the same Wifi network. Waiting for other devices to join..."
        self.longPressLabel?.text = "Long press to stop session"
        self.recordLabel?.isHidden = true
        startHosting()
    }
    
    private func exitStateHosting() {
        self.textViewBottom?.text = "Session ended"
        self.longPressLabel?.text = "Long press to connect to another device"
        self.recordLabel?.isHidden = false
        stopHosting()
    }
    
    func enterStateBrowsingForPeers() {
        self.textViewBottom?.text = "Looking for other devices. Ensure all devices are on the same WiFi network."
        self.longPressLabel?.text = "Long press to stop session"
        self.recordLabel?.isHidden = true
        mcNearbyServiceBrowser = MCNearbyServiceBrowser(peer: peerID, serviceType: "hws-kb")
        mcNearbyServiceBrowser.delegate = self
        mcNearbyServiceBrowser.startBrowsingForPeers()
    }
    
    private func exitStateOpenedSessionBrowser() {
        self.textViewBottom?.text = "Session stopped"
        self.longPressLabel?.text = "Long press to to look for other devices"
        self.recordLabel?.isHidden = false
    }
    
    private func exitStateBrowsingForPeers() {
        self.textViewBottom?.text = "Session stopped"
        self.longPressLabel?.text = "Long press to to look for other devices"
        self.recordLabel?.isHidden = false
        self.mcNearbyServiceBrowser.stopBrowsingForPeers()
    }
    
    private func enterStateConnectedTyping() {
        self.longPressLabel?.text = "Connected: \(peerID.displayName)" + "\n" + "Long press to disconnect"
        self.recordLabel?.isHidden = true
        print("Connected: \(peerID.displayName)")
    }
    
    private func enterStateListening() {
        self.textViewBottom?.text = "Connected, waiting for the other person to start talking..."
        self.longPressLabel?.text = "Connected: \(peerID.displayName)" + "\n" + "Long press to disconnect"
        self.recordLabel?.isHidden = true
    }
    
    private func enterStateConnectedSpeaking() {
        self.longPressLabel?.text = "Connected: \(peerID.displayName)" + "\n" + "Long press to disconnect"
        self.recordLabel?.isHidden = true
        print("Connected: \(peerID.displayName)")
    }
    
    private func enterStateReading() {
        self.textViewBottom?.text = "Connected, waiting for the other person to start typing..."
        self.recordLabel?.isHidden = true
    }
    
    private func enterStateTyping() {
        self.textViewBottom?.text = "Connected, you can now start typing. Tap enter when done..."
        textViewBottom?.isEditable = true
        textViewBottom?.becomeFirstResponder()
    }
    
    private func exitStateTyping() {
        textViewBottom?.isEditable = false
        textViewBottom?.resignFirstResponder()
    }
    
    private func enterStateSpeaking() {
        if hasInternetConnection() {
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate)) //vibration ONLY if not receiving
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
    
    private func exitStateSpeaking() {
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
            recordLabel?.text = "Tap screen to start recording"
        }
    }
    
    private func enterStateOpenedSessionBrowser() {
        if hasInternetConnection() {
            joinSession()
        }
        else if !hasInternetConnection() {
            dialogOK(title: "Alert", message: "No internet connection")
        }
    }
    
    private func userEndedConnection() {
        sendText(text: "\n\n")
        exitStateConnected()
    }
    
    private func exitStateConnected() {
        UIApplication.shared.isIdleTimerDisabled = false //The screen is allowed to dim
        mcSession?.disconnect()
        self.textViewBottom?.text = "Connection Lost"
        self.textViewBottom?.isEditable = false
        self.textViewBottom?.resignFirstResponder()
        self.longPressLabel?.text = "Long press to connect to a device"
        self.recordLabel?.isHidden = false
        self.dismiss(animated: true)
    }
    
    
    
    func typistDeletedAllText() {
        self.textViewBottom?.text = "Connected, waiting for the other person to start typing..."
    }
    
    // MARK: General Private Helpers
    
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
    
    func dialogTypingOrSpeaking() {
        let alert = UIAlertController(title: "Select Role", message: "If you are hearing impaired, select Typing. Else select Speaking", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Typing", style: .default, handler: { action in
            switch action.style{
            case .default:
                self.changeState(action: Action.UserSelectedTyping)
                
            case .cancel:
                print("cancel")
                
            case .destructive:
                print("destructive")
                
                
            }}))
        alert.addAction(UIAlertAction(title: "Speaking", style: .default, handler: { action in
            switch action.style{
            case .default:
                self.changeState(action: Action.UserSelectedSpeaking)
                
            case .cancel:
                print("cancel")
                
            case .destructive:
                print("destructive")
                
                
            }}))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            switch action.style{
            case .default:
                self.changeState(action: Action.UserPrmoptCancelled)
                
            case .cancel:
                self.changeState(action: Action.UserPrmoptCancelled)
                
            case .destructive:
                print("destructive")
                
                
            }}))
        self.present(alert, animated: true, completion: nil)
    }
    
    func startHosting() {
        mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "hws-kb", discoveryInfo: nil, session: mcSession)
        mcAdvertiserAssistant?.start()
    }
    
    func stopHosting() {
        mcAdvertiserAssistant?.stop()
    }
    
    func joinSession() {
        let mcBrowser = MCBrowserViewController(serviceType: "hws-kb", session: mcSession)
        mcBrowser.delegate = self
        mcBrowser.maximumNumberOfPeers = 2
        present(mcBrowser, animated: true)
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
    
    
}

