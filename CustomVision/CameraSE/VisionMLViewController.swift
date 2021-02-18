import UIKit
import AVFoundation
import Vision
import IntentsUI
import FirebaseAnalytics

// controlling the pace of the machine vision analysis
var lastAnalysis: TimeInterval = 0
var pace: TimeInterval = 0.33 // in seconds, classification will not repeat faster than this value

// performance tracking
let trackPerformance = false // use "true" for performance logging
var frameCount = 0
let framesPerSample = 10
var startDate = NSDate.timeIntervalSinceReferenceDate

let synth = AVSpeechSynthesizer()


class VisionMLViewController: UIViewController {
    
    public var siriShortcut : SiriShortcut? = nil
    var delegate : WhiteSpeechViewControllerProtocol? = nil
    var delegateActions : ActionsMCViewControllerProtocol? = nil
    var delegateActionsTable : ActionsTableViewControllerProtocol? = nil
    
    private var lastFrame: CMSampleBuffer?
    
    private lazy var previewOverlayView: UIImageView = {
        
        precondition(isViewLoaded)
        let previewOverlayView = UIImageView(frame: .zero)
        previewOverlayView.translatesAutoresizingMaskIntoConstraints = false
        return previewOverlayView
    }()
    
    private lazy var annotationOverlayView: UIView = {
        precondition(isViewLoaded)
        let annotationOverlayView = UIView(frame: .zero)
        annotationOverlayView.translatesAutoresizingMaskIntoConstraints = false
        return annotationOverlayView
    }()
    ///MARK:- Firebase MLKit properties END
  
    
  @IBOutlet weak var previewView: UIView!
  @IBOutlet weak var stackView: UIStackView!
  @IBOutlet weak var lowerView: UIView!
  
    @IBOutlet weak var middleStackView: UIStackView!
    @IBOutlet weak var bottomStackView: UIStackView!
    var previewLayer: AVCaptureVideoPreviewLayer!
  let bubbleLayer = BubbleLayer(string: "")
  
  let queue = DispatchQueue(label: "videoQueue")
  var captureSession = AVCaptureSession()
  var captureDevice: AVCaptureDevice?
  let videoOutput = AVCaptureVideoDataOutput()
  var unknownCounter = 0 // used to track how many unclassified images in a row
  let confidence: Float = 0.7
    var backTapLabels : [UILabel] = []
  
  // MARK: Load the Model
  let targetImageSize = CGSize(width: 227, height: 227) // must match model data input
  
  lazy var classificationRequest: [VNRequest] = {
    do {
      // Load the Custom Vision model.
      // To add a new model, drag it to the Xcode project browser making sure that the "Target Membership" is checked.
      // Then update the following line with the name of your new model.
      //let model = try VNCoreMLModel(for: AdarshBlueBackpack().model) //try VNCoreMLModel(for: Rupees().model)
      //let classificationRequest = VNCoreMLRequest(model: model, completionHandler: self.handleClassification)
        let classificationRequest = VNRecognizeTextRequest(completionHandler: self.handleClassificationText)
      return [ classificationRequest ]
    } catch {
      fatalError("Can't load Vision ML model: \(error)")
    }
  }()
  
  // MARK: Handle image classification results
  
