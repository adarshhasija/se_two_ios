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
import CoreBluetooth
import FirebaseAnalytics
import WatchConnectivity

public class WhiteSpeechViewController: UIViewController {

    // MARK: Properties
    let synth = AVSpeechSynthesizer()
    let networkManager = NetworkManager.sharedInstance
    var currentState: [State] = []
    var seconds = 60
    var timer = Timer()
    var isTimerRunning = false
    private var dataChats: [ChatListItem] = []
    var speechToTextInstructionString = "Long press on screen to record speech"
    var typingInstructionString = "Swipe up to type"
    var hiSIContextString = "This person cannot hear or speak. Please help them"
    var tapToRepeat = "Tap to repeat"
    
    // MARK: Multipeer Connectivity Properties
    var peerID: MCPeerID!
    var mcSession: MCSession!
    var mcAdvertiserAssistant: MCAdvertiserAssistant!
    var mcNearbyServiceBrowser: MCNearbyServiceBrowser!
    
    
    // MARK: Bluetooth check
    var cbCentralManager:CBCentralManager!
    var isBluetoothOn = true //Default=true by design. If we are not sure what the value is, we should still allow user to connect
    
    // MARK: Speech Recognition Properties
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // MARK: UI Properties
    @IBOutlet weak var helpBarButtonItem: UIBarButtonItem! //To make this visible again, in storyboard, set Enabled to true + set Tint to Default
    @IBOutlet var mainView : UIView?
    @IBOutlet var textViewTop : UITextView?
    @IBOutlet var textViewBottom : UITextView!
    @IBOutlet weak var composerStackView: UIStackView!
    @IBOutlet weak var navStackView: UIStackView!
    @IBOutlet weak var bottomLeftStackView: UIStackView!

    @IBOutlet weak var chatLogBtn: UIImageView!
    
    @IBOutlet var recordButton : UIButton?
    @IBOutlet weak var longPressLabel: UILabel?   
    @IBOutlet weak var noInternetImageView: UIImageView!
    @IBOutlet weak var recordLabel: UILabel?
    @IBOutlet weak var timerLabel: UILabel?
    @IBOutlet weak var swipeUpLabel: UILabel!
    @IBOutlet weak var swipeLeftLabel: UILabel!
    @IBOutlet weak var disabledContextLabel: UILabel!
    
    //User profile view
    @IBOutlet weak var userProfileVerticalStackView: UIStackView!
    @IBOutlet weak var hiLeftImageView: UIImageView!
    @IBOutlet weak var viLeftImageView: UIImageView!
    @IBOutlet weak var userLeftImageView: UIImageView!
    @IBOutlet weak var appIconButton: UIImageView!
    @IBOutlet weak var userRightImageView: UIImageView!  
    @IBOutlet weak var hiRightImageView: UIImageView!
    @IBOutlet weak var viRightImageView: UIImageView!
    @IBOutlet weak var userStatusLabel: UILabel!
    ///
    
    // MARK: Interface Builder actions
    
    
    @IBAction func helpBarButtonItemTapped(_ sender: Any) {
        changeState(action: Action.BarButtonHelpTapped)
    }
    
    
    @IBAction func appleWatchButtonTapped(_ sender: Any) {
        changeState(action: Action.AppleWatchButtonTapped)
    }
    
    
    @IBAction func userProfileStackViewTapped(_ sender: Any) {
        if currentState.last == State.Idle {
            changeState(action: Action.UserProfileButtonTapped)
        }
        else {
            //Cannot move away from this screen if we are in the middle of typing or speaking
            self.recordLabel?.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            UIView.animate(withDuration: 1.0,
                           delay: 0,
                           usingSpringWithDamping: 0.2,
                           initialSpringVelocity: 6.0,
                           options: .allowUserInteraction,
                           animations: { [weak self] in
                            self?.recordLabel?.transform = .identity
                },
                           completion: nil)
        }
    }
    
