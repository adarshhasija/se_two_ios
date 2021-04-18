//
//  CameraViewController.swift
//  Suno
//
//  Created by Adarsh Hasija on 14/04/21.
//  Copyright © 2021 Adam Behringer. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import Vision
import IntentsUI
import FirebaseAnalytics

class CameraViewController : UIViewController {
    
    var instructionsLabel : UILabel?
    var settingsButton: UIButton?
    
    @IBAction func settingsButtonTapped(_ sender: Any) {
        let settingsUrl = URL(string: UIApplicationOpenSettingsURLString)!
        UIApplication.shared.open(settingsUrl)
    }
    
    private let messageOnOpen = "Point your camera at the text\nWe will try to read it"
    private var captureDevice: AVCaptureDevice?
    private let captureSession = AVCaptureSession()
    private lazy var previewLayer : AVCaptureVideoPreviewLayer = {
        let preview = AVCaptureVideoPreviewLayer(session: self.captureSession)
        preview.videoGravity = .resizeAspect
        return preview
    }()
    lazy var classificationRequest: [VNRequest] = {
        let classificationRequest = VNRecognizeTextRequest(completionHandler: self.handleClassificationText)
        return [ classificationRequest ]
    }()
    private let videoOutput = AVCaptureVideoDataOutput()
    let targetImageSize = CGSize(width: 227, height: 227) // must match model data input
    var backTapLabels : [UILabel] = []
    var siriShortcut : SiriShortcut? = nil
    var delegateActionsTable : ActionsTableViewControllerProtocol? = nil
    var textObserved : String? = nil //Used when popping this view controller on the return
    
