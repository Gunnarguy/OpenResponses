#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v fastlane >/dev/null 2>&1; then
  echo "fastlane is not installed. Install with: brew install fastlane" >&2
  exit 1
fi

if [[ -z "${APP_STORE_CONNECT_API_KEY_ID:-}" && -z "${FASTLANE_USER:-}" ]]; then
  echo "No auth configured. Set FASTLANE_USER for Apple ID login or APP_STORE_CONNECT_API_KEY_ID/ISSUER_ID/API_KEY_PATH for API key auth." >&2
fi

python3 "$ROOT/scripts/sync_app_store_metadata.py"

fastlane metadata
