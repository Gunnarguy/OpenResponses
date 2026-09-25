# Current State

Updated: 2026-09-24
Branch/worktree: main in the repo root. HEAD 3c3f04c (one commit ahead of origin 9dd8e1d). The API coverage pass below is UNCOMMITTED in the working tree.
Last verified commit: 3c3f04c

## Objective
OpenResponses 2.7 as a long-lived release. Gunnar asked (2026-09-24) to remove everything OpenAI has shut down or deprecated and to include every current API endpoint and parameter. Earlier today 9dd8e1d added GPT-6 Sol/Luna and GPT Image 2.5; Xcode Cloud build 46 of that commit is VALID and selected on ASC version 2.7.

## Status
In progress: code complete and tested locally; an adversarial reviewer subagent was reviewing the uncommitted diff when this was written. Not yet committed or pushed. Pushing main starts Xcode Cloud build 47, which must then replace build 46 on version 2.7.

## Completed (uncommitted)
- Removed: Assistants service/models/protocol, CreateAssistantSheet, LegacyMigrationLabView; FineTuningService/Models/View and JSONLDocument (9 files, git rm). Published prompts, user, promptCacheRetention, streamIncludeUsage, audio modalities, includeComputerCallOutput (Prompt fields, registry descriptors, request code). web_search_preview and computer_use_preview tools and the computer-use-preview path (old saved configs decode to web_search/computer). Registry entries for o3, o3-mini, gpt-5, gpt-5-mini, gpt-5-nano, gpt-4.1-nano, gpt-4.1-2025-04-14, computer-use-preview, gpt-5.5-mini/nano. Realtime beta event aliases. Dead tool-config helpers in OpenAIService.
- Added: GPT-Live 1 in RealtimeService (wss /v1/live/sessions, session.start, session.input_audio.append, mute/unmute, output audio/transcript deltas, session.close). Voice settings sheet now reachable from Settings → Model → Voice. ModernResponseOptions fields (tolerant decoder): moderation, webSearchExternalAccess, codeInterpreterMemoryLimit, imageInputFidelity, imageOutputCompression, hybrid search weights. Service tiers fast/ultrafast. Workbench endpoints for responses, conversations, models, moderations, embeddings, files, vector stores, containers, batches, realtime client secrets, voice consents, with DELETE confirmation. Batch endpoint picker defaulting to /v1/responses.
- Fixed: capability inheritance only for dated snapshots; getCapabilities nil for retired models; presets on retired models move to OpenAI's documented replacement (CurrentModelCatalog.replacement, applied in ChatViewModel.enforceResponsesAPIConstraints); web_search filters send allowed_domains only; ranker default-2024-11-15; moderation names omni-moderation-latest; registry apiField names.
- Store copy updated in fastlane/metadata (description, What's New, review notes), CHANGELOG, docs/ReleaseNotes_2.7.0.md, TestFlight notes, paste sheet.

## Active Constraints
- Saved presets decode with synthesized Codable via try? ([Prompt]); never add a non-optional Prompt property. New options go in ModernResponseOptions.
- Every push to main starts an Xcode Cloud archive (build number = run number). No attribution trailers. Wrap git in gtimeout 60. DerivedData outside iCloud.
- API facts come from OpenAI's Markdown reference exports downloaded 2026-09-24 to the session scratchpad (oaidocs/); re-download from https://developers.openai.com/api/reference/llms.txt. No OpenAI key on this Mac; Live voice is verified by unit tests of the protocol payloads only, not a live session.
- Before PATCHing ASC copy, compare live fields with the last committed copy (script asc_27_update.py in the scratchpad did this; hand edits are skipped).

## Verification
- `xcodebuild test -project OpenResponses.xcodeproj -scheme OpenResponses -destination "platform=iOS Simulator,id=CC71613C-046E-4386-B24E-9512FD114884" -only-testing:OpenResponsesTests -parallel-testing-enabled NO -derivedDataPath <scratchpad>/DD27 CODE_SIGNING_ALLOWED=NO` (Xcode 27.0 27A266a, simulator "OpenResponses tests", iOS 27.0) on the uncommitted tree -> `Executed 296 tests, with 0 failures`, `** TEST SUCCEEDED **`; no warnings in app sources.
- ASC dry run of the copy update: description/whatsNew/reviewNotes "matches 9dd8e1d copy", keywords/promo "already new"; no hand edits.
- 9dd8e1d: GitHub CI run 36079930935 green (297 tests); Xcode Cloud run 46 SUCCEEDED, build 46 VALID.

## Blockers / Unknowns
- Reviewer findings pending at time of writing; address any verified defects before committing.
- GPT-Live 1 has never been exercised against the live service.
- Notion token in test.env was printed into the session log earlier; Gunnar should rotate it.

## Exact Next Action
Address reviewer findings, rerun the test command above, then commit and `gtimeout 120 git push origin main`; when Xcode Cloud build 47 is VALID, attach it to ASC version 2.7 and run `zsh -ic "python3 <scratchpad>/asc_27_update.py <scratchpad> $PWD write"`.
