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

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

echo "🔨 Building: $APP_PATH"

pushd "$APP_PATH" >/dev/null

# Disable Next.js telemetry
export NEXT_TELEMETRY_DISABLED=1

# Install dependencies
if [[ -f "package.json" ]]; then
    echo "  📦 Installing dependencies..."
    if [[ -f "$REPO_ROOT/pnpm-lock.yaml" ]] && command -v pnpm >/dev/null 2>&1; then
        pnpm install --frozen-lockfile
    elif [[ -f "package-lock.json" ]]; then
        npm ci
    else
        npm install
    fi
else
    echo "  ℹ️  No package.json in app directory - skipping dependency install"
fi

# Run build
echo "  🔧 Running build..."
if [[ -f "package.json" ]] && grep -q '"build"' package.json; then
    if command -v pnpm >/dev/null 2>&1; then
        pnpm run build
    else
        npm run build
    fi
else
    echo "  ℹ️  No build script defined in package.json"
fi

popd >/dev/null

echo "✅ Build complete: $APP_PATH"

