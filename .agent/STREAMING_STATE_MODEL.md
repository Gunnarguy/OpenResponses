# Streaming & Computer-Use State Model

This document outlines the state variables, ownership, lifecycle transitions, and cleanup/cancellation semantics for streaming and computer-use actions in OpenResponses. It also provides a detailed audit of all calls to `api.sendComputerCallOutput`.

## State Variables, Ownership, and Lifecycles

All state variables are isolated to the `@MainActor` class `ChatViewModel`.

| State Variable | Type | Lifecycle / Purpose | Legal Transitions | Mutating Tasks / Methods |
| :--- | :--- | :--- | :--- | :--- |
| `currentStreamGeneration` | `UUID` | Identifies the active stream/computer-use generation. Prevents stale callback races. | Updated to new `UUID` on every new user message send, retry, user cancellation, or terminal error. | `sendUserMessage`, `cancelStreaming`, error handlers. |
| `streamingTask` | `Task<Void, Never>?` | Handle to the active Swift Concurrency task executing the stream request or explore demo. | `nil` → `Task` → `nil` (upon completion/cancellation). | `sendUserMessage`, `cancelStreaming`. |
| `streamingMessageId` | `UUID?` | The ID of the assistant `ChatMessage` currently receiving streaming text/tool outputs. | `nil` → `UUID` → `nil` | `sendUserMessage`, `cancelStreaming`, `executeComputerCallWithApproval`, error handlers. |
| `streamingStatus` | `StreamingStatus` | Current operational state shown in the UI status bar (e.g. `.idle`, `.connecting`, `.thinking`, `.usingComputer`). | `.idle` ↔ `.connecting` ↔ `.thinking` ↔ `.streamingText` ↔ `.usingComputer` ↔ `.done` | `updateStreamingStatus`, `executeComputerCallWithApproval`, error handlers, cancellation. |
| `isStreaming` | `Bool` | High-level flag disabling input field during active generation. | `false` ↔ `true` | `sendUserMessage`, `cancelStreaming`, error handlers. |
| `isAwaitingComputerOutput`| `Bool` | Guard preventing the user from sending new messages while a computer action output is pending. | `false` ↔ `true` | `resolveAllPendingComputerCallsIfAny`, `executeComputerCallWithApproval`, error handlers. |
| `lastResponseId` | `String?` | The OpenAI response ID of the last processed stream response, used to chain subsequent tool outputs. | `nil` → `String` → `nil` | `processNonStreamingResponse`, `executeComputerCallWithApproval`, error handlers. |
| `consecutiveWaitCount` | `Int` | Counter for wait-only actions to prevent infinite loop screenshots on the same page. | `0` → `1` → `2` → `3` (circuit breaker) → `0` | `updateConsecutiveWaitGuard`, `executeComputerCallWithApproval`. |
| `deltaBuffers` | `[UUID: String]` | Buffers streamed assistant text fragments to batch UI updates. | Key added on delta → cleared on flush or cancel. | `flushDeltaBufferIfNeeded`, `cancelStreaming`. |
| `deltaFlushWorkItems` | `[UUID: DispatchWorkItem]` | Debounce timers for flushing the delta buffers. | Scheduled on delta → cancelled/cleared on flush/cancel. | `flushDeltaBufferIfNeeded`, `cancelStreaming`. |
| `pendingFunctionCallIds` | `Set<String>` | Tracks tools currently executing to prevent duplicate runs. | Inserted on call added → removed on completion/failure. | `handleFunctionCallWithBatching`, `cancelStreaming`. |
| `pendingParallelCalls` | `[String: [OutputItem]]` | Batches parallel function call objects for simultaneous execution. | Accumulated on delta → cleared when batch timer fires. | `handleFunctionCallWithBatching`, `cancelStreaming`. |
| `parallelCallBatchTimer` | `[String: DispatchWorkItem]` | Timers coordinating the batching of parallel tool calls. | Scheduled on first tool delta → cancelled/cleared on fire. | `handleFunctionCallWithBatching`, `cancelStreaming`. |
| `imageHeartbeatTasks` | `[UUID: Task<Void, Never>]` | Heartbeat animation tasks for image generation feedback. | Created on image generation start → cancelled on finish. | `handleImageGeneration`, `cancelStreaming`. |
| `retryContextByMessageId` | `[UUID: StreamRetryContext]` | Remembers request context to retry once if the stream errors. | Saved on stream start → deleted on success or final fail. | `sendUserMessage`, error handlers. |
| `pendingSafetyApproval` | `SafetyApprovalRequest?` | Holds action details when a computer action requires user consent. | `nil` → `SafetyApprovalRequest` → `nil` | `resolveAllPendingComputerCallsIfAny`, `approveSafetyChecks`, `denySafetyChecks`. |
| `activeBackgroundResponseId` | `String?` | Holds response ID when generating responses in background polling mode. | `nil` → `String` → `nil` | `cancelStreaming`, background loop. |

