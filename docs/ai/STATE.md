# Current State

Updated: 2026-09-30
Branch/worktree: main in the repo root; this handoff is pushed with the 2.9 version bump (Xcode Cloud builds it as a 2.9 TestFlight build).
Last verified commit: 5be03ad

## Objective
None active. 2.8 is released and every release-day task is done. 2.9 is open for whatever Gunnar picks next from the Notion roadmap (the v2.9 rows are device checks carried over from 2.8, plus anything he adds).

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
- Simulator for this repo: "OpenResponses tests" 2C5F635A-DB92-4FD4-ACC1-DEB2B2939DEA; check `xcrun simctl list devices` first.

## Working Set
- None in progress.

## Verification
- 2.9 changes (version bump, Computer Use text): full unit suite, the set CI runs, on simulator 2C5F635A -> 329 executed, 0 failures, 2 skipped (the live docs-page test without its variable, and a search-by-meaning test).
- `python3 release.py status` (scripts/asc) on 2026-09-30 -> version 2.8 READY_FOR_SALE, build 51 attached, submission 5e3d5bf0 COMPLETE.
- Gunzino `npm run build` and `./scripts/verify-site.sh source` -> exit 0 before pushing 5e5cf19. Gunnarguy-Portfolio `npm run verify` -> exit 0 before pushing d8327d6.
- `python3 scripts/codemap.py check` -> 0 errors, 0 warnings.
- GitHub CI run 36751566276 (86d9c13) failed six timing tests on a slow runner (Build & Test 19.5 minutes). 5be03ad raised the lifecycle tests' wait to 15 s and retries a timed-out first WebKit page load once; CI run 36754719209 (5be03ad) -> all four jobs success, 329 tests, 3 skipped, 0 failures, tests 119 s.

## Blockers / Unknowns
- The 2.8 features are unchecked on a device (Notion v2.9 row "Live-check the 2.8 features on a device").
- Async tool calls on GPT-6 Sol and Luna stay off until a live request settles whether "GPT-6 Astra and later models" includes them.
- The Notion token in test.env was printed into a session log on 2026-09-24; Gunnar should rotate it.

## Exact Next Action
None. The previous objective is complete and verified. There is no active objective; ask the user what to pick up, or take an item from the Notion roadmap (the v2.9 rows).
