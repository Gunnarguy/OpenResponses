# Changelog

This changelog records implemented application behavior. Version 2.6 includes committed development after the last 2.5 source state and the September working-tree additions. Release dates below are documentation/verification dates, not inferred App Store publication dates.

## 2.8 — submitted for review September 29, 2026 (build 51)

**Marketing version:** 2.8. Xcode Cloud assigns the build number; build 49 (September 28) is the first 2.8 archive, and the build submitted for review is the Xcode Cloud archive of the commit that prepared this entry. App Store text: [release_notes.txt](fastlane/metadata/en-US/release_notes.txt) and [2.8 release notes](docs/ReleaseNotes_2.8.0.md). GPT-Live behavior was checked against OpenAI's Live reference and guides on September 28, 2026, and model settings against OpenAI's model pages, GPT-6 guide, reasoning guide and async tool calling guide on September 29, 2026.

### Added

- GPT-6.1 Sol (`gpt-6.1-sol`, released September 29, 2026) is in every model menu with its documented settings: reasoning effort low to max (it rejects `none`, so a saved `none` is sent as `low`), pro reasoning mode and async tool calls.
- New models show up with the right settings without an app update. The model menus list every current GPT model the account's model list includes (GET /models, once per launch), and for a model the app does not know yet it reads that model's page on OpenAI's docs site once for its reasoning options and summary, then again weekly. A model whose entry in the account's model list shuts down within 30 days leaves the menus, and a preset using it moves to its replacement. The known models, their settings, the default model and retirements now live in one built-in file. Details: docs/model-catalog.md.
- Local Python: with Settings → Local Python on, the assistant can write Python and, after you approve each run in a sheet that shows the code, run it on your device. It runs Pyodide 314.0.7 (CPython compiled to WebAssembly, bundled, MPL-2.0) in a sealed web view: standard library only, no network, no files, no package installs, a fresh namespace each run, and a 30-second limit. The runtime adds about 13.5 MB before compression.
- Search your conversations: the Conversations list has a search field that matches by meaning with Apple's on-device language model and falls back to matching words where your language has no model. Nothing leaves the device; vectors are cached per message and refreshed when a message changes.
- Sign-in for MCP providers that refuse the app's own callback address (monday.com, Airtable, Intercom and Vercel on September 8): the app registers `https://gunzino.me/openresponses/oauth/callback.html`, which hands the result straight back to the app.

### Fixed

- The model menus on the chat status bar and in request settings list the account's newer models. 2.7 recognized later GPT releases by version number, but only Settings → Model read the account's model list, so GPT-6.1 Sol was missing from the other two menus. The app now asks GET /models once per launch and adds every current general-purpose model the account has that the catalog does not list yet. A model the catalog does not know starts reasoning effort at low, because `none` returns HTTP 400 on models that do not accept it (GPT-6 Astra and GPT-6.1 Sol); 2.7 offered `none` to every model except Astra.
- Settings → Model → Voice opens the voice settings and they stay open. The sheet was attached to a section inside the settings form and closed within seconds, whenever the form redrew (reported on a device September 28, 2026).
- GPT-Live 1 no longer plays on after you talk over it. Live sends no speech-started event and can keep talking while it listens, so with Voice Barge-In on and sound going to headphones or Bluetooth, about 0.2 seconds of your speech pauses the assistant at once. If Live keeps sending audio over the next 0.6 seconds, it was only an "mm-hmm" and playback resumes where it stopped; otherwise the audio still queued on the phone is dropped. On the built-in speaker, where the microphone hears the assistant, playback is unchanged.

### Changed

