//
//  Model+Extensions.swift
//  Chats
//
//  Created by Peter Sugihara on 8/8/23.
//

import Foundation
import CoreData
import OSLog

enum ModelCreateError: LocalizedError {
  var errorDescription: String? {
    switch self {
    case .unknownFormat:
      "Model files must be in .gguf format"
    case .accessNotAllowed(let url):
      "File access not allowed to \(url.absoluteString)"
    }
  }

  case unknownFormat
  case accessNotAllowed(_ url: URL)
}

struct DefaultModel: Identifiable {
    let id = UUID()
    let name: String
    let url: URL
    let size: String
    let description: String
    let category: ModelCategory
    let capabilities: [ModelCapability]
    let lastUpdated: Date
    let version: String
    let provider: String
    let contextWindow: String
}

enum ModelCategory: String, CaseIterable {
    case small = "Small (1-2GB)"
    case medium = "Medium (2-5GB)"
    case large = "Large (5GB+)"
}

enum ModelCapability: String, CaseIterable {
    case fast = "Fast"
    case multilingual = "Multilingual"
    case coding = "Coding"
    case creative = "Creative"
    case reasoning = "Reasoning"
    case longContext = "Long Context"
}

extension Model {
  @available(*, deprecated, message: "use nil instead")
  static let unsetModelId = "unset"
  static let defaultModelUrl = URL(string: "https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf?download=true")!
//  static let defaultModelUrl = URL(string: "http://localhost:8080/synthia-7b-v1.5.Q3_K_M.gguf")!

  // Collection of default models available for download
  static let defaultModels: [DefaultModel] = [
      DefaultModel(
          name: "Llama-3.2-3B-Instruct",
          url: URL(string: "https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf")!,
          size: "2.02 GB",
          description: "Meta's Llama 3.2 3B is a compact model with excellent instruction-following capabilities. Good balance of speed and intelligence.",
          category: .medium,
          capabilities: [.fast, .reasoning],
          lastUpdated: ISO8601DateFormatter().date(from: "2024-07-15T00:00:00Z")!,
          version: "3.2",
          provider: "Meta",
          contextWindow: "8K"
      ),
      DefaultModel(
          name: "Llama-3-8B-Instruct",
          url: URL(string: "https://huggingface.co/bartowski/Llama-3-8B-GGUF/resolve/main/llama-3-8b-instruct.Q4_K_M.gguf")!,
          size: "4.37 GB",
          description: "Meta's 8B parameter model offering better reasoning and more nuanced responses compared to smaller models.",
          category: .medium,
          capabilities: [.reasoning, .creative],
          lastUpdated: ISO8601DateFormatter().date(from: "2024-06-25T00:00:00Z")!,
          version: "3",
          provider: "Meta",
          contextWindow: "8K"
      ),
      DefaultModel(
          name: "Phi-3-Mini-4K-Instruct",
          url: URL(string: "https://huggingface.co/bartowski/phi-3-mini-4k-instruct-GGUF/resolve/main/phi-3-mini-4k-instruct-q4_k_m.gguf")!,
          size: "1.91 GB",
          description: "Microsoft's 3.8B parameter model. Small, fast and optimized for instruction following with 4K context window.",
          category: .small,
          capabilities: [.fast, .reasoning],
          lastUpdated: ISO8601DateFormatter().date(from: "2024-05-20T00:00:00Z")!,
          version: "3",
          provider: "Microsoft",
          contextWindow: "4K"
      ),
      DefaultModel(
          name: "TinyLlama-1.1B-Chat",
          url: URL(string: "https://huggingface.co/bartowski/TinyLlama-1.1B-Chat-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q5_K_M.gguf")!,
          size: "0.84 GB",
          description: "Ultra-lightweight model suitable for low-resource devices. Great for basic conversations and simple assistance.",
          category: .small,
          capabilities: [.fast],
          lastUpdated: ISO8601DateFormatter().date(from: "2024-04-18T00:00:00Z")!,
          version: "1.0",
          provider: "TinyLlama",
          contextWindow: "2K"
      ),
      DefaultModel(
          name: "Qwen2-0.5B-Instruct",
          url: URL(string: "https://huggingface.co/bartowski/Qwen2-0.5B-Instruct-GGUF/resolve/main/qwen2-0.5b-instruct.Q5_K_M.gguf")!,
          size: "0.48 GB",
          description: "Alibaba's tiny model offering surprising capabilities in a tiny package. Perfect for resource-constrained environments.",
          category: .small,
          capabilities: [.fast],
          lastUpdated: ISO8601DateFormatter().date(from: "2024-04-22T00:00:00Z")!,
          version: "2",
          provider: "Alibaba",
          contextWindow: "4K"
      ),
      DefaultModel(
          name: "Mistral-7B-Instruct-v0.2",
          url: URL(string: "https://huggingface.co/bartowski/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q4_K_M.gguf")!,
          size: "3.80 GB",
          description: "Highly capable open-source model with excellent instruction following and general knowledge.",
          category: .medium,
          capabilities: [.reasoning, .creative],
          lastUpdated: ISO8601DateFormatter().date(from: "2024-04-10T00:00:00Z")!,
          version: "0.2",
          provider: "Mistral AI",
          contextWindow: "8K"
      ),
      DefaultModel(
          name: "CodeLlama-7B-Instruct",
          url: URL(string: "https://huggingface.co/bartowski/CodeLlama-7B-Instruct-GGUF/resolve/main/codellama-7b-instruct.Q4_K_M.gguf")!,
          size: "3.83 GB",
          description: "Meta's specialized model for code generation and understanding programming tasks.",
          category: .medium,
          capabilities: [.coding, .reasoning],
          lastUpdated: ISO8601DateFormatter().date(from: "2024-01-15T00:00:00Z")!,
          version: "1.0",
          provider: "Meta",
          contextWindow: "16K"
      )
  ]

