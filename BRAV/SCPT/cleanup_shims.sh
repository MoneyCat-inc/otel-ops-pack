#!/bin/bash
# Cleanup shims after validation window (2+ green CI cycles)
# BossCat OEM - Tetragram Migration Kit

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

echo "🐾 BossCat Shim Cleanup"
echo "======================"
echo ""
echo "⚠️  WARNING: This will remove backward-compatibility shims."
echo "   Only proceed after 2+ successful CI/CD cycles with new paths."
echo ""

# Check for dry-run flag
DRY_RUN=false
if [ "${1:-}" = "--dry-run" ]; then
    DRY_RUN=true
    echo "🔍 DRY RUN MODE - no changes will be made"
    echo ""
fi

# Function to remove shim
remove_shim() {
    local shim="$1"
    local target="$2"
    
    if [ ! -e "$shim" ]; then
        return 0
    fi
    
    if [ ! -L "$shim" ]; then
        echo "⚠️  $shim exists but is not a symlink - skipping"
        return 0
    fi
    
    if [ "$DRY_RUN" = true ]; then
        echo "🔍 Would remove: $shim → $target"
    else:
        rm "$shim"
        echo "✅ Removed shim: $shim"
    fi
}

echo "Checking for legacy shims..."
echo ""

# Check and remove known shims
remove_shim "scripts" "BRAV/SCPT"
remove_shim "config" "DELT/CONF/config"
remove_shim "configs" "DELT/CONF/configs"
remove_shim "docker" "BRAV/DOCK/legacy"
remove_shim "helm" "BRAV/INFR/helm"
remove_shim "deployment-pipeline" "BRAV/INFR/deployment-pipeline"
remove_shim "artifacts" "CHAR/EVID/artifacts"
remove_shim "reports" "CHAR/EVID/reports"
remove_shim "playwright-report" "CHAR/EVID/playwright-report"
remove_shim "assets" "DELT/ASST/assets"
remove_shim "baseline" "DELT/FIXT/baseline"
remove_shim "test-payloads" "DELT/FIXT/test-payloads"
remove_shim "templates" "DELT/TMPL/templates"

echo ""

if [ "$DRY_RUN" = true ]; then
    echo "🔍 Dry run complete. Re-run without --dry-run to apply changes."
else
    echo "✅ Shim cleanup complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Verify CI/CD still passes: git push"
    echo "  2. Check for any remaining legacy path references"
    echo "  3. Commit: git add -A && git commit -m 'chore(repo): remove legacy shims after validation'"
fi

echo ""