    @IBAction func chatLogButtonTapped(_ sender: Any) {
        if dataChats.count > 0 {
            changeState(action: Action.SwipeLeft)
        }
        else {
            self.chatLogBtn.transform = CGAffineTransform(translationX: 20, y: 0)
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.2, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
                self.chatLogBtn.transform = CGAffineTransform.identity
            }, completion: nil)
        }
    }
    
    
    @IBAction func tapGesture() {
        changeState(action: Action.Tap)
    }
    
    
    @IBAction func longPressGesture(_ sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.recognized {
           changeState(action: Action.LongPress)
        }
    }
    
    
    @IBAction func swipeGesture(_ sender: UISwipeGestureRecognizer) {
        if sender.direction == UISwipeGestureRecognizerDirection.up {
            changeState(action: Action.SwipeUp)
        }
        else if sender.direction == UISwipeGestureRecognizerDirection.left {
            changeState(action: Action.SwipeLeft)
        }
    }
    
    // MARK: State Machine
    private func changeState(action : Action) {
        //All events logged without parameters are temporary. Will be removed once we analyze events better
        Analytics.logEvent("se3_change_state", parameters: [
            "os_version": UIDevice.current.systemVersion,
            "device_type": getDeviceType(),
            "action": action.rawValue,
            "current_state": currentState.last?.rawValue
            ])
        if action == Action.AppOpened && currentState.last == State.ControllerLoaded {
            enterStateControllerLoaded()
            currentState.append(State.Idle)
        }
        else if action == Action.ChatLogsCleared && currentState.last == State.Idle {
            enterStateControllerLoaded() //Reset
        }
        else if action == Action.AppleWatchButtonTapped && currentState.last == State.Idle {
            openAppleWatchAppInfoScreen()
        }
        else if action == Action.UserProfileButtonTapped && currentState.last == State.Idle {
            openUserProfileOptions()
        }
        else if action == Action.Tap && currentState.last == State.Idle {
            if textViewBottom.text.count > 0 {
                sayThis(string: textViewBottom.text)
            }
            else {
                let se3UserType = UserDefaults.standard.string(forKey: "SE3_IOS_USER_TYPE")
                if se3UserType != nil {
                    self.recordLabel?.transform = CGAffineTransform(translationX: 20, y: 0)
                    UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.2, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
                        self.recordLabel?.transform = CGAffineTransform.identity
                    }, completion: nil)
                }
                else {
                    self.userStatusLabel?.transform = CGAffineTransform(translationX: 20, y: 0)
                    UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.2, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
                        self.userStatusLabel?.transform = CGAffineTransform.identity
                    }, completion: nil)
                }
            }
        }
        else if action == Action.LongPress && currentState.last == State.Idle {
            Analytics.logEvent("se3_speaking_not_connected", parameters: [:])
            UIApplication.shared.isIdleTimerDisabled = true //Prevent the app from going to sleep
            sendStatusToWatch(beginningOfAction: true, success: true, text: "User is speaking on iPhone. Please wait. Tell them to tap screen when done.")
            let permission = checkAppleSpeechRecoginitionPermissions()
            if permission != nil {
                showErrorMessageFormPermission(permission: permission)
            }
            else if !hasInternetConnection() {
                //dialogOK(title: "Alert", message: "No internet connection")
                animateNoInternetConnection()
            }
            else {
                currentState.append(State.Speaking)
                enterStateSpeaking()
            }
        }
        else if action == Action.Tap && currentState.contains(State.Typing) {
            changeState(action: Action.TypistFinishedTyping)
        }
        else if action == Action.SpeakerDidSpeak && currentState.last == State.Speaking {
            currentState.append(State.SpeechInProgress)
        }
        else if action == Action.Tap && (currentState.last == State.Speaking || currentState.last == State.SpeechInProgress) {
            exitStateSpeaking()
            if State.SpeechInProgress == currentState.popLast() {
                currentState.popLast() //Remove speaking as well
            }
            
            if currentState.last == State.Idle {
                UIApplication.shared.isIdleTimerDisabled = false //The screen is allowed to dim
            }
            else if currentState.last == State.ConnectedTyping || currentState.last == State.ConnectedSpeaking {
                sendText(text: "\n") //Send to other other to confirm that speaking is done
                currentState.append(State.Reading)
                enterStateReading()
            }
        }
        else if (action == Action.SwipeLeft || action == Action.BarButtonHelpTapped) && currentState.last == State.Idle {
            Analytics.logEvent("se3_view_chat_log", parameters: [:])
            swipeLeft()
            //performSegue(withIdentifier: "segueHelpTopics", sender: nil)
        }
        else if action == Action.SwipeUp && currentState.last == State.Idle {
            Analytics.logEvent("se3_typing_not_connected", parameters: [:])
            sendStatusToWatch(beginningOfAction: true, success: true, text: "User is typing on iPhone. Please wait. Tell them to tap screen when done.")
            currentState.append(State.Typing)
            enterStateTyping()
        }
     /*   else if action == Action.LongPress && currentState.last == State.Idle {
            Analytics.logEvent("se3_long_press_not_connected", parameters: [:])
            currentState.append(State.PromptUserRole)
            enterStatePromptUserRole()
        }   */
        else if action == Action.ReceivedStatusFromWatch && currentState.last == State.Idle {
            //Entering listening state
            while currentState.last != State.Idle {
                currentState.popLast()
            }
            currentState.append(State.ReceivingFromWatch)
            enterStateReceivingFromWatch()
        }
        else if action == Action.ReceivedStatusFromWatch && currentState.contains(State.ReceivingFromWatch) {
            while currentState.last != State.Idle {
                currentState.popLast()
            }
            exitStateReceivingFromWatch()
            // foreground
            //Use this to update the UI instantaneously (otherwise, takes a little while)
            DispatchQueue.main.async(execute: { () -> Void in
                self.enterStateIdle()
            })
        }
        else if action == Action.ReceivedContentFromWatch && currentState.last == State.ReceivingFromWatch {
            while currentState.last != State.Idle {
                currentState.popLast()
            }
            exitStateReceivingFromWatch()
        }
        else if action == Action.WatchUserStopped && currentState.contains(State.ReceivingFromWatch) {
            while currentState.last != State.Idle {
                currentState.popLast()
            }
            exitStateReceivingFromWatch()
            enterStateIdle()
        }
        else if action == Action.WatchNotReachable && currentState.contains(State.ReceivingFromWatch) {
            while currentState.last != State.Idle {
                currentState.popLast()
            }
            exitStateReceivingFromWatch()
            enterStateIdle()
            dialogOK(title: "Alert", message: "Watch not reachable")
        }
        else if action == Action.LongPress && currentState.contains(State.ReceivingFromWatch) {
            while currentState.last != State.Idle {
                currentState.popLast()
            }
            exitStateReceivingFromWatch()
            enterStateIdle()
        }
        else if action == Action.LongPress && (currentState.contains(State.ConnectedTyping) || currentState.contains(State.ConnectedSpeaking) || currentState.contains(State.Hosting)) {
            //All other states in which user does long press
            while currentState.last != State.Idle {
                currentState.popLast()
            }
            sendText(text: "\n\n")
            exitStateTyping()
            exitStateSpeaking()
            exitStateConnected()
            exitStateHosting()
            exitStateBrowsingForPeers()
            enterStateIdle()
            dialogOK(title: "Alert", message: "Connection Closed")
        }
        else if action == Action.BrowserCancelled && currentState.last == State.OpenedSessionBrowser {
            while currentState.last != State.Idle {
                currentState.popLast()
            }
            exitStateOpenedSessionBrowser()
        }
        else if action == Action.UserSelectedTyping && currentState.last == State.PromptUserRole {
            currentState.popLast() //Prompt User Role
            //Only checking bluetooth right now, not Wifi
            if isBluetoothOn {
                currentState.append(State.Hosting)
                enterStateHosting()
            }
            else {
                Analytics.logEvent("se3_connecting_bluetooth_off", parameters: [:])
                dialogOK(title: "Bluetooth is off", message: "Bluetooth should be ON before starting a conversation session")
            }
        }
        else if action == Action.UserSelectedSpeaking && currentState.last == State.PromptUserRole {
            currentState.popLast() //Prompt User Role
            if SFSpeechRecognizer.authorizationStatus() != .authorized {
                dialogOK(title: "Permission Error", message: "You must enable speech recognition on order to use the speaking option. Go to Settings->Suno and turn Speech Recognition to ON")
            }
            else if AVAudioSession.sharedInstance().recordPermission() != AVAudioSession.RecordPermission.granted {
                dialogOK(title: "Permission Error", message: "You must allow microphone on order to use the speaking option. Go to Settings->Suno and turn Microphone to ON")
            }
            else if !isBluetoothOn {
                Analytics.logEvent("se3_connecting_bluetooth_off", parameters: [:])
                dialogOK(title: "Bluetooth is off", message: "Bluetooth should be ON before starting a conversation session")
            }
            else {
                currentState.append(State.OpenedSessionBrowser)
                enterStateOpenedSessionBrowser()
            }
        }
        else if action == Action.UserPrmoptCancelled && currentState.last == State.PromptUserRole {
            while currentState.last != State.Idle {
                currentState.popLast()
            }
        }
        else if action == Action.ReceivedConnection && currentState.last == State.Hosting {
            Analytics.logEvent("se3_connected_hosting", parameters: [:])
            currentState.popLast()
            currentState.append(State.ConnectedTyping)
            currentState.append(State.Typing)
            UIApplication.shared.isIdleTimerDisabled = true //Prevent the app from going to sleep
            enterStateConnectedTyping()
            enterStateTyping()
        }
        else if action == Action.ReceivedConnection && (currentState.last == State.BrowsingForPeers || currentState.last == State.OpenedSessionBrowser) {
            Analytics.logEvent("se3_connected_not_hosting", parameters: [:])
            currentState.popLast()
            currentState.append(State.ConnectedSpeaking)
            currentState.append(State.Reading)
            UIApplication.shared.isIdleTimerDisabled = true //Prevent the app from going to sleep
            enterStateConnectedSpeaking()
            enterStateReading()
        }
        else if action == Action.TypistDeletedAllText && currentState.contains(State.Typing) {
            while currentState.last != State.Typing {
                currentState.popLast()
            }
            typistDeletedAllText()
        }
        else if action == Action.TypistDeletedAllText && currentState.contains(State.Reading) {
            //The partner has deleted all text
            typistDeletedAllText()
        }
        else if action == Action.TypistStartedTyping && currentState.last == State.Typing {
            currentState.append(State.TypingStarted)
        }
        else if action == Action.TypistFinishedTyping && currentState.contains(State.ConnectedTyping) {
            //Means we are connected to another device
            while currentState.last != State.ConnectedTyping {
                currentState.popLast()
            }
            currentState.append(State.Listening)
            exitStateTyping()
            sendText(text: "\n")
            enterStateListening()
        }
        else if action == Action.TypistFinishedTyping {
            exitStateTyping()
            if currentState.last == State.TypingStarted {
                //User is not in conversation session
                //User had started typing
                sendResponseToWatch(text: self.textViewBottom?.text)
            }
            else if currentState.last == State.Typing {
                //User is not in a conversation session
                //User did not start typing.
                //User just finished typing
                sendStatusToWatch(beginningOfAction: false, success: false, text: "User did not enter response")
                enterStateIdle()
            }
            while currentState.last != State.Idle {
                currentState.popLast()
            }
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
        else if action == Action.LostConnection || action == Action.PartnerEndedSession {
            while currentState.last != State.Idle {
                currentState.popLast()
            }
            exitStateTyping()
            exitStateSpeaking()
            exitStateConnected()
            exitStateHosting()
            exitStateBrowsingForPeers()
            enterStateIdle()
            dialogConnectionLost()
        }
        
    }
    
    
    // MARK: UIViewController
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        (view as? ThreeDTouchView)?.whiteSpeechViewControllerProtocol = self as WhiteSpeechViewControllerProtocol
        
        //currentState.append(State.SubscriptionNotPaid)
        currentState.append(State.ControllerLoaded) //Push
        changeState(action: Action.AppOpened)
        
        // Disable the record buttons until authorization has been granted.
        recordButton?.isEnabled = false
        
        textViewTop?.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi)) //To turn one textView upside down
        //recordLabel?.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
        //timerLabel?.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
        mainView?.accessibilityLabel = speechToTextInstructionString
        
        //self.textViewTop?.layoutManager.allowsNonContiguousLayout = false //Allows scrolling if text is more than screen real-estate
        //self.textViewBottom.layoutManager.allowsNonContiguousLayout = false
        
        peerID = MCPeerID(displayName: UIDevice.current.name)
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self
        
        //Setup bluetooth check
        cbCentralManager          = CBCentralManager()
        cbCentralManager.delegate = self
        
        //Setup watch connectivity
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
        
        //UserDefaults.standard.removeObject(forKey: "SE3_IOS_USER_TYPE")
        let se3UserType = UserDefaults.standard.string(forKey: "SE3_IOS_USER_TYPE")
        if se3UserType == nil || se3UserType == "_0" || se3UserType == "_2" {
            //If none selected, Assuming person to be deaf
            if #available(iOS 13.0, *) {
                if se3UserType == nil {
                    //No selection made
                    self.userStatusLabel?.text = "Tap here to change"
                    self.userStatusLabel.transform = CGAffineTransform(translationX: 20, y: 0)
                    UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.2, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
                        self.userStatusLabel.transform = CGAffineTransform.identity
                    }, completion: nil)
                }
                else {
                    self.userStatusLabel?.text = ""
                }
                self.hiLeftImageView?.tintColor = UIColor.systemBlue
                self.viLeftImageView?.tintColor = UIColor.systemGray
                self.hiLeftImageView?.image = UIImage(systemName: "speaker.slash")
                self.viLeftImageView?.image = UIImage(systemName: "eye.slash")
                self.userLeftImageView?.image = UIImage(systemName: "person")
                self.appIconButton?.image = UIImage(systemName: "app.fill")
                self.userRightImageView?.image = UIImage(systemName: "person")
                self.hiRightImageView?.image = UIImage(systemName: "speaker.slash")
                self.viRightImageView?.image = UIImage(systemName: "eye.slash")
                self.hiRightImageView?.tintColor = UIColor.systemGray
                self.viRightImageView?.tintColor = UIColor.systemGray
            }
        }
        else {
            //Person has declared themselves not p-w-d
            if #available(iOS 13.0, *) {
                self.userStatusLabel?.text = ""
                self.hiLeftImageView?.isHidden = true
                self.viLeftImageView?.isHidden = true
                self.hiLeftImageView?.image = UIImage(systemName: "speaker.slash")
                self.viLeftImageView?.image = UIImage(systemName: "eye.slash")
                self.userLeftImageView?.image = UIImage(systemName: "person")
                self.appIconButton?.image = UIImage(systemName: "app.fill")
                self.userRightImageView?.image = UIImage(systemName: "person")
                self.hiRightImageView?.image = UIImage(systemName: "speaker.slash")
                self.viRightImageView?.image = UIImage(systemName: "eye.slash")
                self.hiRightImageView?.isHidden = false
                self.viRightImageView?.isHidden = true
            }
        }
        
    }
    
    public func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable {
        }
        else if !session.isReachable {
            changeState(action: Action.WatchNotReachable)
        }
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
    
    public override func viewWillAppear(_ animated: Bool) {
        //We do not want the navigation bar on this screen
        if let navigationController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController {
            navigationController.setNavigationBarHidden(true, animated: false)
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        //Set the nav bar to visible for next view controller so that user can come back
        if let navigationController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController {
            navigationController.setNavigationBarHidden(false, animated: false)
        }
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
                self.changeState(action: Action.SpeakerDidSpeak)
                if self.currentState.last != State.Reading {
                    self.textViewTop?.text = result.bestTranscription.formattedString
                    self.textViewBottom?.text = result.bestTranscription.formattedString
                }
                if self.currentState.contains(State.ConnectedSpeaking) && self.currentState.last == State.Speaking {
                    self.sendText(text: result.bestTranscription.formattedString)
                }
                
                if self.textViewBottom.text.count > 0 {
                    let location = self.textViewBottom.text.count - 1
                    let bottom = NSMakeRange(location, 1)
                    self.textViewTop?.scrollRangeToVisible(bottom)
                    self.textViewBottom?.scrollRangeToVisible(bottom)
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
                
                if self.currentState.last == State.Idle {
                    if let resultText = self.textViewBottom?.text {
                        if resultText.count > 0 {
                            self.sendResponseToWatch(text: resultText)
                        }
                        else {
                            self.sendStatusToWatch(beginningOfAction: false, success: false, text: "User did not enter response")
                        }
                    }
                    
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
        textViewBottom.text = "I am listening..."
    }
    
    private func animateNoInternetConnection() {
        self.noInternetImageView?.isHidden = false
        self.noInternetImageView?.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: .allowUserInteraction,
                       animations: { [weak self] in
                        self?.noInternetImageView.transform = .identity
            },
                       completion: { _ in
                           self.noInternetImageView?.isHidden = true
                           self.sayThis(string: "No internet connection")
                       })
    }
    
    // MARK: State Machine Private Helpers
    private func enterStateControllerLoaded() {
        if #available(iOS 13.0, *) {
            self.hiLeftImageView?.image = UIImage(systemName: "speaker.slash")
            self.viLeftImageView?.image = UIImage(systemName: "eye.slash")
            self.userLeftImageView?.image = UIImage(systemName: "person")
            self.appIconButton?.image = UIImage(systemName: "app.fill")
            self.userRightImageView?.image = UIImage(systemName: "person")
            self.viRightImageView?.image = UIImage(systemName: "eye.slash")
            self.hiRightImageView?.image = UIImage(systemName: "speaker.slash")
        }
        self.disabledContextLabel?.textColor = UIColor.lightGray
        self.disabledContextLabel?.isHidden = true
        self.recordLabel?.textColor = UIColor.darkGray
        
        let se3UserType = UserDefaults.standard.string(forKey: "SE3_IOS_USER_TYPE")
        if se3UserType == "_1" {
            self.recordLabel?.text = speechToTextInstructionString
        }
        else {
            self.recordLabel?.text = typingInstructionString
        }

     /*   let transform2 = self.recordLabel?.transform.scaledBy(x: 1.5, y: 1.5)
        UIView.animate(withDuration: 2.0) {
            //self.composerStackView?.transform = transform1 ?? CGAffineTransform()
            self.recordLabel?.transform = transform2 ?? CGAffineTransform()
            
            //self.view.layoutIfNeeded()
        }   */
        if se3UserType != nil {
            //If it is nil, it means user has never gone to the user profile. We need to emphasize that instead. If it is not nil, they have gone there before. We can animate this.s
            self.recordLabel?.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            UIView.animate(withDuration: 2.0,
                           delay: 0,
                           usingSpringWithDamping: 0.2,
                           initialSpringVelocity: 6.0,
                           options: .allowUserInteraction,
                           animations: { [weak self] in
                            self?.recordLabel?.transform = .identity
                },
                           completion: nil)
        }
        else {
            self.userStatusLabel?.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            UIView.animate(withDuration: 2.0,
                           delay: 0,
                           usingSpringWithDamping: 0.2,
                           initialSpringVelocity: 6.0,
                           options: .allowUserInteraction,
                           animations: { [weak self] in
                            self?.userStatusLabel?.transform = .identity
                },
                           completion: nil)
        }
        
        self.textViewBottom?.text = ""
        
    }
    
    private func swipeLeft() {
        //Open the chat log
        guard let storyBoard : UIStoryboard = self.storyboard else {
            return
        }
        let speechViewController = storyBoard.instantiateViewController(withIdentifier: "SpeechViewController") as! SpeechViewController
        speechViewController.dataChats.removeAll()
        speechViewController.dataChats.append(contentsOf: dataChats)
        speechViewController.inputAction = Action.OpenedChatLogForReading
        speechViewController.whiteSpeechViewControllerProtocol = self as WhiteSpeechViewControllerProtocol
        if let navigationController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController {
            navigationController.pushViewController(speechViewController, animated: true)
        }
    }
    
    private func openAppleWatchAppInfoScreen() {
        performSegue(withIdentifier: "segueAppleWatch", sender: nil)
    }
    
    private func openUserProfileOptions() {
        guard let storyBoard : UIStoryboard = self.storyboard else {
            return
        }
        let userProfileOptionsViewController = storyBoard.instantiateViewController(withIdentifier: "TwoPeopleProfileOptions") as! TwoPeopleSettingsViewController
        userProfileOptionsViewController.inputUserProfileOption = UserDefaults.standard.string(forKey: "SE3_IOS_USER_TYPE")
        userProfileOptionsViewController.whiteSpeechViewControllerProtocol = self as WhiteSpeechViewControllerProtocol
        self.present(userProfileOptionsViewController, animated: true, completion: nil)
     /*   if let navigationController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController {
            navigationController.pushViewController(userProfileOptionsViewController, animated: true)
        } */
    }
    
    private func enterStateIdle() {
        //self.textViewBottom?.text = "Tap & Hold to Record"
    }
    
    private func enterStatePromptUserRole() {
        dialogTypingOrSpeaking()
    }
    
    private func enterStateHosting() {
        self.textViewBottom?.text = "Started session. Ensure WiFi and bluetooth are ON for all connecting devices. Waiting for other devices to join..."
        self.longPressLabel?.text = "Long press to stop session"
        self.recordLabel?.isHidden = true
        self.swipeUpLabel?.isHidden = true
        self.swipeLeftLabel?.isHidden = true
        startHosting()
    }
    
    private func exitStateHosting() {
        self.textViewBottom?.text = "Session ended"
        self.longPressLabel?.text = "Long press to connect to another device"
        self.recordLabel?.isHidden = false
        self.swipeUpLabel?.isHidden = false
        self.swipeLeftLabel?.isHidden = false
        stopHosting()
    }
    
    func enterStateBrowsingForPeers() {
        self.textViewBottom?.text = "Looking for other devices. Ensure all devices are on the same WiFi network."
        self.longPressLabel?.text = "Long press to stop session"
        self.recordLabel?.isHidden = true
        self.swipeUpLabel?.isHidden = true
        self.swipeLeftLabel?.isHidden = true
        mcNearbyServiceBrowser = MCNearbyServiceBrowser(peer: peerID, serviceType: "hws-kb")
        mcNearbyServiceBrowser.delegate = self
        mcNearbyServiceBrowser.startBrowsingForPeers()
    }
    
    private func exitStateOpenedSessionBrowser() {
        self.textViewBottom?.text = "Session stopped"
        self.longPressLabel?.text = "Long press to to look for other devices"
        self.recordLabel?.isHidden = false
        self.swipeUpLabel?.isHidden = false
        self.swipeLeftLabel?.isHidden = false
    }
    
    private func exitStateBrowsingForPeers() {
        self.textViewBottom?.text = "Session stopped"
        self.longPressLabel?.text = "Long press to to look for other devices"
        self.recordLabel?.isHidden = false
        self.swipeUpLabel?.isHidden = false
        self.swipeLeftLabel?.isHidden = false
        self.mcNearbyServiceBrowser?.stopBrowsingForPeers()
    }
    
    private func enterStateConnectedTyping() {
        self.recordLabel?.isHidden = true
        self.swipeUpLabel?.isHidden = true
        self.swipeLeftLabel?.isHidden = true
    }
    
    private func enterStateListening() {
        self.textViewBottom?.text = "Connected, waiting for the other person to start talking..."
        self.recordLabel?.isHidden = true
        self.swipeUpLabel?.isHidden = true
        self.swipeLeftLabel?.isHidden = true
    }
    
    private func enterStateConnectedSpeaking() {
        self.recordLabel?.isHidden = true
        self.swipeUpLabel?.isHidden = true
        self.swipeLeftLabel?.isHidden = true
    }
    
    private func enterStateReading() {
        self.textViewBottom?.text = "Connected, waiting for the other person to start typing..."
        self.recordLabel?.isHidden = true
        self.swipeUpLabel?.isHidden = true
        self.swipeLeftLabel?.isHidden = true
    }
    
    private func enterStateTyping() {
        //Close stack views
        bottomLeftStackView?.isHidden = true
        navStackView?.isHidden = true
        //
        
        if #available(iOS 13.0, *) {
            let se3UserType = UserDefaults.standard.string(forKey: "SE3_IOS_USER_TYPE")
            if se3UserType == nil || se3UserType == "_0" || se3UserType == "_2" {
                // Deaf user
                self.hiLeftImageView?.image = UIImage(systemName: "speaker.slash.fill")
                self.viLeftImageView?.image = UIImage(systemName: "eye.slash.fill")
                self.userLeftImageView?.image = UIImage(systemName: "person.fill")
                self.appIconButton?.image = UIImage(systemName: "app")
                self.userRightImageView?.image = UIImage(systemName: "person")
                self.hiRightImageView?.image = UIImage(systemName: "speaker.slash")
                self.viRightImageView?.image = UIImage(systemName: "eye.slash")
            }
            else if se3UserType == "_1" {
                // Normal user
                self.hiLeftImageView?.image = UIImage(systemName: "speaker.slash")
                self.viLeftImageView?.image = UIImage(systemName: "eye.slash")
                self.userLeftImageView?.image = UIImage(systemName: "person")
                self.appIconButton?.image = UIImage(systemName: "app")
                self.userRightImageView?.image = UIImage(systemName: "person.fill")
                self.hiRightImageView?.image = UIImage(systemName: "speaker.slash.fill")
                self.viRightImageView?.image = UIImage(systemName: "eye.slash.fill")
            }
        }
        self.userStatusLabel?.text = "Hearing-impaired person typing"
        self.disabledContextLabel?.text = ""
        self.disabledContextLabel?.isHidden = true
        self.recordLabel?.text = "Tap Screen or Tap Return button to complete"
        self.textViewBottom?.text = "Start typing..."
        textViewBottom?.isEditable = true
        textViewBottom?.becomeFirstResponder()
        
        let stackViewTransform = self.composerStackView?.transform.translatedBy(x: 0, y: -40) // delta = -10
        let textViewBottomTransform = self.textViewBottom?.transform.translatedBy(x: 0, y: -85) // delta = -40
        UIView.animate(withDuration: 1.0) {
            self.composerStackView?.transform = stackViewTransform ?? CGAffineTransform()
            self.textViewBottom?.transform = textViewBottomTransform ?? CGAffineTransform()
        }
    }
    
    private func exitStateTyping() {
        //Show stack views
        navStackView?.isHidden = false
        bottomLeftStackView?.isHidden = false
        //
        exitStateTypingOrSpeaking()
        
        textViewBottom?.isEditable = false
        textViewBottom?.resignFirstResponder()
        if currentState.last == State.Typing {
            //Means nothing was actually entered
            userStatusLabel?.text = ""
            recordLabel?.text = typingInstructionString
            if dataChats.count > 0 {
                if dataChats[dataChats.count - 1].mode == "typing" {
                    //If the last message was typed
                    recordLabel?.text = speechToTextInstructionString
                    disabledContextLabel?.isHidden = false
                    disabledContextLabel?.text = hiSIContextString
                }
                textViewBottom?.text = dataChats[dataChats.count - 1].text
            }
            else {
                textViewBottom?.text = ""
            }
        }
        else {
            guard let newText = textViewBottom?.text else {
                return
            }
            sayThis(string: newText)
            self.dataChats.append(ChatListItem(text: newText, origin: peerID.displayName, mode: "typing"))
            
            if dataChats.count == 1 {
                //Means its the first entry in the chat list
                if #available(iOS 13.0, *) {
                    self.chatLogBtn?.image = UIImage(systemName: "book.fill")
                } else {
                    // Fallback on earlier versions
                }
                self.chatLogBtn?.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                UIView.animate(withDuration: 1.0,
                               delay: 0,
                               usingSpringWithDamping: 0.2,
                               initialSpringVelocity: 6.0,
                               options: .allowUserInteraction,
                               animations: { [weak self] in
                                self?.chatLogBtn.transform = .identity
                    },
                               completion: nil)
            }
            
            userStatusLabel?.text = "Give the device to the other person"
            recordLabel?.text = speechToTextInstructionString
            disabledContextLabel?.isHidden = false
            disabledContextLabel?.text = hiSIContextString

        }
        
        
        let stackViewTransform = self.composerStackView?.transform.translatedBy(x: 0, y: 40) //80
        let textViewBottomTransform = self.textViewBottom?.transform.translatedBy(x: 0, y: 85) //130
        UIView.animate(withDuration: 1.0) {
            self.composerStackView?.transform = stackViewTransform ?? CGAffineTransform()
            self.textViewBottom?.transform = textViewBottomTransform ?? CGAffineTransform()
        }
    }
    
    private func exitStateTypingOrSpeaking() {
        if #available(iOS 13.0, *) {
            self.hiLeftImageView?.image = UIImage(systemName: "speaker.slash")
            self.viLeftImageView?.image = UIImage(systemName: "eye.slash")
            self.userLeftImageView?.image = UIImage(systemName: "person")
            self.appIconButton?.image = UIImage(systemName: "app.fill")
            self.userRightImageView?.image = UIImage(systemName: "person")
            self.hiRightImageView?.image = UIImage(systemName: "speaker.slash")
            self.viRightImageView?.image = UIImage(systemName: "eye.slash")
        }
    }
    
    private func enterStateReceivingFromWatch() {
        //When coming from the watch
        //Use this to update the UI instantaneously (otherwise, takes a little while)
        DispatchQueue.main.async(execute: { () -> Void in
            self.swipeLeftLabel?.isHidden = true
            self.swipeUpLabel?.isHidden = true
            self.recordLabel?.isHidden = true
            self.longPressLabel?.isHidden = false
            self.longPressLabel?.text = "Long press to stop"
        })
        
    }
    
    private func exitStateReceivingFromWatch() {
        //When coming from the watch
        //Use this to update the UI instantaneously (otherwise, takes a little while)
        DispatchQueue.main.async(execute: { () -> Void in
            self.swipeLeftLabel?.isHidden = false
            self.swipeUpLabel?.isHidden = false
            self.longPressLabel?.isHidden = false
            self.longPressLabel?.text = "Long press to connect to another device"
            self.recordLabel?.isHidden = false
        })
    }
    
    private func enterStateSpeaking() {
        if hasInternetConnection() {
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate)) //vibration ONLY if not receiving
            //try! startRecording()
            //runTimer()
            //recordButton?.setTitle("Stop recording", for: [])
            
            //Close/hide stack views
            navStackView?.isHidden = true
            bottomLeftStackView?.isHidden = true
            //
            
            if #available(iOS 13.0, *) {
                let se3UserType = UserDefaults.standard.string(forKey: "SE3_IOS_USER_TYPE")
                if se3UserType == nil || se3UserType == "_0" || se3UserType == "_2" {
                    // Normal user
                    self.hiLeftImageView?.image = UIImage(systemName: "speaker.slash")
                    self.viLeftImageView?.image = UIImage(systemName: "eye.slash")
                    self.userLeftImageView?.image = UIImage(systemName: "person")
                    self.appIconButton?.image = UIImage(systemName: "app")
                    self.userRightImageView?.image = UIImage(systemName: "person.fill")
                    self.hiRightImageView?.image = UIImage(systemName: "speaker.slash.fill")
                    self.viRightImageView?.image = UIImage(systemName: "eye.slash.fill")
                }
                else if se3UserType == "_1" {
                    // Deaf user
                    self.hiLeftImageView?.image = UIImage(systemName: "speaker.slash.fill")
                    self.viLeftImageView?.image = UIImage(systemName: "eye.slash.fill")
                    self.userLeftImageView?.image = UIImage(systemName: "person.fill")
                    self.appIconButton?.image = UIImage(systemName: "app")
                    self.userRightImageView?.image = UIImage(systemName: "person")
                    self.hiRightImageView?.image = UIImage(systemName: "speaker.slash")
                    self.viRightImageView?.image = UIImage(systemName: "eye.slash")
                }
            }
            self.userStatusLabel?.text = "Non hearing-impaired person speaking"
            disabledContextLabel?.isHidden = true
            disabledContextLabel?.text = ""
            navStackView?.isHidden = true
            self.timerLabel?.alpha = 0
            
            //let labelTransform = self.recordLabel?.transform.scaledBy(x: 0.5, y: 0.5)
            //let stackViewTransform = self.composerStackView?.transform.translatedBy(x: 0.0, y: -50.0)
            UIView.animate(withDuration: 0.5, animations: {
                //self.recordLabel?.transform = labelTransform ?? CGAffineTransform()
                //self.composerStackView?.transform = stackViewTransform ?? CGAffineTransform()
                self.timerLabel?.alpha = 1
                
                if self.recordLabel != nil {
                    
                    UIView.transition(with: self.recordLabel!,
                                      duration: 2.0,
                                      options: .transitionCrossDissolve,
                                      animations: { [weak self] in
                                        self!.recordLabel!.text = "Tap screen to stop recording"
                        }, completion: nil)
                }
                
                try! self.startRecording()
                self.runTimer()
            })
            
        /*    UIView.animate(withDuration: 2.0) {
                self.timerLabel?.alpha = 1
                self.recordLabel?.transform.scaledBy(x: 1, y: 1) //CGAffineTransform(scaleX: 1, y: 1)
                self.composerStackView?.transform.translatedBy(x: 0.0, y: -100.0)
                //self.view.layoutIfNeeded()
            }   */
            recordLabel?.isHidden = false
            swipeUpLabel?.isHidden = true
            swipeLeftLabel?.isHidden = true
            longPressLabel?.isHidden = true
        }
        else {
            //dialogOK(title: "Alert", message: "No internet connection")
            animateNoInternetConnection()
        }
    }
    
    private func exitStateSpeaking() {
        //Show stack views
        navStackView?.isHidden = false
        bottomLeftStackView?.isHidden = false
        //
        exitStateTypingOrSpeaking()
        
        textViewBottom?.isEditable = false
        textViewBottom?.resignFirstResponder() //If keyboard is open for any reason, close it
        
        if audioEngine.isRunning {
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate)) //vibration to indicate end of recording
            audioEngine.stop()
            recognitionRequest?.endAudio()
            resetTimer()
            self.timerLabel?.isHidden = true
            navStackView?.isHidden = false
            if currentState.last != State.SpeechInProgress {
                //Means nothing was spoken
                userStatusLabel?.text = ""
                if dataChats.count > 0 && dataChats[dataChats.count - 1].mode == "typing" {
                    //If the last message was typed
                    disabledContextLabel?.isHidden = false
                    disabledContextLabel?.text = hiSIContextString
                    textViewBottom?.text = dataChats[dataChats.count - 1].text
                    recordLabel?.text = speechToTextInstructionString
                }
                else if dataChats.count > 0 && dataChats[dataChats.count - 1].mode == "talking" {
                    recordLabel?.text = typingInstructionString
                    disabledContextLabel?.isHidden = true
                    disabledContextLabel?.text = ""
                    textViewBottom?.text = dataChats[dataChats.count - 1].text
                }
                else {
                    recordLabel?.isHidden = false
                    recordLabel?.text = speechToTextInstructionString
                    disabledContextLabel?.isHidden = true
                    disabledContextLabel?.text = ""
                    textViewBottom?.text = ""
                }
            }
            else {
                userStatusLabel?.text = "Give the device to the other person"
                recordLabel?.text = typingInstructionString //In this section we are guaranteed to have new text
                guard let newText = textViewBottom?.text else {
                    return
                }
                sayThis(string: newText)
                self.dataChats.append(ChatListItem(text: newText, origin: peerID.displayName, mode: "talking"))
                
                if dataChats.count == 1 {
                    //Means its the first entry in the chat list
                    if #available(iOS 13.0, *) {
                        self.chatLogBtn?.image = UIImage(systemName: "book.fill")
                    } else {
                        // Fallback on earlier versions
                    }
                    self.chatLogBtn?.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                    UIView.animate(withDuration: 1.0,
                                   delay: 0,
                                   usingSpringWithDamping: 0.2,
                                   initialSpringVelocity: 6.0,
                                   options: .allowUserInteraction,
                                   animations: { [weak self] in
                                    self?.chatLogBtn.transform = .identity
                        },
                                   completion: nil)
                }
            }
            
        /*    recordButton?.isEnabled = false
            recordButton?.setTitle("Stopping", for: .disabled)
            recordLabel?.text = "Stopping"
            resetTimer()
            //textViewTop?.font = textViewTop?.font?.withSize(16)
            textViewTop?.text = ""
            //textViewBottom.font = textViewBottom.font?.withSize(16)
            textViewBottom.text = ""
            swipeUpLabel?.isHidden = false
            swipeLeftLabel?.isHidden = false
            longPressLabel?.isHidden = false
             */
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
    
    private func exitStateConnected() {
        UIApplication.shared.isIdleTimerDisabled = false //The screen is allowed to dim
        mcSession?.disconnect()
        self.textViewBottom?.isEditable = false
        self.textViewBottom?.resignFirstResponder()
        self.longPressLabel?.text = "Long press to connect to a device"
        self.recordLabel?.isHidden = false
        self.swipeUpLabel?.isHidden = false
        self.swipeLeftLabel?.isHidden = false
        self.dismiss(animated: true)
    }
    
    
    
    func typistDeletedAllText() {
        if currentState.contains(State.ConnectedSpeaking) {
            self.textViewBottom?.text = "Connected, waiting for the other person to start typing..."
        }
        else {
            self.textViewBottom?.text = "Start typing..."
        }
    }
    
    // MARK: General Private Helpers
    
    func hasInternetConnection() -> Bool {
        return networkManager.reachability?.connection == .wifi || networkManager.reachability?.connection == .cellular
      //  guard let reachability = SCNetworkReachabilityCreateWithName(nil, "www.google.com") else { return false }
     /*   var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let reachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags = SCNetworkReachabilityFlags()
        SCNetworkReachabilityGetFlags(reachability!, &flags)
        if !isNetworkReachable(with: flags) {
            // Device doesn't have internet connection
            return false
        }
        return true */
    }
    
    func checkAppleSpeechRecoginitionPermissions() -> String? {
        if hasInternetConnection() == false {
            return "internet"
        }
      /*  if AVAudioSession.sharedInstance().recordPermission() != AVAudioSession.RecordPermission.granted {
            return "mic"
        }   */
        if SFSpeechRecognizer.authorizationStatus() != .authorized {
            return "not_authorized"
        }
        return nil
    }
    
    func showErrorMessageFormPermission(permission: String?) {
        //We will only dispay a warning message. Cannot prompt for permission. User has to do it themselves in the settings app
        if permission?.contains("internet") == true {
            dialogOK(title: "No internet connection", message: "You need an internet connection to use speech-to-text")
        }
        else if permission?.contains("mic") == true {
            dialogOK(title: "Permission Error", message: "Mic permission is needed to record what is being said. Please provide the permission in the settings app")
        }
        else if permission?.contains("not_authorized") == true {
            dialogOK(title: "Permission Error", message: "Speech Recognition permission is needed to understand the words that are being said. Please provide the permission in the settings app")
        }
    }
    
    func isNetworkReachable(with flags: SCNetworkReachabilityFlags) -> Bool {
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        let canConnectAutomatically = flags.contains(.connectionOnDemand) || flags.contains(.connectionOnTraffic)
        let canConnectWithoutUserInteraction = canConnectAutomatically && !flags.contains(.interventionRequired)
        
        return isReachable && (!needsConnection || canConnectWithoutUserInteraction)
    }
    
    func getDeviceType() -> String {
        switch UIDevice.current.userInterfaceIdiom {
            case .phone:
                return "iPhone"
            case .pad:
                return "iPad"
            case .unspecified:
                return "unspecified"
            default:
                return "unknown"
        }
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
    
    func dialogConnectionLost() {
        let alert = UIAlertController(title: "Sorry", message: "Connection Lost", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { action in
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
        let alert = UIAlertController(title: "Start a conversation session with another iOS device. One device will type and the other device will talk", message: "If you are hearing impaired, select Typing, then ask your partner to select Speaking. If you are not hearing impaired, select Speaking and connect to the device that will be typing. Note that in order to connect, both devices must have WiFi and bluetooth switched ON.", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "I am hearing-impaired, I will type", style: .default, handler: { action in
            switch action.style{
            case .default:
                self.changeState(action: Action.UserSelectedTyping)
                
            case .cancel:
                print("cancel")
                
            case .destructive:
                print("destructive")
                
                
            }}))
        alert.addAction(UIAlertAction(title: "I am not hearing-impaired, I will speak", style: .default, handler: { action in
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
            Analytics.logEvent("se3_timer_finished", parameters: [:])
            resetTimer()
            tapGesture() //this should stop the recording
        }
        if seconds == 10 {
            //Removing this for now as we do not know how to switch back to system color in swift. System color is needed for light/dark mode
            //timerLabel?.textColor = UIColor.red
            timerLabel?.transform = CGAffineTransform(translationX: 20, y: 0)
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.2, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
                self.timerLabel?.transform = CGAffineTransform.identity
            }, completion: nil)
        }
    }
    
    func runTimer() {
        if !isTimerRunning {
            timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(WhiteSpeechViewController.updateTimer)), userInfo: nil, repeats: true)
            isTimerRunning = true
        }
        timerLabel?.isHidden = false
    }
    
    func resetTimer() {
        timer.invalidate()
        isTimerRunning = false
        seconds = 60
        timerLabel?.text = "1:00"
        timerLabel?.isHidden = true
    }
    
    func timeString(time:TimeInterval) -> String {
        
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        
        return String(format:"%01i:%02i", minutes, seconds)
        
    }
    
    //Send to iOS/macOS device via MultipeerConnectivity
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
    
    func sendStatusToWatch(beginningOfAction: Bool, success: Bool, text: String) {
        if WCSession.isSupported() {
            let session = WCSession.default
            if session.isReachable && session.isWatchAppInstalled {
                session.sendMessage(["beginningOfAction": beginningOfAction, "success": success, "status": text], replyHandler: nil, errorHandler: nil)
            }
        }
    }
    
    func sendResponseToWatch(text: String!) {
        if WCSession.isSupported() {
            let session = WCSession.default
            if session.isReachable && session.isWatchAppInstalled {
                session.sendMessage(["response": text], replyHandler: nil, errorHandler: nil)
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
    
    private func sayThis(string: String) {
        let audioSession = AVAudioSession.sharedInstance()
        do { try audioSession.setCategory(AVAudioSessionCategoryPlayback) }
        catch { showToast(message: "Sorry, audio failed to play") }
        do { try audioSession.setMode(AVAudioSessionModeDefault) }
        catch { showToast(message: "Sorry, audio failed to play") }
        
        synth.delegate = self
        let utterance = AVSpeechUtterance(string: string)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        if synth.isSpeaking {
            synth.stopSpeaking(at: AVSpeechBoundary.immediate)
            synth.speak(utterance)
        }
        if synth.isPaused {
            synth.continueSpeaking()
        }
        else {
            synth.speak(utterance)
        }
    }
    
    func showToast(message : String) {
        
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 75, y: self.view.frame.size.height-100, width: 150, height: 60))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(1.0) //0.6
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center;
        toastLabel.numberOfLines = 2
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
    
}

extension WhiteSpeechViewController : SFSpeechRecognizerDelegate {
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            recordButton?.isEnabled = true
            recordButton?.setTitle("Start Recording", for: [])
            recordLabel?.text = speechToTextInstructionString
            
        } else {
            recordButton?.isEnabled = false
            recordButton?.setTitle("Recognition not available", for: .disabled)
            recordLabel?.text = "Recognition not available"
        }
    }
}

