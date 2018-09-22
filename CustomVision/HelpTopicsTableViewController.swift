//
//  File.swift
//  Suno
//
//  Created by Adarsh Hasija on 22/09/18.
//  Copyright © 2018 Adam Behringer. All rights reserved.
//

import Foundation
import UIKit

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
        
        helpTopics.append(HelpTopic(
            question: "I can hear and speak and I would like to record a message for my hearing-impaired friend",
            answer: "Ensure you have an internet connection, either data or Wifi. In this app, tap the screen to start a recording. Speak normally and you will see your words appearing on the screen. Tap the screen again when finished to end the recording. Show the message to your friend.")
        )
        
        helpTopics.append(HelpTopic(
            question: "I am hearing-imapired and speech-impaired and I would like to give my friend a message",
            answer: "Swipe up to open the keyboard. Type out a message. Tap the screen to close the keyboard. Show your friend the message.")
        )
        
        helpTopics.append(HelpTopic(
            question: "I am hearing-impaired and I want to use this device to have a conversation with someone who can hear and speak",
            answer: "Swipe up on the main screen to open the keyboard and type a message. Tap the screen again to close the keyboard. Show your partner the message. Your partner can then tap on the screen to record their voice. Once they have finished recording, they can tap the screen to end their recording. They will then return the device to you so you can read the message.")
        )
        
        helpTopics.append(HelpTopic(
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
            answer: "Go to your settings menu and ensure Wifi is turned ON and bluetooth is turned ON. Then return to this app and and long press to start a new session. In the pop up window that appears select Typing. Your friend must also check their settings to make sure Wifi and bluetooth are ON. They must also have their internet data on or be connected to a wifi network for voice recording to work. Then they must return to the app, long press to start a new session, select Speaking, and in the menu that appears, select your device to connect to.")
        )
        
        helpTopics.append(HelpTopic(
            question: "I can hear and speak and I would like to connect to my friend's device. My friend is hearing-imapired and is sitting right next to me with his/her device",
            answer: "Go to your settings menu and ensure Wifi is turned ON and bluetooth is turned ON. You must also ensure you have an internet connection(either data or wifi) for voice recording to work. Then return to this app and and long press to start a new session. In the pop up window that appears select Speaking. The menu that appears will be empty. Your friend must also check their settings to make sure Wifi and bluetooth are ON. Then they must return to the app, long press to start a new session, select Typing. Now go back to the menu on your screen. It should have your friend's device name on it. Select it to connect to it. Once connection is successful, the session has begun.")
        )
        
        helpTopics.append(HelpTopic(
            question: "How do I stop a session?",
            answer: "You can long press the screen at any time to stop a session.")
        )
        
        helpTopics.append(HelpTopic(
            question: "How long can a voice recording be?",
            answer: "A voice recording can be a maximum of 1 minute in length. There will be a timer near the bottom of the screen. Recording will stop automatically after 1 minute if it is not stopped be the user.")
        )
        
        helpTopics.append(HelpTopic(
            question: "Which devices does this app work on?",
            answer: "This app works on all iPhones and iPads running iOS 12 and above")
        )
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
            let vc = segue.destination as? HelpTopicViewController
            vc?.answer = helpTopics[selectedIndex].answer
        }
    }
}
