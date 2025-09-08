# OpenResponses: The Definitive Development Roadmap

## 1. Objective

This document serves as the comprehensive playbook for upgrading the OpenResponses app from its current state to 100% compliance with the latest OpenAI and Apple capabilities. It outlines every feature, API endpoint, and architectural improvement required to create a best-in-class, multimodal AI experience.

This roadmap is organized into five distinct phases, guiding a systematic implementation from core functionality to advanced features and polish.

---

## 2. Current Status & API Coverage

This section provides a high-level overview of the current implementation status based on the `Full_API_Reference.md`.

| API Feature Category        | Implementation Level | Details                                                                                 |
| :-------------------------- | :------------------- | :-------------------------------------------------------------------------------------- |
| **Text Input/Output**       | ✅ **Complete**      | Full text conversation support.                                                         |
| **Image Input**             | ✅ **Complete**      | Full image selection, base64 encoding, and API integration.                             |
| **File Input**              | 🟡 **Partial**       | Supports `file_id` references, but not direct file uploads.                             |
| **Audio Input**             | ✅ **Complete**      | Full audio recording, base64 encoding, and API integration with microphone permissions. |
| **Basic Tools**             | ✅ **Complete**      | Web search, code interpreter, and file search are fully integrated.                     |
| **Advanced Tools**          | 🟡 **Partial**       | Custom tools, MCP, and calculator are implemented; `computer` use is missing.           |
| **Streaming Response**      | ✅ **Complete**      | Comprehensive event handling and real-time status display.                              |
| **Rich Content Output**     | 🟡 **Partial**       | Text rendering is complete; annotations and media previews are not.                     |
| **Conversation Management** | 🟡 **Partial**       | Local storage is implemented; backend Conversations API integration is missing.         |
| **Advanced Parameters**     | ✅ **Complete**      | All advanced model parameters are supported in the UI and API requests.                 |

---

## 3. Implementation Playbook: From Partial to Full Compliance

This playbook details every feature and improvement required to reach 100% API and feature compliance.

### Phase 1: Input & Tool Completion

**Objective:** Implement all remaining input modalities and complete the integration of advanced tools.

| Feature / Improvement                | Rationale & Evidence                                                                                                                                        | Required Actions & Affected Files/Classes                                                                                                                                                                                                                                                                                                                    | Importance |
| :----------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :--------- |
| **Audio Input**                      | ✅ **Complete** - Full audio recording capabilities implemented with `AudioRecordingService`, `AudioRecordingButton`, base64 encoding, and API integration. | - ✅ Added audio recording UI using `AVAudioRecorder` with `AudioRecordingButton` component.<br>- ✅ Encoded recordings to base64 in `ChatViewModel`.<br>- ✅ Updated `OpenAIService.buildInputMessages()` to include `input_audio` objects with proper format handling.<br>- ✅ Added microphone permission handling with iOS 17+ `AVAudioApplication` API. | 0.8        |
| **Direct File Uploads**              | The app only supports `file_id` references, limiting users from uploading new documents for analysis.                                                       | - Add `UIDocumentPickerViewController` to `ChatInputView`.<br>- Read file data, base64-encode it, and set `filename` and `file_data` fields.<br>- Modify `OpenAIService` to handle direct data uploads.                                                                                                                                                      | 0.7        |
| Computer Use Tool                    | Deferred. Not publicly supported in your account; UI and wiring removed to avoid errors.                                                                    | Defer until OpenAI publishes supported models or access is granted.                                                                                                                                                                                                                                                                                          | -          |
| **gpt-image-1 & Streaming Previews** | ✅ **Complete** - Upgraded to `gpt-image-1` with streaming support. App now uses the latest model with enhanced capabilities.                               | - ✅ Updated tool configuration to use `image_generation` with `model: gpt-image-1`.<br>- ✅ Removed streaming restrictions for image generation.<br>- ✅ Added streaming event handling for progressive image generation updates.<br>- ✅ Support for multi-turn editing by adding instructions to subsequent requests.                                     | 0.9        |
| **Code Interpreter Enhancements**    | The API now supports container selection and parallel tool calls. The app has a basic implementation.                                                       | - Update `buildTools()` to accept `container.type` and `file_ids` for preloaded files.<br>- Expose these options in `SettingsView`.<br>- Add concurrency controls for `parallel_tool_calls`.                                                                                                                                                                 | 0.6        |
| **File Search Enhancements**         | Multi-vector-store search and attribute filtering are now available. The app only supports one.                                                             | - Allow users to select multiple vector store IDs in `SettingsView`.<br>- Pass selected IDs to the `file_search` tool in `OpenAIService`.<br>- Add UI to set `max_num_results` and attribute filters.                                                                                                                                                        | 0.6        |

