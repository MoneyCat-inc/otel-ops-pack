#!/usr/bin/env bash
# Test script for applications
# Usage: bash BRAV/SCPT/test.sh ALFA/APPS/<APP_NAME>

set -euo pipefail

APP_PATH="${1:-}"
if [[ -z "$APP_PATH" ]]; then
    echo "❌ Usage: test.sh ALFA/APPS/<APP_NAME>"
    exit 2
fi

if [[ ! -d "$APP_PATH" ]]; then
    echo "❌ App directory not found: $APP_PATH"
    exit 2
fi

APP_NAME=$(basename "$APP_PATH")
OUT_DIR="out/test-results/$APP_NAME"

echo "🧪 Testing: $APP_PATH"

# Create output directory
mkdir -p "$OUT_DIR"

pushd "$APP_PATH" >/dev/null

# Run tests if test script exists
if [[ -f "package.json" ]] && grep -q '"test"' package.json; then
    echo "  🔍 Running tests..."
    
    # Try to run with junit output if jest/vitest configured
    npm test -- --ci --reporters=default --reporters=junit --outputFile="../../$OUT_DIR/junit.xml" 2>/dev/null || \
    npm test -- --ci --reporter=json --outputFile="../../$OUT_DIR/results.json" 2>/dev/null || \
    npm test -- --ci || EXIT=$?
    
    EXIT_CODE=${EXIT:-$?}
else
    echo "  ℹ️  No test script defined in package.json - skipping"
    EXIT_CODE=0
fi

popd >/dev/null

if [[ "${EXIT_CODE:-0}" -ne 0 ]]; then
    echo "❌ Tests failed: $APP_PATH"
    exit $EXIT_CODE
fi

echo "✅ Tests passed: $APP_PATH"
echo "   Results: $OUT_DIR"

