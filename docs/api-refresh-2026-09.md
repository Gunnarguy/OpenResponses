# September 2026 OpenAI API refresh

> Part of the [complete v2.6 release dossier](releases/v2.6/README.md). Test counts below describe this milestone; the final implementation total is **265**, recorded in the [validation ledger](releases/v2.6/Validation.md). [Live ASC status](releases/v2.6/ASCStatus.md) is tracked separately.


Verified against official OpenAI documentation and account-visible API models on September 6–7, 2026. This describes the local source update, not an App Store release.

## Native chat and settings

- Shared recommended catalog: `gpt-6-astra`, `gpt-5.6-sol`, `gpt-5.6-terra`, `gpt-5.6-luna`. Account discovery, offline fallback, model search, and explicit custom model IDs coexist. Unknown IDs do not automatically inherit current-model capabilities. Saved model choices remain intact.
- Model-aware reasoning effort, summary, context (`auto`, `current_turn`, `all_turns`), and pro mode. Astra omits unsupported sampling parameters; compatible earlier models keep sampling with reasoning disabled. Function-result continuations use the same settings as the initial request.
- Opt-in automatic compaction through `context_management`, hosted shell, and deferred function/MCP schemas through `tool_search`.
- Native foreground tool orchestration for current models: Astra async lookups, programmatic tool calling, function and custom-text outputs, and multi-agent WebSocket execution. The configured echo/calculator tools execute locally; configured webhooks and existing Apple/Notion tools use their existing execution handlers. Requests advertise only enabled tools, and execution checks that allowlist again.
- Read-only functions can overlap generation, with at most four concurrent client lookups. Mutations execute sequentially and are excluded from programmatic/async routing. Async and programmatic calling are mutually exclusive; async plus multi-agent disables parallel tool calls. Multi-agent omits unsupported reasoning summaries and `max_tool_calls`.
- Native multi-agent responses send real tool results with `response.inject`, wait for acknowledgment and the terminal response, and retain agent/caller metadata. Root text is kept separate from subagent activity cards. Multi-agent uses a configurable client-call limit; HTTP tool chains use a configurable round limit. These controls do not impose a total hosted-agent token budget.
- Stateless turns retain raw program fingerprints, reasoning, compaction, phase, and agent fields. Cancellation and failures retain known tool results, mark unresolved tool outcomes unknown, and fork the saved replay window without automatically retrying mutations. Deleting a message invalidates the corresponding remote/raw context so subsequent turns cannot replay that deleted text.
- Native activity cards distinguish generated arguments from completed execution, retain actual tool results, and show cancelled/failed work. Token usage accumulates across tool rounds. Generated images render partial and final bytes into stable image slots.
- MCP settings and tool definitions are available again, retaining Keychain credentials and the existing approval path. Demo Mode remains offline even when a key is present.
- GPT Image 2, generation/edit action, transparency-compatible formats, and up to three partial previews on streaming requests. Input-token counting excludes streaming-only previews.
- Current Realtime session schema, GPT Realtime 2.1, GPT Live Transcribe, and current voices. Existing saved voice choices normalize when unsupported.
- Manual compaction fetches the complete stored input/output, retains the entire compacted output window including opaque reasoning/compaction items, persists it locally, and replays it once before continuing. Compaction IDs never become response IDs. Switching conversations while compaction runs cannot apply its result to the wrong conversation.
- Conversation metadata and items are fetched separately, with item pagination. The UI shows remote IDs already associated with local conversations; the API does not provide account-wide conversation enumeration.
- Legacy Migration imports retained Assistant JSON. Live Assistants operations are disabled following the August 26 shutdown.
- Existing prompt-cache controls stay optional, with cached-token and cache-write-token reporting preserved. No automatic cache-write configuration is added to short prompts.

## API Workbench

Open **Settings → Model → API Workbench** for editable JSON requests and complete JSON export.

| Surface | Coverage |
| --- | --- |
| Transports | HTTP, SSE, persistent Responses WebSocket |
| Responses | Create, retrieve, background cancel, all input items |
| Context | Input-token counting and standalone compaction |
| Conversations | Create, retrieve metadata, all items |
| Examples | Astra, hosted shell, tool search, async functions, programmatic tool calling, multi-agent beta, GPT Image 2, automatic compaction, configuration updates, custom text tools, apply patch |
| Continuation | Saved-response or same-socket continuation, raw output replay for stateless HTTP, batches of actual function/custom tool results |
| Multi-agent tools | Pending calls appear during generation; saved results can be injected into waiting agents, with acceptance/failure feedback |
| Steering | `response.steer`, acceptance/failure events, original response termination and automatic successor handling |
| Diagnostics | Raw unknown events, structured API errors, request IDs, retry information, final response export |

The workbench preserves unknown JSON fields, tool caller metadata, and phase values. Its on-screen event preview is bounded; the complete terminal response is retained for export. Multi-agent requests attach `OpenAI-Beta: responses_multi_agent=v1`.

The Workbench is a raw API client: arbitrary client tools require results supplied by the user. Function/custom results can be composed and saved by their real API call IDs, then submitted as a complete batch or injected into an active multi-agent response. Patch outcomes and MCP approvals can be supplied as documented raw input items. Native chat separately executes its configured tools through the native runner described above.

