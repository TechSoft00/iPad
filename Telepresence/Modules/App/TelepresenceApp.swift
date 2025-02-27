//
//  TelepresenceApp.swift
//  Telepresence
//
//  Created by Ditmar Jubica on 2/3/25.
//

import SwiftUI

@main
struct TelepresenceApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            CameraView()
        }
    }
}
