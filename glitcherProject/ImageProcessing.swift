//
//  UIImageExtension.swift
//  glitcherProject
//
//  Created by Kamil Sosna on 06/03/2019.
//  Copyright © 2019 Kamil Sosna. All rights reserved.
//

import Foundation
import UIKit

protocol ImageProcessingDelegate: AnyObject {
    func loopInImageProcessing(_ percent: Float)
}
class ImageProcessing: UIImage {
    var imageToProcess: UIImage?
    weak var delegate: ImageProcessingDelegate?
    func processImageWithEffect(effect: availableEffects) -> UIImage?
    {
        if let imageToProcess = imageToProcess {
            print("Image size before processing\(imageToProcess.size)")
            if let pixelData = imageInitialProcessing(imageToProcess)
            {
                let afterEffect: [PixelData]?
                switch effect {
                case .someEffect :
                    afterEffect = someEffect(pixelData)
                case .blueCalX :
                    afterEffect = blueCalx(pixelData)
                case .nanou2 :
                    afterEffect = nanou2(pixelData)
                }
                
                
                
                if let afterEffect = afterEffect {
                    if let imageAfter: UIImage = createImageFromBitmap(pixelData: afterEffect, width: Int(imageToProcess.size.width), height: Int(imageToProcess.size.height)) {
                        print("Image Processing 100% Success")
                        print("Image size after processing \(imageAfter.size)")
                        return imageAfter

                    }
                }
            }
        }
        
        return nil
    }
    public func imageToArrayUInt8(_ image: UIImage) -> [UInt8]?
    {
        //Size of image
        let size = image.size
        print("Size of the image for which context will be created \(size)")
        let totalSize = size.width * size.height * 4
        var imagePixelData = [UInt8](repeating: 0, count: Int(totalSize))
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let cgContext = CGContext(data: &imagePixelData, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: Int(4 * size.width), space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue) else {
            print("Could not create CGContext from data")
            return nil
        }

        let ciContext = CIContext(cgContext: cgContext, options: nil)
//        guard let cgImage = image.cgImage else {
//            print("No CGImage avaiable")
//            return nil}
        if let cgImage = image.cgImage {
            cgContext.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            print("imageToArrayUInt8 Success from cgImage")
            return imagePixelData
        } else if let ciImage = image.ciImage{
            
            guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
                    print("Couldn't create CGImage from CiImage")
                    return nil
                }
            cgContext.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
                print("imageToArrayUInt8 Success from ciImage")
                return imagePixelData
                
            
        }
//        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
//        print("imageToArrayUInt8 Success")
//        return imagePixelData
        
        //Calculating size with four channels
        print("[ERROR] Couldn't create imagePixelData")
        return nil
    }
    func arrayToPixelData(_ imageArray: [UInt8]) -> [PixelData]
    {
        var index: Int = 0
        var pixelData: [PixelData] = []
        for _ in imageArray
        {
            if (index % 4) == 0
            {
                var pixel = PixelData()
                pixel.R = imageArray[index]
                pixel.G = imageArray[index + 1]
                pixel.B = imageArray[index + 2]
                pixel.A = imageArray[index + 3]
                pixelData.append(pixel)
            }
            index += 1
        }
        return pixelData
    }
    func createImageFromBitmap(pixelData: [PixelData], width: Int, height: Int) -> UIImage?
    {
        assert(width > 0)
        assert(height > 0)
        
        let pixelDataSize = MemoryLayout<PixelData>.size
        assert(pixelDataSize == 4)
        assert(pixelData.count == width * height)
        
        let data: Data = pixelData.withUnsafeBufferPointer{
            return Data(buffer: $0)
        }
        let cfData = NSData(data: data) as CFData
        let provider: CGDataProvider! = CGDataProvider(data: cfData)
        
        if let cgImage: CGImage = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: pixelDataSize * width, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue), provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
        {
            return UIImage(cgImage: cgImage)
        }
        
        return nil
    }
    func imageInitialProcessing(_ image: UIImage) -> [PixelData]?
    {
        if imageToProcess != nil {
            let fixedImage = fixOrientation(image: imageToProcess!)
            if let arrayUInt8 = imageToArrayUInt8(fixedImage)
            {
                let pixelData = arrayToPixelData(arrayUInt8)
                return pixelData
            } else {
                print("Image to array uint8 failed")
            }
        }
        print("Initial processing failed")
        return nil
    }
    func fixOrientation(image: UIImage) -> UIImage {
        assert(image.size.height > 0)
        if image.imageOrientation == UIImage.Orientation.up {
            return image
        }
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        let normalizedImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return normalizedImage;
    }

    public struct PixelData
    {
        var R: UInt8 = 0
        var G: UInt8 = 0
        var B: UInt8 = 0
        var A: UInt8 = 0
    }
    enum availableEffects {
        case someEffect
        case blueCalX
        case nanou2
    }
    func someEffect(_ inputData: [PixelData]) -> [PixelData]{
        var returnArray = inputData
        var percentDone: Float = 0
        let sizeOfData = inputData.count
        
        for i in 0..<sizeOfData{
            percentDone = Float(i) /  Float(sizeOfData)
            if (i % (sizeOfData/100)) == 0 {
                if let delegate = delegate {
                    delegate.loopInImageProcessing(percentDone)
                }
            }
            
            //delegate?.loopInImageProcessing(percentDone)
            if i % 100 == 0 {
                let random = Int(arc4random_uniform(UInt32((100))))
                if random + i < sizeOfData {
                    for j in i..<random + i{
                        returnArray[j] = inputData[random]
                    }
                }
            }
        }
        return returnArray
    }
    
    func blueCalx(_ inputData: [PixelData]) -> [PixelData]{
        var finishedEverything = inputData
        let sizeOfData = inputData.count
        var percentDone: Float = 0
        for i in 0..<sizeOfData{
            percentDone = Float(i) /  Float(sizeOfData)
            if (i % (sizeOfData/100)) == 0 {
                if let delegate = delegate {
                    delegate.loopInImageProcessing(percentDone)
                }
            }
            //        let random = arc4random_uniform(UInt32((input.count)))
            if i % 1000 == 0 {
                let randomRange = Int(arc4random_uniform(UInt32((800))))
                if i + randomRange < sizeOfData{
                    let range = i..<i + randomRange
                    var sortableRange = inputData[range]
                    sortableRange.sort{ $0.G < $1.B}
                    finishedEverything[range] = sortableRange
                }
            }
        }
        return finishedEverything
    }
    
    //sortbyalphachanges
    func nanou2(_ inputData: [PixelData]) -> [PixelData]{
        var returnArray = inputData
        let sizeOfData = inputData.count
        var percentDone: Float = 0
        for i in 0..<sizeOfData{
            percentDone = Float(i) /  Float(sizeOfData)
            if (i % (sizeOfData/100)) == 0 {
                if let delegate = delegate {
                    delegate.loopInImageProcessing(percentDone)
                }
            }
            if i % 500 == 0  {
                let random = Int(arc4random_uniform(UInt32((250))))
                print(random)
                if random + i < inputData.count {
                    var sortable = inputData[i..<random + i]
                    sortable.sort { $0.G < $1.B }
                    returnArray.replaceSubrange(i..<random + i, with: sortable)
                }
            }
        }
        return returnArray
    }
    
}
