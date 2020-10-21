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

//Morse code reader with buttons, no gestures
class MCReaderButtonsViewController : UIViewController {
    
    var inputAlphanumeric : String? = nil
    var inputMorseCode : String? = nil
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
    
    @IBOutlet weak var alphanumericLabel: UILabel!
    @IBOutlet weak var morseCodeLabel: UILabel!
    @IBOutlet weak var currentActivityLabel: UILabel!
    @IBOutlet weak var visuallyImpairedLabel: UILabel!
    @IBOutlet weak var playAudioButton: UIButton!
    @IBOutlet weak var deafBlindLabel: UILabel!
    @IBOutlet weak var scrollMCLabel: UILabel!
    @IBOutlet weak var mcExplanationLabel: UILabel! //Explanation of the dots and dashes screen. In the case of date and time

    
    @IBAction func playAudioButtonTapped(_ sender: Any) {
        guard let alphanumeric = inputAlphanumeric else {
            return
        }
        sayThis(string: alphanumeric)
    }

    @IBAction func gestureLongPress(_ sender: Any) {
        if (sender as? UIGestureRecognizer)?.state == UIGestureRecognizer.State.recognized {
            if isAutoPlayOn == true {
                isAutoPlayOn = false
                return
            }
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
            mcExplanationLabel.isHidden = false
            currentActivityLabel.text = ""
            currentActivityLabel.isHidden = true
            visuallyImpairedLabel.isHidden = false
            playAudioButton.isHidden = false
            deafBlindLabel.isHidden = false
            scrollMCLabel.isHidden = false
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
        scrollMCLabel.isHidden = true
        let autoPlayTxt = "Autoplaying morse code...\nLong press to stop"
        currentActivityLabel.text = autoPlayTxt
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, // announce
        autoPlayTxt);
        
        let dictionary = [
            "direction" : direction
        ]
        let timeInterval = direction == "right" ? 1 : 0.5
        Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(ActionsMCViewController.autoPlay(timer:)), userInfo: dictionary, repeats: true)
    }
    
    override func viewDidLoad() {
        hapticManager = HapticManager(supportsHaptics: supportsHaptics)
        alphanumericLabel.text = inputAlphanumeric
        morseCodeLabel.text = inputMorseCode != nil ? inputMorseCode : convertAlphanumericToMC(alphanumericString: inputAlphanumeric ?? "")
        if WCSession.isSupported() {
            let session = WCSession.default
            if session.isWatchAppInstalled {
                scrollMCLabel.text = "Want to scroll through the vibrations one by one? You can do so using the digital crown on your Apple Watch.\nOpen your watch app and select Get From iPhone\n"
                scrollMCLabel.isHidden = false
            }
        }
        mcExplanationLabel.text = inputMCExplanation
        mcExplanationLabel.isHidden = inputMCExplanation != nil ? false : true
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
                session.sendMessage(["is_english_mc": true, "english": alphanumeric, "morse_code": morseCode], replyHandler: nil, errorHandler: nil)
            }
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
