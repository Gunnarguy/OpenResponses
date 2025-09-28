# OpenResponses

OpenResponses is a native SwiftUI app for iOS and macOS, designed as a powerful and flexible playground for exploring the full range of OpenAI's API capabilities. It provides a robust chat interface, deep tool integration, and extensive customization options for developers and power users aiming to work with the latest models and features.

This project is currently in a "super beta" state, with a focus on achieving 100% compliance with the latest OpenAI APIs, including advanced tools like `computer` and backend conversation management.

![App Screenshot](OpenResponses/Resources/Assets/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png)

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
- **Reasoning Configuration**: Configure reasoning effort and summary output for O-series and reasoning models like `gpt-5`.
- **Include Controls**: Choose what additional data to include in API responses.
- **Service Tier Management**: Configure API service tiers and background processing.
- **Parallel Tool Calls**: Control concurrent tool execution for efficiency.

### Development & Debugging Tools

- **API Inspector**: View detailed API requests and responses for transparency and debugging.
- **Debug Console**: Real-time debug logs with filtering by level and category.
- **Analytics Dashboard**: Comprehensive request tracking and performance monitoring.
- **Network Logging**: Detailed request/response logging with JSON pretty-printing.

### Real-Time Streaming & Activity Monitoring

- **Enhanced Streaming Feedback**: Real-time typing indicators with animated cursors during message generation.
- **Live Token Estimation**: Per-message and conversation-level token counters that update during streaming.
- **Activity Feed**: Expandable activity panel showing real-time updates during streaming:
  - Tool execution status (web search, code execution, image generation)
  - Reasoning and model thinking phases
  - MCP server interactions and approvals
  - Computer use actions and safety checks
- **Streaming Status Indicators**: Granular status updates for different phases of response generation.

### Safety & Approval Systems

- **MCP Tool Approval Workflow**: User-in-the-loop approval system for MCP server tool calls with detailed request information.
- **Safety Approval for Computer Use**: Review and approve computer actions that may require user confirmation.
- **Secure Credential Management**: All API keys and sensitive data stored in iOS/macOS Keychain.

### Web Content & URL Processing

- **Intelligent URL Detection**: Automatic detection and extraction of URLs from messages using `URLDetector.swift`.
- **Embedded Web Content**: Rich web content rendering with `WebContentView.swift` using native `WKWebView` integration.
- **Content Filtering**: Smart filtering for renderable content with support for markdown images, data URLs, and sandbox paths.
- **Ad Blocking**: Built-in ad blocking and security restrictions for web content.
- **Desktop User Agents**: Automatic desktop user agent configuration for optimal web content display.

### Image Processing & Enhancement

- **Enhanced Image Display**: Advanced image rendering with `EnhancedImageView.swift` featuring animations, fullscreen support, and save functionality.
- **Image Processing Utilities**: Optimized image handling with `ImageProcessingUtils.swift` for memory management and display optimization.
- **Image Reconstruction**: Robust image reconstruction from various formats with fallback handling.
- **Memory Management**: Smart image optimization to prevent memory issues with large images.
- **Placeholder System**: Beautiful placeholder images for loading states.
- **Image Generation Suggestions**: Smart suggestion system with `ImageSuggestionView.swift` that appears when users type image-related keywords.
- **Quick Image Generation**: One-tap image generation from the input toolbar.

### User Onboarding & Experience

- **Multi-Page Onboarding**: Comprehensive onboarding flow with `OnboardingView.swift` for first-time users.
- **API Key Setup Guidance**: Step-by-step API key configuration with visual guidance.
- **Welcome Experience**: Interactive introduction to tools and features.
- **Progressive Disclosure**: Gradual introduction of advanced features.

### Rich Text & Content Display

- **Advanced Text Formatting**: `FormattedTextView.swift` with full Markdown support including code blocks, bold, italics, and syntax highlighting.
- **Code Interpreter Artifacts**: Comprehensive artifact system with `ArtifactView.swift` supporting 43+ file types including logs, CSV, JSON, Python files, and archives.
- **Expandable Content**: Collapsible artifact views with copy functionality and proper MIME type handling.
- **Message Bubbles**: Rich message rendering with `MessageBubbleView.swift` supporting streaming indicators, formatted text, and media content.

### File Management & Attachments

