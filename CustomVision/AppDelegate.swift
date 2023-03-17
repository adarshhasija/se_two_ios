import UIKit
import Firebase
import WatchConnectivity
import CoreHaptics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
  var supportsHaptics : Bool = false
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?)
        -> Bool {
            FirebaseApp.configure()
            
            // Check if the device supports haptics.
            self.supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
            
            if WCSession.isSupported() {
                let session = WCSession.default
                session.delegate = self
                session.activate()
            }   
            return true
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        Analytics.logEvent("se3_shortcut_selected", parameters: [
            "os_version": UIDevice.current.systemVersion,
            "interface": "shortcut"
        ])
        
        let navigationController = window?.rootViewController as! UINavigationController
        navigationController.popToRootViewController(animated: false) //Pop everything. We do not want an endless list of controllers
        let actionsTableViewController = navigationController.topViewController as? ActionsTableViewController
        actionsTableViewController?.showDialog(title: "Sorry", message: "This shortcut is not currently supported")
        
        //removing support for existing shortcuts for now
    /*    let action = SiriShortcut.intentToActionMap[userActivity.activityType] ?? Action.UNKNOWN
        let siriShortcut = SiriShortcut.shortcutsDictionary[action]
        if action == Action.CAMERA_OCR {
            let storyBoard : UIStoryboard = UIStoryboard(name: "MainVision", bundle:nil)
            let cameraViewController = storyBoard.instantiateViewController(withIdentifier: "CameraViewController") as! CameraViewController
            cameraViewController.siriShortcut = siriShortcut
            cameraViewController.delegateActionsTable = navigationController.topViewController as? ActionsTableViewController
            navigationController.pushViewController(cameraViewController, animated: true)
        }
        else {
            var inputAlphanumeric : String? = nil
            let mcReaderViewController = getMorseCodeReadingScreen(inputAction: action, alphanumericString: inputAlphanumeric)
            navigationController.pushViewController(mcReaderViewController, animated: true)
        }   */
        
     //   self.window?.makeKeyAndVisible() //This assumes root view controller is VisionMLViewController
        
        return true
    }
    
    func isBackTapSupported() -> Bool {
        let model = modelIdentifier()
        let iphoneModel = model.split(separator: ",")[0]
        let number : Int = Int(iphoneModel.filter("0123456789.".contains)) ?? 0
        let supportsBackTap = number >= 10 //Has to be iPhone 8 or later: https://stackoverflow.com/questions/26028918/how-to-determine-the-current-iphone-device-model
        return supportsBackTap
    }
    
    private func modelIdentifier() -> String {
        if let simulatorModelIdentifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] { return simulatorModelIdentifier }
        var sysinfo = utsname()
        uname(&sysinfo) // ignore return value
        return String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
    }

}

extension AppDelegate : WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
    
 
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let eventName = message["event_name"] as? String, let parameters = message["parameters"] as? Dictionary<String, Any>
            {
            Analytics.logEvent(eventName, parameters: parameters)
        }
        else if let requestMorseCode = message["request_morse_code"] as? Bool {
            //User has opened the watch app and is requesting the current english and morse code on the phone
            //This is because they prefer to read it on the watch
            let mode = message["mode"] as? String
            DispatchQueue.main.async {
                //This is because topViewController must be accessed from the main threads
                //((self.window?.rootViewController as? UINavigationController)?.topViewController as? WhiteSpeechViewController)?.receivedRequestForEnglishAndMCFromWatch()
                //((self.window?.rootViewController as? UINavigationController)?.topViewController as? ActionsMCViewController)?.receivedRequestForEnglishAndMCFromWatch()
                if ((self.window?.rootViewController as? UINavigationController)?.topViewController is MCReaderButtonsViewController) {
                    ((self.window?.rootViewController as? UINavigationController)?.topViewController as? MCReaderButtonsViewController)?.receivedRequestForAlphanumericsAndMCFromWatch(mode: mode)
                }
                else {
                    if WCSession.isSupported() {
                        let session = WCSession.default
                        if session.isWatchAppInstalled && session.isReachable {
                            session.sendMessage([:], replyHandler: nil, errorHandler: nil)
                        }
                    }
                }
            }
            
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        let TIME_DIFF_MILLIS : Int? = applicationContext["TIME_DIFF_MILLIS"] as? Int
        if TIME_DIFF_MILLIS != nil {
            UserDefaults.standard.set(TIME_DIFF_MILLIS, forKey: LibraryCustomActions.STRING_FOR_USER_DEFAULTS)
            //((self.window?.rootViewController as? UINavigationController)?.topViewController as? SettingsTableViewController)?.updateTime() //not working 100%
        }
    }
    
    func getMorseCodeReadingScreen(inputAction: Action, alphanumericString : String?) -> MCReaderButtonsViewController {
        let storyBoard : UIStoryboard = UIStoryboard(name: "MorseCode", bundle:nil)
        let mcReaderButtonsViewController = storyBoard.instantiateViewController(withIdentifier: "MCReaderButtonsViewController") as! MCReaderButtonsViewController
        mcReaderButtonsViewController.siriShortcut = inputAction == Action.CAMERA_OCR ? nil : SiriShortcut.shortcutsDictionary[inputAction] //If its not BATTERY_LEVEL, its CAMERA_OCR. In this case we dont want to get the siri shortcut as the Add to Siri button should not appear on the reader screen
        let customInputs = inputAction == Action.BATTERY_LEVEL ? getBatteryLevelCustomInputs() : SiriShortcut.getCustomInputs(action: Action(rawValue: inputAction.rawValue) ?? Action.UNKNOWN)
        mcReaderButtonsViewController.inputMode = inputAction
        if customInputs.isEmpty == false {
            mcReaderButtonsViewController.inputAlphanumeric = customInputs[SiriShortcut.INPUT_FIELDS.input_alphanumerics.rawValue]! as? String
            mcReaderButtonsViewController.inputMorseCode = customInputs[SiriShortcut.INPUT_FIELDS.input_morse_code.rawValue]! as? String
            mcReaderButtonsViewController.inputMCExplanation.append(contentsOf: customInputs[SiriShortcut.INPUT_FIELDS.input_mc_explanation.rawValue]! as? [String] ?? []
            )
        }
        else if alphanumericString != nil {
            //Probably MANUAL or CAMERA_OCR
            mcReaderButtonsViewController.inputAlphanumeric = alphanumericString
        }
        
        return mcReaderButtonsViewController
    }
    
    //Have to call it here as UIDevice cannot be access inside LibraryCustomActions or SiriShortcut
    func getBatteryLevelCustomInputs() -> [String:Any] {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let level = Int(UIDevice.current.batteryLevel * 100) //int as we do not decimal
        UIDevice.current.isBatteryMonitoringEnabled = false
        let levelString = String(level) + "%"
        let dotsDashesExplanations = LibraryCustomActions.getBatteryLevelInDotsDashes(batteryLevel: level)
        return [
            SiriShortcut.INPUT_FIELDS.input_alphanumerics.rawValue: levelString,
            SiriShortcut.INPUT_FIELDS.input_morse_code.rawValue: dotsDashesExplanations["morse_code"],
            SiriShortcut.INPUT_FIELDS.input_mc_explanation.rawValue: dotsDashesExplanations["instructions"]
        ]
    }
}
