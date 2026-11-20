# Current State

Updated: 2026-11-20
Branch/worktree: main in the repo root; the 3.1 commit below is local, not pushed (3.0 is in review and a push starts an Xcode Cloud archive). Untracked `.codex/config.toml` is an earlier session's; leave it.
Last verified commit: 2b361da (3.1 work tested on top of it, 2026-11-20); earlier: 2b70581 (code tested on ab93bcb, 2026-11-19, simulator 54DDDEDE: "Executed 384 tests, with 3 tests skipped and 0 failures", all 8 UI tests passed, ** TEST SUCCEEDED **; 2b70581 changed store text and docs only)

## Objective
3.1 (Gunnar, 2026-11-20: "Share sheet + Shortcuts", then "mac app too ... do literally EVERYTHING ... deep research the OpenAI and also apple APIs"): Shortcuts actions, the share sheet and a Mac Catalyst build are in the local 3.1 commit; next are the OpenAI API gaps in `docs/research/openai-api-gaps-2026-11.md` (new GPT-6.2 and 6.1 Terra models, GPT-6.2 instructions as a developer message, background completion windows, prompt cache 12h and diagnostics, streaming events, web search blocked domains, service tiers per model). Meanwhile 3.0 is in review.

Earlier objective: OpenResponses 3.0 is submitted with everything through November 19, 2026 (Settings redesign, Text Size, Connectors, large-text fixes, Decisions, rating sheet, tool-step arguments, Calendar dates). Next: watch review, and after it goes live bump MARKETING_VERSION.

## Status
- 2026-11-20, 3.1 (local commit, see CHANGELOG 3.1 and `docs/share-shortcuts-mac.md`): App Intents `AskOpenResponsesIntent` and `NewChatIntent` with `OpenResponsesShortcuts`; share extension target `OpenResponsesShare` writing to `SharedInbox` in App Group `group.Gunndamental.OpenResponses`; `ChatViewModel.takeSharedInbox` opens it as an unsent new chat; Mac Catalyst on (`SUPPORTS_MACCATALYST = YES`, same bundle ID) with `Config/*-mac.entitlements`; menu commands New Chat and Settings; Command-Return sends. Research reports in `docs/research/`. Device build blocked on signing (Blockers).
- 2026-11-19: pushed 2b70581; Xcode Cloud run 56 SUCCEEDED 17:52, build 56 VALID, attached to 3.0 (`python3 scripts/asc/release.py attach --go`, now pointed at 3.0) and submitted: submission c40d93aa-0d3c-4fda-ad72-4731bed170f5 WAITING_FOR_REVIEW, version 3.0 WAITING_FOR_REVIEW, release AFTER_APPROVAL. The first submit got 409 because the age rating lacked Apple's new required `socialMedia`; set `socialMedia`, `sharedLocation` and `datingAndRelationships` to false on app info e4cf1762 (the app has none of them; Apple's AgeRatingDeclarationUpdateRequest reference read 2026-11-20 UTC). `socialMediaAgeRestricted` left unset.
- ASC 3.0 en-US read back equal to the repo: whatsNew = `fastlane/metadata/en-US/release_notes.txt`, promotionalText, description, keywords, and App Review notes = `fastlane/metadata/review_information/notes.txt`.
- GitHub release v3.0 published at 2b70581, not marked Latest (2.9 is still live): https://github.com/Gunnarguy/OpenResponses/releases/tag/v3.0. Mark it Latest when 3.0 is live.
- Not updated: App Store screenshots and previews still show the 2.9 Settings tabs.
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
- Device and Cloud builds of 3.1 need the App Group and the extension's App ID registered. 2026-11-20: `scripts/ship_device.sh` failed with "No Accounts" (Xcode signed out) and, through `zsh -ic` with the App Store Connect key, "Authentication failed". Gunnar signs in to Xcode (Settings > Accounts, team Z3E334EXZD), then `zsh -ic scripts/ship_device.sh` registers both and installs. Until then the share extension has run only in the simulator build.
- Mac: the Catalyst build ran unsigned; the menu commands were not seen working (the shell could not send keystrokes). Whether "Make this app available on Mac" (the iPad app on Apple silicon Macs) is on in App Store Connect is unknown.
- Connectors: account sign-in and key connections were not tried against a live service in this change. OpenAI's own connectors (Gmail, Google Drive and the rest) are hidden until the app can sign in to them.
- None for 3.0 code: the rating sheet and Decisions were both seen working live on 2026-11-19. The Notion verification row "Live-check Decisions" (https://app.notion.com/p/41749a74d54f81069597c73426b1b265) can be marked done.
- Async tool calls on GPT-6 Sol and Luna stay off until a live request settles whether "GPT-6 Astra and later models" includes them.
- The Notion token in test.env was printed into a session log on 2026-09-24; Gunnar should rotate it.

## Exact Next Action
After Gunnar signs in to Xcode: `zsh -ic scripts/ship_device.sh`, then share a web page from Safari to OpenResponses on the phone and open the app; the chat should open with the link in the message field. Then the OpenAI gaps, top rows of `docs/research/openai-api-gaps-2026-11.md` first. Separately, when 3.0 is live:
When App Store Connect shows 3.0 Ready for Distribution: `gh release edit v3.0 --latest`, change CHANGELOG's 3.0 heading to "released <date> (build 56)", and bump MARKETING_VERSION to 3.1 in all four lines of project.pbxproj (app and share extension) and create 3.1 in ASC before the next push to main. If review rejects, read the resolution center and fix on a commit from 2b361da, since local main now carries 3.1 work.
