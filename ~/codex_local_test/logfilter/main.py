#!/usr/bin/env python3
"""LogFilter CLI - Filter log files by level and keyword."""

import argparse
import sys
from pathlib import Path
from typing import List, Optional


def parse_log_line(line: str) -> Optional[dict]:
    """Parse a log line in format 'YYYY-MM-DD HH:MM:SS LEVEL Message'."""
    try:
        parts = line.strip().split(' ', 3)
        if len(parts) < 4:
            return None
        
        date_part = parts[0]
        time_part = parts[1]
        level = parts[2]
        message = parts[3]
        
        return {
            'datetime': f"{date_part} {time_part}",
            'level': level,
            'message': message,
            'raw': line.strip()
        }
    except Exception:
        return None


def filter_logs(lines: List[str], level: Optional[str] = None, contains: Optional[str] = None) -> List[str]:
    """Filter log lines by level and/or keyword."""
    filtered = []
    
    for line in lines:
        if not line.strip():
            continue
            
        parsed = parse_log_line(line)
        if not parsed:
            continue
            
        # Filter by level
        if level and parsed['level'] != level:
            continue
            
        # Filter by keyword - INTENTIONAL BUG: case sensitive
        if contains and contains not in parsed['message']:
            continue
            
        filtered.append(line.strip())
    
    return filtered


def main():
    """Main CLI entry point."""
    parser = argparse.ArgumentParser(description="Filter log files by level and keyword")
    parser.add_argument("file", help="Path to log file")
    parser.add_argument("--level", choices=["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"], 
                       help="Filter by log level")
    parser.add_argument("--contains", help="Filter by keyword in message")
    parser.add_argument("--count", action="store_true", help="Show count of matching lines")
    
    args = parser.parse_args()
    
    log_file = Path(args.file)
    if not log_file.exists():
        print(f"Error: File '{args.file}' not found", file=sys.stderr)
        sys.exit(1)
    
    try:
        with open(log_file, 'r', encoding='utf-8') as f:
            lines = f.readlines()
    except Exception as e:
        print(f"Error reading file: {e}", file=sys.stderr)
        sys.exit(1)
    
    filtered = filter_logs(lines, level=args.level, contains=args.contains)
    
    if args.count:
        print(len(filtered))
    else:
        for line in filtered:
            print(line)


if __name__ == "__main__":
    main()
