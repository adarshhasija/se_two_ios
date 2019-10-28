//
//  File.swift
//  Suno
//
//  Created by Adarsh Hasija on 22/09/18.
//  Copyright © 2018 Adam Behringer. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAnalytics

public class HelpTopicsTableViewController: UITableViewController {
    
    class HelpTopic {
        var question: String
        var answer: String
        
        init(question: String, answer: String) {
            self.question = question
            self.answer = answer
        }
    }
    
    // Properties
    var helpTopics : [HelpTopic] = []
    var selectedIndex : Int = -1
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Help Topics"
        
    /*    helpTopics.append(HelpTopic(
            question: "I can hear and speak and I would like to convey a message to my hearing-impaired friend",
            answer: "Voice recording is only available when connected to another device. In this app, tap the screen to start a recording. Speak normally and you will see your words appearing on the screen. Tap the screen again when finished to end the recording. Show the message to your friend.")
        )   */
        
        helpTopics.append(HelpTopic(
        question: "Apple Watch:\nWho is the Apple Watch app designed for?",
        answer: "The watch app is designed specially for user who are both deaf and blind. It is designed to allow these users to communicate via touch. The user types in morse code by doing gestures anywhere on the screen. There is no need to be able to see the screen. As the user does gestures, the app confirms what has been typed by tapping the user on the wrist.\n\nTo find out what another person has said in English, the deaf-blind user simply scrolls through the morse code. The app will tap them on the wrist to tell them what has been said.\n\nThis is communicating through touch/taps on the wrist.\n\nWe highly recommend that a guardian/caregiver try out the app before giving it to the deaf-blind user.")
        )
        
        helpTopics.append(HelpTopic(
        question: "Apple Watch:\nHow does a deaf-blind person use the Apple Watch app?",
        answer: "The user can type in morse code. If the user taps the screen, they get a dot and the watch will tap their wrist once to confirm that. If they swipe right, they get a dash and the app will tap their wrist twice to confirm this. Like this they can write a message in morse code which the app will convert to English and play an audio for the other person.\n\nThe other person can then reply on the watch in English and the app will convert it to morse code. When the deaf-blind user scrolls through the morse code, the app will again tap once for dot and twice for dash to help the user understand what was said in English.\n\nWe highly recoomend that a guardian/caregiver try out the app before giving it to the deaf-blind user.\n\nAlso note that it is not neccessary to see the screen. One can tap anywhere on the screen")
        )
        
        helpTopics.append(HelpTopic(
        question: "Apple Watch:\nWhat is the purpose of the blue text?",
        answer: "The blue text are hints designed to guide a caregiver/guardian. It will help them understand how to use the app. For example: Once the deaf-blind user has typed out a message in morse code, the hint will inform the caregiver to lightly long press on the screen to reply in English\n\nWe highly recommend that a guardian/caregiver user these hints to understand how to use this app before giving it to the deaf-blind user.")
        )
        
        helpTopics.append(HelpTopic(
            question: "iPhone/iPad:\nI am hearing-imapired and speech-impaired and I would like to get help from a person in front of me",
            answer: "Tap the Type button towards the bottom of the screen. Type out a message and show the device to the other person so they can read it. They can tap Type a reply or Talk a reply. If they talk a reply, their words will appear on the screen as text.")
        )
        
        helpTopics.append(HelpTopic(
            question: "iPhone/iPad:\nCan I share chat history?",
            answer: "You can use the Share Chat button to share a copy of the chat log with anyone else on any other messenger app(eg: iMessage or WhatsApp) for future reference. This option will only be available once a chat has started. Note that we do not save chat logs within the app")
        )
        
        helpTopics.append(HelpTopic(
            question: "iPhone/iPad:\nWhat does Clear Chat do? When should I use Clear Chat?",
            answer: "It deletes the log of the current chat, giving you a blank screen on which to start a new chat. Use it when a particular chat has become too long and you are scrolling too much. In this case, it maybe better to start a new chat. This option will only be available once a chat has started")
        )
        
