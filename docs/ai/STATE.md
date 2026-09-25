# Current State

Updated: 2026-09-24
Branch/worktree: main in the repo root, level with origin at 9dd8e1d when written; this file is committed locally after it.
Last verified commit: 9dd8e1d 2.7: GPT-6 Sol and Luna, GPT Image 2.5, and version-aware model recognition

## Objective
Ship OpenResponses 2.7 as a long-lived release: support GPT-6 Sol and Luna and GPT Image 2.5, recognize later general-purpose GPT releases without an app update, account for announced OpenAI retirements, and get a valid 2.7 build into App Store Connect.

## Status
Ready for Gunnar to submit. ASC version 2.7 is PREPARE_FOR_SUBMISSION with build 46 selected (Xcode Cloud run 46 of 9dd8e1d, VALID, usesNonExemptEncryption false). What's New, description, promotional text, keywords and review notes in ASC match `fastlane/metadata` (read back 2026-09-24). TestFlight "What to Test" for build 46 matches `docs/releases/v2.7/TestFlightNotes.txt`. Nothing was submitted for review.

## Completed
- Catalog (`OpenResponses/Core/Models/CurrentModelCatalog.swift`): version parsing of `gpt-<major>[.<minor>][-variant]`; GPT-5.6+ general models are modern, specialized variants are not; default `gpt-6-sol`; image default `gpt-image-2.5-flare`; `xhigh`/`max` quality only for Image 2.5 and normalized per request; realtime migration to `gpt-realtime-2.1`; MCP discovery on `gpt-6-luna`; offline list drops models shutting down 2026-12-11.
- Four Xcode Cloud warnings fixed (three ineffective `[weak self]`, one main-actor formatter). MARKETING_VERSION 2.7.
- CI skips `BrowserLiveSiteTests` (network flake). Store copy and docs: CHANGELOG 2.7, `docs/ReleaseNotes_2.7.0.md`, README, APP_STORE.md, paste sheet.
- iCloud conflict refs `.git/refs/heads/main 2` and `.git/refs/tags/v2.6.0 2` (both redundant) were moved to the session scratchpad; they had broken `git fetch`.

## Active Constraints
- Every push to main starts an Xcode Cloud archive (build number = run number). Do not push docs-only commits without Gunnar's go-ahead.
- Bump MARKETING_VERSION after each release before the next push; a released version's train rejects uploads ("Preparing build for App Store Connect failed").
- GitHub CI stays on macos-26 + Xcode 26.6 (no Xcode 27 on hosted runners as of image 20260907); Xcode Cloud archives with "Latest Release" = Xcode 27.
- `.claude/` is untracked local settings. No attribution trailers. DerivedData outside iCloud; wrap git in `gtimeout 60`.
- Model facts come from developers.openai.com (fetched 2026-09-24). No OpenAI key exists on this Mac; `test.env` holds a Notion token only.

## Verification
- Local: `xcodebuild test -project OpenResponses.xcodeproj -scheme OpenResponses -destination "platform=iOS Simulator,id=CC71613C-046E-4386-B24E-9512FD114884" -only-testing:OpenResponsesTests -parallel-testing-enabled NO -derivedDataPath <scratchpad>/DD27 -resultBundlePath <scratchpad>/Test27.xcresult CODE_SIGNING_ALLOWED=NO` (Xcode 27.0 27A266a, dedicated simulator "OpenResponses tests", iPhone 18 Pro, iOS 27.0) -> `Executed 298 tests, with 0 failures`, `** TEST SUCCEEDED **`; zero warnings in app sources.
- Xcode Cloud run 46 (commit 9dd8e1d): COMPLETE SUCCEEDED; build 46 VALID, uploaded 2026-09-24 18:01 PDT, internal READY_FOR_BETA_TESTING.
- GitHub CI run 36079930935 (commit 9dd8e1d, macos-26, Xcode 26.6): all four jobs green; `Executed 297 tests, with 0 failures`, `** TEST SUCCEEDED **` (298 minus the skipped BrowserLiveSiteTests case).
- `python3 scripts/secret_scan.py` -> passed; `git diff --check` clean.

## Blockers / Unknowns
- Xcode 27 still emits 52 isolated deinits under default MainActor isolation. The iOS 26.2 simulator runtime aborted on them only under synchronous XCTest (swiftlang/swift#87316); no production crash has been observed. Mitigation if ever needed: explicit `nonisolated deinit {}` on the affected classes.
- Published prompts (`v1/prompts`) shut down 2026-11-30; presets with that toggle on will get an API error after that date until it is turned off.
- The Notion token in `test.env` was printed into the 2026-09-24 session log; Gunnar should rotate it.

## Exact Next Action
Gunnar: in App Store Connect, open OpenResponses 2.7, optionally add a reviewer OpenAI API key to App Review notes, then Submit for Review.
