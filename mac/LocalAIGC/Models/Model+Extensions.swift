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

    /// Collection of default models available for download
    static let defaultModels: [DefaultModel] = [
      // Original default
      DefaultModel(
        name: "Llama-3.2-3B-Instruct",
        url: URL(string: "https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf?download=true")!,
        size: "2.02 GB",
        description: "Meta's Llama 3.2 3B is a compact model with excellent instruction-following capabilities.",
        category: .medium,
        capabilities: [.fast, .reasoning],
        lastUpdated: ISO8601DateFormatter().date(from: "2024-07-15T00:00:00Z")!,
        version: "3.2",
        provider: "Meta",
        contextWindow: "8K"
      ),
      DefaultModel(
        name: "Granite-3.3-2B-Instruct",
        url: URL(string: "https://huggingface.co/ibm-granite/granite-3.3-2b-instruct-GGUF/resolve/main/granite-3.3-2b-instruct-Q4_K_M.gguf?download=true")!,
        size: "1.55 GB",
        description: "IBM's Granite 3.3 2B model with 128K context window.",
        category: .small,
        capabilities: [.fast, .reasoning],
        lastUpdated: ISO8601DateFormatter().date(from: "2025-04-30T00:00:00Z")!,
        version: "3.3",
        provider: "IBM",
        contextWindow: "128K"
      ),
      DefaultModel(
        name: "Granite-3.3-8B-Instruct",
        url: URL(string: "https://huggingface.co/ibm-granite/granite-3.3-8b-instruct-GGUF/resolve/main/granite-3.3-8b-instruct-Q4_K_M.gguf?download=true")!,
        size: "4.94 GB",
        description: "IBM's Granite 3.3 8B model with extended context.",
        category: .medium,
        capabilities: [.reasoning, .creative],
        lastUpdated: ISO8601DateFormatter().date(from: "2025-04-30T00:00:00Z")!,
        version: "3.3",
        provider: "IBM",
        contextWindow: "128K"
      ),
      DefaultModel(
        name: "Gemma-3-1B-Instruct",
        url: URL(string: "https://huggingface.co/unsloth/gemma-3-1b-it-GGUF/resolve/main/gemma-3-1b-it-Q4_K_M.gguf?download=true")!,
        size: "0.80 GB",
        description: "Google's Gemma 3 1B instruct-tuned model with extended context.",
        category: .small,
        capabilities: [.multilingual, .fast],
        lastUpdated: ISO8601DateFormatter().date(from: "2025-05-01T00:00:00Z")!,
        version: "3",
        provider: "Google",
        contextWindow: "128K"
      ),
      DefaultModel(
        name: "Phi-4-Mini-3.8B-Instruct",
        url: URL(string: "https://huggingface.co/unsloth/Phi-4-mini-instruct-GGUF/resolve/main/Phi-4-mini-instruct-Q4_K_M.gguf?download=true")!,
        size: "2.50 GB",
        description: "Microsoft's Phi 4 Mini 3.8B model with large context.",
        category: .medium,
        capabilities: [.fast, .reasoning],
        lastUpdated: ISO8601DateFormatter().date(from: "2025-04-15T00:00:00Z")!,
        version: "4-mini",
        provider: "Microsoft",
        contextWindow: "128K"
      ),
      DefaultModel(
        name: "Gemma-3-4B-Instruct",
        url: URL(string: "https://huggingface.co/unsloth/gemma-3-4b-it-GGUF/resolve/main/gemma-3-4b-it-Q4_K_M.gguf?download=true")!,
        size: "2.49 GB",
        description: "Google's Gemma 3 4B instruct-tuned model.",
        category: .medium,
        capabilities: [.multilingual, .creative],
        lastUpdated: ISO8601DateFormatter().date(from: "2025-05-02T00:00:00Z")!,
        version: "3",
        provider: "Google",
        contextWindow: "128K"
      ),
      DefaultModel(
        name: "Gemma-3-12B-Instruct",
        url: URL(string: "https://huggingface.co/unsloth/gemma-3-12b-it-GGUF/resolve/main/gemma-3-12b-it-Q4_K_M.gguf?download=true")!,
        size: "7.30 GB",
        description: "Google's Gemma 3 12B model for advanced reasoning tasks.",
        category: .large,
        capabilities: [.multilingual, .creative, .reasoning],
        lastUpdated: ISO8601DateFormatter().date(from: "2025-05-02T00:00:00Z")!,
        version: "3",
        provider: "Google",
        contextWindow: "128K"
      ),
      DefaultModel(
        name: "Mistral-Nemo-12B-Instruct",
        url: URL(string: "https://huggingface.co/starble-dev/Mistral-Nemo-12B-Instruct-2407-GGUF/resolve/main/Mistral-Nemo-12B-Instruct-2407-Q4_K_M.gguf?download=true")!,
        size: "7.20 GB",
        description: "NVIDIA's Mistral Nemo 12B instruction model.",
        category: .large,
        capabilities: [.reasoning, .coding],
        lastUpdated: ISO8601DateFormatter().date(from: "2025-05-03T00:00:00Z")!,
        version: "2407",
        provider: "NVIDIA",
        contextWindow: "8K"
      ),
      DefaultModel(
            name: "Phi-4-14B-Instruct",
            url: URL(string:
                "https://huggingface.co/theprint/ReWiz-Phi-4-14B-GGUF/resolve/main/ReWiz-Phi-4-14B.Q4_K_M.gguf?download=true"
            )!,
            size: "8.89 GB",
            description: "Microsoft's Phi 4 14B instruct-tuned model with extensive context handling.",
            category: .large,
            capabilities: [.reasoning, .multilingual],
            lastUpdated: ISO8601DateFormatter().date(from: "2025-04-28T00:00:00Z")!,
            version: "4",
            provider: "Microsoft",
            contextWindow: "128K"
        ),
    ]

  // Backup URLs for specific models in case the primary source is unavailable
  private static let backupURLs: [String: URL] = [
    "Llama-3.2-3B-Instruct-Q4_K_M.gguf": URL(string: "https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf?download=true")!,
    "llama-3-8b-instruct.Q4_K_M.gguf": URL(string: "https://huggingface.co/bartowski/Llama-3-8B-GGUF/resolve/main/llama-3-8b-instruct.Q4_K_M.gguf?download=true")!,
    "phi-3-mini-4k-instruct-q4_k_m.gguf": URL(string: "https://huggingface.co/bartowski/phi-3-mini-4k-instruct-GGUF/resolve/main/phi-3-mini-4k-instruct-q4_k_m.gguf?download=true")!,
    "ReWiz-Phi-4-14B.Q4_K_M.gguf": URL(string:
        "https://huggingface.co/theprint/ReWiz-Phi-4-14B-GGUF/resolve/main/ReWiz-Phi-4-14B.Q4_K_M.gguf?download=true"
    )!
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
