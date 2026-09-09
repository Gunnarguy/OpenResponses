# Changelog

This changelog records implemented application behavior. Version 2.6 includes committed development after the last 2.5 source state and the September working-tree additions. Release dates below are documentation/verification dates, not inferred App Store publication dates.

## 2.6 — released September 8, 2026

**Marketing version/build:** 2.6 (8). **Baseline:** `855ab3b` / 2.5 (7). [Baseline and release status](docs/releases/v2.6/README.md) · [Full release notes](docs/ReleaseNotes_2.6.0.md).

Released on the App Store September 8, 2026 (evening Pacific): 2.6 `READY_FOR_SALE`, build 41 from Xcode Cloud run 41 of commit `5b270d8`, uploaded 12:14 Pacific. Earlier the same day ASC still showed 2.5/build 4 released and draft 2.6 with no selected build; uploaded build 38 (`bf5a783`) excluded the later fixes and reported missing export compliance. [ASC evidence](docs/releases/v2.6/ASCStatus.md), [delivery](docs/releases/v2.6/Delivery.md).

### Added

- Unified MCP Connections page with native provider browser sign-in, 44 featured entries and paginated live registry search. Multiple accounts can be enabled per chat, renamed and managed independently.
- Authorization-code/PKCE S256, protected-resource/issuer discovery, dynamic registration, secure access/refresh storage, token rotation and reconnect handling. Live registration accepted the native callback for 19 entries; providers requiring setup are explicitly identified.
- Workbench request-draft recovery in Keychain, draft export, replacement confirmation and literal JSON editing without smart quotes.
- Structured-output and custom-function schema validation before HTTP, SSE or WebSocket requests.

- Shared current-model catalog: GPT-6 Astra and GPT-5.6 Sol/Terra/Luna, preserving account discovery, fallback selection, search, and explicit model IDs.
- Current-model reasoning context/pro controls, automatic compaction, hosted shell, and deferred function/MCP lookup through tool search.
- Native foreground response runner for configured function/custom tools, async lookups, programmatic calling, and multi-agent WebSocket execution.
- Acknowledged multi-agent tool-result injection, agent/caller metadata, root-answer separation, activity cards, and retained replay checkpoints.
- API Workbench with editable JSON, HTTP/SSE/WebSocket transport, examples, actual tool-result batches, steering, same-socket continuation, and full terminal response export.
- Workbench operations for input-token counting, standalone compaction, response retrieval/cancellation/input items, and known conversation metadata/items.
- GPT Image 2 controls for action, output compatibility, and up to three partial previews on streaming generation.
- Realtime voice service, microphone recorder/transcription surfaces, inline voice UI, and voice settings during the earlier development cycle; current defaults and multi-turn recovery in September.
- Searchable MCP discovery catalog with schema/annotation display, refresh/cancel, allowed-tool filtering, and last-check information.
- Browser DOM reference system, shared serialized action lane, back/forward/reload, page-state reporting, and explicit execution budgets.
- Developer-lab screens for Batch jobs and fine-tuning during the earlier cycle; complete downloads and reviewed-dataset import in September.
- Dynamic response-settings registry and coverage checks, interactive model selection, inline tool execution status, remote conversation hydration, and richer annotations during the earlier cycle.
- Release dossier, complete source inventory, upgrade guide, validation ledger, live ASC/Cloud reconciliation, and synchronized local store/reviewer/beta copy.
- Documentation corrections for actual settings-reset scope, Keychain storage, hosted MCP data flow and on-device browser execution. These are corrected descriptions of behavior, not new data-deletion or credential-storage features.

### Changed

- MCP approval defaults to asking before tool calls. The new account library migrates existing prompt configurations and refreshes credentials for managed native continuations without attaching them to altered endpoints.
- Normal Notion setup uses hosted MCP account sign-in. Existing direct integration keys remain in legacy management. OAuth token-copying tutorials and fake community endpoints are removed from the connection pages.
- GitHub CI now executes the unit/integration suite and preserves its result bundle. Local build number advances to 39; export-compliance metadata and the native OAuth callback are included in the app plist.
- Reset Prompt Settings and separate voice-session labels now describe their actual scope. Published-prompt retirement is documented as November 30, 2026.

