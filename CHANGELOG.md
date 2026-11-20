# Changelog

This changelog records implemented application behavior. Version 2.6 includes committed development after the last 2.5 source state and the September working-tree additions. Release dates below are documentation/verification dates, not inferred App Store publication dates.

## 3.1 — in development

**Marketing version:** still 3.0 in the project until 3.0 ships (build 55 is the 3.0 archive and has none of this).

### Changed

- Settings is one list of named pages instead of five segmented tabs (General, Model, Tools, MCP, Advanced), at Gunnar's request on November 19, 2026 ("holy shit are some of the best options hidden"). Before, Local Python, the hosted shell, multi-agent, tool search, async and programmatic tool calls, moderation, the image options, the voice settings and the API Workbench all sat at the bottom of the Model tab under one "Current Responses capabilities" heading, below the model card, and Verbosity was there twice. Now:
  - The root lists API Key, Model & Reasoning, Instructions, Response Format, Voice, Tools, Agents & Tool Calling, Connectors, Files & Vector Stores, Prompt Library, API Workbench, Decisions, Batch Jobs, Request Options, Privacy & Safety, Text Size and About. Each row shows what is set now (for example "gpt-6-sol · Medium", "4 on", "Saved").
  - A search field finds about 50 options by name or by a word in their description ("pyodide" finds Local Python) and opens the page that holds each one.
  - Tools groups every tool by what it does (Search, Your documents, Run code, Create, Act for you, Other apps), each with an icon and one line saying what it does. Local Python and the hosted shell are next to Code Interpreter; Code Interpreter's memory, File Search's hybrid ranking and Web Search's live access sit under the tool they change; the Custom Tool has its own page.
  - Agents & Tool Calling holds tool choice, parallel calls, the call limit, multi-agent, tool search, async and programmatic calls, tool rounds and Background Mode. Privacy & Safety holds Store on OpenAI, moderation, data-sharing consent and the safety identifier and prompt cache key. Truncation and streaming moved to Response Format.
  - Options are named for what they do ("Use tools: When useful / Always / Never", "Answer length: Short / Medium / Long", "When the chat gets too long: Stop with an error / Drop the oldest messages"); the values sent to the API are unchanged, so saved presets load as before.
- UI tests: the voice-sheet regression test opens Voice from the Settings root, and a new test searches "pyodide" and lands on Tools.
- Settings rows at the accessibility text sizes put the value under the title and drop the icon tile. Side by side, the largest size broke words into pieces ("Op / en / AI / API / Ke / y", "No / t set"); seen on simulator 54DDDEDE at Accessibility XXXL on November 19, 2026, and fixed the same day. Toggle rows drop the icon tile at those sizes too.
- Connectors (formerly Connected Apps), at Gunnar's request on November 19, 2026 ("I want people to be able to connect literally whatever they possibly are able to connect"):
  - The page opens on the popular services grouped by kind, with nothing to type, and below them every remote server in the public MCP Registry, loaded 100 at a time as the list scrolls. The search field filters both, searching the registry after a pause in typing; the "Search the MCP Registry" button and the category picker are gone. Adding a server by its address is the last row.
  - Services marked "Provider setup required" had no button. They now say "Sign-in or key" and offer Try Signing In, plus Connect with a key or token for a personal key from that service's settings.
  - GitHub's official server is in the popular list. OpenAI's own connectors with no server address (Gmail, Google Drive and the rest) are no longer listed, since the app can't sign in to them yet.
  - Notion is one more connector: the Tools page's "Existing Notion integration" section is gone, and a Notion integration token saved by an earlier version shows on the Connectors page as "Notion (integration token)", with its own Use in this chat switch.
  - The root row and its Tools-page link show how many connections this chat uses ("1 of 2 on", or "None yet").

- At the accessibility text sizes (Gunnar, November 19, 2026: "fix those"):
  - A tool step in the chat puts its status under the name and leaves out the tool icon. Before, at Accessibility XXXL it read "fet / c…" and "Fai / led" with the icon spilling out of its 16-point box.
  - Onboarding pages scroll when their text is taller than the page, and the AI notice and terms under them scroll in their own area. Before, they were cut to "Welcome…", "Experience t…" and "AI-generated content can be inc…".
  - The chat's floating Details button has a capsule background, so it no longer sits directly on message text.
  - The message field gets its own line with its buttons under it. Before, it shared one line with four buttons and showed "Mes…".
  - Both chat-screen audits now pass, including `testLargestTextSizeKeepsTheChatScreenReadable`.

