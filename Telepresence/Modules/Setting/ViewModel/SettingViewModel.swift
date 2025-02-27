//
//  SettingViewModel.swift
//  Telepresence
//
//  Created by Ditmar Jubica on 2/5/25.
//

import Foundation

// MARK: - Model for Setting Item
struct SettingItem {
    var keyword: String
    var activationPhrase: String
    var videoURL: String
    var videoName: String
    var showHome: Bool
    var videoObj: Videos?
}

// MARK: - ViewModel for Settings
class SettingViewModel: ObservableObject {
    
    @Published var settingItems: [SettingItem] = []
    @Published var initialVideo : String = ""
    @Published var selectedRotation: Int = UserDefaults.standard.integer(forKey: "videoRotation")
    @Published var faceDetectionVideoSetting: Bool = false
    @Published var faceDetectionVideo : String = ""
    
    var errorMessage = "Please fill all required fields and choose a valid video."


    private let repository: VideoRepositoryProtocol
    
    // MARK: - Initializer
    init(repository: VideoRepositoryProtocol = VideoRepository()) {
        self.repository = repository
        loadAllVideos()
         // Ensures at least one empty setting item is present
    }
    
    // MARK: - Load All Videos from Repository
    private func loadAllVideos() {
        let videos = repository.fetchAllVideos()
        settingItems = videos.map { video in
            SettingItem(
                keyword: video.keyword ?? "",
                activationPhrase: video.activationPhrase ?? "",
                videoURL: video.videoURL ?? "",
                videoName: video.videoURL ?? "",
                showHome: video.showOnHome,
                videoObj: video
            )
        }
        
        if(settingItems.count == 0){
            addNewItem()
        }
    }
    
    // MARK: - Add a New Empty Setting Item
    func addNewItem() {
        settingItems.append(SettingItem(keyword: "", activationPhrase: "", videoURL: "", videoName: "", showHome: false))
    }
    
    // MARK: - Validate All Fields
    func isAllFieldsValid() -> Bool {
        if(faceDetectionVideoSetting){
            if(faceDetectionVideo.isEmpty){
                errorMessage = "Face decoding video URL cannot be empty"
                return false
            }
        }
        
        
        return settingItems.allSatisfy {
            !$0.keyword.isEmpty && !$0.activationPhrase.isEmpty && !$0.videoURL.isEmpty
        }
    }
    
    // MARK: - Delete Video Entry
    func deleteVideo(at index: Int) {
        guard index < settingItems.count else { return }
        
        let item = settingItems[index]
        
        // If the video exists in the database, delete it
        if let video = item.videoObj {
            deleteFile(named: video.videoURL ?? "") // Delete associated file
            repository.deleteVideo(video)
        }
        
        // Remove item from list if there's more than one item
        if settingItems.count > 1 {
            settingItems.remove(at: index)
        }
    }
    
    // MARK: - Save All Data to Repository
    func saveAllData() {
        
        UserDefaults.standard.set(faceDetectionVideoSetting, forKey: "faceDetectionVideoSetting")
        
        for item in settingItems {
            if let video = item.videoObj {
                // Update existing video entry
                if(video.videoURL != item.videoName){
                    self.deleteFile(named: video.videoURL ?? "")
                }
                repository.updateVideo(
                    activationPhrase: item.activationPhrase,
                    keyword: item.keyword,
                    showOnHome: item.showHome,
                    videoURL: item.videoName,
                    videoObj: video
                )
            } else {
                // Add new video entry
                repository.addVideo(
                    activationPhrase: item.activationPhrase,
                    keyword: item.keyword,
                    showOnHome: item.showHome,
                    videoURL: item.videoName
                )
            }
        }
        
        UserDefaults.standard.set(selectedRotation, forKey: "videoRotation")
    }

    // MARK: - Delete File from Documents Directory
    private func deleteFile(named fileName: String) {
        let fileManager = FileManager.default
        
        // Get the path of the file in the Documents directory
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Failed to get the documents directory")
            return
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        print(fileURL)
        
        // Check if file exists before attempting to delete
        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("File not found: \(fileName)")
            return
        }
        
        do {
            try fileManager.removeItem(at: fileURL)
            print("File deleted successfully: \(fileName)")
        } catch {
            print("Error deleting file: \(error.localizedDescription)")
        }
    }
}
