# App Review Notes – OpenResponses 1.0.0

**Last updated:** 2025-11-11

## Reviewer access

- No reviewer account is needed. The app runs entirely with the reviewer’s OpenAI API key.
- On first launch the app prompts for the key; it is stored only in the iOS Keychain and never leaves the device.

## Primary review scenario (10 minutes)

1. Launch the app.
2. When prompted, enter an OpenAI API key (e.g., a limited-scope test key).
3. Send “Hello! Can you help me test this app?” and verify the response streams.
4. Open Settings → Tools and enable **Code Interpreter**.
5. Ask “Calculate the first 10 Fibonacci numbers.” The assistant will execute the code tool and stream back the result.
6. (Optional) Attach a PDF or image from the Files picker to see file handling in action.

## Computer Use safety summary

- Computer Use is **off by default**. Enable it under Settings → Tools when you want to test it.
- Every action (navigate, click, type, screenshot) shows a confirmation sheet. Rejecting an action cancels the chain immediately.
- The app connects only to the user-approved local computer-use bridge (no background scanning).

## Data handling highlights

- API keys (OpenAI, MCP, Notion) are user-supplied and saved only in the iOS Keychain.
- Conversations and attachments remain on device unless the user explicitly uploads them to OpenAI or an MCP tool.
- We do not request camera, microphone, speech recognition, or precise location permissions in this release.
- Optional analytics are disabled by default and contain no conversation content.

## Support contact

- Email: [support@gunnarguy.com](mailto:support@gunnarguy.com) (monitored daily)
- Issues: <https://github.com/Gunnarguy/OpenResponses/issues>
