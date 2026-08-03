#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_DIR="$BUILD_DIR/Awake Time.app"
CONTENTS_DIR="$APP_DIR/Contents"
CONFIGURATION="${1:-release}"
INSTALL_DIR="${AWAKE_TIME_INSTALL_DIR:-/Applications}"
INSTALLED_APP_DIR="$INSTALL_DIR/Awake Time.app"

cd "$PROJECT_DIR"
swift build -c "$CONFIGURATION" --product AwakeTime

BIN_DIR="$(swift build -c "$CONFIGURATION" --show-bin-path)"
mkdir -p "$CONTENTS_DIR/MacOS" "$CONTENTS_DIR/Resources"
cp "$BIN_DIR/AwakeTime" "$CONTENTS_DIR/MacOS/AwakeTime"
cp "$PROJECT_DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
chmod 755 "$CONTENTS_DIR/MacOS/AwakeTime"

codesign --force --deep --sign - "$APP_DIR"
touch "$APP_DIR"

if [[ "${AWAKE_TIME_SKIP_INSTALL:-0}" != "1" ]]; then
  osascript -e 'tell application id "local.awaketime.app" to quit' 2>/dev/null || true
  for _ in {1..50}; do
    if ! pgrep -x AwakeTime >/dev/null; then
      break
    fi
    sleep 0.1
  done
  mkdir -p "$INSTALL_DIR"
  ditto "$APP_DIR" "$INSTALLED_APP_DIR"
  touch "$INSTALLED_APP_DIR"
  open "$INSTALLED_APP_DIR"
  echo "$INSTALLED_APP_DIR"
else
  echo "$APP_DIR"
fi
