//
//  ManipulatePhotoViewController.swift
//  glitcherProject
//
//  Created by Kamil Sosna on 06/03/2019.
//  Copyright © 2019 Kamil Sosna. All rights reserved.
//

import Foundation
import UIKit

class ManipulatePhotoViewController: UIViewController {
    var imageProcessor: ImageProcessing = ImageProcessing()
    
    @IBOutlet weak var progressBar: UIProgressView!
    
    @IBOutlet weak var effectPicker: UIPickerView!
    var isProcessing: Bool = false
    var pickerData: [String] = [String]()
    var selectedRow: Int = 0;
    @IBOutlet weak var photoPreview: UIImageView!
    var photoData: Data?
    var photoDataUIImage: UIImage?
    override func viewDidLoad() {
        super.viewDidLoad()
        progressBar.progress = 0
        imageProcessor.delegate = self
        if imageProcessor.delegate != nil {
            print("Image processor set")
        }
        effectPicker.delegate = self
        effectPicker.dataSource = self
        if let photoDataUIImage = self.photoDataUIImage {
            photoPreview.image = photoDataUIImage
            imageProcessor.imageToProcess = photoDataUIImage
        }
        
        pickerData = ["someEffect", "blueCalX", "nanou2"]
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    @IBAction func goToTakePhoto(_ sender: Any) {
        photoPreview.image = nil
        photoDataUIImage = nil
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func processImageButton(_ sender: Any) {
        var processedImage: UIImage?
        if !isProcessing {
            isProcessing = true
            if imageProcessor.imageToProcess != nil {
                    DispatchQueue.global().async {
                        switch self.selectedRow {
                        case 0:
                            print(self.selectedRow)
                            processedImage = self.imageProcessor.processImageWithEffect(effect: .someEffect)
                        case 1: print(self.selectedRow)
                        processedImage = self.imageProcessor.processImageWithEffect(effect: .blueCalX)
                        case 2:
                            processedImage = self.imageProcessor.processImageWithEffect(effect: .nanou2)
                        default: print("Nothing chosen \(self.selectedRow)")
                        }
                        if processedImage != nil {
                            print("Done processing")
                        } else {
                            print("Processing failed")
                        }
                        self.isProcessing = false
                        DispatchQueue.main.async {
                            self.photoPreview.image = processedImage
                        }
                    }
                
            }
        }
        
    }
}

extension ManipulatePhotoViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedRow = row
    }
    
}

extension ManipulatePhotoViewController: ImageProcessingDelegate {
    func loopInImageProcessing(_ percent: Float) {
        DispatchQueue.main.async {
            self.progressBar.progress = percent
            print(percent)
        }
        
    }
}
