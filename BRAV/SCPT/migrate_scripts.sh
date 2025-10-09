#!/bin/bash
# Phase B.1: Migrate scripts → BRAV/SCPT with backward-compatible shim
# BossCat OEM - Tetragram Migration Kit

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

echo "🐾 BossCat Phase B.1: Scripts Migration"
echo "======================================="
echo ""

# Safety checks
if [ ! -d "scripts" ]; then
    echo "✅ scripts/ directory not found - may already be migrated"
    exit 0
fi

if [ -L "scripts" ]; then
    echo "⚠️  scripts/ is already a symlink - skipping migration"
    exit 0
fi

# Create BRAV/SCPT if it doesn't exist
mkdir -p BRAV/SCPT

echo "📦 Moving script files..."
# Move all .ps1, .sh, .py scripts from root scripts/ to BRAV/SCPT/
if [ -d "scripts" ]; then
    # Count files to move
    file_count=$(find scripts -maxdepth 1 -type f \( -name "*.ps1" -o -name "*.sh" -o -name "*.py" -o -name "*.js" \) | wc -l)
    
    if [ "$file_count" -gt 0 ]; then
        echo "  Moving $file_count script files..."
        find scripts -maxdepth 1 -type f \( -name "*.ps1" -o -name "*.sh" -o -name "*.py" -o -name "*.js" \) -exec mv -v {} BRAV/SCPT/ \;
    fi
    
    # Move subdirectories if any
    if [ "$(find scripts -mindepth 1 -maxdepth 1 -type d | wc -l)" -gt 0 ]; then
        echo "  Moving subdirectories..."
        find scripts -mindepth 1 -maxdepth 1 -type d -exec mv -v {} BRAV/SCPT/ \;
    fi
    
    # Remove the now-empty scripts directory
    if [ -z "$(ls -A scripts)" ]; then
        rmdir scripts
        echo "  Removed empty scripts/ directory"
    fi
fi

echo ""
echo "🔗 Creating backward-compatible symlink..."
ln -s BRAV/SCPT scripts
echo "  Created: scripts → BRAV/SCPT"

echo ""
echo "✅ Phase B.1 complete!"
echo ""
echo "Next steps:"
echo "  1. Review changes: git status"
echo "  2. Test key scripts still work via old paths"
echo "  3. Commit: git add -A && git commit -m 'chore(repo): move scripts → BRAV/SCPT with shim'"
echo "  4. Update references in workflows and docs over next 2 cycles"
echo "  5. Remove shim after validation: ./BRAV/SCPT/cleanup_shims.sh"
echo ""