  // Backup URLs for specific models in case the primary source is unavailable
  private static let backupURLs: [String: URL] = [
    "Llama-3.2-3B-Instruct-Q4_K_M.gguf": URL(string: "https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf")!,
    "llama-3-8b-instruct.Q4_K_M.gguf": URL(string: "https://huggingface.co/bartowski/Llama-3-8B-GGUF/resolve/main/llama-3-8b-instruct.Q4_K_M.gguf")!,
    "phi-3-mini-4k-instruct-q4_k_m.gguf": URL(string: "https://huggingface.co/bartowski/phi-3-mini-4k-instruct-GGUF/resolve/main/phi-3-mini-4k-instruct-q4_k_m.gguf")!
  ]
  
  // Expected SHA-256 hashes for verifying model integrity
  // Note: These are placeholder values and should be replaced with actual hashes
  private static let expectedHashes: [String: String] = [:]
  
  // Method to get a backup URL for a model if available
  static func getBackupURL(for modelName: String) -> URL? {
    return backupURLs[modelName]
  }
  
  // Method to get the expected hash for a model if available
  static func getExpectedHash(for modelName: String) -> String? {
    return expectedHashes[modelName]
  }

  var url: URL? {
    if bookmark == nil { return nil }
    var stale = false
    do {
      let res = try URL(resolvingBookmarkData: bookmark!, options: .withSecurityScope, bookmarkDataIsStale: &stale)

      guard res.startAccessingSecurityScopedResource() else {
        print("error starting security scoped access")
        return nil
      }

      if stale {
        print("renewing stale bookmark", res)
        bookmark = try res.bookmarkData(options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess])
      }

      return res
    } catch {
      print("Error resolving \(name ?? "unknown model") bookmark", error.localizedDescription)
      return nil
    }
  }

  public static func create(context: NSManagedObjectContext, fileURL: URL) throws -> Model {
    if fileURL.pathExtension != "gguf" {
      throw ModelCreateError.unknownFormat
    }

    print("Creating model from file: \(fileURL.path)")
    
    // Check file existence
    let fileManager = FileManager.default
    guard fileManager.fileExists(atPath: fileURL.path) else {
      print("Error: File does not exist at \(fileURL.path)")
      throw ModelCreateError.accessNotAllowed(fileURL)
    }
    
    // Check file size
    if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
       let fileSize = attributes[.size] as? Int {
      print("The file size is \(fileSize)")
      if fileSize < 100_000 { // 100KB
        print("Warning: File size is suspiciously small (\(fileSize) bytes)")
      }
    } else {
      print("Warning: Could not determine file size")
    }

    // Gain access to the directory
    let gotAccess = fileURL.startAccessingSecurityScopedResource()
    print("Got security scoped access: \(gotAccess)")

    do {
      let model = Model(context: context)
      model.id = UUID()
      model.name = fileURL.lastPathComponent
      
      // Create bookmark with proper options
      print("Creating bookmark for: \(fileURL.path)")
      model.bookmark = try fileURL.bookmarkData(options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess])
      
      // Verify bookmark works
      var isStale = false
      if let bookmark = model.bookmark,
         let resolvedURL = try? URL(resolvingBookmarkData: bookmark, options: .withSecurityScope, bookmarkDataIsStale: &isStale) {
        print("Verified bookmark resolves to: \(resolvedURL.path)")
        if isStale {
          print("Warning: Bookmark was stale")
        }
      } else {
        print("Warning: Could not verify bookmark")
      }
      
      if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path()),
        let fileSize = attributes[.size] as? Int {
        print("Setting model size to \(fileSize / 1000000) MB")
        model.size = Int32(fileSize / 1000000)
      }
      
      model.updatedAt = Date()
      try context.save()

      if gotAccess {
        fileURL.stopAccessingSecurityScopedResource()
      }

      return model
    } catch {
      print("Error creating Model: \(error.localizedDescription)")

      if gotAccess {
        fileURL.stopAccessingSecurityScopedResource()
      }

      throw error
    }
  }

  public override func willSave() {
    super.willSave()

    if !isDeleted, changedValues()["updatedAt"] == nil {
      self.setValue(Date(), forKey: "updatedAt")
    }
  }
}
