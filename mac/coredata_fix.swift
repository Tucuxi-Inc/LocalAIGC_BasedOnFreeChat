// Helper to migrate CoreData models if needed after renaming
// You can add this to your project if CoreData issues arise after renaming

import Foundation
import CoreData

extension NSPersistentContainer {
    
    /// Helper function to handle CoreData model name changes
    /// Call this in your PersistenceController if you see CoreData errors after renaming
    static func handleModelRename(from oldName: String, to newName: String) {
        // Check if we need to do the migration
        let userDefaults = UserDefaults.standard
        let migrationKey = "CoreDataModelRenamedFrom\(oldName)To\(newName)"
        
        if !userDefaults.bool(forKey: migrationKey) {
            // Get paths to the old and new stores
            guard let libraryDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
                return
            }
            
            // Create app directory within the Application Support directory if it doesn't exist
            let appDirectory = libraryDirectory.appendingPathComponent(newName)
            if !FileManager.default.fileExists(atPath: appDirectory.path) {
                do {
                    try FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    print("Error creating app directory: \(error)")
                    return
                }
            }
            
            // Old store files paths
            let oldAppDirectory = libraryDirectory.appendingPathComponent(oldName)
            let oldStoreURL = oldAppDirectory.appendingPathComponent("\(oldName).sqlite")
            let oldStoreWALURL = oldAppDirectory.appendingPathComponent("\(oldName).sqlite-wal")
            let oldStoreSHMURL = oldAppDirectory.appendingPathComponent("\(oldName).sqlite-shm")
            
            // New store files paths
            let newStoreURL = appDirectory.appendingPathComponent("\(newName).sqlite")
            let newStoreWALURL = appDirectory.appendingPathComponent("\(newName).sqlite-wal")
            let newStoreSHMURL = appDirectory.appendingPathComponent("\(newName).sqlite-shm")
            
            let fileManager = FileManager.default
            
            // Copy old store to new location if it exists
            if fileManager.fileExists(atPath: oldStoreURL.path) {
                do {
                    try fileManager.copyItem(at: oldStoreURL, to: newStoreURL)
                    print("Successfully copied main store file")
                    
                    // Copy -wal file if exists
                    if fileManager.fileExists(atPath: oldStoreWALURL.path) {
                        try fileManager.copyItem(at: oldStoreWALURL, to: newStoreWALURL)
                        print("Successfully copied WAL file")
                    }
                    
                    // Copy -shm file if exists
                    if fileManager.fileExists(atPath: oldStoreSHMURL.path) {
                        try fileManager.copyItem(at: oldStoreSHMURL, to: newStoreSHMURL)
                        print("Successfully copied SHM file")
                    }
                    
                    // Mark the migration as complete
                    userDefaults.set(true, forKey: migrationKey)
                } catch {
                    print("Failed to copy store files: \(error)")
                }
            } else {
                print("Old store not found, no migration needed")
                userDefaults.set(true, forKey: migrationKey)
            }
        }
    }
}

// Usage in PersistenceController:
/*
class PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init() {
        // Handle renamed model
        NSPersistentContainer.handleModelRename(from: "LocalAIGC", to: "LocalAIGC")
        
        // Regular container initialization
        container = NSPersistentContainer(name: "LocalAIGC")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Error: \(error.localizedDescription)")
            }
        }
    }
}
*/ 