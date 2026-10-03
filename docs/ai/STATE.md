# Current State

Updated: 2026-10-01
Branch/worktree: main in the repo root; pushed with the 2.9 fixes on 2026-10-01, and Xcode Cloud archives that push for App Review.
Last verified commit: the 2.9 tool-steps commit that carries this handoff (parent ce20b29)

## Objective
2026-10-02: 2.9 is live, READY_FOR_SALE with build 54 (`release.py status`; the App Store lookup's release time is 2026-10-02T16:24:23Z), and the README says so.  The release-day places under Active Constraints (gunzino.me, gunnarguy.me, the profile README, Notion) still read 2.8.  What follows is as of the submission.

2.9 was in App Review: resubmitted 2026-10-01 14:33 PDT with three App Store previews (submission `a4928014-ecb3-4a57-a7eb-24cd2eba5032`, build 54 from Xcode Cloud run 54 on baff2fc, version `9343d705-a4ce-481c-9459-92ee7b1035f4`, release after approval).  The first submission (11:41, `e52a229a-...`) was pulled at the owner's word to add the previews.  The previews (chart, browser, thinker, in the 6.5" iPhone set, posters at 00:00:00:24) are the Apple-encoder cuts from `~/Movies/App demos/OpenResponses/App Store/`: the first x264 uploads sat in PROCESSING for 80 minutes, so `scripts/asc/previews.py clear` deleted them and they were uploaded again at 14:07.  App Store Connect took the submission while the new ones were still processing.  Check them with `previews.py state`. What's New and promotional text match `fastlane/metadata/en-US`.

## Status
- 2.8 released 2026-09-30 (build 51, Xcode Cloud run 51 from ab87186). Submitted 2026-09-29 about 21:28 PDT (review submission 5e3d5bf0-cff5-4f69-9019-05599a734175) and approved on the first submission with Local Python in it; App Store Connect showed READY_FOR_SALE. Contents: CHANGELOG.md "2.8", docs/ReleaseNotes_2.8.0.md.
- Release day, 2026-09-30:
  - gunzino.me OpenResponses page to v2.8 with a 2.8 What's new section, support page names GPT-6.1 Sol (Gunzino 5e5cf19); version history there comes from gunnarguy.me's releases.json and already had 2.8.
  - gunnarguy.me project page: "Version 2.8 (September 2026)" paragraph (Gunnarguy-Portfolio d8327d6, rebased over two bot commits that touched only OpenIntelligence files).
  - GitHub profile README: OpenResponses line says 2.8 (Gunnarguy 37d48d2).
  - Notion: v2.9 option added; App Store on every v2.8 row; the six 2.8 feature rows Completed on 2026-09-30; "2.8 released (build 51)" Release row; the device checks moved to v2.9 with a new row "Live-check the 2.8 features on a device"; the "2.8 phone checklist" page has a note on top.
  - This repo: MARKETING_VERSION 2.9; CHANGELOG "2.8 — released September 30, 2026 (build 51)" and a "2.9 — in development" section; the Computer Use warning in SettingsHomeView.swift no longer claims it "can control apps" (it drives only the app's own off-screen browser).
- Store listing (fastlane/metadata/en-US, identical to App Store Connect): written in the voice of the OpenIntelligence and OpenManual listings; links at gunzino.me/openresponses/.

## Active Constraints
- Saved presets decode with synthesized Codable via try?; never add a non-optional Prompt property. New options go in ModernResponseOptions (tolerant decoder).
- Every push to main starts an Xcode Cloud archive and GitHub CI; avoid docs-only pushes. Bump MARKETING_VERSION after each release (done for 2.9). No attribution trailers. Wrap git in gtimeout 60. DerivedData outside iCloud.
- Store text lives in `fastlane/metadata/en-US`; keep it identical to App Store Connect, written like the OpenIntelligence and OpenManual listings from Gunnar's own words, no em dashes, no invented anecdotes.
- App Store Connect: `scripts/asc/asc.py` and `scripts/asc/release.py` (status, wait, attach, submit), run from `scripts/asc` through `zsh -ic`; read ~/ASC/API_ACCESS.md first. release.py hardcodes version 2.8's id and "2.8"; point it at the 2.9 version before using it for 2.9.
- Release-day places for a new version: gunzino.me `src/content/pages/openresponses.md` (version line and What's new; its daily appstore-versions check opens an issue on drift), `openresponses.support.md`, gunnarguy.me `src/content/projects/openresponses.md`, the Gunnarguy profile README, Notion.
- The Gunzino and Gunnarguy-Portfolio repositories are shared with other sessions and bots: commit only your own paths, fetch before pushing. The Gunnarguy profile repo's .git sits in iCloud and can stall; materialize it first (see MACHINE-MAP).
- New models: no scheduled GitHub Actions; the app reads OpenAI's docs pages itself (docs/model-catalog.md). Check the parser with `TEST_RUNNER_LIVE_OPENAI_DOCS=1 ... -only-testing:OpenResponsesTests/ModelCatalogTests`.
- Local Python passed App Review with 2.8 (memory: openresponses-local-python-app-review). Keep it bundled, sandboxed, off by default, approval per run.
- Simulator for this repo: "OpenResponses tests" 73D9ECD6-A7CD-475B-9407-BC12F0B4B0CB (iPhone 18 Pro, iOS 27.0), created 2026-10-01 after 2C5F635A was deleted by something outside this repo; check `xcrun simctl list devices` first. Never run the unit tests on "OpenResponses demo" (D2926987): ChatViewModelLifecycleTests saves and then deletes the Keychain `openAIKey`, which would erase the key Gunnar loaded there for the demos.

## Working Set
- 2.9 = the fixes found while filming the 2.8 demos (CHANGELOG 2.9, docs/ReleaseNotes_2.9.0.md). Store text for 2.9 is in `fastlane/metadata/en-US/release_notes.txt` and `promotional_text.txt`, written to App Store Connect as-is; description, keywords and URLs are unchanged from 2.8.
- Release steps, from `scripts/asc` through `zsh -ic`: push main (Xcode Cloud archives 2.9), `python3 release.py wait RUN` for that push's run, `attach --go` (newest VALID 2.9 build; builds from the 2.9 bump on 2026-09-30 exist too, so attach only after this run's build is VALID), PATCH What's New and promotional text on localization `f344a94d-500c-400a-90d6-840ec22f9261`, `submit --go`.

## Verification
- 2.9 fixes: full unit suite, the set CI runs, on simulator 73D9ECD6 -> 343 executed, 0 failures, 3 skipped (the live docs-page test without its variable, and two search-by-meaning tests that need Apple's on-device model, which a new simulator doesn't have yet). New tests: ToolRowsTextAndFilesTests (12) and two in ChatViewModelLifecycleTests. Two reviewer passes found: browser failures read "Error processing ...", MCP's in_progress names no tool, an mcp_tool_execution_error has no message, a screenshot that replaces `images` hid a chart, and managed image rows kept "Image Generation Call"; all fixed and tested. `python3 scripts/codemap.py check` -> 0 errors, 0 warnings.
- `python3 release.py status` (scripts/asc) on 2026-09-30 -> version 2.8 READY_FOR_SALE, build 51 attached, submission 5e3d5bf0 COMPLETE.
- Gunzino `npm run build` and `./scripts/verify-site.sh source` -> exit 0 before pushing 5e5cf19. Gunnarguy-Portfolio `npm run verify` -> exit 0 before pushing d8327d6.
- `python3 scripts/codemap.py check` -> 0 errors, 0 warnings.
- GitHub CI run 36751566276 (86d9c13) failed six timing tests on a slow runner (Build & Test 19.5 minutes). 5be03ad raised the lifecycle tests' wait to 15 s and retries a timed-out first WebKit page load once; CI run 36754719209 (5be03ad) -> all four jobs success, 329 tests, 3 skipped, 0 failures, tests 119 s.

## Blockers / Unknowns
- The 2.8 features are unchecked on a device (Notion v2.9 row "Live-check the 2.8 features on a device").
- Async tool calls on GPT-6 Sol and Luna stay off until a live request settles whether "GPT-6 Astra and later models" includes them.
- The Notion token in test.env was printed into a session log on 2026-09-24; Gunnar should rotate it.

## Exact Next Action
Wait for App Review (`python3 release.py status` from `scripts/asc` through `zsh -ic`). On approval, update the release-day places in Active Constraints, and push this handoff commit with the next code change (it is docs-only).
