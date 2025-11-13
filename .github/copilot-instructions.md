# OpenResponses AI Coding Instructions

## Orientation

- SwiftUI MVVM app anchored by `AppContainer`, wiring `OpenAIService`, `ComputerService`, storage, analytics, and Apple system providers; build view models via `AppContainer.makeChatViewModel()`.
- Phase 2 (Conversations API migration) is tracked in `docs/ROADMAP.md`; align new features and update release docs when behavior shifts.
- Keep surfaces and logic separated: `OpenResponses/Features` for SwiftUI UI, `OpenResponses/Core` for services/models/tool providers, compliance material in `docs/` and `PRIVACY.md`.

## Core Systems

- `Features/Chat/ViewModels/ChatViewModel.swift` orchestrates conversations, delta buffers, safety approvals, analytics; companion files (`ChatViewModel+Streaming`, `+MCP`) own streaming parsing and MCP state.
- `Core/Services/OpenAIService.swift` builds Responses payloads, streams events, and probes MCP servers; update the tests in `OpenResponsesTests/OpenAIServiceTests.swift` when altering payload shape.
- `Core/Models/ChatMessage.swift` holds message, tool call, and `StreamingEvent` models consumed across view models and tests.
- `Core/Services/ComputerService.swift` runs the WKWebView automation loop; respect the guardrails enforced via `pendingSafetyApproval` and circuit-breaker counters in the view model.
- `Core/Services/ConversationStorageService.swift` persists JSON transcripts; `Core/Models/Prompt.swift` mirrors Settings tabs and drives request assembly.
- Tool providers live under `Core/ToolProviders` with `ToolHub.shared` exposing Notion and Google clients; tokens flow through `TokenStore` (Keychain wrapper).

## Data & Tool Flows

- Attachments traverse `DocumentPicker` → `FileConverterService` → `ChatViewModel` buffers → `OpenAIService`; reuse this conveyor for new formats or constraints.
- Streaming events land in `ChatViewModel+Streaming.handleStreamChunk`; keep `deltaBuffers`, `activityLines`, token usage, and reasoning trace caches synchronized when adding event types.
- Computer-use chains must send `computer_call_output` before issuing new prompts; `ComputerService.executeAction` handles navigation, waits, and screenshots with blank-page recovery helpers.
- MCP setup uses `Features/Tools/ToolConnectionsView` and `Settings/MCPConnectorGalleryView` to write credentials into `Prompt.secureMCPHeaders` / connector keys; diagnostics call `OpenAIService.probeMCPListTools`.
- Model/tool toggles consult `Core/Services/ModelCompatibilityService` so published compatibility sheets never expose unsupported combinations.

## Coding Patterns

- Credentials (OpenAI, Notion, Google, MCP) live in `KeychainService`/`TokenStore`; never persist secrets elsewhere.
- Logging and analytics flow through `AppLogger` and `AnalyticsService`; avoid raw `print` statements to keep telemetry structured.
- Observability surfaces (activity feed, token counters, reasoning traces) are updated inside `ChatViewModel`; extend these helpers instead of patching views directly.
- Computer-use guardrails (blank-page navigation, wait throttles, click suppression) live in `ChatViewModel` and `ComputerService`; adjust helpers rather than bypassing policy checks.
- SwiftUI views under `Features/Chat`, `Features/Settings`, and `Features/Tools` remain declarative; push side effects into services or dedicated view models.

## Build & Validation

- Build with Xcode 16.1+ using the `OpenResponses` scheme (iPhone 16 Pro simulator default; Catalyst shares sources).
- Secret hygiene: `python3 scripts/secret_scan.py`.
- Release preflight: `bash scripts/preflight_check.sh` revalidates usage descriptions and secrets.
- Automated coverage: `xcodebuild test -scheme OpenResponses -destination 'platform=iOS Simulator,name=iPhone 16 Pro'` exercises unit suites, including streaming decoding and prompt persistence.

## Documentation Hooks

- Capture architectural shifts in `docs/CASE_STUDY.md` and `docs/ROADMAP.md` whenever service boundaries change.
- Reflect API or event payload changes in `docs/api/Full_API_Reference.md`, `API/ResponsesAPI.md`, and `docs/Advanced.md`.
- Update `docs/PRODUCTION_CHECKLIST.md`, `docs/AppReviewNotes.md`, and `PRIVACY.md` whenever user-visible flows evolve.
- Keep connector guidance current in `docs/Tools.md`, `userInstructions/Setup-Notion-Integration.md`, and `userInstructions/Setup-Google-OAuth.md` when tokens or flows change.
