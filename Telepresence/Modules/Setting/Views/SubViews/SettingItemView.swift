//
//  SettingItemView.swift
//  Telepresence
//
//  Created by Muhammad Junaid Babar on 2/12/25.
//
import SwiftUI
import PhotosUI


/// View representing a single setting item, allowing users to configure phrases, keywords, and associate a video.
struct SettingItemView: View {
    
    @Binding var settingItem: SettingItem
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var showDeleteAlert = false
    var onDelete: () -> Void  // Callback for deleting the item
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            deleteButton
            inputFieldsSection
            videoSelectionSection
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.gray.opacity(0.2), radius: 10, x: 0, y: 3)
        .alert(isPresented: $showDeleteAlert, content: deleteAlert)
    }
    
    /// Delete button allowing users to remove the setting item.
    private var deleteButton: some View {
        HStack {
            Spacer()
            Button(action: { showDeleteAlert = true }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete")
                }
                .foregroundColor(.white)
                .padding(.horizontal, 15)
                .padding(.vertical, 8)
                .background(Color.red)
                .cornerRadius(8)
            }
        }
    }
    
    /// Section containing text fields for input phrase and keyword.
    private var inputFieldsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            inputField(title: "Input phrase", text: $settingItem.activationPhrase)
            inputField(title: "Input keyword", text: $settingItem.keyword)
        }
    }
    
    /// Section allowing users to select a video and toggle home visibility.
    private var videoSelectionSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Video to play if keyword or phrase match")
                .font(.headline)
            
            PhotosPicker(
                settingItem.videoURL.isEmpty ? "Choose Video" : settingItem.videoName,
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
            
            Toggle("Show on home page", isOn: $settingItem.showHome)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
        }
    }
    
    /// Reusable input field for text entry.
    private func inputField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
            TextField("Enter \(title.lowercased())", text: text)
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.gray.opacity(0.2), radius: 10, x: 0, y: 3)
        }
    }
    
    /// Handles video selection and saves it to the document directory.
    private func handleVideoSelection(_ newItem: PhotosPickerItem?) {
        Task {
            if let newItem = newItem {
                do {
                    if let videoData = try await newItem.loadTransferable(type: Data.self),
                       let savedURL = saveVideoToDocuments(videoData: videoData) {
                        settingItem.videoURL = savedURL.absoluteString
                        settingItem.videoName = savedURL.lastPathComponent
                        print("Saved to Documents: \(savedURL)")
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
    
    /// Alert for confirming the deletion of an item.
    private func deleteAlert() -> Alert {
        Alert(
            title: Text("Delete Item"),
            message: Text("Are you sure you want to delete this item?"),
            primaryButton: .destructive(Text("Delete")) { onDelete() },
            secondaryButton: .cancel()
        )
    }
}
