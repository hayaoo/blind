#!/bin/bash
set -e

echo "Building BlindCore..."
cd Packages/BlindCore
swift build -c release

echo "Building Blind App..."
# TODO: xcodebuild for App target
# xcodebuild -project App/Blind/Blind.xcodeproj \
#   -scheme Blind \
#   -configuration Release \
#   -archivePath build/Blind.xcarchive \
#   archive

echo "Build complete!"
