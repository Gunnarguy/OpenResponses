# Current State

Updated: 2026-09-25
Branch/worktree: main in the repo root; origin at 32ca9d0. This file is committed locally after it and not pushed (a push starts another Xcode Cloud build).
Last verified commit: ebdadaa docs: 2.7 submitted for review

## Objective
OpenResponses 2.7 as a long-lived release: current OpenAI models (GPT-6 Sol/Astra/Luna, GPT Image 2.5, GPT-Live 1), every current endpoint and Responses parameter in scope, and nothing OpenAI has shut down or deprecated.

## Status
Released 2026-09-25.  App Store Connect reported version 2.7 appStoreState READY_FOR_SALE / appVersionState READY_FOR_DISTRIBUTION at 11:11 PDT (its API had still said IN_REVIEW at 11:06, after Gunnar already saw the approval), build 47.  The public lookup (itunes.apple.com/lookup?id=6757338355) still returned 2.6 at 11:11; storefront propagation follows.  Post Desk: the `sw:after27` flag was set to 2026-09-25 in the artifact db, which unlocks the six OpenResponses 2.7 posts.

## Completed
- 9dd8e1d: GPT-6 Sol/Luna, GPT Image 2.5, version-aware model recognition, MARKETING_VERSION 2.7, four Xcode 27 warnings.
- 32ca9d0: removed Assistants, fine-tuning, published prompts, preview tools, the computer-use-preview path, invalid/deprecated request fields (user, prompt_cache_retention, modalities/audio, include_usage, computer_call_output.output, input_audio) and retired-model capability entries; added GPT-Live 1 (wss /v1/live/sessions), Responses moderation and new tool options, Workbench endpoints with DELETE confirmation, voice-note transcription with gpt-transcribe; fixed snapshot-only capability inheritance, gpt-4o-mini, blocked domains with custom instructions, retired-model migration order. Full list in CHANGELOG.md 2.7.
- An adversarial review of the pass found 17 items; all defects were fixed or answered from the downloaded Live reference before commit.

## Active Constraints
- Saved presets decode with synthesized Codable via try?; never add a non-optional Prompt property. New options go in ModernResponseOptions (tolerant decoder).
- Every push to main starts an Xcode Cloud archive; bump MARKETING_VERSION after each release. No attribution trailers. Wrap git in gtimeout 60. DerivedData outside iCloud.
- API facts come from OpenAI's Markdown reference (https://developers.openai.com/api/reference/llms.txt, resource pages as .md), fetched 2026-09-24. No OpenAI key on this Mac.
- Compare live ASC fields with the last committed copy before PATCHing (skip hand edits).
- Use the dedicated simulator "OpenResponses tests" (CC71613C-046E-4386-B24E-9512FD114884, iPhone 18 Pro, iOS 27.0); simulators are shared across sessions.

## Verification
- `xcodebuild test -project OpenResponses.xcodeproj -scheme OpenResponses -destination "platform=iOS Simulator,id=CC71613C-046E-4386-B24E-9512FD114884" -only-testing:OpenResponsesTests -parallel-testing-enabled NO -derivedDataPath <scratchpad>/DD27 CODE_SIGNING_ALLOWED=NO` (Xcode 27.0 27A266a) on 32ca9d0 -> `Executed 297 tests, with 0 failures`, `** TEST SUCCEEDED **`; no warnings in app sources.
- Xcode Cloud run 47 (32ca9d0): SUCCEEDED; build 47 VALID, uploaded 2026-09-24 19:15 PDT.
- GitHub CI run 36085257026 (32ca9d0): see git log / gh run view; recorded in the final session message.
- `python3 scripts/secret_scan.py` passed; `git diff --check` clean.

## Blockers / Unknowns
- GPT-Live 1, voice-note transcription and the new Responses fields are verified against the reference and unit tests only; no live request was possible without a key.
- Live has no speech-started event, so locally buffered assistant audio keeps playing briefly when the user interrupts; transcripts are split into turns when the speaker changes.
- `OpenResponses/Resources/Localization/Localizable 2.xcstrings` is an old tracked iCloud conflict copy (since f679fa5); it builds as an unused table. Remove in a later commit if wanted.
- The Notion token in test.env was printed into this session's log; Gunnar should rotate it.

## Exact Next Action
Before any further push to main, set MARKETING_VERSION to 2.8 in OpenResponses.xcodeproj/project.pbxproj (two lines): a push still declaring 2.7 fails in Xcode Cloud at "Preparing build for App Store Connect", as runs 42 to 45 did for 2.6.  The local commits after ebdadaa (this file and the CHANGELOG approval line) are unpushed for that reason.