  func handleClassification(request: VNRequest, error: Error?) {
    guard let observations = request.results as? [VNClassificationObservation]
      else { fatalError("unexpected result type from VNCoreMLRequest") }
    
    guard let best = observations.first else {
      fatalError("classification didn't return any results")
    }
    
    // Use results to update user interface (includes basic filtering)
    print("\(best.identifier): \(best.confidence)")
    if best.identifier.starts(with: "Unknown") || best.confidence < confidence {
      if self.unknownCounter < 3 { // a bit of a low-pass filter to avoid flickering
        self.unknownCounter += 1
      } else {
        self.unknownCounter = 0
        DispatchQueue.main.async {
          self.bubbleLayer.string = nil
        }
      }
    } else {
      self.unknownCounter = 0
      DispatchQueue.main.async {
        // Trimming labels because they sometimes have unexpected line endings which show up in the GUI
        self.bubbleLayer.string = best.identifier.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        let message : String = self.bubbleLayer.string ?? ""
        if message.count > 0 {
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, message)
        }
      }
    }
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
                    self.delegate?.setTextFromCamera(english: recognizedText)
                    self.delegateActions?.setTextFromCamera(english: recognizedText)
                    self.delegateActionsTable?.setTextFromCamera(english: recognizedText)
                    //self.dismiss(animated: true, completion: nil) //This is now being done in ActionsTableViewController. Uncomment this line if calling from a different view.
                }
                //self.bubbleLayer.string = recognizedText
            }
        }
  }
  
  // MARK: Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    previewView.layer.addSublayer(previewLayer)
  }
    
    override func viewWillDisappear(_ animated: Bool) {
        if synth.isSpeaking {
            synth.stopSpeaking(at: .immediate)
        }
    }
  
  override func viewDidAppear(_ animated: Bool) {
    if siriShortcut != nil { addSiriButton(shortcut: siriShortcut!, to: middleStackView) }
    
    bubbleLayer.opacity = 0.0
    bubbleLayer.position.x = self.view.frame.width / 2.0
    bubbleLayer.position.y = lowerView.frame.height / 2
    lowerView.layer.addSublayer(bubbleLayer)
    //setupCamera()
    
    switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: // The user has previously granted access to the camera.
            //self.setupCaptureSession()
            setupCamera()
            addInstructionsTextLabel(text: self.siriShortcut?.messageOnOpen, to: bottomStackView)
            break
        
        case .notDetermined: // The user has not yet been asked for camera access.
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.setupCamera()
                        self.addInstructionsTextLabel(text: self.siriShortcut?.messageOnOpen, to: self.bottomStackView)
                    }
                }
                else {
                    DispatchQueue.main.async {
                        self.addInstructionsTextLabel(text: "You have not given camera permission\nYou need to go to the Settings app to do so", to: self.bottomStackView)
                    }
                    
                }
            }
        
        case .denied: // The user has previously denied access. Therefore requestAccess does not work here. It only returns false
            //UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!) //This opens the Settings app so user can turn the Camera permission ON again. However, we are not using this right now over doubts that Apple could reject the update in future
            DispatchQueue.main.async {
                self.addInstructionsTextLabel(text: "You have not given camera permission\nYou need to go to the Settings app to do so", to: self.bottomStackView)
            }
            return

        case .restricted: // The user can't grant access due to restrictions.
            DispatchQueue.main.async {
                self.addInstructionsTextLabel(text: "You cannot access the camera due to restrictions on your device", to: self.bottomStackView)
            }
            return
    }
    
   /* if AVCaptureDevice.authorizationStatus(for: AVMediaType.video) ==  AVAuthorizationStatus.authorized {
        // Already Authorized
        addInstructionsTextLabel(text: shortcutListItem.messageOnOpen, to: bottomStackView)
    } else {
        //addInstructionsTextLabel(text: "You have not given camera permission\nPlease go to settings to give permission", to: bottomStackView)
        AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted: Bool) -> Void in
           if granted == true {
               print("*******YES**********")
               // User granted
               //self.setupCamera()
                //self.addInstructionsTextLabel(text: self.shortcutListItem.messageOnOpen, to: self.bottomStackView)
           } else {
               print("********NO***********")
               // User rejected
                //self.addInstructionsTextLabel(text: "You have not given camera permission\nPlease go to settings to give permission", to: self.bottomStackView)
           }
       })
    }   */
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    previewLayer.frame = previewView.bounds;
    //stackView.addTarget(self, action: #selector(tapGesture), forControlEvents: .TouchUpInside)
    
    //sayThis(string: shortcutListItem.messageOnOpen) //We do not need this. It automatically speaks once when voiceover is ON as we have set the accessibility label
  }
  
    
    @IBAction func tapGesture(_ sender: Any) {
        if synth.isSpeaking {
            synth.stopSpeaking(at: .immediate)
        }
        sayThis(string: siriShortcut?.messageOnOpen ?? "")
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
    
  
  // MARK: Camera handling
  
  func setupCamera() {
    let deviceDiscovery = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back)
    
    if let device = deviceDiscovery.devices.last {
      captureDevice = device
      beginSession()
    }
  }
  
  func beginSession() {
    do {
      videoOutput.videoSettings = [((kCVPixelBufferPixelFormatTypeKey as NSString) as String) : (NSNumber(value: kCVPixelFormatType_32BGRA) as! UInt32)]
      videoOutput.alwaysDiscardsLateVideoFrames = true
      videoOutput.setSampleBufferDelegate(self, queue: queue)
        
        if captureSession.isRunning {
            return
        }
        if captureSession.outputs.count > 0 {
            captureSession.startRunning()
            //This is to avoid exception An AVCaptureOutput instance may not be added to more than one session'
            return
        }
      
      captureSession.sessionPreset = .hd1920x1080
      captureSession.addOutput(videoOutput)
      
      let input = try AVCaptureDeviceInput(device: captureDevice!)
      captureSession.addInput(input)
      
      captureSession.startRunning()
    } catch {
      print("error connecting to capture device")
    }
  }
}

