#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PRODUCT_NAME="ScenePick"
APP_NAME="ScenePick"
DISPLAY_NAME="拾景"
BUNDLE_ID="com.xian.ScenePick"

cd "$ROOT_DIR"
swift build -c release --product "$PRODUCT_NAME"

if [ ! -f "$ROOT_DIR/Resources/AppIcon.icns" ]; then
  swift Scripts/generate-icon.swift
fi

BIN_DIR="$(swift build -c release --show-bin-path)"
APP_DIR="$ROOT_DIR/Build/${APP_NAME}.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$BIN_DIR/$PRODUCT_NAME" "$MACOS_DIR/$PRODUCT_NAME"
if [ -f "$ROOT_DIR/Resources/AppIcon.icns" ]; then
  cp "$ROOT_DIR/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi
find "$BIN_DIR" -maxdepth 1 \( -name "*.bundle" -o -name "*.resources" \) -type d -exec cp -R {} "$RESOURCES_DIR/" \;
mkdir -p "$RESOURCES_DIR/en.lproj" "$RESOURCES_DIR/zh-Hans.lproj"
cat > "$RESOURCES_DIR/en.lproj/InfoPlist.strings" <<STRINGS
"CFBundleDisplayName" = "ScenePick";
"CFBundleName" = "ScenePick";
STRINGS
cat > "$RESOURCES_DIR/zh-Hans.lproj/InfoPlist.strings" <<STRINGS
"CFBundleDisplayName" = "拾景";
"CFBundleName" = "拾景";
STRINGS

cat > "$CONTENTS_DIR/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>${PRODUCT_NAME}</string>
  <key>CFBundleIdentifier</key>
  <string>${BUNDLE_ID}</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon.icns</string>
  <key>CFBundleLocalizations</key>
  <array>
    <string>en</string>
    <string>zh-Hans</string>
  </array>
  <key>CFBundleDisplayName</key>
  <string>${DISPLAY_NAME}</string>
  <key>CFBundleName</key>
  <string>${APP_NAME}</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

printf "APPL????" > "$CONTENTS_DIR/PkgInfo"
touch "$APP_DIR"

echo "Built $APP_DIR"
