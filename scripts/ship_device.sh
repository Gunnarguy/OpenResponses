#!/bin/zsh
# Build OpenResponses (Debug) and install it on a paired iPhone or iPad, then launch it.
#
#   scripts/ship_device.sh            the first paired iPhone
#   scripts/ship_device.sh ipad       the first paired iPad
#   scripts/ship_device.sh <udid>     that device
#
# Builds outside ~/Documents (an in-place build picks up a FinderInfo xattr and codesign fails).
# A locked device gets the install but not the launch; the script says so and exits 0.
set -euo pipefail

repo="${0:A:h:h}"
want="${1:-iphone}"
derived="/private/tmp/openresponses-device-dd"
bundle="Gunndamental.OpenResponses"

devices="$(xcrun devicectl list devices 2>/dev/null)"
case "$want" in
  iphone) udid="$(print -r -- "$devices" | awk '/available \(paired\)/ && /iPhone/ && /physical/ {for(i=1;i<=NF;i++) if ($i ~ /^[0-9A-F]{8}-[0-9A-F]{16}$/) {print $i; exit}}')" ;;
  ipad)   udid="$(print -r -- "$devices" | awk '/available \(paired\)/ && /iPad/ && /physical/ {for(i=1;i<=NF;i++) if ($i ~ /^[0-9A-F]{8}-[0-9A-F]{16}$/) {print $i; exit}}')" ;;
  *)      udid="$want" ;;
esac
if [[ -z "${udid:-}" ]]; then
  print -u2 "No paired $want is available. xcrun devicectl list devices:"
  print -u2 -r -- "$devices"
  exit 1
fi
print "Device: $udid"

# Signing in to Xcode is not required: with the App Store Connect API key exported by ~/.zshrc
# (run this script through `zsh -ic` from a non-interactive shell) xcodebuild registers App IDs,
# the App Group and profiles itself. The key's values are passed by path and ID, never printed.
auth=()
if [[ -n "${APP_STORE_CONNECT_API_KEY_PATH:-}" && -n "${APP_STORE_CONNECT_API_KEY_ID:-}" && -n "${APP_STORE_CONNECT_ISSUER_ID:-}" ]]; then
  auth=(-authenticationKeyPath "$APP_STORE_CONNECT_API_KEY_PATH" -authenticationKeyID "$APP_STORE_CONNECT_API_KEY_ID" -authenticationKeyIssuerID "$APP_STORE_CONNECT_ISSUER_ID")
fi

log="$(mktemp -t openresponses-device-build).log"
start=$SECONDS
setopt pipefail
if ! xcodebuild -project "$repo/OpenResponses.xcodeproj" -scheme OpenResponses -configuration Debug \
    -destination "id=$udid" -allowProvisioningUpdates "${auth[@]}" -derivedDataPath "$derived" build 2>&1 \
    | sed -E 's/(-authenticationKey(Path|ID|IssuerID)) [^ ]+/\1 <redacted>/g' >"$log"; then
  grep -E "error:" "$log" | sort -u | head -20
  print -u2 "Build failed; full log: $log"
  exit 1
fi
print "Build succeeded in $(( SECONDS - start )) s"

app="$derived/Build/Products/Debug-iphoneos/OpenResponses.app"
xattr -cr "$app"
xcrun devicectl device install app --device "$udid" "$app" | grep -E "bundleID|installationURL" || true
if launch="$(xcrun devicectl device process launch --terminate-existing --device "$udid" "$bundle" 2>&1)"; then
  print -r -- "$launch" | tail -1
elif print -r -- "$launch" | grep -q "Locked"; then
  print "Installed, not launched: the device is locked. Unlock it and open OpenResponses."
else
  print -u2 -r -- "$launch"
  exit 1
fi
