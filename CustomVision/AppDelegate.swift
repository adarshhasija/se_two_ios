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
        
        let siriShortcut = SiriShortcut(dictionary: userActivity.userInfo! as NSDictionary)
        if Action(rawValue: siriShortcut.action)! == Action.CAMERA_OCR {
            let storyBoard : UIStoryboard = UIStoryboard(name: "MainVision", bundle:nil)
                    let visionMLViewController = storyBoard.instantiateViewController(withIdentifier: "VisionMLViewController") as! VisionMLViewController
                    visionMLViewController.siriShortcut = siriShortcut
                    navigationController.pushViewController(visionMLViewController, animated: true)
        }
        else {
            let storyBoard : UIStoryboard = UIStoryboard(name: "MorseCode", bundle:nil)
                    let mcReaderViewController = storyBoard.instantiateViewController(withIdentifier: "MCReaderButtonsViewController") as! MCReaderButtonsViewController
            mcReaderViewController.siriShortcut = SiriShortcut.shortcutsDictionary[Action(rawValue: siriShortcut.action)!]
            let inputs = SiriShortcut.getInputs(action: Action(rawValue: siriShortcut.action)!)
            mcReaderViewController.inputAlphanumeric = inputs[SiriShortcut.INPUT_FIELDS.input_alphanumerics.rawValue] as? String
            mcReaderViewController.inputMorseCode = inputs[SiriShortcut.INPUT_FIELDS.input_morse_code.rawValue] as? String
            mcReaderViewController.inputMCExplanation.append(contentsOf: inputs[SiriShortcut.INPUT_FIELDS.input_mc_explanation.rawValue] as? [String] ?? []
            )
            navigationController.pushViewController(mcReaderViewController, animated: true)
        }
        
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
}
