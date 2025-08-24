# OpenResponses

OpenResponses is a native SwiftUI app for iOS and macOS, designed as a powerful and flexible playground for exploring OpenAI's language models. It provides a robust chat interface, deep tool integration, and extensive customization options for developers and power users.

![App Screenshot](ABFB8418-0099-402B-B479-E4789A6E3536.PNG)

## 🚀 Features

- **Multi-Model Support**: Switch between standard models (`gpt-4o`) and reasoning models (`o1`, `o3`, `o3-mini`).
- **Streaming & Non-Streaming Modes**: Receive responses in real-time or as a single message.
- **Powerful Tool Integration**:
  - **Web Search**: Browse the web in real-time.
  - **Code Interpreter**: Execute code in a secure sandbox.
  - **Image Generation**: Create images from text prompts.
  - **File Attachments & Search**: Provide context to the model by attaching files and searching across user-managed vector stores.
- **Advanced Customization**:
  - Securely store your API key and adjust core parameters like `temperature`.
  - Fine-tune API calls with controls for `max_output_tokens`, `presence_penalty`, `frequency_penalty`, `top_p`, and more.
  - Enforce specific output structures with JSON Schema mode.
- **Comprehensive File & Vector Store Management**: A dedicated interface for full CRUD operations on files and vector stores.
- **Native SwiftUI Interface**: A clean, responsive, and platform-native experience for iOS and macOS.

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

## 🧪 Testing

This project is set up with UI tests. To run them:

1.  In Xcode, open the Test Navigator (Cmd+6).
2.  Click the play button next to the `OpenResponsesUITests` test suite to run all tests.

## 🏗️ Architecture

OpenResponses is built with SwiftUI and follows the MVVM (Model-View-ViewModel) pattern.

- **`OpenResponsesApp.swift`**: The app's entry point, which injects the shared `ChatViewModel`.
- **`ChatView.swift`**: The main UI, containing the message list, input view, and settings navigation.
- **`ChatViewModel.swift`**: The central ViewModel, managing chat state, API calls, and error handling.
- **`OpenAIService.swift`**: The networking layer responsible for all communication with the OpenAI API.
- **`KeychainService.swift`**: Securely manages the OpenAI API key.
- **Models**: `Codable` structs that match the OpenAI API's JSON structure.

## 🤝 Contributing

Contributions are welcome! If you'd like to contribute, please follow these steps:

1.  Fork the repository.
2.  Create a new branch (`git checkout -b feature/your-feature-name`).
3.  Make your changes and commit them (`git commit -m 'Add some feature'`).
4.  Push to the branch (`git push origin feature/your-feature-name`).
5.  Open a Pull Request.

## 📄 License

This project is licensed under the MIT License. See the `LICENSE` file for details.
