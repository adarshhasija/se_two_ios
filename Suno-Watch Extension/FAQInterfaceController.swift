//
//  FAQInterfaceController.swift
//  Suno-Watch Extension
//
//  Created by Adarsh Hasija on 20/10/19.
//  Copyright © 2019 Adam Behringer. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

class FAQInterfaceController: WKInterfaceController {
    
    
    @IBOutlet weak var faqTable: WKInterfaceTable!
    
    var faqArray : [FAQCell] = []
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        faqArray.append(FAQCell(question: "How can deaf-blind read the time", answer: "Tap 8 times and swipe up. The app will display the time in 24 hour format. The deaf-blind user can scroll through the morse code"))
        faqArray.append(FAQCell(question: "How can deaf-blind read the date", answer: "Tap 9 times and swipe up. The app will display the date and the first 2 letters of the day. eg: Tuesday 20th will be 20TU. The deaf-blind user can scroll through the morse code"))
        faqArray.append(FAQCell(question: "Who is this app designed for", answer: "It is designed for the deaf-blind. However it is highly recommended that a someone who can see and hear and is known to the deaf-blind person use it first to understand it before giving it to the deaf-blind person"))
        faqArray.append(FAQCell(question: "What is special about this app", answer: "Allows communicating using touch. App will convert english alphabets to morse code. The morse code will translate to taps on the wrist which a deaf-blind person can feel."))
        faqArray.append(FAQCell(question: "Meaning of blue text", answer: "It is for the guardian/caregiver of the deaf-blind person. It guides you on how to take the next step in the app."))
        faqArray.append(FAQCell(question: "Typing in morse code", answer: "Tap the screen for a dot. The watch will tap your wrist once. Swipe right for a dash. The watch will tap your wrist twice."))
        faqArray.append(FAQCell(question: "Morse code to alphabet", answer: "Swipe up on the screen. If the morse code matches an alphabet character, the alphabet will be displayed and the watch will ping you once on your wrist."))
        faqArray.append(FAQCell(question: "Deleting characters", answer: "Just swipe left. The watch will ping you once if the delete was successful"))
        faqArray.append(FAQCell(question: "Make the watch say text", answer: "After you submit the last alphabet character, swipe up again and the watch will say the text aloud. Ensure the watch volume in high and it is not on Silent Mode in the settings app."))
        faqArray.append(FAQCell(question: "How to reply", answer: "Lightly long press on the screen. Then choose dictation or typing to enter a message."))
        faqArray.append(FAQCell(question: "Dictation is not working", answer: "Dictation will not work if you are out of range of your iPhone or your iPhone is switched off or your iPhone is on Airplane mode."))
        faqArray.append(FAQCell(question: "Reading a reply", answer: "The app will automatically convert the english reply to morse code. Rotate the digital crown downwards to scroll through each character of morse code. The watch will tap you once for dot, twice for dash and once again for end of character. You can also rotate the digital crown upwards to scroll back"))
        faqArray.append(FAQCell(question: "Stop reading and start typing in morse code again", answer: "Just swipe left once. Then you can start typing in morse code again."))
        faqArray.append(FAQCell(question: "Recommended settings for audio", answer: "In the Settings app on the watch, ensure that audio volume is set to maximum and 'Silent Mode' is set to off."))
        faqArray.append(FAQCell(question: "Recommended settings for haptics", answer: "In the Settings app on the watch, ensure that the setting for Haptics is set to 'Prominent' instead of 'Default'."))
        
        // Configure interface objects here.
        faqTable.setNumberOfRows(faqArray.count, withRowType: "FAQRow")

        for (index, faqCell) in faqArray.enumerated() {
            let row = faqTable.rowController(at: index) as! FAQRowController
            row.questionLabel.setText(faqCell.question)
        }
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        let faqCell : FAQCell = faqArray[rowIndex]
        sendAnalytics(eventName: "se3_watch_row_tap", parameters: [
            "screen" : "faq",
            "question" : faqCell.question.prefix(100)
        ])
        presentAlert(withTitle: "", message: faqCell.answer, preferredStyle: .alert, actions: [
        WKAlertAction(title: "OK", style: .default) {}
        ])
    }

}


extension FAQInterfaceController {
    
    func sendAnalytics(eventName : String, parameters : Dictionary<String, Any>) {
        var message : [String : Any] = [:]
        message["event_name"] = eventName
        message["parameters"] = parameters
        if WCSession.isSupported() {
            let session = WCSession.default
            if session.isReachable {
                // In your WatchKit extension, the value of this property is true when the paired iPhone is reachable via Bluetooth.
                session.sendMessage(message, replyHandler: nil, errorHandler: nil)
            }
            
        }
    }
}