// MARK: Video Data Delegate

extension VisionMLViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
  
  // called for each frame of video
  func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    
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
    
    // keep track of performance and log the frame rate
    if trackPerformance {
      frameCount = frameCount + 1
      if frameCount % framesPerSample == 0 {
        let diff = currentDate - startDate
        if (diff > 0) {
          if pace > 0.0 {
            print("WARNING: Frame rate of image classification is being limited by \"pace\" setting. Set to 0.0 for fastest possible rate.")
          }
          print("\(String.localizedStringWithFormat("%0.2f", (diff/Double(framesPerSample))))s per frame (average)")
        }
        startDate = currentDate
      }
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
    
    
}

let context = CIContext()
var rotateTransform: CGAffineTransform?
var scaleTransform: CGAffineTransform?
var cropTransform: CGAffineTransform?
var resultBuffer: CVPixelBuffer?

func croppedSampleBuffer(_ sampleBuffer: CMSampleBuffer, targetSize: CGSize) -> CVPixelBuffer? {
  
  guard let imageBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
    fatalError("Can't convert to CVImageBuffer.")
  }
  
  // Only doing these calculations once for efficiency.
  // If the incoming images could change orientation or size during a session, this would need to be reset when that happens.
  if rotateTransform == nil {
    let imageSize = CVImageBufferGetEncodedSize(imageBuffer)
    let rotatedSize = CGSize(width: imageSize.height, height: imageSize.width)
    
    guard targetSize.width < rotatedSize.width, targetSize.height < rotatedSize.height else {
      fatalError("Captured image is smaller than image size for model.")
    }
    
    let shorterSize = (rotatedSize.width < rotatedSize.height) ? rotatedSize.width : rotatedSize.height
    rotateTransform = CGAffineTransform(translationX: imageSize.width / 2.0, y: imageSize.height / 2.0).rotated(by: -CGFloat.pi / 2.0).translatedBy(x: -imageSize.height / 2.0, y: -imageSize.width / 2.0)
    
    let scale = targetSize.width / shorterSize
    scaleTransform = CGAffineTransform(scaleX: scale, y: scale)
    
    // Crop input image to output size
    let xDiff = rotatedSize.width * scale - targetSize.width
    let yDiff = rotatedSize.height * scale - targetSize.height
    cropTransform = CGAffineTransform(translationX: xDiff/2.0, y: yDiff/2.0)
  }
  
  // Convert to CIImage because it is easier to manipulate
  let ciImage = CIImage(cvImageBuffer: imageBuffer)
  let rotated = ciImage.transformed(by: rotateTransform!)
  let scaled = rotated.transformed(by: scaleTransform!)
  let cropped = scaled.transformed(by: cropTransform!)
  
  // Note that the above pipeline could be easily appended with other image manipulations.
  // For example, to change the image contrast. It would be most efficient to handle all of
  // the image manipulation in a single Core Image pipeline because it can be hardware optimized.
  
  // Only need to create this buffer one time and then we can reuse it for every frame
  if resultBuffer == nil {
    let result = CVPixelBufferCreate(kCFAllocatorDefault, Int(targetSize.width), Int(targetSize.height), kCVPixelFormatType_32BGRA, nil, &resultBuffer)
    
    guard result == kCVReturnSuccess else {
      fatalError("Can't allocate pixel buffer.")
    }
  }
  
  // Render the Core Image pipeline to the buffer
  context.render(cropped, to: resultBuffer!)
  
  //  For debugging
  //  let image = imageBufferToUIImage(resultBuffer!)
  //  print(image.size) // set breakpoint to see image being provided to CoreML
  
  return resultBuffer
}

