# OpenResponses

OpenResponses is a native SwiftUI application for iOS and macOS that provides a flexible and powerful chat interface for interacting with OpenAI's language models. It's designed to be a playground for exploring the capabilities of different models and tools, with a focus on the latest "o-series" reasoning models.

## 🚀 Features

- **Multi-Model Support**: Seamlessly switch between standard models like `gpt-4o` and the latest reasoning models (`o1`, `o3`, `o3-mini`).
- **Tool Integration**: Enable and disable powerful tools for the AI assistant:
  - **Web Search**: Allows the model to browse the web for real-time information.
  - **Code Interpreter**: Enables the model to write and execute code in a sandboxed environment.
  - **Image Generation**: Lets the model create images based on textual descriptions.
  - **File Search**: Provides the model with the ability to search through user-provided files.
- **Customizable Settings**:
  - Securely store your OpenAI API key.
  - Adjust `temperature` for standard models to control response creativity.
  - Set `reasoning effort` (low, medium, high) for o-series models to influence their problem-solving approach.
- **File Management**: A dedicated interface to upload, view, and manage files and vector stores used by the File Search tool.
- **Conversation Management**: Easily clear the current chat history.
- **Native SwiftUI Interface**: A clean, responsive, and platform-native user experience.

## 📱 App Flow & Architecture

The application is built using SwiftUI and follows the MVVM (Model-View-ViewModel) design pattern. This architecture promotes a clean separation of concerns between the user interface (View), the application logic and state (ViewModel), and the data structures (Model).

Here is a detailed breakdown of each component and the flow of data:

### Core Components

1.  **`OpenResponsesApp.swift` (App Entry Point)**

    - **Purpose**: This is the root of the application.
    - **Functionality**: It initializes the main `ContentView` and injects a shared instance of `ChatViewModel` as an `EnvironmentObject`. This makes the view model accessible to all child views.

2.  **`ContentView.swift` (Root View)**

    - **Purpose**: Acts as the primary container for the user interface.
    - **Functionality**: It wraps the `ChatView` in a `NavigationStack`, which is essential for managing navigation between the main chat screen and the settings screen.

3.  **`ChatView.swift` (The Main UI)**

    - **Purpose**: Displays the conversation and handles user interaction.
    - **Functionality**:
      - Uses a `ScrollViewReader` and a `LazyVStack` to efficiently display the list of messages from the `ChatViewModel`.
      - Automatically scrolls to the newest message when the conversation updates.
      - Embeds the `ChatInputView` at the bottom, which is pinned above the keyboard.
      - Includes a toolbar button to present the `SettingsView` modally.

4.  **`ChatViewModel.swift` (The Brains of the Operation)**

    - **Purpose**: Manages the application's state and business logic.
    - **Functionality**:
      - Holds the array of `ChatMessage` objects in a `@Published` property, which the `ChatView` subscribes to.
      - `sendUserMessage(String)`: This function is called when the user sends a message. It appends the user's message to the chat history and then creates a `Task` to call the `OpenAIService`.
      - `handleOpenAIResponse(OpenAIResponse)`: Processes the successful response from the API. It extracts text and image content, creates a new assistant `ChatMessage`, and appends it to the messages array. It also saves the `response_id` for conversational continuity.
      - `handleError(Error)`: If the API call fails, this function creates a system-level error message and adds it to the chat for the user to see.
      - `clearConversation()`: Resets the chat history.

5.  **`OpenAIService.swift` (The Network Layer)**

    - **Purpose**: Encapsulates all communication with the OpenAI API.
    - **Functionality**:
      - `sendChatRequest(...)`: Constructs the complex JSON payload for the API. It dynamically reads settings (API key, model, tool toggles, vector store ID) from `UserDefaults` to build the request. It sets parameters like `temperature` or `reasoning_effort` based on the selected model.
      - Handles API error responses by decoding them into a specific error struct.
      - Contains methods for file management (`listFiles`, `uploadFile`, `deleteFile`) and vector store management, which are used by the `FileManagerView`.
      - `fetchImageData(...)`: Fetches image data from a URL or by file ID when the assistant generates an image.

