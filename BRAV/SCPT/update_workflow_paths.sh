#!/bin/bash
# Update GitHub workflows to use BRAV/SCPT paths
# BossCat OEM - Phase B.1 cleanup

set -euo pipefail

echo "🐾 BossCat: Updating workflow paths scripts/ → BRAV/SCPT/"
echo ""

updated=0

# Find workflows with scripts/ references
workflows=$(git grep -l 'scripts/' .github/workflows 2>/dev/null || true)

if [ -z "$workflows" ]; then
    echo "✅ No workflows need updating"
    exit 0
fi

# Update each workflow
for workflow in $workflows; do
    sed -i'' -e 's#\(\s\|^\)scripts/#\1BRAV/SCPT/#g' "$workflow"
    echo "  ✅ Updated: $(basename $workflow)"
    ((updated++))
done

echo ""
echo "✅ Updated $updated workflow(s)"
echo ""
echo "Next steps:"
echo "  1. Review changes: git diff .github/workflows/"
echo "  2. Commit: git add .github/workflows/"
echo "  3. git commit -m 'ci(workflows): update paths scripts/ → BRAV/SCPT/'"
echo ""

