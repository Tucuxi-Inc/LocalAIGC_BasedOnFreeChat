# Local AI GC

<div align="center">
  <img src="FreeChat/Assets.xcassets/AppIcon.appiconset/Local AI GC 512.png" alt="Local AI GC Logo" width="200">
  <h1>Local AI GC</h1>
  <p><strong>Privacy-First AI Chat for macOS</strong></p>
</div>

Local AI GC is a native macOS application that lets you chat with AI models locally on your Mac, without sending your data to external servers. It's based on the open-source [FreeChat](https://github.com/psugihara/FreeChat) project.

## Features

- **100% Local Processing**: All AI processing happens on your device - no data leaves your computer
- **Support for GGUF Models**: Compatible with Llama, Mistral, and other models in GGUF format
- **Intuitive macOS Interface**: Native experience with macOS design patterns
- **Easy Model Management**: Download and switch between different models
- **Customizable System Prompts**: Tailor the AI's behavior to your needs
- **Keyboard Shortcuts**: Quick access to create new conversations

## Getting Started

1. Download and install Local AI GC
2. Launch the app
3. Download a model or load your own custom model
4. Start chatting with your local AI!

## Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| New Conversation | ⌘N |
| Delete Conversation | ⌫ (Delete) |
| Focus on Message Input | ⌘L |
| Send Message | Return/Enter (when input is focused) |
| Copy Selected Message | ⌘C (with message selected) |
| Summon Application | Customizable via Preferences |

## Model Compatibility

Local AI GC works with most models in GGUF format. Recommended models include:
- Llama-3.2-3B-Instruct-Q4_K_M.gguf (default)
- Mistral-7B-Instruct-v0.1.Q4_K_M.gguf
- Any other GGUF-formatted models

## System Requirements

- macOS 15.0 or later
- Apple silicon or Intel processor
- Minimum 4GB RAM (8GB+ recommended for larger models)
- 4GB+ free disk space (varies by model size)

## About This Project

Local AI GC is a fork of the FreeChat project, customized to provide a focused, privacy-first AI chat experience. We've updated the interface, optimized performance, and added features while maintaining the core philosophy of keeping all AI processing local.

## Acknowledgements

Local AI GC is built upon [FreeChat](https://github.com/psugihara/FreeChat), created by Peter Sugihara and contributors. The application uses [llama.cpp](https://github.com/ggerganov/llama.cpp) by Georgi Gerganov to run AI models locally.

We extend our gratitude to all the open-source projects that made this application possible:
- The llama.cpp community
- FreeChat contributors
- The creators of the various GGUF models

## License

This software is distributed under the MIT License, the same as the original FreeChat project. 