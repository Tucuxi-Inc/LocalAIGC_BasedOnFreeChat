//
//  ModelGalleryView.swift
//  FreeChat
//
//  Created by Claude on 4/29/25.
//

import SwiftUI
import CommonCrypto

struct ModelGalleryView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var conversationManager: ConversationManager
    
    @StateObject private var downloadManager = DownloadManager.shared
    
    @State private var selectedModelForDetails: DefaultModel?
    @State private var searchText = ""
    @State private var selectedCategory: ModelCategory?
    @State private var selectedCapability: ModelCapability?
    @State private var showDownloadHistory = false
    @State private var downloadProgress: [URL: Double] = [:]
    @State private var downloadStatuses: [URL: DownloadStatus] = [:]
    @State private var showVerificationAlert = false
    @State private var verificationMessage = ""
    @State private var failedVerificationURL: URL?
    
    enum DownloadStatus {
        case downloading
        case paused
        case completed
        case failed(Error)
        case verifying
    }
    
    var filteredModels: [DefaultModel] {
        var filtered = Model.defaultModels
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { model in
                model.name.localizedCaseInsensitiveContains(searchText) ||
                model.description.localizedCaseInsensitiveContains(searchText) ||
                model.provider.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by category
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Filter by capability
        if let capability = selectedCapability {
            filtered = filtered.filter { $0.capabilities.contains(capability) }
        }
        
        return filtered
    }
    
    var groupedModels: [ModelCategory: [DefaultModel]] {
        Dictionary(grouping: filteredModels, by: { $0.category })
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with search field and filters
            VStack(spacing: 12) {
                HStack {
                    Text("Model Gallery")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()
                    
                    TextField("Search models", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 200)
                }
                
                HStack(spacing: 12) {
                    // Category filter
                    Menu {
                        Button("All Sizes") {
                            selectedCategory = nil
                        }
                        
                        ForEach(ModelCategory.allCases, id: \.self) { category in
                            Button(category.rawValue) {
                                selectedCategory = category
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedCategory?.rawValue ?? "All Sizes")
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Capability filter
                    Menu {
                        Button("All Capabilities") {
                            selectedCapability = nil
                        }
                        
                        ForEach(ModelCapability.allCases, id: \.self) { capability in
                            Button(capability.rawValue) {
                                selectedCapability = capability
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedCapability?.rawValue ?? "All Capabilities")
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showDownloadHistory.toggle()
                    }) {
                        Label("Downloads", systemImage: "arrow.down.circle")
                    }
                    .buttonStyle(.bordered)
                    .popover(isPresented: $showDownloadHistory, arrowEdge: .bottom) {
                        DownloadHistoryView()
                            .frame(width: 300, height: 300)
                    }
                }
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            
            if filteredModels.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No models match your search")
                        .font(.title3)
                    Text("Try adjusting your filters or search term")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Model list grouped by category
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(ModelCategory.allCases, id: \.self) { category in
                            if let models = groupedModels[category], !models.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(category.rawValue)
                                        .font(.headline)
                                        .padding(.horizontal)
                                    
                                    ForEach(models) { model in
                                        modelCard(for: model)
                                            .padding(.horizontal)
                                        
                                        if models.last?.id != model.id {
                                            Divider()
                                                .padding(.horizontal)
                                        }
                                    }
                                }
                                
                                Divider()
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            
            // Bottom toolbar
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Text("Done")
                        .frame(width: 80)
                }
                .keyboardShortcut(.escape)
            }
            .padding()
            .background(Material.bar)
        }
        .frame(width: 700, height: 600)
        .sheet(item: $selectedModelForDetails) { model in
            modelDetailView(for: model)
        }
        .alert(isPresented: $showVerificationAlert) {
            Alert(
                title: Text("Model Verification"),
                message: Text(verificationMessage),
                primaryButton: .default(Text("Download Again"), action: {
                    if let url = failedVerificationURL,
                       let model = Model.defaultModels.first(where: { $0.url == url }) {
                        downloadModel(model, retryWithBackup: true)
                    }
                }),
                secondaryButton: .cancel()
            )
        }
        .onAppear {
            // Initialize download progress for any ongoing downloads
            for task in downloadManager.tasks {
                if let url = task.originalRequest?.url {
                    downloadStatuses[url] = .downloading
                }
            }
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    private func modelCard(for model: DefaultModel) -> some View {
        HStack(alignment: .top, spacing: 15) {
            // Model info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(model.name)
                        .font(.headline)
                    
                    Text("v\(model.version)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text(model.provider)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(model.contextWindow)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text(model.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // Capability tags
                HStack {
                    ForEach(model.capabilities, id: \.self) { capability in
                        HStack(spacing: 4) {
                            Image(systemName: iconFor(capability: capability))
                                .font(.caption)
                            Text(capability.rawValue)
                                .font(.caption)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(colorFor(capability: capability).opacity(0.2))
                        .cornerRadius(4)
                    }
                }
            }
            
            Spacer()
            
            // Download button/progress
            VStack(alignment: .trailing, spacing: 6) {
                Text("\(model.size) MB")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(4)
                
                Group {
                    if let status = downloadStatuses[model.url] {
                        switch status {
                        case .downloading:
                            VStack(spacing: 4) {
                                HStack(spacing: 4) {
                                    ProgressView()
                                        .scaleEffect(0.5)
                                        .frame(width: 12, height: 12)
                                    
                                    Text("\(Int((downloadProgress[model.url] ?? 0) * 100))%")
                                        .font(.caption)
                                }
                                
                                Button("Cancel") {
                                    cancelDownload(url: model.url)
                                }
                                .buttonStyle(.borderless)
                                .controlSize(.small)
                                .font(.caption)
                            }
                            
                        case .paused:
                            Button("Resume") {
                                resumeDownload(model)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            
                        case .verifying:
                            HStack(spacing: 4) {
                                ProgressView()
                                    .scaleEffect(0.5)
                                    .frame(width: 12, height: 12)
                                Text("Verifying")
                                    .font(.caption)
                            }
                            
                        case .completed:
                            Text("Installed")
                                .font(.caption)
                                .foregroundColor(.green)
                            
                        case .failed(let error):
                            Button("Retry") {
                                downloadModel(model)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .help(error.localizedDescription)
                        }
                    } else {
                        Button("Download") {
                            downloadModel(model)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .frame(width: 100)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            selectedModelForDetails = model
        }
    }
    
    private func modelDetailView(for model: DefaultModel) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.name)
                        .font(.title)
                    
                    HStack {
                        Text("by \(model.provider)")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text("Version \(model.version)")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text("\(model.size) MB")
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(6)
            }
            
            Divider()
            
            // Details
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        
                        Text(model.description)
                            .lineLimit(nil)
                    }
                    
                    // Capabilities
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Capabilities")
                            .font(.headline)
                        
                        HStack {
                            ForEach(model.capabilities, id: \.self) { capability in
                                HStack(spacing: 4) {
                                    Image(systemName: iconFor(capability: capability))
                                    Text(capability.rawValue)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(colorFor(capability: capability).opacity(0.2))
                                .cornerRadius(8)
                            }
                        }
                    }
                    
                    // Technical details
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Technical Details")
                            .font(.headline)
                        
                        HStack(spacing: 20) {
                            VStack(alignment: .leading) {
                                Text("Context Window")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(model.contextWindow)
                                    .font(.body)
                            }
                            
                            VStack(alignment: .leading) {
                                Text("Updated")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(model.lastUpdated, style: .date)
                                    .font(.body)
                            }
                        }
                    }
                    
                    // System requirements
                    VStack(alignment: .leading, spacing: 8) {
                        Text("System Requirements")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• Minimum \(minimumRAMFor(model: model)) RAM")
                            Text("• \(model.size) free disk space")
                            if model.category == .large {
                                Text("• Apple Silicon recommended")
                            }
                        }
                    }
                }
                .padding(.bottom)
            }
            
            Divider()
            
            // Actions
            HStack {
                Spacer()
                
                if let status = downloadStatuses[model.url] {
                    switch status {
                    case .downloading:
                        VStack(spacing: 4) {
                            ProgressView(value: downloadProgress[model.url] ?? 0)
                                .frame(width: 150)
                            Text("Downloading \(Int((downloadProgress[model.url] ?? 0) * 100))%")
                                .font(.caption)
                        }
                        .padding(.trailing, 10)
                        
                        Button("Pause") {
                            pauseDownload(url: model.url)
                        }
                        
                        Button("Cancel") {
                            cancelDownload(url: model.url)
                        }
                        
                    case .paused:
                        Text("Download Paused")
                            .foregroundColor(.orange)
                            .padding(.trailing, 10)
                        
                        Button("Resume") {
                            resumeDownload(model)
                        }
                        
                    case .verifying:
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Verifying Download...")
                        }
                        
                    case .completed:
                        Text("Installed")
                            .foregroundColor(.green)
                            .padding(.trailing, 10)
                        
                    case .failed(let error):
                        Text(error.localizedDescription)
                            .foregroundColor(.red)
                            .padding(.trailing, 10)
                            .lineLimit(1)
                        
                        Button("Try Again") {
                            downloadModel(model)
                        }
                    }
                } else {
                    Button(action: {
                        downloadModel(model)
                        selectedModelForDetails = nil
                    }) {
                        Text("Download")
                            .frame(minWidth: 100)
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Button("Cancel") {
                    selectedModelForDetails = nil
                }
                .keyboardShortcut(.escape)
            }
        }
        .padding()
        .frame(width: 600, height: 500)
    }
    
    // MARK: - Helpers
    
    private func iconFor(capability: ModelCapability) -> String {
        switch capability {
        case .fast:
            return "bolt.fill"
        case .multilingual:
            return "globe"
        case .coding:
            return "curlybraces"
        case .creative:
            return "sparkles"
        case .reasoning:
            return "brain.head.profile"
        case .longContext:
            return "doc.text.magnifyingglass"
        }
    }
    
    private func colorFor(capability: ModelCapability) -> Color {
        switch capability {
        case .fast:
            return .blue
        case .multilingual:
            return .green
        case .coding:
            return .purple
        case .creative:
            return .orange
        case .reasoning:
            return .red
        case .longContext:
            return .teal
        }
    }
    
    private func minimumRAMFor(model: DefaultModel) -> String {
        switch model.category {
        case .small:
            return "4GB"
        case .medium:
            return "8GB"
        case .large:
            return "16GB"
        }
    }
    
    // MARK: - Download Management
    
    private func downloadModel(_ model: DefaultModel, retryWithBackup: Bool = false) {
        downloadManager.viewContext = viewContext
        
        let urlToUse: URL
        if retryWithBackup, let backupURL = Model.getBackupURL(for: model.name) {
            urlToUse = backupURL
        } else {
            urlToUse = model.url
        }
        
        downloadStatuses[model.url] = .downloading
        downloadProgress[model.url] = 0.0
        
        // Remove any existing observers before adding new ones
        NotificationCenter.default.removeObserver(self)
        
        // Create an observer for download progress
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("DownloadProgressUpdated"),
            object: nil,
            queue: .main
        ) { notification in
            if let userInfo = notification.userInfo,
               let url = userInfo["url"] as? URL,
               let progress = userInfo["progress"] as? Double,
               url == model.url {
                downloadProgress[model.url] = progress
            }
        }
        
        // Create an observer for download completion
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("DownloadCompleted"),
            object: nil,
            queue: .main
        ) { notification in
            if let userInfo = notification.userInfo,
               let url = userInfo["url"] as? URL,
               let localURL = userInfo["localURL"] as? URL,
               url == model.url {
                downloadStatuses[model.url] = .verifying
                
                // Verify the downloaded file if hash is available
                Task {
                    if let expectedHash = Model.getExpectedHash(for: model.name) {
                        let isValid = await self.verifyFileHash(url: localURL, expectedHash: expectedHash)
                        
                        DispatchQueue.main.async {
                            if isValid {
                                self.downloadStatuses[model.url] = .completed
                            } else {
                                self.failedVerificationURL = model.url
                                self.verificationMessage = "The downloaded model appears to be corrupted or incomplete. Would you like to try downloading it again?"
                                self.showVerificationAlert = true
                                self.downloadStatuses[model.url] = .failed(NSError(domain: "ModelGallery", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Verification failed"]))
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.downloadStatuses[model.url] = .completed
                        }
                    }
                }
            }
        }
        
        // Create an observer for download failure
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("DownloadFailed"),
            object: nil,
            queue: .main
        ) { notification in
            if let userInfo = notification.userInfo,
               let url = userInfo["url"] as? URL,
               let error = userInfo["error"] as? Error,
               url == model.url {
                downloadStatuses[model.url] = .failed(error)
            }
        }
        
        downloadManager.startDownload(url: urlToUse)
    }
    
    private func pauseDownload(url: URL) {
        // Implement when DownloadManager supports pausing
        downloadStatuses[url] = .paused
    }
    
    private func resumeDownload(_ model: DefaultModel) {
        // Clear existing status and restart download
        downloadStatuses[model.url] = nil
        downloadModel(model)
    }
    
    private func cancelDownload(url: URL) {
        // Implement when DownloadManager supports cancellation
        downloadStatuses[url] = nil
        downloadProgress[url] = nil
        
        // For now, just remove tasks from UI - would need to actually cancel in DownloadManager
        let tasksToCancel = downloadManager.tasks.filter { $0.originalRequest?.url == url }
        for task in tasksToCancel {
            task.cancel()
        }
    }
    
    private func verifyFileHash(url: URL, expectedHash: String) async -> Bool {
        do {
            let fileData = try Data(contentsOf: url)
            var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
            
            _ = fileData.withUnsafeBytes {
                CC_SHA256($0.baseAddress, CC_LONG(fileData.count), &digest)
            }
            
            let hash = digest.map { String(format: "%02x", $0) }.joined()
            return hash == expectedHash
        } catch {
            print("Error verifying hash: \(error)")
            return false
        }
    }
}

// MARK: - Download History View

struct DownloadHistoryView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Model.updatedAt, ascending: false)]
    )
    private var models: FetchedResults<Model>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Downloaded Models")
                .font(.headline)
                .padding()
            
            Divider()
            
            if models.isEmpty {
                VStack {
                    Text("No downloaded models")
                        .foregroundColor(.secondary)
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(models) { model in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(model.name ?? "Unknown Model")
                                    .fontWeight(.medium)
                                if let updatedAt = model.updatedAt {
                                    Text("Downloaded on \(updatedAt, style: .date)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Text("\(model.size) MB")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
}

struct ModelGalleryView_Previews: PreviewProvider {
    static var previews: some View {
        ModelGalleryView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(ConversationManager.shared)
    }
} 