# OpenResponses AI Coding Instructions

## Big Picture

- SwiftUI + MVVM assistant targeting the OpenAI **Responses** API. Align all work with the active phase in `docs/ROADMAP.md` (Phase 2: Conversations API migration).
- `AppContainer` is the dependency hub; it wires `OpenAIService`, `ComputerService`, `ConversationStorageService`, analytics, Notion connectors, MCP, and Apple integrations.
- `ChatViewModel` (plus extensions) orchestrates message state, streaming, tool execution, computer-use approvals, persistence, and analytics. Treat it as the coordination layer.
- UX primitives (message list, composer, inspectors, activity feed) live under `OpenResponses/Features/Chat`; changes there ripple across the entire app.

## Architecture & Modules

- `OpenResponses/Features/Chat` – chat timeline, composer, attachments, streaming indicators, activity feed, request/response inspectors.
- `OpenResponses/Features/Conversations` – saved conversations list, rename/delete flows, persistence UI.
- `OpenResponses/Features/Settings` – tabbed settings (General, Models, Tools, MCP, Advanced), prompt library, onboarding triggers, keychain-backed credential forms.
- `OpenResponses/Features/Tools` – Notion quick connect, file manager, MCP catalogue, computer-use approval sheets, execution summaries.
- `OpenResponses/Features/Compatibility` – model/tool compatibility surfaces and diagnostics.
- `OpenResponses/Features/Onboarding` – first-run experience and API key gating.
- `OpenResponses/Features/DebugTools` – API inspector, debug console, developer toggles.
- `OpenResponses/Core/Services` – OpenAI API client, streaming pipeline, computer-use automation, file conversion, storage, analytics, network reachability, Notion auth/service, Apple EventKit/Contacts repositories, MCP configuration, model compatibility, Keychain access.
- `OpenResponses/Core/ToolProviders` – adapters for Apple, Notion, Google tooling (`ToolHub`, provider implementations, capability flags).
- `OpenResponses/Core/Models` – core data types (`ChatMessage`, `Prompt`, `StreamingEvent`, computer action payloads, artifact descriptors).
- `OpenResponses/Core/Utilities` – accessibility identifiers, output summarizers, URL parsing, image helpers, UI metrics.
- `OpenResponses/Resources` – assets, typography/colors, localization catalogs.
- Tests: `OpenResponsesTests/` covers API client, streaming decoding, prompt persistence, function-output summarizer. `OpenResponsesUITests/` supplies smoke coverage.
- Extra tooling: `utils/StreamingEventHandler.ts` mirrors streaming parsing for docs/demos.

## Essential Workflows

- Build with Xcode 16.1+ using the **OpenResponses** scheme (iPhone 16 Pro simulator default). Catalyst shares sources.
- Run guard checks before committing:
  - `python3 scripts/secret_scan.py`
  - `bash scripts/preflight_check.sh`
  - `xcodebuild test -scheme OpenResponses -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`
- Release hygiene lives in `docs/MVAS_SUBMISSION_TRACKER.md`, `docs/PRODUCTION_CHECKLIST.md`, `docs/AppReviewNotes.md`, and `docs/ProductionReadinessSummary.md`.
- Test data: fixtures and sample transcripts sit in `OpenResponses/Resources/SeedData`; update when adjusting default scenarios.

## Patterns to Respect

- `OpenAIService` is the only layer hitting `/v1/responses`; extend `buildRequestObject`, streaming handlers, and response parsing there when adding parameters or tool support.
- Streaming UX must keep `handleStreamChunk`, `updateStreamingStatus`, `activityLines`, reasoning traces, and token counters in sync.
- Credentials (OpenAI, Notion, MCP) always flow through `KeychainService`; `SettingsHomeView` already bridges UI ↔ Keychain.
- Attachment flow: `DocumentPicker` → `FileConverterService` → `ChatViewModel` buffers → `OpenAIService`. Reuse that conveyor for new formats or constraints.
- Computer-use steps require safety approval: honor `pendingSafetyApproval` and `SafetyApprovalSheet` before calling `ComputerService.executeAction`, and emit audit messages.
- Tool toggles must consult `ModelCompatibilityService` and compatibility UI to avoid exposing unsupported features.
- Logging/analytics go through `AppLogger` and `AnalyticsService`; avoid raw prints.
- Privacy usage descriptions live in `OpenResponses.xcodeproj/project.pbxproj`; update those build settings instead of Info.plist files.
- Localized copy lives in `OpenResponses/Resources/Localization`; add keys alongside UI changes.

## Documentation Discipline

- Update `docs/ROADMAP.md`, `docs/api/Full_API_Reference.md`, `PRIVACY.md`, `docs/AppReviewNotes.md`, and `docs/CASE_STUDY.md` when capabilities, data flows, or review guidance change.
- Sync feature guides: `docs/Tools.md`, `docs/Files.md`, `docs/Images.md`, `docs/AccessibilityAudit.md`, and Notion setup docs under `Notion/`.
- Keep MVAS status accurate in `docs/MVAS_SUBMISSION_TRACKER.md` whenever touching release-critical items.
- Record user-facing behavior shifts in `docs/ReleaseNotes_*.md` and update App Store assets under `AppStoreAssets/` when required.

Following these conventions keeps implementation, documentation, and release workflows in lockstep for the next engineering handoff.
