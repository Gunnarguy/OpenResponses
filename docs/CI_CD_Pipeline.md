# OpenResponses CI/CD and delivery evidence

**Verified:** September 8, 2026 against [the checked-in workflow](../.github/workflows/ci.yml) and the [live ASC/Xcode Cloud snapshot](releases/v2.6/ASCStatus.md).

## GitHub Actions

The repository currently contains `.github/workflows/ci.yml`, triggered by pushes and pull requests to `main`, with per-ref concurrency cancellation.

| Job | Actual checked-in behavior |
| --- | --- |
| Build & Test | macOS 26, Xcode 26.6 (17F113) pinned by the setup action, `xcodebuild test`, a dynamically selected available iPhone simulator, signing disabled. Executes unit/integration tests and uploads the xcresult bundle. |
| Lint | Installs/runs SwiftLint on macOS 26; lint step has `continue-on-error: true`. |
| Security Scan | Ubuntu scan for a specific API-key-shaped pattern in Swift/JSON. This is a narrow pattern check, not an exhaustive secret audit. |
| Docs Check | Requires README, LICENSE and PRIVACY files. It does not validate the complete release dossier or all Markdown links. |

Older documentation referring to active `ios-ci.yml`, `release-check.yml`, automatic UI-test execution or a complete metadata release lane is superseded by this table. No workflow implementation was changed during the documentation task.

## Local tests and device verification

The September 8 final local run executed **294 unit/integration tests**, zero failures, on the iPhone 16 Pro Max simulator using Xcode beta. Signed device validation is recorded separately. GitHub CI run 34267148194 (commit `5b270d8`, macOS 26 runner, Xcode 26.6, iPhone 17 Pro simulator on iOS 26.5) executed the same 294 tests with zero failures. The two preceding runs on the macOS 15 image (Xcode 26.3, iOS 26.2 simulator) crashed 29 tests in the Swift runtime's isolated-deinit hand-off when a `@MainActor` class was released from a synchronous test (swiftlang/swift#87316); the workflow now pins the release toolchain.

Use the [validation ledger](releases/v2.6/Validation.md) for the exact result, reproducible command shape and remaining manual checks. Choose an available simulator and keep DerivedData outside iCloud-backed Documents. Require final `TEST SUCCEEDED` / `BUILD SUCCEEDED`, not just a process that started.

## Xcode Cloud and uploaded builds

ASC's retained Cloud listing returned run **38**, source `bf5a783f7912b9e12f37e88e63c5c6891412eb94`, with a successful **Archive - iOS** action and a relationship to uploaded 2.6/build 38. No test action was returned. The run predates the completed working-tree implementation.

The local candidate now declares build 39; the previously uploaded Cloud binary is build 38. Record the delivery system's actual build number with the source SHA; do not assume local project numbering identifies the uploaded binary.

At inspection, build 38 was processed `VALID` but internal/external TestFlight states both reported `MISSING_EXPORT_COMPLIANCE`. The 2.6 App Store version had no build selected. An archive success does not imply review or public release.

## Release documentation workflow

Maintain [What's New](ReleaseNotes_2.6.0.md), [changelog](../CHANGELOG.md), [technical changes](releases/v2.6/TechnicalChanges.md), [validation](releases/v2.6/Validation.md), and [store copy](AppStoreMetadata.md) together. Before an upload, include intended untracked source and map the final candidate to its revision. After an upload, refresh the ASC record, eligibility, beta information and selected version build.

The text files under `fastlane/metadata` are local copy sources. Preparing or editing them does not run a deployment lane. The [release plan](AppStoreReleasePlan.md) lists remaining external actions and validation gates.
