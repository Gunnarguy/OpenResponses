# OpenResponses 2.8 release notes

Prepared September 29, 2026. The App Store What's New text is [release_notes.txt](../fastlane/metadata/en-US/release_notes.txt), written to match the OpenIntelligence and OpenManual listings; the full list of changes is in the [changelog](../CHANGELOG.md). Model facts were checked against OpenAI's model pages, GPT-6 guide, reasoning guide and async tool calling guide on September 29, 2026.

## Models

| Model | Reasoning effort | Pro mode | Async tool calls | Role in the app |
| --- | --- | --- | --- | --- |
| `gpt-6.1-sol` (new) | low, medium (default), high, xhigh, max | yes | yes | Top of the model menus |
| `gpt-6-sol` | none, low, medium (default), high, xhigh, max | yes (new in 2.8) | no | Default for new presets |
| `gpt-6-astra` | low, medium, high, xhigh, max | yes | yes | |
| `gpt-6-luna` | none, low, medium (default), high, xhigh, max | yes (new in 2.8) | no | MCP tool discovery |
| `gpt-5.6-sol`, `-terra`, `-luna` | none, low, medium (default), high, xhigh, max | yes | no | Previous generation |

These rows live in [ModelCatalog.json](../OpenResponses/Resources/ModelCatalog/ModelCatalog.json). A model OpenAI adds after this release appears in the menus from the account's model list, with reasoning efforts read from its docs page ([model-catalog.md](model-catalog.md)).

## New

- Local Python: Pyodide 314.0.7 bundled, run only after the user approves each run in a sheet that shows the code; standard library, no network, no files, 30 seconds.
- Search conversations by meaning with Apple's on-device sentence embeddings, falling back to word matching.
- MCP sign-in through https://gunzino.me/openresponses/oauth/callback.html for providers that refuse the app's own callback.
- A GET /models `shutdown_date` within 30 days retires a model and moves presets to its replacement.

## Fixed

- GPT-Live 1 pauses when the caller talks over it (headphones or Bluetooth, Voice Barge-In on), resumes after a backchannel, and drops queued audio otherwise.
- Settings → Model → Voice stays open.
- Model menus list the account's newer models; 2.7 listed them only in Settings → Model.

## Accessibility

4.5:1 text contrast, VoiceOver labels and 44-point targets on the chat, Settings and Conversations screens, checked by UI audit tests; the message bar fits the screen at the largest text sizes.

## Store listing

Description, What's New and promotional text were rewritten in the first-person, measured voice of the OpenIntelligence and OpenManual listings. Keywords swap `JSON` for `python`. Marketing, support and privacy links move to https://gunzino.me/openresponses/, like the other apps; the privacy policy there lists the automatic requests 2.8 makes.
