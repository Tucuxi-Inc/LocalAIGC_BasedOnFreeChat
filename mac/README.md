# Local AI GC

<div align="center">
  <img src="LocalAIGC/Assets.xcassets/AppIcon no shadow.appiconset/Local AI GC 512.png" alt="Local AI GC Logo" width="200">
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

## Available Models

Local AI GC provides a curated collection of high-quality models that you can download directly within the application. These models are organized by size and capabilities to help you choose the right one for your needs:

### Small Models (1-2GB)
- **Gemma-3-1B-Instruct** (0.80 GB)
  - Provider: Google, Context: 128K
  - Capabilities: Multilingual, Fast
  - A compact Google model ideal for quick responses with extended context

- **Granite-3.3-2B-Instruct** (1.55 GB)
  - Provider: IBM, Context: 128K
  - Capabilities: Fast, Reasoning
  - IBM's Granite 3.3 2B model with extensive context window

### Medium Models (2-5GB)
- **Llama-3.2-3B-Instruct** (2.02 GB)
  - Provider: Meta, Context: 8K
  - Capabilities: Fast, Reasoning
  - Meta's Llama 3.2 3B compact model with excellent instruction-following capabilities

- **Phi-4-Mini-3.8B-Instruct** (2.50 GB)
  - Provider: Microsoft, Context: 128K
  - Capabilities: Fast, Reasoning
  - Microsoft's Phi 4 Mini 3.8B model with large context

- **Gemma-3-4B-Instruct** (2.49 GB)
  - Provider: Google, Context: 128K
  - Capabilities: Multilingual, Creative
  - Google's Gemma 3 4B instruct-tuned model

- **Granite-3.3-8B-Instruct** (4.94 GB)
  - Provider: IBM, Context: 128K
  - Capabilities: Reasoning, Creative
  - IBM's Granite 3.3 8B model with extended context

### Large Models (5GB+)
- **Gemma-3-12B-Instruct** (7.30 GB)
  - Provider: Google, Context: 128K
  - Capabilities: Multilingual, Creative, Reasoning
  - Google's Gemma 3 12B model for advanced reasoning tasks

- **Mistral-Nemo-12B-Instruct** (7.20 GB)
  - Provider: NVIDIA, Context: 8K
  - Capabilities: Reasoning, Coding
  - NVIDIA's Mistral Nemo 12B instruction model

- **Phi-4-14B-Instruct** (8.89 GB)
  - Provider: Microsoft, Context: 128K
  - Capabilities: Reasoning, Multilingual
  - Microsoft's Phi 4 14B instruct-tuned model with extensive context handling

## Model Compatibility

Besides the built-in models listed above, Local AI GC works with most models in GGUF format. You can add your own models by:
1. Going to Settings > AI Settings
2. Clicking "Add or Remove Models..."
3. Selecting a GGUF file from your computer

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