### Phase 2: Conversation & Backend Sync

**Objective:** Replace the local conversation storage system with the official OpenAI Conversations API for cross-device sync and persistence.

| Feature / Improvement                      | Rationale & Evidence                                                                                                   | Required Actions & Affected Files/Classes                                                                                                                                                                                                                                               | Importance |
| :----------------------------------------- | :--------------------------------------------------------------------------------------------------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :--------- |
| **Backend-Managed Conversations**          | The app uses local storage only. Without server sync, conversations are not accessible across devices.                 | - Implement `createConversation`, `listConversations`, `getConversation`, `updateConversation`, and `deleteConversation` in `OpenAIService`.<br>- Update `ConversationStorageService` to fetch and sync conversations with the backend.<br>- Add offline fallback to use a local cache. | 0.9        |
| **Conversation-Level Metadata**            | The Conversations API supports metadata for custom tags, topics, or user preferences.                                  | - Update the `Conversation` data model to include a `metadata` dictionary.<br>- Provide UI for tagging and searching conversations in `ConversationListView`.                                                                                                                           | 0.4        |
| **Conversation State & `store` Parameter** | Use the `conversation` object instead of `previous_response_id` for state. Allow disabling storage via `store: false`. | - Adjust `OpenAIService.buildRequestObject()` to include the full conversation object or ID.<br>- Provide a toggle for the `store` parameter in `SettingsView` for privacy-sensitive sessions.                                                                                          | 0.6        |
| **Hierarchical Roles**                     | The API introduces new roles: `platform`, `system`, `developer`. Developer messages override user content.             | - Modify `InputMessage` to support roles beyond `system`/`user`.<br>- Update UI to allow creation of `developer` and `system` messages, perhaps in an advanced settings screen.                                                                                                         | 0.5        |

### Phase 3: UI/UX & Apple Framework Integration

**Objective:** Modernize the user interface and integrate powerful on-device features from the latest Apple frameworks.

| Feature / Improvement                      | Rationale & Evidence                                                                          | Required Actions & Affected Files/Classes                                                                                                                               | Importance |
| :----------------------------------------- | :-------------------------------------------------------------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :--------- |
| **Liquid Glass Design**                    | Adopt Apple’s new `Liquid Glass` design language for a modern, translucent UI.                | - Recompile with the latest Xcode.<br>- Apply `glassEffect()` modifiers to toolbars, navigation bars, and chat bubbles.<br>- Provide per-view opt-outs for readability. | 0.6        |
| **Live Translation & Visual Intelligence** | Apple’s on-device frameworks for Live Translation and Visual Intelligence are not integrated. | - Use `FoundationModels` or `Vision` frameworks for on-device translation.<br>- Allow users to share screenshots, detect objects, and feed results into a custom tool.  | 0.6        |
| **Rich Text Editing**                      | SwiftUI now includes a built-in `WebView` and rich text editing via `AttributedString`.       | - Replace custom web view implementations with the native `WebView`.<br>- Use rich text editing for the user input view to support bold, italics, and lists.            | 0.4        |

### Phase 4: On-Device & Real-Time Capabilities

**Objective:** Integrate on-device AI for low-latency, offline-capable features and explore real-time voice interactions.

| Feature / Improvement            | Rationale & Evidence                                                                                           | Required Actions & Affected Files/Classes                                                                                                                                                                                                                 | Importance |
| :------------------------------- | :------------------------------------------------------------------------------------------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :--------- |
| **On-Device AI Integration**     | Apple’s on-device models offer 50-200ms latency and offline operation, significantly improving user retention. | - Integrate Apple’s `FoundationModels` framework for local summarization and text generation.<br>- Implement a fallback mechanism: on-device first, then cloud via OpenAI.<br>- Add UI in `SettingsView` to select processing mode (on-device vs. cloud). | 0.9        |
| **Offline Conversation Caching** | Store conversation messages locally for offline viewing and queue requests to send when back online.           | - Extend `ConversationStorageService` to store unsent messages and sync when the network is available.<br>- Provide offline indicators and sync status in the UI.                                                                                         | 0.5        |
| **Real-time API / gpt-realtime** | OpenAI’s new realtime API provides speech-to-speech interactions. The app has no voice features.               | - Add microphone capture and transcription via Apple’s `Speech` framework or OpenAI’s Whisper.<br>- Provide voice replies with `AVSpeechSynthesizer`.<br>- Integrate `gpt-realtime` models when available.                                                | 0.7        |

