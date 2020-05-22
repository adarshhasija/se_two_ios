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
            if #available(iOS 13.0, *) {
                self.supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
            } else {
                // Fallback on earlier versions
            };
            
            if WCSession.isSupported() {
                let session = WCSession.default
                session.delegate = self
                session.activate()
            }   
            return true
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
            DispatchQueue.main.async {
                //This is because topViewController must be accessed from the main threads
                ((self.window?.rootViewController as? UINavigationController)?.topViewController as? WhiteSpeechViewController)?.receivedRequestForEnglishAndMCFromWatch()
            }
            
        }
    }
}
