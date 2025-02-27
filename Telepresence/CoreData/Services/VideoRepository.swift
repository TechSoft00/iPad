//
//  VideoRepository.swift
//  Telepresence
//
//  Created by Ditmar Jubica on 2/6/25.
//


import CoreData

/// Repository class for managing `Videos` entities using Core Data.
class VideoRepository: VideoRepositoryProtocol {
    
    /// Managed object context used to interact with Core Data.
    private let context: NSManagedObjectContext

    /// Initializes the repository with an optional managed object context.
    /// - Parameter context: The managed object context to be used, defaulting to the shared Core Data context.
    init(context: NSManagedObjectContext = CoreDataManager.shared.context) {
        self.context = context
    }
    
    /// Fetches all videos from the database.
    /// - Returns: An array of `Videos` objects.
    func fetchAllVideos() -> [Videos] {
        let request: NSFetchRequest<Videos> = Videos.fetchRequest()
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching videos: \(error)")
            return []
        }
    }

    /// Fetches videos based on their `showOnHome` status.
    /// - Parameter showOnHome: A Boolean value indicating whether the video should be shown on the home screen.
    /// - Returns: An array of `Videos` objects matching the condition.
    func fetchVideos(showOnHome: Bool) -> [Videos] {
        let request: NSFetchRequest<Videos> = Videos.fetchRequest()
        request.predicate = NSPredicate(format: "showOnHome == %@", NSNumber(value: showOnHome))
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching videos: \(error)")
            return []
        }
    }
    
    /// Adds a new video to the database.
    /// - Parameters:
    ///   - activationPhrase: The activation phrase associated with the video.
    ///   - keyword: A keyword used for searching the video.
    ///   - showOnHome: A Boolean value indicating whether the video should be displayed on the home screen.
    ///   - videoURL: The URL of the video.
    func addVideo(activationPhrase: String?, keyword: String?, showOnHome: Bool, videoURL: String?) {
        let newVideo = Videos(context: context)
        newVideo.activationPhrase = activationPhrase
        newVideo.keyword = keyword
        newVideo.showOnHome = showOnHome
        newVideo.videoURL = videoURL
        
        saveContext()
    }
    
    /// Deletes a video from the database.
    /// - Parameter video: The `Videos` object to be deleted.
    func deleteVideo(_ video: Videos) {
        context.delete(video)
        saveContext()
    }
    
    /// Updates an existing video record in the database.
    /// - Parameters:
    ///   - activationPhrase: The new activation phrase for the video.
    ///   - keyword: The new keyword for the video.
    ///   - showOnHome: Whether the video should be displayed on the home screen.
    ///   - videoURL: The updated video URL.
    ///   - videoObj: The existing `Videos` object to be updated.
    func updateVideo(activationPhrase: String?, keyword: String?, showOnHome: Bool, videoURL: String?, videoObj: Videos) {
        videoObj.activationPhrase = activationPhrase
        videoObj.keyword = keyword
        videoObj.showOnHome = showOnHome
        videoObj.videoURL = videoURL
        
        saveContext()
    }
    
    /// Searches for a video that matches a given keyword or activation phrase.
    /// - Parameter text: The keyword or activation phrase to search for.
    /// - Returns: A `Videos` object if a match is found, otherwise `nil`.
    func fetchVideo(matching text: String) -> Videos? {
        let request: NSFetchRequest<Videos> = Videos.fetchRequest()
        request.predicate = NSPredicate(format: "keyword ==[c] %@ OR activationPhrase ==[c] %@", text, text)
        request.fetchLimit = 1  // Ensure only one result is returned

        do {
            return try context.fetch(request).first
        } catch {
            print("Error fetching video: \(error)")
            return nil
        }
    }

    /// Saves changes to the Core Data context.
    private func saveContext() {
        CoreDataManager.shared.saveContext()
    }
}

