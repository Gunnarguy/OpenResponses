# OpenResponses 2.6: App Store Connect reconciliation

**Later delivery:** build 39 uploaded successfully and store metadata was updated on September 8. See the [delivery receipt](Delivery.md). The snapshot below predates that upload.

**Read-only inspection:** September 8, 2026. The timestamped, selected API fields are retained in [ASC-Snapshot.json](ASC-Snapshot.json). Credentials were loaded from the existing local configuration; no key material, JWTs, reviewer credentials or contact details are included in this dossier. This inspection made GET requests only.

## What Apple currently has

| Record | Live result |
| --- | --- |
| App | OpenResponses, `6757338355`, bundle `Gunndamental.OpenResponses`. |
| Released version | **2.5**, `READY_FOR_DISTRIBUTION` (legacy field: `READY_FOR_SALE`). |
| Released 2.5 build | **4**, uploaded June 19, 2026 at 21:08:46 Pacific; build ID `d6f79902-8ce2-48d5-82c4-e29770559ab9`. |
| Next version | **2.6**, `PREPARE_FOR_SUBMISSION`, created June 25. |
| Build selected for 2.6 submission | **None**. |
| Release setting for 2.6 | `AFTER_APPROVAL`; this is a setting, not evidence that approval occurred. |
| Uploaded 2.6 builds | 23 returned, numbered 9 through 38 with gaps. See the snapshot for each upload. |
| Latest uploaded 2.6 build | **38**, uploaded September 2 at 09:54:49 Pacific; processing `VALID`, not expired at inspection. |
| Latest build's TestFlight states | Internal and external both `MISSING_EXPORT_COMPLIANCE`; encryption declaration value is unset. |
| Latest build's beta What's New | No beta localization records returned. |
| Version localizations | One `en-US` localization each for 2.5 and 2.6. |
| Current subtitle | `GPT-5.X - Responses API` in the returned app-info localizations. |
| Reviewer setup | No demo account required; reviewer notes present. Credential contents were not copied into the release record. |

The App Store version record, uploaded binary, TestFlight state and Xcode Cloud run are separate objects. `VALID` means processing succeeded; it does not mean the build is selected for release, available to testers, approved, or published.

## Source-to-upload evidence

The returned Xcode Cloud product is `02676c39-e39d-49e8-af7f-412bc7c32473`. Its retained build-run listing returned one run: **38**, ID `708ca5ce-69d3-409e-bd44-7344e5f91a07`, completed `SUCCEEDED`. Its **Archive - iOS** action also completed `SUCCEEDED` and its build relationship points to uploaded build 38 (`055415b9-3e51-476d-a80b-bae53d2b5ef2`).

Apple reports the source commit as:

```text
bf5a783f7912b9e12f37e88e63c5c6891412eb94
```

That is the repository's current committed HEAD. The later September API, voice, MCP, browser and reliability edits are still in the working tree, including untracked source files. Consequently **uploaded build 38 does not contain those working-tree changes**. Its successful archive is useful historical distribution evidence, but it is not the archive of the completed update described by this dossier.

No test action was returned for this retained run. Its archive success therefore does not establish that Xcode Cloud executed the locally recorded 265 tests.

The September 8 candidate now declares 2.6/build 39. The previously inspected Cloud upload declares 2.6/build 38. Similarly, the last local v2.5 source declares build 7 while the released upload used build 4. Do not equate the local build-setting number with the uploaded Cloud build number. Before the next upload, confirm the delivery system's assigned build number is valid for the existing version train.

The retained Cloud listing did not identify the source commit for released 2.5/build 4. Its June 19 upload date narrows the release history, but does not prove an exact Git SHA. The [inventory](SourceInventory.md) therefore includes a separate June 19–25 source interval as well as the primary last-v2.5-source comparison.

## Stored copy versus the completed update

The original API-returned text is preserved in:

- [Released 2.5 en-US metadata](history/ASC-v2.5-en-US.json).
- [Existing 2.6 en-US draft metadata](history/ASC-v2.6-en-US.json).

These are **historical snapshots of ASC**, not the proposed new copy. The 2.5 notes describe performance, URL/stream recovery, diagnostics redaction and GPT-5.5 additions. The existing 2.6 notes mainly describe the June API/developer-lab/concurrency work. They still advertise live Assistants migration support ahead of a sunset that has now passed. The shared description lists older model/image defaults and does not cover the new Workbench, modern orchestration, completed browser/MCP hardening or latest persistence fixes. Its promotional text also promotes legacy live threads.

Corrected local candidates now live in [App Store metadata](../../AppStoreMetadata.md), [What's New](../../../fastlane/metadata/en-US/release_notes.txt), [description](../../../fastlane/metadata/en-US/description.txt), [App Review notes](../../AppReviewNotes.md), and [TestFlight notes](TestFlightNotes.txt). They have **not** been uploaded by this documentation task. The beta copy is a preparation artifact; adding the file does not imply any deployment lane consumes it automatically.

## Required distribution follow-through

1. Include all intended implementation and documentation files in a reviewed source revision; the old July tag is incomplete.
2. Build/archive that revision and record its source SHA and actual uploaded build number.
3. Verify processing and resolve the real export-compliance questions for that binary. No declaration was submitted during this read-only check.
4. Verify TestFlight eligibility and attach the appropriate beta test information. Current build 38 has no beta What's New records.
5. Synchronize the reviewed 2.6 metadata/reviewer copy and choose the correct completed build for the version.
6. Recheck screenshots, privacy answers, feature/account access, review status and release controls before submission.

For API semantics, see Apple's [build resources](https://developer.apple.com/documentation/appstoreconnectapi/builds), [Xcode Cloud build runs](https://developer.apple.com/documentation/appstoreconnectapi/build-runs), and [version localizations](https://developer.apple.com/documentation/appstoreconnectapi/get-v1-appstoreversions-_id_-appstoreversionlocalizations). Account-specific results above come from the authenticated September 8 snapshot, not those public reference pages.
