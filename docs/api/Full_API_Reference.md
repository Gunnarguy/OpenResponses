# OpenResponses: Definitive API and Codebase Integration Reference

| Property | Type     | Required | Description             | App Status & Implementation Details                                                        |
| :------- | :------- | :------- | :---------------------- | :----------------------------------------------------------------------------------------- |
| `type`   | `String` | **Yes**  | Must be `"input_text"`. | **Implemented**. The `buildInputMessages` function correctly creates `input_text` objects. |
| `text`   | `String` | **Yes**  | The text content.       | **Implemented**. Text from user input is correctly passed through.                         |

**B. Input Image**

| Property    | Type     | Required | Description                                         | App Status & Implementation Details                                                                                                                                                                   |
| :---------- | :------- | :------- | :-------------------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `type`      | `String` | **Yes**  | Must be `"input_image"`.                            | **✅ Implemented**. `InputImage` struct created in `ResponseModels.swift` with proper type handling.                                                                                                  |
| `detail`    | `String` | **Yes**  | Image detail level (`high`, `low`, `auto`).         | **✅ Implemented**. `InputImage` struct includes detail level with default "auto". UI picker in `SelectedImagesView` allows users to choose detail level.                                             |
| `image_url` | `String` | No       | A fully qualified URL or a base64 encoded data URL. | **✅ Implemented**. `InputImage` automatically converts `UIImage` to base64 data URL with JPEG compression. `buildInputMessages` creates proper `input_image` objects with base64 encoded image data. |
| `file_id`   | `String` | No       | The ID of a previously uploaded file.               | **✅ Implemented**. `InputImage` struct supports both `image_url` and `file_id` initialization patterns for uploaded image files.                                                                     |

**C. Input File**

| Property    | Type     | Required | Description                           | App Status & Implementation Details                                                                                               |
| :---------- | :------- | :------- | :------------------------------------ | :-------------------------------------------------------------------------------------------------------------------------------- |
| `type`      | `String` | **Yes**  | Must be `"input_file"`.               | **✅ Implemented**. The `buildInputMessages` function handles both `file_id` references and direct file uploads with `file_data`. |
| `filename`  | `String` | No       | The name of the file.                 | **✅ Implemented**. Direct file uploads include filename in the `input_file` object via `pendingFileNames`.                       |
| `file_data` | `String` | No       | Base64 encoded file content.          | **✅ Implemented**. `DocumentPicker` reads file data, base64-encodes it, and sends it via `buildInputMessages`.                   |
| `file_id`   | `String` | No       | The ID of a previously uploaded file. | **✅ Implemented**. The app supports both pre-uploaded files (`file_id`) and direct uploads (`file_data` + `filename`).           |

**D. Input Audio**

Audio input is not supported. This feature was removed from the app.

**Version 1.0**

## Introduction

This document provides an exhaustive, field-level analysis of the OpenAI APIs used by the OpenResponses iOS application. Its purpose is to serve as a single source of truth for all developers, both human and AI, to understand the full capabilities of the backend and how they are currently implemented within the Swift codebase.

Each API feature is mapped directly to the relevant files, classes, and functions. "App Status" indicates the current level of integration, and "Implementation Details & Gap Analysis" provides a precise, actionable description of the existing code and the work required to achieve full functionality.

---

## 1. The Responses API

This is the primary API for generating model responses. It is a stateful, multimodal endpoint.

- **Endpoint:** `POST https://api.openai.com/v1/responses`
- **Primary Service File:** `OpenAIService.swift`
- **Orchestrator:** `ChatViewModel.swift`

### 1.1. Top-Level Request Body

This table details every parameter in the root of the JSON request body sent to the `/v1/responses` endpoint.

