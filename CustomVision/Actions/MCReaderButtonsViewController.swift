//
//  MCReaderButtonsViewController.swift
//  Suno
//
//  Created by Adarsh Hasija on 21/10/20.
//  Copyright © 2020 Adam Behringer. All rights reserved.
//

import Foundation
import UIKit
import Speech
import FirebaseAnalytics
import WatchConnectivity
import IntentsUI

//Morse code reader with buttons, no gestures
class MCReaderButtonsViewController : UIViewController {
    
    var siriShortcut: SiriShortcut? = nil
    var inputAlphanumeric : String? = nil
    var inputMorseCode : String? = nil //Customized morse code is sent it. If this is nil, we will use standard morse code dictionary
    var inputMCExplanation : String? = nil
    
    lazy var supportsHaptics: Bool = {
            return (UIApplication.shared.delegate as? AppDelegate)?.supportsHaptics ?? false
        }()
    var hapticManager : HapticManager?
    
    var alphanumericStringIndex = -1
    var morseCodeStringIndex = -1
    var morseCode = MorseCode()
    var synth = AVSpeechSynthesizer()
    var indicesOfPipes : [Int] = [] //This is needed when highlighting morse code when the user taps on the screen to play audio
    var isAutoPlayOn = false
    
    @IBOutlet weak var stackViewMain: UIStackView!
    @IBOutlet weak var alphanumericLabel: UILabel!
    @IBOutlet weak var morseCodeLabel: UILabel!
    @IBOutlet weak var currentActivityLabel: UILabel!
    @IBOutlet weak var visuallyImpairedLabel: UILabel!
    @IBOutlet weak var middleStackView: UIStackView!
    @IBOutlet weak var playAudioButton: UIButton!
    @IBOutlet weak var deafBlindLabel: UILabel!
    @IBOutlet weak var appleWatchImageView: UIImageView!
    @IBOutlet weak var scrollMCLabel: UILabel!
    @IBOutlet weak var mcExplanationLabel: UILabel! //Explanation of the dots and dashes screen. In the case of date and time
    var siriButton : INUIAddVoiceShortcutButton!
    var backTapLabels : [UILabel] = []

    
    @IBAction func playAudioButtonTapped(_ sender: Any) {
        guard let alphanumeric = inputAlphanumeric else {
            return
        }
        Analytics.logEvent("se3_ios_audio_btn", parameters: [:])
        sayThis(string: alphanumeric)
    }

    @IBAction func gestureLongPress(_ sender: Any) {
        if (sender as? UIGestureRecognizer)?.state == UIGestureRecognizer.State.recognized {
            if isAutoPlayOn == true {
                isAutoPlayOn = false
                return
            }
            Analytics.logEvent("se3_ios_long_press", parameters: [:])
            alphanumericStringIndex = -1
            morseCodeStringIndex = -1
            morseCodeAutoPlay(direction: "right")
        }
    }
    
