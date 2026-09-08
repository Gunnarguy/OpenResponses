# OpenResponses 2.6: validation ledger and known limits

Updated September 8, 2026. This ledger separates the latest local implementation checks, historical live probes, physical-device delivery and the previously inspected App Store Connect state.

## Latest implementation result

**294 unit/integration tests passed, zero failures, zero skipped** in `/tmp/OpenResponsesMCPReleaseTests.xcresult`. The final run used the iPhone 16 Pro Max simulator on **iOS 18.3**, with Xcode beta selected from `/Applications/Xcode-beta.app/Contents/Developer`. Test run duration is not an app performance benchmark.

The new coverage includes nine schema/Workbench-draft tests and 20 MCP authorization/account/registry tests beyond the earlier 265-test milestone. Earlier lifecycle fixtures now explicitly leave Demo Mode before testing live-response orchestration. A JSON image-cache fixture uses deterministic key ordering, and a WebKit fixture returns a serializable value after installing its forged-reference map. These fixture repairs preserve the behaviors the tests check.

| Area | Evidence and boundary |
| --- | --- |
| Schemas and literal JSON | Malformed JSON/schema roots, names, strict nested requirements and valid references/examples; validation before HTTP/SSE/socket setup. Simulator typing preserves straight quotes. |
| Workbench drafts | Restore invalid edits and all selectors; debounce/flush; failed write/read preservation. Actual simulator relaunch retained request text; replacement cancellation retained the body and selection. Invalid JSON was blocked locally. |
| OAuth | PKCE known vector, random verifier/state, callback mismatch/duplicates, issuer/resource boundaries, current/older metadata discovery, dynamic-registration validation and code exchange. |
| Account lifecycle | Rotation/omitted refresh tokens, invalid-grant reconnect state, atomic vault failures, refresh coalescing, disconnect during refresh, endpoint substitution and legacy migration. |
| Multi-account tools | Separate labels/endpoints/credentials/policies; missing accounts fail rather than reusing stale authorization. Catalog inspection and renaming preserve chat tool restrictions. |
| Registry | HTTPS remote filtering, inactive/stdio/template/credential-URL rejection, deduplication and pagination parsing. |
| Native orchestration | Existing current-model request, tool output, cancellation, replay, WebSocket and lifecycle coverage retained. |
| Browser | Real WebKit DOM/screenshot/input checks, reference expiry, navigation, cancellation, limits and process-recovery tests. |
| Voice | Audio conversion/playback and session-state tests. Physical acoustics remain account/device checks. |
| Files, Batch, fine-tuning, storage | Existing indexing, full-export, JSONL, pagination, safe deletion/save and persistence coverage retained. No paid job was started for the new tests. |

The final source includes the Info.plist resource-membership correction and a clear missing-key preflight for tool discovery. The signed device build includes the callback scheme and no duplicate-resource warning.

## Live OAuth compatibility and UI evidence

The app reached **Notion's actual login page** using the system authentication sheet. It offered the provider's normal sign-in methods; no provider password or OAuth access token was requested in the app. The account consent/token exchange was not completed with a real private account during this check.

Live dynamic-registration checks accepted `openresponses://mcp/oauth/callback` for **19 featured entries**. Twenty-three entries were probed for native registration in total; monday.com, Airtable, Intercom and Vercel rejected that registration configuration. Other entries requiring developer registration/approval are labeled accordingly. These outcomes are detailed in [MCP connections](../../mcp-connections.md) and the sanitized [compatibility evidence](MCPOAuthCompatibility.json). Registration acceptance does not prove private workspace access or provider tool behavior.

The current catalog has 44 entries plus live public-registry search. Actual simulator checks covered local catalog filtering, a live Notion registry query returning two remote listings, public DeepWiki connection creation, account naming and the default approval switch. [Connections screenshot](screenshots/Connections-iPhone.png) and [Notion login handoff](screenshots/Notion-Sign-In-iPhone.png) are actual simulator captures, not design mockups.

## Physical iPhone delivery — September 8

Version **2.6/build 39** was built and installed on **Gunnar's Hand Extension, iPhone 16 Pro Max**. The final build log records `BUILD SUCCEEDED` and installation returned success. An earlier build-39 iteration launched successfully (process 34882) and passed the six-file preservation check.

After the final missing-key message correction, installation succeeded again. After the user unlocked the phone, the final build launched successfully (process 35188).

Six existing conversation files were copied privately before installation and again after the preceding successful relaunch. **All six matched byte-for-byte**. The post-launch container contained seven files; the additional file does not replace any of the six originals. No conversation contents or filenames are published in this ledger.

The installed candidate's Info.plist contains the `openresponses` callback scheme and `ITSAppUsesNonExemptEncryption = false`. This declares the app's use of exempt/system encryption; it is not a claim that the app sends unencrypted traffic.

