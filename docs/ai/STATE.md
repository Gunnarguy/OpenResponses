# Current State

Updated: 2026-09-30
Branch/worktree: main in the repo root, level with origin/main at ab87186 (pushed 2026-09-29 21:21 PDT) apart from this handoff. Xcode Cloud run 51 builds ab87186. Build 51 (Xcode Cloud run 51, ab87186) is attached to version 2.8, which was submitted to App Review on 2026-09-29 at about 21:28 PDT: review submission 5e3d5bf0-cff5-4f69-9019-05599a734175, WAITING_FOR_REVIEW. This handoff and `scripts/asc/` are committed locally, unpushed, because a docs-only push would start another Xcode Cloud build.
Last verified commit: ab87186

## Objective
2.8 is live: App Review approved it with Local Python in it, and App Store Connect showed version 2.8 READY_FOR_SALE with build 51 on 2026-09-30 (release type AFTER_APPROVAL). Remaining release-day chores, not yet asked for: the gunzino.me OpenResponses page to v2.8 (its appstore-versions workflow opens a drift issue while the page says v2.7), App Store on the v2.8 Notion rows plus a Release row, MARKETING_VERSION to 2.9, the gunnarguy.me card and the GitHub profile README.

## Status
- 2.8 contents (CHANGELOG.md, docs/ReleaseNotes_2.8.0.md): GPT-6.1 Sol; new models listed from the account's GET /models with settings read from OpenAI's docs pages (docs/model-catalog.md); Local Python (Pyodide 314.0.7, per-run approval); search conversations by meaning; MCP sign-in through https://gunzino.me/openresponses/oauth/callback.html; GPT-Live stops when talked over; Settings → Model → Voice stays open; Pro mode on every GPT-5.6 and GPT-6 model; accessibility pass.
- Store listing rewritten 2026-09-29 in the voice of OpenIntelligence 5.4/5.5 and OpenManual 1.2/1.3 (first person, measured, candid; CAPS sections with bullets in What's New): description, What's New, promotional text in `fastlane/metadata/en-US` and in App Store Connect (read back identical). Keywords swap JSON for python. Marketing, support and privacy links moved from GitHub to https://gunzino.me/openresponses/ like OpenIntelligence and OpenManual. Copyright is "© 2026 Gunnar Hostetler" like those apps. Subtitle "Responses API Playground" unchanged. Screenshots carried over from 2.7 (10 iPhone 6.5", 10 iPad 12.9").
- App Review notes (App Store Connect, 3,302 characters; docs/AppReviewNotes.md) add a "New in 2.8" section that explains Local Python against Guideline 2.5.2: bundled interpreter, nothing downloaded, content rules block every load but the runtime, standard library only, approval per run.
- Privacy: gunzino.me/openresponses/privacy/ (Gunzino c79576f, deployed) and PRIVACY.md list the automatic GET /models and docs-page requests and the sign-in page.
- Not done before submission, by Gunnar's choice: the Notion "2.8 phone checklist" device pass. Everything on it is unverified on a device.

## Active Constraints
- Saved presets decode with synthesized Codable via try?; never add a non-optional Prompt property. New options go in ModernResponseOptions (tolerant decoder).
- Every push to main starts an Xcode Cloud archive and GitHub CI; avoid docs-only pushes. Bump MARKETING_VERSION to 2.9 before the next release's first upload. No attribution trailers. Wrap git in gtimeout 60. DerivedData outside iCloud.
- Store text lives in `fastlane/metadata/en-US`; keep it identical to App Store Connect. Write it like the OpenIntelligence and OpenManual listings, from Gunnar's own words, with no em dashes and no invented anecdotes.
- App Store Connect access: `zsh -ic` with the key variables from ~/.zshrc; read ~/ASC/API_ACCESS.md first. `scripts/asc/asc.py` (get/patch/post, listings of all four apps) and `scripts/asc/release.py` (status, wait, attach, submit; mirrors OpenManual's `asc_attach.py` and `asc_submit.py`), run from `scripts/asc` through `zsh -ic`. App 6757338355, version 2.8 id 8dc1e46a-ea72-462b-891f-b1b2a7b2c2bc, release type AFTER_APPROVAL (goes live when approved).
- No scheduled GitHub Actions for model upkeep. Model facts the docs pages cannot give (pro mode, async tool calls, the default model) change in `ModelCatalog.json` with an app release.
- The docs-page parser depends on OpenAI's page layout; check it with `TEST_RUNNER_LIVE_OPENAI_DOCS=1` and `-only-testing:OpenResponsesTests/ModelCatalogTests` (docs/model-catalog.md).
- The Gunzino repository is shared with other sessions: commit only your own paths. Its appstore-versions workflow opens an issue when a page's version differs from the App Store, so the site's "v2.7" changes only after 2.8 is live.
- Simulator for this repo: "OpenResponses tests" 2C5F635A-DB92-4FD4-ACC1-DEB2B2939DEA. Simulators get deleted between sessions; check `xcrun simctl list devices` first.
- Local Python must never download code (App Store guideline 2.5.2).

## Working Set
- `fastlane/metadata/en-US/*.txt`, `docs/AppReviewNotes.md`, `docs/ReleaseNotes_2.8.0.md`, `PRIVACY.md`, `APP_STORE.md`, `CHANGELOG.md`.
- Gunzino: `src/content/pages/openresponses.md` (version line and features, to update on release day), `src/content/pages/openresponses.privacy.md`.

## Verification
- Before the push, on 3f5c8f6's code: full unit suite 329 executed, 0 failures, 1 skipped; ModelCatalogTests 11 of 11 including the live GPT-6.1 Sol docs page; UI suite 6 of 6; signed Debug build installed on Gunnar's iPhone, which saved his key's 7 current models and 60 shutdown dates. ab87186 changes only docs and store text after that.
- App Store Connect after the PATCHes (read back 2026-09-29 21:2x PDT): description 2,951, What's New 2,163, promotional text 161, keywords 95 characters, all identical to the fastlane files; marketing and support URLs, privacy URL, copyright and review notes as written.
- Gunzino deploys for 9eabfb8 and c79576f -> build, deploy and verify success; the live privacy page shows the three automatic-request lines.
- Xcode Cloud run 51 -> COMPLETE SUCCEEDED; build 51 VALID at 21:25 PDT, usesNonExemptEncryption false; `release.py attach --go` -> attached 51; `release.py submit --go` -> submission 5e3d5bf0-cff5-4f69-9019-05599a734175 WAITING_FOR_REVIEW, version 2.8 WAITING_FOR_REVIEW.
- GitHub CI run 36668432665 for ab87186 was still in progress at submission; check it with `gh run view 36668432665 --repo Gunnarguy/OpenResponses`.

## Blockers / Unknowns
- App Review may question Local Python under Guideline 2.5.2. Gunnar decided on 2026-09-29 to leave it in review ("let's try it out, leave for now") after reading Guideline 2.5.2, 4.7 and Developer Program License Agreement 3.3.1(B), which allows interpreted code that fits the app's advertised purpose and stays in the sandbox. If Apple rejects it, remove Local Python entirely (toggle, run_python tool, `OpenResponses/Resources/Pyodide/`, listing and review-note mentions), rebuild and resubmit; hiding it while still bundling it would break Guideline 2.3.1.
- Async tool calls on GPT-6 Sol and Luna stay off until a live request settles whether "GPT-6 Astra and later models" includes them.
- The Notion token in test.env was printed into a session log on 2026-09-24; Gunnar should rotate it.

## Exact Next Action
Ask Gunnar whether to do the release-day chores listed under Objective; the gunzino.me page is the urgent one because of the daily drift check. The in-app Computer Use alert in SettingsHomeView.swift says "Computer Use can control apps", but it only drives the app's own off-screen browser; fix that text in 2.9.