| Parameter      | Type                 | Required | API Description                                                                                                                        | App Status & Implementation Details                                                                                                                                                                                                          |
| :------------- | :------------------- | :------- | :------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `model`        | `String`             | **Yes**  | The ID of the model to use for this request (e.g., `gpt-4-turbo`).                                                                     | **Implemented**. In `OpenAIService.swift`, the `buildRequestObject` function retrieves the model ID from `prompt.model.id`. The user selects this in `SettingsView.swift`, which updates the `activePrompt` in `ChatViewModel`.              |
| `input`        | `String` or `Array`  | **Yes**  | The core content for the model. Can be a simple string for user input or a rich array of `InputItem` objects for multimodal content.   | **✅ Implemented**. The `buildRequestObject` function handles both text strings and multimodal input arrays. `buildInputMessages` supports `input_text`, `input_image`, and `input_file` with both `file_id` and direct `file_data` uploads. |
| `conversation` | `String` or `Object` | No       | The conversation this response belongs to. Can be a conversation ID string or a full conversation object. Manages state automatically. | **Not Implemented**. The app manages state locally by passing `previous_response_id`. It does not use the Conversations API.                                                                                                                 |
| `stream`       | `Bool`               | No       | If `true`, the server streams back Server-Sent Events (SSE) as the response is generated. Defaults to `false`.                         | **Partially Implemented**. Streaming is enabled when requested; text deltas, tool calls, and image generation events are handled, but not every possible event type.                                                                         |
| `background`   | `Bool`               | No       | If `true`, the model response runs in the background. Defaults to `false`.                                                             | **Implemented**. Controlled by `Prompt.backgroundMode`; included by `OpenAIService.buildRequestObject` when enabled.                                                                                                                         |
| `tools`        | `Array`              | No       | A list of tool configurations the model can use, such as `web_search`, `code_interpreter`, etc.                                        | **Partially Implemented**. Builds `web_search`, `code_interpreter`, `file_search`, `image_generation`, MCP, and Custom Function tools. `computer` tool is not implemented.                                                                   |
| `tool_choice`  | `String` or `Object` | No       | Forces the model to use a specific tool.                                                                                               | **Implemented**. `Prompt.toolChoice`; added to the request when not `auto`.                                                                                                                                                                  |
| `include`      | `Array<String>`      | No       | Specifies additional data to include in the output (e.g., `message.output_text.logprobs`).                                             | **Partially Implemented**. Built by `buildIncludeArray`: supports `file_search_call.results`, `web_search_call.action.sources`, `message.output_text.logprobs`, `reasoning.encrypted_content`, and `message.input_image.image_url`.          |

---

### 1.2. The `input` Parameter: A Deep Dive

The `input` parameter is the most critical part of the request. The API supports a rich, multimodal array of content parts.

#### 1.2.1. Input Message (`role`, `content`)

The app correctly wraps the user's text in an `InputMessage` structure. However, the `content` is limited.

#### 1.2.2. Supported `content` Array Types

**A. Input Text**

| Property | Type     | Required | Description             | App Status & Implementation Details                                                       |
| :------- | :------- | :------- | :---------------------- | :---------------------------------------------------------------------------------------- |
| `type`   | `String` | **Yes**  | Must be `"input_text"`. | **Implemented**. The `InputText` struct in `ResponseModels.swift` correctly defines this. |
| `text`   | `String` | **Yes**  | The text content.       | **Implemented**. This is the primary data type the app sends.                             |

**B. Input Image**

| Property    | Type     | Required | Description                                         | App Status & Implementation Details                                                                                                |
| :---------- | :------- | :------- | :-------------------------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------- |
| `type`      | `String` | **Yes**  | Must be `"input_image"`.                            | **Implemented**. `InputImage` struct in `ResponseModels.swift`; `OpenAIService.buildInputMessages` constructs `input_image` items. |
| `detail`    | `String` | **Yes**  | Image detail level (`high`, `low`, `auto`).         | **Implemented**. User-selectable via `ChatViewModel.selectedImageDetailLevel` and passed through to the API.                       |
| `image_url` | `String` | No       | A fully qualified URL or a base64 encoded data URL. | **Implemented**. Images are converted to base64 data URLs when attached from the UI; URLs are also supported.                      |
| `file_id`   | `String` | No       | The ID of a previously uploaded file.               | **Implemented**. `InputImage(fileId:)` supported and sent as `{ "type": "input_image", "file_id": "..." }`.                        |

**C. Input File**

| Property    | Type     | Required | Description                           | App Status & Implementation Details                                                                                                                                              |
| :---------- | :------- | :------- | :------------------------------------ | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `type`      | `String` | **Yes**  | Must be `"input_file"`.               | **Partially Implemented**. `OpenAIService.buildInputMessages` sends `{ "type": "input_file", "file_id": ... }` for attachments. No `InputFile` struct is required for this path. |
| `filename`  | `String` | No       | The name of the file.                 | **Not Implemented**.                                                                                                                                                             |
| `file_data` | `String` | No       | Base64 encoded file content.          | **Not Implemented**. Files are uploaded first via the Files API; only `file_id` references are sent in `input` messages.                                                         |
| `file_id`   | `String` | No       | The ID of a previously uploaded file. | **Implemented**. The app uploads files (`ChatViewModel.attachFile`) and sends the resulting `file_id` in `input`.                                                                |