6.  **`SettingsView.swift` (Configuration Screen)**

    - **Purpose**: Allows the user to configure the app's settings.
    - **Functionality**:
      - Uses `@AppStorage` property wrappers to bind UI controls directly to `UserDefaults`. This provides a seamless and persistent way to manage the API key, selected model, and tool preferences.
      - Conditionally shows UI elements. For example, the "Reasoning Effort" picker is only enabled for "o-series" models.
      - Provides a button to present the `FileManagerView` for managing files related to the "File Search" tool.

7.  **`FileManagerView.swift` (File & Vector Store Management)**

    - **Purpose**: Provides a UI for the user to manage files and vector stores for the "File Search" tool.
    - **Functionality**:
      - Lists all uploaded files and available vector stores by calling the respective methods in `OpenAIService`.
      - Allows the user to select which vector store should be active for searches. This selection is saved to `UserDefaults`.
      - Provides UI to create new vector stores and upload files using a `fileImporter`.

8.  **Component Views (`MessageBubbleView.swift`, `ChatInputView.swift`)**

    - **`MessageBubbleView`**: Renders a single message with distinct styling and alignment for user, assistant, and system roles. It's responsible for displaying both text and images within a message.
    - **`ChatInputView`**: A reusable component for text input, featuring a multi-line `TextEditor` and a send button that is only active when there is text.

9.  **Data Models (`ChatMessage.swift`)**
    - **Purpose**: Defines the data structures for the entire application.
    - **Functionality**:
      - `ChatMessage`: The struct used by the UI to represent a message.
      - `Codable` Structs (`OpenAIResponse`, `OutputItem`, `ContentItem`, `OpenAIFile`, `VectorStore`, etc.): A comprehensive set of structs that precisely match the JSON structure of the OpenAI API. These are crucial for reliably decoding API responses using `JSONDecoder`.

### Data Flow: A User's Message

1.  **Input**: The user types a message in `ChatInputView` and taps "Send".
2.  **Action**: `ChatView` calls `viewModel.sendUserMessage()`.
3.  **UI Update (User)**: `ChatViewModel` immediately creates a user `ChatMessage` and appends it to the `@Published` messages array. The `ChatView` updates instantly to show the user's message.
4.  **API Call**: The view model's `Task` calls `OpenAIService.sendChatRequest()`, passing the message and pulling the latest settings from `UserDefaults`.
5.  **Network**: `OpenAIService` builds and sends the HTTP request to the OpenAI API.
6.  **Response**: The service receives the JSON response and decodes it into the `OpenAIResponse` model object.
7.  **UI Update (Assistant)**: The view model receives the response object. On the main thread, it calls `handleOpenAIResponse`, which processes the output, fetches any generated images, creates an assistant `ChatMessage`, and appends it to the messages array. The `ChatView` updates again to display the assistant's response.

## 🔧 How to Use

1.  **Clone the repository.**
2.  **Obtain an OpenAI API Key**: You need an API key from the [OpenAI Platform](https://platform.openai.com/).
3.  **Build and Run**: Open the `.xcodeproj` file in Xcode and run the app on your desired simulator or device.
4.  **Configure Settings**:
    - Navigate to the settings screen.
    - Enter your OpenAI API key.
    - Select a model (`gpt-4o`, `o3`, etc.).
    - Enable the tools you want the assistant to use.
5.  **Start Chatting**: Return to the main chat screen and start your conversation!

## 🤖 Agent-Driven Development

This repository is designed to be understood and modified by AI agents. The code is clearly structured, commented, and uses modern SwiftUI practices. The detailed README provides the necessary context for an agent to understand the project's purpose, architecture, and functionality, enabling it to assist with future development, bug fixes, and feature implementations.
