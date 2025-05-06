//
//  FreeChatAppDelegate.swift
//  FreeChat
//

import SwiftUI
import ObjectiveC

// Extension to override the application name
extension Bundle {
  static func swizzle() {
    let originalSelector = #selector(getter: Bundle.infoDictionary)
    let swizzledSelector = #selector(Bundle.swizzledInfoDictionary)
    
    let originalMethod = class_getInstanceMethod(self, originalSelector)
    let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
    
    if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
      method_exchangeImplementations(originalMethod, swizzledMethod)
    }
  }
  
  @objc func swizzledInfoDictionary() -> [String: Any]? {
    var info = self.swizzledInfoDictionary()
    
    if self == Bundle.main {
      // Replace the display name and bundle name
      info?["CFBundleName"] = "Local AI GC"
      info?["CFBundleDisplayName"] = "Local AI GC"
    }
    
    return info
  }
}

class FreeChatAppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
  @AppStorage("selectedModelId") private var selectedModelId: String?

  func applicationWillFinishLaunching(_ notification: Notification) {
    // Swizzle the Bundle methods before the app fully launches
    Bundle.swizzle()
  }
  
  func applicationDidFinishLaunching(_ notification: Notification) {
    // Add a slight delay to ensure the menu is fully initialized
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      self.updateMainMenuTitle()
    }
  }
  
  private func updateMainMenuTitle() {
    // Get main menu
    if let mainMenu = NSApplication.shared.mainMenu {
      // App menu is usually the first item
      if let appMenuItem = mainMenu.items.first {
        // Update app menu title
        appMenuItem.title = "Local AI GC"
        
        // Also update items in the submenu
        if let appMenu = appMenuItem.submenu {
          for item in appMenu.items {
            if item.title.contains("About FreeChat") {
              item.title = "About Local AI GC"
            } else if item.title == "Hide FreeChat" {
              item.title = "Hide Local AI GC"
            } else if item.title == "Quit FreeChat" {
              item.title = "Quit Local AI GC"
            }
          }
        }
      }
    }
  }

  func application(_ application: NSApplication, open urls: [URL]) {
    let viewContext = PersistenceController.shared.container.viewContext
    do {
      let req = Model.fetchRequest()
      req.predicate = NSPredicate(format: "name IN %@", urls.map({ $0.lastPathComponent }))
      let existingModels = try viewContext.fetch(req).compactMap({ $0.url })

      for url in urls {
        guard !existingModels.contains(url) else { continue }
        let insertedModel = try Model.create(context: viewContext, fileURL: url)
        selectedModelId = insertedModel.id?.uuidString
      }
      
      NotificationCenter.default.post(name: NSNotification.Name("selectedModelDidChange"), object: selectedModelId)
      NotificationCenter.default.post(name: NSNotification.Name("needStartNewConversation"), object: selectedModelId)
    } catch {
      print("error saving model:", error)
    }
  }
}
