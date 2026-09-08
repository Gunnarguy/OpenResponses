# What's new in OpenResponses 2.6

**Documentation updated September 8, 2026.** Covers the full change from the last v2.5/build 7 source state to the current v2.6/build 39 implementation. This is the locally verified release candidate, not an announcement of App Store availability. [Complete release dossier](releases/v2.6/README.md).

**ASC checked September 8:** v2.5/build 4 is released. v2.6 remains Prepare for Submission with no build selected; uploaded build 38 predates the completed working-tree changes. [Distribution details](releases/v2.6/ASCStatus.md).

OpenResponses 2.6 expands the app into a more capable OpenAI API playground and improves the reliability of everyday chat, voice, browsing, connected tools, and file workflows. The update includes the earlier June/July additions as well as the September refresh.

## New Connections page and account sign-in

Settings → MCP now has one Connections library. Choose an app, tap Connect, and complete the provider's browser login. You can keep several accounts connected, choose which are used in each chat, rename workspaces, inspect tools and manage approval/access per account. Existing configurations migrate without replacing other accounts.

The catalog includes 44 entries plus live registry search. Nineteen entries accepted OpenResponses' native callback in live registration checks, and Notion's real login screen was reached in the running app. Services requiring developer registration or a different callback arrangement are clearly labeled Provider setup required. This is not a claim that every listed service is already available. [Complete provider table and setup boundaries](mcp-connections.md).

Workbench drafts now recover after relaunch, replacing a draft requires confirmation, JSON editing preserves straight quotes, and malformed schema requests are rejected before sending. Voice is explicitly labeled as a separate session, and the reset control says Reset Prompt Settings.

## Current models, clearer choices

The app now shares one recommended model catalog across onboarding, chat, and settings: **GPT-6 Astra, GPT-5.6 Sol, Terra, and Luna**. New defaults use Astra; saved model choices are preserved. You can search account-visible models, use the fallback catalog when discovery is unavailable, or enter a custom model ID.

Change models directly from the chat model control. Settings adapt to the selected model instead of offering one generic set of parameters. Reasoning effort, summary, reasoning context, supported pro mode, and verbosity are available where appropriate. Unsupported sampling parameters are omitted for Astra, and changing models normalizes incompatible choices.

Image generation now includes **GPT Image 2**, generation/edit action selection, compatible transparency/output formats, and streaming partial previews. Current voice defaults include **GPT Realtime 2.1** and **GPT Live Transcribe**. Availability still depends on the OpenAI account used by the app.

## A more capable chat tool loop

Current-model foreground chat can execute configured function and custom-text tools through a dedicated runner. Optional async lookups allow supported read-only work to overlap generation. Programmatic calling supports model-directed combinations of enabled tools. Multi-agent responses use a WebSocket connection to supply real tool results to waiting agents.

The chat distinguishes the main answer from subagent activity and shows actual tool execution state. Generated arguments are not displayed as proof that a tool completed. Known results and replay context are retained when a turn is interrupted; uncertain outcomes are identified rather than silently retried.

These advanced modes have compatibility rules. Async and programmatic calling are mutually exclusive; mutations run sequentially. Computer Use and background responses retain their dedicated execution paths. Hosted shell and tool-search controls are opt-in, and selecting a feature does not grant account access to it.

## New API Workbench

Open **Settings → Model → API Workbench** for editable JSON requests over HTTP, SSE, or persistent Responses WebSockets.

The Workbench supports response creation and retrieval, background cancellation, complete input-item retrieval, token counting, manual compaction, and conversation metadata/items. It includes examples for current models, images, hosted shell, tool search, custom text tools, async/programmatic calls, configuration updates, apply-patch payloads, and multi-agent requests.

You can inspect events, supply actual function/custom-tool results, continue a response, inject results into a waiting multi-agent response, and steer an active response. Complete terminal responses can be exported even though the on-screen event preview is bounded. Arbitrary Workbench tools still need results supplied by you; the Workbench does not automatically execute arbitrary patches or commands on the phone.

## Voice that continues the conversation

The v2.6 development cycle adds Realtime voice and voice recording/transcription surfaces. The subsequent fixes address the reported behavior where the first answer worked but the purple bars appeared to freeze and the conversation stopped listening.

Microphone transmission is now independent of a potentially stale “Speaking” label. Playback scheduling and completion share one state owner, old callbacks are ignored, and elapsed-audio recovery releases capture if a completion callback is lost. Audio is resampled once per microphone buffer. The visualizer follows capture/playback levels, and muting keeps the current session connected.

Voice configuration is applied before audio engines start, with interruption and route-change recovery and barge-in controls. A synthetic-audio check completed two consecutive VAD-driven turns in one session. Real microphone, speaker, Bluetooth, and room-acoustic behavior still benefit from device testing.

