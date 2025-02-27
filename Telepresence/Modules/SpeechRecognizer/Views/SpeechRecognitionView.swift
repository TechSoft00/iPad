//
//  SpeechRecognitionView.swift
//  Telepresence
//
//  Created by Ditmar Jubica on 2/3/25.
//

import SwiftUI
import Combine
import AVFoundation
import AVKit

struct SpeechRecognitionView: View {
    // MARK: - State Objects
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @StateObject private var externalScreenManager = ExternalScreenManager()
    @StateObject private var faceDetector = FaceDetector()
    
    // MARK: - UI States
    @State private var recognizedText = ""
    @State private var showAlert = false
    @State private var showSettings = false
    @State private var showWarningView = false
    @State private var showLiveCameraView = false
    @State var faceDetectonVideo : URL?
    @State private var player: AVPlayer?
    
    @State private var noFaceTimer: AnyCancellable?
    @State private var warningTimer: AnyCancellable?
   
    var body: some View {
        
        ZStack {
            // Scrollable Content
            VStack {
                Spacer().frame(height: 100) // Space for header
                
                if speechRecognizer.videos.isEmpty {
                    Color.white
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .cornerRadius(20)
                } else {
                    ScrollView {
                        TagGridView(tags: speechRecognizer.videos) { video in
                            handleVideoPlayback(video: video)
                        }
                    }
                    .padding(.top, 10)
                }
                Spacer()
                if(!recognizedText.isEmpty){
                    VStack{
                        Text(recognizedText)
                            .font(.system(size: 16))
                    }
                }
                
            }
            
            // Fixed Header with Shadow
            VStack {
                HStack {
                    logoView

                    Spacer() // Push text to center

                    Text("Please ask your question or click on button")
                        .font(.system(size: 25, weight: .bold))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)

                    Spacer() // Maintain centering
                    
                }
                .frame(maxWidth: .infinity, maxHeight: 100)
                .background(Color.white)
                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
                .zIndex(1) // Keep header above content

                Spacer()
            }
            .edgesIgnoringSafeArea(.top)


            // Camera Preview (Top-Right)
            //if(self.showLiveCameraView){
                VStack {
                    HStack {
                        Spacer()
                        ZStack {
                            // White background with shadow
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
                                .frame(width: 220, height: 160) // Background slightly larger than camera
                            
                            VStack (spacing: 0) {
                                      
                                CameraPreviewView(session: faceDetector.getCaptureSession())
                                    .frame(width: 220, height: 120)
                                    .cornerRadius(10)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white, lineWidth: 2))
                                
                                Text("Please stay in the box so I can hear you")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(showLiveCameraView == true ? .green : .red)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 2)
                            }
                            .frame(width: 220, height: 160)
                        }
                        .padding(.top, 10)
                        .padding(.trailing, 10)
                    }
                    
                    Spacer()
                }
                
            //}
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingView() {
                speechRecognizer.fetchHomeVideos()
            }
        }
        .onAppear(perform: handleOnAppear)
        .onDisappear(perform: handleOnDisappear)
        .onReceive(faceDetector.faceDetectionSubject, perform: handleFaceDetection)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("No External Screen Detected"),
                message: Text("Please connect an external screen to play the video."),
                dismissButton: .default(Text("OK"))
            )
        }
        .fullScreenCover(isPresented: $showWarningView) {
            PromptView()
        }
        .onAppear {
            
        }
    }
    
    // MARK: - Logo View
    private var logoView: some View {
        Image("Logo") // Replace with actual logo asset
            .resizable()
            .frame(width: 100, height: 100)
            .padding()
            .onTapGesture(count: 2) { // Open settings on double-tap
                showSettings = true
            }
    }
    
    // MARK: - Handlers
    private func handleOnAppear() {
        speechRecognizer.fetchHomeVideos()
        externalScreenManager.startObserving()
    }
    
    private func handleOnDisappear() {
        externalScreenManager.stopObserving()
        stopTimers()
    }
    
    private func handleVideoPlayback(video: Videos) {
        if externalScreenManager.isExternalScreenConnected {
            externalScreenManager.playVideoOnExternalScreen(videoFileName: video.videoURL ?? "", videoType: .MainVideo)
        } else {
            showAlert = true
        }
    }
    
    private func handleFaceDetection(isClose: Bool) {
        if isClose {
            print("Face detected, starting transcription.")
            stopTimers()
            showLiveCameraView = true
            
            if(ExternalDisplayManager.shared.selectedVideoType == .Initial){
                if(UserDefaults.standard.bool(forKey: "faceDetectionVideoSetting")){
                    if let url = UserDefaults.standard.value(forKey: "faceDetectionVideoURL") as? String {
                        externalScreenManager.playVideoOnExternalScreen(videoFileName: url, videoType: .FaceDetection)
                    }
                }
            }
            
            speechRecognizer.startTranscribing { text in
                self.recognizedText = text
                if let video = speechRecognizer.fetchVideoOnSpeech(text: text) {
                    speechRecognizer.stopTranscribing {
                        self.recognizedText = ""
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            externalScreenManager.playVideoOnExternalScreen(videoFileName: video.videoURL ?? "", videoType: .MainVideo)
                        }
                    }
                }
            }
        } else {
            startNoFaceTimer()
        }
    }
    
    // MARK: - No Face Timer
    func startNoFaceTimer() {
        // Cancel any existing timers
        noFaceTimer?.cancel()
        warningTimer?.cancel()
    
        // Start the 20-second transcription stop timer
        noFaceTimer = Timer.publish(every: 20, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                print("No face detected for 20 seconds, stopping transcription.")
                self.speechRecognizer.stopTranscribing()
                self.showWarningView = false // Hide the warning view
                self.showLiveCameraView = false
                self.noFaceTimer?.cancel()
            }
    }
    
    func stopTimers() {
        noFaceTimer?.cancel()
        warningTimer?.cancel()
        showWarningView = false
    }
    
    /// Initializes and loops the video
    private func setupPlayer(url: URL) {
        player = AVPlayer(url: url)
        player?.play()
        
        // Observe when video finishes and restart it
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { _ in
            player?.seek(to: .zero)
            player?.play()
        }
    }
}

#Preview {
    SpeechRecognitionView()
}



