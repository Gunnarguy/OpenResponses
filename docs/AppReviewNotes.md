# App Review Notes – OpenResponses 1.0.0

**Last updated:** 2025-11-14

## Reviewer access

- No reviewer account is needed. On first launch you can either start **Explore Demo** (offline, no API calls) or paste the limited-scope OpenAI API key from the App Store Connect review note (or your own key).
- Once entered, the key is stored only in the iOS Keychain and never leaves the device.
- Usage is billed directly to that limited-scope key. It has a low credit ceiling, so keep requests short.
- The onboarding flow and chat composer both display an AI accuracy disclaimer reminding reviewers to double-check generated output.

### Reviewer key details

- The placeholder value lives in `AppStoreAssets/ReviewKeyInstructions.md`. Replace it right before submitting to App Store Connect, and copy the finalized value into the secure App Review note.
- During QA, paste the reviewer key into Settings → Credentials and confirm you can remove it anytime using the **Delete Key** option.

## Primary review scenario (10 minutes)

1. Launch the app.
2. On the Welcome sheet, tap **Add API Key** and paste the limited-scope reviewer key from the App Review note (or your own OpenAI API key).
3. Send “Hello! Can you help me test this app?” and verify the response streams.
4. Open Settings → Tools and enable **Code Interpreter**.
5. Ask “Calculate the first 10 Fibonacci numbers.” The assistant will execute the code tool and stream back the result.
6. (Optional) Attach a PDF or image from the Files picker to see file handling in action.
7. (Optional) Toggle **Computer Use** back on in Settings → Tools. You will see a disclosure explaining the local network bridge requirement before the iOS prompt appears.

## Computer Use safety summary

- Computer Use is **off by default**. Enable it under Settings → Tools when you want to test it.
- Every action (navigate, click, type, screenshot) shows a confirmation sheet. Rejecting an action cancels the chain immediately.
- The app connects only to the user-approved local computer-use bridge (no background scanning).
- Enabling computer use shows a rationale dialog before iOS asks for local network access so reviewers know why the permission is requested.

## Data handling highlights

- API keys (OpenAI, MCP, Notion) are user-supplied and saved only in the iOS Keychain.
- Conversations and attachments remain on device unless the user explicitly uploads them to OpenAI or an MCP tool.
- We do not request camera, microphone, speech recognition, or precise location permissions in this release.
- Optional analytics are disabled by default and contain no conversation content.

## Support contact

- Email: [support@gunnarguy.com](mailto:support@gunnarguy.com) (monitored daily)
- Issues: <https://github.com/Gunnarguy/OpenResponses/issues>
- Demo bridge & assets: Local computer-use bridge instructions live in `docs/computerusepreview/Documentation/computeruse.md` along with sample files included in the repo under `AppStoreAssets/DemoFiles/`.