- **Visual File Previews**: `SelectedFilesView.swift` provides thumbnail previews for attached files with proper file type icons.
- **Multi-File Selection**: Support for selecting and managing multiple file attachments simultaneously.
- **File Type Recognition**: Intelligent file type detection with appropriate icons for documents, images, archives, and code files.
- **Image Gallery**: `ImagePickerView.swift` with grid-based image selection and preview capabilities.

### Conversation Management

- **Local Conversation Storage**: Comprehensive conversation persistence using `ConversationStorageService` with JSON-based file storage.
- **Conversation Export**: Export conversations as formatted text for sharing.
- **Conversation Switching**: Seamlessly switch between multiple conversation threads.
- **Message Management**: Delete individual messages, clear conversations, and manage chat history.

### Advanced MCP Integration

- **MCP Server Discovery**: `MCPToolDiscoveryView.swift` provides an intuitive "app store" experience for browsing and configuring MCP servers.
- **Built-in Server Registry**: Curated collection of popular MCP servers including GitHub, Notion, Slack, Google Drive, Shopify, Airtable, Weather, and Calculator.
- **Intelligent Search & Filtering**: Semantic search across server names, descriptions, and tool capabilities with category-based filtering.
- **Secure Authentication Management**: Ultra-secure keychain storage for MCP server authentication with automatic migration from insecure storage.
- **Interactive Approval System**: `MCPApprovalView.swift` presents beautiful approval sheets with parsed tool arguments and security warnings.
- **Real-Time Tool Monitoring**: Complete integration status tracking with `MCPIntegrationStatus.swift` for comprehensive debugging.
- **Per-Tool Configuration**: Granular control over which tools are enabled for each MCP server with visual configuration interface.

### Accessibility & User Experience

- **Full Accessibility Support**: VoiceOver compatibility with proper labels, hints, and navigation.
- **Dynamic Type Support**: Adapts to user's preferred text sizes.
- **Keyboard Navigation**: Complete keyboard accessibility for all features.
- **Error Recovery**: Graceful error handling with user-friendly messages.
- **Comprehensive UI Testing**: Full UI testing suite with accessibility identifiers and launch screen testing.
- **Internationalization Ready**: Complete localization support with `Localizable.xcstrings` supporting multiple languages including Spanish.
- **App Store Ready**: Production-ready implementation with comprehensive app store assets, screenshots, and metadata preparation.
- **Multi-Platform Support**: Native support for iOS, iPadOS, macOS, and visionOS with platform-specific optimizations.

### Analytics & Debugging

- **API Request Inspector**: Real-time API request/response monitoring with `APIInspectorView.swift` for complete transparency.
- **Comprehensive Logging**: Structured logging system with `AppLogger.swift` featuring categorized logs, OpenAI-specific logging, and streaming event tracking.
- **Performance Analytics**: `AnalyticsService.swift` tracks API performance, request sizes, response times, and error rates with detailed metrics.
- **Network Monitoring**: Real-time network connectivity monitoring with `NetworkMonitor.swift` and offline handling with graceful degradation.
- **Debug Console**: Advanced debugging interface with `DebugConsoleView.swift` showing system information and detailed logs.
- **Token Usage Tracking**: `ConversationTokenCounterView.swift` provides detailed token consumption and cost estimation with real-time updates.
- **Request History**: Complete API request history with request/response inspection for troubleshooting and debugging.
- **Error Handling & Retry Logic**: Sophisticated error handling with automatic retry mechanisms for transient failures and rate limiting.
- **Rate Limiting Support**: Built-in rate limiting detection with automatic backoff and retry-after header support.
- **Alternative Service Implementations**: Multiple OpenAI service implementations including minimal testing versions for development scenarios.

## 🏗️ Architecture

OpenResponses is built with SwiftUI and follows the MVVM (Model-View-ViewModel) pattern with feature-oriented folders that keep views, models, and services focused and discoverable.

### Project Structure

- **`OpenResponses/App`**: Application bootstrap code such as `OpenResponsesApp.swift`, `AppContainer.swift`, and logging/analytics setup.
- **`OpenResponses/Core`**: Shared models, services, and protocols (`ChatMessage.swift`, `OpenAIService.swift`, `APICapabilities.swift`, `KeychainService.swift`, etc.).
- **`OpenResponses/Features`**: Feature-specific views and view models. For example, the chat feature lives in `Features/Chat` with UI components, `ChatViewModel.swift`, and related extensions like `ChatViewModel+Streaming.swift` that now own streaming handlers.
- **`OpenResponses/Shared`**: Cross-cutting UI components and utilities reused across multiple features.
- **`OpenResponses/Resources`**: Assets, localized strings, and UI resources (`Assets.xcassets`, `Launch Screen.storyboard`, `Localizable.xcstrings`).
- **`OpenResponses/Support`**: Legacy implementations, sample data, and developer tooling kept separate from production code.

