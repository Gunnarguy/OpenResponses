# Current State

Updated: 2026-11-19
Branch/worktree: main in the repo root. Local commits 45be8d2, 060afd3, 2b0ee98, 6b656a4, 829cc65 and the large-text fix commit after it (all [ci skip]) are not pushed; push only at Gunnar's word. Untracked `.codex/config.toml` is an earlier session's; leave it.
Last verified commit: 829cc65 (the large-text fixes on top of it passed the full run on 54DDDEDE, 2026-11-19: "Executed 384 tests, with 3 tests skipped and 0 failures", all 8 UI tests including both chat-screen audits and the largest-text audit passed, ** TEST SUCCEEDED **)

## Objective
Get OpenResponses 3.0 submitted. Xcode Cloud build 55 (commit 7a12b34) SUCCEEDED and is VALID in App Store Connect but is not attached to the 3.0 version. Attaching it, pasting the What's New (`fastlane/metadata/en-US/release_notes.txt`, 1,294 chars) and submitting are Gunnar's.
3.0 was checked live on 2026-11-19 (chat, rating sheet, Decisions: see Verification).
Settings redesign (Gunnar, 2026-11-19: "make all of these settings, every single page, WAY more intuitive"; he chose to do it in this session): the five segmented tabs are now one list of named pages with search, in `SettingsHomeView.swift`, `ModernResponseSettings.swift` (split into named sections) and `ModelConfigurationView.swift` (Form sections by `Part`). Recorded under CHANGELOG "3.1 — in development"; build 55 (3.0) has none of it. Committed locally, not pushed. Later the same day (Gunnar: text "looks like shit" that big; "connect literally whatever"; Notion "should just be another part of the MCP"): Settings rows stack at accessibility sizes, a Text Size page (`TextSizeSettings.swift`) overrides the size app-wide through window trait overrides, and Connectors (`MCPConnectionsView.swift`) browses the popular list plus the whole MCP Registry, offers sign-in or a key for every listed service, and shows the legacy Notion token as one connection. All in CHANGELOG 3.1; tests pass (see Verification).
Release-note style (Gunnar, 2026-11-19: match OpenIntelligence's ASC release notes for every app): OpenResponses 3.0 already had that layout; its What's New gained the rating sheet line and `promotional_text.txt` was rewritten (it still described 2.9). OpenCone 3.2's What's New was put in that layout by the OpenCone session (OpenCone commit 17b8b44, 3.2 WAITING_FOR_REVIEW). OpenManual has no fastlane release notes in its repo.

## Status
- 3.0 = a6c5507 rating request + 435ac25 Calendar/Reminders dates with no zone offset + b648aa7 Decisions, merged with origin as 7a12b34 and pushed 2026-11-17.
- OpenCone 3.2: build 27 attached and WAITING_FOR_REVIEW since 2026-11-19 (OpenCone commits ccacaa9, 17b8b44, by the OpenCone session).
- GitHub Releases published: v1.0, v2.0, v2.5, v2.7, v2.8, v2.9. Not done: v2.6 (build 41, commit 5b270d8), blocked by an old tag `v2.6.0` at 1e2edda; OpenCone 3.1 (build 25, eeec127), blocked by an old "Release 3.1"/tag `v3.1` at 04267d1. Replacing either needs Gunnar's yes. 3.0 gets a release once it is live.
- China mainland: OpenResponses and OpenCone are `CANNOT_SELL` there, so the Security Assessment and AIGC rows stay "Missing Info". OpenIntelligence and OpenManual are sold there and need a decision by 2027-01-31.

## Active Constraints
- Saved presets decode with synthesized Codable via try?; never add a non-optional Prompt property. New options go in ModernResponseOptions.
- Every push to main starts an Xcode Cloud archive and GitHub CI; mark docs-only commits [ci skip]. Bump MARKETING_VERSION after each release. No attribution trailers. Wrap git in gtimeout 60. Build with `-derivedDataPath /private/tmp/openresponses-derived`.
- App folder `OpenResponses/` is a synchronized group; the test target lists files in project.pbxproj, so new test classes go into existing test files.
- Keys: Gunnar's current key is Keychain service `openai-api-key` (stored with `~/.agents/bin/key-setup openai`). Claude's Bash reading Keychain values is refused; do not route around it. Gunnar runs key-reading scripts in his own terminal. Never print a key or put it in argv.
- Simulators get wiped without notice (all OpenResponses ones were gone again by 2026-11-19). Run `xcrun simctl list devices` first. Never run unit tests on an "OpenResponses demo" simulator (tests delete the Keychain `openAIKey`).
- Store text in `fastlane/metadata/en-US` must match App Store Connect, from Gunnar's words, no em dashes. The Calendar/Reminders and Rate bullets in release_notes.txt were drafted by Claude.
- App Store Connect reads: `zsh -ic "python3 asc.py get '<path>'"` from `scripts/asc`. Workflows: OpenResponses DE3C0357-A353-40E2-9BFF-D94CFEB5D7EB, OpenCone 3AEF0BFD-D83E-431A-A267-523584C570F2 (`/v1/ciWorkflows/<id>/buildRuns`).

## Working Set
- `scripts/sim_openai_key.py` (new, untracked): `python3 scripts/sim_openai_key.py [device name or UDID, default "OpenResponses demo"] [--service openai-api-key]`. Reads the Keychain key, writes it as UserDefaults `openAIKey` plus `hasCompletedOnboarding` through `simctl spawn defaults import` on stdin, relaunches; the app's `KeychainService.migrateApiKeyFromUserDefaults` moves it into the Keychain. Prints "Key moved into the app's Keychain" on success. Refuses device names containing "tests".
- `OpenResponses/Features/Settings/Views/SettingsHomeView.swift`: root list (`SettingsPage`, `SettingsRow`, `SettingsSearchIndex` of about 50 entries), `AccountPage`, `PrivacyPage`, the Tools page (`ToolsTab`, keeps the vector store and file pickers) and Request Options (`AdvancedTab`).
- `OpenResponses/Features/Settings/Views/ModernResponseSettings.swift`: `ReasoningOptionsSection`, `CompactionSection`, `CodeRunningToolsSection`, `AgentOptionsSections`, `ImageGenerationOptionsRows`, `ModerationSection`, `CustomToolSections`, `SettingsToggleLabel`, `SettingsIconTile`.
- `OpenResponses/Features/Settings/Views/TextSizeSettings.swift`: `AppTextSize` (stored as UserDefaults `appTextSize`, "system" or a `DynamicTypeSize` name), `AppTextSizeModifier` (applied in `OpenResponsesApp`), `TextSizeSettingsView`.
- `OpenResponses/Features/Settings/Views/MCPConnectionsView.swift`: `MCPConnectionsView` (Connectors page, registry paging with `loadRegistry`, `notionTokenRow`), `MCPProviderDetailView` (Try Signing In and `connectWithKey` for `.providerSetup`). `MCPProvider.swift` gained GitHub; `MCPRegistryService.search` sends no `search` item for an empty query.
- `OpenResponsesUITests/OpenResponsesUITests.swift`: `testVoiceSettingsStayOpenFromSettings`, `testSettingsSearchOpensThePageThatHoldsAnOption`, and `knownLabelFrameQuirks` now also names the two Settings headers, with the evidence in its comment.
- New Settings strings are not in `Localizable.xcstrings` yet (the catalog only gains keys when Xcode extracts them).
- Demo simulator: "OpenResponses demo" E9842B71-095B-49D2-A72D-0E2FA9C7962B (iPhone 17 Pro, iOS 27.0), created 2026-11-19, booted, 3.0 Debug build installed from `/private/tmp/openresponses-derived/Build/Products/Debug-iphonesimulator/OpenResponses.app`. It holds Gunnar's key (put there by `scripts/sim_openai_key.py`).
- Test simulator: "OpenResponses tests" 54DDDEDE-3B99-48F6-9A30-C65B825A6440 (iPhone 17 Pro, iOS 27.0), created 2026-11-19, text size set back to Large (the default).

## Verification
- 2026-11-17, `xcodebuild test ... -destination 'id=7AFAC899-0FF6-45C9-9F5A-5A441C4FA661' -only-testing:OpenResponsesTests` on 7a12b34 -> "Executed 384 tests, with 4 tests skipped and 0 failures", ** TEST SUCCEEDED **.
- 2026-11-17, `python3 scripts/codemap.py check` -> 0 errors, 0 warnings.
- 2026-11-17, App Store Connect API: OpenResponses build 55 and OpenCone build 27 SUCCEEDED, processing VALID.
- 2026-11-17, `scripts/sim_openai_key.py`: `py_compile` passed; "OpenResponses tests" refused; unknown name exits "No simulator named or with UDID"; `python3 scripts/secret_scan.py` passed. Not yet run with a real key.
- 2026-11-19, Gunnar ran the script -> `No simulator named or with UDID "OpenResponses demo"` (the old demo simulator E9759D29 was wiped). Recreated as E9842B71 above.
- 2026-11-19, second run: the key did reach the app (one `Z3E334EXZD.Gunndamental.OpenResponses` row in the simulator's `keychain-2-debug.db`), but the script reported failure, because `simctl spawn defaults read` kept showing the removed value. The script now counts the app's Keychain rows instead (compiles; not yet rerun).
- 2026-11-19, live on E9842B71 with Gunnar's key, 3.0 Debug build: chat on gpt-6-sol answered (in 5,965, out 30 tokens). Apple's "Enjoying OpenResponses?" rating sheet appeared after the answer; the app's prefs file recorded `reviewPrompt.cleanAnswers` 1, `lastAskedVersion` "3.0". Dismissed with Not Now.
- 2026-11-19, on the 3.1 tree, `xcodebuild test ... -destination 'id=54DDDEDE-3B99-48F6-9A30-C65B825A6440' -only-testing:OpenResponsesTests` plus the three Settings UI tests -> "Executed 384 tests, with 3 tests skipped and 0 failures"; testSettingsPassTheAccessibilityAudit, testSettingsSearchOpensThePageThatHoldsAnOption, testVoiceSettingsStayOpenFromSettings passed; ** TEST SUCCEEDED **. `python3 scripts/codemap.py check` -> 26 slices, 0 errors, 0 warnings.
- 2026-11-19, screenshots on 54DDDEDE: at Accessibility XXXL the old rows broke words ("Op / en / AI"), the new ones don't; with the phone at Accessibility XXXL and `-appTextSize large`, chat and the Settings sheet drew at the default size; Connectors listed the popular services, "github" searched the registry while typing, and GitHub's page showed Try Signing In and Connect with a key or token. No live sign-in or key was tried.
- 2026-11-19, Decisions live (Settings > Advanced > Developer Operations > Decisions, the support-ticket example, gpt-6-luna): department billing 100%, asks_for_refund True 100%, urgency score 1.99 on 0-2 nearest High (99%), 441 input tokens, about $0.000044. The Decisions blocker is closed.

## Blockers / Unknowns
- Connectors: account sign-in and key connections were not tried against a live service in this change. OpenAI's own connectors (Gmail, Google Drive and the rest) are hidden until the app can sign in to them.
- None for 3.0 code: the rating sheet and Decisions were both seen working live on 2026-11-19. The Notion verification row "Live-check Decisions" (https://app.notion.com/p/41749a74d54f81069597c73426b1b265) can be marked done.
- Async tool calls on GPT-6 Sol and Luna stay off until a live request settles whether "GPT-6 Astra and later models" includes them.
- The Notion token in test.env was printed into a session log on 2026-09-24; Gunnar should rotate it.

## Exact Next Action
Gunnar attaches build 55 to the 3.0 version in App Store Connect, pastes `fastlane/metadata/en-US/release_notes.txt` as What's New, and submits. Then push the local [ci skip] commits at his word.
