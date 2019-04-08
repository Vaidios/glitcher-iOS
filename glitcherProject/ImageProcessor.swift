//
//  UIImageExtension.swift
//  glitcherProject
//
//  Created by Kamil Sosna on 31/03/2019.
//  Copyright © 2019 Kamil Sosna. All rights reserved.
//

import UIKit

private struct PixelData {
    //Red, green, blue and alpha channels
    let R, G, B, A: UInt8
}
public enum Effect {
    case caronte, dawan, voi_do
}

protocol ImageProcessorDelegate: AnyObject {
    func imageProcessor(_ imageProcessor: ImageProcessor, _ progress: Float)
}

class ImageProcessor: UIImage {
    var delegate: ImageProcessorDelegate?
    public func create(image: UIImage, with effect: Effect) -> UIImage? {
        let fixedImage = image.fixOrientation()
        //let smallerImage = UIImage.jp
        let width = Int(fixedImage.size.width)
        let height = Int(fixedImage.size.height)
//        let width = Int(smallerImage.size.width)
//        let height = Int(smallerImage.size.height)
//        guard let dataBefore = smallerImage.createPixelData() else { return nil }
        guard let dataBefore = fixedImage.createPixelData() else { return nil }
        var dataAfter = [PixelData]()
        switch effect {
        case .caronte:
            dataAfter = effectCaronte(dataBefore)
        case .dawan:
            dataAfter = effectDawan(dataBefore)
        default:
            print("[ImageProcessor] wrong enum")
        }
        guard let returnImage = UIImage.createImageFrom(pixelData: dataAfter, width: width, height: height) else { return nil }
        print("Orientation of an image is \(returnImage.imageOrientation.hashValue)")
        return returnImage.fixOrientation()
    }
}

//MARK: - Image Effects
//TODO: - Add more effects
extension ImageProcessor {
    private func effectCaronte(_ data: [PixelData]) -> [PixelData] {
        var finishedEverything = data
        let sizeOfData = data.count
        var percentDone: Float = 0
        for i in 0..<sizeOfData{
            percentDone = Float(i) /  Float(sizeOfData)
            if (i % (sizeOfData/100)) == 0 {
                if let delegate = delegate {
                    delegate.imageProcessor(self, percentDone)
                }
            }
            if i % 1000 == 0 {
                let randomRange = Int(arc4random_uniform(UInt32((800))))
                if i + randomRange < sizeOfData{
                    let range = i..<i + randomRange
                    var sortableRange = data[range]
                    sortableRange.sort{ $0.G < $1.B}
                    finishedEverything[range] = sortableRange
                }
            }
        }
        
        return finishedEverything
    }
    private func effectDawan(_ inputData: [PixelData]) -> [PixelData] {
        var returnArray = inputData
        let dataLength = inputData.count
        var percentDone: Float = 0
        for i in 0 ..< dataLength {
            percentDone = Float(i) /  Float(dataLength)
            if (i % (dataLength/100)) == 0 {
                if let delegate = delegate {
                    delegate.imageProcessor(self, percentDone)
                }
            }
            
            if i % 500 == 0  {
                let random = Int(arc4random_uniform(UInt32((250))))
                if random + i < dataLength {
                    var sortable = inputData[ i ..< random + i ]
                    sortable.sort { $0.G < $1.B }
                    returnArray.replaceSubrange(i ..< random + i, with: sortable)
                }
            }
        }
        return returnArray
    }
}

//MARK: - UIImage Extension
extension UIImage {
    
    fileprivate static func createImageFrom(pixelData: [PixelData], width: Int, height: Int) -> UIImage? {
        let pixelDataSize = MemoryLayout<PixelData>.size
        let data = pixelData.withUnsafeBufferPointer {
            return Data(buffer: $0)
        }
        let cfData = NSData(data: data) as CFData
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let provider = CGDataProvider(data: cfData) else {
            print("[ImageProcessor] unable to create CGDataProvider")
            return nil
        }
        guard let cgImage = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: pixelDataSize * 8, bytesPerRow: width * 4, space: colorSpace, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue), provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent) else {
            print("[ImageProcessor] Unable to create CGImage")
            return nil
        }
        print("[ImageProcessor] Image created from pixelData")
        return UIImage(cgImage: cgImage)
    }
    
    fileprivate func createPixelData() -> [PixelData]? {
        let image = self
        let width = Int(image.size.width)
        let height = Int(image.size.height)
        let channelCount = Int(width * height * 4)
        var imageUIntData = [UInt8](repeating: 0, count: channelCount)
        var imagePixelData = [PixelData]()
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let imageContext = CGContext(data: &imageUIntData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue) else {
            print("[ImageProcessor] failed creating CGContext")
            return nil
        }
        guard let cgImage = self.cgImage else {
            print("[ImageProcessor] underlying CGImage does not exist")
            return nil
        }
        let imageFrame = CGRect(x: 0, y: 0, width: width, height: height)
        imageContext.draw(cgImage, in: imageFrame)
        
        for (index, _) in imageUIntData.enumerated() {
            if (index % 4 == 0) {
                let R = imageUIntData[index]
                let G = imageUIntData[index + 1]
                let B = imageUIntData[index + 2]
                let A = imageUIntData[index + 3]
                let pixel = PixelData(R: R, G: G, B: B, A: A)
                imagePixelData.append(pixel)
            }
        }
        print("[ImageProcessor] pixelData created successfully, in total \(imagePixelData.count) pixels.")
        return imagePixelData
    }
    
    fileprivate func fixOrientation() -> UIImage {
        let image = self
        if image.imageOrientation == UIImage.Orientation.up {
            print("[ImageProcessor] orientation is correct")
            return image
        }
        let fixedImage = UIImage(cgImage: image.cgImage!, scale: image.scale, orientation: .up)
        print("[ImageProcessor] orientation fixed")
        return fixedImage
    }
}