### Core Architecture

- **`ChatView.swift`**: Primary conversation UI that renders message history, the input surface, and feature sheets.
- **`ChatViewModel.swift` + `ChatViewModel+Streaming.swift`**: The view model manages chat state, orchestrates API calls, and delegates streaming event parsing to the dedicated extension to keep functions small and focused.
- **`ContentView.swift`**: Coordinates onboarding, API key setup, settings presentation, and deep links.
- **`OpenAIService.swift`**: Central networking layer that builds `/v1/responses` payloads using composable helpers for models, tools, and attachments, and streams events back to the view model.
- **`ConversationStorageService.swift`**: Handles persistence of local conversations and metadata.
- **`AppContainer.swift`**: Dependency registry that wires services together for injection throughout the app.
- **`APICapabilities.swift`** & **`ModelCompatibilityService.swift`**: Type-safe definitions describing available tools and which models support them.

### Management & Tooling Highlights

- **Prompt & File Management**: `PromptLibrary` and `FileManagerView` provide reusable prompt presets and file/vector store workflows.
- **Diagnostics & Debugging**: Views such as `APIInspectorView`, `DebugConsoleView`, and `ConversationTokenCounterView` aid in troubleshooting and monitoring usage.
- **Tool Integrations**: `ComputerService`, MCP discovery components, and code interpreter helpers live in `Core/Services` and are surfaced through feature modules.
- **`MCPIntegrationStatus.swift`**: Complete MCP integration status monitoring and validation system.

### User Interface Components

- **`ChatView.swift`**: The main chat interface with message display, input handling, and tool indicators.
- **`MessageBubbleView.swift`**: Individual message rendering with streaming support and rich content display.
- **`StreamingStatusView.swift`**: Real-time status indicators for different streaming phases with `DotLoadingView` animations.
- **`ActivityFeedView.swift`**: Expandable activity feed showing detailed streaming progress.
- **`ConversationListView.swift`**: Interface for browsing and managing conversation history.
- **`MCPApprovalView.swift`**: User approval interface for MCP tool calls.
- **`SafetyApprovalSheet.swift`**: Safety confirmation interface for computer use actions.
- **`WebContentView.swift`**: Rich web content rendering with embedded `WKWebView` support.
- **`URLDetector.swift`**: Intelligent URL detection and extraction from message content.
- **`EnhancedImageView.swift`**: Advanced image display with animations, fullscreen, and save capabilities.
- **`FormattedTextView.swift`**: Markdown text rendering with code block syntax highlighting.
- **`ArtifactView.swift`**: Code interpreter artifact display supporting 43+ file types.
- **`ImageSuggestionView.swift`**: Smart image generation suggestions based on user input.
- **`OnboardingView.swift`**: Multi-page onboarding flow for first-time users.
- **`ImagePickerView.swift`**: Grid-based image selection with preview capabilities.
- **`SelectedFilesView.swift`**: Visual file attachment previews with type recognition.
- **`ModelCompatibilityView.swift`**: Model capability and tool compatibility display.
- **`DynamicModelSelector.swift`**: Intelligent model selection with compatibility checking and real-time fetching.
- **`ConversationTokenCounterView.swift`**: Real-time token usage monitoring and display.

### Animation & UI Components

- **`DotLoadingView`**: Animated ellipsis indicator with fluid motion for streaming status.
- **`TypingCursor`**: Blinking cursor animation for real-time typing indication during streaming.
- **`CompactToolIndicator`**: Minimal tool status display with animated indicators for active tools.
- **`MessageToolIndicator`**: Individual message tool usage indicators with visual feedback.

### Development Tools

- **`APIInspectorView.swift`**: Real-time API request/response inspection for debugging.
- **`DebugConsoleView.swift`**: Live debug log viewer with filtering capabilities.

### Data Models

Comprehensive `Codable` data structures providing full type safety and matching the OpenAI API's JSON structure:

