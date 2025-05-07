//
//  MessageTextField.swift
//  Chats
//
//  Created by Peter Sugihara on 8/5/23.
//

import SwiftUI
import Speech
import AVFoundation

struct ChatStyle: TextFieldStyle {
  @Environment(\.colorScheme) var colorScheme
  var focused: Bool
  let cornerRadius = 16.0
  var rect: RoundedRectangle {
    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
  }
  func _body(configuration: TextField<Self._Label>) -> some View {
    configuration
      .textFieldStyle(.plain)
      .frame(maxWidth: .infinity)
      .padding(EdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 6))
      .padding(8)
      .cornerRadius(cornerRadius)
      .background(
      LinearGradient(colors: [Color.textBackground, Color.textBackground.opacity(0.5)], startPoint: .leading, endPoint: .trailing)
    )
      .mask(rect)
      .overlay(rect.stroke(.separator, lineWidth: 1)) /* border */
      .animation(focused ? .easeIn(duration: 0.2) : .easeOut(duration: 0.0), value: focused)
  }
}

struct BlurredView: NSViewRepresentable {
  func makeNSView(context: Context) -> some NSVisualEffectView {
    let view = NSVisualEffectView()
    view.material = .headerView
    view.blendingMode = .withinWindow

    return view
  }

  func updateNSView(_ nsView: NSViewType, context: Context) { }
}

struct MessageTextField: View {
  @State var input: String = ""
  @StateObject private var speechManager = SpeechRecognitionManager()

  @EnvironmentObject var conversationManager: ConversationManager
  var conversation: Conversation { conversationManager.currentConversation }

  var onSubmit: (String) -> Void
  @State var showNullState = false

  @FocusState private var focused: Bool
  
  // Animation properties for the mic button
  @State private var isAnimating = false

  var nullState: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack {
        ForEach(QuickPromptButton.quickPrompts) { p in
          QuickPromptButton(input: $input, prompt: p)
        }
      }.padding(.horizontal, 10).padding(.top, 200)

    }.frame(maxWidth: .infinity)
  }
  
  // Microphone button view
  var microphoneButton: some View {
    Button(action: {
      if speechManager.isRecording {
        speechManager.stopRecording()
      } else {
        speechManager.startRecording()
      }
    }) {
      Image(systemName: speechManager.isRecording ? "mic.fill" : "mic.slash.fill")
        .font(.system(size: 18))
        .foregroundColor(speechManager.isRecording ? .red : .blue)
        .frame(width: 30, height: 30)
        .background(
          Circle()
            .fill(Color.secondary.opacity(0.1))
            .scaleEffect(isAnimating ? 1.1 : 1.0)
        )
        .overlay(
          Circle()
            .stroke(speechManager.isRecording ? Color.red : Color.blue, lineWidth: 1.5)
            .scaleEffect(isAnimating ? 1.1 : 1.0)
        )
    }
    .buttonStyle(PlainButtonStyle())
    .padding(.leading, 10)
    .opacity(speechManager.isAuthorized ? 1.0 : 0.5)
    .disabled(!speechManager.isAuthorized)
    .help(speechManager.isAuthorized ? 
          (speechManager.isRecording ? "Stop voice input" : "Start voice input") : 
          "Speech recognition not authorized")
    .onAppear {
      startAnimation()
    }
  }
  
  private func startAnimation() {
    guard speechManager.isRecording else { return }
    
    withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
      isAnimating = true
    }
  }
  
  private func stopAnimation() {
    isAnimating = false
  }

  var inputField: some View {
    Group {
      HStack(spacing: 0) {
        // Microphone button
        microphoneButton
        
        // Text field
        TextField("Message", text: Binding(
          get: { 
            // If recording, show the transcribed text
            speechManager.isRecording ? speechManager.transcribedText : input
          },
          set: { newValue in
            // Only update our input if not recording
            if !speechManager.isRecording {
              input = newValue
            }
          }
        ), axis: .vertical)
        .onSubmit {
          if CGKeyCode.kVK_Shift.isPressed {
            input += "\n"
          } else if input.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
            onSubmit(input)
            input = ""
          }
        }
        .focused($focused)
        .textFieldStyle(ChatStyle(focused: focused))
        .submitLabel(.send)
        .padding(.all, 10)
        .onAppear {
          self.focused = true
        }
        .onChange(of: conversation) { nextConversation in
          if conversationManager.showConversation() {
            self.focused = true
            QuickPromptButton.quickPrompts.shuffle()
          }
        }
      }
    }
    .background(BlurredView().ignoresSafeArea())
    .alert(speechManager.errorMessage, isPresented: $speechManager.showErrorAlert) {
      Button("OK", role: .cancel) {}
    }
    // When recording stops, update the input field with the transcribed text
    .onChange(of: speechManager.isRecording) { isRecording in
      if isRecording {
        startAnimation()
      } else {
        stopAnimation()
        if !speechManager.transcribedText.isEmpty {
          input = speechManager.transcribedText
        }
      }
    }
  }

  var body: some View {
    let messages = conversation.messages
    let showNullState = input == "" && (messages == nil || messages!.count == 0)

    VStack(alignment: .trailing) {
      if showNullState {
        nullState.transition(.asymmetric(insertion: .push(from: .trailing), removal: .identity))
      }
      inputField
    }
  }
}

//#if DEBUG
//struct MessageTextField_Previews: PreviewProvider {
//  static var previews: some View {
//    MessageTextField(conversation: c, onSubmit: { _ in print("submit") })
//      .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
//  }
//}
//#endif
