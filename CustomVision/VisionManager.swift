//
//  VisionMaanager.swift
//  Suno
//
//  Created by Adarsh Hasija on 28/03/23.
//  Copyright © 2023 Adam Behringer. All rights reserved.
//

import Foundation
import UIKit
import Vision

class VisionManager : NSObject {
    static let shared = VisionManager()
    
    //Initializer access level change now
    private override init() {}
    
    fileprivate var currentVC: UIViewController?
    var completion: ((_ imageDescription: String) -> Void)?
    
    func getImageDescription(vc: UIViewController, originalImage: UIImage,
                         completion: @escaping (_ imageDescription: String) -> Void) {
      self.currentVC = vc
      self.completion = completion

        // Convert from UIImageOrientation to CGImagePropertyOrientation.
        let cgOrientation = CGImagePropertyOrientation(originalImage.imageOrientation)
        
        // Fire off request based on URL of chosen photo.
        guard let cgImage = originalImage.cgImage else {
            return
        }
        performVisionRequest(image: cgImage,
                             orientation: cgOrientation)
    }
    
    /// - Tag: PerformRequests
    fileprivate func performVisionRequest(image: CGImage, orientation: CGImagePropertyOrientation) {
        
        // Fetch desired requests based on switch status.
        let requests = createVisionRequests()
        // Create a request handler.
        let imageRequestHandler = VNImageRequestHandler(cgImage: image,
                                                        orientation: orientation,
                                                        options: [:])
        
        // Send the requests to the request handler.
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try imageRequestHandler.perform(requests)
            } catch let error as NSError {
                print("Failed to perform image request: \(error)")
                (self.currentVC as? ActionsTableViewController)?.showDialog(title: "Image Request Failed", message: error.localizedDescription)
                return
            }
        }
    }
    
    /// - Tag: CreateRequests
    fileprivate func createVisionRequests() -> [VNRequest] {
        
        // Create an array to collect all desired requests.
        var requests: [VNRequest] = []
        
        //requests.append(self.rectangleDetectionRequest)
        //requests.append(self.faceDetectionRequest)
        //requests.append(self.faceLandmarkRequest)
        requests.append(self.textDetectionRequest)
        //requests.append(self.animalDetectionRequest)
        //requests.append(self.barcodeDetectionRequest)
        
        // Return grouped requests as a single array.
        return requests
    }
    
    fileprivate func handleDetectedRectangles(request: VNRequest?, error: Error?) {
        if let nsError = error as NSError? {
            (self.currentVC as? ActionsTableViewController)?.showDialog(title: "Rectangle Detection Error", message: nsError.localizedDescription)
            return
        }
        guard let results = request?.results as? [VNRectangleObservation] else {
            return
        }
    }
    
    fileprivate func handleDetectedFaces(request: VNRequest?, error: Error?) {
        if let nsError = error as NSError? {
            (self.currentVC as? ActionsTableViewController)?.showDialog(title: "Face Detection Error", message: nsError.localizedDescription)
            return
        }
        // Perform drawing on the main thread.
        guard let results = request?.results as? [VNFaceObservation] else {
            return
        }
    }
    
    fileprivate func handleDetectedFaceLandmarks(request: VNRequest?, error: Error?) {
        if let nsError = error as NSError? {
            (self.currentVC as? ActionsTableViewController)?.showDialog(title: "Face Landmark Detection Error", message: nsError.localizedDescription)
            return
        }
        guard let results = request?.results as? [VNFaceObservation] else {
            return
        }
    }
    
    fileprivate func handleDetectedText(request: VNRequest?, error: Error?) {
        if let nsError = error as NSError? {
            (self.currentVC as? ActionsTableViewController)?.showDialog(title: "Text Detection Error", message: nsError.localizedDescription)
            return
        }
        guard let results = request?.results as? [VNRecognizedTextObservation] else {
            (self.currentVC as? ActionsTableViewController)?.showDialog(title: "Text Detection Error", message: "No text detected in this immage")
            return
        }
        
        var recognizedText = ""
        for observation in results {
            guard let candidiate = observation.topCandidates(1).first else { return }
              recognizedText += candidiate.string
        }
        
        self.completion?(recognizedText)
    }
    
    fileprivate func handleDetectedObjects(request: VNRequest?, error: Error?) {
        if let nsError = error as NSError? {
            (self.currentVC as? ActionsTableViewController)?.showDialog(title: "Text Detection Error", message: nsError.localizedDescription)
            return
        }
        guard let results = request?.results as? [VNRecognizedObjectObservation] else {
            return
        }
        
        var recognizedText = ""
        for observation in results {
            for label in observation.labels {
                recognizedText += label.identifier + " "
            }
        }
        
        self.completion?(recognizedText)
    }
    
    fileprivate func handleDetectedBarcodes(request: VNRequest?, error: Error?) {
        if let nsError = error as NSError? {
            (self.currentVC as? ActionsTableViewController)?.showDialog(title: "Barcode Detection Error", message: nsError.localizedDescription)
            return
        }
        guard let results = request?.results as? [VNBarcodeObservation] else {
            return
        }
    }
    
    /// - Tag: ConfigureCompletionHandler
    lazy var rectangleDetectionRequest: VNDetectRectanglesRequest = {
        let rectDetectRequest = VNDetectRectanglesRequest(completionHandler: self.handleDetectedRectangles)
        // Customize & configure the request to detect only certain rectangles.
        rectDetectRequest.maximumObservations = 8 // Vision currently supports up to 16.
        rectDetectRequest.minimumConfidence = 0.6 // Be confident.
        rectDetectRequest.minimumAspectRatio = 0.3 // height / width
        return rectDetectRequest
    }()
    
    lazy var faceDetectionRequest = VNDetectFaceRectanglesRequest(completionHandler: self.handleDetectedFaces)
    lazy var faceLandmarkRequest = VNDetectFaceLandmarksRequest(completionHandler: self.handleDetectedFaceLandmarks)
    
    lazy var textDetectionRequest: VNRecognizeTextRequest = {
        let textDetectRequest = VNRecognizeTextRequest(completionHandler: self.handleDetectedText)
        // Tell Vision to report bounding box around each character.
        //textDetectRequest.reportCharacterBoxes = true
        return textDetectRequest
    }()
    lazy var animalDetectionRequest: VNRecognizeAnimalsRequest = {
        let animalDetectRequest = VNRecognizeAnimalsRequest(completionHandler: self.handleDetectedObjects)
        // Tell Vision to report bounding box around each character.
        //textDetectRequest.reportCharacterBoxes = true
        return animalDetectRequest
    }()
    
    lazy var barcodeDetectionRequest: VNDetectBarcodesRequest = {
        let barcodeDetectRequest = VNDetectBarcodesRequest(completionHandler: self.handleDetectedBarcodes)
        // Restrict detection to most common symbologies.
        barcodeDetectRequest.symbologies = [.QR, .Aztec, .UPCE]
        return barcodeDetectRequest
    }()
    
    
}
