import argparse
import sys
from typing import Iterable, List


def parse_args(argv: List[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Filter log lines by level and keyword")
    parser.add_argument("logfile", help="Path to log file to read")
    parser.add_argument("--level", dest="level", choices=["DEBUG", "INFO", "WARN", "ERROR"], help="Filter by level")
    parser.add_argument("--contains", dest="contains", help="Filter by keyword (case-insensitive)")
    return parser.parse_args(argv)


def filter_lines(lines: Iterable[str], level: str | None, keyword: str | None) -> Iterable[str]:
    for line in lines:
        line_stripped = line.rstrip("\n")

        if level:
            # Basic token split, expect: "YYYY-mm-dd HH:MM:SS LEVEL Message"
            parts = line_stripped.split()
            if len(parts) < 3:
                continue
            lvl = parts[2]
            if lvl != level:
                continue

        if keyword:
            # Fix: perform case-insensitive keyword match
            if keyword.lower() not in line_stripped.lower():
                continue

        yield line_stripped


def main(argv: List[str] | None = None) -> int:
    ns = parse_args(sys.argv[1:] if argv is None else argv)
    with open(ns.logfile, "r", encoding="utf-8") as fh:
        for out_line in filter_lines(fh, ns.level, ns.contains):
            print(out_line)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())





