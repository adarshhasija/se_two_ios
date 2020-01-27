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
import AVFoundation

public class SpeechViewController: UIViewController {

    // MARK: Properties
    let synth = AVSpeechSynthesizer()
    var inputAction : Action? = nil //Action that is passed in from previous controller
    var whiteSpeechViewControllerProtocol : WhiteSpeechViewControllerProtocol?
    var speechViewControllerProtocol : SpeechViewControllerProtocol?
    let networkManager = NetworkManager.sharedInstance
    var currentState: [State] = []
    var seconds = 60
    var timer = Timer()
    var isTimerRunning = false
    var emptyTableText : String?
    
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
    @IBOutlet weak var helpBarButtonItem: UIBarButtonItem! //To make this visible again, in storyboard, set Enabled to true + set Tint to Default. To make invisible: Enabled = false, Tint = Clear color
    
    @IBOutlet var tapGestureRecognizer: UITapGestureRecognizer!
    @IBOutlet var mainView : UIView?
    @IBOutlet var textViewTop : UITextView?
    @IBOutlet var textViewBottom : UITextView!
    @IBOutlet var recordButton : UIButton?
    @IBOutlet weak var longPressLabel: UILabel?
    @IBOutlet weak var recordLabel: UILabel?
    @IBOutlet weak var timerLabel: UILabel?
    @IBOutlet weak var swipeUpLabel: UILabel!
    @IBOutlet weak var typingButton: UIButton!
    @IBOutlet weak var speakingButton: UIButton!
    @IBOutlet weak var swipeLeftLabel: UILabel!
    @IBOutlet weak var connectDeviceButton: UIButton!
    @IBOutlet weak var helpTopicsButton: UIButton!
    
    @IBOutlet weak var viewDeafProfile: UIView!  //Top of the screen view to give context that the user is deaf
    @IBOutlet weak var labelTopStatus: UILabel!
    @IBOutlet weak var labelConvSessionInstruction: UILabel!
    @IBOutlet weak var textViewRealTimeTextInput: UITextView!
    @IBOutlet weak var conversationTableView: UITableView!
    var dataChats: [ChatListItem] = []
    
    
    @IBOutlet weak var stackViewBottomActions: UIStackView!
    @IBOutlet weak var stackViewSaveChatButton: UIStackView!
    @IBOutlet weak var buttonClearChatLog: UIButton!
    @IBOutlet weak var buttonYesSave: UIButton!
    @IBOutlet weak var buttonNoSave: UIButton!
    @IBOutlet weak var stackViewSaveChatDialog: UIStackView!
    @IBOutlet weak var stackViewMainAction: UIStackView!
    @IBOutlet weak var labelMainAction: UILabel!
    @IBOutlet weak var stackViewConnectDevice: UIStackView!
    @IBOutlet weak var labelConnectDevice: UILabel!
    // MARK: Interface Builder actions
    
    
    @IBAction func helpBarButtonItemTapped(_ sender: Any) {
        if currentState.contains(State.Typing) {
            changeState(action: Action.Tap)
        }
        else {
            changeState(action: Action.SwipeLeft)
        }
    }
    
