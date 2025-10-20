#!/bin/bash
# Pre-commit hook: Block inflated metrics (optional dev machine guard)
# Install: ln -s ../../scripts/pre-commit-inflated-metrics.sh .git/hooks/pre-commit
# Or: copy to .git/hooks/pre-commit and chmod +x

set -e

echo "🛡️  Checking for inflated metrics..."

# Search staged files for banned patterns (exclude archives)
if git diff --cached --name-only | grep -v 'archive/' | xargs -I {} git grep -nE '77\s*[x×✕]|196[.,]7(?!\d)' -- {}; then
    echo ""
    echo "❌ INFLATED METRICS DETECTED"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "POLICY:"
    echo "  • 77× claim is BANNED (unverified)"
    echo "  • 196.7 logs/sec is BANNED (derived from 77×)"
    echo ""
    echo "ALLOWED:"
    echo "  • 'Performance thresholds met (see test evidence)'"
    echo "  • Link to reproducible benchmark results"
    echo "  • Measured values with test report links"
    echo ""
    echo "FIX:"
    echo "  1. Remove inflated claims from staged files"
    echo "  2. Replace with verifiable statements"
    echo "  3. Link to evidence: docs/ecrr/ECRR_REPORTS/EVIDENCE_YYYY-MM-DD.md"
    echo ""
    echo "TEMPLATE: docs/ecrr/ECRR_REPORTS/EVIDENCE_TEMPLATE.md"
    echo ""
    exit 1
fi

echo "✅ No inflated metrics detected"
exit 0

