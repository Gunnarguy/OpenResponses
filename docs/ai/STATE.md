# Current State

Updated: 2026-09-28
Branch/worktree: main in the repo root. Written before the 2.8 feature commit; local main then carries three unpushed commits on top of origin/main 2d7fedd (docs and CI, the GPT-Live interrupt fix, the 2.8 features), pushed together in the same session.
Last verified commit: 343c3d4

## Objective
Ship 2.8 with everything on the Notion roadmap that Gunnar picked on 2026-09-28 ("Everything, features too"), minus Gmail and Drive, which he skipped. Code items are done; what remains is his device pass with the "2.8 phone checklist" page under the Notion roadmap, then submission.

## Status
- Done in code, tested in the simulator: GPT-Live interrupt fix (LiveInterruptionGate), Local Python (Pyodide 314.0.7, run_python tool with per-run approval), search conversations by meaning (ConversationSearchIndex), MCP sign-in through an HTTPS callback (page live at https://gunzino.me/openresponses/oauth/callback.html, Gunzino commit pushed and deployed), accessibility fixes plus UI audit tests, docs corrected (DRIFT.md 0 rows), GitHub CI moved to the xcode-27 image, duplicate string catalog removed. CHANGELOG.md has the 2.8 entry.
- Needs Gunnar on a device (Notion page "2.8 phone checklist"): GPT-Live session and interrupt feel, audio routes, voice notes, 2.7 Responses options, private MCP sign-in and refresh, HTTPS sign-in with monday.com/Airtable/Intercom/Vercel, Local Python end to end, search by meaning (the iOS simulator has no sentence-embedding model), VoiceOver, largest text, iPad.
- Skipped for 2.8: Gmail and Drive (Notion row moved to Future Backlog with the reasons: connector_id deprecated for models after September 1, 2026; Google's Workspace MCP servers are preview-only and need a confidential client; Gmail read scopes are restricted).

## Active Constraints
- Saved presets decode with synthesized Codable via try?; never add a non-optional Prompt property. New options go in ModernResponseOptions (tolerant decoder); `localPython` was added there.
- Every push to main starts an Xcode Cloud archive and GitHub CI (now on the xcode-27 preview image, which can queue). Bump MARKETING_VERSION after each release. No attribution trailers. Wrap git in gtimeout 60. DerivedData outside iCloud.
- API facts come from OpenAI's Markdown reference (https://developers.openai.com/api/reference/llms.txt), with a fetch date. No OpenAI key on this Mac.
- Simulator for this repo: "OpenResponses tests" 02DCAC26-B0FB-4AD4-B39A-9F48BFCEF277 (iPhone 18 Pro, iOS 27.0, created 2026-09-28; `xcrun simctl delete` it to remove). Simulators are shared across sessions. UI tests: `bash scripts/ui_tests.sh` (uninstalls the app first, so earlier chats do not change the audits).
- An xcodebuild test run in this session twice finished its tests and then hung; the tests' own output was complete. If a run stops printing after "Executed N tests", kill that xcodebuild.
- Local Python must never download code (App Store guideline 2.5.2): packages stay out, python-runner.html refuses network APIs, and the content rule list blocks every load but the runtime scheme.
- Feature tasks start at `docs/ai/codemap/INDEX.md`; the codemap Stop hook names stale slices after code changes.
- Plans live in the Notion roadmap (skill `notion-roadmap`); CHANGELOG.md records what shipped.

## Working Set
- `OpenResponses/Core/Services/LocalPythonRunner.swift`, `OpenResponses/Resources/Pyodide/` (runtime, SHA-256 of the release tarball checked against GitHub's digest), `ChatViewModel+LocalPython.swift`, `PythonRunApprovalSheet.swift`.
- `OpenResponses/Core/Services/ConversationSearchIndex.swift`, `ConversationListView.swift`.
- `OpenResponses/Core/Services/MCPAuthorization.swift` (webRedirectURI fallback); the page is `public/openresponses/oauth/callback.html` in the Gunzino repository.
- `OpenResponses/Core/Services/RealtimeService.swift`, `RealtimeAudioPipeline.swift` (LiveInterruptionGate).
- `OpenResponsesUITests/OpenResponsesUITests.swift`, `scripts/ui_tests.sh`, `.github/workflows/ci.yml`.

## Verification
- Full unit suite, the set CI runs (`-only-testing:OpenResponsesTests -skip-testing:OpenResponsesTests/BrowserLiveSiteTests`), Xcode 27.0 and the iOS 27.0 simulator -> 314 passed, 0 failed, no test-host restart. That run followed a fix for a real crash the previous run found: `ConversationSearchIndex.update` hit Swift's exclusivity check (`store?.entries = store?.entries.filter`).
- UI suite from a fresh install (`scripts/ui_tests.sh` does the same) -> 5 of 5: audits of chat, settings, conversations and the largest text size, and a demo-mode message round trip. Recorded but not failed: "nearly passed" contrast warnings, navigation-bar chrome, and a SwiftUI Label frame quirk on Settings → Start Demo / Exit Demo (a screenshot shows both rows whole).
- LocalPythonRunnerTests 6 of 6 (network refused in 0.06 s; a runaway loop stopped and replaced in 7.9 s). ConversationSearchIndexTests 5 of 5 once the simulator had downloaded the English sentence-embedding asset (the first request logs "Unable to locate Asset"; the index then waits instead of caching empty vectors).
- Meaning-based similarity on macOS 27, English sentence embedding revision 1: related passages 0.21 to 0.28, unrelated 0.02 to 0.18; the cut-off is 0.15.
- `https://gunzino.me/openresponses/oauth/callback.html` -> HTTP 200, forwards to openresponses://mcp/oauth/callback, no analytics, not in the sitemap; Gunzino deploy run 36495560317 succeeded.
- Codemap: `check` 0 errors, 0 warnings; DRIFT.md 0 rows; 25 slices with the new `local-python`.

## Blockers / Unknowns
- Everything on the phone checklist is unverified on a device, including whether the Live interruption gate's thresholds (speech 0.35, onset 0.18 s, hold 0.6 s) feel right.
- Bundling Pyodide adds about 13.5 MB before compression; App Review has not seen Local Python yet.
- The Notion token in test.env was printed into a session log on 2026-09-24; Gunnar should rotate it.

## Exact Next Action
Read the GitHub CI run and the Xcode Cloud run for the 2.8 push. If both pass, Gunnar installs the new build from TestFlight and works through the Notion page "2.8 phone checklist"; close each roadmap row on a pass.