| Local artifact | Result |
| --- | --- |
| `/tmp/OpenResponsesMCPReleaseTests.xcresult` | 294 passed, no failures/skips. |
| `/tmp/openresponses-v26-mcp-device-build-final.log` | Final signed device build succeeded. |
| `/tmp/openresponses-mcp-install.json` | Installation success. |
| `/tmp/openresponses-mcp-launch.json` | Final build launched successfully after device unlock; process 35188. |
| `/tmp/openresponses-mcp-device-verification.json` | Version/build, callback/export metadata and six-file preservation summary. |
| [SourceSnapshot.json](SourceSnapshot.json) | Current implementation fingerprints. |
| [MCPOAuthCompatibility.json](MCPOAuthCompatibility.json) | Sanitized public-provider metadata and registration results. |

Temporary artifacts can be cleaned by the host. The results and their scope are preserved here. A signed Debug install is not an App Store distribution archive or an uploaded binary.

## Earlier milestones remain historical evidence

| Stage | Result | Reference |
| --- | --- | --- |
| API/native refresh | 204 tests and selected live API probes. | [API refresh](../../api-refresh-2026-09.md) |
| Headless MCP discovery | 221 tests; public DeepWiki discovery/cache. | [MCP discovery](../../mcp-discovery.md) |
| Browser/search hardening | 238 tests and public browser/search checks. | [Browser execution](../../browser-execution.md) |
| App reliability | 265 tests, 13 restored lifecycle cases and 14 additional regressions; four-file physical persistence check. | [Reliability](../../app-reliability-2026-09.md) |
| Schema/draft release pass | 274 tests and literal-editor/relaunch UI checks. | Current technical and upgrade guides. |
| OAuth/account redesign | **294 tests**, provider registration checks and signed build 39. | This ledger and [MCP connections](../../mcp-connections.md). |

Public DeepWiki previously returned three tools in 2.37 seconds; the actual Swift service returned three in 1.48 seconds and then used cache without a second HTTP request. Those public-server checks do not establish private OAuth access. Earlier hosted-search verification retained 19 sources and an IANA citation after removing an unsupported parameter. Browser capture verification checked a real 440×956 image against the previous 1320×2868 mismatch. Recorded timings are individual probes, not latency guarantees.

Earlier Realtime evidence includes a two-turn synthetic VAD exchange. It does not establish sustained speaker echo cancellation, every Bluetooth route, interruptions or lock/background behavior on all devices.

## Distribution and CI boundary

The last ASC inspection on September 8 reported v2.5/build 4 released; v2.6 Prepare for Submission with no selected build; and uploaded v2.6/build 38 mapped to committed `bf5a783`, excluding the later working-tree changes. TestFlight reported missing export compliance for build 38. The retained Xcode Cloud run had one successful archive action and no test action. See [ASC reconciliation](ASCStatus.md).

GitHub CI has been updated locally to select an available iPhone simulator, execute `xcodebuild test -only-testing:OpenResponsesTests`, and retain its xcresult bundle. The edited workflow has not yet been committed/pushed/run remotely. The local pass is not evidence of a GitHub or Xcode Cloud test run.

The user authorized committing, pushing and uploading this candidate to App Store Connect on September 8 after the final checks. Delivery is proceeding through the main-branch Xcode Cloud workflow. The ASC snapshot below predates that delivery; upload and processing must be verified separately.

## Remaining release checks

- Real private-account consent, discovery, permission checks and refresh for the intended supported providers.
- OpenResponses-owned provider registrations/approvals and redirect arrangements for the explicitly unavailable catalog entries. A server-owned component is required where a shared confidential-client secret is necessary.
- Sustained physical voice/acoustic checks, Bluetooth and interruptions; broader iPad, Dynamic Type and VoiceOver checks.
- Site-specific authenticated browser flows and recovery after uncertain side effects; CAPTCHAs, restricted frames and native inputs remain explicit limits.
- Optional live indexing/Batch/fine-tuning admission for release scenarios; tests do not grant service eligibility.
- Final source commit, archive, uploaded build, export compliance, beta notes, current screenshots, reviewer access, selected App Store build and review/release state.

## Repeating checks and documentation verification

Use the chosen available simulator ID with `xcodebuild test -project OpenResponses.xcodeproj -scheme OpenResponses -destination 'platform=iOS Simulator,id=SIMULATOR_UDID' -only-testing:OpenResponsesTests -parallel-testing-enabled NO`, keeping DerivedData outside iCloud-backed Documents. Record the exact final result and source revision. Repeat implementation checks when relevant code changes, rather than treating a command launch as success.

[DocumentationVerification.json](DocumentationVerification.json) records resolved relative links, store-copy lengths, JSON parsing, source fingerprints and `git diff --check`. Pattern scanning is not an exhaustive secret audit. Historical ASC and milestone snapshots retain their own dates and are not silently relabeled as current uploads.
