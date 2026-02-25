#!/bin/bash
set -e

# Notarization script for Blind
# Requires: APPLE_ID, APPLE_PASSWORD (app-specific password), TEAM_ID

APP_PATH="${1:-build/Blind.app}"
BUNDLE_ID="com.hayaoo.blind"

if [ -z "$APPLE_ID" ] || [ -z "$APPLE_PASSWORD" ] || [ -z "$TEAM_ID" ]; then
    echo "Error: APPLE_ID, APPLE_PASSWORD, and TEAM_ID must be set"
    exit 1
fi

echo "Signing app..."
codesign --deep --force --verify --verbose \
    --sign "Developer ID Application: Your Name ($TEAM_ID)" \
    --options runtime \
    "$APP_PATH"

echo "Creating ZIP for notarization..."
ditto -c -k --keepParent "$APP_PATH" "Blind.zip"

echo "Submitting for notarization..."
xcrun notarytool submit "Blind.zip" \
    --apple-id "$APPLE_ID" \
    --password "$APPLE_PASSWORD" \
    --team-id "$TEAM_ID" \
    --wait

echo "Stapling ticket..."
xcrun stapler staple "$APP_PATH"

echo "Notarization complete!"
