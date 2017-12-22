//
//  ViewController.swift
//  vision-app-dev
//
//  Created by Manohar Kurapati on 18/12/2017.
//  Copyright © 2017 Manosoft. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML
import Vision

enum FlashState{
    case off
    case on
}

class CameraVC: UIViewController {

    var captureSession: AVCaptureSession!
    var cameraOutput: AVCapturePhotoOutput!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    var photoData: Data?
    var flashControlStatus: FlashState = .off
    
    var speechSynthesizer = AVSpeechSynthesizer()
    
    
    @IBOutlet weak var captureImageView: RoundedShadowImageView!
    @IBOutlet weak var flashButton: RoundedShadowButton!
    @IBOutlet weak var identificationLbl: UILabel!
    @IBOutlet weak var confidenceLbl: UILabel!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var roundedLblView: RoundedShadowView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        previewLayer.frame = cameraView.bounds
        speechSynthesizer.delegate = self
        spinner.isHidden = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapCameraView))
        tap.numberOfTapsRequired = 1
        
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSession.Preset.hd1920x1080
        
        let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
        
        do{
            let input = try AVCaptureDeviceInput(device: backCamera!)
            if captureSession.canAddInput(input) == true {
                captureSession.addInput(input)
            }
            
            cameraOutput = AVCapturePhotoOutput()
            if captureSession.canAddOutput(cameraOutput) == true {
                captureSession.addOutput(cameraOutput!)
                
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
                previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
                previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                
                cameraView.layer.addSublayer(previewLayer!)
                cameraView.addGestureRecognizer(tap)
                
                captureSession.startRunning()
            }
            
        } catch {
            debugPrint(error)
        }
    }//viewWillAppear
    
    @objc func didTapCameraView(){
        
        self.cameraView.isUserInteractionEnabled = false
        self.spinner.isHidden = false
        self.spinner.startAnimating()
        
        let settings = AVCapturePhotoSettings()
        settings.previewPhotoFormat = settings.embeddedThumbnailPhotoFormat
        
        if flashControlStatus == .off {
            settings.flashMode = .off
        } else {
            settings.flashMode = .on
        }
        
        cameraOutput.capturePhoto(with: settings, delegate: self)
    }//didTapCameraview
    
    
    func resultsMethod(request: VNRequest, error: Error?){
        guard let results = request.results as? [VNClassificationObservation] else { return }
        
        for classification in results{
            
            print(classification.identifier)
            if classification.confidence < 0.5 {
                let unknownMessage = "I'm not sure what this is. Please try again."
                
                self.identificationLbl.text = unknownMessage
                self.confidenceLbl.text = ""
                
                synthesizeSpeech(forString: unknownMessage)
                
                break
            } else {
                let identificationString = classification.identifier
                let confidenceValue = Int(classification.confidence * 100)
                
                self.identificationLbl.text = identificationString
                self.confidenceLbl.text = "CONFIDENCE: \(confidenceValue) %"
                
                let completeSentance = "This looks like a \(identificationString) and I'm \(confidenceValue) percent sure."
                synthesizeSpeech(forString: completeSentance)
                break
            }
        }
    }//resultsMethod
    
    func synthesizeSpeech(forString inputString: String){
        let speechUtterance = AVSpeechUtterance(string: inputString)
        speechSynthesizer.speak(speechUtterance)
        
    }
    
    
    
    @IBAction func flashButtonPressed(_ sender: Any) {
        switch flashControlStatus {
        case .off:
            flashButton.setTitle("FLASH ON", for: .normal)
            flashControlStatus = .on
            
        case .on:
            flashButton.setTitle("FLASH OFF", for: .normal)
            flashControlStatus = .off
        }
    }
    
}//CameraVC

//MARK: AVCapture delegates
extension CameraVC: AVCapturePhotoCaptureDelegate{

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {

        if let error = error {
            debugPrint(error)
        } else {
            photoData = photo.fileDataRepresentation()
            
            do {
                
                let model = try VNCoreMLModel(for: SqueezeNet().model)
                let request = VNCoreMLRequest(model: model, completionHandler: resultsMethod)
                let handler = VNImageRequestHandler(data: photoData!)
                
                try handler.perform([request])
                
            } catch {
                debugPrint(error)
            }
            
            let image = UIImage(data: photoData!)
            self.captureImageView.image = image
        }
    }//photoOutput
}

extension CameraVC: AVSpeechSynthesizerDelegate {
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        self.cameraView.isUserInteractionEnabled = true
        self.spinner.isHidden = true
        self.spinner.stopAnimating()
    }
   
    
}