    @IBAction func tapGesture() {
        if currentState.last != State.Idle {
            changeState(action: Action.Tap)
        }
    }
    
    
    @IBAction func longPressGesture(_ sender: UILongPressGestureRecognizer) {
      /*  if sender.state == UIGestureRecognizerState.began {
           changeState(action: Action.LongPress)
        }   */
    }
    
    
    @IBAction func swipeGesture(_ sender: UISwipeGestureRecognizer) {
      /*  if sender.direction == UISwipeGestureRecognizerDirection.up {
            changeState(action: Action.SwipeUp)
        }
        else if sender.direction == UISwipeGestureRecognizerDirection.left {
            changeState(action: Action.SwipeLeft)
        }   */
    }
    
    
    @IBAction func typeButtonTapped(_ sender: Any) {
        changeState(action: Action.SwipeUp)
    }
    
    
    @IBAction func talkButtonTapped(_ sender: Any) {
        changeState(action: Action.Tap)
    }
    
    
    //Same as the yes button. This saves the chat log.
    @IBAction func shareChatTapped(_ sender: Any) {
        Analytics.logEvent("se3_save_chat_tapped", parameters: [
            "log_size": dataChats.count
            ])
        saveChatLog()
    }
    @IBAction func buttonClearChatLogTapped(_ sender: Any) {
        Analytics.logEvent("se3_clear_chat_tapped", parameters: [
            "log_size": dataChats.count
            ])
        
        let alert = UIAlertController(title: "Are you sure?", message: "This action cannot be reversed. The chat log will be deleted", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "No", style: .default, handler: { action in
            switch action.style{
            case .default:
                print("default")
                
            case .cancel:
                print("cancel")
                
            case .destructive:
                print("destructive")
                
            }}))
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
            switch action.style{
            case .default:
                Analytics.logEvent("se3_clear_chat_yes", parameters: [:])
                self.dataChats.removeAll()
                self.conversationTableView?.reloadData()
                self.labelTopStatus?.isHidden = true
                self.labelConvSessionInstruction?.isHidden = true
                self.stackViewSaveChatButton?.isHidden = true
                self.buttonClearChatLog?.isHidden = true
                
                self.whiteSpeechViewControllerProtocol?.chatLogsCleared()
                self.navigationController?.popViewController(animated: true)
            case .cancel:
                print("cancel")
                
            case .destructive:
                print("destructive")
                
            }}))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func yesSaveTapped(_ sender: Any) {
        Analytics.logEvent("se3_save_chat_yes_tapped", parameters: [:])
        saveChatLog()
        self.stackViewSaveChatDialog?.isHidden = true
        self.stackViewMainAction?.isHidden = false
        self.stackViewConnectDevice?.isHidden = false
    }
    
    
    @IBAction func noSaveTapped(_ sender: Any) {
        Analytics.logEvent("se3_save_chat_no_tapped", parameters: [:])
        self.stackViewSaveChatDialog?.isHidden = true
        self.stackViewMainAction?.isHidden = false
        self.stackViewConnectDevice?.isHidden = false
    }
    
    
    @IBAction func connectDeviceTapped(_ sender: Any) {
        changeState(action: Action.LongPress)
    }
    
    
    @IBAction func helpTopicsButtonTapped(_ sender: Any) {
        changeState(action: Action.SwipeLeft)
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
        if synth.isSpeaking {
            synth.stopSpeaking(at: .immediate)
        }
        
        if action == Action.AppOpened {
            enterStateIdle()
        }
        else if action == Action.Tap && currentState.last == State.Idle {
            let result = checkAppleSpeechRecoginitionPermissions()
            if result == nil {
                Analytics.logEvent("se3_talk_tapped", parameters: [
                    "error":"no"
                    ])
                UIApplication.shared.isIdleTimerDisabled = true //Prevent the app from going to sleep
                sendStatusToWatch(beginningOfAction: true, success: true, text: "User is speaking on iPhone. Please wait. Tell them to tap the screen when they have finished recording")
                currentState.append(State.EditingMode)
                enterStateEditingMode(editingType: EditingType.Speaking)
            }
            else {
                Analytics.logEvent("se3_talk_tapped", parameters: [
                    "error":"yes",
                    "error_message": result
                    ])
                
                //We will only dispay a warning message. Cannot prompt for permission. User has to do it themselves in the settings app
                if result?.contains("internet") == true {
                    dialogOK(title: "No internet connection", message: "You need an internet connection to use speech-to-text")
                }
                else if result?.contains("mic") == true {
                    dialogOK(title: "Permission Error", message: "Mic permission is needed to record what is being said. Please provide the permission in the settings app")
                }
                else if result?.contains("not_authorized") == true {
                    dialogOK(title: "Permission Error", message: "Speech Recognition permission is needed to understand the words that are being said. Please provide the permission in the settings app")
                }
                
            }

            
        }
        else if action == Action.Tap && currentState.contains(State.Typing) {
            changeState(action: Action.TypistFinishedTyping)
        }
        else if action == Action.Tap && currentState.last == State.Speaking {
            exitStateSpeaking()
            currentState.popLast()
            //exitStateTyping()
            //exitStateSpeaking()
            if currentState.last == State.ConnectedTyping || currentState.last == State.ConnectedSpeaking {
                sendText(text: "\n") //Send to other other to confirm that speaking is done
                currentState.append(State.Reading)
                enterStateReading()
            }
        }
        else if (action == Action.SwipeLeft || action == Action.BarButtonHelpTapped) && currentState.last == State.Idle {
            Analytics.logEvent("se3_help_topics", parameters: [:])
            performSegue(withIdentifier: "segueHelpTopics", sender: nil)
        }
        else if action == Action.SwipeUp && currentState.last == State.Idle {
            Analytics.logEvent("se3_typing_tapped", parameters: [:])
            sendStatusToWatch(beginningOfAction: true, success: true, text: "User is typing on iPhone. Please wait. Tell them to tap Return or Done when complete.")
            currentState.append(State.EditingMode)
            enterStateEditingMode(editingType: EditingType.Typing)
        }
        else if action == Action.SwipeUp && currentState.last == State.ConnectedTyping {
            currentState.append(State.EditingMode)
            enterStateEditingMode(editingType: EditingType.Typing)
        }
        else if action == Action.Tap && currentState.last == State.ConnectedSpeaking {
            currentState.append(State.EditingMode)
            enterStateEditingMode(editingType: EditingType.Speaking)
        }
        else if action == Action.OpenedEditingModeForTyping && currentState.last == State.Idle {
            currentState.append(State.Typing)
            enterStateTyping()
        }
        else if action == Action.OpenedEditingModeForSpeaking && currentState.last == State.Idle {
            currentState.append(State.Speaking)
            enterStateSpeaking()
        }
        else if action == Action.OpenedChatLogForReading && currentState.last == State.Idle {
            currentState.append(State.ChatsReadAndShareOnly)
            enterStateChatsReadAndShareOnly()
        }
        else if action == Action.CompletedEditing && currentState.last == State.EditingMode {
            currentState.popLast() //pop editing mode
            exitStateEditingMode(isSuccessful: true)
            if currentState.last == State.Idle {
                UIApplication.shared.isIdleTimerDisabled = false //The screen is allowed to dim
            }
            else if currentState.last == State.ConnectedTyping {
                currentState.append(State.Listening)
                enterStateListening()
            }
            else if currentState.last == State.ConnectedSpeaking {
                //sendText(text: "\n") //Send to other other to confirm that speaking is done
                currentState.append(State.Reading)
                enterStateReading()
            }
        }
        else if action == Action.CancelledEditing && currentState.last == State.EditingMode {
            currentState.popLast() //pop editing mode
            exitStateEditingMode(isSuccessful: false)
            sendStatusToWatch(beginningOfAction: false, success: false, text: "User did not enter response")
            if currentState.last == State.Idle {
                UIApplication.shared.isIdleTimerDisabled = false //The screen is allowed to dim
            }
        }
        else if action == Action.LongPress && currentState.last == State.Idle {
            Analytics.logEvent("se3_long_press_not_connected", parameters: [:])
            currentState.append(State.PromptUserRole)
            enterStatePromptUserRole()
        }
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
            UIApplication.shared.isIdleTimerDisabled = true //Prevent the app from going to sleep
            enterStateConnectedTyping()
            //enterStateTyping()
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
        else if action == Action.SpeakerCancelledSpeaking && currentState.contains(State.Listening) {
            //The partner pressed the back button when speaking
            speakerCancelledSpeaking()
        }
        else if action == Action.SpeakerCancelledSpeaking && currentState.last == State.Speaking {
            currentState.popLast() //pop speaking. ViewController will be closed.
            exitStateSpeaking()
        }
        else if action == Action.TypistStartedTyping && currentState.last == State.Typing {
            currentState.append(State.TypingStarted)
        }
        else if action == Action.CompletedEditing && currentState.contains(State.ConnectedTyping) {
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
                guard let enteredText = self.textViewBottom?.text else {
                    return
                }
                self.sayThis(string: enteredText)
                //sendResponseToWatch(text: enteredText)
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
            //exitStateTyping()
        }
        else if action == Action.PartnerCompleted && currentState.last == State.Reading {
            currentState.popLast() //pop reading
            self.typingButton?.isHidden = true
            self.speakingButton?.isHidden = false
            self.labelTopStatus?.isHidden = false
            self.labelConvSessionInstruction?.text = "Partner has completed typing. Tap the Talk button below to speak a reply."
            self.labelConvSessionInstruction?.isHidden = false
            //currentState.append(State.Speaking)
            //enterStateSpeaking()
        }
        else if action == Action.PartnerCompleted && currentState.last == State.Listening {
            currentState.popLast() //pop listening
            self.stackViewMainAction?.isHidden = false
            self.typingButton?.isHidden = false
            self.speakingButton?.isHidden = true
            self.labelTopStatus?.isHidden = false
            self.labelConvSessionInstruction?.text = "Partner has completed speaking. Tap the Type button below to type a reply"
            self.labelConvSessionInstruction?.isHidden = false
            //currentState.append(State.Typing)
            //enterStateTyping()
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
            appendStatusConnectionLost(action: action)
            dialogSaveConversationLog()
        }
        
    }
    
    
    // MARK: UIViewController
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.conversationTableView.dataSource = self
        self.conversationTableView.delegate = self
        self.conversationTableView.rowHeight = UITableViewAutomaticDimension
        self.conversationTableView.estimatedRowHeight = 44
        
        //currentState.append(State.SubscriptionNotPaid)
        currentState.append(State.Idle) //Push
        changeState(action: Action.AppOpened)
        
        if inputAction != nil {
            if inputAction == Action.OpenedEditingModeForTyping {
                self.helpBarButtonItem?.style = .done
                self.helpBarButtonItem?.title = "Done"
            }
            else {
                self.helpBarButtonItem?.isEnabled = false //If we have an input action, help bar button should not be visible
                self.helpBarButtonItem?.tintColor = .clear
            }
            changeState(action: inputAction!)
        }
        
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
        
        //Setup bluetooth check
        cbCentralManager          = CBCentralManager()
        cbCentralManager.delegate = self
        
        //Setup watch connectivity only if it is the main screen
        if inputAction == nil {
         /*   if WCSession.isSupported() {
                let session = WCSession.default
                session.delegate = self
                session.activate()
            }   */
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
        
        let permission = checkAppleSpeechRecoginitionPermissions()
        if permission != nil {
            requestMicrophonePermission()
            requestSpeechRecognitionPermission()
        }
        
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        if self.isMovingFromParentViewController && inputAction != nil {
            //We are in editing mode and back button was tapped
            if currentState.last == State.Speaking {
                changeState(action: Action.SpeakerCancelledSpeaking)
            }
            self.speechViewControllerProtocol?.setResultOfTypingOrSpeaking(valueSent: nil, mode: nil)
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
        try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
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
                //self.textViewBottom?.textColor = .black
                if self.currentState.last != State.Reading {
                    self.textViewTop?.text = result.bestTranscription.formattedString
                    self.textViewBottom?.text = result.bestTranscription.formattedString
                }
                if /*self.currentState.contains(State.ConnectedSpeaking) &&*/ self.currentState.last == State.Speaking {
                    self.speechViewControllerProtocol?.newRealTimeInput(value: result.bestTranscription.formattedString)
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
                
                //App saying the text right after the user has said it is not necessary. Can remove this code block in future
             /*   if self.currentState.last == State.Idle {
                    if let resultText = self.textViewBottom?.text {
                        if resultText.count > 0 /*&& self.textViewBottom?.textColor == UIColor.black*/ {
                            self.sayThis(string: resultText)
                        }
                     /*   else {
                            self.sendStatusToWatch(beginningOfAction: false, success: false, text: "User did not enter response")
                        }   */
                    }
                    
                }   */
                
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
        textViewBottom.textColor = .gray
        textViewBottom.text = "You can now talk. Tap the screen when finished. Go ahead, I'm listening"
    }
    
    // MARK: State Machine Private Helpers
    private func enterStateIdle() {
        self.textViewBottom?.isHidden = true
        //self.textViewBottom?.text = "If you are hearing-impaired, you can use this app to have a conversation with someone face to face. Tap to talk, swipe up to type, or long press to start a session with another device."
    }
    
    private func enterStatePromptUserRole() {
        dialogTypingOrSpeaking()
    }
    
    private func enterStateHosting() {
        self.connectDeviceButton?.setTitle("End Session", for: .normal)
        self.connectDeviceButton?.backgroundColor = .red
        self.labelTopStatus?.text = "Started session. Ensure WiFi and bluetooth are ON for all connecting devices. Waiting for other devices to join..."
        self.labelConvSessionInstruction?.isHidden = true
        self.viewDeafProfile?.isHidden = false
        self.conversationTableView?.isHidden = true
        self.stackViewMainAction?.isHidden = true
        self.labelConnectDevice?.isHidden = true
        self.helpBarButtonItem?.isEnabled = false
        self.helpBarButtonItem?.tintColor = .clear
        
     //   self.longPressLabel?.text = "Long press to stop session"
     //   self.recordLabel?.isHidden = true
     //   self.swipeUpLabel?.isHidden = true
     //   self.helpTopicsButton?.isHidden = true
     //   self.swipeLeftLabel?.isHidden = true
        startHosting()
    }
    
    private func exitStateHosting() {
        self.connectDeviceButton?.setTitle("Connect to other device", for: .normal)
        self.connectDeviceButton?.backgroundColor = UIColor.init(red: 0.1, green: 0.4, blue: 0.2, alpha: 1.0) //dark green
        self.textViewBottom?.text = ""
        self.textViewBottom?.isHidden = true
        self.viewDeafProfile?.isHidden = true
        self.conversationTableView?.isHidden = false
        self.labelConnectDevice?.isHidden = false
        
        self.stackViewMainAction?.isHidden = false
        
        self.helpBarButtonItem?.isEnabled = true
        self.helpBarButtonItem?.tintColor = .none
        
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
    }
    
    private func exitStateBrowsingForPeers() {
        //self.textViewBottom?.text = "Session stopped"
        //self.longPressLabel?.text = "Long press to to look for other devices"
        self.recordLabel?.isHidden = true
        self.swipeUpLabel?.isHidden = true
        self.helpTopicsButton?.isHidden = true
        self.swipeLeftLabel?.isHidden = true
        self.mcNearbyServiceBrowser?.stopBrowsingForPeers()
    }
    
    private func enterStateConnectedTyping() {
        self.recordLabel?.isHidden = true
        self.swipeUpLabel?.isHidden = true
        self.helpTopicsButton?.isHidden = true
        self.swipeLeftLabel?.isHidden = true
        
        self.labelTopStatus?.isHidden = false
        self.labelConvSessionInstruction?.text = "Tap the Type button and send the first message"
        self.labelConvSessionInstruction?.isHidden = false
        self.dataChats.removeAll()
        self.dataChats.append(ChatListItem(text: "Converstion Session started. Tap the Type button below to begin the first message. You can end the conversation at any time my tapping End Session below", origin: EventOrigin.STATUS.rawValue))
        self.conversationTableView?.reloadData()
        self.scrollToBottomOfConversationTable()
        self.conversationTableView?.isHidden = false
        self.stackViewSaveChatDialog?.isHidden = true
        self.stackViewMainAction?.isHidden = false
        self.labelMainAction?.isHidden = true
        self.typingButton?.isHidden = false
        self.speakingButton?.isHidden = true
    }
    
    private func enterStateListening() {
        self.viewDeafProfile?.isHidden = false
        self.labelTopStatus?.isHidden = false
        self.labelConvSessionInstruction?.text = "Waiting for the other person to start talking..."
        self.labelConvSessionInstruction?.isHidden = false
        self.textViewRealTimeTextInput?.isHidden = true
        self.recordLabel?.isHidden = true
        self.swipeUpLabel?.isHidden = true
        self.helpTopicsButton?.isHidden = true
        self.swipeLeftLabel?.isHidden = true
        
        self.stackViewMainAction?.isHidden = true
    }
    
    private func enterStateConnectedSpeaking() {
        //self.recordLabel?.isHidden = true
        //self.swipeUpLabel?.isHidden = true
        //self.helpTopicsButton?.isHidden = true
        //self.swipeLeftLabel?.isHidden = true
        
        self.dataChats.removeAll()
        self.dataChats.append(ChatListItem(text: "Converstion Session started. Your partner will start the conversation. When they have finished, their message will appear here. Please wait.", origin: EventOrigin.STATUS.rawValue))
        self.conversationTableView.reloadData()
        self.scrollToBottomOfConversationTable()
        self.conversationTableView.isHidden = false
        self.labelTopStatus?.isHidden = false
        self.labelConvSessionInstruction?.text = "Waiting for the other person to start typing..."
        self.labelConvSessionInstruction?.isHidden = false
        self.textViewRealTimeTextInput?.isHidden = true
        self.labelMainAction?.isHidden = true
        self.typingButton?.isHidden = true
        self.speakingButton?.isHidden = false
        
        self.labelConnectDevice?.isHidden = true
        self.connectDeviceButton?.setTitle("End Session", for: .normal)
        self.connectDeviceButton?.backgroundColor = .red
        self.connectDeviceButton?.isHidden = false
    }
    
    private func enterStateReading() {
        self.viewDeafProfile?.isHidden = false
        self.labelTopStatus?.isHidden = false
        self.labelConvSessionInstruction?.text = "Waiting for the other person to start typing..."
        self.labelConvSessionInstruction?.isHidden = false
        self.textViewRealTimeTextInput?.isHidden = true
        
        self.speakingButton?.isHidden = true
        //self.recordLabel?.isHidden = true
        //self.swipeUpLabel?.isHidden = true
        //self.helpTopicsButton?.isHidden = true
        //self.swipeLeftLabel?.isHidden = true
    }
    
    private func enterStateEditingMode(editingType : EditingType) {
        //If inputAction is nil, we are at part 1: pushing the view controller
        guard let storyBoard : UIStoryboard = self.storyboard else {
            return
        }
        let speechViewController = storyBoard.instantiateViewController(withIdentifier: "SpeechViewController") as! SpeechViewController
        if editingType == EditingType.Typing {
            speechViewController.inputAction = Action.OpenedEditingModeForTyping
        }
        else if editingType == EditingType.Speaking {
            speechViewController.inputAction = Action.OpenedEditingModeForSpeaking
        }
        speechViewController.speechViewControllerProtocol = self as? SpeechViewControllerProtocol
        if let navigationController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController {
            navigationController.pushViewController(speechViewController, animated: true)
        }
    }
    
    private func exitStateEditingMode(isSuccessful: Bool) {
        self.textViewRealTimeTextInput?.isHidden = true
        
        if isSuccessful {
            self.labelTopStatus?.isHidden = false
            self.labelTopStatus?.text = "This person is deaf/hearing-impaired. Please answer their doubts by using the Type or Talk options at the bottom of the screen"
            self.stackViewSaveChatButton?.isHidden = false
            self.buttonClearChatLog?.isHidden = false
        }
    }
    
    private func enterStateTyping() {
        //Checking for input action
        //Typing mode is always in a separate view controller
        if inputAction == Action.OpenedEditingModeForTyping {
            self.recordLabel?.isHidden = true
            self.swipeUpLabel?.isHidden = true
            self.helpTopicsButton?.isHidden = true
            self.swipeLeftLabel?.isHidden = true
            
            self.textViewBottom?.isHidden = false
            self.conversationTableView?.isHidden = true
            self.stackViewBottomActions?.isHidden = true
            
            //inputAction already has a value means new view controller already pushed
            self.textViewBottom.textColor = UIColor.gray
            self.textViewBottom?.text = "You can now start typing. Tap the screen or tap enter when done..."
            textViewBottom?.isEditable = true
            textViewBottom?.becomeFirstResponder()
        }
    }
    
    private func exitStateTyping() {
        textViewBottom?.isEditable = false
        textViewBottom?.resignFirstResponder()
        if currentState.last == State.TypingStarted {
            let trimmedString = textViewBottom.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedString.count > 0 {
                speechViewControllerProtocol?.setResultOfTypingOrSpeaking(valueSent: trimmedString, mode: "typing")
            }
        }
        else {
            speechViewControllerProtocol?.setResultOfTypingOrSpeaking(valueSent: nil, mode: nil)
        }
        self.navigationController?.popViewController(animated: true)
    }
    
    private func enterStateReceivingFromWatch() {
        //When coming from the watch
        //Use this to update the UI instantaneously (otherwise, takes a little while)
        DispatchQueue.main.async(execute: { () -> Void in
          /*  self.helpTopicsButton?.isHidden = true
            self.swipeLeftLabel?.isHidden = true
            self.swipeUpLabel?.isHidden = true
            self.recordLabel?.isHidden = true
            self.connectDeviceButton?.isHidden = false
            self.longPressLabel?.isHidden = false
            self.longPressLabel?.text = "Long press to stop"    */
            self.viewDeafProfile?.isHidden = false
            self.labelTopStatus?.text = "User is typing on Apple Watch..."
            self.labelTopStatus?.isHidden = false
            self.labelConvSessionInstruction?.isHidden = true
            self.stackViewMainAction?.isHidden = true
            self.stackViewSaveChatDialog?.isHidden = true
            self.labelConnectDevice?.isHidden = true
            self.connectDeviceButton?.setTitle("Stop receiving from watch", for: .normal)
            self.connectDeviceButton?.backgroundColor = .red
            self.connectDeviceButton?.isHidden = false
            self.stackViewConnectDevice?.isHidden = false
        })
        
    }
    
    private func exitStateReceivingFromWatch() {
        //When coming from the watch
        //Use this to update the UI instantaneously (otherwise, takes a little while)
        DispatchQueue.main.async(execute: { () -> Void in
            //labelTopStatus is set in WatchDelegate
            self.stackViewMainAction?.isHidden = false
            self.stackViewConnectDevice?.isHidden = true
            
            //self.labelConnectDevice?.isHidden = false
            //self.connectDeviceButton?.setTitle("Connect to other device", for: .normal)
            //self.connectDeviceButton?.backgroundColor = UIColor.init(red: 0.1, green: 0.4, blue: 0.2, alpha: 1.0) //dark green
            //self.connectDeviceButton?.isHidden = false
        })
    }
    
    private func enterStateChatsReadAndShareOnly() {
        self.title = ""
        viewDeafProfile?.isHidden = false
        labelTopStatus?.text = "We do not store any chat logs. All logs are deleted when the app is closed"
        conversationTableView?.isHidden = false
        typingButton?.isHidden = true
        speakingButton?.isHidden = true
        if dataChats.count > 0 {
            stackViewSaveChatButton?.isHidden = false
            buttonClearChatLog?.isHidden = false
            conversationTableView.reloadData()
            scrollToBottomOfConversationTable()
        }
        else {
            stackViewSaveChatButton?.isHidden = true
            buttonClearChatLog?.isHidden = true
        }
        
    }
    
    private func enterStateSpeaking() {
        if hasInternetConnection() {
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate)) //vibration ONLY if not receiving
            try! startRecording()
            runTimer()
            recordButton?.setTitle("Stop recording", for: [])
            recordLabel?.text = "TAP SCREEN TO STOP RECORDING"
            recordLabel?.isHidden = false
            swipeUpLabel?.isHidden = true
            typingButton?.isHidden = true
            speakingButton?.isHidden = true
            helpTopicsButton?.isHidden = true
            swipeLeftLabel?.isHidden = true
            connectDeviceButton?.isHidden = true
            longPressLabel?.isHidden = true
            
            tapGestureRecognizer?.isEnabled = true
            stackViewBottomActions?.isHidden = true
            conversationTableView?.isHidden = true
            textViewBottom?.isHidden = false
        }
        else {
            dialogOK(title: "Alert", message: "No internet connection")
        }
    }
    
    private func exitStateSpeaking() {
        //Adding the text to the chat log
        if currentState.last == State.Speaking {
            let trimmedString = textViewBottom.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedString.count > 0 {
                speechViewControllerProtocol?.setResultOfTypingOrSpeaking(valueSent: trimmedString, mode: "talking")
            }
        }
        else {
            speechViewControllerProtocol?.setResultOfTypingOrSpeaking(valueSent: nil, mode: nil)
        }
        self.navigationController?.popViewController(animated: true)
        /////
        
        if audioEngine.isRunning {
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate)) //vibration to indicate end of recording
            audioEngine.stop()
            recognitionRequest?.endAudio()
            resetTimer()
            textViewTop?.text = ""
            textViewBottom.textColor = .gray
            textViewBottom.text = ""
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
        self.helpTopicsButton?.isHidden = false
        self.swipeLeftLabel?.isHidden = false
        self.dismiss(animated: true)
        
        self.labelMainAction?.isHidden = false
        self.typingButton?.isHidden = false
        self.speakingButton?.isHidden = true
    }
    
    
    
    func typistDeletedAllText() {
        if currentState.contains(State.ConnectedSpeaking) {
            self.labelTopStatus?.isHidden = false
            self.labelConvSessionInstruction?.isHidden = false
            self.textViewRealTimeTextInput?.text = ""
            self.textViewRealTimeTextInput?.isHidden = true
        }
        else {
            self.labelTopStatus?.isHidden = false
            self.labelConvSessionInstruction?.isHidden = true
            self.textViewRealTimeTextInput?.isHidden = true
        }
    }
    
    func speakerCancelledSpeaking() {
        //Only applicable in multipeer session
        self.labelTopStatus?.isHidden = false
        self.labelConvSessionInstruction?.isHidden = false
        self.textViewRealTimeTextInput?.text = ""
        self.textViewRealTimeTextInput?.isHidden = true
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
    
    func didReceiveMessageFromOtherDevice() {
        //Unhide all UI that interacts with a chat log
        self.labelTopStatus?.isHidden = false
        self.labelTopStatus?.text = "This person is deaf/hearing-impaired. Please answer their doubts by using the Type or Talk options at the bottom of the screen"
        self.stackViewSaveChatButton?.isHidden = false
        self.buttonClearChatLog?.isHidden = false
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
    
    func appendStatusConnectionLost(action : Action) {
        if action == Action.PartnerEndedSession {
            self.dataChats.append(ChatListItem(text: "Your partner ended the session.", origin: EventOrigin.STATUS.rawValue))
        }
        else {
            self.dataChats.append(ChatListItem(text: "Connection Lost. Conversation Session Complete.", origin: EventOrigin.STATUS.rawValue))
        }
        
        self.conversationTableView?.reloadData()
        self.scrollToBottomOfConversationTable()
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
    
    func dialogSaveConversationLog() {
        self.stackViewSaveChatDialog?.isHidden = false
        self.stackViewMainAction?.isHidden = true
        self.stackViewConnectDevice?.isHidden = true
    }
    
    func saveChatLog() {
        let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
        let dateFormatter : DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MMMM-dd h:mm a"
        let date = Date()
        let dateString = dateFormatter.string(from: date)
        var stringToSave = appName + " " + "Session" + " " + dateString + "\n\n"
        for chatListItem in dataChats {
            stringToSave.append(chatListItem.time)
            stringToSave.append("   ")
            stringToSave.append(chatListItem.origin)
            stringToSave.append("\n")
            stringToSave.append(chatListItem.text)
            stringToSave.append("\n\n")
        }
        
        let vc = UIActivityViewController(activityItems: [stringToSave], applicationActivities: [])
        present(vc, animated: true, completion: nil)
        vc.completionWithItemsHandler = { (activityType, completed:Bool, returnedItems:[Any]?, error: Error?) in
            if !completed {
                Analytics.logEvent("se3_save_chat_cancelled", parameters: [:])
            }
        }
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
}

extension SpeechViewController : SFSpeechRecognizerDelegate {
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
}

extension SpeechViewController : MCSessionDelegate {
    public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case MCSessionState.connected:
            DispatchQueue.main.async { [unowned self] in
                self.viewDeafProfile?.isHidden = false
                self.labelTopStatus?.text = "Connected: \(peerID.displayName)"
                //self.longPressLabel?.text = "Connected: \(peerID.displayName)" + "\n" + "Long press to disconnect"
                self.changeState(action: Action.ReceivedConnection)
            }
            
        case MCSessionState.connecting:
            DispatchQueue.main.async { [unowned self] in
                self.viewDeafProfile?.isHidden = false
                self.labelTopStatus?.text = "Connecting: \(peerID.displayName)"
                //self.longPressLabel?.text = "Connecting: \(peerID.displayName)"
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
                    if self.currentState.last == State.Reading {
                        self.changeState(action: Action.TypistDeletedAllText)
                    }
                    else if self.currentState.last == State.Listening {
                        self.changeState(action: Action.SpeakerCancelledSpeaking)
                    }
                }
                else if text.count > 1 && text.last! == "\n" {
                    let textWithoutNewLine = String(text.prefix(text.count - 1)) //This will remove the \n. The \n was only meant to signify end of message. Now that we have the message on the other side we can display it without \n.
                    self.dataChats.append(ChatListItem(text: textWithoutNewLine, origin: peerID.displayName))
                    self.conversationTableView.reloadData()
                    self.scrollToBottomOfConversationTable()
                    self.didReceiveMessageFromOtherDevice()
                    self.textViewRealTimeTextInput?.text = ""
                    self.changeState(action: Action.PartnerCompleted)
                }
                else if self.currentState.last == State.Listening || self.currentState.last == State.Reading {
                    self.labelTopStatus?.isHidden = true
                    self.labelConvSessionInstruction?.isHidden = true
                    self.textViewRealTimeTextInput?.isHidden = false
                    self.textViewRealTimeTextInput?.text = text
                    
                    let location = self.textViewRealTimeTextInput.text.count - 1
                    let bottom = NSMakeRange(location, 1)
                    self.textViewRealTimeTextInput.scrollRangeToVisible(bottom)
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

extension SpeechViewController : MCBrowserViewControllerDelegate {
    public func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    public func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
        changeState(action: Action.BrowserCancelled)
    }
}

extension SpeechViewController : MCNearbyServiceBrowserDelegate {
    public func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        dialogNewConnection(title: "New device found", message: "Found device with name: \(peerID.displayName). Would you like to connect to it?", peerId: peerID)
    }
    
    public func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        self.textViewBottom?.text = "Looking for a device to connect to."
    }
}

extension SpeechViewController : UITextViewDelegate {
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
            //self.textViewBottom?.textColor = .black
            self.textViewBottom?.text = str
            sendText(text: str)
            self.speechViewControllerProtocol?.newRealTimeInput(value: str)
            return
        }
        
        if str.isEmpty {
            //User deleted all the text
            changeState(action: Action.TypistDeletedAllText)
            sendText(text: "\0")
            self.speechViewControllerProtocol?.newRealTimeInput(value: "\0")
            return
        }
        
        sendText(text: str)
        self.speechViewControllerProtocol?.newRealTimeInput(value: str)
        
    }
}


