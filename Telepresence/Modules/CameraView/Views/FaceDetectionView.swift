//
//  FaceDetectionView.swift
//  Telepresence
//
//  Created by ELC on 05/03/2025.
//

import SwiftUI
import AVFoundation
import Vision

struct FaceDetectionView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var captureSession = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    var lastFaceSize: CGFloat? // Store last detected face size
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCamera()
    }
    
    func setupCamera() {
        captureSession.sessionPreset = .high
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            return
        }
        
        captureSession.addInput(videoInput)
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(videoOutput)
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let request = VNDetectFaceRectanglesRequest { (request, error) in
            guard let results = request.results as? [VNFaceObservation], let firstFace = results.first else { return }
            
            DispatchQueue.main.async {
                self.processFaceDetection(face: firstFace)
            }
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
    
    func processFaceDetection(face: VNFaceObservation) {
        let boundingBox = face.boundingBox
        let faceWidth = boundingBox.width
        
        if let lastSize = lastFaceSize {
            let distanceFactor = lastSize / faceWidth
            
            // Assume initial distance as 1 foot when faceWidth is 0.5 (You may need to calibrate this)
            let estimatedDistance = 1 * distanceFactor
            
            if estimatedDistance >= 5 {
                print("User is 5 feet away!")
                showAlert()
            }
        }
        
        lastFaceSize = faceWidth
    }
    
    func showAlert() {
        let alert = UIAlertController(title: "Too Far!", message: "You are 5 feet away, please come closer.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }
}

#Preview {
    FaceDetectionView()
}
