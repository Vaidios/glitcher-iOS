//
//  ManipulatePhotoViewController.swift
//  glitcherProject
//
//  Created by Kamil Sosna on 06/03/2019.
//  Copyright © 2019 Kamil Sosna. All rights reserved.
//

import Foundation
import TransitionButton
import UIKit

class ManipulatePhotoViewController: UIViewController{
    
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var effectPicker: UIPickerView!
    @IBOutlet weak var photoPreview: UIImageView!
    var imageToManip: UIImage?
    let imageProcessor = ImageProcessor()
    var isProcessing: Bool = false
    var pickerData: [String] = [String]()
    var selectedRow: Int = 0;
    override func viewDidLoad() {
        super.viewDidLoad()
        photoPreview.image = imageToManip
        saveToLibraryOutlet.isHidden = true
        progressBar.progress = 0
        imageProcessor.delegate = self
        effectPicker.delegate = self
        effectPicker.dataSource = self
        pickerData = ["Caronte", "Dawan", "VOI_DO"]
    }
    
    @IBAction func didTapOnTakePhoto(_ sender: Any) {
        photoPreview.image = nil
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didTapOnProcessImage(_ sender: Any) {
        var processedImage: UIImage?
        guard let imageToProcess = imageToManip else {
            print("[ManipulatePhoto] unable to retrive Image from UIImageView")
            return
        }
        if !isProcessing {
            isProcessing = true
            DispatchQueue.global().async {
                switch self.selectedRow {
                case 0:
                    processedImage = self.imageProcessor.create(image: imageToProcess, with: .caronte)
                case 1:
                    processedImage = self.imageProcessor.create(image: imageToProcess, with: .dawan)
                case 2:
                    processedImage = self.imageProcessor.create(image: imageToProcess, with: .voi_do)
                default:
                    break
                }
                if processedImage != nil {
                    DispatchQueue.main.async {
                        self.photoPreview.image = processedImage
                    }
                }
                self.isProcessing = false
            }
        }
    }
    
    
    @IBOutlet weak var saveToLibraryOutlet: UIButton!
    
    @IBAction func saveToLibrary(_ sender: Any) {
        guard let imageToBeSaved = photoPreview.image else { return }
        UIImageWriteToSavedPhotosAlbum(imageToBeSaved, self, #selector(didImageSaveSuccess(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    @objc func didImageSaveSuccess(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "Saved!", message: "Your altered image has been saved to your photos.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
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

extension ManipulatePhotoViewController: ImageProcessorDelegate {
    func imageProcessor(_ imageProcessor: ImageProcessor, _ progress: Float) {
        DispatchQueue.main.async {
            if progress >= 0.99 {
                self.saveToLibraryOutlet.isHidden = false
            }
            print("[ImageProcessorDelegate] \(progress * 100)% done")
            self.progressBar.progress = progress
        }
    }
    
    
}
