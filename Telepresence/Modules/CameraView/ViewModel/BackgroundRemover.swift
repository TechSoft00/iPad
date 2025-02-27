//
//  BackgroundRemover.swift
//  Telepresence
//
//  Created by Muhammad Junaid Babar on 2/25/25.
//


import CoreImage
import Vision
import UIKit

class BackgroundRemover {
    private let ciContext = CIContext()
    private let segmentationRequest = VNGeneratePersonSegmentationRequest()

    init() {
        segmentationRequest.outputPixelFormat = kCVPixelFormatType_OneComponent8
    }

    func processFrame(_ pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])

        do {
            try requestHandler.perform([segmentationRequest])
            guard let maskPixelBuffer = segmentationRequest.results?.first?.pixelBuffer else {
                print("Failed to get segmentation mask")
                return nil
            }
            
            let maskImage = CIImage(cvPixelBuffer: maskPixelBuffer)


            return applyBackground(ciImage: ciImage, maskImage: maskImage)
        } catch {
            print("Error in segmentation request: \(error)")
            return nil
        }
    }

    private func applyBackground(ciImage: CIImage, maskImage: CIImage) -> CVPixelBuffer? {
        guard let backgroundImage = UIImage(named: "new_background") else {
            print("❌ Background image not found")
            return nil
        }
        
        let backgroundCIImage = CIImage(image: backgroundImage)!
        
        let resizedBackground = backgroundCIImage
            .transformed(by: CGAffineTransform(scaleX: ciImage.extent.width / backgroundCIImage.extent.width,
                                               y: ciImage.extent.height / backgroundCIImage.extent.height))
            .cropped(to: ciImage.extent)

        let blendedImage = ciImage.applyingFilter("CIBlendWithMask", parameters: [
            "inputBackgroundImage": resizedBackground,
            "inputMaskImage": maskImage
        ])

        var outputBuffer: CVPixelBuffer?
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary

        CVPixelBufferCreate(kCFAllocatorDefault, Int(ciImage.extent.width), Int(ciImage.extent.height),
                            kCVPixelFormatType_32BGRA, attrs, &outputBuffer)

        if let outputBuffer = outputBuffer {
            ciContext.render(blendedImage, to: outputBuffer)
            print("✅ Background applied successfully")
            return outputBuffer
        }

        print("❌ Failed to apply background")
        return nil
    }

}

