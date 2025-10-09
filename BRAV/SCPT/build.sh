#!/usr/bin/env bash
# Build script for applications
# Usage: bash BRAV/SCPT/build.sh ALFA/APPS/<APP_NAME>

set -euo pipefail

APP_PATH="${1:-}"
if [[ -z "$APP_PATH" ]]; then
    echo "❌ Usage: build.sh ALFA/APPS/<APP_NAME>"
    exit 2
fi

if [[ ! -d "$APP_PATH" ]]; then
    echo "❌ App directory not found: $APP_PATH"
    exit 2
fi

echo "🔨 Building: $APP_PATH"

pushd "$APP_PATH" >/dev/null

# Disable Next.js telemetry
export NEXT_TELEMETRY_DISABLED=1

# Install dependencies
echo "  📦 Installing dependencies..."
npm ci

# Run build
echo "  🔧 Running build..."
if [[ -f "package.json" ]] && grep -q '"build"' package.json; then
    npm run build
else
    echo "  ℹ️  No build script defined in package.json"
fi

popd >/dev/null

echo "✅ Build complete: $APP_PATH"

