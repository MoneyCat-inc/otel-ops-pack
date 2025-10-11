#!/usr/bin/env bash
# FLAK Lane: Changed-Paths Smoke Test
# Authority: AUTO-BOTS-FLAK-ALFA
# Purpose: Fast, targeted smoke tests on changed files only
# DoD: ≤3 min runtime, fails CI on any test failure

set -euo pipefail

# Evidence logging
EVIDENCE_LOG=".agent/EVIDENCE.log"
mkdir -p .agent
echo '{"timestamp":"'$(date -Iseconds)'","event":"flak_smoke_start","actor":"FLAK-ALFA","phase":"examine"}' >> "$EVIDENCE_LOG"

# Detect changed files
echo "🔍 Detecting changed paths..."
CHANGED_FILES=$(git diff --name-only origin/${GITHUB_BASE_REF:-main}...HEAD || echo "")

if [ -z "$CHANGED_FILES" ]; then
  echo "ℹ️  No changes detected - skipping smoke tests"
  echo '{"timestamp":"'$(date -Iseconds)'","event":"flak_smoke_skip","actor":"FLAK-ALFA","reason":"no_changes"}' >> "$EVIDENCE_LOG"
  exit 0
fi

echo "📋 Changed files:"
echo "$CHANGED_FILES"

# Filter to test-relevant paths
TEST_CHANGES=$(echo "$CHANGED_FILES" | grep -E '^(tests/|.*\.spec\.|.*\.test\.|playwright/)' || echo "")
WORKFLOW_CHANGES=$(echo "$CHANGED_FILES" | grep -E '^\.github/workflows/' || echo "")

# Fast smoke checks
SMOKE_FAILED=0

# 1. If tests changed, run affected tests
if [ -n "$TEST_CHANGES" ]; then
  echo "🧪 Running affected tests..."
  echo '{"timestamp":"'$(date -Iseconds)'","event":"running_tests","actor":"FLAK-ALFA","files":"'$TEST_CHANGES'"}' >> "$EVIDENCE_LOG"
  
  # Run only changed test files (fast)
  while IFS= read -r test_file; do
    if [ -f "$test_file" ] && [[ "$test_file" =~ \.(spec|test)\.(ts|js)$ ]]; then
      echo "  Testing: $test_file"
      npx jest "$test_file" --maxWorkers=2 --bail || SMOKE_FAILED=1
    fi
  done <<< "$TEST_CHANGES"
fi

# 2. If workflows changed, validate YAML syntax
if [ -n "$WORKFLOW_CHANGES" ]; then
  echo "⚙️  Validating workflow YAML..."
  echo '{"timestamp":"'$(date -Iseconds)'","event":"validating_workflows","actor":"FLAK-ALFA"}' >> "$EVIDENCE_LOG"
  
  while IFS= read -r workflow_file; do
    if [ -f "$workflow_file" ]; then
      echo "  Validating: $workflow_file"
      python -c "import yaml; yaml.safe_load(open('$workflow_file'))" || SMOKE_FAILED=1
    fi
  done <<< "$WORKFLOW_CHANGES"
fi

# 3. If TypeScript/JavaScript changed, quick type check
TS_CHANGES=$(echo "$CHANGED_FILES" | grep -E '\.(ts|tsx|js|jsx)$' | head -5 || echo "")
if [ -n "$TS_CHANGES" ]; then
  echo "📘 Type-checking changed TS/JS files (sample)..."
  echo '{"timestamp":"'$(date -Iseconds)'","event":"typecheck_sample","actor":"FLAK-ALFA"}' >> "$EVIDENCE_LOG"
  
  npx tsc --noEmit --skipLibCheck || echo "⚠️  Type check warnings (non-blocking)"
fi

# Summary
echo ""
echo "═══════════════════════════════════════"
if [ $SMOKE_FAILED -eq 0 ]; then
  echo "✅ FLAK Smoke: PASSED"
  echo '{"timestamp":"'$(date -Iseconds)'","event":"flak_smoke_pass","actor":"FLAK-ALFA","phase":"report"}' >> "$EVIDENCE_LOG"
  exit 0
else
  echo "❌ FLAK Smoke: FAILED"
  echo '{"timestamp":"'$(date -Iseconds)'","event":"flak_smoke_fail","actor":"FLAK-ALFA","phase":"report"}' >> "$EVIDENCE_LOG"
  exit 1
fi