extension WhiteSpeechViewController : MCSessionDelegate {
    public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case MCSessionState.connected:
            DispatchQueue.main.async { [unowned self] in
                self.longPressLabel?.text = "Connected: \(peerID.displayName)" + "\n" + "Long press to disconnect"
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
}

extension WhiteSpeechViewController : MCBrowserViewControllerDelegate {
    public func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    public func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
        changeState(action: Action.BrowserCancelled)
    }
}

extension WhiteSpeechViewController : MCNearbyServiceBrowserDelegate {
    public func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        dialogNewConnection(title: "New device found", message: "Found device with name: \(peerID.displayName). Would you like to connect to it?", peerId: peerID)
    }
    
    public func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        self.textViewBottom?.text = "Looking for a device to connect to."
    }
}

extension WhiteSpeechViewController : UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        var str = textView.attributedText.string
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
}


extension WhiteSpeechViewController : CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            isBluetoothOn = true
            break
        case .poweredOff:
            isBluetoothOn = false
            break
        case .resetting:
            break
        case .unauthorized:
            break
        case .unsupported:
            break
        case .unknown:
            break
        default:
            break
        }
    }
}


extension WhiteSpeechViewController : WCSessionDelegate {
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    public func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    public func sessionDidDeactivate(_ session: WCSession) {
        
    }
    
    
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        
        Analytics.logEvent("se3_received_from_watch", parameters: [
            "os_version": UIDevice.current.systemVersion,
            "device_type": getDeviceType(),
            "current_state": currentState.last?.rawValue
            ])
        
