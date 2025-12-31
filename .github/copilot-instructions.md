# OpenResponses AI Coding Instructions

## Orientation

- **Tech Stack:** SwiftUI MVVM using iOS 17+ on iPhone/iPad/Mac (Catalyst). Bootstrapped by `AppContainer` singleton that wires `OpenAIService`, `ComputerService`, storage, analytics, and Apple system providers (Calendar, Reminders, Contacts via EventKit).
- **Project State:** Phase 1 is feature-complete with local conversation storage, all Responses API tools (computer use, code interpreter, file search, image generation, MCP). Phase 2 (backend Conversations API migration) is scoped in `docs/ROADMAP.md`—always sync code and roadmap together.
- **Folder Intent:** `OpenResponses/Features` = SwiftUI views (Chat, Tools, Settings, Onboarding); `OpenResponses/Core/Services` = API, automation, persistence; `OpenResponses/Core/ToolProviders` = Notion, MCP, Apple integrations; compliance in `docs/` + `PRIVACY.md`.

## Architecture & Ownership

- **ChatViewModel** (`Features/Chat/`) orchestrates message flow, tool execution, streaming events, safety approvals, and analytics. Split via extensions (`+Streaming`, `+MCP`) to keep core <300 lines; `handleStreamChunk()` fans out 40+ `StreamingEvent` types (text deltas, tool calls, reasoning, usage).
- **OpenAIService** (`Core/Services/`) builds Responses API payloads, powers `AsyncThrowingStream<StreamingEvent>`, and probes MCP/tool compatibility. Test helper `testing_buildRequestObject()` validated in `OpenAIServiceTests.swift`—always sync API payload changes with tests.
- **ComputerService** (`Core/Services/`) orchestrates WKWebView automation (navigate → wait → screenshot); enforces `pendingSafetyApproval` gate, 5s blank-page recovery, and click throttle (`2.0s` gap). New actions must respect these guardrails.
- **ConversationStorageService** persists conversations as JSON (local only until Phase 2 backend lands). Sync patterns (`remoteId`, cursor) will be added for `/v1/conversations` integration.
- **Tool ecosystem:** Notion/MCP connectors in `Core/ToolProviders/`; `ToolHub.shared` centralizes clients; credentials flow through `Keychain` (never `UserDefaults`); MCP discovery/probing happens during setup.

## Tool & Data Flows

- **Attachment Pipeline:** `DocumentPicker → FileConverterService.convert() → buffers in ChatViewModel.attachments → encoded in OpenAIService payload`. Add new file types to `FileConverterService` mappings; both PNG and PDF conversion are present.
- **Streaming Event Dispatch:** `ChatViewModel+Streaming.handleStreamChunk()` decodes streaming events; maintains `deltaBuffers` (text), `activityLines` (tool calls), `reasoningLines` (o1/o3), and `tokenUsage`. Rename or add event types = update dispatcher, UI reducers, and `StreamingEventDecodingTests.swift`.
- **Computer Use Safety:** Action execution sequence: evaluate `pendingSafetyApproval`, then `ComputerService.executeAction()` chains navigate → EventKit wait (respects `isWaitingForResponse`) → screenshot. Approval sheet gates all computer calls; emit `computer_call_output` before next prompt.
- **MCP Provisioning:** `ToolConnectionsView` (pair/auth) → `MCPConnectorGalleryView` (list + test) → secrets in `Prompt.secureMCPHeaders` via `TokenStore` (Keychain). Pre-streaming diagnostics: `OpenAIService.probeMCPListTools()` validates connectivity.
- **Availability Gating:** Never hardcode tool/model support in views. Query `ModelCompatibilityService.canUseComputerUse(model:)` and `APICapabilities` helpers instead; these centralize OpenAI's evolving feature matrix.

## Coding Patterns

- **Credentials:** All tokens (OpenAI, MCP, Notion, Google) → `KeychainService` only. Reject `UserDefaults`, environment variable fallback, or hardcoded keys. Use `TokenStore` for named secret retrieval.
- **Logging & Analytics:** `AppLogger` for debug traces (includes `AppLogger.trace(category:)` for event grouping); `AnalyticsService` for user telemetry (tied to pre-defined event names like `"computer_use_executed"`). Skip `print()` in prod code.
- **Observability UI:** Activity feed, status chips, and Assistant Thinking panel driven by view-model computed properties (e.g., `currentActivityLines`, `tokenUsageString`). Avoid pushing animation or formatting logic into SwiftUI views; compute in the ViewModel.
- **Safety & Guardrails:** Blank-page recovery, navigation throttles, click suppression, and approval gates belong in `ChatViewModel` + `ComputerService` (not views). New automation features must wire into existing guardrail lifecycle.

## Build, Test, Release Rituals

- **Build:** Xcode 16.1+, scheme `OpenResponses` (iPhone 16 Pro simulator default). Catalyst via "My Mac (Designed for iPad)" scheme uses same source code.
- **Security & Preflight:** Always run `python3 scripts/secret_scan.py` before commits (detects exposed API keys, tokens). Run `bash scripts/preflight_check.sh` before release merges (validates build, test pass, no secrets).
- **Testing:** `xcodebuild test -scheme OpenResponses -destination 'platform=iOS Simulator,name=iPhone 16 Pro'` runs `OpenAIServiceTests`, `StreamingEventDecodingTests`, `PromptPersistenceTests`, and `FunctionOutputSummarizerTests`. Add tests for new payload shapes or event decoders.
- **Release QA:** Follow `docs/PRODUCTION_CHECKLIST.md` (full feature smoke tests) + `docs/MVAS_SUBMISSION_TRACKER.md` (App Store compliance). Update MVAS tracker + release notes in `docs/ReleaseNotes_*.md` when user-visible flows change.

## Documentation & Sync Responsibilities

- **Authoritative Sources:** `docs/ROADMAP.md` (feature timeline + API coverage), `docs/api/Full_API_Reference.md` (implementation checklist). `docs/CASE_STUDY.md` is historical; defer to roadmap for current state.
- **Tool + Flow Updates:** Refresh `docs/Tools.md` when integrating new MCP connectors. Update `userInstructions/Setup-Notion-Integration.md`, `Setup-Google-OAuth.md` for auth flow changes. New MCP templates go into user guides.
- **Compliance & Release:** User-visible changes (approval flows, data handling, copy) → `PRIVACY.md`, `docs/AppReviewNotes.md`, `AppStoreAssets/` metadata. Sync Phase 1→2 transitions with roadmap; add migration notes to Phase 2 branch.