### Added

- Text Size (Settings → Text Size), at Gunnar's request on November 19, 2026: "Same as iPhone" by default, or any of the twelve system sizes on a slider, for OpenResponses only. It is applied as a trait on the app's windows, so sheets such as Settings follow it; a SwiftUI `.dynamicTypeSize` on the root view did not reach them (seen the same day). Checked on simulator 54DDDEDE with the phone at Accessibility XXXL and the app at Default: the chat and Settings both drew at the default size.

### Verification (November 19, 2026, simulator 54DDDEDE, iOS 27.0)

- Unit suite: 384 tests, 3 skipped, 0 failures. UI tests `testSettingsPassTheAccessibilityAudit`, `testSettingsSearchOpensThePageThatHoldsAnOption` and `testVoiceSettingsStayOpenFromSettings` pass.
- The Settings audit passes with the "Assistant" and "What the assistant can do" headers added to the test's known audit quirks. The audit reports them as "Dynamic Type font sizes are partially unsupported" against the frame of the system's full-width header container, whatever the header holds (a String, a Label, an icon and text, an explicit font), while a screenshot at Accessibility Large showed both headers grown, the second wrapping to two lines.
- Account sign-in and key connection to a live service were not tried.

## 3.0 — in development

**Marketing version:** 3.0.

### Added

- Decisions (Settings, Advanced tab, Developer Operations): a screen for OpenAI's Decisions API (`POST /v1/decisions`, generally available; guide and API reference read November 13, 2026). Write some input, optionally add a photo, and ask up to 400 questions of three types: yes or no (the probability the statement is true), choice (one of 2 to 255 values, with a probability for each) and score (2 to 10 ordered levels; the answer is a probability-weighted average of the level numbers, so it can fall between levels). Answers show as bars with each answer's confidence, a refusal says the model declined that question, and an answer type the app doesn't know yet is shown by name. The footer gives the input tokens and the cost at $0.10 per million input tokens (answers are not charged). It uses `gpt-6-luna`, the only model Decisions accepts. Three examples (a support ticket, a bug's severity, a product photo) are in the ⋯ menu, which also copies the request JSON. Questions are kept on the device; the input and photo are not. A photo is sent as a JPEG of at most 1,536 pixels on its longest side. The screen asks for the same data-sharing consent as the API Workbench and stays offline in Demo Mode.
- The API Workbench has a "Create decision" endpoint with the support-ticket example.
- `scripts/decisions_probe.sh [Keychain service]` sends the support-ticket example to the live API with a key read from the Keychain, which it passes to curl on stdin.
- Tests: 9 in `DecisionsTests` (request shape, image input, names, every validation message, every answer type including a refusal, a boolean choice and an unknown type, the cost estimate, saved questions, image resizing, the Workbench endpoint, and the answer cards drawn with `ImageRenderer`); the full unit suite ran 370 tests, 3 skipped, 0 failures. The answer cards first cut the score line short; the confidence now has its own line.
- The app asks for an App Store rating with Apple's own sheet (SwiftUI `requestReview`; `RequestReviewAction` and the Human Interface Guidelines' Ratings and reviews page read November 14, 2026, and the declaration confirmed in the iOS 27.0 SDK). Until now it never asked: on November 14, 2026 it had 359 first-time downloads and 1 US rating. It asks two seconds after a chat answer finishes, on the first answer that finished with no failed or cancelled tool step, or on the third finished answer of any kind, once per app version and never within 14 days of the last ask. It never asks at launch, during onboarding, in Explore Demo, from a button or under tests, and an error, a stopped answer or one waiting for an approval doesn't count. If the app is not in front, or the next answer has started, the request is held and made on the next return to the app, and the ask is recorded only when the request was made. Apple decides whether the sheet shows (at most three times in 365 days, never in TestFlight). About has a "Rate OpenResponses" link that opens the App Store's review form. 14 tests in `ReviewPromptServiceTests`.

### Fixed

- A function call's step shows its arguments while the model writes them. The app ignored `response.function_call_arguments.delta` and `.done`, so the step stayed empty until `response.output_item.done` finished the item (Responses API streaming events reference, read October 19, 2026). Calls still run from that item, as before. The app now also recognizes `response.custom_tool_call_input.delta` and `.done`, but a custom tool call has no step yet, so nothing shows for it.

