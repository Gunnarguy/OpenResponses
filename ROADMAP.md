# OpenResponses roadmap

**Updated:** September 8, 2026. This is the current source/delivery roadmap. The [v2.6 dossier](docs/releases/v2.6/README.md) contains the full change history, and [ASC status](docs/releases/v2.6/ASCStatus.md) distinguishes uploaded builds from the completed working tree.

## Implemented for the completed 2.6 source

- [x] Shared Astra/Sol/Terra/Luna catalog, model-aware reasoning/request controls, GPT Image 2 and current Realtime/transcription defaults.
- [x] Native foreground async/custom/programmatic tool execution and multi-agent WebSocket result injection, with enabled-tool checks and constrained mutation handling.
- [x] API Workbench with HTTP/SSE/WebSockets, raw export, token counting, compaction, steering, tool-result continuation and known-conversation operations.
- [x] Continuing voice capture/playback, mute, interruption and route recovery.
- [x] OpenAI-hosted MCP discovery with schema inspection, credential-aware cache, cancellation and bounded transport.
- [x] Shared on-device browser execution lane, real screenshots, DOM refs, history, deadlines and per-turn budgets; corrected hosted-search payloads.
- [x] Complete compaction context, richer artifacts/activity, safe chat switching/deletion and coalesced background persistence.
- [x] Honest file-indexing status, full Batch output/error export, reviewed text-chat JSONL import and complete supported resource pagination.
- [x] Existing Apple/Notion integration improvements; retained Assistant JSON migration with retired live operations disabled.
- [x] Latest 294-test local run, native OAuth/registry coverage, and signed iPhone candidate.
- [x] Unified multi-account Connections page, PKCE sign-in and secure refresh.
- [ ] Complete the provider registrations/callback arrangements listed in [MCP connections](docs/mcp-connections.md) before claiming every catalog entry supports sign-in.
- [x] Extensive release, technical, upgrade, validation, source-inventory, store, beta and reviewer documentation.

These checks describe implemented source and recorded local validation. They do not mark App Store delivery complete.

## Release work still open

- [ ] Include all intended September source files in a reviewed release revision and produce its archive/upload.
- [ ] Verify assigned upload build number, processing, export compliance, beta notes and tester eligibility.
- [ ] Perform the remaining physical voice/audio-route, private MCP and wider device/accessibility checks.
- [ ] Synchronize reviewed store metadata, screenshots and reviewer access, select the correct completed build, and submit/release when authorized.

ASC currently has v2.5/build 4 released, v2.6 without a selected build, and older uploaded build 38 with missing export compliance. See the [release plan](docs/AppStoreReleasePlan.md).

## Known product boundaries

Remote conversation views hydrate known IDs rather than listing the entire OpenAI account. Workbench schemas need real handlers/results; they do not provide arbitrary on-device shell execution. Browser automation cannot cover every CAPTCHA, cross-origin frame, closed shadow root or trusted native-input flow. Server mutations cannot be undone merely by cancelling a client task. Model/tool/fine-tuning availability remains account-dependent, and private MCP OAuth remains server-specific.

## Longer-term ideas, not 2.6 promises

- Local Python execution through a suitable sandbox/runtime; current Code Interpreter/hosted shell are hosted services.
- An on-device embedding cache, subject to a separately designed persistence/invalidation scheme.
- Broader provider integrations beyond existing implemented handlers; scaffolding does not equal a complete Gmail/Drive client.
- More extensive automated UI/accessibility and physical audio-route coverage.

## OpenAssistant lineage

OpenAssistant is the archived predecessor based on Assistants threads/runs. Its historical features are not current live API support in OpenResponses. The migration path retained here imports saved Assistant JSON into Responses presets. This roadmap does not reopen the archived project or promise restoration of retired endpoints.
