# OpenResponses 2.6 release plan

**Reconciled:** September 8, 2026 against the working tree, final local test/device artifacts, and live App Store Connect/Xcode Cloud records.

## Current position

The completed implementation is locally **2.6/build 39**, with 294 passing tests and signed iPhone build verification. MCP provider setup and account-level checks remain release dependencies. The user authorized committing, pushing and uploading the completed September implementation on September 8. The historical July `v2.6.0` tag is incomplete.

ASC currently releases **2.5/build 4**. Its 2.6 version is **Prepare for Submission with no build selected**. Latest uploaded **2.6/build 38** has a successful Cloud archive mapped to `bf5a783`, but excludes the later working-tree updates. Both TestFlight states report **missing export compliance**. Its beta What's New is empty. See the [ASC snapshot and explanation](releases/v2.6/ASCStatus.md).

## Verified and prepared

- [x] Identify the last source labeled v2.5 and document the uncertain exact source SHA of the shipped v2.5 binary.
- [x] Inventory 129 app/test/project files and retain source hashes, 57 post-baseline commits, and the late pre-staging interval.
- [x] Record latest local 294-test result, signed build 39, device installation/launch and preservation of six existing conversation files.
- [x] Query live ASC version/build/localization and retained Cloud records using existing credentials without exposing secrets.
- [x] Prepare full release notes, technical changes, upgrade guide, validation ledger, store copy, beta test guide and reviewer walkthrough.
- [x] Preserve old July/ASC copy as clearly labeled history.

## Required before distribution

- [ ] Review/include intended dirty and untracked implementation files in a release source revision; do not ship only the old tag or committed HEAD.
- [ ] Confirm the actual uploaded build number for the next candidate. The local candidate is build 39; uploaded build 38 already exists. Confirm the number assigned by the chosen delivery path.
- [ ] Execute appropriate tests for the final implementation revision and record results with that SHA. The local suite passes 294 tests; the updated GitHub test workflow must also run on the final pushed revision.
- [ ] Archive/upload the completed revision; verify Cloud action status, processing, binary version and source mapping.
- [ ] Resolve the actual export-compliance questions for that binary and verify TestFlight eligibility.
- [ ] Supply beta What to Test and authorized reviewer access; confirm no private key/token appears in public metadata or screenshots.
- [ ] Perform the remaining physical voice/audio-route, private MCP, browser-site and broader accessibility/device checks relevant to release scope.
- [ ] Verify current screenshots, privacy disclosures/questionnaire, rating, territories, pricing and support links in ASC.
- [ ] Synchronize reviewed 2.6 description, subtitle, promotional text, keywords, What's New and review notes from the prepared sources.
- [ ] Select the verified completed build for the 2.6 version, inspect all submission requirements and submit when authorized.
- [ ] Record Apple's actual review state and release outcome. `AFTER_APPROVAL` is the current configured release mode, not a completed approval.

## Delivery rules

A local build proves compilation; an install and launch prove device delivery; a successful Cloud archive proves that run; `VALID` upload processing does not prove release eligibility. Metadata edits, build selection, TestFlight distribution, review submission and public release are separate actions. This documentation task inspected ASC read-only and prepared local copy; it did not perform those external changes.

Do not overwrite the historical `v2.6.0` tag to make the record appear current. Choose the intended release revision explicitly and document how it relates to the old tag. Preserve unrelated working-tree changes while preparing it.

## Documentation and evidence

- [Release dossier](releases/v2.6/README.md) and [full What's New](ReleaseNotes_2.6.0.md).
- [Validation ledger](releases/v2.6/Validation.md), [source inventory](releases/v2.6/SourceInventory.md) and [ASC reconciliation](releases/v2.6/ASCStatus.md).
- [Metadata sources](AppStoreMetadata.md), [reviewer guide](AppReviewNotes.md) and [CI/CD behavior](CI_CD_Pipeline.md).

Refresh this checklist when the source, candidate or ASC state changes. Do not carry forward old “TestFlight queued,” “all UI tests passed,” or “release complete” claims without new evidence.