**D. Input Audio**

Audio input is not supported. This feature was removed from the app.

---

### 1.3. The `tools` Parameter: Comprehensive Analysis

The app has extensive tool integration through the `buildTools` function in `OpenAIService.swift`. Here's the complete status:

**A. Web Search**

- **Type:** `web_search`
- **App Status:** **Fully Implemented**.
- **Implementation Details:** Enabled via `Prompt.enableWebSearch`. `OpenAIService.createWebSearchToolConfiguration` builds config (with optional `user_location`). Streaming status shows a web search in progress during tool calls.

**B. Code Interpreter**

- **Type:** `code_interpreter`
- **App Status:** **Fully Implemented**.
- **Implementation Details:** Enabled via `prompt.enableCodeInterpreter`. Creates tool config with `"container": {"type": "auto"}`. `StreamingStatusView.swift` displays "Executing Code..." status. **Gap:** The app does not yet parse and render the outputs of code execution (charts, images, logs) which can be included via the `include` parameter.

**C. File Search**

- **Type:** `file_search`
- **App Status:** **Fully Implemented**.
- **Implementation Details:** Enabled via `prompt.enableFileSearch`. Requires `selectedVectorStoreIds` from the prompt to be configured. Creates tool config with vector store IDs. **Gap:** The app does not yet parse and render the search results which can be included via the `include` parameter.

**D. Custom Function Tools (User-Defined)**

- **Type:** `function`
- **App Status:** **Fully Implemented**.
- **Implementation Details:** User-defined tools are configurable (`customToolName`, `customToolDescription`, `customToolParametersJSON`). Execution modes: `echo`, `calculator` (local), or `webhook` (POST JSON to URL). Schema built in `OpenAIService.createCustomToolConfiguration`; execution handled in `ChatViewModel.executeCustomTool`.

**E. Image Generation**

- **Type:** `image_generation`
- **App Status:** **Fully Implemented**.
- **Implementation Details:** Enabled via `Prompt.enableImageGeneration`. Streaming-supported with partial previews and completion events. Config includes `size: auto`, `quality: high`, `output_format: png`.

**F. MCP Tool**

- **Type:** `mcp`
- **App Status:** **Partially Implemented**.
- **Implementation Details:** Enabled via `Prompt.enableMCPTool`. Configured with server details (`mcpServerLabel`, `mcpServerURL`, `mcpHeaders`, `mcpRequireApproval`) and `allowed_tools` parsed from `mcpAllowedTools`. Streaming status shows MCP activity. Tool discovery/approvals deferred.

**G. Custom Tool**

- **Type:** `function` (user-defined)
- **App Status:** **Fully Implemented**.
- **Implementation Details:** Enabled via `prompt.enableCustomTool`. Uses `customToolName` and `customToolDescription` from prompt to create function schema.

**H. Computer Use**

- **Type:** `computer`
- **App Status:** **Not Implemented**. This is the major missing tool.
- **Gap Analysis:** No UI exists to enable this tool. `buildTools` does not include computer tool configuration. `ChatViewModel.swift` has no logic to handle `computer_call` streaming events. Would require significant UI development to visualize and approve computer actions.
- **Available Actions in API:**
  - `Click(x, y, button)`: Mouse clicks with button specification
  - `DoubleClick(x, y)`: Double-click actions
  - `Drag(path: [{x, y}, ...])`: Drag operations with path coordinates
  - `KeyPress(keys: ["key1", ...])`: Keyboard input combinations
  - `Move(x, y)`: Mouse movement
  - `Screenshot()`: Screen capture
  - `Scroll(x, y, scroll_x, scroll_y)`: Scrolling actions
  - `Type(text: "...")`: Text input
  - `Wait()`: Pause operations

---

### 1.4. Advanced Parameters Implementation Status

