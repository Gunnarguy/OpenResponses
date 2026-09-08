# OpenResponses App Store package

The current package is for **v2.6** and was reconciled with live ASC on September 8, 2026. Start with the [complete release dossier](docs/releases/v2.6/README.md).

- [Full What's New](docs/ReleaseNotes_2.6.0.md) and [detailed changelog](CHANGELOG.md).
- [Store metadata and paste-ready sources](docs/AppStoreMetadata.md).
- [App Review walkthrough](docs/AppReviewNotes.md).
- [TestFlight What to Test candidate](docs/releases/v2.6/TestFlightNotes.txt).
- [Release plan](docs/AppStoreReleasePlan.md) and [validation ledger](docs/releases/v2.6/Validation.md).
- [Live ASC/Xcode Cloud reconciliation](docs/releases/v2.6/ASCStatus.md).

ASC has **v2.5/build 4 released** and **v2.6 Prepare for Submission, no build selected**. Uploaded v2.6/build 38 maps to committed `bf5a783`, before the newer working-tree changes, and TestFlight reports missing export compliance. Preparing local text files does not publish them or attach a build.

The current browser is an on-device WKWebView. Live Assistants operations are retired; local JSON migration remains. Keys are stored in Keychain and transmitted for authentication. Old store-package claims about a required local browser bridge, every-click approval, hidden reasoning traces or keys never leaving the device are superseded by the linked source-grounded documentation.
