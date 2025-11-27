#!/bin/bash
set -e

echo "Installing Flutter..."

# Clone Flutter SDK (stable channel)
git clone --depth 1 --branch stable https://github.com/flutter/flutter.git /tmp/flutter

# Add Flutter to PATH
export PATH="/tmp/flutter/bin:$PATH"

# Pre-cache web artifacts
flutter precache --web

# Verify installation
flutter --version

# Get dependencies
flutter pub get

echo "Flutter installation complete!"
