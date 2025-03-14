//
//  ExtensionDelegate.swift
//  Suno-Watch Extension
//
//  Created by Adarsh Hasija on 23/10/18.
//  Copyright © 2018 Adam Behringer. All rights reserved.
//

import WatchKit
import WatchConnectivity
import Intents

class ExtensionDelegate: WKExtension, WKExtensionDelegate, WCSessionDelegate {
    
    /// MARK:- WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        (WKExtension.shared().visibleInterfaceController as? BrailleInterfaceController)?.sessionReachabilityDidChange()
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        (visibleInterfaceController as? BrailleInterfaceController)?.receivedMessageFromPhone(message: message)
    }

    func applicationDidFinishLaunching() {
        // Perform any final initialization of your application.
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        let TIME_DIFF_MILLIS : Int? = applicationContext["TIME_DIFF_MILLIS"] as? Int
        if TIME_DIFF_MILLIS != nil {
            UserDefaults.standard.set(TIME_DIFF_MILLIS, forKey: LibraryCustomActions.STRING_FOR_USER_DEFAULTS)
            //((WKExtension.shared().visibleInterfaceController) as? ValuePlusMinusInterfaceController)?.updateTime() //If the time settings page is visible update the time there immediately. Not working 100%
        }
    }
    
    func handle(_ userActivity: NSUserActivity) {
        let action = SiriShortcut.intentToActionMap[userActivity.activityType] ?? Action.UNKNOWN
        var params = getParamsForMCInterfaceController(action: action)
        params["is_from_siri"] = true
        WKExtension.shared().rootInterfaceController?.popToRootController()
        WKExtension.shared().rootInterfaceController?.pushController(withName: "MCInterfaceController", context: params)
    }
    
    func handleUserActivity(_ userInfo: [AnyHashable : Any]?) {
        //Got from SO but not tested it yet
        //WKExtension.shared().rootInterfaceController?.pushController(withName: "ActionListController", context: nil)
    }

    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                backgroundTask.setTaskCompletedWithSnapshot(false)
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                connectivityTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
                urlSessionTask.setTaskCompletedWithSnapshot(false)
            case let relevantShortcutTask as WKRelevantShortcutRefreshBackgroundTask:
                // Be sure to complete the relevant-shortcut task once you're done.
                relevantShortcutTask.setTaskCompletedWithSnapshot(false)
            case let intentDidRunTask as WKIntentDidRunRefreshBackgroundTask:
                // Be sure to complete the intent-did-run task once you're done.
                intentDidRunTask.setTaskCompletedWithSnapshot(false)
            default:
                // make sure to complete unhandled task types
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
    
    func getParamsForMCInterfaceController(action : Action) -> [String:Any] {
        var params : [String:Any] = [:]
        params["mode"] = action.rawValue //Not setting MANUAL here as this could be GET_IOS which we accept
        if action == Action.TIME {
            params["mode"] = Action.MANUAL.rawValue
            let alphanumericString = LibraryCustomActions.getCurrentTimeInAlphanumeric(format: "12")
            params["alphanumeric"] = alphanumericString
        }
        else if action == Action.DATE {
            params["mode"] = Action.MANUAL.rawValue
            let alphanumericString = LibraryCustomActions.getCurrentDateInAlphanumeric()
            params["alphanumeric"] = alphanumericString
        }
        else if action == Action.BATTERY_LEVEL {
            params["mode"] = Action.MANUAL.rawValue
            WKInterfaceDevice.current().isBatteryMonitoringEnabled = true
            let level = String(Int(WKInterfaceDevice.current().batteryLevel * 100)) //int as we do not decimal
            WKInterfaceDevice.current().isBatteryMonitoringEnabled = false
            params["alphanumeric"] = level
        }
        return params
    }
    
    func getBatteryLevelAsAlphanumericWithOutPercentageSign() -> String {
        WKInterfaceDevice.current().isBatteryMonitoringEnabled = true
        let level = Int(WKInterfaceDevice.current().batteryLevel * 100) //int as we do not decimal
        WKInterfaceDevice.current().isBatteryMonitoringEnabled = false
        let levelString = String(level)// + "%"
        return levelString
    }
    
    func getBatteryLevelCustomInputs() -> [String:Any] {
        WKInterfaceDevice.current().isBatteryMonitoringEnabled = true
        let level = Int(WKInterfaceDevice.current().batteryLevel * 100) //int as we do not decimal
        WKInterfaceDevice.current().isBatteryMonitoringEnabled = false
        let levelString = String(level) + "%"
        let dotsDashesExplanations = LibraryCustomActions.getBatteryLevelInDotsDashes(batteryLevel: level)
        return [
            SiriShortcut.INPUT_FIELDS.input_alphanumerics.rawValue: levelString,
            SiriShortcut.INPUT_FIELDS.input_morse_code.rawValue: dotsDashesExplanations["morse_code"],
            SiriShortcut.INPUT_FIELDS.input_mc_explanation.rawValue: dotsDashesExplanations["instructions"]
        ]
    }

}
