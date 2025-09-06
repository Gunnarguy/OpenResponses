# OpenResponses AI Coding Conventions

This document guides AI agents in understanding and contributing to the OpenResponses codebase.

## The Big Picture: The "Responses" API

This app is **not** built on the standard OpenAI Chat Completions API (`/v1/chat/completions`). It is a client for the newer, more powerful **Responses API** (`/v1/responses`). Understanding this is critical.

Key characteristics of the Responses API used in this project:

- **Stateful Conversations:** Unlike the Chat Completions API, the Responses API manages conversation history on the backend. We maintain state by passing the `previous_response_id` from the last turn to the next. The `ChatViewModel` is responsible for storing this ID.
- **Advanced Tool Integration:** The API has first-class support for built-in tools like `web_search_preview`, `code_interpreter`, and `file_search`. These are not implemented as simple function calls on the client.
- **Sophisticated Streaming:** Streaming provides a rich set of structured events, not just text deltas. We receive events like `response.output_item.tool_call.started` and `response.output_item.reasoning.started`. The app uses these to show granular status updates to the user (e.g., "Thinking...", "Searching Web...").

## Architecture & Core Patterns

The application is built with **SwiftUI** and follows a **Model-View-ViewModel (MVVM)** architecture.

- **Dependency Injection:** A central singleton, `AppContainer` (`/OpenResponses/AppContainer.swift`), manages service dependencies. The primary service is the `OpenAIService`.
- **MVVM Structure:**
  - **Views (SwiftUI):** Located in `/OpenResponses/`. The primary UI is `ChatView.swift`. Views are lightweight and driven by the `ChatViewModel`.
  - **ViewModel (`ChatViewModel.swift`):** This is the brain of the application. It holds all UI state (`@Published` properties), manages the conversation flow, and orchestrates API calls. **Crucially, it stores the `lastResponseId` to maintain conversational state.**
  - **Models:** Data structures like `ChatMessage.swift`, `Prompt.swift`, and `StreamingEvent.swift` represent the app's data.

## Key Components & Conventions

- **API Communication (`OpenAIService.swift`):** This is the only class that communicates with the OpenAI API.

  - `buildRequestObject(...)` is a critical method that dynamically constructs the complex JSON payload for the `/v1/responses` endpoint based on the current `Prompt` settings.
  - `streamChatRequest(...)` returns an `AsyncThrowingStream<StreamingEvent, Error>`. The `ChatViewModel` consumes this stream.

- **Streaming Logic (`ChatViewModel.swift`):**

  - The method `handleStreamChunk(_:for:)` is the entry point for processing incoming `StreamingEvent` objects from the API.
  - The `updateStreamingStatus(for:item:)` method translates event types (e.g., `response.output_item.tool_call.started`) into user-facing status messages, which are displayed in `StreamingStatusView.swift`. This is a key UX feature.

- **Secure Storage (`KeychainService.swift`):** The OpenAI API key is sensitive and **must** be stored in the Keychain. Use the singleton `KeychainService.swift` for all interactions with the Keychain. Do not use `UserDefaults` for secrets.

## Developer Workflow

- **Initial Setup:** To build and run the project, you must provide an OpenAI API key.
- **API Key Configuration:** On first launch, the app checks for an API key in the Keychain. If none is found, it automatically presents the `SettingsView.swift` for the user to enter one.

### Example: Adding a new Tool

1.  **Update the `Prompt` Model:** Add a new `Bool` property to `Prompt.swift` to enable/disable your tool.
2.  **Modify `buildRequestObject`:** In `OpenAIService.swift`, add logic to append your new tool's configuration to the `tools` array in the request body if the corresponding `Prompt` property is true.
3.  **Update the UI:** Add a `Toggle` to `SettingsView.swift` or another appropriate view, binding it to the new property on the `activePrompt` in `ChatViewModel`.
4.  **Handle New Streaming Events (If necessary):** If your tool introduces new `StreamingEvent` types, update `updateStreamingStatus` in `ChatViewModel.swift` to provide user feedback.