---

## Terminal States & Cleanup Semantics

A stream generation can reach one of the following terminal states:

### 1. Successful Completion (`.done` / `.idle`)
* **Trigger**: The streaming response finishes successfully, all tool outputs are resolved, and the final message content is rendered.
* **Cleanup**:
  * `isStreaming = false`
  * `streamingMessageId = nil`
  * `isAwaitingComputerOutput = false`
  * `consecutiveWaitCount = 0`
  * Flush `deltaBuffers` for the message.
  * Clear `deltaFlushWorkItems`, `parallelCallBatchTimer`, and `imageHeartbeatTasks`.
  * `currentStreamGeneration` is incremented/regenerated.

### 2. User Cancellation (`cancelStreaming()`)
* **Trigger**: User taps the Stop button.
* **Cleanup**:
  * Cancel `streamingTask`.
  * Cancel in-flight background API responses (`api.cancelResponse`).
  * Flush partial content from `deltaBuffers` into the message text, appending `[Streaming cancelled by user]`.
  * Re-enable user input: `isStreaming = false`, `isAwaitingComputerOutput = false`, `consecutiveWaitCount = 0`.
  * Set `streamingStatus = .idle` and `streamingMessageId = nil`.
  * Clear all pending tool timers and image heartbeats.
  * Increment `currentStreamGeneration` to invalidate any in-flight async callbacks.

### 3. Execution / Network Failure (Error Handlers)
* **Trigger**: Network failure during API calls, or a tool throws an unrecoverable exception.
* **Cleanup**:
  * Present the error cleanly in the UI (e.g., via `errorMessage` and appending a system message helper).
  * Immediately clear operational wait states: `isStreaming = false`, `isAwaitingComputerOutput = false`, `consecutiveWaitCount = 0`, `lastResponseId = nil`, `streamingMessageId = nil`.
  * Cancel `streamingTask`.
  * Cancel all active timers, heartbeats, and delta work items.
  * Increment `currentStreamGeneration` to invalidate stale callbacks.

---

## Streaming Call-Site Audit for `api.sendComputerCallOutput`

Every call to `api.sendComputerCallOutput` is audited below. All calls are isolated to `@MainActor` blocks:

### 1. Approved Computer-Use Flow
* **Call Site**: `executeComputerCallWithApproval(_:)` (Lines 787-794)
* **Inputs**: `callId: request.callId`, `output: ["type": "computer_screenshot", "image_url": "data:image/png;base64,..."]`, `model: activePrompt.openAIModel`, `previousResponseId: request.previousResponseId`, `acknowledgedSafetyChecks: request.checks`, `currentUrl: result.currentURL`.
* **Active Message ID**: `request.messageId`
* **Response ID**: `request.previousResponseId`
* **Task Owner**: Approval execution block called by `approveSafetyChecks()`.
* **Success Path**: Updates consecutive wait counters, parses/processes the API response via `handleNonStreamingResponse`, and clears `isAwaitingComputerOutput = false`.
* **Abort Path**: If `abortAfterOutput` (too many consecutive waits) is true: sets `isStreaming = false`, `streamingStatus = .idle`, `lastResponseId = nil`, and appends a warning system message.
* **Cancellation Path**: Handled by generation check and `cancelStreaming()`.
* **Error Path**: Tries to send output. If network/API fails, caught by internal `do/catch`, sets `isStreaming = false`, `isAwaitingComputerOutput = false`, `streamingStatus = .idle`, `lastResponseId = nil`, and appends a "Couldn't continue..." system message.
* **Retry Behavior**: None (terminal error for the step).
* **Cleanup Behavior**: Clears wait states immediately on error.
* **User-Visible Result**: Captures screenshot and proceeds to next AI response, or shows a warning message.