    @objc func autoPlay(timer : Timer) {
        let dictionary : Dictionary = timer.userInfo as! Dictionary<String,String>
        let direction : String = dictionary["direction"] ?? ""
        if direction == "right" { mcScrollRight() } else { mcScrollLeft() }

        let count = morseCodeLabel.text?.count ?? -1
        if (direction == "right" && morseCodeStringIndex >= count)
            || (direction == "left" && morseCodeStringIndex < 0)
            || isAutoPlayOn == false {
            timer.invalidate()
            isAutoPlayOn = false
            alphanumericStringIndex = -1
            morseCodeStringIndex = -1
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, // announce
            "Autoplay complete");
            alphanumericLabel?.textColor = .none
            morseCodeLabel?.textColor = .none
            morseCodeLabel.text = morseCodeLabel?.text?.replacingOccurrences(of: " ", with: "|") //Autoplay complete, restore pipes
            //mcExplanationLabel.isHidden = false
            currentActivityLabel.text = ""
            currentActivityLabel.text = "Long press to autoplay"
            //visuallyImpairedLabel.isHidden = false
            //playAudioButton.isHidden = false
            //deafBlindLabel.isHidden = false
            appleWatchImageView.isHidden = false
            scrollMCLabel.isHidden = false
            siriButton.isHidden = false
            for backTapLabel in backTapLabels {
                backTapLabel.isHidden = false
            }
        }
    }
    
    func morseCodeAutoPlay(direction: String) {
        isAutoPlayOn = true
        alphanumericLabel?.textColor = .none //Resetting the string colors at the start of autoplay
        let morseCodeString = morseCodeLabel?.text
        morseCodeLabel?.text = morseCodeString?.replacingOccurrences(of: "|", with: " ") //We will not be playing pipes in autoplay
        morseCodeLabel?.textColor = .none
        mcExplanationLabel.isHidden = true
        currentActivityLabel.isHidden = false
        visuallyImpairedLabel.isHidden = true
        playAudioButton.isHidden = true
        deafBlindLabel.isHidden = true
        appleWatchImageView.isHidden = true
        scrollMCLabel.isHidden = true
        siriButton.isHidden = true
        for backTapLabel in backTapLabels {
            backTapLabel.isHidden = true
        }
        let autoPlayTxt = "Autoplaying morse code...\nLong press to stop"
        currentActivityLabel.text = autoPlayTxt
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, // announce
        autoPlayTxt);
        
        let dictionary = [
            "direction" : direction
        ]
        let timeInterval = direction == "right" ? 1 : 0.5
        Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(MCReaderButtonsViewController.autoPlay(timer:)), userInfo: dictionary, repeats: true)
    }
    
    override func viewDidLoad() {
        hapticManager = HapticManager(supportsHaptics: supportsHaptics)
        alphanumericLabel.text = inputAlphanumeric
        morseCodeLabel.text = inputMorseCode != nil ? inputMorseCode : convertAlphanumericToMC(alphanumericString: inputAlphanumeric ?? "")
        setUpPlayAudioButtonScalable()
        if WCSession.isSupported() {
            let session = WCSession.default
            if session.isWatchAppInstalled {
                appleWatchImageView.image = UIImage(named: "AppleWatchTransparent")
                appleWatchImageView.isHidden = false
                scrollMCLabel.text = "You can scroll through the vibrations 1 by 1 using the Digital Crown on your Apple Watch.\nOpen your watch app and select Get From iPhone\n"
                scrollMCLabel.isHidden = false
            }
        }
        mcExplanationLabel.text = inputMCExplanation
        mcExplanationLabel.isHidden = inputMCExplanation != nil ? false : true
        if siriShortcut != nil { addSiriButton(shortcutForButton: siriShortcut!, to: middleStackView) }
        alphanumericStringIndex = -1
        morseCodeStringIndex = -1
        morseCodeAutoPlay(direction: "right")
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        playAudioButton?.sizeToFit()
    }
    
    private func convertAlphanumericToMC(alphanumericString : String) -> String {
        let english = alphanumericString.uppercased().trimmingCharacters(in: .whitespacesAndNewlines).filter("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ".contains).replacingOccurrences(of: " ", with: "␣")
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
    
    func mcScrollLeft() {
        var alphanumericString = alphanumericLabel?.text ?? ""
        let morseCodeString = morseCodeLabel?.text ?? ""
        morseCodeStringIndex -= 1
        if morseCodeStringIndex < 0 {
                Analytics.logEvent("se3_ios_mc_left", parameters: [
                    "state" : "index_less_0"
                ])
                //try? hapticManager?.hapticForResult(success: false)
                hapticManager?.generateHaptic(code: hapticManager?.RESULT_FAILURE)
               
               if morseCodeStringIndex < 0 {
                   morseCodeLabel.text = morseCodeString //If there is still anything highlighted green, remove the highlight and return everything to default color
                   alphanumericStringIndex = -1
                   alphanumericLabel.text = alphanumericString
               }
               morseCodeStringIndex = -1 //If the index has gone behind the string by some distance, bring it back to -1
               return
           }

            Analytics.logEvent("se3_ios_mc_left", parameters: [
                "state" : "scrolling"
            ])
           MorseCodeUtils.setSelectedCharInLabel(inputString: morseCodeString, index: morseCodeStringIndex, label: morseCodeLabel, isMorseCode: true, color : UIColor.green)
        if isAutoPlayOn == false {
            hapticManager?.playSelectedCharacterHaptic(inputString: morseCodeString, inputIndex: morseCodeStringIndex)
        }
        else {
            //When resetting, We just want a short tap every time we are passing a character
            hapticManager?.generateHaptic(code: hapticManager?.MC_DOT)
        }
        if inputMorseCode != nil {
            //That means it is some custom morse code, like TIME or DATE. We do not want to highlight alphanumerics
            return
        }
           
           if MorseCodeUtils.isPrevMCCharPipeOrSpace(input: morseCodeString, currentIndex: morseCodeStringIndex, isReverse: true) {
               //Need to change the selected character of the English string
               alphanumericStringIndex -= 1
                Analytics.logEvent("se3_ios_mc_left", parameters: [
                    "state" : "index_alpha_change"
                ])
               //FIrst check that the index is within bounds. Else isEngCharSpace() will crash
               if alphanumericStringIndex > -1 && MorseCodeUtils.isEngCharSpace(englishString: alphanumericString, englishStringIndex: alphanumericStringIndex) {
                   let start = alphanumericString.index(alphanumericString.startIndex, offsetBy: alphanumericStringIndex)
                   let end = alphanumericString.index(alphanumericString.startIndex, offsetBy: alphanumericStringIndex + 1)
                   alphanumericString.replaceSubrange(start..<end, with: "␣")
               }
               else {
                   alphanumericString = alphanumericString.replacingOccurrences(of: "␣", with: " ")
               }
               
               if alphanumericStringIndex > -1 {
                   //Ensure that the index is within bounds
                   MorseCodeUtils.setSelectedCharInLabel(inputString: alphanumericString, index: alphanumericStringIndex, label: alphanumericLabel, isMorseCode: false, color: UIColor.green)
               }
               
           }
    }
    
    func mcScrollRight() {
        var alphanumericString = alphanumericLabel?.text ?? ""
        let morseCodeString = morseCodeLabel?.text ?? ""
        morseCodeStringIndex += 1
        if morseCodeStringIndex >= morseCodeString.count {
            Analytics.logEvent("se3_ios_mc_right", parameters: [
                "state" : "index_greater_equal_0"
            ])
            morseCodeLabel.text = morseCodeString //If there is still anything highlighted green, remove the highlight and return everything to default color
            alphanumericLabel.text = alphanumericString
            //WKInterfaceDevice.current().play(.success)
            morseCodeStringIndex = morseCodeString.count //If the index has overshot the string length by some distance, bring it back to string length
            alphanumericStringIndex = alphanumericString.count
            return
        }
        MorseCodeUtils.setSelectedCharInLabel(inputString: morseCodeString, index: morseCodeStringIndex, label: morseCodeLabel, isMorseCode: true, color: UIColor.green)
        hapticManager?.playSelectedCharacterHaptic(inputString: morseCodeString, inputIndex: morseCodeStringIndex)
        
        if inputMorseCode != nil {
            //That means it is some custom morse code, like TIME or DATE. We do not want to highlight alphanumerics
            return
        }
        
        if MorseCodeUtils.isPrevMCCharPipeOrSpace(input: morseCodeString, currentIndex: morseCodeStringIndex, isReverse: false) || alphanumericStringIndex == -1 {
            //Need to change the selected character of the English string
            alphanumericStringIndex += 1
            if alphanumericStringIndex >= alphanumericString.count {
                //WKInterfaceDevice.current().play(.failure)
                return
            }
            if MorseCodeUtils.isEngCharSpace(englishString: alphanumericString, englishStringIndex: alphanumericStringIndex) {
                let start = alphanumericString.index(alphanumericString.startIndex, offsetBy: alphanumericStringIndex)
                let end = alphanumericString.index(alphanumericString.startIndex, offsetBy: alphanumericStringIndex + 1)
                alphanumericString.replaceSubrange(start..<end, with: "␣")
            }
            else {
                alphanumericString = alphanumericString.replacingOccurrences(of: "␣", with: " ")
            }
            Analytics.logEvent("se3_ios_mc_right", parameters: [
                "state" : "index_alpha_change"
            ])
            MorseCodeUtils.setSelectedCharInLabel(inputString: alphanumericString, index: alphanumericStringIndex, label: alphanumericLabel, isMorseCode: false, color : UIColor.green)
        }
        return
    }
    
    private func sayThis(string: String) {
        let audioSession = AVAudioSession.sharedInstance()
        do { try audioSession.setCategory(AVAudioSessionCategoryPlayback) }
        catch { showToast(message: "Sorry, audio failed to play") }
        do { try audioSession.setMode(AVAudioSessionModeDefault) }
        catch { showToast(message: "Sorry, audio failed to play") }
        
        //synth.delegate = self
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
    
    func receivedRequestForAlphanumericsAndMCFromWatch() {
        let alphanumericString = alphanumericLabel?.text ?? ""
        let morseCodeString = morseCodeLabel?.text ?? ""
        sendEnglishAndMCToWatch(alphanumeric: alphanumericString, morseCode: morseCodeString)
    }
    
    func sendEnglishAndMCToWatch(alphanumeric: String, morseCode: String) {
        if WCSession.isSupported() {
            let session = WCSession.default
            if session.isWatchAppInstalled && session.isReachable {
                session.sendMessage([
                                        "is_normal_morse": inputMorseCode != nil ? false : true,
                                        "english": alphanumeric,
                                        "morse_code": morseCode
                                    ], replyHandler: nil, errorHandler: nil)
            }
        }
    }
    
    //Increases the size of the PlayAudio button if the user has opted for
    //Accessibility = Larger Text Sizes
    func setUpPlayAudioButtonScalable() {
        //playAudioButton.contentEdgeInsets = UIEdgeInsets(top: 0,
        //                                                  left: 0,
        //                                                  bottom: 0,
        //                                                  right: 0)
        let font = UIFont(name: "Helvetica", size: 19)!
        let scaledFont = UIFontMetrics.default.scaledFont(for: font)
        let attributes = [NSAttributedString.Key.font: scaledFont]
        let attributedText = NSAttributedString(string: "Play Audio",
                                                        attributes: attributes)
        playAudioButton.titleLabel?.attributedText = attributedText
        playAudioButton.setAttributedTitle(playAudioButton.titleLabel?.attributedText,
                                            for: .normal)
        //playAudioButton.titleLabel?.adjustsFontForContentSizeCategory = true
        //playAudioButton.adjustsImageSizeForAccessibilityContentSizeCategory = true
    }
    
    //Using acitivites instead of intents as Siri opens app directly for activity. For intents, it shows button to open app, which we do not want s
    func createActivityForShortcut(siriShortcut: SiriShortcut) -> NSUserActivity {
        let activity = NSUserActivity(activityType: siriShortcut.activityType)
        activity.title = siriShortcut.title
        activity.userInfo = siriShortcut.dictionary
        activity.suggestedInvocationPhrase = siriShortcut.invocation
        activity.persistentIdentifier = siriShortcut.activityType
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        view.userActivity = activity
        activity.becomeCurrent()
        return activity
    }
    
    // Add an "Add to Siri" button to a view.
    func addSiriButton(shortcutForButton: SiriShortcut, to view: UIStackView) {
        siriButton = INUIAddVoiceShortcutButton(style: .blackOutline)
        siriButton.translatesAutoresizingMaskIntoConstraints = false
        siriButton.isUserInteractionEnabled = true
        let activity = createActivityForShortcut(siriShortcut: shortcutForButton)
        siriButton.shortcut = INShortcut(userActivity: activity)
        siriButton.delegate = self
        
        //view.addSubview(button)
        //view.centerXAnchor.constraint(equalTo: button.centerXAnchor).isActive = true
                //view.centerYAnchor.constraint(equalTo: button.centerYAnchor).isActive = true
        view.insertArrangedSubview(siriButton, at: view.arrangedSubviews.count)
        
        
        let model = modelIdentifier()
        let doesNotSupportBackTap = model.split(separator: ",")[0].contains("6") || model.split(separator: ",")[0].contains("5") //Do not need to check lower than 5 as those devices are not supported by latest OS
        guard doesNotSupportBackTap == false else {
            return
        }
        //Back tap is only supported on iPhone 8 and above
        let txt = "After creating the shortcut, we strong encourage that you attach the shortcut to the Back Tap functionality.You can find this under the Settings app -> Accessibility -> Touch -> Back Tap"
        let sentences = txt.split(separator: ".") //Doing this to ensure blind can move over 1 sentence at a time via VoiceOver
        for sentence in sentences {
            let backTapLabel = UILabel()
            backTapLabel.text = String(sentence)
            backTapLabel.textAlignment = .center
            backTapLabel.lineBreakMode = .byWordWrapping
            backTapLabel.numberOfLines = 0
            backTapLabel.font = backTapLabel.font.withSize(12)
            view.insertArrangedSubview(backTapLabel, at: view.arrangedSubviews.count)
            backTapLabels.append(backTapLabel)
        }
    }
    
    func modelIdentifier() -> String {
        if let simulatorModelIdentifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] { return simulatorModelIdentifier }
        var sysinfo = utsname()
        uname(&sysinfo) // ignore return value
        return String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
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

extension MCReaderButtonsViewController : INUIAddVoiceShortcutButtonDelegate {
    func present(_ addVoiceShortcutViewController: INUIAddVoiceShortcutViewController, for addVoiceShortcutButton: INUIAddVoiceShortcutButton) {
        Analytics.logEvent("se3_add_to_siri_tapped", parameters: [
            "os_version": UIDevice.current.systemVersion,
            "mode": "add",
            "shortcut": siriShortcut?.action.prefix(100) ?? ""
            ])
        
        addVoiceShortcutViewController.delegate = self
        addVoiceShortcutViewController.modalPresentationStyle = .formSheet
        present(addVoiceShortcutViewController, animated: true, completion: nil)
    }
    
    func present(_ editVoiceShortcutViewController: INUIEditVoiceShortcutViewController, for addVoiceShortcutButton: INUIAddVoiceShortcutButton) {
        Analytics.logEvent("se3_add_to_siri_tapped", parameters: [
            "os_version": UIDevice.current.systemVersion,
            "mode": "edit",
            "shortcut": siriShortcut?.action.prefix(100) ?? ""
            ])
        
        editVoiceShortcutViewController.delegate = self
        editVoiceShortcutViewController.modalPresentationStyle = .formSheet
        present(editVoiceShortcutViewController, animated: true, completion: nil)
    }
}

extension MCReaderButtonsViewController : INUIAddVoiceShortcutViewControllerDelegate {
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        Analytics.logEvent("se3_add_to_siri_completed", parameters: [
            "os_version": UIDevice.current.systemVersion,
            "mode": "add",
            "shortcut": siriShortcut?.action.prefix(100) ?? ""
            ])
        dismiss(animated: true, completion: nil)
    }
    
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        Analytics.logEvent("se4_add_to_siri_cancelled", parameters: [
            "os_version": UIDevice.current.systemVersion,
            "mode": "add",
            "shortcut": siriShortcut?.action.prefix(100) ?? ""
            ])
        
        dismiss(animated: true, completion: nil)
    }
}


extension MCReaderButtonsViewController : INUIEditVoiceShortcutViewControllerDelegate {
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didUpdate voiceShortcut: INVoiceShortcut?, error: Error?) {
        Analytics.logEvent("se3_add_to_siri_completed", parameters: [
            "os_version": UIDevice.current.systemVersion,
            "mode": siriShortcut?.action.prefix(100) ?? ""
            ])
        
        dismiss(animated: true, completion: nil)
    }
    
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
        Analytics.logEvent("se3_add_to_siri_deleted", parameters: [
            "os_version": UIDevice.current.systemVersion,
            "mode": siriShortcut?.action.prefix(100) ?? ""
            ])
        
        dismiss(animated: true, completion: nil)
    }
    
    func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
        dismiss(animated: true, completion: nil)
    }
}