Demo Mode blocks Workbench networking. Live Workbench operations use the app's existing Keychain and first-send consent setting. Stopping the connection is distinct from cancelling a background response on the server.

## Verification

- Simulator build and 204 unit tests passed on iPhone 17 Pro / iOS 26.5. Coverage includes request compatibility, old preset decoding, complete compaction-window replay, raw program/agent context, duplicate call IDs, async batching, cancellation, uncertain-result recovery, WebSocket injection acknowledgments/failures, native tool-card state, root/child text separation, image constraints, Realtime schema/audio conversion/playback recovery, and the settings coverage registry.
- Live account model discovery verified the recommended text, image, Realtime, and transcription IDs.
- Live input-token counting accepted Astra reasoning controls and the combined tool-search, deferred function, hosted-shell, and GPT Image 2 schemas.
- Live Responses WebSocket creation and steering produced a completed continuation.
- Live Astra async custom-tool execution completed a two-round stateless response with the actual fixture result. Live programmatic calling executed two fixture functions and successfully replayed the program/program-output state into the final answer.
- A live multi-agent WebSocket test completed with `/root` and `/root/probe`, a real client tool result, and one accepted injection. A second test compiled and ran the actual Swift `ResponsesAPIClient`, `ResponseSocketRunner`, and `ResponseTurnRunner` source against the API and also completed with the fixture in the answer. The harness substituted only credential loading and the local fixture executor; it did not exercise the full iOS UI or EventKit/Notion integrations.
- Two bounded non-streaming HTTP multi-agent probes timed out waiting for client-tool handoff. Native multi-agent therefore uses the live-verified WebSocket path. The Workbench retains HTTP/SSE as explicit developer transport choices.
- Live GPT Image 2 generation returned one partial preview and a valid final PNG (772,159 bytes).
- Live standalone compaction preserved a test codename across the compact/replay boundary. Stored validation responses were deleted afterward.
- Live Realtime accepted the nested audio, voice, and transcription configuration. This was a session-schema check, not a microphone/playback quality test.
- After an iPhone report of voice freezing after its first answer, microphone uploads were decoupled from the displayed Speaking state. Playback scheduling/completion now shares one actor, stale callbacks are ignored, and an elapsed-audio fallback releases capture if a completion is lost. Each microphone buffer is resampled once. Waveforms use capture/playback levels; mute keeps the same session. Audio configuration is applied before engines start, with interruption/route recovery. A live synthetic-audio test completed two consecutive VAD-driven turns in one session and retained the first answer for the follow-up. Actual phone acoustics still require user verification.
- Simulator UI checks covered model selection, valid Astra effort controls, async/programmatic mutual exclusion, multi-agent limits, Computer Use compatibility gating, custom text-tool configuration, restored MCP navigation, Workbench navigation/JSON editing surface, and missing-credential feedback. Repository preflight, secret scan, and `git diff --check` passed.

Credentials were loaded privately from an existing local configuration for bounded validation, never printed or added to this repository. The simulator UI was exercised without installing that credential.

Native orchestration applies to current-model foreground chat with Computer Use disabled. Computer Use and background requests retain their existing execution paths. Standalone compaction is disabled for multi-agent conversations; the API manages their automatic compaction. Arbitrary patch/custom execution, private MCP provider OAuth round trips, stateless multi-agent MCP approval recovery, actual Apple/Notion mutations, physical-device audio, and App Store delivery are not covered by these checks. Workbench reconnection does not automatically retry a tool or reconstruct in-flight server state.

## Official references

- [Current models and Astra migration](https://developers.openai.com/api/docs/guides/latest-model)
- [GPT-5.6 migration](https://developers.openai.com/api/docs/guides/upgrading-to-gpt-5p6-sol)
- [Reasoning and preserved context](https://developers.openai.com/api/docs/guides/reasoning)
- [Compaction](https://developers.openai.com/api/docs/guides/compaction)
- [Tool search](https://developers.openai.com/api/docs/guides/tools-tool-search)
- [Hosted shell](https://developers.openai.com/api/docs/guides/tools-shell)
- [Asynchronous tool calling](https://developers.openai.com/api/docs/guides/async-tool-calling)
- [Programmatic tool calling](https://developers.openai.com/api/docs/guides/tools-programmatic-tool-calling)
- [Multi-agent orchestration](https://developers.openai.com/api/docs/guides/responses-multi-agent)
- [WebSocket mode](https://developers.openai.com/api/docs/guides/websocket-mode)
- [Steering](https://developers.openai.com/api/docs/guides/steering)
- [Token counting](https://developers.openai.com/api/docs/guides/token-counting)
- [Image generation](https://developers.openai.com/api/docs/guides/tools-image-generation)
- [Realtime transcription](https://developers.openai.com/api/docs/guides/realtime-transcription)
- [Deprecations](https://developers.openai.com/api/docs/deprecations)

MCP discovery hardening and its separate live validation are documented in [MCP discovery](mcp-discovery.md).