### 2. Resumed Interrupted Computer Call (Non-Streaming Path)
* **Call Site**: `handleComputerToolCallFromOutputItem(_:)` / `resolveAllPendingComputerCallsIfAny` (Line 1873)
* **Inputs**: `callId: callId`, `output: ["type": "computer_screenshot", "image_url": "data:image/png;base64,..."]`, `model: activePrompt.openAIModel`, `previousResponseId: previousId`, `acknowledgedSafetyChecks: acknowledgedSafetyChecks`, `currentUrl: result.currentURL`.
* **Active Message ID**: `messageId`
* **Response ID**: `previousId`
* **Task Owner**: Resolution loop execution task.
* **Success Path**: Calls `processNonStreamingResponse` to advance the loop.
* **Abort Path**: If `abortAfterOutput` is true: resets wait states and appends wait-limit system message.
* **Cancellation Path**: Handled by generation check and `cancelStreaming()`.
* **Error Path**: Caught in `do/catch` inside `handleComputerToolCallFromOutputItem`, resets `streamingStatus = .idle`, `isStreaming = false`, `isAwaitingComputerOutput = false`, `lastResponseId = nil`, `streamingMessageId = nil`, and appends error description system message.
* **Retry Behavior**: None (terminal error).
* **Cleanup Behavior**: Standard immediate operational state cleanup on failure.
* **User-Visible Result**: Attaches screenshot, sends to API, continues loop.

### 3. Streaming Computer-Call Handler
* **Call Site**: `handleComputerToolCallWithFullResponse(_:)` (Line 4145)
* **Inputs**: `callId: finalCallId`, `output: ["type": "computer_screenshot", "image_url": "data:image/png;base64,..."]`, `model: activePrompt.openAIModel`, `previousResponseId: previousId`, `acknowledgedSafetyChecks: acknowledgedSafetyChecks`, `currentUrl: result.currentURL`.
* **Active Message ID**: `messageId`
* **Response ID**: `previousId`
* **Task Owner**: Streaming event receiver task.
* **Success Path**: Calls `processNonStreamingResponse` and clears `isAwaitingComputerOutput = false`.
* **Abort Path**: If `abortAfterOutput` is true: resets wait states and appends wait-limit system message.
* **Cancellation Path**: Handled by generation check and `cancelStreaming()`.
* **Error Path**: Tries to send output. If network/API fails, caught by internal `do/catch`, sets `isStreaming = false`, `isAwaitingComputerOutput = false`, `streamingStatus = .idle`, `lastResponseId = nil`, `streamingMessageId = nil`, cancels active delta/heartbeat timers, and appends a "Couldn't continue..." system message.
* **Retry Behavior**: None (terminal error).
* **Cleanup Behavior**: Resets all state variables immediately.
* **User-Visible Result**: Updates view with screenshots and triggers next AI response or error message.

### 4. Dead Code Call Site (Unused Helper)
* **Call Site**: `sendComputerCallOutput(item:output:previousId:messageId:)` (Line 4674)
* **Inputs**: `call: item`, `output: output`, `model: activePrompt.openAIModel`, `previousResponseId: previousId`.
* **Active Message ID**: `messageId`
* **Response ID**: `previousId`
* **Task Owner**: Unused helper.
* **Success Path**: Calls `processNonStreamingResponse`.
* **Abort Path**: None.
* **Cancellation Path**: Handled by generation check.
* **Error Path**: Caught in `do/catch`, resets all state variables immediately, and appends a "Couldn't continue..." system message.
* **Retry Behavior**: None.
* **Cleanup Behavior**: Immediate operational state cleanup on failure.
* **User-Visible Result**: Unused.
