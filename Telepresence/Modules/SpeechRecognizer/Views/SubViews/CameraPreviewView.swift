//
//  CameraPreviewView.swift
//  Telepresence
//
//  Created by Muhammad Junaid Babar on 2/15/25.
//


import SwiftUI
import AVFoundation

// UIViewControllerRepresentable for displaying the camera preview
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)

        DispatchQueue.main.async {
            previewLayer.frame = view.bounds
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
