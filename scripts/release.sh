#!/bin/bash
set -e

VERSION="${1:-$(git describe --tags --abbrev=0 2>/dev/null || echo 'v0.0.1')}"
APP_PATH="build/Blind.app"
DMG_NAME="Blind-${VERSION}.dmg"

echo "Creating DMG for $VERSION..."

# Create DMG
hdiutil create -volname "Blind" \
    -srcfolder "$APP_PATH" \
    -ov -format UDZO \
    "$DMG_NAME"

echo "Generating checksums..."
shasum -a 256 "$DMG_NAME" > SHA256SUMS.txt

echo "Release artifacts created:"
echo "  - $DMG_NAME"
echo "  - SHA256SUMS.txt"
