//
//  ExternalScreenManager.swift
//  Telepresence
//
//  Created by Muhammad Junaid Babar on 2/6/25.
//

import Foundation
import AVKit


/// Manages external screen connections and video playback on a second display.
class ExternalScreenManager: ObservableObject {
    /// The window that will be used to display content on the external screen.
    var externalWindow: UIWindow?
    
    /// AVPlayerViewController for handling video playback.
    var playerViewController: AVPlayerViewController?
    
    /// Published property that indicates if an external screen is connected.
    @Published var isExternalScreenConnected = false

    // MARK: - Initialization

    /// Initializes the manager and sets up notifications to observe screen connections and disconnections.
    init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(screenDidConnect),
                                               name: UIScreen.didConnectNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(screenDidDisconnect),
                                               name: UIScreen.didDisconnectNotification,
                                               object: nil)
    }

    /// Cleans up by removing observers when the instance is deallocated.
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Screen Observation

    /// Starts observing for external screen connections when the app launches or the manager is initialized.
    func startObserving() {
        // Check if there's already an external screen connected
        if let screen = UIScreen.screens.last, screen != UIScreen.main {
            setupExternalScreen(screen: screen)
        }
    }

    /// Stops observing by disconnecting from the external screen.
    func stopObserving() {
        screenDidDisconnect()
    }

    // MARK: - Notification Handlers

    /// Handles when an external screen is connected.
    /// - Parameter notification: The system notification containing screen details.
    @objc private func screenDidConnect(notification: Notification) {
        guard let screen = notification.object as? UIScreen else { return }
        setupExternalScreen(screen: screen)
    }

    /// Handles when an external screen is disconnected.
    /// - Parameter notification: The system notification (optional).
    @objc private func screenDidDisconnect(notification: Notification? = nil) {
        // Hide and remove the external window
        externalWindow?.isHidden = true
        externalWindow = nil
        
        // Update the state
        isExternalScreenConnected = false
    }

    // MARK: - External Screen Setup

    /// Configures the external screen by creating a new window and setting up its root view controller.
    /// - Parameter screen: The connected external screen.
    func setupExternalScreen(screen: UIScreen) {
        // Ensure that the external window is only created once
        guard externalWindow == nil else { return }

        // Create a new window for the external screen
        externalWindow = UIWindow(frame: screen.bounds)
        externalWindow?.screen = screen
        externalWindow?.rootViewController = UIViewController()
        externalWindow?.isHidden = false

        // Mark external screen as connected
        isExternalScreenConnected = true
    }

    // MARK: - Video Playback on External Screen

    /// Plays a video on the external screen using a shared video manager.
    /// - Parameter videoFileName: The name of the video file stored in the app’s documents directory.
    func playVideoOnExternalScreen(videoFileName: String , videoType : VideoType) {
        // Ensure there's an active external screen
        guard let externalVC = externalWindow?.rootViewController else { return }

        // Construct the file URL for the video in the app's documents directory
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(videoFileName)

        // Delegate playback to the shared external display manager
        ExternalDisplayManager.shared.playVideoOnExternalScreen(videoURL: fileURL,videoType: videoType)
    }
}

