//
//  AppDelegate.swift
//  Telepresence
//
//  Created by Muhammad Junaid Babar on 2/9/25.
//

import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        print("Your code here")
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenConnected),
            name: UIScreen.didConnectNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenDisconnected),
            name: UIScreen.didDisconnectNotification,
            object: nil
        )
    
        
        let defaults = UserDefaults.standard
        let videoRotationKey = "videoRotation"
        
        // Assign default value (90°) if it's not set
        if defaults.object(forKey: videoRotationKey) == nil {
            defaults.set(360, forKey: videoRotationKey)
            print("Default video rotation set to 360°")
        }
        
        return true
    }
    
    @objc func screenConnected(notification: Notification) {
        print("External screen connected")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            ExternalDisplayManager.shared.playDefaultVideo()
        }
    }
    
    @objc func screenDisconnected(notification: Notification) {
        print("External screen disconnected")
    }
    
    func checkForExternalScreen() {
        if UIScreen.screens.count > 1 {
            print("External screen is already connected")
        } else {
            print("No external screen detected")
        }
    }
}