        var status = false
        var response = ""
        
        if let watchStatus = message["status"] as? String {
            status = true
            response = "Message displayed on iPhone"
            
            // foreground
            //Use this to update the UI instantaneously (otherwise, takes a little while)
            if let state = currentState.last {
                if state == State.Idle {
                    DispatchQueue.main.async(execute: { () -> Void in
                        if UIApplication.shared.applicationState == .active {
                            self.textViewBottom?.text = watchStatus
                        }
                    })
                }
            }
            changeState(action: Action.ReceivedStatusFromWatch)
        }
        else if let cancalledTyping = message["user_cancelled_typing"] as? String {
            response = cancalledTyping //Used only for analytics
            changeState(action: Action.ReceivedStatusFromWatch)
        }
        else if let request = message["request"] as? String {
            if currentState.last == State.ReceivingFromWatch {
                // foreground
                //Use this to update the UI instantaneously (otherwise, takes a little while)
                DispatchQueue.main.async(execute: { () -> Void in
                    if UIApplication.shared.applicationState == .active {
                        self.textViewBottom?.text = request
                    }
                })
                changeState(action: Action.ReceivedContentFromWatch)
            }
            else if currentState.contains(State.ConnectedTyping) || currentState.contains(State.ConnectedSpeaking) ||
                currentState.contains(State.Hosting) ||
                currentState.contains(State.OpenedSessionBrowser) ||
                currentState.contains(State.BrowsingForPeers) ||
                currentState.contains(State.PromptUserRole) {
                status = false
                response = "iPhone is in conversation session. Message not displayed"
            }
            else if currentState.last == State.Speaking {
                status = false
                response = "User is speaking into iPhone. Message not displayed"
            }
            else if currentState.last == State.Typing {
                status = false
                response = "User is typing on iPhone. Message not displayed"
            }
            
            
        }
        
