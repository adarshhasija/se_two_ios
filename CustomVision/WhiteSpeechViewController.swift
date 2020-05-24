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
import CoreHaptics

public class WhiteSpeechViewController: UIViewController {

    // MARK: Properties
    let synth = AVSpeechSynthesizer()
    var hapticManager : HapticManager?
    lazy var supportsHaptics: Bool = {
        return (UIApplication.shared.delegate as? AppDelegate)?.supportsHaptics ?? false
    }()
    var morseCode = MorseCode()
    let networkManager = NetworkManager.sharedInstance
    var currentState: [State] = []
    var seconds = 60
    var timer = Timer()
    var isTimerRunning = false
    private var dataChats: [ChatListItem] = []
    var speechToTextInstructionString = "Tap the talk button to record speech"
    var setupInstructionString = "Please declare your ailment. Tap the card above"
    var typingInstructionString = "Tap the type button to begin"
    var longPressMorseCodeInstructionString = "Long press to begin typing in morse code"
    var composerButtonsUseInstructions = "I need your help\nPlease read the message in bold\nUse the button below to reply"
    var showMorseCodeInstruction = "Tap with 2 fingers to show morse code"
    var hiSIContextString = "This person cannot hear or speak. Please help them"
    var tapToRepeat = "Tap to repeat"
    var lastActionTypingDeaf = "Typed by hearing-impaired"
    var lastActionSpeaking = "Spoken by non-hearing-impaired"
    var indicesOfPipes : [Int] = [] //This is needed when highlighting morse code when the user taps on the screen to play audio
    var englishStringIndex = -1
    var morseCodeStringIndex = -1
    
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
    @IBOutlet weak var mainTextViewAndMorseCodeLabelStackView: UIStackView!
    @IBOutlet var textViewBottom : UITextView!
    @IBOutlet weak var morseCodeLabel: UILabel!
    @IBOutlet weak var englishMorseCodeTextLabel: UILabel!
    @IBOutlet weak var mcReadInstructionLabel: UILabel!
    @IBOutlet weak var timerStackView: UIStackView!
    @IBOutlet weak var viewForTypeTalkStackView: UIView!
    @IBOutlet weak var composerStackView: UIStackView!
    @IBOutlet weak var composerButtonsStackView: UIStackView!
    
    
    // Bottom nav stack
    @IBOutlet weak var navStackView: UIStackView!
    @IBOutlet weak var bottomLeftImageView: UIImageView!
    @IBOutlet weak var bottomMiddleImageView: UIImageView!
    
    @IBOutlet weak var bottomMiddleChevronUpImageView: UIImageView!
    @IBOutlet weak var chatLogBtn: UIImageView!
    //
    
    
    @IBOutlet weak var cameraOriginImageView: UIImageView!
    @IBOutlet var recordButton : UIButton?
    @IBOutlet weak var longPressLabel: UILabel?   
    @IBOutlet weak var noInternetImageView: UIImageView!
    @IBOutlet weak var errorCoreHapticsLabel: UILabel!
    @IBOutlet weak var recordLabel: UILabel?
    @IBOutlet weak var timerLabel: UILabel?
    @IBOutlet weak var swipeUpLabel: UILabel!
    @IBOutlet weak var swipeLeftLabel: UILabel!
    @IBOutlet weak var disabledContextLabel: UILabel!
    
    //User profile view
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userAilmentLabel: UILabel!
    @IBOutlet weak var userStatusLabel: UILabel!
    ///
    
    // MARK: Interface Builder actions
    
    
    
    @IBAction func userProfileTapped(_ sender: Any) {
        guard let storyBoard : UIStoryboard = self.storyboard else {
            return
        }
        let userProfileController = storyBoard.instantiateViewController(withIdentifier: "UserProfile") as! UserProfileTableViewController
        userProfileController.whiteSpeechViewControllerProtocol = self as WhiteSpeechViewControllerProtocol
        userProfileController.peerIDName = peerID.displayName
        if let navigationController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController {
            navigationController.pushViewController(userProfileController, animated: true)
        }
    }
    
