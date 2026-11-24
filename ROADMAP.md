# OpenResponses roadmap

**Updated:** November 23, 2026. Open work is tracked in the Notion roadmap (the source of truth for plans) and [CHANGELOG.md](CHANGELOG.md) records each release; this file is a summary. The [v2.6 dossier](docs/releases/v2.6/README.md) contains the full change history, and [ASC status](docs/releases/v2.6/ASCStatus.md) distinguishes uploaded builds from the completed working tree.

## Now

- iPhone and iPad: 3.1 (build 57) is live on the App Store since November 23, 2026, with the OpenResponses Pro In-App Purchase approved. 3.0 (build 56) went live November 20.
- Mac: macOS 3.1 (build 60), the first Mac version, is live on the App Store since November 23, 2026.
- Next: 3.2. The marketing version is 3.2 in all four `MARKETING_VERSION` lines and 3.2 exists for iOS and macOS in App Store Connect (November 23, 2026). The first change in it: the Mac's attachment menu leaves out Take Photo (CHANGELOG, Unreleased).

## 3.1 (released November 23, 2026 on iPhone, iPad and Mac)

- [x] OpenResponses Pro, a one-time USD 4.99 purchase for Shortcuts and Siri, the share sheet and the 12-hour prompt cache ([pro-purchase.md](docs/pro-purchase.md)).
- [x] Shortcuts and Siri ("Ask OpenResponses", "New Chat in OpenResponses") and the share sheet extension ([share-shortcuts-mac.md](docs/share-shortcuts-mac.md)).
- [x] Native macOS app on the same bundle ID (live November 23, 2026, build 60).
- [x] GPT-6.2 Sol as the default, GPT-6.2 Astra and GPT-6.1 Terra, developer-message instructions on GPT-6.2, service tiers per model, the 12-hour cache lifetime, blocked domains as an API filter, retired-model replacements, misalignment stops.
- [x] Connectors and source-preview fixes; GitHub CI runs the Pro purchase test for real (run 45250471857).
- [ ] A production Pro purchase, the share sheet and Shortcuts seen on the App Store build.
- [ ] GPT-6.2 instruction placement, Flex gating and the blocked-domain filter against the live API.

## 3.0 (released November 20, 2026)

- [x] Decisions screen (Settings → Decisions (under Developer)) and an API Workbench "Create decision" endpoint for `POST /v1/decisions`, with unit tests (November 13, 2026).
- [x] A function call's step shows its arguments while they stream (October 19, 2026).
- [x] Calendar and Reminders accept a date or time with no time-zone offset (October 21 to 23, 2026).
- [x] App Store rating request with Apple's `requestReview` sheet, and a "Rate OpenResponses" link in About (November 14, 2026).
- [x] The rating sheet seen once in a development build (November 19, 2026, simulator E9842B71 with a real key).
- [x] A live Decisions request (November 19, 2026, the support-ticket example on gpt-6-luna, 441 input tokens).
- [x] The Decisions screen, its Demo Mode guard, the question editor and the answer cards checked on simulator 2460D513 (November 13, 2026).
- [ ] A live Decisions answer on a physical device with a key (the November 19 check ran in the simulator).
- [ ] Not planned: the Agents API (`/v1/agents/sessions`, beta). It overlaps the app's Responses features and has no Zero Data Retention; revisit if it leaves beta with something the Responses API lacks.

## Implemented for the completed 2.6 source

- [x] Shared Astra/Sol/Terra/Luna catalog, model-aware reasoning/request controls, GPT Image 2 and current Realtime/transcription defaults.
- [x] Native foreground async/custom/programmatic tool execution and multi-agent WebSocket result injection, with enabled-tool checks and constrained mutation handling.
- [x] API Workbench with HTTP/SSE/WebSockets, raw export, token counting, compaction, steering, tool-result continuation and known-conversation operations.
- [x] Continuing voice capture/playback, mute, interruption and route recovery.
- [x] OpenAI-hosted MCP discovery with schema inspection, credential-aware cache, cancellation and bounded transport.
- [x] Shared on-device browser execution lane, real screenshots, DOM refs, history, deadlines and per-turn budgets; corrected hosted-search payloads.
- [x] Complete compaction context, richer artifacts/activity, safe chat switching/deletion and coalesced background persistence.
- [x] Honest file-indexing status, full Batch output/error export, reviewed text-chat JSONL import and complete supported resource pagination.
- [x] Existing Apple/Notion integration improvements. The Assistant JSON migration lab was removed in 2.7 after the Assistants API shut down.
- [x] Latest 294-test local run, native OAuth/registry coverage, and signed iPhone candidate.
- [x] Unified multi-account Connections page, PKCE sign-in and secure refresh.
- [ ] Complete the provider registrations/callback arrangements listed in [MCP connections](docs/mcp-connections.md) before claiming every catalog entry supports sign-in.
- [x] Extensive release, technical, upgrade, validation, source-inventory, store, beta and reviewer documentation.

These checks describe implemented source and recorded local validation. They do not mark App Store delivery complete.

## Release work still open

- [x] Include all intended September source files in a reviewed release revision and produce its archive/upload.
- [x] Verify assigned upload build number, processing, export compliance, beta notes and tester eligibility.
- [ ] Perform the remaining physical voice/audio-route, private MCP and wider device/accessibility checks (Notion Verification rows).
- [x] Synchronize reviewed store metadata, screenshots and reviewer access, select the correct completed build, and submit/release when authorized.

2.6 was released September 8, 2026 and 2.7 on September 25 (build 47); 2.8 followed on September 30 (build 51), 2.9 on October 2 (build 54), 3.0 on November 20 (build 56) and 3.1 on November 23 (build 57). [CHANGELOG.md](CHANGELOG.md) has each one.

## Known product boundaries

Remote conversation views hydrate known IDs rather than listing the entire OpenAI account. Workbench schemas need real handlers/results; they do not provide arbitrary on-device shell execution. Browser automation cannot cover every CAPTCHA, cross-origin frame, closed shadow root or trusted native-input flow. Server mutations cannot be undone merely by cancelling a client task. Model/tool/fine-tuning availability remains account-dependent, and private MCP OAuth remains server-specific.

## Longer-term ideas

- Done in 2.8: Local Python on the device (bundled Pyodide, each run approved) and search by meaning with an on-device embedding.
- Open: broader provider integrations beyond existing implemented handlers; scaffolding does not equal a complete Gmail/Drive client (Notion row "Complete Gmail and Drive clients").
- Open: more extensive automated UI/accessibility and physical audio-route coverage.
- Open from the November 2026 API audit ([openai-api-gaps-2026-11.md](docs/research/openai-api-gaps-2026-11.md)): background completion windows, cache diagnostics and breakpoints, streaming reasoning, code and shell events.

## OpenAssistant lineage

OpenAssistant is the archived predecessor based on Assistants threads/runs. Its historical features are not current live API support in OpenResponses. The Assistant JSON migration path was removed in 2.7. This roadmap does not reopen the archived project or promise restoration of retired endpoints.
