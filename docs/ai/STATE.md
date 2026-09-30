# Current State

Updated: 2026-09-29
Branch/worktree: main in the repo root. origin/main is dfc028f (pushed 2026-09-28 16:51 PDT). Local main is ahead by 9f20335 (handoff), 55bae08 (voice settings fix), 4a48084 (GPT-6.1 Sol and the account's models in the menus), 1f56b73 and 733265a (handoffs), 9c75a47 (model catalog with a gunzino.me download), 3f5c8f6 (replaces the download with OpenAI docs pages) and this handoff, unpushed on purpose: fixes from Gunnar's phone pass go up together in one Xcode Cloud build when he says "push". His iPhone runs a direct Debug install of 3f5c8f6; TestFlight build 50 has none of these.
Last verified commit: 3f5c8f6

## Objective
Ship 2.8 with everything on the Notion roadmap that Gunnar picked on 2026-09-28 ("Everything, features too"), minus Gmail and Drive, plus automatic new-model support he put in v2.8 on 2026-09-29. Code items are done; what remains is his device pass with the "2.8 phone checklist" page under the Notion roadmap, then a push, then submission.

## Status
- Done in code, tested in the simulator: GPT-Live interrupt fix (LiveInterruptionGate), Local Python (Pyodide 314.0.7), search conversations by meaning, MCP sign-in through an HTTPS callback, accessibility fixes plus UI audit tests, docs corrected, GitHub CI on the xcode-27 image, duplicate string catalog removed. CHANGELOG.md has the 2.8 entry.
- Fixed from the phone pass: Settings → Model → Voice closed its sheet (2026-09-28); GPT-6.1 Sol missing from the chat's model menu (2026-09-29).
- New models without an app update (2026-09-29). Gunnar's requirement: nothing for him to do when OpenAI releases a model, and no scheduled GitHub Actions. The menus list every current GPT model in the account's GET /models list (once per launch); a model the built-in list (`ModelCatalog.json`) does not name gets its reasoning efforts, summary and Responses support from its page on OpenAI's docs site, read once, again after 7 days, at most 3 pages per launch; a GET /models `shutdown_date` within 30 days retires a model. docs/model-catalog.md has the details.
- Replaced the same evening: the first version published the list at gunzino.me with a daily Action that proposed new models. Gunnar rejected the daily Action; Gunzino 9eabfb8 removed the file, the Action and its script, and changed the privacy page's automatic-request line to the docs-page read (deploy passed; the old URL answers 404).
- Needs Gunnar on a device (Notion page "2.8 phone checklist"): GPT-Live and interrupt feel, audio routes, voice notes, 2.7 Responses options, private MCP sign-in, HTTPS sign-in with monday.com/Airtable/Intercom/Vercel, GPT-6.1 Sol and Pro mode, Local Python, search by meaning, VoiceOver, largest text, iPad. "New models appear on their own" can only be checked when OpenAI releases a model the built-in list does not name.
- Skipped for 2.8: Gmail and Drive (Notion row in Future Backlog).

## Active Constraints
- Saved presets decode with synthesized Codable via try?; never add a non-optional Prompt property. New options go in ModernResponseOptions (tolerant decoder).
- Every push to main starts an Xcode Cloud archive and GitHub CI. Bump MARKETING_VERSION after each release. No attribution trailers. Wrap git in gtimeout 60. DerivedData outside iCloud.
- No scheduled GitHub Actions for model upkeep (Gunnar, 2026-09-29: "a check every single day seems crazy"). Model facts the docs pages cannot give (pro mode, async tool calls, the default model) change in `ModelCatalog.json` with an app release.
- The docs-page parser (`ModelCatalog.settings(fromDocsPage:id:checkedOn:)`) depends on OpenAI's page layout. Check it with `TEST_RUNNER_LIVE_OPENAI_DOCS=1` and `-only-testing:OpenResponsesTests/ModelCatalogTests` (docs/model-catalog.md); if the layout changes, new models keep the fallbacks (reasoning from low).
- Model facts come from OpenAI's Markdown docs with a fetch date (append `.md` to a docs URL). No OpenAI key on this Mac.
- Default model stays gpt-6-sol (Notion Decision row "New presets default to GPT-6 Sol"); switching to GPT-6.1 Sol is Gunnar's call and a one-line change in `ModelCatalog.json`.
- Simulator for this repo: "OpenResponses tests" 2C5F635A-DB92-4FD4-ACC1-DEB2B2939DEA (iPhone 18 Pro, iOS 27.0, created 2026-09-29). Simulators get deleted between sessions; check `xcrun simctl list devices` first. UI tests: `bash scripts/ui_tests.sh`.
- xcodebuild test runs here have hung after printing their totals; kill the xcodebuild if it stops printing after "Executed N tests".
- Local Python must never download code (App Store guideline 2.5.2). Docs pages are parsed as data, never run.
- Feature tasks start at `docs/ai/codemap/INDEX.md`; plans live in the Notion roadmap (skill `notion-roadmap`). The Gunzino repository is shared with other sessions: commit only your own paths.

## Working Set
- `OpenResponses/Core/Models/ModelCatalog.swift` (format, validation, docs-page parser), `OpenResponses/Core/Services/ModelCatalogStore.swift` (built-in list, learned settings in Caches/LearnedModelSettings.json, shutdown dates), `OpenResponses/Resources/ModelCatalog/ModelCatalog.json`, `CurrentModelCatalog.swift` (reads both; fallback rules), `ChatViewModel.refreshAccountModels`, `ContentView.swift` (launch `.task`), `OpenAIModel.swift` (`shutdownDate`), `OpenResponsesTests/ModelCatalogTests.swift`.
- Gunzino: `src/content/pages/openresponses.privacy.md` (section 3 automatic-request lines), `scripts/verify-site.sh` (APP_FILES: the MCP callback page).

## Verification
- Full unit suite, the set CI runs (`-only-testing:OpenResponsesTests -skip-testing:OpenResponsesTests/BrowserLiveSiteTests`) plus `TEST_RUNNER_LIVE_OPENAI_DOCS=1`, simulator 2C5F635A -> 329 executed, 0 failures, 1 skipped (a search-by-meaning test). ModelCatalogTests 11 of 11, including testTheLiveGPT61SolPageStillGivesItsSettings, which read the live GPT-6.1 Sol page through the app's parser and got low, medium, high, xhigh, max.
- UI suite from a fresh install, same tree -> 6 executed, 0 failures (chat, settings and conversation audits, largest text, Explore Demo message, voice settings stay open).
- Signed Debug build for generic iOS -> BUILD SUCCEEDED; installed and launched on Gunnar's iPhone (00008140-001130DA1863C01C). Its saved preferences, copied back with `devicectl device copy from`: accountModels = gpt-6.1-sol, gpt-6-sol, gpt-6-astra, gpt-6-luna, gpt-5.6-sol, gpt-5.6-terra, gpt-5.6-luna (all built in, so no docs page was read), and accountModelShutdowns holds 60 entries (for example o4-mini 2026-10-23, gpt-realtime 2027-01-20): the live GET /models returns `shutdown_date`.
- Gunzino 9eabfb8: `npm run build` and `./scripts/verify-site.sh source` -> exit 0; deploy run -> build, deploy and verify success; https://gunzino.me/openresponses/models.json -> 404; the privacy page shows the "New Models (automatic, from version 2.8)" line.
- `python3 scripts/codemap.py check` -> 0 errors, 0 warnings.
- Earlier, unchanged since: push of dfc028f -> GitHub CI success, Xcode Cloud build 50 VALID in App Store Connect.

## Blockers / Unknowns
- Everything on the phone checklist is unverified on a device.
- Async tool calls on GPT-6 Sol and Luna stay off ("GPT-6 Astra and later models" may or may not include them); one live request with `async: true` would settle it, then a `ModelCatalog.json` change.
- Bundling Pyodide adds about 13.5 MB before compression; App Review has not seen Local Python yet.
- The Notion token in test.env was printed into a session log on 2026-09-24; Gunnar should rotate it.

## Exact Next Action
Gunnar works through the Notion page "2.8 phone checklist" on the direct install. For each item he reports, close the matching roadmap row on a pass or fix it on a fail. When he says "push": push main (starts Xcode Cloud and GitHub CI), confirm the new build is VALID in App Store Connect, and add TestFlight to the rows it contains.
