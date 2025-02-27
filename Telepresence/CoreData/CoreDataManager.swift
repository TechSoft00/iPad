//
//  CoreDataManager.swift
//  Telepresence
//
//  Created by Ditmar Jubica on 2/3/25.
//

import CoreData

/// A singleton class responsible for managing Core Data operations.
class CoreDataManager {
    
    /// Shared instance of `CoreDataManager` to ensure a single point of access.
    static let shared = CoreDataManager()
    
    /// The persistent container that holds the Core Data stack.
    let persistentContainer: NSPersistentContainer

    /// Private initializer to enforce the singleton pattern.
    private init() {
        // Initialize the persistent container with the name of the Core Data model (.xcdatamodeld file)
        persistentContainer = NSPersistentContainer(name: "Telepresence")
        
        // Load the persistent store (SQLite database) associated with the container
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load Core Data: \(error)")
            }
        }
        
        // Enables automatic merging of changes from background contexts
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
    }

    /// Provides access to the main view context of the Core Data stack.
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    /// Saves changes in the main view context to persist data.
    func saveContext() {
        let context = persistentContainer.viewContext
        // Check if there are any changes to save
        if context.hasChanges {
            do {
                // Try to save the changes
                try context.save()
            } catch {
                // Handle error if saving fails
                print("Failed to save Core Data: \(error)")
            }
        }
    }
}

