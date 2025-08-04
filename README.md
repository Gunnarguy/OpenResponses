# OpenResponses

OpenResponses is a native SwiftUI app for iOS and macOS, designed as a powerful and flexible playground for exploring OpenAI's language models, including the advanced "o-series" reasoning models. It features a robust chat interface, deep tool integration, and extensive customization options for developers, researchers, and power users.

## 🚀 Features

- **Multi-Model Support**: Instantly switch between standard models (`gpt-4o`) and the latest reasoning models (`o1`, `o3`, `o3-mini`).
- **Streaming & Non-Streaming Modes**: Choose between receiving responses in real-time with a status indicator (`Connecting`, `Streaming`, `Done`) or as a complete message.
- **Powerful Tool Integration**:
  - **Web Search**: Real-time web browsing with advanced configuration for location, search quality, language, and recency.
  - **Code Interpreter**: Write and execute code in a secure sandbox.
  - **Image Generation**: Create images from text prompts.
  - **File Search**: Search through one or multiple user-managed vector stores.
  - **Custom Calculator**: A built-in function-calling tool for evaluating mathematical expressions.
- **Advanced Customizable Settings**:
  - **Basic**: Securely store your API key, adjust `temperature`, and set `reasoning effort` for o-series models.
  - **Power User Controls**: Fine-tune API calls with parameters like `max_output_tokens`, `presence_penalty`, `frequency_penalty`, `top_p`, and `parallel_tool_calls`.
  - **JSON Schema Mode**: Force the model to return responses that conform to a specific JSON schema.
  - **System & Developer Instructions**: Provide separate contexts for general system behavior and technical instructions.
- **Comprehensive File & Vector Store Management**:
  - A dedicated interface to perform full CRUD (Create, Read, Update, Delete) operations on files and vector stores.
  - Upload, delete, and manage files for the File Search tool.
  - Create, edit, and delete vector stores, including managing their file associations and metadata.
- **Conversation Management**: Instantly clear chat history.
- **Native SwiftUI Interface**: A clean, responsive, and platform-native experience.

## 📱 App Flow & Architecture

OpenResponses is built with SwiftUI and follows the MVVM (Model-View-ViewModel) pattern for a clean separation of concerns.

### Core Components

1.  **`OpenResponsesApp.swift`**: The app's entry point. It initializes and injects a shared `ChatViewModel` as an `EnvironmentObject` for global state management.
2.  **`ContentView.swift`**: The root view, which acts as a container for the `ChatView`.
3.  **`ChatView.swift`**: The main UI. It contains the `NavigationStack` for the app, displays the message list, and integrates the `ChatInputView` and `StreamingStatusView`. It also presents the `SettingsView`.
4.  **`ChatViewModel.swift`**: The brain of the app. It manages the chat state, handles both streaming and non-streaming API calls, processes function calls (like the calculator), and manages errors.
5.  **`OpenAIService.swift`**: The network layer. It constructs the complex API request payloads by reading all basic and advanced settings from `UserDefaults`, sends requests, and handles file/vector store operations.
6.  **`SettingsView.swift`**: The configuration screen where users can manage everything from the API key to advanced power-user controls.
7.  **`FileManagerView.swift`**: A comprehensive UI for managing files and vector stores, allowing for multi-store selection and full CRUD operations.
8.  **Component Views**:
    - **`MessageBubbleView`**: Renders individual messages, including special formatting for code blocks.
    - **`ChatInputView`**: The text input component.
    - **`StreamingStatusView`**: A visual indicator for the status of streaming responses.
9.  **Data Models**: `ChatMessage` and a full set of `Codable` structs that precisely match the OpenAI API's JSON structure.

### Data Flow: A User's Message

1.  **Input**: The user types a message in `ChatInputView` and taps "Send".
2.  **Action**: `ChatView` calls `viewModel.sendUserMessage()`.
3.  **UI Update (User)**: `ChatViewModel` immediately appends the user's message to the chat history. If streaming, it also appends a placeholder for the assistant's response.
4.  **API Call**: The view model creates a `Task` to call the appropriate method in `OpenAIService` (`sendChatRequest` or `streamChatRequest`), which builds the request from the latest settings in `UserDefaults`.
5.  **Network & Response**: The service sends the request.
    - **Non-Streaming**: It awaits the full response, decodes it, and returns it to the view model.
    - **Streaming**: It opens a connection and yields response chunks (`StreamingEvent`) as they arrive.
6.  **UI Update (Assistant)**: The view model, on the main thread, processes the response.
    - **Non-Streaming**: It updates the placeholder with the final text and images.
    - **Streaming**: It incrementally updates the placeholder message and the `StreamingStatusView` as data arrives.
7.  **Function Calls**: If the model returns a function call (e.g., `calculator`), the view model executes it, sends the result back via `OpenAIService`, and processes the final response.

## 🔧 Getting Started

1.  **Clone the repository.**
2.  **Get an OpenAI API Key**: [OpenAI Platform](https://platform.openai.com/)
3.  **Build & Run**: Open `.xcodeproj` in Xcode and run on your device or simulator.
4.  **Configure Settings**:
    - Go to the settings screen and enter your API key.
    - Select your preferred model and enable desired tools.
    - Explore the advanced settings to customize the experience.
5.  **Start Chatting!**

## 🤖 Agent-Driven Development

OpenResponses is designed for easy modification by AI agents. The codebase is well-structured, thoroughly commented, and leverages modern SwiftUI and MVVM best practices. This detailed README provides all the context needed for agents to understand, extend, and maintain the project.
