# OpenResponses Privacy Summary

**Last updated:** April 23, 2026

OpenResponses runs entirely on your device until you decide to contact an external service. The app’s primary network traffic is to OpenAI when you send a live AI request, plus any optional services you explicitly enable, such as Notion.

## What stays on your device

- **API credentials:** Your OpenAI key and any optional integration tokens are saved in the iOS Keychain and never leave your device unless they are used to contact the service you configured.
- **Conversations:** Message history, prompts, and tool results are stored locally. You can delete any thread or remove the app to erase the data.
- **File handling:** Attachments are processed in memory, optionally converted on device, then sent only to the selected service. The app does not persist extra copies.

## In-app permission before data is sent

- Before the first live AI request, OpenResponses shows an in-app disclosure that explains what may be sent to **OpenAI** and asks for explicit permission.
- Nothing is sent to OpenAI until the user taps **Allow & Send**.
- Explore Demo remains offline and does not make OpenAI API calls.

## Data sent upon user request

- **OpenAI Responses API:** User prompts, optional attachments, and request-related tool inputs or outputs are sent to OpenAI to generate a reply. Nothing is sent automatically, and the app asks permission before the first live request.
- **Computer Use bridge (optional):** When you approve an automation step, the app streams the approved action, screenshot, and follow-up instructions to your trusted computer-use server on the local network.
- **Optional connected services:** If you enable integrations such as Notion, the assistant forwards only the prompts and parameters needed for the action you requested. Those services apply their own privacy policies.

## How data is used

- OpenAI receives request data solely to generate the assistant response or tool result you asked for.
- Optional connected providers receive only the request data needed to carry out the specific action you initiated.
- OpenResponses does not sell conversation data and does not use conversation content for advertising.

## Requested device permissions

- **Photo library & Files:** Lets you attach screenshots, documents, and other files to a chat.
- **Calendars, Reminders, Contacts:** Enables the assistant to create or update items you explicitly authorize.
- **Local network:** Required to reach the computer-use bridge running on your network. No other local scanning occurs.

The app does not request microphone, speech recognition, or precise location access in the 2.0 release.

## Computer Use safety

- Every automation step is surfaced in a review UI before execution.
- You can reject any action; declining cancels the chain and nothing runs in the background.
- The app never executes commands without a visible audit trail in the chat.

## Analytics and crash data

- Optional, anonymous usage metrics can be enabled in Settings. They default to **off** and never include conversation content or credentials.
- Crash diagnostics come from Apple’s opt-in system reports; they contain no chat transcripts or API keys.

## Retention, revocation, and deletion

- Remove keys or disconnect integrations from Settings at any time.
- Delete individual conversations or clear all history from the conversation list.
- Reset the first-send OpenAI consent prompt from Settings → General.
- Uninstalling the app removes all local content and credentials.

If you want data removed from an external provider, you must also follow that provider’s deletion process for any content already sent there.

Questions? File an issue at <https://github.com/Gunnarguy/OpenResponses/issues>. OpenResponses is open source (MIT licensed) so you can audit anything described here.
