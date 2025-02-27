//
//  FaceDetectionVideoSettingView.swift
//  Telepresence
//
//  Created by Muhammad Junaid Babar on 2/23/25.
//

import SwiftUI
import PhotosUI

struct FaceDetectionVideoSettingView: View {
    
    @State private var selectedItem: PhotosPickerItem? = nil
    @Binding var isSettingOn : Bool
    @Binding var faceDetectionVideo : String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack( spacing: 15) {
                Text("Face Detection Video Enabled")
                    .font(.headline)
                Spacer()
                
                Toggle("", isOn: $isSettingOn)
                    .padding()
                
            }
            
            VStack(alignment: .leading, spacing: 15) {
                
                PhotosPicker(
                    faceDetectionVideo.isEmpty ? "Choose Video" : faceDetectionVideo,
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
            isSettingOn = UserDefaults.standard.bool(forKey: "faceDetectionVideoSetting")
            faceDetectionVideo = UserDefaults.standard.string(forKey: "faceDetectionVideoURL") ?? ""
        }
    }
    
    /// Handles video selection and saves it to the document directory.
    private func handleVideoSelection(_ newItem: PhotosPickerItem?) {
        Task {
            if let newItem = newItem {
                do {
                    if let videoData = try await newItem.loadTransferable(type: Data.self),
                       let savedURL = saveVideoToDocuments(videoData: videoData) {
                        self.faceDetectionVideo = savedURL.lastPathComponent
                        UserDefaults.standard.set(savedURL.lastPathComponent, forKey: "faceDetectionVideoURL")
                        
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
        let uniqueFileName = "faceDetectionVideoURL.mp4"
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
    //FaceDetectionVideoSettingView()
}
