#!/bin/bash
set -e

echo "Testing BlindCore..."
cd Packages/BlindCore
swift test

echo "All tests passed!"