    @IBAction func helpBarButtonItemTapped(_ sender: Any) {
        changeState(action: Action.BarButtonHelpTapped)
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
    
    @IBAction func settingsButtonTapped(_ sender: Any) {
        changeState(action: Action.SettingsButtonTapped)
    }
    
    
    @IBAction func bottomMiddleButtonTapped(_ sender: Any) {
        self.view.transform = CGAffineTransform(translationX: 0, y: 100)
        UIView.animate(withDuration: 1.0, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.5, options: UIView.AnimationOptions.curveLinear, animations: ({
            self.view.transform = .identity
        }), completion: nil)
        self.view.transform = CGAffineTransform(translationX: 0, y: -100)
        UIView.animate(withDuration: 1.0, delay: 0.8, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.5, options: UIView.AnimationOptions.curveEaseOut, animations: ({
            self.view.transform = .identity
        }), completion: nil)
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
        
        // Play haptic here.
     /*   do {
            // Start the engine if necessary.
            if engineNeedsStart {
                try chHapticEngine?.start()
                engineNeedsStart = false
            }

            // Create a haptic pattern player from normalized magnitude.
            let hapticPlayer = try hapticForResult(success: true)

            // Start player, fire and forget
            try hapticPlayer?.start(atTime: CHHapticTimeImmediate)
        } catch let error {
            print("Haptic Playback Error: \(error)")
        }   */
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
        else if sender.direction == UISwipeGestureRecognizerDirection.left {
            changeState(action: Action.SwipeLeft)
        }
        else if sender.direction == UISwipeGestureRecognizerDirection.right {
            changeState(action: Action.SwipeRight)
        }
    }
    
    
    @IBAction func swipeGestureDouble(_ sender: UISwipeGestureRecognizer) {
        if sender.direction == UISwipeGestureRecognizerDirection.left {
            Analytics.logEvent("se3_2f_left_swipe", parameters: [:])
            morseCodeStringIndex -= 1
            changeState(action: Action.SwipeLeft2Finger)
        }
        else if sender.direction == UISwipeGestureRecognizerDirection.right {
            Analytics.logEvent("se3_2f_right_swipe", parameters: [:])
            morseCodeStringIndex += 1
            changeState(action: Action.SwipeRight2Finger)
        }
    }
    
    
    @IBAction func tap2Fingers(_ sender: Any) {
        Analytics.logEvent("se3_2f_tap", parameters: [:])
        morseCodeLabel?.isHidden = false
        mcReadInstructionLabel?.text = "Swipe right with 2 fingers to read morse code"
        mcReadInstructionLabel?.isHidden = false
        //try? hapticManager?.hapticForResult(success: true)
        hapticManager?.generateHaptic(code: hapticManager?.RESULT_SUCCESS)
    }
    
    
    @IBAction func typeButtonTapped(_ sender: Any) {
        Analytics.logEvent("se3_type_btn_tap", parameters: [:])
        changeState(action: Action.SwipeUp)
    }
    
    
    @IBAction func talkButtonTapped(_ sender: Any) {
        Analytics.logEvent("se3_talk_btn_tap", parameters: [:])
        changeState(action: Action.TalkButtonTapped)
    }
    
    
    @IBAction func centerBigButtunTapped(_ sender: Any) {
        Analytics.logEvent("se3_center_btn_tap", parameters: [:])
        currentState.append(State.EditingMode)
        let maxLength = 35
        let alert = UIAlertController(title: englishMorseCodeTextLabel?.text, message: "Character limit for reply: " + String(maxLength), preferredStyle: .alert)

        //2. Add the text field. You can configure it however you need.
        alert.addTextField { (textField) in
            textField.placeholder = "Your Reply"
            textField.maxLength = maxLength
        }

        // 3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            if textField?.text?.isEmpty == false {
                self.setTypedMessage(english: textField!.text!)
            }
            //print("Text field: \(textField.text)")
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak alert] (_) in
            self.changeState(action: Action.CancelledEditing)
            alert?.dismiss(animated: true, completion: nil)
        }))

        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
    }
    
    
    @IBAction func mcButtonTapped(_ sender: Any) {
        Analytics.logEvent("se3_mc_btn_tap", parameters: [:])
        changeState(action: Action.LongPress)
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
        else if action == Action.UserProfileChanged && currentState.last == State.Idle {
            enterStateControllerLoaded() //Clear chat logs and reset after user profile changed
        }
        else if action == Action.SettingsButtonTapped && currentState.last == State.Idle {
            openSettingsScreen()
        }
        else if action == Action.UserProfileButtonTapped && currentState.last == State.Idle {
            Analytics.logEvent("se3_uprofile_tap", parameters: [:])
        }
        else if action == Action.Tap && currentState.last == State.Idle {
            if englishMorseCodeTextLabel.text?.isEmpty == false {
                sayThis(string: englishMorseCodeTextLabel.text!)
            }
            else {
                //No text to highlight
                //Shake the recordLabel to indidate the next action to the user
                self.recordLabel?.transform = CGAffineTransform(translationX: 20, y: 0)
                UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.2, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
                    self.recordLabel?.transform = CGAffineTransform.identity
                }, completion: nil)
            }
        }
        else if action == Action.CompletedEditing && currentState.last == State.EditingMode {
            currentState.popLast()
            //try? hapticManager?.hapticForResult(success: true)
            hapticManager?.generateHaptic(code: hapticManager?.RESULT_SUCCESS)
        }
        else if action == Action.CancelledEditing && currentState.last == State.EditingMode {
            currentState.popLast()
            //try? hapticManager?.hapticForResult(success: false)
            hapticManager?.generateHaptic(code: hapticManager?.RESULT_FAILURE)
        }
        else if action == Action.SwipeRight && currentState.last == State.Idle {
            let se3UserType = UserDefaults.standard.string(forKey: "SE3_IOS_USER_TYPE")
            if se3UserType == "_3" {
                //Deaf-blind
                textViewBottom?.text += "-"
            }
        }
        else if action == Action.LongPress && currentState.last == State.Idle {
            currentState.append(State.EditingMode)
            openMorseCodeEditor()
        }
        else if action == Action.TalkButtonTapped && currentState.last == State.Idle {
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
                //currentState.append(State.Speaking)
                currentState.append(State.EditingMode)
                enterStateSpeaking()
            }
        }
        else if action == Action.SwipeRight2Finger && currentState.last == State.Idle {
            actionSwipeRightDouble()
        }
        else if action == Action.SwipeLeft2Finger && currentState.last == State.Idle {
            actionSwipeLeftDouble()
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
            //sendStatusToWatch(beginningOfAction: true, success: true, text: "User is typing on iPhone. Please wait. Tell them to tap screen when done.")
            //currentState.append(State.Typing)
            //currentState.append(State.EditingMode)
            //enterStateTyping()
            openCameraForBlind()
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

        hapticManager = HapticManager(supportsHaptics: supportsHaptics)
        //createAndStartHapticEngine()
        
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
     /*   if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }   */
        
        //currentState.append(State.SubscriptionNotPaid)
        currentState.append(State.ControllerLoaded) //Push
        changeState(action: Action.AppOpened)

        
    }
    
    private func actionSwipeLeftDouble() {
        if supportsHaptics == false { errorCoreHapticsLabel?.isHidden = false }
        else { errorCoreHapticsLabel?.isHidden = true }
        
        let morseCodeString = morseCodeLabel.text ?? ""
        var englishString = englishMorseCodeTextLabel.text ?? ""
        if morseCodeStringIndex < 0 {
                Analytics.logEvent("se3_morse_scroll_left", parameters: [
                    "state" : "index_less_0"
                ])
                //try? hapticManager?.hapticForResult(success: false)
                hapticManager?.generateHaptic(code: hapticManager?.RESULT_FAILURE)
               
               mcReadInstructionLabel?.text = "Swipe right with 2 fingers to read morse code"
               if morseCodeStringIndex < 0 {
                   morseCodeLabel.text = morseCodeString //If there is still anything highlighted green, remove the highlight and return everything to default color
                   englishStringIndex = -1
                   englishMorseCodeTextLabel.text = englishString
               }
               morseCodeStringIndex = -1 //If the index has gone behind the string by some distance, bring it back to -1
               return
           }

            Analytics.logEvent("se3_morse_scroll_left", parameters: [
                "state" : "scrolling"
            ])
           mcReadInstructionLabel?.text = "Swipe left with 2 fingers to go back"
           MorseCodeUtils.setSelectedCharInLabel(inputString: morseCodeString, index: morseCodeStringIndex, label: morseCodeLabel, isMorseCode: true, color : UIColor.blue)
           hapticManager?.playSelectedCharacterHaptic(inputString: morseCodeString, inputIndex: morseCodeStringIndex) // TODO: Find out which call is the right call
             //hapticManager?.generateHaptic(code: String(morseCodeString[morseCodeString.index(morseCodeString.startIndex, offsetBy: morseCodeStringIndex)]) == "." ? hapticManager?.MC_DOT : hapticManager?.MC_DASH)
           
           if MorseCodeUtils.isPrevMCCharPipe(input: morseCodeString, currentIndex: morseCodeStringIndex, isReverse: true) {
               //Need to change the selected character of the English string
               englishStringIndex -= 1
                Analytics.logEvent("se3_morse_scroll_left", parameters: [
                    "state" : "index_alpha_change"
                ])
               //FIrst check that the index is within bounds. Else isEngCharSpace() will crash
               if englishStringIndex > -1 && MorseCodeUtils.isEngCharSpace(englishString: englishString, englishStringIndex: englishStringIndex) {
                   let start = englishString.index(englishString.startIndex, offsetBy: englishStringIndex)
                   let end = englishString.index(englishString.startIndex, offsetBy: englishStringIndex + 1)
                   englishString.replaceSubrange(start..<end, with: "␣")
               }
               else {
                   englishString = englishString.replacingOccurrences(of: "␣", with: " ")
               }
               
               if englishStringIndex > -1 {
                   //Ensure that the index is within bounds
                   MorseCodeUtils.setSelectedCharInLabel(inputString: englishString, index: englishStringIndex, label: englishMorseCodeTextLabel, isMorseCode: false, color: UIColor.blue)
               }
               
           }
    }
    
    private func actionSwipeRightDouble() {
        if supportsHaptics == false { errorCoreHapticsLabel?.isHidden = false }
        else { errorCoreHapticsLabel?.isHidden = true }
        let morseCodeString = morseCodeLabel.text ?? ""
        var englishString = englishMorseCodeTextLabel.text ?? ""
        if morseCodeStringIndex >= morseCodeString.count {
            Analytics.logEvent("se3_morse_scroll_right", parameters: [
                "state" : "index_greater_equal_0"
            ])
            mcReadInstructionLabel?.text = "Swipe left with 2 fingers to go back"
            morseCodeLabel.text = morseCodeString //If there is still anything highlighted green, remove the highlight and return everything to default color
            englishMorseCodeTextLabel.text = englishString
            //WKInterfaceDevice.current().play(.success)
            morseCodeStringIndex = morseCodeString.count //If the index has overshot the string length by some distance, bring it back to string length
            englishStringIndex = englishString.count
            return
        }
        mcReadInstructionLabel?.text = "Swipe right with 2 fingers to read morse code"
        MorseCodeUtils.setSelectedCharInLabel(inputString: morseCodeString, index: morseCodeStringIndex, label: morseCodeLabel, isMorseCode: true, color: UIColor.blue)
        hapticManager?.playSelectedCharacterHaptic(inputString: morseCodeString, inputIndex: morseCodeStringIndex)  // TODO: Still need to see which version is the right version
        //hapticManager?.generateHaptic(code: String(morseCodeString[morseCodeString.index(morseCodeString.startIndex, offsetBy: morseCodeStringIndex)]) == "." ? hapticManager?.MC_DOT : hapticManager?.MC_DASH)
        
        if MorseCodeUtils.isPrevMCCharPipe(input: morseCodeString, currentIndex: morseCodeStringIndex, isReverse: false) || englishStringIndex == -1 {
            //Need to change the selected character of the English string
            englishStringIndex += 1
            if englishStringIndex >= englishString.count {
                //WKInterfaceDevice.current().play(.failure)
                return
            }
            if MorseCodeUtils.isEngCharSpace(englishString: englishString, englishStringIndex: englishStringIndex) {
                let start = englishString.index(englishString.startIndex, offsetBy: englishStringIndex)
                let end = englishString.index(englishString.startIndex, offsetBy: englishStringIndex + 1)
                englishString.replaceSubrange(start..<end, with: "␣")
            }
            else {
                englishString = englishString.replacingOccurrences(of: "␣", with: " ")
            }
            Analytics.logEvent("se3_morse_scroll_right", parameters: [
                "state" : "index_alpha_change"
            ])
            MorseCodeUtils.setSelectedCharInLabel(inputString: englishString, index: englishStringIndex, label: englishMorseCodeTextLabel, isMorseCode: false, color : UIColor.blue)
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
        
        if currentState.last == State.EditingMode {
            //This will be the case when we opened Typing or Speaking mode and pressed back. None of the delegates were called and the mode is still editing modes
            changeState(action: Action.CancelledEditing)
        }
        
        textViewBottom?.delegate = self
        speechRecognizer.delegate = self
        
     /*   SFSpeechRecognizer.requestAuthorization { authStatus in
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
                        //self.recordLabel?.text = "User has denied access to speech recognition" //This line is not needed right now

                    case .restricted:
                        self.recordButton?.isEnabled = false
                        self.recordButton?.setTitle("Speech recognition restricted on this device", for: .disabled)

                    case .notDetermined:
                        self.recordButton?.isEnabled = false
                        self.recordButton?.setTitle("Speech recognition not yet authorized", for: .disabled)
                        self.recordLabel?.text = "Speech recognition not yet authorized"
                }
            }
        }   */
        
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
        //textViewBottom.font = textViewBottom.font?.withSize(30)
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
                           //self.sayThis(string: "No internet connection") //This causes a bug where the user text is overriden in the speech delegate
                       })
    }
    
    // MARK: State Machine Private Helpers
    private func enterStateControllerLoaded() {
        
        if #available(iOS 13.0, *) {
            self.view.backgroundColor = UIColor.systemBackground
        } else {
            // Fallback on earlier versions
            self.view.backgroundColor = UIColor.blue
        }
        self.disabledContextLabel?.textColor = UIColor.lightGray
        self.disabledContextLabel?.isHidden = true
        //self.view.bringSubview(toFront: viewForTypeTalkStackView)
        
        //composerStackView?.isHidden = true //We do not want this at the start
        loadImage(image: nil)
        //UserDefaults.standard.removeObject(forKey: "SE3_IOS_USER_TYPE")
        let se3UserName = UserDefaults.standard.string(forKey: "SE3_IOS_USER_NAME")
        updateName(name: se3UserName)
        let se3UserType = UserDefaults.standard.string(forKey: "SE3_IOS_USER_TYPE")
        updateAilment(ailment: se3UserType)
        updateInstructions(se3UserType: se3UserType)

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
        
        self.englishMorseCodeTextLabel?.text = ""
        self.morseCodeLabel?.text = ""
        self.mcReadInstructionLabel?.isHidden = true
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
    
    private func openMorseCodeEditor() {
        //Open the chat log
        guard let storyBoard : UIStoryboard = self.storyboard else {
            return
        }
        let morseCodeEditorViewController = storyBoard.instantiateViewController(withIdentifier: "MorseCodeEditorViewController") as! MorseCodeEditorViewController
        morseCodeEditorViewController.whiteSpeechViewControllerProtocol = self as WhiteSpeechViewControllerProtocol
        if let navigationController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController {
            navigationController.pushViewController(morseCodeEditorViewController, animated: true)
        }
    }
    
    private func openSettingsScreen() {
        guard let storyBoard : UIStoryboard = self.storyboard else {
            return
        }
        let settingsTableViewController = storyBoard.instantiateViewController(withIdentifier: "SettingsTableViewController") as! SettingsTableViewController
        if let navigationController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController {
            navigationController.pushViewController(settingsTableViewController, animated: true)
        }
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
        //Open new window for typing
        guard let storyBoard : UIStoryboard = self.storyboard else {
            return
        }
        let speechViewController = storyBoard.instantiateViewController(withIdentifier: "SpeechViewController") as! SpeechViewController
        speechViewController.dataChats.removeAll()
        speechViewController.dataChats.append(contentsOf: dataChats)
        speechViewController.inputAction = Action.OpenedEditingModeForTyping
        speechViewController.previousMessage = dataChats.last
        speechViewController.whiteSpeechViewControllerProtocol = self as WhiteSpeechViewControllerProtocol
        if let navigationController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController {
            navigationController.pushViewController(speechViewController, animated: true)
        }
        
        //Close stack views
     /*   composerStackView?.isHidden = true
        bottomLeftImageView?.isHidden = true
        navStackView?.isHidden = true
        //
        
        let se3UserType = UserDefaults.standard.string(forKey: "SE3_IOS_USER_TYPE")
        if se3UserType == nil || se3UserType == "_2" {
           //Device owner = grey
            view.backgroundColor = UIColor.gray
        }
        else if se3UserType == "_1" {
           // Device owner = normal. Typing = other user = green
           view.backgroundColor = UIColor.init(red: 0, green: 80, blue: 0, alpha: 0.2)
        }
       
        self.userStatusLabel?.text = "Hearing-impaired person typing"
        self.disabledContextLabel?.text = ""
        self.disabledContextLabel?.isHidden = true
        self.recordLabel?.text = "Tap Screen or Tap Return button to complete"
        self.textViewBottom?.text = "Start typing..."
        textViewBottom?.isEditable = true
        textViewBottom?.becomeFirstResponder()
        
        let stackViewTransform = self.timerStackView?.transform.translatedBy(x: 0, y: -40) // delta = -10
        let textViewBottomTransform = self.textViewBottom?.transform.translatedBy(x: 0, y: -85) // delta = -40
        UIView.animate(withDuration: 1.0) {
            self.timerStackView?.transform = stackViewTransform ?? CGAffineTransform()
            self.textViewBottom?.transform = textViewBottomTransform ?? CGAffineTransform()
        }   */
    }
    
    private func exitStateTyping() {
        //Show stack views
        if dataChats.count > 0 { composerStackView?.isHidden = false }
        navStackView?.isHidden = false
        bottomLeftImageView?.isHidden = false
        bottomMiddleImageView?.isHidden = false
        //
        
        textViewBottom?.isEditable = false
        textViewBottom?.resignFirstResponder()
        if currentState.last == State.Typing {
            //Means nothing was actually entered
            
            if dataChats.count > 0 {
                textViewBottom?.text = dataChats[dataChats.count - 1].text
                if dataChats[dataChats.count - 1].mode == "typing" {
                    //If the last message was typed
                    recordLabel?.text = speechToTextInstructionString
                    disabledContextLabel?.isHidden = false
                    disabledContextLabel?.text = hiSIContextString
                }
                else if dataChats[dataChats.count - 1].mode == "talking" {
                    //If the last message was spoken
                    if UserDefaults.standard.string(forKey: "SE3_IOS_USER_TYPE") == "_1" {
                        // Device owner was talking
                        view.backgroundColor = UIColor.gray
                    }
                    else {
                        view.backgroundColor = UIColor.init(red: 0, green: 80, blue: 0, alpha: 1)
                    }
                    recordLabel?.text = typingInstructionString
                }
            }
            else {
                if #available(iOS 13.0, *) {
                    view.backgroundColor = UIColor.systemBackground
                }
                if UserDefaults.standard.string(forKey: "SE3_IOS_USER_TYPE") == "_1" {
                    recordLabel?.text = speechToTextInstructionString
                }
                else {
                    recordLabel?.text = typingInstructionString
                }
                textViewBottom?.text = ""
            }
        }
        else {
            guard let newText = textViewBottom?.text else {
                return
            }
            sayThis(string: newText)
            let morseCodeString = convertEnglishToMC(englishString: newText)
            englishMorseCodeTextLabel?.text = newText
            morseCodeLabel?.text = morseCodeString
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
        
        
        let stackViewTransform = self.timerStackView?.transform.translatedBy(x: 0, y: 40) //80
        let textViewBottomTransform = self.textViewBottom?.transform.translatedBy(x: 0, y: 85) //130
        UIView.animate(withDuration: 1.0) {
            self.timerStackView?.transform = stackViewTransform ?? CGAffineTransform()
            self.textViewBottom?.transform = textViewBottomTransform ?? CGAffineTransform()
        }
    }
    
    private func openCameraForBlind() {
        //currentState.append(State.EditingMode)
        performSegue(withIdentifier: "SECamera", sender: nil)
    }
    
    public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SECamera" {
            let visionMLViewController = segue.destination as? VisionMLViewController
            visionMLViewController?.delegate = self
            hapticManager?.generateHaptic(code: hapticManager?.RESULT_SUCCESS)
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
        //Open new window for typing
        guard let storyBoard : UIStoryboard = self.storyboard else {
            return
        }
        let speechViewController = storyBoard.instantiateViewController(withIdentifier: "SpeechViewController") as! SpeechViewController
        speechViewController.dataChats.removeAll()
        speechViewController.dataChats.append(contentsOf: dataChats)
        speechViewController.inputAction = Action.OpenedEditingModeForSpeaking
        speechViewController.previousMessage = dataChats.last
        speechViewController.whiteSpeechViewControllerProtocol = self as WhiteSpeechViewControllerProtocol
        if let navigationController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController {
            navigationController.pushViewController(speechViewController, animated: true)
        }
        return
        
        
        if hasInternetConnection() {
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate)) //vibration ONLY if not receiving
            //try! startRecording()
            //runTimer()
            //recordButton?.setTitle("Stop recording", for: [])
            
            //Close/hide stack views
            composerStackView?.isHidden = true
            navStackView?.isHidden = true
            bottomLeftImageView?.isHidden = true
            //
            
            let se3UserType = UserDefaults.standard.string(forKey: "SE3_IOS_USER_TYPE")
            if se3UserType == nil || se3UserType == "_2" {
               //Not device owner = green
                view.backgroundColor = UIColor.init(red: 0, green: 80, blue: 0, alpha: 1)
            }
            else if se3UserType == "_1" {
               // Device owner = gray
               view.backgroundColor = UIColor.gray
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
            //longPressLabel?.isHidden = true
        }
        else {
            //dialogOK(title: "Alert", message: "No internet connection")
            animateNoInternetConnection()
        }
    }
    
    private func exitStateSpeaking() {
        //Show stack views
        if dataChats.count > 0 { composerStackView?.isHidden = false }
        navStackView?.isHidden = false
        bottomLeftImageView?.isHidden = false
        //
        
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
                    if UserDefaults.standard.string(forKey: "SE3_IOS_USER_TYPE") == "_1" {
                        // other person was typing
                        view.backgroundColor = UIColor.init(red: 0, green: 80, blue: 0, alpha: 1)
                    }
                    else {
                        // device owner was typing
                        view.backgroundColor = UIColor.gray
                    }
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
                    //There was no message before. THis was the first message
                    if #available(iOS 13.0, *) {
                        view.backgroundColor = UIColor.systemBackground
                    }
                    recordLabel?.isHidden = false
                    if UserDefaults.standard.string(forKey: "SE3_IOS_USER_TYPE") == "_1" {
                        recordLabel?.text = speechToTextInstructionString
                    }
                    else {
                        recordLabel?.text = typingInstructionString
                    }
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
      /*  if hasInternetConnection() == false {
            return "internet"
        }
        if AVAudioSession.sharedInstance().recordPermission() != AVAudioSession.RecordPermission.granted {
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
    
    func sendEnglishAndMCToWatch(english: String, morseCode: String) {
        if WCSession.isSupported() {
            let session = WCSession.default
            if session.isWatchAppInstalled && session.isReachable {
                session.sendMessage(["is_english_mc": true, "english": english, "morse_code": morseCode], replyHandler: nil, errorHandler: nil)
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
    
    func receivedRequestForEnglishAndMCFromWatch() {
        let englishString = englishMorseCodeTextLabel?.text
        let morseCodeString = morseCodeLabel?.text
        sendEnglishAndMCToWatch(english: englishString != nil ? englishString! : "", morseCode: morseCodeString != nil ? morseCodeString! : "")
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
        else if !synth.isSpeaking {
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
    
    //input method: typing/talking/morse_code
    private func setEnglishAndMCLabels(english : String, morseCode: String, inputMethod : String) {
        englishMorseCodeTextLabel?.text = english
        englishMorseCodeTextLabel?.textColor = .none
        englishMorseCodeTextLabel?.isHidden = false
        englishStringIndex = -1
        morseCodeLabel?.text = morseCode
        morseCodeLabel?.textColor = .none
        morseCodeLabel?.isHidden = false
        morseCodeStringIndex = -1
        if inputMethod != "camera" {
            self.dataChats.append(ChatListItem(text: english, morseCodeText: morseCode, origin: peerID.displayName, mode: inputMethod))
            self.chatLogBtn?.image = UIImage(systemName: "book.fill")
        }
    }
    
    private func convertEnglishToMC(englishString : String) -> String {
        let english = englishString.uppercased().trimmingCharacters(in: .whitespacesAndNewlines).filter("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ".contains).replacingOccurrences(of: " ", with: "␣")
        var morseCodeString = ""
        var index = 0
        indicesOfPipes.removeAll()
        indicesOfPipes.append(0)
        for character in english {
            var mcChar = morseCode.alphabetToMCDictionary[String(character)] ?? ""
            mcChar += "|"
            index += mcChar.count
            indicesOfPipes.append(index)
            morseCodeString += mcChar
        }
        
        return morseCodeString
    }
    
    //last action: typing/talking/morse_code
    private func setBackgroundColor(lastAction : String) {
        let se3UserType = UserDefaults.standard.string(forKey: "SE3_IOS_USER_TYPE")
        if (se3UserType == nil || se3UserType == "_3") && lastAction == "morse_code" {
            //User is type deaf-blind and action was morse code. So owner did the typing.
            view.backgroundColor = UIColor.gray
            view.backgroundColor?.withAlphaComponent(0.5)
        }
        else {
            //All others green
            view.backgroundColor = UIColor.init(red: 0, green: 80, blue: 0, alpha: 0.2)
        }
    }

    private func loadImage(image: UIImage?) {
        if image != nil {
            userImageView?.image = image
        }
        else {
            let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
            let nsUserDomainMask    = FileManager.SearchPathDomainMask.userDomainMask
            let paths               = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
            if let dirPath          = paths.first
            {
                let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent("se3_profile_pic.jpg")
                let image    = UIImage(contentsOfFile: imageURL.path)
                // Do whatever you want with the image
                if image != nil {
                    userImageView?.image = image
                }
                else {
                    userImageView?.image = UIImage(named: "se_person")
                }
            }
        }
        
    }
    
    private func updateName(name: String?) {
        if name != nil {
            userNameLabel?.text = name
        }
        else {
            userNameLabel?.text = peerID.displayName
        }
    }
    
    private func updateAilment(ailment: String?) {
        userAilmentLabel?.text = "Deaf-blind"
      /*  if ailment == "_1" {
            userAilmentLabel?.text = "Not impaired"
        }
        else if ailment == "_2" {
            userAilmentLabel?.text = "Hearing-impaired"
        }
        else if ailment == "_3" {
            userAilmentLabel?.text = "Deaf-blind"
        }
        else {
            userAilmentLabel?.text = "No ailment mentioned"
        }   */
    }
    
    private func updateInstructions(se3UserType: String?) {
        if se3UserType == "_1" {
            self.recordLabel?.text = speechToTextInstructionString
        }
        else if se3UserType == "_2" {
            self.recordLabel?.text = typingInstructionString
        }
        else if se3UserType == "_3" {
            self.recordLabel?.text = longPressMorseCodeInstructionString
        }
        else {
            //self.recordLabel?.text = setupInstructionString
            
            //Assuming deaf-blind by default
            self.recordLabel?.text = longPressMorseCodeInstructionString
        }
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
     /*   else if let requestMorseCode = message["request_morse_code"] as? Bool {
            //User has opened the watch app and is requesting the current english and morse code on the phone
            //This is because they prefer to read it on the watch
            let allowiOSToWatch = UserDefaults.standard.string(forKey: "SE3_IOS_WATCH_SEND")
            if allowiOSToWatch == nil || allowiOSToWatch == "_1" {
                let englishString = englishMorseCodeTextLabel?.text
                let morseCodeString = morseCodeLabel?.text
                if englishString?.isEmpty == false && morseCodeString?.isEmpty == false {
                    sendEnglishAndMCToWatch(english: englishString!, morseCode: morseCodeString!)
                }
            }
        }   */
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
        mutableAttributedString.addAttribute(.foregroundColor, value: UIColor.blue, range: characterRange)
        let font = englishMorseCodeTextLabel?.font
        let alignment = englishMorseCodeTextLabel?.textAlignment
        englishMorseCodeTextLabel?.attributedText = mutableAttributedString //all attributes get ovverridden here. necessary to save it before hand
        englishMorseCodeTextLabel?.font = font
        if alignment != nil { englishMorseCodeTextLabel?.textAlignment = alignment! }
        
        if morseCodeLabel?.isHidden == true {
            return
        }
        let mcLowerBound = indicesOfPipes[safe: characterRange.lowerBound] ?? 0
        let mcUpperBound = indicesOfPipes[safe: characterRange.upperBound] ?? indicesOfPipes.last ?? mcLowerBound
        let mcRange = NSRange(location: mcLowerBound, length: mcUpperBound - mcLowerBound)
        let mutableAttributedStringMC = NSMutableAttributedString(string: morseCodeLabel.text ?? "")
        mutableAttributedStringMC.addAttribute(.foregroundColor, value: UIColor.blue, range: mcRange)
        let fontMC = morseCodeLabel?.font
        let alignmentMC = morseCodeLabel?.textAlignment
        morseCodeLabel?.attributedText = mutableAttributedStringMC //all attributes get ovverridden here. necessary to save it before hand
        morseCodeLabel?.font = fontMC
        if alignmentMC != nil { morseCodeLabel?.textAlignment = alignmentMC! }
        
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        englishMorseCodeTextLabel?.textColor = .none
        morseCodeLabel?.textColor = .none
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

    
    //To get typing message back
    func setTypedMessage(english : String)
    
    //To get spoken message back
    func setSpokenMessage(english : String)
    
    //To get the morse code message back
    func setMorseCodeMessage(englishInput : String, morseCodeInput : String)
    
    //To get text recognized by the camera
    func setTextFromCamera(english : String)

    func userProfilePicSet(image : UIImage?)
    func userProfileNameSet(name : String?)
    func userProfileAilmentSet(ailment: String?)

}

