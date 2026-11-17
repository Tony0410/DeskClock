#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
echo "== swift build (release) =="
swift build -c release
APP="build/DeskClock.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp ".build/release/DeskClock" "$APP/Contents/MacOS/DeskClock"
cp "Resources/Info.plist" "$APP/Contents/Info.plist"
cp "Resources/DeskClock.icns" "$APP/Contents/Resources/DeskClock.icns" 2>/dev/null || true
echo "== ad-hoc sign =="
codesign --force --deep --sign - "$APP" 2>&1 | tail -2 || true
echo "== built: $APP =="
ls -la "$APP/Contents/MacOS/"
