# OpenResponses

OpenResponses is a native SwiftUI app for iOS and macOS, designed as a powerful and flexible playground for exploring the full range of OpenAI's API capabilities. It provides a robust chat interface, deep tool integration, and extensive customization options for developers and power users aiming to work with the latest models and features.

This project is currently in a "super beta" state, with a focus on achieving 100% compliance with the latest OpenAI APIs, including advanced tools like `computer` and backend conversation management.

![App Screenshot](ABFB8418-0099-402B-B479-E4789A6E3536.PNG)

## 🚀 Features

### Core Functionality

- **Multi-Model Support**: Switch between a wide range of models, categorized for clarity:
    - **Latest Models**: `gpt-5`, `gpt-4.1`, and their variants.
    - **Standard Models**: `gpt-4o`, `gpt-4`, and `gpt-3.5-turbo`.
    - **Reasoning Models**: `o-series` models for complex, multi-step tasks.
    - **Specialized Models**: `computer-use-preview` for browser automation tasks.
- **Dynamic Model Selection**: Automatically fetches and displays the latest available models from OpenAI's API with intelligent categorization.
- **Enhanced Streaming Experience**: Real-time responses with granular status updates showing when the AI is thinking, searching the web, generating code, or running specific tools.
- **Cancellable Operations**: Stop streaming responses mid-generation with full control.
- **Native SwiftUI Interface**: A clean, responsive, and platform-native experience for iOS and macOS.

### Powerful Tool Integration

- **Computer Use**: A production-ready tool (primarily for the `computer-use-preview` model) that allows the model to control a web browser to perform complex tasks. It supports a full range of actions including navigation, clicking, typing, and scrolling with robust error handling.
- **Web Search**: Access up-to-date information from the internet, with support for both standard and preview search capabilities.
- **Code Interpreter**: Execute Python code in a secure, sandboxed environment. Features include:
    - **Container Selection**: Choose between `auto`, `secure`, or `gpu` execution environments.
    - **File Preloading**: Provide file IDs to be available in the sandbox from the start.
    - **Artifact Parsing**: Richly displays outputs like logs, images, and data files.
- **Image Generation**: Create images from text prompts using `gpt-image-1` with real-time streaming previews and configurable quality settings.
- **File Search**: Perform searches across multiple vector stores simultaneously, enabling powerful knowledge retrieval from uploaded documents.
- **MCP Integration**: Connect to Model Context Protocol (MCP) servers for extended functionality, featuring a discovery service for popular platforms and a secure approval workflow.
- **Custom Functions**: Define and call your own custom functions within the chat flow.

### Advanced File & Data Management

- **Direct File Uploads**: Upload files directly from your device for use in prompts, supporting over 43 file types.
- **Vector Store Management**: Organize and manage documents in vector stores for efficient file searching.
- **Smart Organization**: Group related documents for better search results.

### Prompt Management & Presets

- **Prompt Library**: Save, manage, and reuse custom prompt configurations.
- **Preset System**: Create named presets with all settings (models, tools, parameters).
- **Quick Switching**: Instantly switch between different conversation configurations.

### Advanced API Controls & Customization

- **Core Parameters**: Adjust `temperature`, `max_output_tokens`, `presence_penalty`, `frequency_penalty`, `top_p`, and more.
- **Advanced Reasoning**: Configure summary output for O-series models.
- **Include Controls**: Choose what additional data to include in API responses.
- **Service Tier Management**: Configure API service tiers and background processing.
- **Parallel Tool Calls**: Control concurrent tool execution for efficiency.

### Development & Debugging Tools

- **API Inspector**: View detailed API requests and responses for transparency and debugging.
- **Debug Console**: Real-time debug logs with filtering by level and category.
- **Analytics Dashboard**: Comprehensive request tracking and performance monitoring.
- **Network Logging**: Detailed request/response logging with JSON pretty-printing.

### Accessibility & User Experience

