//
//  ExternalDisplayManager.swift
//  Telepresence
//
//  Created by Muhammad Junaid Babar on 2/9/25.
//


import UIKit
import AVKit
import Combine

enum VideoType {
    case Initial , FaceDetection , MainVideo
}

// MARK: - External Display Manager
// This class handles playing videos on an external display using AVPlayer.
class ExternalDisplayManager: ObservableObject {
    
    // Singleton instance for global access
    static let shared = ExternalDisplayManager()
    
    // UIWindow for displaying content on the external screen
    var externalWindow: UIWindow?
    
    // AVPlayer instance for video playback
    var player: AVPlayer?
    
    // Set to store Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    var selectedVideoType : VideoType = .Initial

    // MARK: - Play Video on External Screen
    /// Plays a video on an external display if available.
    /// - Parameter videoURL: The URL of the video to be played.
    
    func playVideoOnExternalScreen(videoURL: URL , videoType : VideoType = .Initial) {
        selectedVideoType = videoType
    
        stopVideo()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("Starting the video ")
            self.playVideo(videoURL: videoURL)
        }
    }
    
    func playVideo(videoURL: URL) {
        
        // Find an external screen (if connected)
        guard let externalScreen = UIScreen.screens.first(where: { $0 != UIScreen.main }) else {
            print("No external display detected")
            return
        }
        
        // Ensure we get the external UIWindowScene associated with the external screen
        guard let externalScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }) // Filter only window scenes
            .first(where: { $0.screen == externalScreen }) else { // Find the scene matching the external screen
            print("No available UIWindowScene for external display")
            return
        }
        
        // Create a new UIWindow for the external screen
        let externalWindow = UIWindow(windowScene: externalScene)
        
        // Set up a basic root view controller to manage the player
        let rootVC = UIViewController()
        rootVC.view.backgroundColor = .black // Prevents white flash when opening
        
        // Assign the view controller to the external window
        externalWindow.rootViewController = rootVC
        externalWindow.isHidden = false // Make window visible
        externalWindow.makeKeyAndVisible()
        
        // Store reference to external window
        self.externalWindow = externalWindow
        
        // MARK: - Video Player Setup
        // Create an AVPlayerItem with the provided video URL
        let playerItem = AVPlayerItem(url: videoURL)
        
        // Initialize the AVPlayer with the player item
        let player = AVPlayer(playerItem: playerItem)
        self.player = player
        
        // Create an AVPlayerLayer to render the video
        let playerLayer = AVPlayerLayer(player: player)
        
        // Get the rotation angle from settings
        let rotationAngle = getRotationAngle()
        let screenSize = externalScreen.bounds.size
        
        // Adjust frame based on rotation
        if rotationAngle == -(.pi / 2) || rotationAngle == .pi / 2 { // 90° or 270°
            playerLayer.frame = CGRect(x: 0, y: 0, width: rootVC.view.bounds.height, height: rootVC.view.bounds.width)
        } else {
            playerLayer.frame = rootVC.view.bounds
        }
        
        // Apply rotation transform
        playerLayer.setAffineTransform(CGAffineTransform(rotationAngle: rotationAngle))
        
        // Center the layer properly
        playerLayer.position = CGPoint(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY)
        
        // Ensure the video fills the screen properly
        playerLayer.videoGravity = .resizeAspect
        
        // Add the player layer to the root view
        rootVC.view.layer.addSublayer(playerLayer)
        
        // Start playback
        player.play()
        
        // MARK: - Observe Video Completion
        // Subscribe to notification when video playback ends
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: playerItem)
            .sink { [weak self] _ in
                print("Video finished playing")
                self?.videoDidFinishPlaying() // Handle video completion
            }
            .store(in: &cancellables) // Store subscription to prevent memory leaks
    }
       
    
    // Function to get rotation angle from user settings
    private func getRotationAngle() -> CGFloat {
        let rotationSetting = UserDefaults.standard.integer(forKey: "videoRotation")

        switch rotationSetting {
        case 90:
            return -(.pi / 2) // left to right
        case 180:
            return .pi // bottom to top
        case 270:
            return .pi / 2 // right to left
        case 360:
            return 0 // actual
        default:
            return 0 // Default to no rotation
        }
    }

    // MARK: - Handle Video Completion
    /// Called when the video finishes playing.
    private func videoDidFinishPlaying() {
        playDefaultVideo() // Play default video when the current one ends
    }
    
    // MARK: - Play Default Video
    /// Plays the default "initial.mp4" video from the app bundle.
    func playDefaultVideo() {
        // Check if the default video exists in the app bundle
        if let initialVideo = UserDefaults.standard.value(forKey: "initialVideo") as? String , !initialVideo.isEmpty {
            
            let fileManager = FileManager.default
            let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsDirectory.appendingPathComponent(initialVideo)
            self.playVideoOnExternalScreen(videoURL: fileURL) // Play default video
            print(fileURL)
        }else{
            if let videoURL = Bundle.main.url(forResource: "initial", withExtension: "mp4") {
                print(videoURL)
                self.playVideoOnExternalScreen(videoURL: videoURL) // Play default video
            } else {
                print("Video not found in bundle")
            }
        }
        
    }

    // MARK: - Stop Video Playback
    /// Stops video playback and hides the external display window.
    func stopVideo() {
        guard player != nil || externalWindow != nil else { return } // Avoid unnecessary logs
        
        DispatchQueue.main.async {
            self.player?.pause()
            self.player?.replaceCurrentItem(with: nil)
            self.player = nil
            
            // Remove all layers safely
            if let rootView = self.externalWindow?.rootViewController?.view {
                rootView.layer.sublayers?.removeAll()
            }
            
            print("Video playback stopped and all layers removed")
        }
    }
}