- Model IDs normalize consistently; unsupported/unknown models do not inherit modern capabilities merely by matching a loose prefix.
- Reasoning/verbosity payloads are mapped to their supported nested API fields. Astra omits unsupported sampling settings; compatible earlier models retain sampling when reasoning is disabled.
- Native advanced orchestration is scoped to current-model foreground chat with Computer Use off. Read-only client work can overlap; mutations stay sequential. Async and programmatic modes are mutually exclusive.
- Multi-agent native execution uses WebSockets. Result injection waits for acknowledgment and final completion; hosted-agent token budgets are not represented by client call/round limits.
- Stateless continuation preserves complete opaque context, including reasoning/program/phase/agent fields, instead of reconstructing history solely from visible messages.
- Manual compaction persists and replays the entire compacted output window. Multi-agent automatic compaction remains server-managed.
- Conversation listing shows remote IDs known locally; metadata and item retrieval are separate, paginated operations.
- MCP discovery uses a 35-second deadline, bounded stream/catalog sizes, shared in-flight requests, and a five-minute in-memory cache scoped to connection and credential identity.
- Normal MCP chat no longer requires the former diagnostic turn/label-only health cache. OpenAI owns remote MCP transport negotiation; app-invented session/version headers are removed.
- Browser DOM and screenshot actions share ordering/cancellation. Main-frame navigation requires HTTP/HTTPS without embedded credentials; unsupported downloads fail explicitly.
- Search Style is instruction guidance; preferred page/depth controls are not described as hard hosted-search limits.
- Conversation saves coalesce at 750 ms, write on a serial background queue, and flush at lifecycle boundaries. Image encoding is cached until image replacement.
- Fine-tuning accepts reviewed text-only JSONL, validates ten-example minimum and positive hyperparameters, snapshots selected settings, and labels restricted account availability.
- Notion provider concurrency and linked-database metadata retrieval were reorganized; date formatting and Apple integration concurrency boundaries were tightened.

### Fixed

- Voice capture becoming stuck after the first answer because “Speaking” state blocked further microphone transmission.
- Lost/stale playback completions, unnecessary repeated resampling, mute-induced session disruption, and audio setup/route/interruption handling.
- Duplicate root-level verbosity and other incompatible request parameters producing API rejections.
- Compaction IDs being used as response IDs, partial context replay, and results being applied after a chat switch.
- Deleted text remaining in subsequent remote/raw conversation context.
- Streamed text using a stale message array index after changing conversations or editing message order.
- An active deleted chat being resurrected by cancellation-triggered persistence.
- Two separate root chat controllers loading state and registering background work.
- Save-error handling recursively creating additional messages that would also fail to save.
- Late or duplicate WebKit callbacks completing the wrong operation; interrupted browser actions being replayed; navigation/process failures leaving queues stuck.
- Device-scale screenshots disagreeing with the 440×956 computer coordinate space.
- Ambiguous/stale/obscured browser targets, multiple click/submission dispatches, and input values not being verified.
- Invalid hosted-search `profile` payload and unsupported claims about hard crawl/page controls.
- MCP draft credential fallback, stale catalog identity, incomplete/invalid discovery outcomes, and replay risk after uncertain hosted-tool execution.
- Vector-store files being labeled complete before indexing completed; partial failures disappearing with automatic dismissal.
- Batch result downloads being reduced to a 400-character alert instead of an exportable file; error/partial-output export gaps.
- Fine-tuning immediately uploading an entire chat as one invalid training example.
- Resource lists silently stopping after one page and Notion compaction advancing past discarded items.
- Thirteen lifecycle tests existing on disk but missing from the Xcode test target; stale mocks, async assertions, and missing return/throws declarations in those tests.
- Non-streaming function batches submitting an incomplete first batch before all declared calls were registered. Concurrent duplicate submissions are suppressed; unused reasoning waits are removed.
- Earlier-cycle unsafe decoder unwraps, URL scheme/ordering edge cases, concurrency diagnostics, redundant image work, repeated OCR concatenation, and missing test references.

### Retired or constrained

- Live Assistants API operations are disabled. Saved Assistant JSON import remains for migration to Responses presets.
- Fine-tuning remains conditional on OpenAI account eligibility; it is not a universally available model-customization feature.
- Arbitrary Workbench custom/patch/shell payloads are API testing surfaces, not unrestricted local iPhone execution.
- Browser cancellation cannot undo a website action already received. Unknown outcomes require inspection rather than automatic mutation retry.
- Host-provided API capabilities, private OAuth access, and model visibility remain account/server dependent.

### Validation

- Latest September 8 run: **294 unit/integration tests passed**, zero failures. The earlier 265-test result remains the September 6–7 reliability milestone.
- Includes the earlier restored lifecycle/reliability coverage, nine schema/draft checks and 20 OAuth/account/registry regressions. JSON fixture ordering and WebKit fixture return values were made deterministic during validation.
- Signed iPhone build, install, launch, running-process check, and four-file SHA-256 persistence comparison passed.
- Prior bounded live probes cover models, request schemas, WebSockets/steering, async/programmatic/multi-agent fixtures, image generation, compaction, Realtime sessions/two synthetic turns, public MCP discovery/cache, and hosted web search.
- Paid Batch/fine-tuning jobs, private-provider OAuth, arbitrary third-party browser flows, physical-device voice acoustics, and App Store distribution are not all covered by those probes. [Detailed evidence and limits](docs/releases/v2.6/Validation.md).

## 2.5 — source baseline

`de7df81` sets version 2.5/build 7 on June 19, 2026. `855ab3b` is the last source state still labeled 2.5 before staging 2.6. The baseline already includes core Responses chat, browser/web/file tools, attachments, Apple and Notion integrations, Keychain storage, Explore Demo, first-send consent, and conversation scaffolding. Security/build fixes between those two commits are described in the [inventory chronology](docs/releases/v2.6/SourceInventory.md); no App Store ship date is inferred.
