//
//  ContentView.swift
//  Mantras
//
//  Created by Peter Sugihara on 7/31/23.
//

import AppKit
import CoreData
import KeyboardShortcuts
import SwiftUI

struct ContentView: View {
  @Environment(\.managedObjectContext) private var viewContext
  @Environment(\.openWindow) private var openWindow

  @AppStorage("systemPrompt") private var systemPrompt: String = DEFAULT_SYSTEM_PROMPT
  @AppStorage("firstLaunchComplete") private var firstLaunchComplete = false

  @FetchRequest(
    sortDescriptors: [NSSortDescriptor(keyPath: \Model.size, ascending: false)]
  )
  private var models: FetchedResults<Model>

  @FetchRequest(
    sortDescriptors: [NSSortDescriptor(keyPath: \Conversation.updatedAt, ascending: true)]
  )
  private var conversations: FetchedResults<Conversation>

  @State private var selection: Set<Conversation> = Set()
  @State private var showDeleteConfirmation = false
  @State private var showWelcome = false
  @State private var setInitialSelection = false
  @State private var isServerStarting = false
  @State private var serverStartProgress = 0.0

  var agent: Agent? {
    conversationManager.agent
  }

  @EnvironmentObject var conversationManager: ConversationManager

  var body: some View {
    NavigationSplitView {
      if setInitialSelection {
        NavList(selection: $selection, showDeleteConfirmation: $showDeleteConfirmation)
          .navigationSplitViewColumnWidth(min: 160, ideal: 160)
      }
    } detail: {
      if selection.count > 1 {
        Text("\(selection.count) conversations selected")
      } else if conversationManager.showConversation() {
        ConversationView()
      } else if conversations.count == 0 {
        Text("Hit ⌘N to start a conversation")
      } else {
        Text("Select a conversation")
      }
    }
    .onReceive(
      NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification),
      perform: { output in
        Task {
          await agent?.llama.stopServer()
        }
      }
    )
    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("needStartNewConversation"))) { _ in
      conversationManager.newConversation(viewContext: viewContext, openWindow: openWindow)
    }
    .onDeleteCommand { showDeleteConfirmation = true }
    .onAppear(perform: initializeFirstLaunchData)
    .onChange(of: selection) { nextSelection in
      if nextSelection.count == 1,
        let first = nextSelection.first
      {
        if first != conversationManager.currentConversation {
          conversationManager.currentConversation = first
        }
      } else {
        conversationManager.unsetConversation()
      }
    }
    .onChange(of: conversationManager.currentConversation) { nextCurrent in
      if conversationManager.showConversation(), !selection.contains(nextCurrent) {
        selection = Set([nextCurrent])
      }
    }
    .onChange(of: models.count, perform: handleModelCountChange)
    .sheet(isPresented: $showWelcome) {
      WelcomeSheet(isPresented: $showWelcome)
    }
    .onChange(of: isServerStarting) { newValue in
      if newValue {
        Task {
          await startServer()
        }
      }
    }
    .onChange(of: serverStartProgress) { newValue in
      if newValue == 1.0 {
        isServerStarting = false
      }
    }
    if isServerStarting {
      ProgressView("Starting AI model...", value: serverStartProgress, total: 1.0)
        .progressViewStyle(LinearProgressViewStyle())
        .padding()
    }
  }

  private func handleModelCountChange(_ nextCount: Int) {
    showWelcome = showWelcome || nextCount == 0
  }

  private func initializeFirstLaunchData() {
    if let c = conversations.last {
      selection = Set([c])
    }
    setInitialSelection = true

    if !conversationManager.summonRegistered {
      KeyboardShortcuts.onKeyUp(for: .summonFreeChat) {
        NSApp.activate(ignoringOtherApps: true)
        conversationManager.newConversation(viewContext: viewContext, openWindow: openWindow)
      }
      conversationManager.summonRegistered = true
    }

    try? fetchModelsSyncLocalFiles()
    handleModelCountChange(models.count)

    if firstLaunchComplete { return }
    conversationManager.newConversation(viewContext: viewContext, openWindow: openWindow)
    firstLaunchComplete = true
  }

  private func fetchModelsSyncLocalFiles() throws {
    for model in models {
      if try model.url?.checkResourceIsReachable() != true {
        viewContext.delete(model)
      }
    }
    
    try viewContext.save()
  }

  private func startServer() async {
    isServerStarting = true
    serverStartProgress = 0.0
    // Simulate server starting process
    for _ in 0..<10 {
      try? await Task.sleep(nanoseconds: 500_000_000) // Wait between 0.5 and 1 seconds
      serverStartProgress += 0.1
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    let context = PersistenceController.preview.container.viewContext
    ContentView()
      .environment(\.managedObjectContext, context)
      .environmentObject(ConversationManager.shared)
  }
}
