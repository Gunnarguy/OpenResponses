# OpenResponses 2.6 release dossier

**Prepared:** September 8, 2026 · **Xcode marketing version:** 2.6 · **Build:** 39

This is the complete release documentation for the v2.5 → v2.6 source transition, including the June/July development and the September API, voice, MCP, browser, and reliability work. “2.6.0” is the existing release-document/tag spelling; the app's actual marketing version is `2.6`.

## Start here

| Document | Audience and purpose |
| --- | --- |
| [What's new / full release notes](../../ReleaseNotes_2.6.0.md) | User-facing explanation of the complete update. |
| [Changelog](../../../CHANGELOG.md) | Categorized, detailed record of additions, changes, fixes, and retained behavior. |
| [MCP accounts, OAuth and provider availability](../../mcp-connections.md) | Complete connection redesign, migration, security contracts, catalog and remaining provider registrations. |
| [Technical changes](TechnicalChanges.md) | API contracts, execution paths, settings, persistence, boundaries, and source pointers. |
| [Upgrade and feature guide](UpgradeGuide.md) | How to use the changes and what happens to existing settings and conversations. |
| [Validation and known limits](Validation.md) | Tests, live probes, device delivery, evidence boundaries, remaining checks, and documentation verification. |
| [Live App Store Connect reconciliation](ASCStatus.md) | Released/draft versions, Cloud source mapping, upload and TestFlight status. |
| [Source inventory](SourceInventory.md) | Every changed/added app, test, and Xcode-project file in the comparison, plus development chronology. |
| [App Store metadata](../../AppStoreMetadata.md) | Current local store description, promotional copy, and What's New source locations. |
| [App Review walkthrough](../../AppReviewNotes.md) | Accurate reviewer steps and data-flow explanations. |
| [Release plan](../../AppStoreReleasePlan.md) | What is verified locally and what still requires distribution verification. |
| [TestFlight What to Test](TestFlightNotes.txt) | Prepared beta test instructions and known limits. |
| [Plain-text What's New](../../../fastlane/metadata/en-US/release_notes.txt) | Ready to paste into the App Store Connect version record. |

## Exact comparison baseline

The primary source baseline is `855ab3b4aac8f19b487757c269e2e0a20d2cbb02`, the parent of `e77e889` (“Version 2.6 Staging”, June 25, 2026). Both app configurations at that baseline declare marketing version **2.5**, build **7**. The staging commit changes those values to **2.6**, build **8**.

The earlier version-bump commit is `de7df81` (“Bump version to 2.5 and build to 7”, June 19). Fixes committed between that bump and the last 2.5 source state are recorded separately in the inventory chronology. This avoids accidentally describing work already in the final 2.5 source state as newly introduced by 2.6. Live ASC confirms released v2.5 used uploaded build **4** on June 19, while the local source declares build **7**. The retained Cloud records do not identify that released build’s exact source SHA. The inventory separately records the ten commits between the June 19 source bump and June 25 baseline, so post-upload/pre-staging work is not lost.

The target is committed HEAD `bf5a783f7912b9e12f37e88e63c5c6891412eb94` **plus the current September working-tree changes**, including new files. There are 57 reachable commits after the primary baseline and 129 changed/added app, test, and project files in the documented implementation snapshot. Counts describe source coverage, not a count of new features or a performance measurement.

The existing `v2.6.0` tag resolves to `1e2eddab803847ed432c9e274933db35fb90b1db` from July 10. It does not contain the completed September update. It has not been moved. The previous small [July release-note draft](history/JulyReleaseNotes.md) is retained as historical context; its old verification statements are not evidence for the present build.

## Release status

The September 8 release and MCP account pass passed **294 unit/integration tests**. The current signed candidate is version 2.6/build 39. Earlier device installations preserved existing conversations; the latest device result and exact boundaries are in [validation](Validation.md). The user authorized release delivery on September 8. Provider registration and account-level limitations remain documented.

Live ASC on September 8 reports **v2.5/build 4 released**, **v2.6 Prepare for Submission with no build selected**, and latest uploaded **v2.6/build 38**. Xcode Cloud maps build 38 to committed HEAD `bf5a783` with a successful archive. It excludes the newer working-tree changes; TestFlight reports missing export compliance. See [ASC reconciliation](ASCStatus.md).

**Delivery update:** version 2.6/build 39 uploaded successfully using stable Xcode, and ASC metadata was updated. Apple processing was pending at the receipt. See [delivery evidence](Delivery.md); the ASC figures above remain the pre-delivery snapshot.

**Released:** App Store Connect on September 8 (evening Pacific) reports 2.6 `READY_FOR_SALE` with build **41**, the Xcode Cloud run 41 archive of `5b270d8` uploaded at 12:14 Pacific; the public store lookup shows the release at 2026-09-09T01:59:47Z. Build 41 supersedes the build 39 candidate described above with the same app source.

## Scope at a glance

| Area | Position in 2.5 → 2.6 |
| --- | --- |
| Models and request controls | Earlier GPT-5.6 integration expanded into a shared Astra/Sol/Terra/Luna catalog and stricter model-aware request construction. |
| Native orchestration | New current-model foreground runner, async/programmatic calls, custom text tools, multi-agent WebSocket result injection, and recovery state. |
| API Workbench | New raw HTTP/SSE/WebSocket playground, token counting, compaction, steering, continuation, and full response export. |
| Voice | New Realtime/recorder surfaces in the development cycle, followed by multi-turn capture/playback fixes and current session schemas. |
| MCP | Unified account library, native OAuth sign-in, 44 catalog entries, live registry search, multiple selected accounts, secure refresh and bounded OpenAI-hosted tool discovery. |
| Browser and web search | Existing tools made more reliable; shared execution lane, accurate pixels, element refs, deadlines, and corrected hosted-search payloads. |
| Conversations and observability | Remote hydration, richer artifacts/timelines, complete compaction state, safe chat switching/deletion, and background persistence. |
| Files, Batch, fine-tuning | New developer-lab surfaces completed with honest indexing state, full exports, validated datasets, and pagination. |
| Apple/Notion integrations | Existing integrations retained; concurrency/date-handling work and Notion pagination improved. |
| Quality and release operations | Broader tests, restored lifecycle coverage, documentation repair, and explicit separation of local verification from distribution. |

## Maintaining this record

For another 2.6 change, update the changelog and technical section first, then adjust user-facing/store copy if the behavior is visible. Add the associated test or validation result with its date and scope. Keep historical milestone counts separate from the latest total. Before distribution, verify the chosen source revision, untracked-file inclusion, version/build values, archive, and App Store Connect state rather than assuming the old tag represents the finished release.
