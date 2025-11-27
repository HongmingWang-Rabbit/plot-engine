#!/bin/bash
set -e

echo "Building Flutter web app..."

# Add Flutter to PATH (installed in previous step)
export PATH="/tmp/flutter/bin:$PATH"

# Build with environment variables
flutter build web --release \
  --dart-define=API_BASE_URL="${API_BASE_URL:-http://localhost:3000}" \
  --dart-define=APP_BASE_URL="${APP_BASE_URL:-https://plot-engine.com}"

echo "Build complete!"