- Pro reasoning mode is offered for every GPT-5.6 and GPT-6 model, as OpenAI's reasoning guide states ("GPT-5.6 and GPT-6 models support standard and pro reasoning modes", September 29, 2026). 2.7 offered it only for GPT-6 Astra and GPT-5.6 Sol.
- GitHub CI builds and tests with the same Xcode as the App Store archive (Xcode 27.0, 27A266a, on GitHub's `xcode-27` image).
- ARCHITECTURE.md, ROADMAP.md, APP_STORE.md, docs/ROADMAP.md, docs/mcp-discovery.md and the Copilot instructions describe the current code; the 2.7 note on retired models below is corrected.
- Accessibility: every screen the new UI tests audit uses at least 4.5:1 text contrast, the chat toolbar icons are labelled for VoiceOver and have 44-point targets, and at the largest text sizes the message bar no longer pushes the chat wider than the screen (icons show the Large Content Viewer instead). `scripts/ui_tests.sh` runs the audits from a fresh install.

### Removed

- `Localizable 2.xcstrings`, an iCloud conflict copy whose 9 strings were already in `Localizable.xcstrings`.

## 2.7 — released September 25, 2026

Released on the App Store September 25, 2026: 2.7 `READY_FOR_DISTRIBUTION` in App Store Connect (read 11:11 Pacific), build 47 from Xcode Cloud run 47 of `32ca9d0`, submitted September 24 at 20:16 Pacific and released automatically after approval.

**Marketing version:** 2.7. Xcode Cloud assigns the build number. Models, deprecations and endpoints were checked against OpenAI's model catalog, changelog and deprecations pages on September 24, 2026.

### Added

- GPT-6 Sol (`gpt-6-sol`) and GPT-6 Luna (`gpt-6-luna`), released September 22. Both accept reasoning effort `none` through `max`, with `medium` as the default. Before this change the model list hid them, because only catalogued models passed its capability filter.
- GPT Image 2.5 Flare and Sunburst (`gpt-image-2.5-flare`, `gpt-image-2.5-sunburst`), with the `xhigh` and `max` quality levels only these models accept. GPT Image 2 stays selectable.
- Version-aware model recognition: a general-purpose ID of GPT-5.6 or later, such as `gpt-6.1-sol` or `gpt-7-luna`, is treated as a current model, including dated snapshots. Specialized variants (audio, realtime, transcription, image, search, codex, cyber and similar) are excluded, and later releases sort above the current list.

### Changed

- New presets, the API Workbench and onboarding default to GPT-6 Sol ($2 input / $10 output per million tokens) instead of GPT-6 Astra ($10 / $50). Existing presets keep their model.
- New presets generate images with GPT Image 2.5 Flare. Quality is normalized to what the chosen image model accepts, in settings and in every request, so `max` never reaches GPT Image 2.
- MCP tool discovery probes with GPT-6 Luna, the lowest-cost current model.
- The offline model list omits `gpt-5`, `gpt-5-mini`, `gpt-5-nano` and `o3`, whose snapshots shut down December 11, 2026. The account's live model list hides them too, and saving settings that name one moves it to OpenAI's documented replacement (corrected September 28, 2026).
- A voice model saved by an earlier version that is no longer offered, such as `gpt-realtime` or `gpt-realtime-mini` (shutdown January 20, 2027), connects as `gpt-realtime-2.1`.
- API Workbench templates "Astra response" and "GPT Image 2" are now "Basic response" and "Image generation"; saved drafts using the old names restore to the same template. The async-tool and reasoning-update templates pin `gpt-6-astra`, where those features were introduced.
- GitHub CI skips `BrowserLiveSiteTests`, which needs example.com and iana.org, after it failed two unrelated runs on hosted-runner network loss. It still runs locally.

### Added (API coverage pass)

- GPT-Live 1 (`gpt-live-1`) voice sessions over the Live API (`wss://api.openai.com/v1/live/sessions`): `session.start`, `session.input_audio.append`, mute/unmute, `session.output_audio.delta`, input/output transcript deltas, `session.close` and `session.closed`. Transcripts are saved per turn. GPT Realtime 2.1 stays the default. The voice settings screen, previously unreachable, opens from Settings → Model → Voice.
- Responses `moderation` (model plus score/block policy for input and output), `web_search.external_web_access`, `code_interpreter` container `memory_limit`, `image_generation.input_fidelity` and `output_compression`, `file_search.ranking_options.hybrid_search`, and the `fast` and `ultrafast` service tiers. New options live in the optional `modernOptions` container, so presets saved by earlier versions still decode.
- API Workbench endpoints for deleting responses; updating, extending and deleting conversations; models; moderations; embeddings; files; vector stores (including search); containers; batches; Realtime client secrets; and voice consents. DELETE requests require confirmation.

### Removed (shut down or deprecated by OpenAI, checked September 24, 2026)

- Assistants API service, models, the unreachable create-assistant sheet and the Legacy Migration Lab (API shut down August 26, 2026).
- Fine-tuning jobs screen, service, dataset validation and chat-to-dataset export (job creation deprecated; halted for existing customers January 6, 2027).
- Published prompts and the `prompt` request object (`/v1/prompts` shuts down November 30, 2026).
- `user` (replaced by `safety_identifier`), `prompt_cache_retention` (deprecated), Chat Completions-style `modalities`/`audio`, stream `include_usage`, and the include value `computer_call_output.output`, none of which the current Responses reference accepts.
- `web_search_preview` and `computer_use_preview` tools, the `computer-use-preview` model path and deep-research branches. Older saved tool configurations naming the preview types decode to `web_search` and `computer`.
- Capability entries for retired models (o3, o3-mini, gpt-5, gpt-5-mini, gpt-5-nano, gpt-4.1-nano, computer-use-preview) and for `gpt-5.5-mini`/`gpt-5.5-nano`, which are not API models. Retired models are hidden from the model list, and a preset that names one moves to OpenAI's documented replacement when loaded.
- Realtime beta event aliases (`response.audio.delta`, `response.text.delta` and related); the app uses the GA event names.
- Batch endpoint choices limited to endpoints with live models; the default is `/v1/responses`.
- The `input_audio` content part, which the Responses API does not accept. Voice notes recorded with the microphone button are now transcribed with `gpt-transcribe` (`POST /v1/audio/transcriptions`) into the message field for editing; this runs only after the data-sharing notice is accepted and never in Explore Demo.

### Fixed

- `gpt-4o-mini` has its own capability entry; it had relied on the loose prefix rule below.
- Blocked web-search domains reach the model as instructions even when a preset has custom system instructions.
- A preset on a retired model is migrated before computer-use and reasoning settings are checked, so those settings are judged against the replacement model.
- Fine-tuned model IDs (`ft:`) are not treated as retired.
- Only dated snapshots (`-YYYY-MM-DD`) inherit a known family's capabilities. Before, any suffix did, so `gpt-4o-realtime-preview` was treated as `gpt-4o` and `gpt-5.2-codex` as `gpt-5.2`.
- `web_search` filters send only `allowed_domains`; `blocked_domains` is not an API field and is now expressed as instructions only.
- The file-search ranker sends `default-2024-11-15`; earlier builds saved a malformed older ranker ID.
- Moderation checks name `omni-moderation-latest` explicitly.
- Settings registry fields are labeled with their Responses names (`instructions`, `max_output_tokens`, `truncation`, `safety_identifier`, `text.format`).
- Three closures whose `[weak self]` had no effect because an enclosing closure already held `self` strongly (API Workbench socket reader, conversation save completion, voice recorder timer). Xcode 27 reported them.
- `AppleDateUtilities.formatISO8601` is nonisolated, so the Contacts tool can format birthdays off the main actor, which Swift 6 language mode would reject.
- Xcode Cloud runs 42 through 45 archived successfully, then failed at "Preparing build for App Store Connect" because the project still declared 2.6 after 2.6 was released.

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