### Phase 5: Privacy, Security & Analytics

**Objective:** Harden the application with robust privacy controls, improved error handling, and comprehensive analytics.

| Feature / Improvement                 | Rationale & Evidence                                                                                 | Required Actions & Affected Files/Classes                                                                                                                                              | Importance |
| :------------------------------------ | :--------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :--------- |
| **Encryption & Zero-Data Retention**  | 73% of users worry about privacy. The API supports `reasoning.encrypted_content` and `store: false`. | - Add a toggle to enable encrypted reasoning; handle keys via `KeychainService`.<br>- Provide a `store` switch in `SettingsView` to prevent storing conversations on OpenAI’s servers. | 0.6        |
| **Graceful Error Handling**           | Provide user-friendly messages for common HTTP errors (400, 401, 429, 500).                          | - Map server error codes to localized, user-friendly messages.<br>- Display actionable suggestions (e.g., re-authenticate on 401).                                                     | 0.5        |
| **Concurrency & Memory Optimization** | Use modern Swift Concurrency features for efficient memory management and performance.               | - Refactor streaming handlers to use `AsyncSequence` and other concurrency primitives.<br>- Optimize memory usage for large conversations.                                             | 0.5        |
| **Comprehensive Analytics**           | Extend basic analytics to record tool usage frequency, latency, token usage, and error rates.        | - Add instrumentation points in `ChatViewModel` for each API call and event.<br>- Use privacy-preserving analytics techniques.                                                         | 0.4        |

---

## 4. Detailed API Endpoint Implementation Plan

### Responses API (`/v1/responses`)

| Endpoint                    | Method | Description & Tasks                                                                                                    | Current Status      |
| :-------------------------- | :----- | :--------------------------------------------------------------------------------------------------------------------- | :------------------ |
| `/v1/responses`             | POST   | Create a new model response. Already implemented but must be expanded to support all parameters from the playbook.     | **Partial**         |
| `/v1/responses/{id}`        | GET    | Retrieve a response. Needed for background-mode polling and error recovery. Add `getResponse(id:)` in `OpenAIService`. | **Not Implemented** |
| `/v1/responses/{id}`        | DELETE | Delete a response. Rarely needed but required for full API support.                                                    | **Not Implemented** |
| `/v1/responses/{id}/cancel` | POST   | Cancel a background response. Add UI control and call `cancelResponse(id:)`.                                           | **Not Implemented** |

### Conversations API (`/v1/conversations`)

| Endpoint                 | Method | Description & Tasks                                                                                    | Current Status      |
| :----------------------- | :----- | :----------------------------------------------------------------------------------------------------- | :------------------ |
| `/v1/conversations`      | POST   | Create a new conversation. Replace local creation in `ConversationStorageService` with a network call. | **Not Implemented** |
| `/v1/conversations`      | GET    | List conversations. Replace local storage retrieval with a network call.                               | **Not Implemented** |
| `/v1/conversations/{id}` | GET    | Retrieve conversation history. Use when a user selects a conversation.                                 | **Not Implemented** |
| `/v1/conversations/{id}` | POST   | Update a conversation (e.g., rename). Add editing UI and a network call.                               | **Not Implemented** |
| `/v1/conversations/{id}` | DELETE | Delete a conversation from the backend. Add a UI action and network call.                              | **Not Implemented** |

### Streaming Events (Server-Sent Events)

| Event Category    | Description & Tasks                                                                                                           | Current Status |
| :---------------- | :---------------------------------------------------------------------------------------------------------------------------- | :------------- |
| **Core Events**   | The app must handle all SSE events: `response.created`, `response.in_progress`, `response.completed`, `response.failed`, etc. | **Partial**    |
| **Nested Events** | Expand the `StreamingEvent` model to decode all event types, like `tool_call.started` and `reasoning.started`.                | **Partial**    |

---

## 5. Supporting Documentation

For more specific details, refer to the following documents in the repository:

- **`API/Full_API_Reference.md`**: A detailed, field-level analysis of the app's current API implementation.
- **`PRODUCTION_CHECKLIST.md`**: A comprehensive guide for pre-release validation.
- **`PRIVACY_POLICY.md`**: The official privacy policy for the application.
- **`.github/copilot-instructions.md`**: AI coding conventions for contributing to the codebase.
