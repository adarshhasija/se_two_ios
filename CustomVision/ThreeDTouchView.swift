//
//  3DTouchView.swift
//  Suno
//
//  Created by Adarsh Hasija on 23/01/20.
//  Copyright © 2020 Adam Behringer. All rights reserved.
//

import Foundation
import UIKit

class ThreeDTouchView : UIView {
   //var touchViews = [UITouch:TouchSpotView]()
    var prevForce : CGFloat = 0
    var whiteSpeechViewControllerProtocol : WhiteSpeechViewControllerProtocol?
    var numberOfTransformations = 0
 
   override init(frame: CGRect) {
      super.init(frame: frame)
      isMultipleTouchEnabled = true
   }
 
   required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
      isMultipleTouchEnabled = true
   }
 
   override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
      for touch in touches {
         //createViewForTouch(touch: touch)
      }
   }
 
   override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
      for touch in touches {
         //let view = viewForTouch(touch: touch)
         // Move the view to the new location.
         let newLocation = touch.location(in: self)
        let force = touch.force
        let maxPossibleForce = touch.maximumPossibleForce
        //let txt = String(format: "Force: %.2f", forceTouchInfo)
        if force >= maxPossibleForce {
            whiteSpeechViewControllerProtocol?.maxForceReached()
        }
        else {
            let simpleForce : CGFloat = force > prevForce ? 1 : -1
            //whiteSpeechViewControllerProtocol?.touchBegan(withForce: simpleForce)
            let transform1 = self.transform.scaledBy(x: simpleForce > 0 ? 0.995 : 1.005, y: simpleForce > 0 ? 0.995 : 1.005)
            self.transform = transform1
            numberOfTransformations += 1
            prevForce = simpleForce
        }
        
        
        
         //view?.center = newLocation
      }
   }
 
   override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
      //whiteSpeechViewControllerProtocol?.touchEnded(numberOfTransformations: numberOfTransformations)
        //numberOfTransformations = 0
      touchOver()
    
      //for touch in touches { removeViewForTouch(touch: touch) }
   }
 
    //Called when SpeechRecognition is launched. Cancels the touch process
   override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    //whiteSpeechViewControllerProtocol?.touchEnded(numberOfTransformations: numberOfTransformations)
    //numberOfTransformations = 0
    //touchOver()
    
    
      //for touch in touches { removeViewForTouch(touch: touch) }
   }
  
    func touchOver() {
        while numberOfTransformations > -1 {
            let transform1 = self.transform.scaledBy(x: 1.004, y: 1.004)
            self.transform = transform1
            
          /*  UIView.animate(withDuration: 0.5) {
                self.transform = transform1
                //self.frame = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight)
            }   */
            
            numberOfTransformations -= 1
        }
        
        
    }
}
