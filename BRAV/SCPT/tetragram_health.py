#!/usr/bin/env python3
"""
Tetragram health report utility.
Provides a compact JSON snapshot of repository structure compliance.
"""
import os
import pathlib
import json
import sys
import io

# Ensure UTF-8 output on Windows
if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

PLANES = ["ALFA", "BRAV", "CHAR", "DELT"]

# Forbidden legacy roots (should never reappear at top level)
FORBID = {
    "docs", "scripts", "docker", "helm", "config", "configs",
    "assets", "baseline", "test-payloads", "artifacts", "reports",
    "playwright-report", "synthetic", "tests", "tools"
}

# Allowed top-level (non-plane) directories
ALLOWED = {".github", ".agent"}

def main():
    """Generate health report as JSON."""
    root = pathlib.Path(".")
    
    # Get all top-level directories
    top = [p.name for p in root.iterdir() 
           if p.is_dir() and not p.name.startswith(".") or p.name in ALLOWED]
    
    # Check for forbidden roots
    forbidden = sorted(set(top) & FORBID)
    
    # Get subdirectories of each plane
    by_plane = {}
    for plane in PLANES:
        plane_path = root / plane
        if plane_path.exists():
            subdirs = sorted([c.name for c in plane_path.iterdir() if c.is_dir()])
            by_plane[plane] = subdirs
        else:
            by_plane[plane] = []
    
    # Calculate unauthorized directories
    unauthorized = [d for d in top 
                   if d not in PLANES 
                   and d not in ALLOWED 
                   and not d.startswith(".")]
    
    # Build report
    report = {
        "timestamp": "2025-10-09",
        "forbidden_roots": forbidden,
        "forbidden_count": len(forbidden),
        "unauthorized_top_level": sorted(unauthorized),
        "unauthorized_count": len(unauthorized),
        "planes": by_plane,
        "plane_health": {
            plane: {
                "exists": (root / plane).exists(),
                "subdir_count": len(by_plane.get(plane, []))
            }
            for plane in PLANES
        },
        "overall_health": "✅ PASS" if len(forbidden) == 0 else "❌ FAIL"
    }
    
    # Print report
    print(json.dumps(report, indent=2))
    
    # Exit with error if forbidden roots exist
    return 1 if len(forbidden) > 0 else 0

if __name__ == "__main__":
    sys.exit(main())