extension WhiteSpeechViewController : WhiteSpeechViewControllerProtocol {
    func setTypedMessage(english: String) {
        Analytics.logEvent("se3_ios_typing_ret", parameters: [:]) //returned from typing
        errorCoreHapticsLabel?.isHidden = true
        if english.count > 0 {
            cameraOriginImageView?.isHidden = true
            let englishFiltered = english.uppercased().trimmingCharacters(in: .whitespacesAndNewlines).filter("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ".contains)
            let morseCodeString = convertEnglishToMC(englishString: englishFiltered)
            setEnglishAndMCLabels(english: englishFiltered, morseCode: morseCodeString, inputMethod: "typing")
            morseCodeLabel?.isHidden = true
            setBackgroundColor(lastAction: "typing")
            morseCodeLabel?.isHidden = true
            recordLabel?.text = composerButtonsUseInstructions
            mcReadInstructionLabel?.text = showMorseCodeInstruction
            mcReadInstructionLabel?.isHidden = false
            changeState(action: Action.CompletedEditing)
        }
        else {
            changeState(action: Action.CancelledEditing)
        }
    }
    
    func setSpokenMessage(english: String) {
        Analytics.logEvent("se3_ios_speak_ret", parameters: [:]) //returned from speaking
        errorCoreHapticsLabel?.isHidden = true
        if english.count > 0 {
            cameraOriginImageView?.isHidden = true
            let englishFiltered = english.uppercased().trimmingCharacters(in: .whitespacesAndNewlines).filter("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ".contains)
            let morseCodeString = convertEnglishToMC(englishString: englishFiltered)
            setEnglishAndMCLabels(english: englishFiltered, morseCode: morseCodeString, inputMethod: "talking")
            setBackgroundColor(lastAction: "talking")
            morseCodeLabel?.isHidden = true
            recordLabel?.text = composerButtonsUseInstructions
            mcReadInstructionLabel?.text = showMorseCodeInstruction
            mcReadInstructionLabel?.isHidden = false
            changeState(action: Action.CompletedEditing)
        }
        else {
            changeState(action: Action.CancelledEditing)
        }
    }
    