## MCP discovery with useful results and bounded waiting

MCP settings expose **Discover Tools**, refresh, cancellation, tool search, input schemas, annotations, and last-check information. Allowed-tool filtering is reflected in the displayed catalog. Editing a connection clears stale results, and a saved configuration is not presented as a verified connection.

Discovery runs through OpenAI-hosted MCP. It does not launch a local MCP process or open a browser. Normal chat no longer performs an extra diagnostic model turn before every eligible MCP interaction. Explicit discovery has a 35-second deadline, shared in-flight requests, and a short cache keyed to the actual connection and credentials.

Authentication failures, rate limits, malformed catalogs, and empty catalogs are distinguished. Draft discovery does not overwrite saved credentials. Private-provider OAuth and server-specific compatibility remain separate from discovering a public server's tools.

## More reliable browsing and web search

Hosted Web Search and the on-device browser have distinct roles. Web Search provides OpenAI-hosted retrieval, citations, sources, and supported domain/location settings. The persistent on-device WKWebView handles navigation, reading, clicking, typing, scrolling, and history.

DOM and screenshot actions now share one ordered execution queue, with operation deadlines and per-turn limits. Page snapshots provide expiring element references. Ambiguous, hidden, disabled, changed, or stale targets fail explicitly. Clicks and form submissions are sent once, and typed values are checked immediately after entry.

Computer screenshots now contain exactly **440 × 956 pixels**, matching the model's coordinate space even on higher-density displays. Stop, changing chats, disabling Computer Use, and pending API safety checks stop active or queued work. WebKit recovery recreates the browser without replaying an uncertain click.

The invalid hosted-search `profile` field is removed. Search Style becomes instruction guidance; preferred page count and crawl depth are labeled as preferences rather than API-enforced limits. The separate local browser limits are enforced in code.

## Safer conversations and clearer activity

Remote conversation hydration and richer annotations were added earlier in the cycle. The current app retrieves known remote conversation metadata and paginated items separately. It does not promise an account-wide list of every OpenAI conversation.

Manual compaction preserves the complete returned context window, including opaque items, and replays it on the next turn. Compaction IDs are no longer mistaken for response IDs. Deleting a message invalidates remote/raw context that would otherwise still contain that text.

Switching chats during streaming now flushes text into its owning conversation and invalidates delayed updates. Message identity replaces stale array positions. Deleting an active chat cannot restore it through a queued save.

Conversation saves are coalesced and serialized on a background queue; unchanged image attachments reuse their PNG encoding. This removes repeated whole-conversation encoding/writing from the per-token UI path. The app now has one root chat controller. No specific speed or battery improvement is claimed without profiling.

Tool timelines, reasoning summaries, usage reporting, artifact/image handling, and request inspection received improvements throughout the cycle. “Reasoning” in these surfaces means returned summaries and metadata, not access to private internal reasoning.

## Files and developer jobs that finish the workflow

**Vector-store uploads:** “Ready for search” now requires completed indexing. Failed files and files still indexing remain visible after partial success. Stop cancels local waiting; Check Indexing Again resumes status checks without uploading another copy.

**Batch Jobs:** Submit JSONL requests, inspect status, and save complete result or error files through the system share sheet. Available partial outputs are exportable too. The old 400-character result preview no longer substitutes for a download.

**Fine-tuning:** Import reviewed text-only JSONL with at least ten examples and validate parameters before submission. Current-chat export produces a draft instead of immediately launching an invalid one-example job. The screen explains that OpenAI is winding down fine-tuning and that access is restricted to eligible existing users.

**Pagination:** Vector-store files, Batch jobs, and fine-tuning jobs follow all pages. Notion chat search can request the next page, and compacting a Notion response no longer discards results while advancing its cursor.

**Legacy migration:** Retained Assistant JSON can be imported as Responses presets. Live Assistants operations are disabled after the API shutdown; old thread/run management is not advertised as an active 2.6 feature.

## Quality work included in this release

Earlier v2.6 work improved settings labels/layout, URL handling, WebView scheme checks, date formatting, image/OCR processing, Notion metadata lookup, Swift concurrency boundaries, redaction, and test/build configuration. Apple Calendar, Contacts, Reminders, first-send data-sharing consent, Explore Demo, and the established attachment workflows remain available; they are not all new inventions in 2.6.

The latest September 8 implementation passed **294 unit/integration tests**. Signed iPhone delivery and persistence checks are recorded in the [validation ledger](releases/v2.6/Validation.md), separately from App Store Connect delivery.

For exact source coverage, API boundaries, upgrade instructions, and remaining validation, read the [release dossier](releases/v2.6/README.md). The latest local results do not establish a TestFlight upload, App Review approval, or public release.
