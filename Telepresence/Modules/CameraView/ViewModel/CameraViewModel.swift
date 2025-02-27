//
//  CameraViewModel.swift
//  Telepresence
//
//  Created by Muhammad Junaid Babar on 2/24/25.
//
import Foundation
import AVFoundation
import Vision
import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

final class CameraViewModel: NSObject, ObservableObject {
    private let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let context = CIContext()
    private var request: VNCoreMLRequest?
    private var backgroundImage: CIImage?
    
    @Published private var lastCapturedPixelBuffer: CVPixelBuffer?
    @Published var filteredImage: UIImage?

    override init() {
        super.init()
        setupCamera()
        loadModel()
        loadBackgroundImage(named: "new_background") // Replace with your background image name
    }
    
    // MARK: - Setup Camera
    private func setupCamera() {
        session.sessionPreset = .high
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device) else {
            print("❌ Error: Unable to access camera")
            return
        }
        
        if session.canAddInput(input) { session.addInput(input) }
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "cameraQueue"))
        if session.canAddOutput(videoOutput) { session.addOutput(videoOutput) }
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }
    
    // MARK: - Load Model
    private func loadModel() {
        guard let model = try? VNCoreMLModel(for: DeepLabV3().model) else {
            print("❌ Error: Loading CoreML model failed")
            return
        }
        request = VNCoreMLRequest(model: model, completionHandler: handleSegmentation)
        request?.imageCropAndScaleOption = .scaleFill
    }
    
    // MARK: - Load Background Image
    private func loadBackgroundImage(named name: String) {
        guard let uiImage = UIImage(named: name),
              let ciImage = CIImage(image: uiImage) else { return }
        backgroundImage = ciImage
    }
    
    // MARK: - Process Segmentation
    private func handleSegmentation(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNCoreMLFeatureValueObservation],
              let segmentationMask = results.first?.featureValue.multiArrayValue else {
            print("❌ Error: No segmentation mask received.")
            return
        }

        guard let pixelBuffer = lastCapturedPixelBuffer else {
            print("❌ Error: No captured frame available.")
            return
        }

        let personImage = CIImage(cvPixelBuffer: pixelBuffer)

        DispatchQueue.main.async {
            self.filteredImage = self.processMask(segmentationMask, person: personImage)
        }
    }
    
    private func processMask(_ mask: MLMultiArray, person: CIImage) -> UIImage? {
        guard let bgImage = backgroundImage else { return nil }

        let width = mask.shape[0].intValue
        let height = mask.shape[1].intValue

        print("📏 Processing Mask with width: \(width), height: \(height)")

        let maskData = UnsafeMutableBufferPointer<Float>(
            start: mask.dataPointer.assumingMemoryBound(to: Float.self), count: mask.count
        )
        
        // Convert MLMultiArray mask to grayscale image
        let maskImage = createMaskImage(from: maskData, width: width, height: height)
        
        // Debug: Show the mask before applying blending
        DispatchQueue.main.async {
            if let debugMaskImage = self.convertCIImageToUIImage(maskImage) {
                print("🛠 Debug: Showing mask image")
                self.filteredImage = debugMaskImage
            }
        }

        return blendImages(foreground: person, mask: maskImage, background: bgImage)
    }
    
    private func convertCIImageToUIImage(_ ciImage: CIImage) -> UIImage? {
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            print("❌ Error: Failed to convert CIImage to CGImage")
            return nil
        }
        return UIImage(cgImage: cgImage)
    }


    
    // MARK: - Create Mask Image
    private func createMaskImage(from maskData: UnsafeMutableBufferPointer<Float>, width: Int, height: Int) -> CIImage {
        let maskPixels = maskData.map { UInt8($0 * 255) }
        let maskData = Data(maskPixels)
        
        let provider = CGDataProvider(data: maskData as CFData)!
        let cgMask = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: width, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: .init(rawValue: 0), provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
        
        return CIImage(cgImage: cgMask)
    }
    
    // MARK: - Blend Images
    private func blendImages(foreground: CIImage, mask: CIImage, background: CIImage) -> UIImage? {
        let blendFilter = CIFilter.blendWithMask()
        blendFilter.inputImage = foreground // Person’s image
        blendFilter.maskImage = mask       // Grayscale mask
        blendFilter.backgroundImage = background

        guard let output = blendFilter.outputImage,
              let cgImage = context.createCGImage(output, from: output.extent) else {
            print("❌ Error: Failed to create blended image")
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Camera Delegate
extension CameraViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let request = request else {
            print("❌ Error: No frame captured")
            return
        }

        DispatchQueue.main.async {
            self.lastCapturedPixelBuffer = pixelBuffer // Store the latest frame
        }

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])

        do {
            try handler.perform([request])
        } catch {
            print("❌ Error performing Vision request: \(error.localizedDescription)")
        }
    }
}
