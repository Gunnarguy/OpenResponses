# Current State

Updated: 2026-09-24
Branch/worktree: main in the repo root; origin at 32ca9d0. This file is committed locally after it and not pushed (a push starts another Xcode Cloud build).
Last verified commit: 32ca9d0 2.7: remove shut-down and deprecated OpenAI features; cover the current API

## Objective
OpenResponses 2.7 as a long-lived release: current OpenAI models (GPT-6 Sol/Astra/Luna, GPT Image 2.5, GPT-Live 1), every current endpoint and Responses parameter in scope, and nothing OpenAI has shut down or deprecated.

## Status
Ready for Gunnar to submit. ASC version 2.7 is PREPARE_FOR_SUBMISSION with build 47 selected (Xcode Cloud run 47 of 32ca9d0, VALID, usesNonExemptEncryption false, internal READY_FOR_BETA_TESTING). What's New, description, promotional text, keywords and review notes in ASC match fastlane/metadata (read back 2026-09-24). Build 47 TestFlight "What to Test" matches docs/releases/v2.7/TestFlightNotes.txt. Nothing was submitted for review.

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
Gunnar: in App Store Connect, open OpenResponses 2.7 (build 47 selected), optionally add a reviewer OpenAI API key to App Review notes, then Submit for Review.