extension SpeechViewController : CBCentralManagerDelegate {
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


extension SpeechViewController : WCSessionDelegate {
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
            "current_state": currentState.last?.rawValue,
            "message": (message["request"] as? String)?.prefix(100) as Any
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
                            self.labelTopStatus?.text = watchStatus
                            //self.textViewBottom?.text = watchStatus
                        }
                    })
                }
            }
            changeState(action: Action.ReceivedStatusFromWatch)
        }
        else if let cancalledTyping = message["user_cancelled_typing"] as? String {
            response = cancalledTyping //Used only for analytics
            changeState(action: Action.ReceivedStatusFromWatch)
            
            self.viewDeafProfile?.isHidden = false
            self.labelTopStatus?.text = ""
            self.labelTopStatus?.isHidden = false
        }
        else if let request = message["request"] as? String {
            if currentState.last == State.ReceivingFromWatch {
                // foreground
                //Use this to update the UI instantaneously (otherwise, takes a little while)
                DispatchQueue.main.async(execute: { () -> Void in
                    if UIApplication.shared.applicationState == .active {
                        self.dataChats.append(ChatListItem(text: request, origin: "Apple Watch"))
                        self.conversationTableView?.reloadData()
                        self.scrollToBottomOfConversationTable()
                        self.didReceiveMessageFromOtherDevice()
                        self.sayThis(string: request)
                        
                        self.viewDeafProfile?.isHidden = false
                        self.labelTopStatus?.text = "This person is deaf/hearing-impaired. Please answer their doubts by using the Type or Talk options at the bottom of the screen"
                        self.labelTopStatus?.isHidden = false
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
            else if currentState.last == State.Typing ||
                    currentState.last == State.EditingMode {
                status = false
                response = "User is typing on iPhone. Message not displayed"
            }
            
            
        }
        
        replyHandler(["status": status, "response":response])
    }
}

extension SpeechViewController : UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        var numOfSections: Int = 1
        if dataChats.count > 0 {
            tableView.separatorStyle = .none //.singleLine
            numOfSections            = 1
            tableView.backgroundView = nil
        }
        else {
            if emptyTableText == nil {
                emptyTableText = "No conversation in progress"
            }
            
            let noDataLabel: UILabel  = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
            noDataLabel.text          = emptyTableText
            noDataLabel.textAlignment = .center
            noDataLabel.numberOfLines = 5
            noDataLabel.lineBreakMode = .byWordWrapping
            tableView.backgroundView  = noDataLabel
            tableView.separatorStyle  = .none
        }
        return numOfSections
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataChats.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let chatListItem : ChatListItem = dataChats[indexPath.row]
        
        //Option 1: Status of chat
        //Option 2: Message from host phone
        //Option 3: Message from another device
        let cell : ConversationTableViewCell =
            (chatListItem.origin == EventOrigin.STATUS.rawValue) ?
                tableView.dequeueReusableCell(withIdentifier: "conversationTableViewCellStatus") as! ConversationTableViewCell :
            (chatListItem.mode == "typing") ?
                    tableView.dequeueReusableCell(withIdentifier: "conversationTableViewCell") as! ConversationTableViewCell :
                tableView.dequeueReusableCell(withIdentifier: "conversationTableViewCellGuest") as! ConversationTableViewCell
                
          /*  (chatListItem.origin == peerID.displayName) ?
                tableView.dequeueReusableCell(withIdentifier: "conversationTableViewCell") as! ConversationTableViewCell :
                tableView.dequeueReusableCell(withIdentifier: "conversationTableViewCellGuest") as! ConversationTableViewCell   */
    
        cell.textViewLabel?.text = chatListItem.text
        cell.timeLabel?.text = chatListItem.time
        cell.messageOriginLabel?.text = chatListItem.origin
        cell.delegate = self
        cell.indexPath = indexPath
        
        return cell 
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
}

extension SpeechViewController : UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //We do not want to trigger logic when the user taps on whitespace outside the chat bubble
        //We only detect clicks inside the chat bubble.
        //Solution is in ChatBubbleDelegate
    }
    
    private func sayThis(string: String) {
        let audioSession = AVAudioSession.sharedInstance()
        do { try audioSession.setCategory(AVAudioSessionCategoryPlayback) }
        catch { showToast(message: "Sorry, audio failed to play") }
        do { try audioSession.setMode(AVAudioSessionModeDefault) }
        catch { showToast(message: "Sorry, audio failed to play") }
        
        let utterance = AVSpeechUtterance(string: string)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
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
    
    func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission({ (granted) in
            // Handle granted
            
        })
    }
    
    func checkAppleSpeechRecoginitionPermissions() -> String? {
        if hasInternetConnection() == false {
            return "internet"
        }
        if AVAudioSession.sharedInstance().recordPermission() != AVAudioSession.RecordPermission.granted {
            self.speakingButton?.backgroundColor = UIColor.gray
            return "mic"
        }
        if SFSpeechRecognizer.authorizationStatus() != .authorized {
            self.speakingButton?.backgroundColor = UIColor.gray
            return "not_authorized"
        }
        
        self.speakingButton?.backgroundColor = UIColor.blue
        return nil
    }
    
    
    func requestSpeechRecognitionPermission() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            /*
             The callback may not be called on the main thread. Add an
             operation to the main queue to update the record button's state.
             */
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    self.speakingButton?.backgroundColor = UIColor.blue
                    self.recordButton?.isEnabled = true
                case .denied:
                    self.speakingButton?.backgroundColor = UIColor.gray
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
}

