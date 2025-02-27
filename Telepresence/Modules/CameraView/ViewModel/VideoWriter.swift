//
//  VideoWriter.swift
//  Telepresence
//
//  Created by Muhammad Junaid Babar on 2/25/25.
//


import AVFoundation

class VideoWriter {
    private var assetWriter: AVAssetWriter?
    private var assetWriterInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?

    private let outputURL: URL

    init() {
        outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mov")
        setupWriter()
    }

    private func setupWriter() {
        do {
            assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
            let settings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: 1080,
                AVVideoHeightKey: 1920
            ]
            assetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
            pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterInput!,
                                                                      sourcePixelBufferAttributes: nil)
            if assetWriter!.canAdd(assetWriterInput!) {
                assetWriter!.add(assetWriterInput!)
            }
            assetWriter?.startWriting()
            assetWriter?.startSession(atSourceTime: .zero)
        } catch {
            print("Error setting up asset writer: \(error)")
        }
    }

    func appendBuffer(_ buffer: CVPixelBuffer, with timestamp: CMTime) {
        if assetWriterInput!.isReadyForMoreMediaData {
            pixelBufferAdaptor?.append(buffer, withPresentationTime: timestamp)
        }
    }

    func finishRecording() {
        assetWriterInput?.markAsFinished()
        assetWriter?.finishWriting {
            print("Video saved to: \(self.outputURL)")
        }
    }
}
