#!/usr/bin/env python3
"""
Pathmap Validator - BossCat Tetragram Migration
Validates that legacy paths have been migrated to tetragram structure
"""

import sys
from pathlib import Path

# Ensure UTF-8 encoding for Windows console
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

# Legacy → Tetragram pathmap
PATHMAP = {
    "scripts/": "BRAV/SCPT/",
    "synthetic/": "ALFA/OTEL/synthetic/",
    "tests/": "ALFA/TEST/unit/",
    "tools/": "ALFA/TOOL/cli/",
    "docker/": "BRAV/DOCK/legacy/",
    "helm/": "BRAV/INFR/helm/",
    "deployment-pipeline/": "BRAV/INFR/deployment-pipeline/",
    "docs/": "CHAR/DOCS/legacy/",
    "artifacts/": "CHAR/EVID/artifacts/",
    "reports/": "CHAR/EVID/reports/",
    "playwright-report/": "CHAR/EVID/playwright-report/",
    "config/": "DELT/CONF/config/",
    "configs/": "DELT/CONF/configs/",
    "assets/": "DELT/ASST/assets/",
    "baseline/": "DELT/FIXT/baseline/",
    "test-payloads/": "DELT/FIXT/test-payloads/",
    "templates/": "DELT/TMPL/templates/"
}

def main(root="."):
    """Validate pathmap migration status"""
    root = Path(root).resolve()
    
    print(f"🐾 BossCat Pathmap Validator")
    print(f"Repository: {root.name}\n")
    
    missing = []
    ok = []
    shims = []
    
    for old, new in sorted(PATHMAP.items()):
        old_path = root / old.rstrip('/')
        new_path = root / new.rstrip('/')
        
        if old_path.exists():
            if old_path.is_symlink():
                target = old_path.readlink()
                shims.append(f"  🔗 {old} → {target} (shim)")
            else:
                missing.append(f"  ❌ {old} still exists and is not a shim")
        
        if new_path.exists():
            ok.append(f"  ✅ {new}")
    
    # Report
    if ok:
        print(f"Migrated ({len(ok)}):")
        for item in ok:
            print(item)
        print()
    
    if shims:
        print(f"Shims ({len(shims)}):")
        for item in shims:
            print(item)
        print()
    
    if missing:
        print(f"Pending Migration ({len(missing)}):")
        for item in missing:
            print(item)
        print()
    
    print(f"Summary: {len(ok)} migrated, {len(shims)} shims, {len(missing)} pending")
    
    return 1 if missing else 0

if __name__ == "__main__":
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else "."))