    func setMorseCodeMessage(englishInput: String, morseCodeInput : String) {
        Analytics.logEvent("se3_ios_mc_ret", parameters: [:]) //returned from morse code
        errorCoreHapticsLabel?.isHidden = true
        if englishInput.count > 0 && morseCodeInput.count > 0 {
            cameraOriginImageView?.isHidden = true
            setEnglishAndMCLabels(english: englishInput, morseCode: morseCodeInput, inputMethod: "morse_code")
            setBackgroundColor(lastAction: "morse_code")
            morseCodeLabel?.isHidden = true
            recordLabel?.text = composerButtonsUseInstructions
            mcReadInstructionLabel?.text = showMorseCodeInstruction
            mcReadInstructionLabel?.isHidden = false
            changeState(action: Action.CompletedEditing)
        }
        else {
            changeState(action: Action.CancelledEditing)
        }
    }
    
    func setTextFromCamera(english: String) {
        Analytics.logEvent("se3_ios_camera_ret", parameters: [:]) //returned from camera
        errorCoreHapticsLabel?.isHidden = true
        if english.count > 0 {
            cameraOriginImageView?.isHidden = false
            let englishFiltered = english.uppercased().trimmingCharacters(in: .whitespacesAndNewlines).filter("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ".contains)
            let morseCodeString = convertEnglishToMC(englishString: englishFiltered)
            setEnglishAndMCLabels(english: englishFiltered, morseCode: morseCodeString, inputMethod: "camera") //Originally from device
            morseCodeLabel?.isHidden = true
            setBackgroundColor(lastAction: "morse_code")
            morseCodeLabel?.isHidden = true
            recordLabel?.text = ""
            mcReadInstructionLabel?.text = showMorseCodeInstruction
            mcReadInstructionLabel?.isHidden = false
        }
    }
    
