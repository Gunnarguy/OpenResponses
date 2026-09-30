# Current State

Updated: 2026-09-29
Branch/worktree: main in the repo root. origin/main is dfc028f (pushed 2026-09-28 16:51 PDT). Local main is ahead by 9f20335 (handoff), 55bae08 (voice settings fix), 4a48084 (GPT-6.1 Sol and the account's models in the model menus) and this handoff, unpushed on purpose: fixes from Gunnar's phone pass go up together in one Xcode Cloud build when he says "push". His iPhone runs a direct Debug install of 4a48084; TestFlight build 50 has neither fix.
Last verified commit: 4a48084

## Objective
Ship 2.8 with everything on the Notion roadmap that Gunnar picked on 2026-09-28 ("Everything, features too"), minus Gmail and Drive, which he skipped. Code items are done; what remains is his device pass with the "2.8 phone checklist" page under the Notion roadmap, then a push, then submission.

## Status
- Done in code, tested in the simulator: GPT-Live interrupt fix (LiveInterruptionGate), Local Python (Pyodide 314.0.7, run_python tool with per-run approval), search conversations by meaning (ConversationSearchIndex), MCP sign-in through an HTTPS callback (page live at https://gunzino.me/openresponses/oauth/callback.html), accessibility fixes plus UI audit tests, docs corrected, GitHub CI on the xcode-27 image, duplicate string catalog removed. CHANGELOG.md has the 2.8 entry.
- Fixed from the phone pass:
  - 2026-09-28: Settings → Model → Voice closed its sheet within seconds; the sheet moved from a Section to the Form (UI test testVoiceSettingsStayOpenFromTheModelTab).
  - 2026-09-29: GPT-6.1 Sol (`gpt-6.1-sol`, released that day) was missing from the chat status bar's model menu. Those menus read only the catalog; 2.7's version recognition reached only Settings → Model. Now the catalog lists it with its documented settings, and both menus add `ChatViewModel.accountModels` (one GET /models per launch). Pro mode is offered for every GPT-5.6 and GPT-6 model. Notion row "GPT-6.1 Sol in every model menu; menus list the account's newer models".
- Needs Gunnar on a device (Notion page "2.8 phone checklist", which now has a GPT-6.1 Sol line): GPT-Live session and interrupt feel, audio routes, voice notes, 2.7 Responses options, private MCP sign-in and refresh, HTTPS sign-in with monday.com/Airtable/Intercom/Vercel, GPT-6.1 Sol and Pro mode, Local Python end to end, search by meaning, VoiceOver, largest text, iPad.
- Skipped for 2.8: Gmail and Drive (Notion row in Future Backlog with the reasons).

## Active Constraints
- Saved presets decode with synthesized Codable via try?; never add a non-optional Prompt property. New options go in ModernResponseOptions (tolerant decoder).
- Every push to main starts an Xcode Cloud archive and GitHub CI (xcode-27 preview image, which can queue). Bump MARKETING_VERSION after each release. No attribution trailers. Wrap git in gtimeout 60. DerivedData outside iCloud.
- API and model facts come from OpenAI's Markdown docs, with a fetch date: https://developers.openai.com/api/reference/llms.txt, and any docs page with `.md` appended (for example https://developers.openai.com/api/docs/models/gpt-6.1-sol.md). No OpenAI key on this Mac. A new model goes into `CurrentModelCatalog.recommended` with its reasoning efforts; `modelsAcceptingNoReasoning` lists only models whose model page lists `none`.
- Default model stays gpt-6-sol (Notion Decision row "New presets default to GPT-6 Sol; existing presets keep their model"). OpenAI's guide now features GPT-6.1 Sol in that slot; changing the default is Gunnar's call.
- Simulator for this repo: "OpenResponses tests" 2C5F635A-DB92-4FD4-ACC1-DEB2B2939DEA (iPhone 18 Pro, iOS 27.0, created 2026-09-29 because the 2026-09-28 one had been deleted; `xcrun simctl delete` it to remove). Simulators are shared across sessions and get deleted; check `xcrun simctl list devices` first. A new simulator has no sentence-embedding model, so ConversationSearchIndexTests skips 2 tests until it downloads. UI tests: `bash scripts/ui_tests.sh`.
- xcodebuild test runs in this repo have hung after printing their totals; the scratchpad wrapper killed them 30 s later. If a run stops printing after "Executed N tests", kill that xcodebuild.
- Local Python must never download code (App Store guideline 2.5.2): packages stay out, python-runner.html refuses network APIs, and the content rule list blocks every load but the runtime scheme.
- Feature tasks start at `docs/ai/codemap/INDEX.md`; the codemap hooks name stale slices after code changes.
- Plans live in the Notion roadmap (skill `notion-roadmap`); CHANGELOG.md records what shipped.

## Working Set
- `OpenResponses/Core/Models/CurrentModelCatalog.swift` (recommended list, `currentAccountModels`, `selectionModels(including:account:)`, reasoning efforts, pro and async support), `ChatViewModel.swift` (`accountModels`, `refreshAccountModels`), `ContentView.swift` (launch `.task`), `ChatStatusBar.swift` and `PlaygroundSettingsPanel.swift` (the two menus).
- `OpenResponses/Core/Services/LocalPythonRunner.swift`, `OpenResponses/Resources/Pyodide/`, `ChatViewModel+LocalPython.swift`, `PythonRunApprovalSheet.swift`.
- `OpenResponses/Core/Services/ConversationSearchIndex.swift`, `ConversationListView.swift`.
- `OpenResponses/Core/Services/MCPAuthorization.swift` (webRedirectURI fallback); the page is `public/openresponses/oauth/callback.html` in the Gunzino repository.
- `OpenResponses/Core/Services/RealtimeService.swift`, `RealtimeAudioPipeline.swift` (LiveInterruptionGate).
- `OpenResponsesUITests/OpenResponsesUITests.swift`, `scripts/ui_tests.sh`, `.github/workflows/ci.yml`.

## Verification
- Full unit suite, the set CI runs (`-only-testing:OpenResponsesTests -skip-testing:OpenResponsesTests/BrowserLiveSiteTests`), on simulator 2C5F635A with the 4a48084 tree -> 317 executed, 0 failures, 2 skipped (ConversationSearchIndexTests: "No English sentence embedding on this device"). The new tests testGPT61SolIsInEveryModelMenuWithItsDocumentedSettings, testModelMenusListTheAccountsNewerModelsFirst and testAccountModelsKeepTheCurrentGeneralModelsFromTheModelList passed.
- UI suite on the same tree, from a fresh install (`-only-testing:OpenResponsesUITests/OpenResponsesUITests`) -> 6 executed, 0 failures: chat, settings and conversation-list audits, largest text, Explore Demo message, and testVoiceSettingsStayOpenFromTheModelTab.
- `xcodebuild build -configuration Debug -destination generic/platform=iOS -allowProvisioningUpdates` -> BUILD SUCCEEDED; `devicectl device install app` and `process launch` on Gunnar's iPhone (00008140-001130DA1863C01C) succeeded 2026-09-29.
- `python3 scripts/codemap.py check` -> 0 errors, 0 warnings.
- Earlier, unchanged since: push of dfc028f -> GitHub CI run 36500130939 success; Xcode Cloud run 50 succeeded; App Store Connect lists build 50 for 2.8 as VALID. Meaning-based similarity on macOS 27: related passages 0.21 to 0.28, unrelated 0.02 to 0.18, cut-off 0.15. The HTTPS callback page returns 200 and forwards to openresponses://mcp/oauth/callback.

## Blockers / Unknowns
- Everything on the phone checklist is unverified on a device, including whether the Live interruption gate's thresholds (speech 0.35, onset 0.18 s, hold 0.6 s) feel right, and whether GPT-6.1 Sol answers with Pro mode on.
- Async tool calls on GPT-6 Sol and Luna stay off: OpenAI's guide says "GPT-6 Astra and later models", and whether that covers Sol and Luna (released after Astra, same version number) needs one live request with `async: true` to settle.
- Bundling Pyodide adds about 13.5 MB before compression; App Review has not seen Local Python yet.
- The Notion token in test.env was printed into a session log on 2026-09-24; Gunnar should rotate it.

## Exact Next Action
Gunnar works through the Notion page "2.8 phone checklist" on the direct install of 4a48084 (or on TestFlight once pushed). For each item he reports, close the matching roadmap row on a pass or fix it on a fail. When he says "push", push main (starts Xcode Cloud and GitHub CI), confirm the new build is VALID in App Store Connect, and add TestFlight to the rows it contains.
