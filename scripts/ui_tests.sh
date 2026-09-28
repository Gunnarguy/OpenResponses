#!/bin/bash
# Runs the UI and accessibility tests from a fresh install, so chats left by earlier runs do not change what
# the audits see. Uses the repo's own simulator ("OpenResponses tests"); simulators are shared between sessions.
# Usage: bash scripts/ui_tests.sh [simulator-udid]
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
SIM="${1:-$(xcrun simctl list devices available | sed -n 's/.*OpenResponses tests (\([0-9A-F-]*\)).*/\1/p' | head -1)}"
[ -n "$SIM" ] || { echo "No 'OpenResponses tests' simulator. Create one: xcrun simctl create \"OpenResponses tests\" \"iPhone 18 Pro\" com.apple.CoreSimulator.SimRuntime.iOS-27-0"; exit 1; }
xcrun simctl boot "$SIM" 2>/dev/null || true
xcrun simctl uninstall "$SIM" Gunndamental.OpenResponses 2>/dev/null || true
DERIVED="${TMPDIR:-/tmp}/openresponses-derived" # outside iCloud
xcodebuild test -project OpenResponses.xcodeproj -scheme OpenResponses \
  -destination "platform=iOS Simulator,id=$SIM" -only-testing:OpenResponsesUITests/OpenResponsesUITests \
  -parallel-testing-enabled NO -derivedDataPath "$DERIVED" CODE_SIGNING_ALLOWED=NO
