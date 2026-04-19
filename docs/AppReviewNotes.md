# App Review Notes – OpenResponses 1.0.1

**Last updated:** 2026-04-19

## Reviewer access

- No reviewer account is needed. On first launch you can either start **Explore Demo** (offline, no API calls) or paste an OpenAI API key (from the App Store Connect review note, if provided, or your own key).
- Once entered, the key is stored only in the iOS Keychain and never leaves the device.
- Usage is billed directly to the API key used for testing.
- The onboarding flow and chat composer both display an AI accuracy disclaimer reminding reviewers to double-check generated output.

### Reviewer key details

- Reviewer-key staging notes live in `AppStoreAssets/ReviewKeyInstructions.md`. If providing a reviewer key, copy it into the secure App Review note in App Store Connect.
- During QA, paste the reviewer key into Settings → Credentials and confirm you can remove it anytime using the **Delete Key** option.

## Primary review scenario (10 minutes)

1. Launch the app.
2. On the Welcome sheet, tap **Add API Key** and paste an OpenAI API key (from the App Review note if provided, or your own OpenAI API key).
3. In Settings → Model, select **GPT-5.4** or **GPT-4.1**.
4. Send "Hello! Can you help me test this app?" and verify the response streams, activity feed, and Assistant Thinking surface.
5. Open Settings → Tools and enable **Code Interpreter**.
6. Ask "Calculate the first 10 Fibonacci numbers." The assistant will execute the code tool and stream back the result.
7. Enable **Web Search** and ask "What happened in tech news today?"
8. Attach a PDF from the Files picker, or use **Take Photo** from the composer, to verify document and camera attachments.
9. Open the Request Inspector from the message menu to review the outbound request and tool trace.
10. (Optional) Enable Apple integrations and ask what is on today's calendar, what reminders are due today, or search for a contact.
11. (Optional) Open Settings → MCP → Connector Gallery to inspect connector and remote server setup paths, including Direct Notion Integration guidance.
12. (Optional) Toggle **Computer Use** back on in Settings → Tools. You will see a disclosure explaining the local network bridge requirement before the iOS prompt appears.

## Computer Use safety summary

- Computer Use is **off by default**. Enable it under Settings → Tools when you want to test it.
- Every action (navigate, click, type, screenshot) shows a confirmation sheet. Rejecting an action cancels the chain immediately.
- The app connects only to the user-approved local computer-use bridge (no background scanning).
- Enabling computer use shows a rationale dialog before iOS asks for local network access so reviewers know why the permission is requested.

## Data handling highlights

- API keys (OpenAI, Notion) are user-supplied and saved only in the iOS Keychain.
- Conversations and attachments remain on device unless the user explicitly uploads them to OpenAI or a connected tool.
- The app may request camera, photo/file, calendar, reminders, contacts, and local network permissions only when related features are used. It does not request microphone, speech recognition, or precise location permissions.
- Optional analytics are disabled by default and contain no conversation content.

## Support contact

- Email: [support@gunnarguy.com](mailto:support@gunnarguy.com) (monitored daily)
- Issues: <https://github.com/Gunnarguy/OpenResponses/issues>
- Computer-use bridge: Local computer-use bridge instructions live in `docs/computerusepreview/Documentation/computeruse.md`.
