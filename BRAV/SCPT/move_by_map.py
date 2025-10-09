#!/usr/bin/env python3
"""
Deterministic directory mover for tetragram migration.
Reads a JSON map and executes git mv commands for batch migrations.
"""
import json
import os
import sys
import subprocess
import pathlib
import io

# Ensure UTF-8 output on Windows
if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

def main(map_path="BRAV/SCPT/move_map.json"):
    """
    Move directories according to the mapping file.
    
    Args:
        map_path: Path to JSON file containing source -> destination mapping
    
    Returns:
        Exit code (0 = success, 1 = errors)
    """
    repo = pathlib.Path(".").resolve()
    
    # Load mapping
    try:
        with open(map_path, "r", encoding="utf-8") as f:
            mapping = json.load(f)
    except FileNotFoundError:
        print(f"❌ Mapping file not found: {map_path}")
        return 1
    except json.JSONDecodeError as e:
        print(f"❌ Invalid JSON in {map_path}: {e}")
        return 1
    
    print(f"📋 Loaded {len(mapping)} mappings from {map_path}")
    print()
    
    # Ensure destinations exist
    for dst in set(mapping.values()):
        d = repo / dst
        d.mkdir(parents=True, exist_ok=True)
    
    # Execute moves
    moved, skipped, errors = [], [], []
    for src, dst in mapping.items():
        sp, dp = repo / src, repo / dst
        if sp.exists():
            print(f"📦 git mv {src} {dst}")
            result = subprocess.run(
                ["git", "mv", "-k", src, dst],
                capture_output=True,
                text=True
            )
            if result.returncode == 0:
                moved.append((src, dst))
                print(f"   ✅ Moved")
            else:
                errors.append((src, dst, result.stderr))
                print(f"   ❌ Failed: {result.stderr.strip()}")
        else:
            skipped.append(src)
            print(f"ℹ️  {src} (not present)")
    
    # Summary
    print()
    print(f"📊 Migration Summary:")
    print(f"   ✅ Moved: {len(moved)}")
    print(f"   ℹ️  Skipped: {len(skipped)}")
    print(f"   ❌ Errors: {len(errors)}")
    
    if skipped:
        print()
        print(f"ℹ️  Skipped (not present): {', '.join(skipped)}")
    
    if errors:
        print()
        print(f"❌ Errors encountered:")
        for src, dst, err in errors:
            print(f"   {src} → {dst}: {err.strip()}")
        return 1
    
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else "BRAV/SCPT/move_map.json"))

