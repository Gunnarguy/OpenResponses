# v2.6 delivery — September 8, 2026

The complete release implementation was committed as `deeaf2d144c5894b2624a626abf94f830ae88a8d` and pushed to `main`. This follow-up commit adds the stable Swift compiler workaround and records the successful upload.

- **App Store Connect:** version **2.6**, build **39** uploaded successfully at **18:23:53 UTC**. Xcode reported `Upload succeeded`, `Uploaded OpenResponses`, and `EXPORT SUCCEEDED`. Apple processing was still pending at this receipt; this is not App Review submission or public release confirmation.
- **Archive:** signed Release archive built with stable **Xcode 26.6 (17F113)**. `/tmp/OpenResponsesV26Stable.xcarchive`; build log `/tmp/openresponses-v26-stable-archive.log`; upload log `/tmp/openresponses-v26-stable-upload.log`.
- **Store metadata:** description, keywords, promotional text, What's New, subtitle and review notes uploaded successfully. Release metadata was read back and matched the committed files.
- **Validation:** 294 tests passed before delivery. All eight browser execution regression tests passed after the compiler workaround. Final device build 39 launched successfully after unlock (process 35188); all six original conversation files remained byte-identical after installation.
- **Compiler workaround:** Cloud run 39 crashed in Swift 6.3.3 while optimizing the synthesized generic `BrowserCallback` destructor. An explicit destructor with optimization disabled avoids the compiler crash. Stable Release archiving passed afterward. A preceding local beta-Xcode upload was rejected for unsupported SDK; the successful upload uses the stable SDK.

The source inventory includes the final browser source fingerprint. The older [ASC snapshot](ASCStatus.md) remains historical. Provider registration requirements and account-level verification limits remain documented in [MCP connections](../../mcp-connections.md).

## Release

**September 8, evening Pacific:** App Store Connect reports version 2.6 `READY_FOR_SALE` with build **41**, produced by Xcode Cloud run 41 from commit `5b270d8` and uploaded at 12:14 Pacific, after run 40 (`3801465`, build 40) and the failed run 39 (`deeaf2d`). The public store lookup carries a release timestamp of 2026-09-09T01:59:47Z. Build 41 shipped instead of the locally archived build 39; both are the completed 2.6 app source.
