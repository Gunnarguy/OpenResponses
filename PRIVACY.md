# Privacy Policy

Last updated: 2026-09-08 (v2.6 implementation clarification)

OpenResponses is a native iOS client for the OpenAI Responses API, built with a local-first design philosophy. We believe that your data belongs on your device. This Privacy Policy details what information is collected, what data stays local, what data is transmitted over the network, and how you retain complete control over your credentials and chat histories.

---

## 1. Plain-Language Privacy Summary

- **Provider connections:** The app contacts configured API providers directly rather than a developer-operated proxy. OpenAI-hosted tools may contact other services; hosted MCP can receive the configured server credentials so OpenAI can authenticate to that server.
- **No Third-Party Analytics SDKs:** The application does not integrate tracking frameworks (such as Firebase, Mixpanel, Amplitude, or Google Analytics). Your usage behavior is private and stays on your device.
- **You Own Your Keys:** Your API keys and integration tokens are stored locally on your device in the secure iOS Keychain. The app transmits credentials to the relevant service when required for authentication.

---

## 2. On-Device Storage (What Stays Local)

The following information is persisted within the app’s local sandboxed directory or iOS Keychain:
1. **API Keys & Credentials:** The application saves OpenAI keys, existing Notion integration credentials, and MCP account authorization inside the iOS Keychain using generic-password `SecItem` storage. MCP OAuth access/refresh tokens, installation-specific registration details and account metadata use an atomic device-only Keychain record. The Workbench also saves request drafts in Keychain because raw request text can contain sensitive information.
2. **Conversation History:** Saved prompts, active chat threads, model settings presets, and execution statistics reside in the local directory as JSON files via `ConversationStorageService`. Optional OpenAI storage is separate from these local files. Device backup behavior is governed by your operating-system settings.
3. **Diagnostic Traces:** App logs and request/event inspection are local diagnostic surfaces. Raw exports can include conversation or tool data; review them before sharing. Targeted redaction does not make every possible diagnostic export public-safe.
4. **Security-Scoped Bookmarks:** When you import files or folders for processing, Apple generates security-scoped bookmarks stored on-device to retain access permissions across launches.

---

## 3. Data Sent Off-Device (Network API Boundaries)

To execute live requests and tools, the app uses HTTPS or secure WebSockets. Demo Mode does not send live API requests.

| Recipient / path | Data and purpose | Controls / boundaries |
| --- | --- | --- |
| OpenAI Responses and related APIs | API authentication, messages/instructions, selected attachments, tool definitions/results, response metadata and requested job/dataset content. | First-live-send disclosure, selected tools and request settings. Optional remote storage is separate from local history. |
| OpenAI Realtime / transcription | Authentication and captured audio for voice/transcription, with returned audio/text. | Microphone permission, voice-session controls and mute. |
| Provider account sign-in | The provider handles login and consent in the system browser. OpenResponses exchanges the authorization code and verifier with the provider and stores the resulting account credentials in Keychain. Refresh contacts that provider again. | Explicit Connect / Sign In Again; provider setup and access requirements apply. |
| MCP Registry search | The text entered for an explicit live search goes to the public MCP Registry. Account credentials and chat history are not part of this search. | Search the MCP Registry; leaving Demo Mode is explicit. |
| OpenAI-hosted MCP | Configured endpoint, tool restrictions and server authentication when supplied; server tool results can become response context. | Explicit server configuration and applicable approvals; private OAuth depends on the server/account. |
| Notion and configured third-party handlers | Authentication and the data needed for enabled reads/writes. | User configuration, service permissions and enabled tools. |
| Apple Calendar, Reminders and Contacts | Authorized local framework access; information returned by enabled tools may be sent to the model for the requested task. | System permissions and integration/tool controls. |
| Browser websites / OpenAI browser context | On-device WKWebView requests go to visited sites; page content/screenshots and action results may be sent to OpenAI as tool context. | Opt-in tools, Stop, execution limits and API-provided safety decisions. No separate local-network bridge is required. |

The current file-search path uses uploaded files/vector stores; this document does not promise an on-device embedding service or a File Search toggle that controls all possible remote retention.

---

## 4. Document & File Uploads

When you attach files (PDF, TXT, PNG, etc.) to the chat:
- The app uses `FileConverterService` to extract plaintext or render images locally.
- Extracted content and image buffers are sent as part of the API payload request to the OpenAI Responses API.
- File/vector-store, Batch and fine-tuning workflows can upload selected files or datasets to their configured API service. Enabled tools may also transmit content to the configured destination. A completed upload and completed vector-store indexing are different states.

---

## 5. App Store Privacy Declarations

The submission’s privacy answers must match the actual candidate and provider data flow above. The September 8 read-only App Store Connect check verified versions, builds, localizations and retained Cloud records; it did not verify the current privacy questionnaire. Earlier categorical answers on this page are not evidence of the live ASC form. See the [release plan](docs/AppStoreReleasePlan.md).

## 6. Deletion, reset and remote storage

**Reset Prompt Settings restores the active prompt/settings defaults. It does not erase all Keychain entries, conversation files, remote objects or website data.** This follows `SettingsHomeView` calling `ChatViewModel.resetToDefaultPrompt()`.

Use the app’s corresponding conversation deletion, credential editing/removal and remote-resource controls for those resources. Removing local history or resetting preferences does not revoke a provider credential or prove that a remote object has been deleted. Revoke credentials with the provider when needed.

Turning off **Store on OpenAI / Store Responses** controls supported future request storage behavior; it does not retroactively delete previous server objects or override provider retention obligations/settings. Background responses require supported server storage. Local settings reset is not a universal data-erasure command.

For the current feature/data boundaries, see the [2.6 technical record](docs/releases/v2.6/TechnicalChanges.md) and [upgrade guide](docs/releases/v2.6/UpgradeGuide.md).

For MCP accounts, switching off Use in this chat preserves the account login. Disconnect removes the local account record; revoking the provider’s consent grant requires the provider’s connected-app settings. See [MCP connection details](docs/mcp-connections.md).