    override func viewDidLoad() {
        //This must be here so that other UI can be added over it
        addPreviewLayer()
        
        addInstructionsStackView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if textObserved != nil {
            //Means we are returning backwards from the Reader controller. Simply pop this
            //We are doing it like this so it works well with VoiceOver.
            //If we popped this controller before showing the reader then VoiceOver will pick UI of the parent controller (table), which we do not want
            self.navigationController?.popViewController(animated: true)
            return
        }
        if siriShortcut != nil { addToSiriStackView(siriShortcut: siriShortcut!) }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
                    case .authorized: // The user has previously granted access to the camera.
                        self.addCameraInput()
                        self.addVideoOutput()
                        self.captureSession.startRunning()
                        self.instructionsLabel?.text = messageOnOpen
                        self.settingsButton?.isHidden = true
                        break
                    
                    case .notDetermined: // The user has not yet been asked for camera access.
                        self.instructionsLabel?.text = "Requesting camera permission"
                        AVCaptureDevice.requestAccess(for: .video) { granted in
                            if granted {
                                DispatchQueue.main.async {
                                    self.addCameraInput()
                                    self.addVideoOutput()
                                    self.captureSession.startRunning()
                                    self.instructionsLabel?.text = self.messageOnOpen
                                    self.settingsButton?.isHidden = true
                                }
                            }
                            else {
                                DispatchQueue.main.async {
                                    let txt = "You have not given camera permission\nTap the Settings button to go to the Settings app and give permission"
                                    self.instructionsLabel?.text = txt
                                    self.settingsButton?.isHidden = false
                                }
                                
                            }
                        }
                    
                    case .denied: // The user has previously denied access. Therefore requestAccess does not work here. It only returns false
                        //UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!) //This opens the Settings app so user can turn the Camera permission ON again. However, we are not using this right now over doubts that Apple could reject the update in future
                        DispatchQueue.main.async {
                            let txt = "You have not given camera permission\nTap the Settings button to go to the Settings app and give permission"
                            self.instructionsLabel?.text = txt
                            self.settingsButton?.isHidden = false
                        }
                        return

                    case .restricted: // The user can't grant access due to restrictions.
                        DispatchQueue.main.async {
                            let txt = "You cannot access the camera due to restrictions on your device"
                            self.instructionsLabel?.text = txt
                        }
                        return
                }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        let device = AVCaptureDevice.default(for: AVMediaType.video)
        if device?.torchMode == AVCaptureDevice.TorchMode.on {
            turnFlashlightOff()
        }
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
        
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.previewLayer.frame = self.view.bounds
    }
    
    private func addCameraInput() {
        if let device = AVCaptureDevice.default(for: .video) {
            let cameraInput = try! AVCaptureDeviceInput(device: device)
            self.captureSession.addInput(cameraInput)
        }
    }
    
    private func addInstructionsStackView() {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.center.x = view.center.x
        stackView.frame = CGRect(x: 0, y: 100, width: self.view.frame.width, height: 100)
        
        instructionsLabel = UILabel()
        instructionsLabel?.text = "Loading..."
        instructionsLabel?.numberOfLines = 0
        instructionsLabel?.textAlignment = .center
        stackView.addArrangedSubview(instructionsLabel!)
        
        settingsButton = UIButton(type: .system)
        settingsButton?.setTitle("Settings", for: .normal)
        settingsButton?.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        settingsButton?.isUserInteractionEnabled = true
        settingsButton?.addTarget(self, action: #selector(self.settingsButtonTapped(_:)), for: .touchUpInside)
        settingsButton?.isHidden = true
        if settingsButton != nil { stackView.addArrangedSubview(settingsButton!) }
        
        self.view.addSubview(stackView)
    }
    
    private func addToSiriStackView(siriShortcut : SiriShortcut) {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.center.x = view.center.x
        self.view.addSubview(stackView)
        stackView.frame = CGRect(x: 0, y: self.view.frame.height - 180, width: self.view.frame.width, height: (UIApplication.shared.delegate as? AppDelegate)?.isBackTapSupported() == true ? 125 : 50) //Did these because if we kept height of 125 only, Add to Siri button would appear stretched as there is no text under it
        addSiriButton(shortcut: siriShortcut, to: stackView)
    }
    
    private func addPreviewLayer() {
        self.view.layer.addSublayer(previewLayer)
    }
    
    private func addVideoOutput() {
        self.videoOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
        self.videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "my.image.handling.queue"))
        self.captureSession.addOutput(self.videoOutput)
    }
    
    func turnFlashLightOn() {
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        guard device.hasTorch else { return }
        
        do {
            try device.lockForConfiguration()
            
            if (device.torchMode == AVCaptureDevice.TorchMode.off) {
                device.torchMode = AVCaptureDevice.TorchMode.on
            }
            
            device.unlockForConfiguration()
        } catch {
            print(error)
        }
    }
    
    func turnFlashlightOff() {
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        guard device.hasTorch else { return }
        
        do {
            try device.lockForConfiguration()
            
            if (device.torchMode == AVCaptureDevice.TorchMode.on) {
                device.torchMode = AVCaptureDevice.TorchMode.off
            }
            
            device.unlockForConfiguration()
        } catch {
            print(error)
        }
    }
    
    func getBrightness(sampleBuffer: CMSampleBuffer) -> Double {
        let rawMetadata = CMCopyDictionaryOfAttachments(nil, sampleBuffer, CMAttachmentMode(kCMAttachmentMode_ShouldPropagate))
        let metadata = CFDictionaryCreateMutableCopy(nil, 0, rawMetadata) as NSMutableDictionary
        let exifData = metadata.value(forKey: "{Exif}") as? NSMutableDictionary
        let brightnessValue : Double = exifData?[kCGImagePropertyExifBrightnessValue as String] as! Double
        return brightnessValue
    }
    
    func handleClassificationText(request: VNRequest, error: Error?) {
        if let results = request.results, !results.isEmpty {
              if let requestResults = request.results as? [VNRecognizedTextObservation] {
                  var recognizedText = ""
                  for observation in requestResults {
                      guard let candidiate = observation.topCandidates(1).first else { return }
                        recognizedText += candidiate.string
                      //recognizedText += "\n"
                  }
                  DispatchQueue.main.async {
                    self.textObserved = recognizedText
                    self.delegateActionsTable?.setTextFromCamera(english: recognizedText)
                  }
                  //self.bubbleLayer.string = recognizedText
              }
          }
    }
    
    func addButtonForSettings(to view: UIStackView) {
        //Not doinng this as the text does not appear blue
        let button = UIButton()
        button.setTitle("Settings", for: .normal)
        button.tintColor = .blue
        button.addTarget(self, action: #selector(settingsButtonTapped), for: .touchUpInside)
        view.insertArrangedSubview(button, at: view.arrangedSubviews.count)
        
     /*   let barButtonItem = UIBarButtonItem()
        barButtonItem.image = UIImage(systemName: "gear")
        barButtonItem.target = self
        barButtonItem.action = #selector(settingsButtonTapped)
        self.navigationItem.rightBarButtonItem = barButtonItem  */
    }
    
    // Add an "Add to Siri" button to a view.
    func addSiriButton(shortcut: SiriShortcut, to view: UIView) {
        let button = INUIAddVoiceShortcutButton(style: .blackOutline)
        button.isAccessibilityElement = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isUserInteractionEnabled = true
        button.shortcut = SiriShortcut.createINShortcutAndAddToSiriWatchFace(siriShortcut: shortcut)
        button.shortcut?.userActivity?.isAccessibilityElement = true
        button.delegate = self
        
        guard let sV = view as? UIStackView else {
            return
        }
        sV.insertArrangedSubview(button, at: sV.arrangedSubviews.count)
        
        guard (UIApplication.shared.delegate as? AppDelegate)?.isBackTapSupported() == true else {
            return
        }
        //Back tap is only supported on iPhone 8 and above
        let txt = "After creating shortcut, go to the Settings app to attach this shortcut to Back Tap"
        let sentences = txt.split(separator: ".") //Doing this to ensure blind can move over 1 sentence at a time via VoiceOver
        for sentence in sentences {
            let backTapLabel = UILabel()
            backTapLabel.text = String(sentence)
            backTapLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
            backTapLabel.textAlignment = .center
            backTapLabel.lineBreakMode = .byWordWrapping
            backTapLabel.numberOfLines = 0
            sV.insertArrangedSubview(backTapLabel, at: sV.arrangedSubviews.count)
            backTapLabels.append(backTapLabel)
        }
    }
}

