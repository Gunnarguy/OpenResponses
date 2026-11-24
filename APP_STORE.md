# OpenResponses App Store package

> **Update 2026-11-23:** iOS 3.1 is live (approved November 23, 2026, build 57) with the OpenResponses Pro In-App Purchase approved; macOS 3.1, the first Mac version (build 60), was approved and is live the same day. Store text: `fastlane/metadata/en-US` (What's New `release_notes.txt`), reviewer notes `fastlane/metadata/review_information/notes.txt`, [3.1 release notes](docs/ReleaseNotes_3.1.0.md), [Pro](docs/pro-purchase.md).

> **Update 2026-11-20:** 3.0 is live (released November 20, 2026, build 56): [3.0 release notes](docs/ReleaseNotes_3.0.0.md).

> **Update 2026-10-02:** 2.9 is live (released October 2, 2026, build 54). The project now declares 3.0.

> **Update 2026-10-01:** 2.9 is submitted for review: [release notes](docs/ReleaseNotes_2.9.0.md), What's New and promotional text in `fastlane/metadata/en-US` (identical to App Store Connect). The description, keywords and URLs are unchanged from 2.8.

> **Update 2026-09-30:** 2.8 is live (released September 30, 2026, build 51, approved on the first submission with Local Python in it). The project now declares 2.9.

> **Update 2026-09-29:** 2.8 is prepared for review: [release notes](docs/ReleaseNotes_2.8.0.md), store copy in `fastlane/metadata/en-US` (rewritten to match the OpenIntelligence and OpenManual listings), [App Review notes](docs/AppReviewNotes.md). Marketing, support and privacy links move from GitHub to gunzino.me/openresponses/ with this version.

> **Update 2026-09-28:** 2.7 is live (released September 25, 2026, build 47), and 2.8 is in development with build 49 in App Store Connect. The notes below predate the 2.7 release.

> **Update 2026-09-24:** version 2.7 is being prepared: [release notes](docs/ReleaseNotes_2.7.0.md), store copy in `fastlane/metadata`, [TestFlight guide](docs/releases/v2.7/TestFlightNotes.txt). The project declares 2.7 and ASC has 2.7 in Prepare for Submission.

> **Update 2026-09-23:** 2.6 is live on the App Store (released 2026-09-09, per Apple's public lookup). The status below predates the release.

Below is the **v2.6** package as reconciled with live ASC on September 8, 2026, kept as a record; the updates above give the current state. Start with the [complete release dossier](docs/releases/v2.6/README.md).

- [Full What's New](docs/ReleaseNotes_2.6.0.md) and [detailed changelog](CHANGELOG.md).
- [Store metadata and paste-ready sources](docs/AppStoreMetadata.md).
- [App Review walkthrough](docs/AppReviewNotes.md).
- [TestFlight What to Test candidate](docs/releases/v2.6/TestFlightNotes.txt).
- [Release plan](docs/AppStoreReleasePlan.md) and [validation ledger](docs/releases/v2.6/Validation.md).
- [Live ASC/Xcode Cloud reconciliation](docs/releases/v2.6/ASCStatus.md).

ASC has **v2.5/build 4 released** and **v2.6 Prepare for Submission, no build selected**. Uploaded v2.6/build 38 maps to committed `bf5a783`, before the newer working-tree changes, and TestFlight reports missing export compliance. Preparing local text files does not publish them or attach a build.

The current browser is an on-device WKWebView. Live Assistants operations and the local JSON migration were removed in 2.7. Keys are stored in Keychain and transmitted for authentication. Old store-package claims about a required local browser bridge, every-click approval, hidden reasoning traces or keys never leaving the device are superseded by the linked source-grounded documentation.
