# Current State

Updated: 2026-09-08
Branch/worktree: main in the repo root. The diagnostic branch `ci/toolchain-matrix` and its worktree were deleted after the matrix run finished.
Last verified commit: 5b270d8 ci: run tests on macos-26 with Xcode 26.6

## Objective
Make the GitHub CI workflow green for the v2.6 App Store submission (runs 34261694919 and 34262928247 on main failed), and establish whether the crash behind those failures can reach the shipped build (2.6, archived with Xcode 26.6, deployment target iOS 17).

## Status
Complete. CI run 34267148194 on commit 5b270d8 passed all 294 tests (macOS 26 runner, Xcode 26.6, iPhone 17 Pro simulator on iOS 26.5). The docs commit that records this (docs/CI_CD_Pipeline.md, docs/releases/v2.6/Validation.md, this file) is committed locally and NOT pushed: every push to main starts an Xcode Cloud archive (Gunnar received a "build 41 completed" ASC notification minutes after the 19:07 UTC push of 5b270d8), and he had not asked for another build.

## Completed
- Root cause: on the `macos-15` image (Xcode 26.3, iOS 26.2 simulator) 29 tests crashed with `malloc: pointer being freed was not allocated`, stack `<Class>.__deallocating_deinit -> swift_task_deinitOnExecutorMainActorBackDeploy -> libswift_Concurrency swift_task_deinitOnExecutorImpl -> TaskLocal::StopLookupScope::~StopLookupScope -> abort` (swiftlang/swift#87316). Trigger: a `@MainActor` class released from a synchronous XCTest method while XCTest has a task-local bound outside any task.
- Fix (5b270d8): `.github/workflows/ci.yml` Build & Test and Lint jobs run on `macos-26`; Xcode pinned to `26.6` instead of `latest-stable`.
- Matrix run 34267002652 (macOS 26 image): Xcode 26.3 / iOS 26.5 passed 294; Xcode 26.6 / iOS 26.5 passed 294; Xcode 26.6 / iOS 26.4 executed 294 with one unrelated failure (`BrowserLiveSiteTests.testExampleAndIANAWithHistory`, WebKit `InvalidTransition`, live network); Xcode 26.6 / iOS 26.2 aborted with the same crash (eight restarts). The defect is in the iOS 26.2 simulator runtime, reachable from the shipping toolchain.

## Active Constraints
- No attribution trailers in commits. Commits go straight to main. Pushing main triggers an Xcode Cloud archive; say so before pushing and do not push docs-only changes without Gunnar's go-ahead.
- `.claude/` in the repo root is untracked user-local settings; do not commit it.
- Build and test with DerivedData outside iCloud-synced `~/Documents`; wrap git in `gtimeout 60`.
- Never report a run as green without reading its output (`gh run view <id>`).
- 2026-09-08 decision (no decisions log exists in this repo yet; move it when one does): CI pins the archive toolchain rather than tracking `latest-stable`, because runner-image toolchain drift produced a spurious red run. Bump the pin together with the Xcode used for the archive.

## Working Set
- `.github/workflows/ci.yml`: the committed fix; the comment above `runs-on` explains why.
- `docs/CI_CD_Pipeline.md` and `docs/releases/v2.6/Validation.md`: record the failed runs, the green run, and the matrix; Validation.md's "Remaining release checks" carries the isolated-deinit exposure item.
- Session-only artifacts (may be gone): `/private/tmp/claude-501/-Users-gunnarhostetler-Documents-GitHub-OpenResponses/fc8868b2-038d-4296-a7b7-db1c465206ae/scratchpad/` with the downloaded `TestResults.xcresult` from run 34262928247 (crash reports under `attach/*.ips`), `LocalTest26.xcresult`, `local_test_26.log`, matrix cell logs `cell_*_clean.txt`, `DerivedData`.

## Verification
- `gh run view 34267148194 --json conclusion,status` -> `conclusion=success status=completed`; job log: `Executed 294 tests, with 0 failures (0 unexpected)`, `** TEST SUCCEEDED **`, no "Restarting after unexpected exit".
- `gh run view 34262928247 --log` -> `** TEST FAILED **`; xcresult summary 96 attempted, 67 passed, 29 failed, "Exceeded max restart count of 2"; 25 `.ips` reports, all `EXC_CRASH SIGABRT` with the stack above.
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project OpenResponses.xcodeproj -scheme OpenResponses -destination "platform=iOS Simulator,id=DA9536BA-F048-4352-92AA-66A7E1A464BA" -only-testing:OpenResponsesTests -parallel-testing-enabled NO -derivedDataPath <scratchpad>/DerivedData -resultBundlePath <scratchpad>/LocalTest26.xcresult CODE_SIGNING_ALLOWED=NO` (Xcode 26.6 17F113, iPhone 17 Pro, iOS 26.5) -> `Executed 294 tests, with 0 failures`, `** TEST SUCCEEDED **`.
- Matrix job logs via `gh api repos/Gunnarguy/OpenResponses/actions/jobs/<id>/logs`: 102198762271 (26.3/26.5) `Executed 294 tests, with 0 failures`; 102198762373 (26.6/26.5) same; 102198762264 (26.6/26.4) `Executed 294 tests, with 1 failure`; 102198762418 (26.6/26.2) `** TEST FAILED **`, 8 "Restarting after unexpected exit", 9 malloc errors.
- `nm OpenResponses.debug.dylib | xcrun swift-demangle | grep -c __isolated_deallocating_deinit` (local Xcode 26.6 build) -> 52; `otool -tv` of `_swift_task_deinitOnExecutorMainActorBackDeploy` -> `_stdlib_isOSVersionAtLeast(18, 4, 0)` then `bl _swift_task_deinitOnExecutor`.
- `grep -rn "@TaskLocal" OpenResponses/` -> 0 uses.

## Blockers / Unknowns
- Production exposure of the isolated-deinit abort on device runtimes between iOS 18.4 and 26.3 is unmeasured. Condition: a `@MainActor` object released outside a Swift task while a task-local is bound on that thread. Only XCTest has been observed to create that state. Mitigation, if Gunnar wants it: explicit `nonisolated deinit {}` in the `@MainActor` classes (the crash reports named OpenAIService, APIWorkbenchDraftStore, ResponsesAPIClient, MCPAuthorizationClient, MCPConnectionStore, APIWorkbenchSession), then rerun the local command above.
- `BrowserLiveSiteTests.testExampleAndIANAWithHistory` needs the real network and WebKit; it failed once on the iOS 26.4 simulator and passed on 26.5. CI uses 26.5 today.

## Exact Next Action
`gtimeout 120 git push origin main` once Gunnar confirms that one more Xcode Cloud archive is acceptable; the local commit ahead of origin contains only docs/CI_CD_Pipeline.md, docs/releases/v2.6/Validation.md and docs/ai/STATE.md. If he declines, leave the commit local; nothing else is pending.
