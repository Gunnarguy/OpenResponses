# OpenResponses 2.6: upgrade and feature guide

Use this alongside the [full release notes](../../ReleaseNotes_2.6.0.md). These steps describe the current 2.6/build 39 source and locally installed development build; check the [release plan](../../AppStoreReleasePlan.md) for distribution status.

## Connect apps with account sign-in

Settings → MCP now has one Connections library. Choose an app, tap Connect, and complete the provider's browser login. You can keep several accounts connected, choose which are used in each chat, rename workspaces, inspect tools and manage approval/access per account. Existing configurations migrate without replacing other accounts.

The catalog includes 44 entries plus live registry search. Nineteen entries accepted OpenResponses' native callback in live registration checks, and Notion's real login screen was reached in the running app. Services requiring developer registration or a different callback arrangement are clearly labeled Provider setup required. This is not a claim that every listed service is already available. [Complete provider table and setup boundaries](../../mcp-connections.md).

Workbench drafts now recover after relaunch, replacing a draft requires confirmation, JSON editing preserves straight quotes, and malformed schema requests are rejected before sending. Voice is explicitly labeled as a separate session, and the reset control says Reset Prompt Settings.

## Existing conversations, keys and presets

Your existing conversation files, Keychain credentials and saved presets remain in use. New settings have backward-compatible defaults. You do not need to delete the app, wipe your chats, or replace a working key to use the update. Device validation preserved four existing conversation files byte-for-byte across installation and relaunch.

**Reset Prompt Settings restores the active prompt defaults; it does not wipe keys, conversations, remote resources or browser data.** Use the corresponding resource/credential controls for removal.

Keep a conversation export if you want an independent backup. Local history and optional OpenAI-stored response/conversation data are different stores. The app can retrieve known remote IDs; it does not enumerate every conversation belonging to your OpenAI account. An empty remote view does not prove your account has no stored conversations.

Demo Mode remains useful for exploring without a live API request. Live requests require your own account credentials and incur whatever usage your account/provider charges. The existing consent flow appears before the first live send.

## Choose a model and review advanced controls

The recommended selector now groups Astra, Sol, Terra and Luna consistently. Existing saved choices remain selected. If a request reports an unavailable model, check that the account/project behind your key has access; a visible catalog entry is not an entitlement.

Reasoning choices follow the selected model. Astra starts at low rather than none, and pro reasoning is shown only for supported configurations. Advanced controls include context, verbosity, image action/partial previews, compaction, tool search, hosted shell and client-tool execution modes. Unsupported parameter combinations are filtered or constrained by the app.

Automatic compaction, hosted shell, tool search, async calls, programmatic calls and multi-agent mode start off in newly defaulted settings. Enable features deliberately for the conversation that needs them. Async and programmatic calling are alternatives; they are not simultaneously active. The subagent limit and client-tool round limit govern their corresponding execution paths, not every possible server-side action or charge.

## Use the API Workbench

Open **Settings → Model → API Workbench**. Start with a template, inspect the JSON and transport, then send. The Workbench is useful when you need request-level control that a chat toggle does not expose.

You can inspect streamed/raw events, export the full completed response, count input tokens, compact context, retrieve a background response, cancel a background job, or inspect a known conversation and its items. Large on-screen previews may be shortened; use full export when you need the complete payload.

For a client tool call, provide the real result using the returned call ID before continuing. An arbitrary schema in the editor does not supply a native implementation. Hosted tools run through their configured API service; the Workbench does not execute arbitrary shell commands on the iPhone. Socket disconnection and server-job cancellation are separate operations. If a socket is lost mid-session, inspect server state before retrying potentially consequential work.

## Have a continuing voice conversation

Open voice mode, grant microphone access when requested, and speak normally. The session should continue listening after the assistant answers. The input/output visualizer now follows the audio pipeline, and stale playback callbacks no longer leave it permanently in a speaking state. You can mute without destroying the whole session; VAD supports interruption while the assistant is speaking.

After a phone call, route change or headset change, allow the audio session to recover. If the route remains unusable, end and reopen the voice session. Actual speaker echo, Bluetooth devices and interruption acoustics still need broader physical-device checks. A successful synthetic two-turn test does not prove all of those environments.

Voice uses a network Realtime session. It is not a promise of offline speech-to-speech inference.

## Connect and discover MCP tools

