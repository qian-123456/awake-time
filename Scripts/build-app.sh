#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_DIR="$BUILD_DIR/Awake Time.app"
CONTENTS_DIR="$APP_DIR/Contents"
CONFIGURATION="${1:-release}"

cd "$PROJECT_DIR"
swift build -c "$CONFIGURATION" --product AwakeTime

BIN_DIR="$(swift build -c "$CONFIGURATION" --show-bin-path)"
mkdir -p "$CONTENTS_DIR/MacOS" "$CONTENTS_DIR/Resources"
cp "$BIN_DIR/AwakeTime" "$CONTENTS_DIR/MacOS/AwakeTime"
cp "$PROJECT_DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
chmod 755 "$CONTENTS_DIR/MacOS/AwakeTime"

codesign --force --deep --sign - "$APP_DIR"
touch "$APP_DIR"

echo "$APP_DIR"
