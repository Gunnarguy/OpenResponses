#!/bin/bash
# Minimal release preflight: confirm privacy usage strings exist and re-run the secret scanner.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_FILE="$ROOT_DIR/OpenResponses.xcodeproj/project.pbxproj"

REQUIRED_KEYS=(
  "INFOPLIST_KEY_NSPhotoLibraryUsageDescription"
  "INFOPLIST_KEY_NSLocalNetworkUsageDescription"
  "INFOPLIST_KEY_NSDocumentsFolderUsageDescription"
  "INFOPLIST_KEY_NSFilesystemUsageDescription"
  "INFOPLIST_KEY_NSCalendarsUsageDescription"
  "INFOPLIST_KEY_NSContactsUsageDescription"
  "INFOPLIST_KEY_NSRemindersUsageDescription"
)

missing_keys=()
for key in "${REQUIRED_KEYS[@]}"; do
  if ! grep -q "$key" "$PROJECT_FILE"; then
    missing_keys+=("$key")
  fi
done

if [[ ${#missing_keys[@]} -gt 0 ]]; then
  echo "❌ Missing expected Info.plist usage descriptions:"
  printf '  - %s\n' "${missing_keys[@]}"
  exit 1
fi

echo "✅ Required Info.plist usage descriptions present."

# Run the secret scanner as part of the preflight bundle.
python3 "$ROOT_DIR/scripts/secret_scan.py"