// Only used for debugging.
// Turns an image buffer into a UIImage that is easier to display in the UI or debugger.
func imageBufferToUIImage(_ imageBuffer: CVImageBuffer) -> UIImage {
  
  CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
  
  let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)
  let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
  
  let width = CVPixelBufferGetWidth(imageBuffer)
  let height = CVPixelBufferGetHeight(imageBuffer)
  
  let colorSpace = CGColorSpaceCreateDeviceRGB()
  let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
  
  let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
  
  let quartzImage = context!.makeImage()
  CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
  
  let image = UIImage(cgImage: quartzImage!, scale: 1.0, orientation: .right)
  
  return image
}

extension VisionMLViewController {
    //Firebase MLKit functions
    
    private func removeDetectionAnnotations() {
        for annotationView in annotationOverlayView.subviews {
            annotationView.removeFromSuperview()
        }
    }
    
    private func updatePreviewOverlayView() {
        guard let lastFrame = lastFrame,
            let imageBuffer = CMSampleBufferGetImageBuffer(lastFrame)
            else {
                return
        }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return
        }
        let rotatedImage =
            UIImage(cgImage: cgImage, scale: Constant.originalScale, orientation: .right)
        previewOverlayView.image = rotatedImage
    }
    
    private func convertedPoints(
        from points: [NSValue]?,
        width: CGFloat,
        height: CGFloat
        ) -> [NSValue]? {
        return points?.map {
            let cgPointValue = $0.cgPointValue
            let normalizedPoint = CGPoint(x: cgPointValue.x / width, y: cgPointValue.y / height)
            let cgPoint = previewLayer.layerPointConverted(fromCaptureDevicePoint: normalizedPoint)
            let value = NSValue(cgPoint: cgPoint)
            return value
        }
    }
    
    private enum Constant {
        static let alertControllerTitle = "Vision Detectors"
        static let alertControllerMessage = "Select a detector"
        static let cancelActionTitleText = "Cancel"
        static let videoDataOutputQueueLabel = "com.google.firebaseml.visiondetector.VideoDataOutputQueue"
        static let sessionQueueLabel = "com.google.firebaseml.visiondetector.SessionQueue"
        static let noResultsMessage = "No Results"
        static let smallDotRadius: CGFloat = 4.0
        static let originalScale: CGFloat = 1.0
    }
}

extension VisionMLViewController {
    //Siri Shortcuts
    
    //Using acitivites instead of intents as Siri opens app directly for activity. For intents, it shows button to open app, which we do not want s
    func createActivityForQuestion(siriShortcut: SiriShortcut) -> NSUserActivity {
        let activity = NSUserActivity(activityType: siriShortcut.activityType)
        activity.title = siriShortcut.title
        activity.userInfo = siriShortcut.dictionary
        activity.suggestedInvocationPhrase = siriShortcut.invocation
        activity.persistentIdentifier = siriShortcut.activityType
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        view.userActivity = activity
        activity.becomeCurrent()
        return activity
    }
    
    // Add an "Add to Siri" button to a view.
    func addSiriButton(shortcut: SiriShortcut, to view: UIView) {
        let button = INUIAddVoiceShortcutButton(style: .blackOutline)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isUserInteractionEnabled = true
        let activity = createActivityForQuestion(siriShortcut: shortcut)
        button.shortcut = INShortcut(userActivity: activity)
        button.delegate = self
        
        //view.addSubview(button)
        //view.centerXAnchor.constraint(equalTo: button.centerXAnchor).isActive = true
        //view.centerYAnchor.constraint(equalTo: button.centerYAnchor).isActive = true
        guard let sV = view as? UIStackView else {
            return
        }
        sV.insertArrangedSubview(button, at: sV.arrangedSubviews.count)
        
        let model = modelIdentifier()
        let doesNotSupportBackTap = model.split(separator: ",")[0].contains("6") || model.split(separator: ",")[0].contains("5") //Do not need to check lower than 5 as those devices are not supported by latest OS
        guard doesNotSupportBackTap == false else {
            return
        }
        //Back tap is only supported on iPhone 8 and above
        let txt = "After creating the shortcut, we strong encourage that you attach the shortcut to the Back Tap functionality.You can find this under the Settings app -> Accessibility -> Touch -> Back Tap"
        let sentences = txt.split(separator: ".") //Doing this to ensure blind can move over 1 sentence at a time via VoiceOver
        for sentence in sentences {
            let backTapLabel = UILabel()
            backTapLabel.text = String(sentence)
            backTapLabel.textAlignment = .center
            backTapLabel.lineBreakMode = .byWordWrapping
            backTapLabel.numberOfLines = 0
            backTapLabel.font = backTapLabel.font.withSize(12)
            sV.insertArrangedSubview(backTapLabel, at: sV.arrangedSubviews.count)
            backTapLabels.append(backTapLabel)
        }
    }
    
