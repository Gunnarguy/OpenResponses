# OpenResponses Case Study

## 1. Purpose & Current Scope

OpenResponses is a SwiftUI playground for the modern OpenAI platform. The app is built for power users who need to explore the entire Responses API surface – switching between models, streaming modes, and tools without swapping projects or shell scripts. Version 2025.11 focuses on production-ready coverage of every Phase 1 roadmap feature while preparing the codebase for Phase 2's Conversations API migration.

- **Primary goal:** Deliver a trustworthy chat client that exposes advanced OpenAI features (computer use, MCP connectors, reasoning models, file search, image generation) with the ergonomics of a native Apple app.
- **Audience:** Engineers, developer advocates, and QA teams validating OpenAI capabilities ahead of their own integrations.
- **Non-goals:** Audio capture or realtime voice interfaces (explicitly out of scope for 2025) and speculative Phase 3 UI redesigns.

## 2. High-Level Architecture

OpenResponses follows a strict MVVM structure with dependency injection via `AppContainer`.

- **Views (SwiftUI):** `ChatView.swift` drives the primary chat surface. Secondary views handle onboarding, settings, file management, and MCP tooling. Views remain lightweight; they bind to `@Published` state and forward actions to the view model.
- **View Models:** `ChatViewModel.swift` orchestrates user input, streaming, tooling, and persistence. The streaming extension (`ChatViewModel+Streaming.swift`) owns SSE parsing to keep the main type focused on orchestration. Settings, onboarding, and tooling each expose smaller view models to minimise state bleed.
- **Services:**
  - `OpenAIService.swift` builds and submits Requests API payloads, including streaming via `AsyncThrowingStream<StreamingEvent>`.
  - `ComputerService.swift` executes browser automation actions for the `computer` tool using a hidden WebView.
  - `ConversationStorageService.swift` persists conversations to JSON on disk (current shipping behaviour until the Conversations API migration is complete).
  - `ModelCompatibilityService.swift` and `APICapabilities.swift` gate features per model/tool support matrix.
- **Dependency Injection:** `AppContainer` seeds shared services (OpenAI, analytics, computer use, Notion helpers) so previews/tests can swap implementations.

## 3. Core Systems Snapshot

### 3.1 Prompt & Model Management

- Dynamic model catalogue fetched at runtime with grouping for latest, reasoning, classic, and specialty models.
- Prompt presets and the Prompt Library serialize full configurations (model, tools, parameters) for instant recall.
- Reasoning-aware defaults auto-enable reasoning traces when a supporting model is selected.

### 3.2 Streaming & Reasoning Pipeline

- `OpenAIService.streamChatRequest` translates SSE bytes into strongly typed `StreamingEvent` instances.
- `ChatViewModel+Streaming` reacts to 40+ event types (response lifecycle, tool calls, image generation, MCP approvals, computer use telemetry).
- Assistant responses render in `MessageBubbleView` with the **Assistant Thinking** disclosure panel, surfacing reasoning traces gathered during streaming and from the final response payload.
- Activity feed and status chip provide at-a-glance progress (thinking, searching, generating code, using computer, processing artifacts).

### 3.3 Tool Orchestration

- Computer use tool delivers 100% action coverage with guardrails (navigate-first logic, wait limits, safety approval sheet, auto retries, blank-page avoidance).
- Code interpreter integrates artifact parsing for 43 file types with a sandbox cache to avoid repeat downloads.
- File search supports multi-vector-store queries with advanced controls (max results, ranker override).
- MCP connectors feature discovery, approval workflows, Keychain-secured credentials, and health probes before streaming begins.

### 3.4 Attachments & Knowledge

- Direct file uploads via `DocumentPicker` (base64 payloads) plus `file_id` attachment support.
- Image attachments support detail tuning (`auto`, `low`, `high`) including preview gallery UI.
- Vector store management UI (Settings → Tools) guides enabling search and entering store IDs.

### 3.5 Persistence & Conversations

- Conversations currently persist locally with `ConversationStorageService` (JSON per conversation, cached in memory).
- The **Phase 2** objective is to transition to backend-managed history via `/v1/conversations`, keeping local storage as an offline cache. Supporting work includes augmenting the `Conversation` model with remote IDs/metadata and adding sync logic to the storage service and view model.

### 3.6 Security & Privacy

- All secrets stored in the system Keychain (OpenAI key, MCP headers/tokens, Notion OAuth).
- Safety approvals surface for both computer-use actions and MCP operations requiring user consent.
- Analytics scrub sensitive payloads before logging; request/response inspectors provide redacted views suitable for debugging.

## 4. Recent Milestones (2025)

- **Reasoning trace UX:** Assistant messages now expose a collapsible "Assistant Thinking" section fed by live deltas and final reasoning payloads.
- **Computer use hardening:** Navigate-first enforcement, blank-page recovery, safety approvals, and resilient click strategies remove prior 400-series failure modes.
- **Prompt ergonomics:** Prompt Library integration inside Settings, MCP prompt normalization helpers, and reasoning-aware defaults when switching models.
- **Diagnostics:** Enhanced activity feed copy, analytics hooks for streaming milestones, and clearer status strings across the UI.

## 5. Near-Term Focus (Phase 2 Highlights)

1. **Backend-managed conversations:** Implement `/v1/conversations` CRUD, add sync logic with offline cache fallback, and expose conversation metadata where useful (titles, tags).
2. **Annotation rendering:** Extend `ChatMessage` to store output annotations (file, URL citations) and update `FormattedTextView` to render inline links/badges.
3. **Documentation parity:** Maintain this case study, `ROADMAP.md`, and `docs/api/Full_API_Reference.md` whenever feature coverage changes to keep future contributors aligned.

## 6. Testing & Quality Signals

- Unit tests cover streaming event decoding, persistence, and key integrations (`StreamingEventDecodingTests`, `OpenResponsesTests`).
- Manual smoke suites (see `docs/PRODUCTION_CHECKLIST.md`) validate tools, reasoning displays, MCP connectors, and computer-use loops before releases.
- Analytics dashboards record tool usage, error classes, and retry events for field debugging.

---

This document snapshots the app as of November 2025. Update it after major architectural changes (Conversations API landing, annotation renderer, Apple Intelligence integration) so new contributors inherit accurate context.