    /*    helpTopics.append(HelpTopic(
            question: "I can speak and hear and I want to use this device to have a conversation with my hearing impaired friend.",
            answer: "Tap the screen to record a message. Tap the screen again to stop the recording. Show your partner the message. Your partner can then swipe up to open the keyboard and type a reply. Once they have finished recording, they can tap the screen to close the keyboard. They will then return the device to you so you can read the message.")
        )
        
        helpTopics.append(HelpTopic(
            question: "What is a conversation session?",
            answer: "A conversation session is when you connect to a device that is near you in order to have a conversation. Instead of passing one device from one person to another for a conversation, each person can sit comfortably with one device. In a conversation session, the hearing-imapired person will type while the other person will speak and record their voice. Note that both devices need to be running the Suno app for a conversation session to work.")
        )
        
        helpTopics.append(HelpTopic(
            question: "Do I need an internet connection to have a conversation session?",
            answer: "The device that will be doing speech recording will have to be connected to the internet, either via data or wifi. The device that will be doing only typing does not need to be connected to the internet. Both devices need to have Wifi and Bluetooth set to ON")
        )
        
        helpTopics.append(HelpTopic(
            question: "I am hearing-imapired and I would like to connect to my friend's device. My friend can hear and speak and is sitting right next to me with his/her device",
            answer: "Go to your settings menu and ensure Wifi is turned ON and bluetooth is turned ON. Then return to this app and and tap the green button at the bottom to start a new session. In the pop up window that appears select Typing. Your friend must also check their settings to make sure Wifi and bluetooth are ON. They must also have their internet data on or be connected to a wifi network for voice recording to work. Then they must return to the app, tap the same green button at the bottom to start a new session, select Speaking, and in the menu that appears, select your device to connect to.")
        )
        
        helpTopics.append(HelpTopic(
            question: "I can hear and speak and I would like to connect to my friend's device. My friend is hearing-imapired and is sitting right next to me with his/her device",
            answer: "Go to your settings menu and ensure Wifi is turned ON and bluetooth is turned ON. You must also ensure you have an internet connection(either data or wifi) for voice recording to work. Then return to this app and and tap the green button at the bottom to start a new session. In the pop up window that appears select Speaking. The menu that appears will be empty. Your friend must also check their settings to make sure Wifi and bluetooth are ON. Then they must return to the app, tap the same green button to start a new session, select Typing. Now go back to the menu on your screen. It should have your friend's device name on it. Select it to connect to it. Once connection is successful, the session has begun.")
        )
        
        helpTopics.append(HelpTopic(
            question: "How do I stop a session?",
            answer: "You can tap the red button at the bottom that says End Session. This will stop the session.")
        )   */
        
        helpTopics.append(HelpTopic(
            question: "iPhone/iPad:\nHow long can a voice recording be?",
            answer: "A voice recording can be a maximum of 1 minute in length. There will be a timer near the bottom of the screen. Recording will stop automatically after 1 minute if it is not stopped be the user.")
        )
        
     /*   helpTopics.append(HelpTopic(
            question: "Which devices does this app work on?",
            answer: "This app works on all iPhones and iPads running iOS 12 and above and on an Apple Watch running watchOS 5 and above, if the watch is connected to the iPhone.")
        )   */
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.helpTopics.count
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // create a new cell if needed or reuse an old one
        let cell:HelpTopicsTableViewCell = self.tableView.dequeueReusableCell(withIdentifier: "helpTopicCell") as! HelpTopicsTableViewCell!
        
        // set the text from the data model
        cell.questionLabel?.text = self.helpTopics[indexPath.row].question
        
        return cell
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndex = indexPath.row
        performSegue(withIdentifier: "segueShowDetail", sender: nil)
    }
    
    public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is HelpTopicViewController {
            Analytics.logEvent("se3_help_question_selected", parameters: [
                "os_version": UIDevice.current.systemVersion,
                "device_type": getDeviceType(),
                "question": helpTopics[selectedIndex].question.prefix(100)
                ])
            let vc = segue.destination as? HelpTopicViewController
            vc?.answer = helpTopics[selectedIndex].answer
        }
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
}
