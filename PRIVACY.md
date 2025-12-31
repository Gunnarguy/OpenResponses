# OpenResponses Privacy Summary

**Last updated:** November 11, 2025

OpenResponses runs entirely on your device until you decide to contact an external service. The only network calls are the ones you trigger (OpenAI, optional MCP servers, and optional Notion integrations).

## What stays on your device

- **API credentials:** Your OpenAI key and any MCP/Notion tokens are saved in the iOS Keychain and never leave your device.
- **Conversations:** Message history, prompts, and tool results are stored locally. You can delete any thread or remove the app to erase the data.
- **File handling:** Attachments are processed in memory, optionally converted on device, then sent only to the service you asked us to use. We do not persist extra copies.

## What we send when you ask us to

- **OpenAI Responses API:** User prompts, optional file snippets, and tool arguments are sent to OpenAI to generate a reply. Nothing is sent automatically.
- **Computer Use bridge (optional):** When you approve an automation step, we stream the approved action, screenshot, and follow-up instructions to your trusted computer-use server on the local network.
- **MCP / Notion (optional):** If you connect external providers, the assistant forwards only the prompts and parameters needed for the action. Those services apply their own privacy policies.

## Device permissions we request

- **Photo library & Files:** Lets you attach screenshots, documents, and other files to a chat.
- **Calendars, Reminders, Contacts:** Enables the assistant to create or update items you explicitly authorize.
- **Local network:** Required to reach the computer-use bridge running on your network. No other local scanning occurs.

We do not request camera, microphone, speech recognition, or precise location access in the 1.0.0 release.

## Computer Use safety

- Every automation step is surfaced in a review UI before execution.
- You can reject any action; declining cancels the chain and nothing runs in the background.
- The app never executes commands without a visible audit trail in the chat.

## Analytics and crash data

- Optional, anonymous usage metrics can be enabled in Settings. They default to **off** and never include conversation content or credentials.
- Crash diagnostics come from Apple’s opt-in system reports; they contain no chat transcripts or API keys.

## Your choices

- Remove keys or disconnect integrations from Settings at any time.
- Delete individual conversations or clear all history from the conversation list.
- Uninstalling the app removes all local content and credentials.

Questions? File an issue at <https://github.com/Gunnarguy/OpenResponses/issues>. OpenResponses is open source (MIT licensed) so you can audit anything described here.
