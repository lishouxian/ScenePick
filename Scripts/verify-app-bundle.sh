#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_PATH="${1:-"$ROOT_DIR/Build/ScenePick.app"}"
BINARY_PATH="$APP_PATH/Contents/MacOS/ScenePick"
INFO_PLIST="$APP_PATH/Contents/Info.plist"
EXPECTED_BUNDLE_ID="com.xian.ScenePick"
EXPECTED_MIN_SYSTEM="13.0"

if [ ! -d "$APP_PATH" ]; then
  echo "App bundle not found: $APP_PATH" >&2
  exit 1
fi

if [ ! -x "$BINARY_PATH" ]; then
  echo "App executable not found: $BINARY_PATH" >&2
  exit 1
fi

plist_value() {
  /usr/libexec/PlistBuddy -c "Print :$1" "$INFO_PLIST"
}

bundle_id="$(plist_value CFBundleIdentifier)"
if [ "$bundle_id" != "$EXPECTED_BUNDLE_ID" ]; then
  echo "Unexpected CFBundleIdentifier: $bundle_id" >&2
  exit 1
fi

lsui_element="$(plist_value LSUIElement)"
if [ "$lsui_element" != "true" ]; then
  echo "LSUIElement must be true for the menu bar app, got: $lsui_element" >&2
  exit 1
fi

minimum_system="$(plist_value LSMinimumSystemVersion)"
if [ "$minimum_system" != "$EXPECTED_MIN_SYSTEM" ]; then
  echo "Unexpected LSMinimumSystemVersion: $minimum_system" >&2
  exit 1
fi

if ! otool -L "$BINARY_PATH" | grep -q "ServiceManagement.framework"; then
  echo "ScenePick binary is not linked with ServiceManagement.framework" >&2
  exit 1
fi

codesign --verify --deep --strict --verbose=2 "$APP_PATH"
codesign -dvvv "$APP_PATH" 2>&1 | grep -E "Identifier=|Signature=|TeamIdentifier" || true
codesign -d --entitlements :- "$APP_PATH" >/dev/null 2>&1 || true

echo "Verified $APP_PATH"
