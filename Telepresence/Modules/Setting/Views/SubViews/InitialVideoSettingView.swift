//
//  InitialVideoSettingView.swift
//  Telepresence
//
//  Created by Muhammad Junaid Babar on 2/17/25.
//

import SwiftUI
import PhotosUI

struct InitialVideoSettingView: View {
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var initailVideo : String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 15) {
                Text("Initial Video to play")
                    .font(.headline)
                
                PhotosPicker(
                    initailVideo.isEmpty ? "Choose Video" : initailVideo,
                    selection: $selectedItem,
                    matching: .videos
                )
                .onChange(of: selectedItem, perform: handleVideoSelection)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.gray.opacity(0.2), radius: 10, x: 0, y: 3)
                
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.gray.opacity(0.2), radius: 10, x: 0, y: 3)
        .onAppear {
            initailVideo = UserDefaults.standard.string(forKey: "initialVideo") ?? ""
        }
        
    }
    
    /// Handles video selection and saves it to the document directory.
    private func handleVideoSelection(_ newItem: PhotosPickerItem?) {
        Task {
            if let newItem = newItem {
                do {
                    if let videoData = try await newItem.loadTransferable(type: Data.self),
                       let savedURL = saveVideoToDocuments(videoData: videoData) {
                        self.initailVideo = savedURL.lastPathComponent
                        UserDefaults.standard.set(savedURL.lastPathComponent, forKey: "initialVideo")
                        
                    }
                } catch {
                    print("Error loading video: \(error)")
                }
            }
        }
    }
    
    /// Saves the selected video to the app's document directory.
    private func saveVideoToDocuments(videoData: Data) -> URL? {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let uniqueFileName = "video_\(UUID().uuidString).mp4"
        let fileURL = documentsDirectory.appendingPathComponent(uniqueFileName)

        do {
            try videoData.write(to: fileURL)
            return fileURL
        } catch {
            print("Error saving video: \(error)")
            return nil
        }
    }
}

#Preview {
    InitialVideoSettingView()
}