- Calendar and Reminders accept a date or time with no time-zone offset. The tool schemas ask for the device's offset ("preferably"), and models leave it out: on October 21, 2026, GPT-6.1 Sol sent `"2026-11-04T18:30:00"` for each game on a photographed schedule, and 2.9 rejected all twelve `createAppleCalendarEvent` and `createAppleReminder` calls with "The provided date is not a valid ISO 8601 timestamp", although ISO 8601 allows a local time. `AppleDateUtilities.parseToolDate` reads a value with no offset in the device's time zone, with or without seconds or fractional seconds and with a space for the T; a value with an offset or `Z` means that moment, now also without seconds ("2026-11-04T18:30-08:00"). Every field is checked (ASCII digits, a real day of the month, hours to 23), so anything else is still refused. A local time that a daylight-saving change skips moves forward by the gap, and a bare date is the start of that day even where midnight is skipped. The tools go through three helpers: `eventInterval` refuses a bare event date with a message asking for times (the app makes timed events only), `reminderDue` gives a bare due date a due day with no time, and `queryRange` makes a bare end date in a Calendar or Reminders query cover the whole day. `parseISO8601` stays strict, because the file converter uses it to recognize date columns. In a query, a UTC midnight or 23:59:59 means the local day's boundary with or without seconds. Tests: 15 new in `AppleDateUtilitiesTests`, which call the helpers the tools use, and one saves a reminder with a due day through `AppleProvider` and reads it back from EventKit with no hour (it skips where the test host has no Reminders access, as on CI); the two older assertions that `parseQueryDate` refuses a local time and a bare date were replaced by other refused inputs, and those two values are now expected to parse.

## 2.9 — released October 2, 2026 (build 54)

**Marketing version:** 2.9. Released October 2, 2026 as build 54, the Xcode Cloud run 54 archive of commit `baff2fc`, after one submission on October 1. App Store text: [release_notes.txt](fastlane/metadata/en-US/release_notes.txt) and [2.9 release notes](docs/ReleaseNotes_2.9.0.md). Everything below was found while filming the app's demo videos on 2.8.

### Fixed

- Tool steps no longer stay on "Queued" after they finish. A step moved on only at `response.output_item.completed`, an event the Responses API doesn't send: it ends every output item with `response.output_item.done` (openai-python's stream event types, read October 1, 2026). Web search, file search, Code Interpreter, image generation and MCP steps now show Running while they work and Completed or Failed when they end. The app's own functions, the browser steps of Computer Use among them, show Running until the app has run them, then Completed, or Failed when their output starts with "Error" (the browser's failures read "Error processing …").
- A failed MCP tool shows Failed. Its error carries `content` instead of `message` (openai-python's McpToolCallError), the app couldn't read the item, and it dropped the event.
- The answer after a tool call starts a new paragraph. Text from a new output item ran straight on from the text before it ("retrying.The Chicago Cubs") on the streaming path taken with Computer Use and with models older than GPT-5.6 or specialized ones such as Codex models; the path the other GPT-5.6 and GPT-6 models take already separated them.
- The note the app shows when a tool fails goes away once the model starts its answer, as intended. Each round of a tool loop forgot the notes when its response completed, so after a round that only called another tool, or a second failure, the note stayed above the answer.
- A Code Interpreter chart shows once. The app keeps each generated picture with the message's images too, which is the copy a saved conversation keeps, and the message drew both. The same file could also be added again from a link in the answer, and code that displayed a chart and also saved it got it cited twice: Code Interpreter keeps the displayed plot as a file named by its own id (one chart was listed three times). Each file is listed once now, and a plot that matches a file the code saved shows once, as the saved file. A reopened conversation no longer lists the chart again as "Content not loaded", and generated text files keep their words: every saved file came back as "Content not loaded", though a text file's words were saved. A picture that failed to load stays listed with its error.
- Reasoning summaries show their formatting. A summary's heading showed its Markdown asterisks ("**Calculating tip distribution**").
- GitHub CI's unit tests no longer fail on a slow shared runner: the chat lifecycle tests wait up to 15 seconds instead of 1 for background work, and the WebKit browser tests retry a first page load that times out. Run 36751566276 on September 30 failed six timing tests this way while the same code passed locally and on the previous run.
- The warning shown when you turn on Computer Use said it "can control apps". It drives only the app's own off-screen browser, and the warning says so now.

### Changed

- Tool steps are named as Settings names the tools ("Code Interpreter", "Web Search", "File Search", "Image Generation") instead of by the API's item types ("code_interpreter_call", or "Image Generation Call" with GPT-5.6 and GPT-6 models), and a Code Interpreter step opens to the Python it ran.

## 2.8 — released September 30, 2026 (build 51)

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
