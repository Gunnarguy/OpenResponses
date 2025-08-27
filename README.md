# OpenResponses

OpenResponses is a native SwiftUI app for iOS and macOS, designed as a powerful and flexible playground for exploring OpenAI's language models. It provides a robust chat interface, deep tool integration, and extensive customization options for developers and power users.

![App Screenshot](ABFB8418-0099-402B-B479-E4789A6E3536.PNG)

## 🚀 Features

### Core Functionality

- **Multi-Model Support**: Switch between standard models (`gpt-4o`) and reasoning models (`o1`, `o3`, `o3-mini`).
- **Dynamic Model Selection**: Automatically fetch and display the latest available models from OpenAI's API with intelligent categorization.
- **Enhanced Streaming Experience**: Real-time responses with granular status updates showing when the AI is thinking, searching the web, generating code, or running specific tools.
- **Cancellable Operations**: Stop streaming responses mid-generation with full control.
- **Native SwiftUI Interface**: A clean, responsive, and platform-native experience for iOS and macOS.

### Powerful Tool Integration

- **Enhanced Web Search**: Comprehensive search with location settings, language preferences, recency filtering, and quality controls.
- **Code Interpreter**: Execute Python code in a secure sandbox environment.
- **Image Generation**: Create images from text prompts using DALL-E.
- **File Search**: Search through uploaded documents and PDFs with advanced vector store management.
- **MCP Integration**: Connect to Model Context Protocol servers for extended functionality.
- **Custom Tools**: Define and use your own custom tools with configurable parameters.
- **Calculator**: Built-in mathematical calculation capabilities.

### Advanced File & Data Management

- **Comprehensive File Management**: Upload, organize, and search through documents, PDFs, and text files.
- **Vector Store Operations**: Full CRUD operations with expiration settings and multi-store search.
- **File Format Support**: Plain text, PDF, JSON, and other text-based formats.
- **Smart Organization**: Group related documents for better search results.

### Prompt Management & Presets

- **Prompt Library**: Save, manage, and reuse custom prompt configurations.
- **Preset System**: Create named presets with all settings (models, tools, parameters).
- **Quick Switching**: Instantly switch between different conversation configurations.

### Advanced API Controls & Customization

- **Core Parameters**: Adjust `temperature`, `max_output_tokens`, `presence_penalty`, `frequency_penalty`, `top_p`, and more.
- **JSON Schema Mode**: Enforce specific output structures with strict schema validation.
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

### Key Features Guide

### Dynamic Model Selection

Access the latest AI models automatically:

1. The app fetches available models directly from OpenAI's API.
2. Models are intelligently categorized: "Latest & Greatest", "Reasoning Specialists", "Proven Performers".
3. Includes fallback models for offline use.
4. Smart filtering shows only chat-compatible models.
5. Real-time model descriptions help you choose the right model for your task.

### Prompt Presets

Create and manage reusable prompt configurations:

1. Configure your settings (model, tools, parameters) in the main Settings screen.
2. Tap "Manage Presets" to open the Prompt Library.
3. Tap "+" to save your current configuration as a new preset.
4. Switch between presets using the dropdown in Settings.

### File Management

Upload and search through documents:

1. Navigate to Settings → "Manage Files & Vector Stores".
2. Upload files using the "Upload File" button.
3. Create vector stores to organize related documents.
4. Enable "File Search" in Settings and select your vector store.
5. Ask questions about your documents in the chat interface.

### Web Search Configuration

Customize web search behavior:

1. Enable "Web Search" in Settings → Tools.
2. Configure location settings, language preferences, and search quality.
3. Set recency filters and safe search options as needed.
4. The AI will automatically search the web when needed during conversations.

### Debugging Tools

Monitor and debug API interactions:

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

- **`FILE_MANAGEMENT.md`**: Comprehensive guide to file uploads, vector stores, and search functionality.
- **`PRODUCTION_CHECKLIST.md`**: Pre-release validation checklist for app store deployment.
- **`PRIVACY_POLICY.md`**: Privacy policy and data handling information.
- **`APP_STORE_GUIDE.md`**: Guidelines for App Store submission and compliance.
- **`CASE_STUDY.md`**: Technical deep-dive and development insights.
