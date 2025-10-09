#!/bin/bash
# Phase B.2: Migrate configs/assets/infra → DELT & BRAV
# BossCat OEM - Tetragram Migration Kit

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

echo "🐾 BossCat Phase B.2: Configs/Assets/Infra Migration"
echo "===================================================="
echo ""

# Create target directories
mkdir -p DELT/CONF DELT/ASST DELT/FIXT DELT/TMPL
mkdir -p BRAV/INFR/legacy BRAV/DOCK/legacy
mkdir -p CHAR/EVID

moved_count=0

# Function to migrate with shim
migrate_dir() {
    local src="$1"
    local dest="$2"
    local create_shim="${3:-true}"
    
    if [ ! -d "$src" ] || [ -L "$src" ]; then
        return 0
    fi
    
    echo "📦 Migrating: $src → $dest"
    
    # Move the directory
    mv "$src" "$dest"
    moved_count=$((moved_count + 1))
    
    # Create symlink shim if requested
    if [ "$create_shim" = "true" ]; then
        ln -s "$dest" "$src"
        echo "  🔗 Created shim: $src → $dest"
    fi
    
    echo "  ✅ Migrated successfully"
    echo ""
}

# Migrate configurations
if [ -d "config" ]; then
    migrate_dir "config" "DELT/CONF/config"
fi

if [ -d "configs" ]; then
    migrate_dir "configs" "DELT/CONF/configs"
fi

# Migrate Docker infrastructure
if [ -d "docker" ]; then
    migrate_dir "docker" "BRAV/DOCK/legacy"
fi

# Migrate Helm and deployment pipelines
if [ -d "helm" ]; then
    migrate_dir "helm" "BRAV/INFR/helm"
fi

if [ -d "deployment-pipeline" ]; then
    migrate_dir "deployment-pipeline" "BRAV/INFR/deployment-pipeline"
fi

# Migrate evidence/reports
if [ -d "artifacts" ]; then
    migrate_dir "artifacts" "CHAR/EVID/artifacts"
fi

if [ -d "reports" ]; then
    migrate_dir "reports" "CHAR/EVID/reports"
fi

if [ -d "playwright-report" ]; then
    migrate_dir "playwright-report" "CHAR/EVID/playwright-report"
fi

# Migrate test assets and fixtures
if [ -d "assets" ]; then
    migrate_dir "assets" "DELT/ASST/assets"
fi

if [ -d "baseline" ]; then
    migrate_dir "baseline" "DELT/FIXT/baseline"
fi

if [ -d "test-payloads" ]; then
    migrate_dir "test-payloads" "DELT/FIXT/test-payloads"
fi

# Migrate templates
if [ -d "templates" ]; then
    migrate_dir "templates" "DELT/TMPL/templates"
fi

echo "✅ Phase B.2 complete!"
echo ""
echo "Summary: Migrated $moved_count directories"
echo ""
echo "Next steps:"
echo "  1. Review changes: git status"
echo "  2. Update workflow paths: ./BRAV/SCPT/update_workflow_paths.sh (if available)"
echo "  3. Test CI/CD pipelines"
echo "  4. Commit: git add -A && git commit -m 'chore(repo): move configs/infra/assets to DELT/BRAV'"
echo "  5. After 2 green cycles, remove shims: ./BRAV/SCPT/cleanup_shims.sh"
echo ""