Open Settings → MCP → Connections. Choose a supported provider and tap Connect to sign in through its browser login. Use Add a Custom Server only when you have a remote address to add. Account sign-in is the default; public servers and explicitly supported API keys are separate advanced choices.

Select one or more saved accounts with Use in this chat. Open an account to rename it, sign in again, inspect tools and set permissions. Discover Tools retrieves definitions through OpenAI without running tools or sending chat history. It needs your OpenAI key and data-sharing consent. The account login itself does not require that key.

An account is not represented as a verified tool catalog until discovery succeeds. The five-minute discovery cache is separate from OAuth storage and refresh. Provider setup requirements and the complete availability table are in [MCP connections](../../mcp-connections.md). Ordinary chat does not require an extra discovery turn as a preflight.

## Browse and search

Hosted web search and browser automation are separate capabilities. Hosted search returns search sources/citations through OpenAI. Browser tools operate an on-device, offscreen WebKit page and can navigate, read, search, click, type, scroll and move through history.

Enable the relevant tools for the conversation. DOM results provide element refs that should be used with the current page snapshot; refs expire when the page or target changes. Computer screenshots now use the advertised pixel size. The browser preserves its own website state, not your existing Safari session.

Stop, changing chats or disabling Computer Use cancels pending browser work. If a form may already have been submitted, inspect the page before explicitly retrying: cancellation cannot undo a server-side change. API safety prompts apply to their originating turn and can be denied or dismissed. There is not a separate approval dialog for every browser click.

Some sites remain unsuitable for automation: CAPTCHAs, cross-origin embedded content, closed shadow roots, native pickers and flows requiring trusted physical input can need manual interaction. Action, navigation and time limits intentionally end a run that stops making progress.

## Attach searchable files

Upload completion means the file reached the service; vector-store indexing must also complete before it is searchable. The progress sheet keeps each file's result visible, including partial failures. Only successfully indexed/attached files are presented as ready for the relevant attachment flow.

If waiting times out, use **Check again** on the existing upload. This checks status instead of uploading a duplicate. Stopping the wait stops the local polling; server indexing may continue. Resolve a reported indexing failure rather than repeatedly attaching a file that has not become ready.

## Save Batch results and prepare training data

The Batch lab can export the complete available output and error files through the system share sheet. Choose Save to Files or another destination. Partial jobs may have useful output/error files; availability of those files matters independently from overall success. Leaving/cancelling a download cleans up its temporary file; a chat preview is not the export artifact.

The fine-tuning lab now expects a reviewed JSONL dataset. Import UTF-8 text-chat examples, one JSON object per line, with supported roles, a user turn and a final assistant turn. The app requires at least ten examples and validates a maximum 50 MB import. This path does not accept image/tool-call training formats.

Exporting one conversation is a **draft** for review and dataset preparation. App system-log entries are removed; one conversation is not automatically enough training data. Review the chosen model, dataset and positive numeric/automatic training parameters before submitting. The app explains that fine-tuning access is winding down; account eligibility and server responses determine whether a job can be created.

No paid Batch or fine-tuning job was started solely to validate this release's export/import repairs.

## Migrate legacy Assistant configuration

Use local Assistant JSON import to turn saved configuration into a Responses preset. Live retired Assistants/Threads/Runs operations are disabled. The migration utility does not restore a retired API or imply that every legacy hosted object can still be retrieved.

## Troubleshooting changes in behavior

| Symptom | Check first |
| --- | --- |
| Model or tool is unavailable | Account/project access, model compatibility and whether the tool is enabled. |
| MCP is configured but unverified | Explicit discovery result, authentication format, server reachability and OAuth setup. |
| Browser action is refused or times out | Current snapshot/ref, visible unambiguous target, navigation/action budget and site-specific restrictions. |
| Voice appears connected but silent | Mute state, microphone permission and current audio route; reopen after an unrecovered interruption. |
| File uploaded but cannot be searched | Indexing status and actual attachment result; poll the existing upload. |
| Remote history is incomplete | Only known remote IDs can be hydrated; this is not account-wide enumeration. |
| Save fails | The app reports the storage error without recursively inserting more messages. Preserve an export if possible and inspect device storage. |
| A cancelled tool may have run | Inspect its destination before retrying; uncertain mutations are not automatically replayed. |

See [validation and known limits](Validation.md) for what was exercised and what still needs manual coverage.
