#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="ScenePick"
VOLUME_NAME="ScenePick"
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:--}"

APP_DIR="$ROOT_DIR/Build/${APP_NAME}.app"
DIST_DIR="$ROOT_DIR/Dist"

clean_bundle_metadata() {
  local path="$1"

  xattr -cr "$path" 2>/dev/null || true
  xattr -rd com.apple.FinderInfo "$path" 2>/dev/null || true
  xattr -rd 'com.apple.fileprovider.fpfs#P' "$path" 2>/dev/null || true
  xattr -rd com.apple.ResourceFork "$path" 2>/dev/null || true
  xattr -rd com.apple.macl "$path" 2>/dev/null || true
}

if [ ! -d "$APP_DIR" ]; then
  echo "Missing $APP_DIR. Run ./Scripts/build-app.sh first." >&2
  exit 1
fi

rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

STAGING_ROOT="$(mktemp -d)"
trap 'rm -rf "$STAGING_ROOT"' EXIT

APP_COPY="$STAGING_ROOT/${APP_NAME}.app"
DMG_ROOT="$STAGING_ROOT/dmg-root"

ditto --norsrc "$APP_DIR" "$APP_COPY"
clean_bundle_metadata "$APP_COPY"
codesign --force --deep --sign "$CODESIGN_IDENTITY" "$APP_COPY"
codesign --verify --deep --strict --verbose=2 "$APP_COPY"

ditto -c -k --norsrc --keepParent "$APP_COPY" "$DIST_DIR/${APP_NAME}.zip"

mkdir -p "$DMG_ROOT"
ditto --norsrc "$APP_COPY" "$DMG_ROOT/${APP_NAME}.app"
ln -s /Applications "$DMG_ROOT/Applications"

hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$DMG_ROOT" \
  -ov \
  -format UDZO \
  "$DIST_DIR/${APP_NAME}.dmg"
hdiutil verify "$DIST_DIR/${APP_NAME}.dmg"

(
  cd "$DIST_DIR"
  shasum -a 256 "${APP_NAME}.dmg" "${APP_NAME}.zip" > SHA256SUMS
)

echo "Packaged:"
echo "  $DIST_DIR/${APP_NAME}.dmg"
echo "  $DIST_DIR/${APP_NAME}.zip"
echo "  $DIST_DIR/SHA256SUMS"