| Parameter             | Prompt Property      | UI Location  | Request Implementation | Status       |
| :-------------------- | :------------------- | :----------- | :--------------------- | :----------- |
| `temperature`         | `temperature`        | SettingsView | ✅ Implemented         | **Complete** |
| `top_p`               | `topP`               | SettingsView | ✅ Implemented         | **Complete** |
| `max_output_tokens`   | `maxOutputTokens`    | SettingsView | ✅ Implemented         | **Complete** |
| `parallel_tool_calls` | `parallelToolCalls`  | SettingsView | ✅ Implemented         | **Complete** |
| `truncation_strategy` | `truncationStrategy` | SettingsView | ✅ Implemented         | **Complete** |
| `reasoning_effort`    | `reasoningEffort`    | SettingsView | ✅ Implemented         | **Complete** |
| `reasoning_summary`   | `reasoningSummary`   | SettingsView | ✅ Implemented         | **Complete** |
| `service_tier`        | `serviceTier`        | SettingsView | ✅ Implemented         | **Complete** |
| `top_logprobs`        | `topLogprobs`        | SettingsView | ✅ Implemented         | **Complete** |
| `user_identifier`     | `userIdentifier`     | SettingsView | ✅ Implemented         | **Complete** |
| `metadata`            | `metadata`           | SettingsView | ✅ Implemented         | **Complete** |
| `background`          | `backgroundMode`     | SettingsView | ✅ Implemented         | **Complete** |
| `tool_choice`         | `toolChoice`         | SettingsView | ✅ Implemented         | **Complete** |

---

## 2. The Streaming Events API: Detailed Implementation Analysis

The app has sophisticated streaming integration through `ChatViewModel.handleStreamChunk()` and comprehensive event models in `ChatMessage.swift`.

### 2.1. Event Handling Implementation Status

| Event Name                           | Handler Function        | Status          | Implementation Details                            |
| :----------------------------------- | :---------------------- | :-------------- | :------------------------------------------------ |
| `response.created`                   | `handleStreamChunk`     | **Implemented** | Extracts `responseId` for conversation continuity |
| `response.queued`                    | `updateStreamingStatus` | **Implemented** | Sets `streamingStatus = .connecting`              |
| `response.in_progress`               | `updateStreamingStatus` | **Implemented** | Sets `streamingStatus = .connecting`              |
| `response.output_item.added`         | `updateStreamingStatus` | **Implemented** | Analyzes item type to set appropriate status      |
| `response.output_item.content.delta` | `handleStreamChunk`     | **Implemented** | Appends text deltas to message content            |
| `response.output_item.content.done`  | `handleStreamChunk`     | **Implemented** | Calls `handleCompletedStreamingItem`              |
| `response.output_item.done`          | `handleStreamChunk`     | **Implemented** | Calls `handleCompletedStreamingItem`              |
| `response.done`                      | `handleStreamChunk`     | **Implemented** | Logs completion, maintains streaming state        |
| `error`                              | Stream error handling   | **Implemented** | Caught in AsyncThrowingStream                     |

### 2.2. Streaming Status Display Implementation

The app provides granular streaming status feedback through `StreamingStatusView.swift`:

| Status               | Trigger Events                             | Implementation |
| :------------------- | :----------------------------------------- | :------------- |
| `.responseCreated`   | `response.created`                         | ✅ Complete    |
| `.connecting`        | `response.queued`, `response.in_progress`  | ✅ Complete    |
| `.thinking`          | `reasoning` item type, `reasoning.started` | ✅ Complete    |
| `.searchingWeb`      | `web_search` tool calls                    | ✅ Complete    |
| `.generatingCode`    | `code_interpreter` tool calls              | ✅ Complete    |
| `.generatingImage`   | `image_generation` tool calls              | ✅ Complete    |
| `.runningTool(name)` | Generic tool calls with custom names       | ✅ Complete    |
| `.streamingText`     | `response.content_part.added`, text deltas | ✅ Complete    |

### 2.3. Output Content and Annotations

Computer Use Preview: Deferred. Feature removed from UI and requests until supported models are publicly available.

**A. Output Text**

- **App Status:** **Implemented**. The app correctly decodes `OutputText` objects and appends the `text` property to the message displayed in `MessageBubbleView.swift`.

**B. Annotations**

