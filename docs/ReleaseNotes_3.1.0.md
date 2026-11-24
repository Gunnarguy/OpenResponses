# OpenResponses 3.1 release notes

| Platform | Build | Review submission | State (App Store Connect, read 2026-11-23 and 2026-11-24 02:02 UTC) |
| --- | --- | --- | --- |
| iPhone and iPad | 57, Xcode Cloud run 57 of commit `3c59e7f` | 639883b0, submitted 2026-11-22 17:27 PST, with the OpenResponses Pro In-App Purchase | Live: `READY_FOR_SALE`, approved 2026-11-23 |
| Mac (native macOS, the first Mac version) | 60, archived and uploaded from this Mac with the `NSColor.systemGray` fix (`9f751f9`) | e526d156, replaced 199c4543 (build 59) on 2026-11-22 | Live: `READY_FOR_SALE`, approved 2026-11-23 |
| OpenResponses Pro (In-App Purchase 6838132013) | | reviewed with iOS 3.1 | `APPROVED` |

The work was pushed to `main` on 2026-11-20 with `[ci skip]` on the head commit while 3.0 was in review, and 3.1 became the marketing version on 2026-11-22, after 3.0 went live on November 20. The App Store What's New text is [release_notes.txt](../fastlane/metadata/en-US/release_notes.txt). The details and their tests are in [CHANGELOG.md](../CHANGELOG.md) under 3.1. Shortcuts, the share sheet and the Mac are described in [share-shortcuts-mac.md](share-shortcuts-mac.md), and Pro in [pro-purchase.md](pro-purchase.md).

## OpenResponses Pro

| What | Detail |
| --- | --- |
| Product | `Gunndamental.OpenResponses.pro`, non-consumable, USD 4.99, one purchase for iPhone, iPad and Mac (one bundle ID) |
| Unlocks | Shortcuts and Siri, the share sheet, and the 12-hour prompt cache lifetime: the three 3.1 features that work outside the chat |
| Stays free | Everything in 2.9 and 3.0, the new models, the fixes and the Mac app. The app stays bring-your-own-key |
| Where | Settings → OpenResponses Pro, with Buy and Restore Purchases (`ProPaywallView`) |
| How it decides | StoreKit 2 current entitlements (`ProStore`); a refunded or revoked purchase locks again. The app records the state in the App Group so the share extension can read it (`ProAccess`) |
| When locked | Ask OpenResponses answers with how to unlock it, New Chat opens the app on the Pro sheet, the share sheet shows a Pro message with Close, Request Options lists "12 hours (Pro)" with a lock |

## Outside the chat

| Feature | What it does |
| --- | --- |
| Ask OpenResponses (Shortcuts, Siri, Spotlight, the Action button) | Sends a question with a saved preset (or the current settings) and an optional image, PDF or text file, and returns the answer as text without opening the app. Same Allow & Send consent as the chat; the tools the app runs itself are off |
| New Chat in OpenResponses | Opens a new chat with the text in the message field and the files attached, unsent |
| Share sheet (`OpenResponsesShare`) | Text, a web link, up to 10 images and up to 10 files, plus a question; Save puts it in `SharedInbox` in App Group `group.Gunndamental.OpenResponses`, and the app opens it as an unsent new chat. Nothing is sent from the sheet |

## Mac

A native macOS app (not Mac Catalyst) built from the same sources on the same bundle ID, macOS 14 or later, Apple silicon and Intel. A sidebar of conversations beside the chat, a Settings window laid out like System Settings, Open and Save panels, the system Share menu. The camera, Text Size, haptics and the share extension stay off the Mac. Live since 2026-11-23.

## GPT-6.2 and the API

| Change | Detail |
| --- | --- |
| Models | GPT-6.2 Sol is the default for new presets; GPT-6.2 Astra and GPT-6.1 Terra are in every model menu. GPT-6.2 offers reasoning effort low through max, Terra none through max. Existing presets keep their model |
| Instructions on GPT-6.2 | Sent as a developer message, the first input item, so the API can cache it; a chained turn doesn't send it again (`InstructionsLedger`) |
| Service tiers | Request Options lists only the model's tiers (no Flex on GPT-6.2; Ultrafast on GPT-6.2 Astra and Sol, GPT-6 Astra and GPT-6.1 Sol). A saved tier the model lacks is left out of the request |
| Prompt cache lifetime | 30 minutes or 12 hours (`prompt_cache_options.ttl`) on GPT-5.6 and later; the 12-hour option needs Pro |
| Blocked domains | Sent as `filters.blocked_domains`, up to 100 entries |
| Retired models | Presets move to the replacements on OpenAI's deprecations page |
| Misalignment stops | Shown in the chat and not retried |

## Fixes

- Web search sources whose page embeds an `about:srcdoc` or `data:` frame load instead of showing "Navigation blocked".
- Connectors: a service with a signed-in account leaves the Popular and registry lists; an old Notion integration token next to a signed-in Notion account offers Remove Token.
- Mac: `NSColor.systemGray` no longer calls itself (build 59 overflowed the stack in the Model Compatibility view and image placeholders; build 60 has the fix).

## Verification

- Unit tests on simulator 54DDDEDE (iOS 27.0), 2026-11-22: 409 tests, 2 skipped, 0 failures; `bash scripts/ui_tests.sh`: 7 tests, 0 failures.
- GitHub CI on `88baac2`, run 45250471857, 2026-11-23: all 4 jobs succeeded, 408 tests, 4 skipped (environment only), 0 failures, with the Pro purchase test passing in 2.540 s.
- Xcode Cloud run 57 signed the App Group and the share extension (build 57 `VALID`). Xcode Cloud's "Mac Release" workflow archived and signed the Mac app in test run 58 and failed only at upload on a duplicate build number.

Not verified: a production Pro purchase on a device, the share sheet and Shortcuts on the App Store build, and the GPT-6.2 instruction placement, Flex gating and blocked-domain filter against the live API (Notion roadmap Verification rows for v3.1). On the Mac: a live chat with a real key, computer use and voice.