- **`StreamingEvent.swift`**: Complete streaming event system supporting 40+ event types from the OpenAI Responses API.
- **`ChatMessage.swift`**: Core message model with support for text, images, tools, and token usage tracking.
- **`ResponseModels.swift`**: Complete response object models for all API interactions.
- **`ComputerModels.swift`**: Computer use tool models and action definitions.
- **`MCPModels.swift`**: Model Context Protocol integration models and server configurations.
- **`OpenAIModel.swift`**: Model listing and capability definitions.
- **`Conversation.swift`**: Local conversation storage model with metadata and persistence support.
- **`Prompt.swift`**: Configuration model containing all prompt settings, tool selections, and parameters.
- **`StreamingStatus.swift`**: Enumerated streaming states with user-friendly descriptions.

## 🧭 Getting Started

### Prerequisites

- macOS with Xcode installed.
- An OpenAI API Key from the [OpenAI Platform](https://platform.openai.com/).

### Installation

1. **Clone the repository:**

  ```sh
  git clone https://github.com/Gunnarguy/OpenResponses.git
  cd OpenResponses
  ```

1. **Open the project:**

  Open the `OpenResponses.xcodeproj` file in Xcode.

1. **Build and Run:**

  Select your target device (iOS or macOS) and run the app.

1. **Configure the App:**

   - On first launch, navigate to the **Settings** screen.
   - Enter your OpenAI API key to enable communication with the API.
   - Select your preferred model and configure any desired tools or advanced settings.
   - **Optional**: Create prompt presets to save your favorite configurations for quick switching.

## 📚 Key Features Guide

For detailed guides on all features, please refer to our comprehensive documentation:

- **`/docs/PromptingGuide.md`**: Best practices for writing effective prompts.
- **`/docs/Tools.md`**: A guide to using tools like Web Search, File Search, and Function Calling.
- **`/docs/Images.md`**: A guide to image generation and vision capabilities.
- **`/docs/Advanced.md`**: A guide to advanced features like streaming, structured outputs, and prompt caching.
- **`/docs/FILE_MANAGEMENT.md`**: A user guide for file and vector store features.
- **`/API/StreamingEventsAPI.md`**: Complete documentation of all supported streaming events.

### Dynamic Model Selection

The app automatically fetches and categorizes the latest models from OpenAI, including:

- **Latest Models**: `gpt-5`, `gpt-4.1` series with full tool support
- **Reasoning Models**: `o-series` models optimized for complex thinking tasks
- **Specialized Models**: `computer-use-preview` for browser automation
  This includes intelligent filtering for chat-compatible models and provides real-time descriptions to help you choose the best model for your task.

### Advanced Streaming Features

The app provides comprehensive streaming feedback through multiple layers:

- **Streaming Event Processing**: Handles 40+ different streaming event types from the OpenAI API
- **Real-time Status Updates**: Granular status indicators showing exactly what phase the model is in:
  - `thinking` for reasoning phases
  - `searchingWeb` for web search operations
  - `generatingCode` for code interpreter execution
  - `generatingImage` for image creation with progress updates
  - `usingComputer` for browser automation actions
  - `mcpApprovalRequested` for MCP tool confirmation
- **Activity Feed**: Detailed, user-friendly activity log showing:
  - Tool execution progress
  - Reasoning steps and model thinking
  - File processing and artifact generation
  - Network status and rate limiting information

### MCP Integration & Discovery

The app features a complete MCP (Model Context Protocol) ecosystem:

- **Discovery Service**: Built-in registry of popular MCP servers (GitHub, Notion, Slack, etc.)
- **One-click Setup**: Streamlined configuration for known services
- **Security-First**: All credentials stored in Keychain with approval workflows
- **Real-time Tool Discovery**: Dynamic detection of available tools from MCP servers

### Prompt Presets & Library

Save and manage reusable prompt configurations in the **Prompt Library**. Configure your settings once, save it as a preset, and quickly switch between different setups for different tasks.

### File Management & Vector Search

Upload, organize, and search through your documents using Vector Stores with multi-store search capabilities. For more information, see the [File Management Guide](/docs/FILE_MANAGEMENT.md).

### Debugging & Development Tools

- **API Inspector**: View detailed request/response data with full JSON formatting
- **Debug Console**: Real-time logs with filtering by category and severity
- **Analytics Dashboard**: Track API usage, performance metrics, and token consumption
- **Streaming Event Viewer**: Monitor all streaming events in real-time for development

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

## 🤝 Contributing

Contributions are welcome! If you'd like to contribute, please follow these steps:

1. Fork the repository.
1. Create a new branch (`git checkout -b feature/your-feature-name`).
1. Make your changes and commit them (`git commit -m 'Add some feature'`).
1. Push to the branch (`git push origin feature/your-feature-name`).
1. Open a Pull Request.

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
