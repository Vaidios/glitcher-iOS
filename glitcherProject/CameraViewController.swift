//
//  ViewController.swift
//  glitcherProject
//
//  Created by Kamil Sosna on 05/03/2019.
//  Copyright © 2019 Kamil Sosna. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class CameraViewController: UIViewController
{
    //BUTTONs HANDLERS BEGIN
    @IBOutlet weak var takePhotoOutlet: UIButton!
    
    @IBOutlet weak var cameraRollOutlet: UIButton!
    
    @IBOutlet weak var useTakenPhotoOutlet: UIButton!
    
    @IBOutlet weak var repeatPhotoOutlet: UIButton!
    //BUTTONs HANDLERS END
    
    @IBOutlet weak var takenPhoto: UIImageView!
    
    @IBOutlet weak var previewView: PreviewCameraView!
    
    var stillImageOutput: AVCapturePhotoOutput?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    let imagePicker = UIImagePickerController()
    private var photoData: Data?
    private var photoDataUIImage: UIImage?
    
    override func viewDidLoad() {
         super.viewDidLoad()
        imagePicker.delegate = self
        takenPhoto.isHidden = true
        repeatPhotoOutlet.isHidden = true
        useTakenPhotoOutlet.isHidden = true
        
        self.previewView.videoPreviewLayer.session = self.session
        previewView.videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.configureSession()
        session.startRunning()
        
        
    }
    private let photoOutput = AVCapturePhotoOutput()
    //private let sessionQueue = DispatchQueue(label: "sessionqueue")
    
    @IBAction func didTapOnTakePhotoButton(_ sender: UIButton)
    {
        let videoPreviewLayerOrientation = previewView.videoPreviewLayer.connection?.videoOrientation
        sessionQueue.async {
            if let photoOutputConnection = self.photoOutput.connection(with: .video) {
                photoOutputConnection.videoOrientation = videoPreviewLayerOrientation!
            }
            var photoSettings = AVCapturePhotoSettings()
            
            if self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            }
            if self.videoDeviceInput.device.isFlashAvailable {
                photoSettings.flashMode = .off
            }
            self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
            print("Photo capture")
        }
        
        sender.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        
        UIView.animate(withDuration: 2.0,
                       delay: 0,
                       usingSpringWithDamping: CGFloat(0.20),
                       initialSpringVelocity: CGFloat(6.0),
                       options: UIView.AnimationOptions.allowUserInteraction,
                       animations: {
                        sender.transform = CGAffineTransform.identity
        },
                       completion: { Void in()  }
        )
        
    }
    
    @IBAction func didTapOnRepeatButton(_ sender: Any) {
        cleanUpToCamera()
    }
    
    @IBAction func showCameraRoll(_ sender: Any) {
        checkPermission()
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    private let session = AVCaptureSession()
    private var isSessionRunning = false
    
    private let sessionQueue = DispatchQueue(label: "sessionQueue") //communicate with session queue and other session objects on this queue
    
    private var setupResults: SessionSetupResult = .success
    @objc dynamic var videoDeviceInput: AVCaptureDeviceInput!
    
    //Call this on session queue
    /// - Tag: ConfigureSession
    private func configureSession() {
        if setupResults != .success {
            return
        }
        
        session.beginConfiguration()
        
        /*
         We do not create an AVCaptureMovieFileOutput because liveSession is not supported
         */
        session.sessionPreset = .photo
        
        //ADd video input
        
        do {
            var defaultVideoDevice: AVCaptureDevice?
            
            //Choose the back dual camera if available, otherwises dealut to wide angle
            
            if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
                defaultVideoDevice = dualCameraDevice
            } else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                defaultVideoDevice = backCameraDevice
            } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                defaultVideoDevice = frontCameraDevice
            }
            guard let videoDevice = defaultVideoDevice else {
                print("Couldn't obtain default video device")
                setupResults = .configurationFailed
                session.commitConfiguration()
                return
            }
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
                DispatchQueue.main.async {
                    let statusBarOrientation = UIApplication.shared.statusBarOrientation
                    var initialVideoOrientation: AVCaptureVideoOrientation = .portrait
                    if statusBarOrientation != .unknown {
                        if let videoOrientation = AVCaptureVideoOrientation(interfaceOrientation: statusBarOrientation) {
                            initialVideoOrientation = videoOrientation
                        }
                    }
                    
                    self.previewView.videoPreviewLayer.connection?.videoOrientation = initialVideoOrientation
                }
            } else {
                print("Couldn't add video device input to the session")
                setupResults = .configurationFailed
                session.commitConfiguration()
                return
            }
            
        } catch {
            print("Couldn't create video device input to the session: \(error)")
            setupResults = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            
            photoOutput.isHighResolutionCaptureEnabled = false
            photoOutput.isLivePhotoCaptureEnabled = false
            
        } else {
            print("Could not add output to the session")
            setupResults = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        session.commitConfiguration()
    }
    
    //Add photo output
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toManipPhoto" {
            if let vc = segue.destination as? ManipulatePhotoViewController
            {
                vc.photoData = self.photoData
                vc.photoDataUIImage = self.photoDataUIImage
                cleanUpToCamera()
            }
        }
    }
    private func cleanUpWithReadyPhoto() {
        useTakenPhotoOutlet.isHidden = false
        takenPhoto.isHidden = false
        repeatPhotoOutlet.isHidden = false
        previewView.isHidden = true
        takePhotoOutlet.isHidden = true
    }
    private func cleanUpToCamera() {
        takenPhoto.isHidden = true
        previewView.isHidden = false
        takePhotoOutlet.isHidden = false
        repeatPhotoOutlet.isHidden = true
        useTakenPhotoOutlet.isHidden = true
    }
    
}

extension AVCaptureVideoOrientation {
    init?(deviceOrientation: UIDeviceOrientation) {
        switch deviceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeLeft
        case .landscapeRight: self = .landscapeRight
        default: return nil
        }
    }
    init?(interfaceOrientation: UIInterfaceOrientation) {
        switch interfaceOrientation {
        case .portrait: self = .portrait
        case .landscapeLeft: self = .landscapeLeft
        case .landscapeRight: self = .landscapeRight
        case .portraitUpsideDown: self = .portraitUpsideDown
        default: return nil
        }
    }
    
    
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    
    
    
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error returning photo \(error)")
        } else {
            if let photoData = photo.fileDataRepresentation()
            {
                self.photoData = photoData
                useTakenPhotoOutlet.isHidden = false
                previewView.isHidden = true
                takenPhoto.isHidden = false
                repeatPhotoOutlet.isHidden = false
                takePhotoOutlet.isHidden = true
                takenPhoto.image = UIImage(data: photoData)
                self.photoData = photoData
                self.photoDataUIImage = UIImage(data: photoData)
                print("Photo captured from delegate")
            }
            
        }
    }
}

extension CameraViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func checkPermission() {
        let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        switch photoAuthorizationStatus {
        case .authorized :
            print("Access to photoLib granted")
            return
        case .notDetermined : PHPhotoLibrary.requestAuthorization({(newStatus) in print("New access to photoLib is \(newStatus)")
        })
        case .restricted :
            print("User can't use library")
        case .denied :
            print("User denied access to photoLib")
            
        }
    }
    
    @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage{
            cleanUpWithReadyPhoto()
            self.takenPhoto.image = pickedImage
            self.photoDataUIImage = pickedImage
            //takenPhoto.image = UIImage(data: pickedImage)
            dismiss(animated: true, completion: nil)
        }
        let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as! CGImage
        print(pickedImage.bitsPerComponent)
    }
    @objc func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}


