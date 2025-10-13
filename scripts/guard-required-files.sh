#!/bin/bash
# Guard: Required files must be tracked by git
# Directive 011 (BOSS-CATX-CIGT-SBOM)
# Budget: 12 LOC

set -euo pipefail

missing=0
required_files=(
  "signature-registry.json"
  "Vasilisa_High_Priestess_TinCanForest.jpg"
)

for f in "${required_files[@]}"; do
  if ! git ls-files --error-unmatch "$f" >/dev/null 2>&1; then
    echo "::error file=$f::Required file is not tracked by git (add and commit)"
    missing=1
  else
    echo "[OK] $f is tracked"
  fi
done

exit $missing