- **API Description:** The `OutputText` object can contain an `annotations` array with rich metadata linked to the text.
- **App Status:** **Not Implemented**.
- **Gap Analysis:** The `ChatMessage` model only contains a `text` property and has no structure to store annotations. `FormattedTextView.swift` renders Markdown but has no logic to parse annotations. To implement, `ChatMessage` would need an `[Annotation]` property and `FormattedTextView` would need to process annotations to render `url_citation` as clickable links and `file_citation` with appropriate styling.
- **Annotation Types:**
  - `file_citation`: Contains `file_id`, `filename`, provides source attribution
  - `url_citation`: Contains `url`, `title`, `start_index`, `end_index`, enables clickable web links
  - `container_file_citation`: Contains `file_id`, `filename`, `container_id`, references files within containers

---

## 3. The Conversations API: Implementation Analysis

**App Status:** **Not Implemented**. The app manages conversations entirely through local storage via `ConversationStorageService.swift`. The backend Conversations API is not used.

### 3.1. Current Local Implementation

**File:** `ConversationStorageService.swift`

- **Storage:** Uses `FileManager` to save JSON files in Application Support directory
- **Cache:** Maintains in-memory `conversationsCache` for performance
- **Operations:** `loadConversations()`, `saveConversation()`, `deleteConversation()`
- **UI Integration:** `ConversationListView.swift` displays conversations from local storage

### 3.2. Missing API Integration

| Endpoint                 | Method   | Purpose                       | Implementation Gap     |
| :----------------------- | :------- | :---------------------------- | :--------------------- |
| `/v1/conversations`      | `POST`   | Create backend conversation   | No network call exists |
| `/v1/conversations`      | `GET`    | List all conversations        | No network call exists |
| `/v1/conversations/{id}` | `GET`    | Retrieve conversation history | No network call exists |
| `/v1/conversations/{id}` | `POST`   | Update conversation           | No network call exists |
| `/v1/conversations/{id}` | `DELETE` | Delete conversation           | No network call exists |

### 3.3. Implementation Requirements for Full API Integration

**A. Network Service Layer**

- Add conversation management methods to `OpenAIService.swift`
- Replace local storage calls with API calls in `ConversationStorageService.swift`
- Handle API errors and offline fallback scenarios

**B. Data Model Updates**

- Ensure `Conversation` model matches API response format
- Add server-side conversation IDs and metadata
- Handle conversation synchronization between local and remote

**C. UI Considerations**

- Add loading states for network operations
- Handle online/offline scenarios gracefully
- Provide sync status indicators in `ConversationListView`

---

## 4. Complete Feature Implementation Matrix

### 4.1. API Features vs App Implementation

| API Feature Category        | Implementation Level | Details                                                                      |
| :-------------------------- | :------------------- | :--------------------------------------------------------------------------- |
| **Text Input/Output**       | ✅ **Complete**      | Full text conversation support                                               |
| **Image Input**             | ✅ **Complete**      | Full image selection, base64 encoding, detail level control, API integration |
| **File Input**              | 🟡 **Partial**       | Supports `file_id` references, not direct uploads                            |
| **Audio Input**             | ❌ **Removed**       | Audio capture and API integration removed from the app                       |
| **Basic Tools**             | ✅ **Complete**      | Web search, code interpreter, file search fully integrated                   |
| **Advanced Tools**          | 🟡 **Partial**       | Custom Function tools complete; MCP partial; Computer Use missing            |
| **Streaming Response**      | ✅ **Complete**      | Comprehensive event handling and status display                              |
| **Rich Content Output**     | 🟡 **Partial**       | Text rendering complete; annotations, media incomplete                       |
| **Conversation Management** | 🟡 **Partial**       | Local storage complete; API integration missing                              |
| **Advanced Parameters**     | ✅ **Complete**      | All parameters properly sent in requests                                     |
| **Include Parameters**      | 🟡 **Partial**       | Several include options supported (web/file/logprobs/reasoning/image URLs)   |

### 4.2. Priority Implementation Roadmap

**Phase 1: ✅ COMPLETED - Core Multimodal Support**

1. ✅ Fix `include` parameter request building (Previous session)
2. ✅ Add missing advanced parameters to requests (Previous session)
3. ✅ Image input UI and processing - **NEWLY COMPLETED**
   - ✅ Created `InputImage` data model with base64 encoding
   - ✅ Built `ImagePickerView` with `PHPickerViewController` integration
   - ✅ Added `SelectedImagesView` for image preview and detail level selection
   - ✅ Updated `ChatViewModel` with image attachment management
   - ✅ Extended `OpenAIService` API to handle image attachments
   - ✅ Updated `buildInputMessages` to create proper `input_image` objects

