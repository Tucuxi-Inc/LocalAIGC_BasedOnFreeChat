//
//  DownloadManager.swift
//  FreeChat
//
//  Created by Peter Sugihara on 9/28/23.
//

import Foundation
import OSLog
import CoreData
import SwiftUI

class DownloadManager: NSObject, ObservableObject {
  static var shared = DownloadManager()

  @AppStorage("selectedModelId") private var selectedModelId: String?

  var viewContext: NSManagedObjectContext?

  private var urlSession: URLSession!
  @Published var tasks: [URLSessionTask] = []
  @Published var lastUpdatedAt = Date()
  
  // Maps a URL to its download destination
  private var downloadDestinations: [URL: URL] = [:]
  
  // Minimum valid model file size in bytes (100KB instead of 1MB for testing)
  private let minimumValidModelSize: Int64 = 100_000

  override private init() {
    super.init()

    // Using a foreground session instead of a background session to avoid entitlement issues
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 300 // 5 minutes
    config.timeoutIntervalForResource = 24 * 60 * 60 // 1 day
    config.waitsForConnectivity = true

    urlSession = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue.main)

    updateTasks()
  }

  func startDownload(url: URL) {
    print("starting download", url)
    
    // Check and remove any existing corrupt or incomplete files before starting a new download
    cleanupExistingFile(for: url)
    
    // ignore download if it's already in progress
    if tasks.contains(where: { $0.originalRequest?.url == url }) { return }
    
    let task = urlSession.downloadTask(with: url)
    tasks.append(task)
    task.resume()
  }
  
  private func cleanupExistingFile(for url: URL) {
    let fileName = url.lastPathComponent
    let folderName = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String ?? "Local AI GC"
    let destDir = URL.applicationSupportDirectory.appending(path: folderName, directoryHint: .isDirectory)
    let destinationURL = destDir.appending(path: fileName)
    
    let fileManager = FileManager.default
    
    // Check if file exists and is potentially corrupt (too small)
    if fileManager.fileExists(atPath: destinationURL.path) {
      do {
        let attributes = try fileManager.attributesOfItem(atPath: destinationURL.path)
        if let fileSize = attributes[.size] as? Int64, fileSize < minimumValidModelSize {
          print("Found potentially corrupt model file, removing: \(destinationURL.path)")
          try fileManager.removeItem(at: destinationURL)
          
          // Also check if there's a model in CoreData pointing to this file and delete it
          cleanupModelRecord(for: fileName)
        }
      } catch {
        print("Error checking or removing existing file: \(error.localizedDescription)")
      }
    }
  }
  
  private func cleanupModelRecord(for fileName: String) {
    DispatchQueue.main.async {
      let context = self.viewContext ?? PersistenceController.shared.container.viewContext
      
      let fetchRequest = Model.fetchRequest()
      fetchRequest.predicate = NSPredicate(format: "name == %@", fileName)
      
      do {
        let results = try context.fetch(fetchRequest)
        for model in results {
          context.delete(model)
        }
        try context.save()
      } catch {
        print("Error removing model record: \(error.localizedDescription)")
      }
    }
  }
  
  func pauseDownload(for url: URL) {
    let matchingTasks = tasks.filter { $0.originalRequest?.url == url }
    for task in matchingTasks {
      if let downloadTask = task as? URLSessionDownloadTask {
        // Store the resume data for later
        downloadTask.cancel { _ in
          // Not doing anything with resume data at the moment
        }
      }
    }
  }
  
  func cancelDownload(for url: URL) {
    let matchingTasks = tasks.filter { $0.originalRequest?.url == url }
    for task in matchingTasks {
      task.cancel()
    }
  }

  private func updateTasks() {
    urlSession.getAllTasks { tasks in
      DispatchQueue.main.async {
        self.tasks = tasks
        self.lastUpdatedAt = Date()
      }
    }
  }
}

extension DownloadManager: URLSessionDelegate, URLSessionDownloadDelegate {
  func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
    guard totalBytesExpectedToWrite > 0 else { return }
    
    let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
    
    // Print debug info
    print("Download progress: \(Int(progress * 100))% - \(totalBytesWritten)/\(totalBytesExpectedToWrite) bytes")
    
