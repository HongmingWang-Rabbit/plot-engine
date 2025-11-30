#!/bin/bash
set -e

echo "Building Flutter web app..."

# Add Flutter to PATH (installed in previous step)
export PATH="/tmp/flutter/bin:$PATH"

# Build with environment variables and base-href for /app path
flutter build web --release \
  --base-href="/app/" \
  --dart-define=API_BASE_URL="${API_BASE_URL:-https://api.plot-engine.com}" \
  --dart-define=APP_BASE_URL="${APP_BASE_URL:-https://plot-engine.com}"

# Move Flutter build to /app subdirectory
echo "Organizing build output..."
mkdir -p build/web_temp/app
mv build/web/* build/web_temp/app/
mv build/web_temp/* build/web/
rmdir build/web_temp

# Copy static landing page and assets to root
cp web/landing.html build/web/index.html
cp web/robots.txt build/web/
cp web/sitemap.xml build/web/
cp web/favicon.png build/web/
cp -r web/icons build/web/

echo "Build complete!"
