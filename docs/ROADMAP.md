# OpenResponses roadmap reference

> **Historical record (2.6 era).** This page describes the 2.5 to 2.6 release as of September 2026 and is kept for its evidence. The current release is 3.1 (iPhone and iPad live November 23, 2026; Mac in App Review): see [CHANGELOG.md](../CHANGELOG.md), [README.md](../README.md) and [docs/ai/STATE.md](ai/STATE.md).

**Updated:** September 8, 2026. The [root roadmap](../ROADMAP.md) is the current roadmap. The [2.6 release dossier](releases/v2.6/README.md) is the detailed implementation/release record, and the [release plan](AppStoreReleasePlan.md) tracks delivery gates.

The earlier phase tables on this page are superseded. In particular:

- Native async/custom/programmatic and multi-agent chat orchestration is now implemented for its supported foreground path.
- Voice and MCP discovery are implemented; they are not out-of-scope future features.
- Remote conversation hydration is limited to known IDs; there is no account-wide conversation-list operation.
- Browser automation uses an on-device WKWebView with a shared execution coordinator; a separate local bridge is not required.
- Live Assistants operations and the retained-export migration were removed in 2.7.
- Fine-tuning was removed in 2.7: OpenAI deprecated self-serve job creation, which ends for existing customers January 6, 2027.
- Local source/test completion does not mean the update is in TestFlight or the App Store. See the [live ASC snapshot](releases/v2.6/ASCStatus.md).

For the full 2.5→2.6 chronology, use the [changelog](../CHANGELOG.md) and [source inventory](releases/v2.6/SourceInventory.md). Earlier revisions of this roadmap remain in Git history.