extension SpeechViewController : ChatBubbleDelegate {
    
    func conversationBubbleTapped(at indexPath: IndexPath) {
        let chatListItem : ChatListItem = dataChats[indexPath.row]
        Analytics.logEvent("se3_row_selected", parameters: [
            "os_version": UIDevice.current.systemVersion,
            "device_type": getDeviceType(),
            "origin": chatListItem.origin == EventOrigin.STATUS.rawValue ?
                chatListItem.origin :
                chatListItem.origin == peerID.displayName ?
                    "host" :
                chatListItem.origin == EventOrigin.WATCH.rawValue ?
                    chatListItem.origin :
            "other"
            ])
        
        //Volume check is not done in 'sayThis' because it should not be done when the user has just enetered new text. Loading the dialog on the UI thread breaks the flow of returning to the main screen, which we do not want. Hence this is done only when the user selects a chat bubble
        let audioSession = AVAudioSession.sharedInstance()
        let volume = audioSession.outputVolume
        if volume < 0.5 {
            self.dialogOK(title: "Warning", message: "Your volume is low. You may not be able to hear audio. Please increase the volume")
        }
        self.sayThis(string: chatListItem.text)
    }
    
    
}


///Protocol
protocol SpeechViewControllerProtocol {
    func setResultOfTypingOrSpeaking(valueSent: String?, mode: String?)
    func newRealTimeInput(value : String)
}

