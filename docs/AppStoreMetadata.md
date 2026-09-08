# OpenResponses 2.6: App Store metadata

**Prepared:** September 8, 2026. This document indexes the proposed local copy for the completed v2.6 update. The [live ASC reconciliation](releases/v2.6/ASCStatus.md) records what Apple currently stores. Preparing these files does not upload or publish them.

## Version and delivery status

| Field | Value / scope |
| --- | --- |
| App name / ID | OpenResponses / `6757338355`. |
| Bundle identifier | `Gunndamental.OpenResponses`. |
| Released ASC version | 2.5, uploaded build 4. |
| Next ASC version | 2.6, Prepare for Submission, no build selected. |
| Local project | Marketing version 2.6, build 39. |
| Latest uploaded binary | 2.6/build 38, September 2; matches committed `bf5a783`, before the later working-tree fixes. |
| Locale coverage in this package | `en-US`; no translations are implied. |
| Minimum OS in app/upload records | iOS 17.0. |

Price, territory availability, age rating, privacy questionnaire answers, export compliance and screenshots must be checked against the actual submission. Old documentation values are not treated as current account settings. The September 8 read-only check did not change any of these fields.

## Canonical copy files

The plain-text files are the source of truth for the prepared wording. The repository retains the `fastlane/metadata` layout as a convenient copy source; this does not select Fastlane as the active delivery system or imply an automatic upload.

| ASC field / use | Local source | Limit checked |
| --- | --- | --- |
| Name | [name.txt](../fastlane/metadata/en-US/name.txt) | 30 characters. |
| Proposed subtitle | [subtitle.txt](../fastlane/metadata/en-US/subtitle.txt) | 30 characters. |
| Promotional text | [promotional_text.txt](../fastlane/metadata/en-US/promotional_text.txt) | 170 characters. |
| Description | [description.txt](../fastlane/metadata/en-US/description.txt) | 4,000 characters. |
| What's New | [release_notes.txt](../fastlane/metadata/en-US/release_notes.txt) | 4,000 characters. |
| Keywords | [keywords.txt](../fastlane/metadata/en-US/keywords.txt) | 100 characters. |
| TestFlight What to Test candidate | [TestFlightNotes.txt](releases/v2.6/TestFlightNotes.txt) | Kept under 4,000 characters; separate beta-localization field. |
| Reviewer instructions | [review notes](../fastlane/metadata/review_information/notes.txt) | Private ASC review copy; no credentials in this file. |
| Combined paste/reference sheet | [AppStoreMetadata_Clean.txt](AppStoreMetadata_Clean.txt) | Generated from the copy files above; headings are not field content. |

The proposed subtitle is **Responses API & Voice Tools**. ASC currently has **GPT-5.X - Responses API**. The description and What's New now cover Astra/Sol/Terra/Luna, GPT Image 2, current voice, API Workbench, native orchestration, hosted MCP discovery, browser/search hardening, full Batch exports, reviewed training datasets, pagination and safe conversation persistence.

## What changed from the old store copy

The old local What's New described v2.0, while the old metadata guide described v1.0.1. ASC's v2.6 draft was more recent but still concentrated on early June development. The updated package removes stale current-feature claims about live Assistants threads/runs, automatic training from one chat, a required local browser bridge, and full account-wide conversation enumeration. It also replaces obsolete model/image defaults and qualifies account-dependent features.

The original ASC v2.5/v2.6 metadata is preserved in the dossier's [history folder](releases/v2.6/history/ASC-v2.5-en-US.json) and [2.6 snapshot](releases/v2.6/history/ASC-v2.6-en-US.json). The old July release-note draft is retained separately. These archives show what changed without treating earlier promotional statements as current verification.

## Data-flow language for copy and privacy review

Credentials are stored in Keychain, but the OpenAI key is transmitted to authenticate with OpenAI. Prompts, selected attachments and tool results are sent for requested processing. Optional remote storage is distinct from local conversation files and from provider retention. Hosted MCP can pass server credentials to OpenAI so its hosted client can authenticate. Browser automation uses the app's on-device WebKit store, not Safari or a mandatory network bridge.

Demo Mode is offline. Live access requires the user's API credentials and suitable account permissions/billing. Apple integrations and third-party connectors require their corresponding permissions/accounts. Do not use blanket claims such as “all data never leaves the device,” “all actions require a confirmation,” or “every diagnostic is guaranteed secret-free.” The app's disclosures, actual data flow and current privacy form must agree.

## Screenshot and preview coverage

Capture the actual release candidate with nonprivate demo/test data. Suggested coverage:

1. Chat with current model selection, streamed text and a readable activity/result card.
2. API Workbench with a harmless request and a complete-response export affordance.
3. Continuing voice mode with its listening/mute controls.
4. MCP discovery showing verified tools and schema detail without credentials.
5. Browser/search results showing a real page or useful source citations.
6. File indexing and Batch export or reviewed-dataset validation.

Verify the required device sizes and any iPad requirements in the current ASC submission UI. Do not reuse an old screenshot solely because its dimensions are accepted; its model names, controls and feature claims must still match. Broader accessibility checks remain on the [release plan](AppStoreReleasePlan.md).

## Reviewer and support package

Use the [full reviewer walkthrough](AppReviewNotes.md) and concise private review-copy file. Supply a working authorized reviewer API credential privately if live testing is needed; no credential has been embedded in this documentation. Existing reviewer contact files are preserved.

Existing [support URL](../fastlane/metadata/en-US/support_url.txt), [marketing URL](../fastlane/metadata/en-US/marketing_url.txt), [privacy URL](../fastlane/metadata/en-US/privacy_url.txt), category and copyright files remain their own metadata sources. Their continued presence does not verify the live endpoint content or ASC questionnaire answers.

## Support answers

- **Is 2.6 released?** Not at the September 8 check: v2.5 is released, and v2.6 is Prepare for Submission.
- **Does uploaded build 38 include all of these changes?** No. It maps to committed HEAD before the later working-tree fixes.
- **Does every account get every model/tool?** No. The app exposes supported request controls; account and service access remains authoritative.
- **Is MCP headless?** Discovery is hosted through OpenAI and needs no local MCP process/browser. The browser tool is a separate on-device WebKit execution path.
- **Can I train a model from one chat?** Chat export is a draft. The fine-tuning import requires a reviewed supported dataset, and account access is restricted.
- **Is remote history a complete cloud backup browser?** No. It hydrates remote IDs already known to the device.
- **Where is every code change documented?** Start with the [release dossier](releases/v2.6/README.md), [changelog](../CHANGELOG.md), [technical record](releases/v2.6/TechnicalChanges.md) and [129-file inventory](releases/v2.6/SourceInventory.md).