- **Full Accessibility Support**: VoiceOver compatibility with proper labels, hints, and navigation.
- **Dynamic Type Support**: Adapts to user's preferred text sizes.
- **Keyboard Navigation**: Complete keyboard accessibility for all features.
- **Error Recovery**: Graceful error handling with user-friendly messages.

## 🏗️ Architecture

OpenResponses is built with SwiftUI and follows the MVVM (Model-View-ViewModel) pattern with additional service layers for robust functionality.

### Core Architecture

- **`OpenResponsesApp.swift`**: The app's entry point, which injects the shared `ChatViewModel` and manages app-wide state.
- **`ChatView.swift`**: The main UI, containing the message list, input view, and settings navigation.
- **`ChatViewModel.swift`**: The central ViewModel, managing chat state, API calls, streaming, tool execution, and error handling.

### Service Layer

- **`OpenAIService.swift`**: The networking layer responsible for all communication with the OpenAI API.
- **`APICapabilities.swift`**: A type-safe blueprint defining all supported OpenAI API features and tools, acting as a single source of truth for the app's capabilities.
- **`ComputerService.swift`**: Manages the `computer` tool, providing robust browser automation via a native `WKWebView`.
- **`MCPDiscoveryService.swift`**: Handles the discovery and configuration of MCP (Model Context Protocol) servers.
- **`KeychainService.swift`**: Securely manages the OpenAI API key and other sensitive data.
- **`AnalyticsService.swift`**: Tracks API requests, performance metrics, and provides debugging insights.
- **`AppLogger.swift`**: Centralized logging system with categorization and structured output.
- **`NetworkMonitor.swift`**: Monitors network connectivity and handles offline scenarios.

### Management Systems

- **`PromptLibrary.swift`**: Manages saved prompt presets and configurations.
- **`FileManagerView.swift`**: Comprehensive file and vector store management interface.
- **`AccessibilityUtils.swift`**: Centralized accessibility configuration and utilities.

### Development Tools

- **`APIInspectorView.swift`**: Real-time API request/response inspection for debugging.
- **`DebugConsoleView.swift`**: Live debug log viewer with filtering capabilities.
- **Models**: `Codable` structs that match the OpenAI API's JSON structure with full type safety.

## � Getting Started

### Prerequisites

