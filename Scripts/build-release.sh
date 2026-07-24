#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-1.0.0}"
DIST_DIR="$PROJECT_DIR/dist"
APP_DIR="$DIST_DIR/Awake Time.app"
CONTENTS_DIR="$APP_DIR/Contents"
ARCHIVE_PATH="$DIST_DIR/Awake-Time-$VERSION-universal.zip"
ARM64_BUILD="$PROJECT_DIR/.build-release-arm64"
X86_64_BUILD="$PROJECT_DIR/.build-release-x86_64"

cd "$PROJECT_DIR"
swift build \
  -c release \
  --product AwakeTime \
  --triple arm64-apple-macosx14.0 \
  --scratch-path "$ARM64_BUILD"
swift build \
  -c release \
  --product AwakeTime \
  --triple x86_64-apple-macosx14.0 \
  --scratch-path "$X86_64_BUILD"

mkdir -p "$CONTENTS_DIR/MacOS" "$CONTENTS_DIR/Resources"
lipo -create \
  "$ARM64_BUILD/arm64-apple-macosx/release/AwakeTime" \
  "$X86_64_BUILD/x86_64-apple-macosx/release/AwakeTime" \
  -output "$CONTENTS_DIR/MacOS/AwakeTime"
cp "$PROJECT_DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
/usr/libexec/PlistBuddy \
  -c "Set :CFBundleShortVersionString $VERSION" \
  "$CONTENTS_DIR/Info.plist"
chmod 755 "$CONTENTS_DIR/MacOS/AwakeTime"

codesign --force --deep --sign - "$APP_DIR"
rm -f "$ARCHIVE_PATH" "$ARCHIVE_PATH.sha256"
ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$ARCHIVE_PATH"
(
  cd "$DIST_DIR"
  shasum -a 256 "$(basename "$ARCHIVE_PATH")" > "$(basename "$ARCHIVE_PATH").sha256"
)

echo "$ARCHIVE_PATH"
