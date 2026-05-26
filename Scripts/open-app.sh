#!/usr/bin/env bash
# Builds HalfSheets and launches it as a proper macOS .app bundle (menus + keyboard focus).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

CONFIG="${1:-debug}"
swift build -c "$CONFIG"

BINARY="$(find .build -path "*/$CONFIG/HalfSheets" -type f ! -name '*.dSYM' | head -1)"
if [[ -z "$BINARY" || ! -x "$BINARY" ]]; then
  echo "Could not find HalfSheets binary after build." >&2
  exit 1
fi

APP_DIR=".build/HalfSheets.app"
MACOS="$APP_DIR/Contents/MacOS"
rm -rf "$APP_DIR"
mkdir -p "$MACOS"
cp "$BINARY" "$MACOS/HalfSheets"

cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleExecutable</key>
	<string>HalfSheets</string>
	<key>CFBundleIdentifier</key>
	<string>com.halfsheets.HalfSheets</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>HalfSheets</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>LSMinimumSystemVersion</key>
	<string>14.0</string>
	<key>NSHighResolutionCapable</key>
	<true/>
	<key>NSPrincipalClass</key>
	<string>NSApplication</string>
</dict>
</plist>
PLIST

echo "Opening $APP_DIR"
open "$APP_DIR"
