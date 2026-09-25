# OpenResponses 2.7 release notes

Prepared September 24, 2026. The App Store What's New text is [release_notes.txt](../fastlane/metadata/en-US/release_notes.txt); the full list of changes is in the [changelog](../CHANGELOG.md#27--prepared-september-24-2026).

## Models

| Model | Reasoning effort | Price per 1M tokens (input / output) | Role in the app |
| --- | --- | --- | --- |
| `gpt-6-sol` | none, low, medium (default), high, xhigh, max | $2 / $10 | Default for new presets and the Workbench |
| `gpt-6-astra` | low, medium, high, xhigh, max | $10 / $50 | Pro reasoning mode, async tool calls |
| `gpt-6-luna` | none, low, medium (default), high, xhigh, max | $0.10 / $0.50 | MCP tool discovery |
| `gpt-image-2.5-flare` | quality auto, low, medium, high, xhigh, max | $5 text in / $30 image out | Default image model |
| `gpt-image-2.5-sunburst` | quality auto, low, medium, high, xhigh, max | $5 text in / $30 image out | Selectable |

Source: OpenAI model pages and changelog, fetched September 24, 2026. Prices are OpenAI's list prices and are billed to the user's own API account.

## Retirements the app now accounts for

| Retirement | Shutdown | App behavior |
| --- | --- | --- |
| `gpt-5`, `gpt-5-mini`, `gpt-5-nano`, `o3` snapshots | December 11, 2026 | Left out of the offline list |
| `gpt-realtime`, `gpt-realtime-mini` | January 20, 2027 | Saved voice setting moves to `gpt-realtime-2.1` |
| `whisper-1`, `gpt-4o-transcribe`, `gpt-4o-mini-transcribe` | February 26, 2027 | Not used; voice transcription already uses `gpt-live-transcribe` |
| Reusable prompts API (`v1/prompts`) | November 30, 2026 | Published-prompt fields remain; requests using them will fail after shutdown |
| Fine-tuning job creation for most organizations | January 6, 2027 | The fine-tuning lab already explains restricted availability |

## Forward compatibility

Later general-purpose GPT releases are recognized by version number, so a model such as `gpt-6.1-sol` appears in the model list with current reasoning and tool controls once the account's model list includes it. Reasoning effort follows the GPT-6 pattern: every level for most models, and no `none` for Astra-class models. If a future model rejects a setting, the API returns an error message naming it, and the model ID field and API Workbench remain available.
