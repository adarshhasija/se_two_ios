//
//  FAQInterfaceController.swift
//  Suno-Watch Extension
//
//  Created by Adarsh Hasija on 20/10/19.
//  Copyright © 2019 Adam Behringer. All rights reserved.
//

import WatchKit
import Foundation


class FAQInterfaceController: WKInterfaceController {
    
    
    @IBOutlet weak var faqTable: WKInterfaceTable!
    
    var faqArray : [FAQCell] = []
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        faqArray.append(FAQCell(question: "Typing in morse code", answer: "Tap the screen for a dot. The watch will tap your wrist once. Swipe right for a dash. The watch will tap your wrist twice."))
        faqArray.append(FAQCell(question: "Morse code to alphabet", answer: "Swipe up on the screen. If the morse code matches an alphabet character, the alphabet will be displayed and the watch will ping you once on your wrist."))
        faqArray.append(FAQCell(question: "Deleting characters", answer: "Just swipe left. The watch will ping you once if the delete was successful"))
        faqArray.append(FAQCell(question: "Make the watch say text", answer: "After you submit the last alphabet character, swipe up again and the watch will say the text aloud. Ensure the watch volume in high and it is not on Silent Mode in the settings app."))
        faqArray.append(FAQCell(question: "How to reply", answer: "Lightly long press on the screen. Then choose dictation or typing to enter a message."))
        faqArray.append(FAQCell(question: "Reading a reply", answer: "The app will automatically convert the english reply to morse code. Rotate the digital crown downwards to scroll through each character of morse code. The watch will tap you once for dot, twice for dash and once again for end of character. You can also rotate the digital crown upwards to scroll back"))
        faqArray.append(FAQCell(question: "Stop reading and start typing in morse code again", answer: "Just swipe left once. Then you can start typing in morse code again."))
        
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
        presentAlert(withTitle: "", message: faqCell.answer, preferredStyle: .alert, actions: [
        WKAlertAction(title: "OK", style: .default) {}
        ])
    }

}