- macOS with Xcode installed.
- An OpenAI API Key from the [OpenAI Platform](https://platform.openai.com/).

### Installation

1.  **Clone the repository:**
    ```sh
    git clone https://github.com/Gunnarguy/OpenResponses.git
    cd OpenResponses
    ```
2.  **Open the project:**
    Open the `OpenResponses.xcodeproj` file in Xcode.
3.  **Build and Run:**
    Select your target device (iOS or macOS) and run the app.
4.  **Configure the App:**
    - On first launch, navigate to the **Settings** screen.
    - Enter your OpenAI API key to enable communication with the API.
    - Select your preferred model and configure any desired tools or advanced settings.
    - **Optional**: Create prompt presets to save your favorite configurations for quick switching.

## 📚 Key Features Guide

For detailed guides on all features, please refer to our new documentation:

- **`/docs/PromptingGuide.md`**: Best practices for writing effective prompts.
- **`/docs/Tools.md`**: A guide to using tools like Web Search, File Search, and Function Calling.
- **`/docs/Images.md`**: A guide to image generation and vision capabilities.
- **`/docs/Advanced.md`**: A guide to advanced features like streaming, structured outputs, and prompt caching.
- **`/docs/FILE_MANAGEMENT.md`**: A user guide for file and vector store features.

### Dynamic Model Selection

The app automatically fetches and categorizes the latest models from OpenAI. This includes intelligent filtering for chat-compatible models and provides real-time descriptions to help you choose the best model for your task.

### Prompt Presets

Save and manage reusable prompt configurations in the **Prompt Library**. Configure your settings once, save it as a preset, and quickly switch between different setups for different tasks.

### File Management & Search

Upload, organize, and search through your documents using Vector Stores. For more information, see the [File Management Guide](/docs/FILE_MANAGEMENT.md).

### Debugging Tools

- **API Inspector**: View detailed request/response data for transparency.
- **Debug Console**: Real-time logs with filtering by category and severity.
- **Analytics**: Track API usage and performance metrics.

## 🧪 Testing

This project includes comprehensive testing capabilities:

### UI Testing

1. In Xcode, open the Test Navigator (Cmd+6).
2. Click the play button next to the `OpenResponsesUITests` test suite to run all tests.

### Manual Testing Features

- **API Inspector**: Test API calls and view real-time request/response data.
- **Debug Console**: Monitor app behavior with detailed logging.
- **Accessibility Testing**: Full VoiceOver support for testing accessibility features.

### Production Readiness

- See `PRODUCTION_CHECKLIST.md` for a comprehensive pre-release validation guide.
- Includes performance testing, error handling validation, and accessibility verification.

## 🏗️ Architecture

OpenResponses is built with SwiftUI and follows the MVVM (Model-View-ViewModel) pattern with additional service layers for robust functionality.

### Core Architecture

- **`OpenResponsesApp.swift`**: The app's entry point, which injects the shared `ChatViewModel` and manages app-wide state.
- **`ChatView.swift`**: The main UI, containing the message list, input view, and settings navigation.
- **`ChatViewModel.swift`**: The central ViewModel, managing chat state, API calls, and error handling.

### Service Layer

- **`OpenAIService.swift`**: The networking layer responsible for all communication with the OpenAI API.
- **`APICapabilities.swift`**: Type-safe blueprint defining all supported OpenAI API features and tools with compile-time validation.
- **`KeychainService.swift`**: Securely manages the OpenAI API key and sensitive data.
- **`AnalyticsService.swift`**: Tracks API requests, performance metrics, and provides debugging insights.
- **`AppLogger.swift`**: Centralized logging system with categorization and structured output.
- **`NetworkMonitor.swift`**: Monitors network connectivity and handles offline scenarios.

### Management Systems

- **`PromptLibrary.swift`**: Manages saved prompt presets and configurations.
- **`FileManagerView.swift`**: Comprehensive file and vector store management interface.
- **`AccessibilityUtils.swift`**: Centralized accessibility configuration and utilities.

### Development Tools

- **`APIInspectorView.swift`**: Real-time API request/response inspection for debugging.
- **`DebugConsoleView.swift`**: Live debug log viewer with filtering capabilities.
- **Models**: `Codable` structs that match the OpenAI API's JSON structure with full type safety.
- **`APICapabilities.swift`**: Centralized type-safe definitions ensuring consistency between documentation and implementation.

## 🤝 Contributing

Contributions are welcome! If you'd like to contribute, please follow these steps:

1.  Fork the repository.
2.  Create a new branch (`git checkout -b feature/your-feature-name`).
3.  Make your changes and commit them (`git commit -m 'Add some feature'`).
4.  Push to the branch (`git push origin feature/your-feature-name`).
5.  Open a Pull Request.

## 📄 License

This project is licensed under the MIT License. See the `LICENSE` file for details.

## 📖 Additional Documentation

- **`/docs/ROADMAP.md`**: The strategic master plan for all features and implementation priorities.
- **`/docs/Tools.md`**: A guide to using tools like Web Search, File Search, and Function Calling.
- **`/docs/Images.md`**: A guide to image generation and vision capabilities.
- **`/docs/Advanced.md`**: A guide to advanced features like streaming, structured outputs, and prompt caching.
- **`/docs/PromptingGuide.md`**: Best practices for writing effective prompts.
- **`/docs/CASE_STUDY.md`**: A technical deep-dive into the app's architecture and design decisions.
- **`/docs/api/Full_API_Reference.md`**: Field-level API implementation status.
- **`/docs/PRODUCTION_CHECKLIST.md`**: A comprehensive pre-release validation checklist.
- **`/docs/FILE_MANAGEMENT.md`**: A user guide for file and vector store features.
- **`/docs/APP_STORE_GUIDE.md`**: App Store submission guidance.
- **`/docs/PRIVACY_POLICY.md`**: The app's privacy policy.
