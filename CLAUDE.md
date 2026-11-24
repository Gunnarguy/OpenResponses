@AGENTS.md

## Verify

Never on the "OpenResponses demo" simulator: the tests save and delete the Keychain `openAIKey`.

```bash
SIM=$(xcrun simctl list devices available | sed -n 's/.*OpenResponses tests (\([0-9A-F-]*\)).*/\1/p' | head -1)
xcodebuild test -project OpenResponses.xcodeproj -scheme OpenResponses -destination "id=$SIM" -derivedDataPath /private/tmp/openresponses-derived -only-testing:OpenResponsesTests
bash scripts/ui_tests.sh
python3 scripts/codemap.py check
```

## Ship

- iPhone or iPad (Debug build, installed and launched): `scripts/ship_device.sh` (first paired iPhone), `scripts/ship_device.sh ipad`, or `scripts/ship_device.sh <udid>`.
- Mac (native macOS): the build, archive and upload commands in `docs/share-shortcuts-mac.md` under "Mac"; Xcode Cloud's "Mac Release" workflow archives it on a push to `main` without `[ci skip]`.
- App Store: a push to `main` without `[ci skip]` starts an Xcode Cloud archive (workflow "Default"); `python3 scripts/asc/release.py` attaches and submits. Push only at Gunnar's word.