        replyHandler(["status": status, "response":response])
    }
}

extension WhiteSpeechViewController : AVSpeechSynthesizerDelegate {
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        let mutableAttributedString = NSMutableAttributedString(string: utterance.speechString)
        mutableAttributedString.addAttribute(.foregroundColor, value: UIColor.green, range: characterRange)
        let font = textViewBottom?.font
        let alignment = textViewBottom.textAlignment
        textViewBottom?.attributedText = mutableAttributedString //all attributes get ovverridden here. necessary to save it before hand
        textViewBottom?.font = font
        textViewBottom?.textAlignment = alignment
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        textViewBottom?.text = utterance.speechString
    }
}


///Protocol
protocol WhiteSpeechViewControllerProtocol {
    func touchBegan(withForce : CGFloat)
    func touchEnded(numberOfTransformations : Int)
    func maxForceReached()
    
    //Coming back from chat logs
    func chatLogsCleared()
    
    //Coming back after setting user profile
    func userProfileOptionSet(se3UserType : String)
}

extension WhiteSpeechViewController : WhiteSpeechViewControllerProtocol {
    func userProfileOptionSet(se3UserType : String) {
        Analytics.logEvent("se3_user_profile_setxs", parameters: [
            "user_type": se3UserType
        ])
        
        if se3UserType == "_1" {
            hiLeftImageView?.tintColor = UIColor.systemGray // Main user is normal
            viLeftImageView?.tintColor = UIColor.systemGray
            hiRightImageView?.tintColor = UIColor.systemBlue // Other user is deaf
            viRightImageView?.tintColor = UIColor.systemGray
            recordLabel?.text = speechToTextInstructionString
        }
        else if se3UserType == "_2" {
            hiLeftImageView?.tintColor = UIColor.systemBlue // Main user is deaf
            viLeftImageView?.tintColor = UIColor.systemGray
            hiRightImageView?.tintColor = UIColor.systemGray // Other user is normal
            viRightImageView?.tintColor = UIColor.systemGray
            recordLabel?.text = typingInstructionString
        }
        
        self.userProfileVerticalStackView?.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: .allowUserInteraction,
                       animations: { [weak self] in
                        self?.userProfileVerticalStackView.transform = .identity
            },
                       completion: nil)
    }
    
    func chatLogsCleared() {
        if #available(iOS 13.0, *) {
            self.chatLogBtn?.image = UIImage(systemName: "book")
        } else {
            // Fallback on earlier versions
        }
        dataChats.removeAll()
        changeState(action: Action.ChatLogsCleared)
    }
    
    func maxForceReached() {
        changeState(action: Action.PressAndHold)
    }
    
    func touchEnded(numberOfTransformations : Int) {
        var mutableNumberOfTransformations = numberOfTransformations
        while mutableNumberOfTransformations > 0 {
            let labelTransform = self.recordLabel?.transform.scaledBy(x: 1.005, y: 1.005)
            let stackViewTransform = self.composerStackView?.transform.translatedBy(x: 0.0, y: 5.0)
            
            UIView.animate(withDuration: 0.5, animations: {
                self.recordLabel?.transform = labelTransform ?? CGAffineTransform()
                self.composerStackView?.transform = stackViewTransform ?? CGAffineTransform()
                
            })
            
            mutableNumberOfTransformations -= 1
        }
        changeState(action: Action.ReleaseHold)
        
    }
    
    func touchBegan(withForce: CGFloat) {
        let labelTransform = self.recordLabel?.transform.scaledBy(x: withForce > 0 ? 0.99 : 1.01, y: withForce > 0 ? 0.99 : 1.01)
        let stackViewTransform = self.composerStackView?.transform.translatedBy(x: 0.0, y: -5*withForce)
        UIView.animate(withDuration: 0.5, animations: {
            self.recordLabel?.transform = labelTransform ?? CGAffineTransform()
            self.composerStackView?.transform = stackViewTransform ?? CGAffineTransform()
            //self.timerLabel?.alpha = 1
            
            if self.recordLabel != nil {
                
             /*   UIView.transition(with: self.recordLabel!,
                                  duration: 2.0,
                                  options: .transitionCrossDissolve,
                                  animations: { [weak self] in
                                    self!.recordLabel!.text = "Start Speaking..."
                    }, completion: nil) */
            }
            
            //try! self.startRecording()
            //self.runTimer()
        })
    }
}