    DispatchQueue.main.async {
      // Post notification for progress update
      if let url = downloadTask.originalRequest?.url {
        NotificationCenter.default.post(
          name: NSNotification.Name("DownloadProgressUpdated"),
          object: nil,
          userInfo: [
            "url": url,
            "progress": progress,
            "bytesWritten": totalBytesWritten,
            "totalBytes": totalBytesExpectedToWrite
          ]
        )
      }
      
      let now = Date()
      if self.lastUpdatedAt.timeIntervalSince(now) > 10 {
        self.lastUpdatedAt = now
      }
    }
  }

  func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
    os_log("Download finished: %@ %@", type: .info, location.absoluteString, downloadTask.originalRequest?.url?.lastPathComponent ?? "")
    
    // Check if the downloaded file is valid (has minimum size)
    let fileManager = FileManager.default
    do {
      let attributes = try fileManager.attributesOfItem(atPath: location.path)
      let fileSize = attributes[FileAttributeKey.size] as? Int64 ?? 0
      
      print("Downloaded file size: \(fileSize) bytes, minimum required: \(minimumValidModelSize) bytes")
      
      if fileSize < minimumValidModelSize {
        // Try to inspect the file content to see what we got
        if let data = try? Data(contentsOf: location, options: .alwaysMapped),
           let textContent = String(data: data.prefix(1000), encoding: .utf8) {
          print("File content preview: \(textContent)")
        }
        
        os_log("Downloaded file is too small, likely corrupt: %@", type: .error, location.absoluteString)
        
        // Post notification for download failure
        if let originalURL = downloadTask.originalRequest?.url {
          NotificationCenter.default.post(
            name: NSNotification.Name("DownloadFailed"),
            object: nil,
            userInfo: [
              "url": originalURL,
              "error": NSError(domain: "DownloadManager", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Downloaded file is too small or corrupt"])
            ]
          )
        }
        return
      }
    } catch {
      os_log("Error checking file size: %@", type: .error, error.localizedDescription)
    }

    // move file to app resources
    let fileName = downloadTask.originalRequest?.url?.lastPathComponent ?? "default.gguf"
    let folderName = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String ?? "Local AI GC"
    let destDir = URL.applicationSupportDirectory.appending(path: folderName, directoryHint: .isDirectory)
    let destinationURL = destDir.appending(path: fileName)

    print("Moving downloaded file to: \(destinationURL.path)")
    
    // Print application support directory path
    print("Application Support Directory: \(destDir.path)")
    print("Destination Directory exists: \(fileManager.fileExists(atPath: destDir.path))")
    
    try? fileManager.removeItem(at: destinationURL)

    do {
      let folderExists = (try? destDir.checkResourceIsReachable()) ?? false
      if !folderExists {
        print("Creating destination directory: \(destDir.path)")
        try fileManager.createDirectory(at: destDir, withIntermediateDirectories: true)
      }
      
      print("Copying file from \(location.path) to \(destinationURL.path)")
      // Copy instead of move to ensure the file is fully written
      try fileManager.copyItem(at: location, to: destinationURL)
      
      print("File exists at destination: \(fileManager.fileExists(atPath: destinationURL.path))")
      
      // Verify the file was properly copied by checking its size
      let fileAttributes = try fileManager.attributesOfItem(atPath: destinationURL.path)
      let copyFileSize = fileAttributes[FileAttributeKey.size] as? Int64 ?? 0
      
      print("Copied file size: \(copyFileSize) bytes")
      
      guard copyFileSize >= minimumValidModelSize else {
        os_log("File was not properly copied: %@", type: .error, destinationURL.absoluteString)
        
        // Post notification for download failure
        if let originalURL = downloadTask.originalRequest?.url {
          NotificationCenter.default.post(
            name: NSNotification.Name("DownloadFailed"),
            object: nil,
            userInfo: [
              "url": originalURL,
              "error": NSError(domain: "DownloadManager", code: 1003, userInfo: [NSLocalizedDescriptionKey: "Failed to copy downloaded file to destination"])
            ]
          )
        }
        return
      }
      
      // Save the destination URL for use in completion handling
      if let originalURL = downloadTask.originalRequest?.url {
        downloadDestinations[originalURL] = destinationURL
      }
      
    } catch {
      os_log("FileManager copy error at %@ to %@ error: %@", type: .error, location.absoluteString, destinationURL.absoluteString, error.localizedDescription)
      
      // Post notification for download failure
      if let originalURL = downloadTask.originalRequest?.url {
        NotificationCenter.default.post(
          name: NSNotification.Name("DownloadFailed"),
          object: nil,
          userInfo: [
            "url": originalURL,
            "error": error
          ]
        )
      }
      
      return
    }

    // create Model that points to file
    os_log("DownloadManager creating model", type: .info)
    DispatchQueue.main.async { [self] in
      let ctx = viewContext ?? PersistenceController.shared.container.viewContext
      do {
        let m = try Model.create(context: ctx, fileURL: destinationURL)
        os_log("DownloadManager created model %@", type: .info, m.id?.uuidString ?? "missing id")
        selectedModelId = m.id?.uuidString
        
        // Post notification for download completion
        if let originalURL = downloadTask.originalRequest?.url {
          NotificationCenter.default.post(
            name: NSNotification.Name("DownloadCompleted"),
            object: nil,
            userInfo: [
              "url": originalURL,
              "localURL": destinationURL,
              "modelId": m.id?.uuidString ?? ""
            ]
          )
        }
        
      } catch {
        os_log("Error creating model on main thread: %@", type: .error, error.localizedDescription)
        
        // Post notification for download failure
        if let originalURL = downloadTask.originalRequest?.url {
          NotificationCenter.default.post(
            name: NSNotification.Name("DownloadFailed"),
            object: nil,
            userInfo: [
              "url": originalURL,
              "error": error
            ]
          )
        }
      }
      lastUpdatedAt = Date()
    }
  }

  func urlSession(_: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    if let error = error {
      os_log("Download error: %@", type: .error, String(describing: error))
      
      // Post notification for download failure
      if let originalURL = task.originalRequest?.url {
        NotificationCenter.default.post(
          name: NSNotification.Name("DownloadFailed"),
          object: nil,
          userInfo: [
            "url": originalURL,
            "error": error
          ]
        )
      }
    } else {
      os_log("Task finished: %@", type: .info, task)
    }

    let taskId = task.taskIdentifier
    DispatchQueue.main.async {
      self.tasks.removeAll(where: { $0.taskIdentifier == taskId })
    }
  }
}