    func userProfileOptionSet(se3UserType : String) {
        Analytics.logEvent("se3_user_profile_set", parameters: [
            "user_type": se3UserType
        ])
        
        if se3UserType == "_1" {
            recordLabel?.text = speechToTextInstructionString
        }
        else if se3UserType == "_2" {
            recordLabel?.text = typingInstructionString
        }
        else if se3UserType == "_3" {
            recordLabel?.text = longPressMorseCodeInstructionString
        }
        
    /*    self.userProfileVerticalStackView?.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: .allowUserInteraction,
                       animations: { [weak self] in
                        self?.userProfileVerticalStackView.transform = .identity
            },
                       completion: nil) */
        
        //If user profile has been changed, clear chat logs and reset. Otherwise it will lead to confusion
        if #available(iOS 13.0, *) {
            self.chatLogBtn?.image = UIImage(systemName: "book")
        }
        dataChats.removeAll()
        changeState(action: Action.ChatLogsCleared)
    }
    
    func userProfilePicSet(image: UIImage?) {
        loadImage(image: image)
    }
    
    func userProfileAilmentSet(ailment: String?) {
        updateAilment(ailment: ailment)
    }
    
    func userProfileNameSet(name: String?) {
        updateName(name: name)
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
            let stackViewTransform = self.timerStackView?.transform.translatedBy(x: 0.0, y: 5.0)
            
            UIView.animate(withDuration: 0.5, animations: {
                self.recordLabel?.transform = labelTransform ?? CGAffineTransform()
                self.timerStackView?.transform = stackViewTransform ?? CGAffineTransform()
                
            })
            
            mutableNumberOfTransformations -= 1
        }
        changeState(action: Action.ReleaseHold)
        
    }
    
    func touchBegan(withForce: CGFloat) {
        let labelTransform = self.recordLabel?.transform.scaledBy(x: withForce > 0 ? 0.99 : 1.01, y: withForce > 0 ? 0.99 : 1.01)
        let stackViewTransform = self.timerStackView?.transform.translatedBy(x: 0.0, y: -5*withForce)
        UIView.animate(withDuration: 0.5, animations: {
            self.recordLabel?.transform = labelTransform ?? CGAffineTransform()
            self.timerStackView?.transform = stackViewTransform ?? CGAffineTransform()
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