extension CameraViewController : AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        let brightness = getBrightness(sampleBuffer: sampleBuffer)
        let device = AVCaptureDevice.default(for: AVMediaType.video)
        if brightness < -5.0 && device?.torchMode == AVCaptureDevice.TorchMode.off {
            turnFlashLightOn()
        }
        
        let currentDate = NSDate.timeIntervalSinceReferenceDate
        
        // control the pace of the machine vision to protect battery life
        if currentDate - lastAnalysis >= pace {
          lastAnalysis = currentDate
        } else {
          return // don't run the classifier more often than we need
        }
        
        // Crop and resize the image data.
        // Note, this uses a Core Image pipeline that could be appended with other pre-processing.
        // If we don't want to do anything custom, we can remove this step and let the Vision framework handle
        // crop and resize as long as we are careful to pass the orientation properly.
        guard let croppedBuffer = croppedSampleBuffer(sampleBuffer, targetSize: targetImageSize) else {
          return
        }
        do {
          let classifierRequestHandler = VNImageRequestHandler(cvPixelBuffer: croppedBuffer, options: [:])
          try classifierRequestHandler.perform(classificationRequest)
        } catch {
          print(error)
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


///MARK:- Add or Edit Button
extension CameraViewController: INUIAddVoiceShortcutButtonDelegate {
    func present(_ addVoiceShortcutViewController: INUIAddVoiceShortcutViewController, for addVoiceShortcutButton: INUIAddVoiceShortcutButton) {
        Analytics.logEvent("se3_add_to_siri_tapped", parameters: [
            "os_version": UIDevice.current.systemVersion,
            "device_type": getDeviceType(),
            "mode": "add",
            "action": siriShortcut?.action.prefix(100)
            ])
        
        addVoiceShortcutViewController.delegate = self
        addVoiceShortcutViewController.modalPresentationStyle = .formSheet
        present(addVoiceShortcutViewController, animated: true, completion: nil)
    }
    
    func present(_ editVoiceShortcutViewController: INUIEditVoiceShortcutViewController, for addVoiceShortcutButton: INUIAddVoiceShortcutButton) {
        Analytics.logEvent("se3_add_to_siri_tapped", parameters: [
            "os_version": UIDevice.current.systemVersion,
            "device_type": getDeviceType(),
            "mode": "edit",
            "action": siriShortcut?.action.prefix(100)
            ])
        
        editVoiceShortcutViewController.delegate = self
        editVoiceShortcutViewController.modalPresentationStyle = .formSheet
        present(editVoiceShortcutViewController, animated: true, completion: nil)
    }
    
    
}

extension CameraViewController: INUIAddVoiceShortcutViewControllerDelegate {
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        Analytics.logEvent("se3_add_to_siri_completed", parameters: [
            "os_version": UIDevice.current.systemVersion,
            "device_type": getDeviceType(),
            "mode": "add",
            "action": siriShortcut?.action.prefix(100)
            ])
        dismiss(animated: true, completion: nil)
    }
    
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        Analytics.logEvent("se3_add_to_siri_cancelled", parameters: [
            "os_version": UIDevice.current.systemVersion,
            "device_type": getDeviceType(),
            "mode": "add",
            "action": siriShortcut?.action.prefix(100)
            ])
        
        dismiss(animated: true, completion: nil)
    }
    
    
}

extension CameraViewController : INUIEditVoiceShortcutViewControllerDelegate {
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didUpdate voiceShortcut: INVoiceShortcut?, error: Error?) {
        Analytics.logEvent("se3_add_to_siri_completed", parameters: [
            "os_version": UIDevice.current.systemVersion,
            "device_type": getDeviceType(),
            "mode": "edit",
            "action": siriShortcut?.action.prefix(100)
            ])
        
        dismiss(animated: true, completion: nil)
    }
    
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
        Analytics.logEvent("se3_add_to_siri_cancelled", parameters: [
            "os_version": UIDevice.current.systemVersion,
            "device_type": getDeviceType(),
            "mode": "edit",
            "action": siriShortcut?.action.prefix(100)
            ])
        
        dismiss(animated: true, completion: nil)
    }
    
    func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    
}
