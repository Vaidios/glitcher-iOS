//
//  CameraRollViewController.swift
//  glitcherProject
//
//  Created by Kamil Sosna on 06/03/2019.
//  Copyright © 2019 Kamil Sosna. All rights reserved.
//

import Foundation
import UIKit

class CameraRollViewController: UIViewController {
    
    @IBOutlet weak var chosenPhoto: UIImageView!
    
    let imagePicker = UIImagePickerController()
    override func viewDidLoad() {
        imagePicker.delegate = self
    }
    
    @IBAction func uploadImageButton(_ sender: Any) {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func goTakePhoto(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
}

extension CameraRollViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            chosenPhoto.contentMode = .scaleAspectFill
            chosenPhoto.image = pickedImage
        }
        dismiss(animated: true, completion: nil)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
}
