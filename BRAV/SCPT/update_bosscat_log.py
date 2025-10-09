#!/usr/bin/env python3
"""Append run metadata to docs/BossCat/reports/BOSSCAT_LOG.md."""

import argparse
from datetime import datetime
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser(description="Append BossCat log entry")
    parser.add_argument("--status", default="PASS", help="Gate status (PASS/FAIL)")
    parser.add_argument("--notes", default="automated entry", help="Short summary")
    parser.add_argument("--log-path", default="docs/BossCat/reports/BOSSCAT_LOG.md", help="Log file path")
    args = parser.parse_args()

    log_path = Path(args.log_path)
    timestamp = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%SZ")
    entry = f"\n### {timestamp} UTC\n- Status: {args.status}\n- Notes: {args.notes}\n"

    with log_path.open("a", encoding="utf-8") as handle:
        handle.write(entry)

    print(f"Logged entry to {log_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
