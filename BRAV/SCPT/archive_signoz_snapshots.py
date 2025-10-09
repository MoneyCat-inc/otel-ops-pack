#!/usr/bin/env python3
"""Move SigNoz screenshots into timestamped snapshot directories."""

import argparse
import os
import shutil
from datetime import datetime
from pathlib import Path


def collect_files(source: Path) -> list[Path]:
    patterns = ["*.png", "*.jpg", "*.json", "*.html"]
    files = []
    for pattern in patterns:
        files.extend(source.glob(pattern))
    return files


def main() -> int:
    parser = argparse.ArgumentParser(description="Archive SigNoz screenshots into snapshots directory")
    parser.add_argument("--source", default="artifacts", help="Directory containing Playwright assets")
    parser.add_argument("--dest-root", default="docs/observability/snapshots", help="Root snapshots directory")
    args = parser.parse_args()

    source = Path(args.source)
    dest_root = Path(args.dest_root)

    if not source.exists():
        print(f"Source directory {source} does not exist; nothing to archive")
        return 0

    files = collect_files(source)
    if not files:
        print("No snapshot files detected")
        return 0

    timestamp = datetime.utcnow().strftime("%Y-%m-%d-%H%M%SZ")
    dest_dir = dest_root / timestamp
    dest_dir.mkdir(parents=True, exist_ok=True)

    for item in files:
        target = dest_dir / item.name
        shutil.copy2(item, target)
        print(f"Copied {item} -> {target}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
