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
        if let watchUserType = message["user_type"] as? String {
            
        }
    }
}
