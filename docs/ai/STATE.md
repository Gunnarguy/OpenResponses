# Current State

Updated: 2026-09-29
Branch/worktree: main in the repo root. origin/main is dfc028f (pushed 2026-09-28 16:51 PDT). Local main is ahead by 9f20335 (handoff), 55bae08 (voice settings fix), 4a48084 (GPT-6.1 Sol and the account's models in the model menus), 1f56b73 (handoff), 9c75a47 (model catalog) and this handoff, unpushed on purpose: fixes from Gunnar's phone pass go up together in one Xcode Cloud build when he says "push". His iPhone runs a direct Debug install of 9c75a47; TestFlight build 50 has none of these.
Last verified commit: 9c75a47

## Objective
Ship 2.8 with everything on the Notion roadmap that Gunnar picked on 2026-09-28 ("Everything, features too"), minus Gmail and Drive, plus the model catalog he put in v2.8 on 2026-09-29. Code items are done; what remains is his device pass with the "2.8 phone checklist" page under the Notion roadmap, then a push, then submission.

## Status
- Done in code, tested in the simulator: GPT-Live interrupt fix (LiveInterruptionGate), Local Python (Pyodide 314.0.7), search conversations by meaning, MCP sign-in through an HTTPS callback, accessibility fixes plus UI audit tests, docs corrected, GitHub CI on the xcode-27 image, duplicate string catalog removed. CHANGELOG.md has the 2.8 entry.
- Fixed from the phone pass: Settings → Model → Voice closed its sheet (2026-09-28); GPT-6.1 Sol missing from the chat's model menu (2026-09-29).
- Model catalog (2026-09-29, Gunnar: "Ok, yes, v2.8"): models, their settings, the default model and retirements come from `ModelCatalog.json` in the app or https://gunzino.me/openresponses/models.json, whichever valid copy has the higher revision; downloaded at most once a day; a GET /models shutdown date within 30 days retires a model. docs/model-catalog.md has the format and upkeep. Gunzino side pushed and deployed: 7e654cd (file at revision 1, `scripts/openai_models.py`, daily workflow `openai-models.yml`, deploy check, privacy page section 3 lines dated September 29) and 6593609 (revision 2, same models, so 2.8 builds carrying revision 1 show "downloaded from gunzino.me").
- Needs Gunnar on a device (Notion page "2.8 phone checklist"): GPT-Live and interrupt feel, audio routes, voice notes, 2.7 Responses options, private MCP sign-in, HTTPS sign-in with monday.com/Airtable/Intercom/Vercel, GPT-6.1 Sol and Pro mode, the model list reading "downloaded from gunzino.me", Local Python, search by meaning, VoiceOver, largest text, iPad.
- Skipped for 2.8: Gmail and Drive (Notion row in Future Backlog).

## Active Constraints
- Saved presets decode with synthesized Codable via try?; never add a non-optional Prompt property. New options go in ModernResponseOptions (tolerant decoder).
- Every push to main starts an Xcode Cloud archive and GitHub CI. Bump MARKETING_VERSION after each release. No attribution trailers. Wrap git in gtimeout 60. DerivedData outside iCloud.
- Model facts come from OpenAI's Markdown docs with a fetch date (append `.md` to a docs URL). No OpenAI key on this Mac. A model change goes into the model catalog, not into Swift: edit `public/openresponses/models.json` in the Gunzino repository, raise `revision`, run `python3 scripts/openai_models.py check` there, push. Before an app release, copy the published file into `OpenResponses/Resources/ModelCatalog/ModelCatalog.json` (docs/model-catalog.md); the built-in copy is revision 1 and the published one revision 2 on purpose until then.
- The catalog validation rules exist twice: `ModelCatalog.problem()` and `problem()` in Gunzino's `scripts/openai_models.py`. Change them together.
- Gunzino's "Allow GitHub Actions to create and approve pull requests" was off on 2026-09-29, so the daily workflow proposes new models as an issue with a compare link. Turning it on is Gunnar's call (a repository setting).
- Default model stays gpt-6-sol (Notion Decision row "New presets default to GPT-6 Sol"); now a one-line catalog change if Gunnar picks GPT-6.1 Sol.
- Simulator for this repo: "OpenResponses tests" 2C5F635A-DB92-4FD4-ACC1-DEB2B2939DEA (iPhone 18 Pro, iOS 27.0, created 2026-09-29). Simulators get deleted between sessions; check `xcrun simctl list devices` first. UI tests: `bash scripts/ui_tests.sh`.
- xcodebuild test runs here have hung after printing their totals; kill the xcodebuild if it stops printing after "Executed N tests".
- Local Python must never download code (App Store guideline 2.5.2). The model catalog is data only.
- Feature tasks start at `docs/ai/codemap/INDEX.md`; plans live in the Notion roadmap (skill `notion-roadmap`).

## Working Set
- `OpenResponses/Core/Models/ModelCatalog.swift`, `OpenResponses/Core/Services/ModelCatalogStore.swift`, `OpenResponses/Resources/ModelCatalog/ModelCatalog.json`, `CurrentModelCatalog.swift` (reads the catalog; fallback rules for unlisted models), `ChatViewModel.swift` (`refreshModelCatalog`, `refreshAccountModels`, `modelCatalogRevision`), `ContentView.swift` (launch `.task`), `SettingsHomeView.swift` (Settings → Model footer), `OpenAIModel.swift` (`shutdownDate`), `OpenResponsesTests/ModelCatalogTests.swift`.
- Gunzino: `public/openresponses/models.json`, `scripts/openai_models.py`, `.github/workflows/openai-models.yml`, `scripts/verify-site.sh` (APP_FILES), `src/content/pages/openresponses.privacy.md`.

## Verification
- Full unit suite, the set CI runs (`-only-testing:OpenResponsesTests -skip-testing:OpenResponsesTests/BrowserLiveSiteTests`), simulator 2C5F635A, 9c75a47 tree -> 325 executed, 0 failures, 1 skipped (a search-by-meaning test without the embedding model). ModelCatalogTests 7 of 7 and testAShutdownDateInTheModelListMovesTheActivePresetOffThatModel passed.
- UI suite from a fresh install, same tree -> 6 executed, 0 failures (chat, settings and conversation audits, largest text, Explore Demo message, voice settings stay open).
- Signed Debug build for generic iOS -> BUILD SUCCEEDED; installed and launched on Gunnar's iPhone (00008140-001130DA1863C01C). `devicectl device copy from` Library/Caches/ModelCatalog.json -> revision 2, first model gpt-6.1-sol: the phone downloaded and adopted the published file.
- Gunzino: `npm run build` and `./scripts/verify-site.sh source` -> exit 0, including `dist/openresponses/models.json: valid`; deploy runs for 7e654cd and 6593609 -> build, deploy and live verify all success; https://gunzino.me/openresponses/models.json -> HTTP 200, application/json, max-age=600, revision 2, valid. Workflow openai-models.yml run 36656721573 (manual) -> success, "101 models in OpenAI's catalog, 7 general-purpose; new: none". Locally, with GPT-6.1 Sol removed from a copy, `watch --write` found it and wrote reasoning effort low to max, pro yes, async yes, and a valid revision 2.
- `python3 scripts/codemap.py check` -> 0 errors, 0 warnings.
- Earlier, unchanged since: push of dfc028f -> GitHub CI success, Xcode Cloud build 50 VALID in App Store Connect.

## Blockers / Unknowns
- Everything on the phone checklist is unverified on a device.
- `shutdown_date` is in OpenAI's Models API reference (2026-09-29) but no live GET /models response has been seen from this Mac; the app ignores a missing or unreadable date.
- Async tool calls on GPT-6 Sol and Luna stay off ("GPT-6 Astra and later models" may or may not include them); one live request with `async: true` would settle it, then a catalog change.
- Bundling Pyodide adds about 13.5 MB before compression; App Review has not seen Local Python yet.
- The Notion token in test.env was printed into a session log on 2026-09-24; Gunnar should rotate it.

## Exact Next Action
Gunnar works through the Notion page "2.8 phone checklist" on the direct install. For each item he reports, close the matching roadmap row on a pass or fix it on a fail. When he says "push": copy the published model file into ModelCatalog.json (docs/model-catalog.md), commit, push main, confirm the Xcode Cloud build is VALID in App Store Connect, and add TestFlight to the rows it contains.
