# App Review notes — OpenResponses 2.6

**Prepared:** September 8, 2026. These are local reviewer instructions for the completed 2.6 source. [ASC status](releases/v2.6/ASCStatus.md) currently shows Prepare for Submission with no build selected. Apply these notes to the correct candidate after its build is uploaded and verified.

## Access and data sharing

OpenResponses is a developer client using a user-provided OpenAI API key; it does not require a separate OpenResponses login. **Explore Demo** runs offline without live API requests. Live testing requires an eligible key and bills usage to that API account. Supply any dedicated reviewer credential through the appropriate private App Store Connect review field, not a repository file, screenshot or public release note. The September 8 ASC inspection found no demo-account requirement and existing review notes; it did not establish that a working reviewer API key is currently provided.

The OpenAI key is stored in the iOS Keychain and sent to OpenAI to authenticate requests. Before the first live send, the app presents its data-sharing notice and requires **Allow & Send**. Selected prompts, attachments and tool results are transmitted for processing. Local conversation history and optional remote response/conversation storage are separate. Model/tool access depends on the API account.

## Core walkthrough

1. Launch and use Explore Demo to inspect the interface without a key.
2. For live review, add the privately supplied reviewer key or an authorized test key. Select a model available to that account; the current recommended catalog includes Astra and GPT-5.6 Sol/Terra/Luna.
3. Send a short greeting, verify the first-send disclosure, then allow the request. Observe streaming text, activity and usage. API-provided reasoning summaries appear only when the model/configuration returns them.
4. Send a follow-up, switch conversations and return. Existing chat history and presets should remain available.
5. Inspect the request/response details and export a test conversation that contains no private information.
6. Enable hosted Web Search and make a simple public-information request. Inspect the returned source/citation links.
7. Attach a small document. In a vector-store workflow, observe indexing until ready; upload success alone is not search readiness.
8. Open **Settings → Model → API Workbench**. Inspect a template and raw JSON response. The Workbench also exposes token counting, compaction, known-conversation inspection and background-response management.

## Voice

Open voice mode and grant microphone access when prompted. Speak, wait for the answer and speak again. The session supports continuing listening, mute and interruption. Test return to listening after output ends; actual acoustic behavior can depend on the audio route. Audio is sent to OpenAI's Realtime service. The app does request microphone access for this feature; old notes claiming otherwise are obsolete.

## Tools and browser behavior

Computer Use is opt-in. The current browser runs in an on-device WKWebView; it does not require a separate local-network browser bridge. DOM and screenshot actions share a serialized lane with deadlines and action/navigation limits. Stop or changing chats cancels pending work. API-provided safety checks pause the initiating turn and may be denied. The app does not display an independent confirmation for every navigate/click/type operation, and cancellation cannot reverse a website mutation already received by the server.

Remote MCP configuration and discovery are available. This path uses OpenAI-hosted MCP: the configured endpoint and authentication material may be sent to OpenAI so it can connect. It is separate from the local WebKit browser. Private OAuth servers may require their own account setup; the public discovery test does not validate every connector.

Apple Calendar, Reminders and Contacts, and Notion tools are optional. Related permissions and credentials are needed for those integrations. Avoid writing to real personal data unless the reviewer intends that action. Camera/photos/files access is used for the corresponding attachment flows; voice uses the microphone.

## Developer labs and legacy migration

Batch output/error exports save complete available files through the system share sheet. Fine-tuning imports reviewed text-chat JSONL and validates examples and parameters. It explains restricted/winding-down service availability; a valid dataset does not guarantee account admission. Exporting a conversation creates a draft, not an automatically trainable dataset. Paid jobs are not necessary to inspect those validation/export screens.

Legacy Migration retains local Assistant JSON import into Responses presets. Live retired Assistants/Threads/Runs operations are disabled. Workbench templates for arbitrary tools do not execute arbitrary shell or patch commands on the iPhone; client-tool calls require an implemented handler or explicit real results supplied in the Workbench.

## Submission notes

Use the [release checklist](AppStoreReleasePlan.md) and [validation ledger](releases/v2.6/Validation.md). Local tests and device launch do not establish that the selected ASC binary contains these changes. Current uploaded build 38 maps to the earlier committed source and reports missing export compliance. Verify the replacement candidate, reviewer API access, current screenshots and privacy disclosures before submission.

Support: [repository issues](https://github.com/Gunnarguy/OpenResponses/issues). Preserve the existing App Store Connect contact fields; this documentation task does not change reviewer contacts or publish metadata.