extension SpeechViewController : SpeechViewControllerProtocol {
    func setResultOfTypingOrSpeaking(valueSent: String?, mode: String?) {
        guard var newText : String = valueSent else {
            self.sendText(text: "\0")
            changeState(action: Action.CancelledEditing)
            self.sendStatusToWatch(beginningOfAction: false, success: false, text: "User did not enter response")
            return
        }
        if newText.last == "\n" {
            //Typing mode can put a newline on the end
            newText.removeLast()
        }
        
        self.sendText(text: newText + "\n")
        self.sayThis(string: newText)
        self.dataChats.append(ChatListItem(text: newText, origin: peerID.displayName, mode: mode))
        self.conversationTableView.reloadData()
        self.scrollToBottomOfConversationTable()
        self.viewDeafProfile?.isHidden = false
        self.textViewRealTimeTextInput?.text = ""
        self.sendResponseToWatch(text: valueSent!)
        changeState(action: Action.CompletedEditing)
    }
    
    func newRealTimeInput(value: String) {
        sendText(text: value)
        self.textViewRealTimeTextInput?.text = value
    }
    
    func scrollToBottomOfConversationTable() {
        //scroll to bottom
        let indexPath = NSIndexPath(row: dataChats.count-1, section: 0)
        conversationTableView.scrollToRow(at: indexPath as IndexPath, at: .bottom, animated: true)
    }
}

