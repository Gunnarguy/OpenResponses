# OpenResponses

OpenResponses is a native SwiftUI playground for the OpenAI Responses API. It gives developers a production-quality chat client with full tool coverage (computer use, code interpreter, file search, image generation, MCP connectors) and deep instrumentation for debugging what's happening under the hood.

> **Status — November 2025:** Phase 1 of the roadmap is complete. The app ships with local conversation storage today and is preparing to migrate to the Conversations API in Phase 2.

## Highlights
- **Model playground:** Runtime model catalogue with compatibility gating, prompt presets, reasoning-aware defaults, and advanced parameter controls.
- **Streaming with insight:** Activity feed, granular status chips, live token counters, and the new **Assistant Thinking** panel that replays reasoning traces from supporting models.
- **Tool coverage:** Computer use with safety approvals and blank-page recovery, code interpreter with artifact viewer, multi-vector file search, image generation, web search, and custom function calls.
- **Knowledge workflows:** Direct file uploads, vector store management, and MCP connectors with discovery, approval flows, and Keychain-secured auth.
- **Diagnostics-first:** API inspector, debug console, analytics hooks, and structured logging across streaming, tools, and retries.
- **Native experience:** Shared SwiftUI codebase targeting iOS, macOS (Catalyst), and iPadOS with full accessibility support and keyboard shortcuts.

## What's New (Nov 2025)
- Added reasoning trace capture: assistant messages expose a collapsible **Assistant Thinking** block populated from streaming deltas and the final payload.
- Hardened computer-use workflow with navigate-first enforcement, safety approval sheets, and refined status copy.
- Prompt Library surfaced directly inside Settings with normalization helpers for MCP connectors and reasoning toggles.
- Documentation refresh: `docs/CASE_STUDY.md` and `docs/PRODUCTION_CHECKLIST.md` capture the current architecture and release process.

## Architecture Overview
The project follows MVVM with dependencies provided by `AppContainer`.

- **Views:** Lightweight SwiftUI views (`ChatView`, `MessageBubbleView`, onboarding/settings screens) that bind to observable state.
- **View Models:** `ChatViewModel` orchestrates chat state, while `ChatViewModel+Streaming` handles 40+ streaming event types. Settings, onboarding, and tooling expose slimmer companions.
- **Services:** `OpenAIService` builds requests/streams results, `ComputerService` automates the embedded browser, `ConversationStorageService` persists local transcripts, and compatibility helpers gate tooling per model.
- **Data Models:** Strongly typed representations of streaming events, chat messages (including reasoning traces), computer actions, and tool payloads keep decoding reliable.

See `docs/CASE_STUDY.md` for the full architectural deep-dive and system-by-system notes.

## Getting Started
1. **Clone & open**
   ```sh
   git clone https://github.com/Gunnarguy/OpenResponses.git
   cd OpenResponses
   open OpenResponses.xcodeproj
   ```
2. **Build & run** for iOS simulator, macOS Catalyst, or device.
3. **Configure** via Settings → enter your OpenAI key, pick a model, and toggle desired tools. Create Prompt Library entries to save configurations.

## Testing & Release Readiness
- Run unit tests in Xcode (`OpenResponsesTests`, `StreamingEventDecodingTests`).
- Follow the manual regression checklist in `docs/PRODUCTION_CHECKLIST.md` (streaming, tools, attachments, accessibility, documentation updates).
- Capture any new feature coverage in `docs/api/Full_API_Reference.md`, `docs/ROADMAP.md`, and `docs/CASE_STUDY.md` before cutting a build.

## Documentation
- `docs/ROADMAP.md` – phased plan with current status (Phase 2: Conversations API integration).
- `docs/CASE_STUDY.md` – architecture snapshot and recent milestones.
- `docs/api/Full_API_Reference.md` – field-level coverage matrix for the Responses API.
- `docs/Advanced.md` – streaming, reasoning, and structured output guidance.
- `docs/Tools.md` / `docs/Files.md` / `docs/Images.md` – feature-specific user guides.
- `Notion/` folder – remote MCP setup notes and templates.
- `docs/PRODUCTION_CHECKLIST.md` – release smoke test suite.

## Roadmap at a Glance
- **Phase 1 (Complete):** Multi-modal input, advanced tooling, direct uploads, and production-ready computer use.
- **Phase 2 (In Progress):** Backend-managed conversations, annotation rendering, richer conversation metadata.
- **Future:** Apple Intelligence integration, richer UI polish, offline caching layers (see `docs/ROADMAP.md`).

## Contributing
Pull requests are welcome. Please open an issue or draft plan referencing the roadmap so we keep work aligned with Phase 2 priorities.

1. Fork the repo and create a topic branch.
2. Run tests / follow the production checklist for relevant areas.
3. Update documentation as needed.
4. Submit a PR with a summary of changes and verification notes.

## License
MIT — see `LICENSE`.
