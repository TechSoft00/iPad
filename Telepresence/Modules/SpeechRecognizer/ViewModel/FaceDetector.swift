//
//  FaceDetector.swift
//  Telepresence
//
//  Created by Muhammad Junaid Babar on 2/7/25.
//


import Foundation
import AVFoundation
import Vision
import Combine
import UIKit

// MARK: - Face Detector
// This class detects a face using the front camera and determines if it is close to the device.
class FaceDetector: NSObject, ObservableObject {
    
    // Published property to notify UI if a face is detected close
    @Published var isFaceClose = false
    
    // Combine Publisher to notify listeners about face detection state changes
    let faceDetectionSubject = PassthroughSubject<Bool, Never>()

    // MARK: - Capture Session Setup
    // AVCaptureSession manages input/output for real-time video processing
    private let captureSession = AVCaptureSession()
    
    // Video data output for receiving camera frames
    private let videoOutput = AVCaptureVideoDataOutput()
    
    // Dispatch queue for running the capture session setup asynchronously
    private let sessionQueue = DispatchQueue(label: "com.example.FaceDetectionSession")

    // MARK: - Initializer
    /// Initializes the face detector and starts detection.
    override init() {
        super.init()
        startDetection()
    
        NotificationCenter.default.addObserver(self,
                                                   selector: #selector(orientationDidChange),
                                                   name: UIDevice.orientationDidChangeNotification,
                                                   object: nil)
    }

    // MARK: - Start & Stop Detection
    /// Starts face detection by setting up the camera session asynchronously.
    func startDetection() {
        sessionQueue.async {
            self.setupCamera()
        }
    }

    /// Stops the face detection session safely.
    func stopDetection() {
        sessionQueue.async {
            self.captureSession.stopRunning()
        }
    }

    // MARK: - Camera Setup
    /// Configures the AVCaptureSession with the front camera for face detection.
    private func setupCamera() {
        // Ensure a front camera is available
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("No front camera available.")
            return
        }

        do {
            // Create an input source from the front camera
            let input = try AVCaptureDeviceInput(device: device)
            
            // Reset the session before adding new input
            captureSession.beginConfiguration()
            
            // Remove existing inputs and outputs to avoid conflicts
            captureSession.inputs.forEach { captureSession.removeInput($0) }
            captureSession.outputs.forEach { captureSession.removeOutput($0) }

            // Add the input to the session if possible
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }

            // Configure the video output to process frames
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            
            // Add the video output to the session if possible
            if captureSession.canAddOutput(videoOutput) {
                captureSession.connections.first?.videoOrientation = .landscapeRight
                captureSession.addOutput(videoOutput)
            }

           
            // Commit the session configuration
            captureSession.commitConfiguration()

            // Start running the capture session
            captureSession.startRunning()
        } catch {
            print("Error setting up camera: \(error)")
        }
    }

    // MARK: - Face Detection Logic
    /// Processes a video frame and detects faces.
    /// - Parameter sampleBuffer: The CMSampleBuffer containing video frame data.
    private func detectFace(in sampleBuffer: CMSampleBuffer) {
        // Convert the sample buffer into an image buffer (pixel buffer)
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Create a Vision request for detecting face rectangles
        let request = VNDetectFaceRectanglesRequest { [weak self] request, _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                // Get the first detected face (if any)
                guard let faceObservation = (request.results as? [VNFaceObservation])?.first else {
                    // No face detected; reset `isFaceClose` only if it was previously true
                    if self.isFaceClose {
                        self.isFaceClose = false
                        self.faceDetectionSubject.send(false) // Notify subscribers
                    }
                    return
                }

                // Get the bounding box of the detected face
                let faceBoundingBox = faceObservation.boundingBox

                // Calculate face size based on bounding box
                let faceSize = faceBoundingBox.width * faceBoundingBox.height

                // Define a threshold for detecting if a face is "close"
                let minFaceSizeThreshold: CGFloat = 0.10 // Adjust for ~5 feet distance
                
                // Determine if the detected face is close
                let isClose = faceSize >= minFaceSizeThreshold

                // Only update and send notification if the state has changed
                if self.isFaceClose != isClose {
                    self.isFaceClose = isClose
                    self.faceDetectionSubject.send(isClose)
                }
            }
        }

        // Create an image request handler with the pixel buffer
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])

        // Perform the face detection request
        try? handler.perform([request])
    }
    
    func getCaptureSession() -> AVCaptureSession {
        return captureSession
    }
    
    
    @objc private func orientationDidChange() {
        DispatchQueue.main.async {
            guard let connection = self.videoOutput.connection(with: .video) else { return }
            
            switch UIDevice.current.orientation {
            case .portrait:
                connection.videoOrientation = .portrait
            case .portraitUpsideDown:
                connection.videoOrientation = .portraitUpsideDown
            case .landscapeLeft:
                connection.videoOrientation = .landscapeRight
                self.captureSession.connections.first?.videoOrientation = .landscapeRight
            case .landscapeRight:
                connection.videoOrientation = .landscapeLeft
                self.captureSession.connections.first?.videoOrientation = .landscapeLeft
            default:
                break
            }
        }
    }

    
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
// Delegate to process video frames for face detection.
extension FaceDetector: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    /// Called when a new video frame is captured.
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        detectFace(in: sampleBuffer) // Process the captured frame for face detection
    }
}