**Phase 2: Next Priority - Rich Output and Advanced Tools**

1. Implement annotation parsing and rendering
2. Direct file upload capabilities in `input` (in addition to `file_id` references)
3. MCP approval flow and server tool discovery

**Phase 3: Advanced Features**

1. Computer use tool integration
2. Rich tool output rendering (code interpreter charts, file search results)
3. Backend conversation API integration

**Phase 4: Polish and Enhancement**

1. Offline capability improvements
2. Performance optimizations
3. Advanced UI features

---

## 5. Technical Implementation Guide

### 5.1. Request Building Architecture

**Primary Function:** `buildRequestObject(for:userMessage:attachments:previousResponseId:stream:)` in `OpenAIService.swift`

**Sub-functions:**

- `buildInputMessages()`: Constructs input array with proper content types
- `buildTools()`: Assembles tools based on prompt configuration and model compatibility
- `buildParameters()`: Adds model-specific parameters with compatibility checking
- `buildReasoningObject()`: Creates reasoning configuration for supporting models

**Model Compatibility:** `ModelCompatibilityService.shared` validates all features against specific models

### 5.2. Response Processing Architecture

**Streaming:** `AsyncThrowingStream<StreamingEvent, Error>` processed by `ChatViewModel.handleStreamChunk()`

**Event Flow:**

1. Raw SSE data parsed into `StreamingEvent` objects
2. Events processed by type-specific handlers
3. UI updated through `@Published` properties
4. Conversation state maintained via `lastResponseId`

**Data Models:** Comprehensive hierarchy from `StreamingEvent` down to individual content items

---

This document serves as the definitive reference for understanding the current implementation state and planning future development of the OpenResponses application's API integration capabilities.

- **App Status:** **Implemented**. The app correctly decodes `OutputText` objects and appends the `text` property to the message displayed in `MessageBubbleView.swift`.

**B. Annotations**

- **API Description:** The `OutputText` object can contain an `annotations` array with rich metadata linked to the text.
- **App Status:** **Not Implemented**.
- **Gap Analysis:** The `ChatMessage` model is just a `String` and has no property to store an array of annotation objects. The `FormattedTextView.swift`, which renders the Markdown, has no logic to parse these annotations. To implement, `ChatMessage` would need an `[Annotation]` property. `FormattedTextView` would need to be rewritten to process the text and its associated annotations, rendering `url_citation` as a tappable link and `file_citation` with a specific icon or style.
- **Annotation Types:**
  - `file_citation`: Contains `file_id`, `filename`.
  - `url_citation`: Contains `url`, `title`, `start_index`, `end_index`.
  - `container_file_citation`: Contains `file_id`, `filename`, `container_id`.

---

## 3. The Conversations API

This API allows for explicit, backend-managed conversation history.

- **App Status:** **Not Implemented**.
- **Gap Analysis:** The app manages conversations locally via `ConversationStorageService.swift` using the file system (Application Support). There is no backend sync. To implement this, add Conversations API calls in `OpenAIService.swift` and adapt `ConversationStorageService`/`ChatViewModel` for remote sync with offline fallback.

### 3.1. API Endpoints

| Endpoint                 | Method   | Description                                     | App Status & Implementation Details                                                                   |
| :----------------------- | :------- | :---------------------------------------------- | :---------------------------------------------------------------------------------------------------- |
| `/v1/conversations`      | `POST`   | Create a new conversation.                      | **Not Implemented**. `OpenAIService` would need a `createConversation` function.                      |
| `/v1/conversations`      | `GET`    | List all conversations.                         | **Not Implemented**. `ConversationStorageService` would call this to populate `ConversationListView`. |
| `/v1/conversations/{id}` | `GET`    | Retrieve a single conversation's full history.  | **Not Implemented**. This would be used when a user taps on a conversation in `ConversationListView`. |
| `/v1/conversations/{id}` | `POST`   | Update a conversation (e.g., add/modify items). | **Not Implemented**.                                                                                  |
| `/v1/conversations/{id}` | `DELETE` | Delete a conversation.                          | **Not Implemented**. Would need to be triggered from the UI, likely in `ConversationListView`.        |