    func modelIdentifier() -> String {
        if let simulatorModelIdentifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] { return simulatorModelIdentifier }
        var sysinfo = utsname()
        uname(&sysinfo) // ignore return value
        return String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
    }
    
    func addInstructionsTextLabel(text : String?, to view: UIView) {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 150, height: 21))
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = NSTextAlignment.center
        label.backgroundColor = UIColor.black
        label.textColor = UIColor.white
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.text = text
        label.font = UIFont.preferredFont(forTextStyle: .body)
        self.view.addSubview(label)
        view.centerXAnchor.constraint(equalTo: label.centerXAnchor).isActive = true
        view.centerYAnchor.constraint(equalTo: label.centerYAnchor).isActive = true
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraintEqualToSystemSpacingAfter(view.leadingAnchor, multiplier: 1),
            view.trailingAnchor.constraintEqualToSystemSpacingAfter(view.trailingAnchor, multiplier: 1)
        ])
        self.view.accessibilityLabel = text
    }
    
    func addButtonForSettings(to view: UIView) {
        //let settingsUrl = URL(string: UIApplicationOpenSettingsURLString)!
        //UIApplication.shared.open(settingsUrl)
    }
    
    private func sayThis(string: String) {
        let utterance = AVSpeechUtterance(string: string)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        if synth.isPaused {
            synth.continueSpeaking()
        }
        synth.speak(utterance)
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
    
    /*
     Used as sample code to open view controller from siri
    */
    public func openFromSiri() {
        let alert = UIAlertController(title: "Hi There!", message: "Hey there! Glad to see you got this working!", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

extension VisionMLViewController {
    ///MARK:- Flashlight related functions
    
    func getBrightness(sampleBuffer: CMSampleBuffer) -> Double {
        let rawMetadata = CMCopyDictionaryOfAttachments(nil, sampleBuffer, CMAttachmentMode(kCMAttachmentMode_ShouldPropagate))
        let metadata = CFDictionaryCreateMutableCopy(nil, 0, rawMetadata) as NSMutableDictionary
        let exifData = metadata.value(forKey: "{Exif}") as? NSMutableDictionary
        let brightnessValue : Double = exifData?[kCGImagePropertyExifBrightnessValue as String] as! Double
        return brightnessValue
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
}

///MARK:- Add or Edit Button
extension VisionMLViewController: INUIAddVoiceShortcutButtonDelegate {
    func present(_ addVoiceShortcutViewController: INUIAddVoiceShortcutViewController, for addVoiceShortcutButton: INUIAddVoiceShortcutButton) {
        Analytics.logEvent("se4_add_to_siri_tapped", parameters: [
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
        Analytics.logEvent("se4_add_to_siri_tapped", parameters: [
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

extension VisionMLViewController: INUIAddVoiceShortcutViewControllerDelegate {
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        Analytics.logEvent("se4_add_to_siri_completed", parameters: [
            "os_version": UIDevice.current.systemVersion,
            "device_type": getDeviceType(),
            "mode": "add",
            "action": siriShortcut?.action.prefix(100)
            ])
        dismiss(animated: true, completion: nil)
    }
    
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        Analytics.logEvent("se4_add_to_siri_cancelled", parameters: [
            "os_version": UIDevice.current.systemVersion,
            "device_type": getDeviceType(),
            "mode": "add",
            "action": siriShortcut?.action.prefix(100)
            ])
        
        dismiss(animated: true, completion: nil)
    }
    
    
}

extension VisionMLViewController : INUIEditVoiceShortcutViewControllerDelegate {
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didUpdate voiceShortcut: INVoiceShortcut?, error: Error?) {
        Analytics.logEvent("se4_add_to_siri_completed", parameters: [
            "os_version": UIDevice.current.systemVersion,
            "device_type": getDeviceType(),
            "mode": "edit",
            "action": siriShortcut?.action.prefix(100)
            ])
        
        dismiss(animated: true, completion: nil)
    }
    
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
        Analytics.logEvent("se4_add_to_siri_cancelled", parameters: [
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



