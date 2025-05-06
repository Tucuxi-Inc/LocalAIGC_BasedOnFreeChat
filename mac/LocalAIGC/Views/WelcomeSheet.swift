//
//  WelcomeSheet.swift
//  LocalAIGC
//
//  Created by Peter Sugihara on 9/28/23.
//

import SwiftUI
import CoreData

struct WelcomeSheet: View {
  @FetchRequest(
    sortDescriptors: [NSSortDescriptor(keyPath: \Model.size, ascending: false)]
  )
  private var models: FetchedResults<Model>
  
  @Binding var isPresented: Bool
  @State var showModels = false
  @State var showModelGallery = false
  
  @Environment(\.managedObjectContext) private var viewContext
  @AppStorage("selectedModelId") private var selectedModelId: String?

  @StateObject var downloadManager = DownloadManager.shared
  
  
  var body: some View {
    VStack {
      if models.count == 0 {
        Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
        Text("Welcome to LocalAIGC").font(.largeTitle)

        Text("Download a model to get started")
          .font(.title3)
        Text("LocalAIGC runs AI locally on your Mac for maximum privacy and security. You can chat with different AI models, which vary in terms of training data and knowledge base.\n\nThe default model is general purpose, small, and works on most computers. Larger models are slower but wiser. Some models specialize in certain tasks like coding Python. LocalAIGC is compatible with most models in GGUF format. [Find new models](https://huggingface.co/models?search=GGUF)")
          .font(.callout)
          .lineLimit(10)
          .fixedSize(horizontal: false, vertical: true)
          .padding(.vertical, 16)
        
        ForEach(downloadManager.tasks, id: \.self) { t in
          ProgressView(t.progress).padding(5)
        }
      } else {
        Image(systemName: "checkmark.circle.fill")
          .resizable()
          .frame(width: 60, height: 60)
          .foregroundColor(.green)
          .imageScale(.large)
        
        Text("Success!").font(.largeTitle)

        Text("The model was installed.")
          .font(.title3)
        
        Button("Continue") {
          isPresented = false
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .padding(.top, 16)
        .padding(.horizontal, 40)
        .keyboardShortcut(.defaultAction)
      }

      if models.count == 0, downloadManager.tasks.count == 0 {
        Button(action: downloadDefault) {
          HStack {
            Text("Download default model")
            Text("2.02 GB").foregroundStyle(.white.opacity(0.7))
          }.padding(.horizontal, 20)
        }
        .keyboardShortcut(.defaultAction)
        .controlSize(.large)
        .padding(.top, 6)
        .padding(.horizontal)
        
        Button("Browse model gallery") {
          showModelGallery = true
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .padding(.top, 10)
        
        Button("Load custom model") {
          showModels = true
        }.buttonStyle(.link)
          .padding(.top, 8)
          .font(.callout)
      } else {

      }
    }
    .interactiveDismissDisabled()
    .frame(maxWidth: 480)
    .padding(.vertical, 40)
    .padding(.horizontal, 60)
    .sheet(isPresented: $showModels) {
      EditModels(selectedModelId: $selectedModelId)
    }
    .sheet(isPresented: $showModelGallery) {
      ModelGalleryView()
    }
  }
  
  private func downloadDefault() {
    downloadManager.viewContext = viewContext
    downloadManager.startDownload(url: Model.defaultModelUrl)
  }
}

struct WelcomeSheet_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      // Default preview
      WelcomeSheet(isPresented: .constant(true))
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(ConversationManager.shared)
        .previewDisplayName("Default")
      
      // Success preview - with a model already created
      SuccessPreview()
        .previewDisplayName("Success")
    }
  }
  
  // Helper view for the success scenario
  struct SuccessPreview: View {
    let context: NSManagedObjectContext
    
    init() {
      self.context = PersistenceController.preview.container.viewContext
      let m = Model(context: context)
      m.name = "spicyboros_7b.gguff"
    }
    
    var body: some View {
      WelcomeSheet(isPresented: .constant(true))
        .environment(\.managedObjectContext, context)
        .environmentObject(ConversationManager.shared)
    }
  }
}

// Note: Replaced the newer #Preview macros with traditional PreviewProvider
// as @Previewable is only available in macOS 14.0 or newer
