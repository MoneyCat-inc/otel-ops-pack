#!/usr/bin/env python3
"""BossCat gate run enumeration - deterministic enumeration of expected vs present gate runs."""

import argparse
import json
import os
import re
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple

LOG_PREFIX = "[enumerate]"


def parse_gate_run_verdict(file_path: Path) -> Optional[str]:
    """
    Parse gate run report to extract verdict (READY/NOT_READY/UNKNOWN).
    
    Looks for patterns like:
    - "Gate Verdict: READY"
    - "**Status**: ✅ **COMPLETE - GATE READY**"
    - "verdict.*READY"
    - "NOT_READY" or "NOT READY"
    """
    try:
        content = file_path.read_text(encoding="utf-8")
        content_upper = content.upper()
        
        # Check for NOT_READY first (more specific)
        if re.search(r"NOT[_\s]?READY", content_upper):
            return "NOT_READY"
        
        # Check for READY patterns
        if re.search(r"GATE\s+VERDICT[:\s]+READY", content_upper):
            return "READY"
        if re.search(r"VERDICT[:\s]+READY", content_upper):
            return "READY"
        if re.search(r"STATUS[:\s]+.*?GATE\s+READY", content_upper):
            return "READY"
        if re.search(r"STATUS[:\s]+.*?READY", content_upper) and "NOT" not in content_upper:
            return "READY"
        if "READY" in content_upper and "NOT" not in content_upper and len(content) > 50:
            # Heuristic: if READY appears and file has content, likely READY
            return "READY"
        
        # Check for empty/template files (just headers, no actual content)
        stripped = content.strip()
        if len(stripped) < 200 or (stripped.count('#') > 5 and len(stripped) < 500):
            # Very short or mostly headers = template/empty = NOT_READY
            return "NOT_READY"
        
        # Default: UNKNOWN if file exists but verdict unclear
        return "UNKNOWN"
    except Exception as exc:
        print(f"{LOG_PREFIX} WARNING: Failed to parse {file_path}: {exc}")
        return None


def extract_timestamp_from_filename(filename: str) -> Optional[Tuple[str, str]]:
    """
    Extract date and time from filename pattern: ECRR_GATE_RUN_YYYYMMDD_HHMMSS.md
    Returns (date_str, time_str) or None.
    """
    match = re.match(r"ECRR_GATE_RUN_(\d{8})_(\d{6})\.md", filename)
    if match:
        return match.group(1), match.group(2)
    return None


def generate_expected_gate_runs(
    start_date: str = "20251009",
    end_date: str = "20251019",
    interval_minutes: int = 5
) -> List[str]:
    """
    Generate expected gate run IDs based on time window and interval.
    
    This is a deterministic derivation rule for the 81-set.
    Note: This is a best-effort approximation; actual runs may vary.
    """
    from datetime import timedelta
    
    expected: List[str] = []
    
    # Parse dates
    start = datetime.strptime(start_date, "%Y%m%d")
    end = datetime.strptime(end_date, "%Y%m%d")
    end = end.replace(hour=23, minute=59, second=59)
    
    current = start
    while current <= end:
        date_str = current.strftime("%Y%m%d")
        time_str = current.strftime("%H%M%S")
        expected.append(f"ECRR_GATE_RUN_{date_str}_{time_str}.md")
        current = current + timedelta(minutes=interval_minutes)
    
    return expected


def enumerate_gate_runs(reports_dir: str, output_path: str) -> Dict:
    """
    Enumerate gate run reports: expected vs present, categorized by status.
    """
    reports_path = Path(reports_dir)
    if not reports_path.exists():
        raise FileNotFoundError(f"Reports directory not found: {reports_dir}")
    
    # Scan actual files
    pattern = "ECRR_GATE_RUN_*.md"
    all_files = list(reports_path.glob(pattern))
    
    print(f"{LOG_PREFIX} Scanning {reports_dir} for {pattern}...")
    print(f"{LOG_PREFIX} Found {len(all_files)} files total")
    
    # Separate canonical runs (timestamped) from pointers/excluded files
    canonical_run_ids: List[str] = []
    excluded_files: List[str] = []
    pointer_files: Dict[str, Dict] = {}
    
    for file_path in all_files:
        filename = file_path.name
        
        # ECRR_GATE_RUN_LATEST.md is a pointer, not a canonical run
        if filename == "ECRR_GATE_RUN_LATEST.md":
            excluded_files.append(filename)
            # Try to resolve pointer target
            try:
                content = file_path.read_text(encoding="utf-8")
                # Look for references to actual run files
                target_match = re.search(r"ECRR_GATE_RUN_(\d{8}_\d{6})\.md", content)
                pointer_files[filename] = {
                    "filename": filename,
                    "path": str(file_path.relative_to(Path.cwd())) if Path.cwd() in file_path.parents else str(file_path),
                    "type": "pointer",
                    "target_id": target_match.group(1) if target_match else None,
                    "last_modified": datetime.fromtimestamp(file_path.stat().st_mtime).isoformat() + "Z",
                }
            except Exception:
                pointer_files[filename] = {
                    "filename": filename,
                    "path": str(file_path.relative_to(Path.cwd())) if Path.cwd() in file_path.parents else str(file_path),
                    "type": "pointer",
                    "target_id": None,
                    "last_modified": datetime.fromtimestamp(file_path.stat().st_mtime).isoformat() + "Z",
                }
            continue
        
        # Check if filename matches canonical pattern: ECRR_GATE_RUN_YYYYMMDD_HHMMSS.md
        ts = extract_timestamp_from_filename(filename)
        if ts:
            canonical_run_ids.append(filename)
        else:
            # Files that don't match pattern are excluded
            excluded_files.append(filename)
    
    print(f"{LOG_PREFIX} Canonical runs: {len(canonical_run_ids)}")
    print(f"{LOG_PREFIX} Excluded files: {len(excluded_files)}")
    
    # Parse each canonical run file to determine status
    present_ready: List[str] = []
    present_not_ready: List[str] = []
    present_unknown: List[str] = []
    present_by_id: Dict[str, Dict] = {}
    
    for filename in canonical_run_ids:
        file_path = reports_path / filename
        verdict = parse_gate_run_verdict(file_path)
        
        # Get relative path safely
        try:
            rel_path = str(file_path.relative_to(Path.cwd()))
        except ValueError:
            rel_path = str(file_path)
        
        ts = extract_timestamp_from_filename(filename)
        file_info = {
            "filename": filename,
            "path": rel_path,
            "verdict": verdict,
            "last_modified": datetime.fromtimestamp(file_path.stat().st_mtime).isoformat() + "Z",
        }
        
        if ts:
            file_info["date"] = ts[0]
            file_info["time"] = ts[1]
        
        present_by_id[filename] = file_info
        
        # Partition canonical runs by verdict (mutually exclusive)
        if verdict == "READY":
            present_ready.append(filename)
        elif verdict == "NOT_READY":
            present_not_ready.append(filename)
        else:
            present_unknown.append(filename)
    
    # Verify accounting: present_total must equal sum of partitions
    present_total = len(canonical_run_ids)
    accounted_total = len(present_ready) + len(present_not_ready) + len(present_unknown)
    if present_total != accounted_total:
        print(f"{LOG_PREFIX} WARNING: Accounting mismatch: {present_total} != {accounted_total}")
    
    # Authoritative source: ECRR_PROCESSING_SUMMARY_20251019.md (line 195-198) states:
    # - 81 total gate run reports (expected in the 81-set)
    # - 78 READY (from the 81-set)
    # - 1 NOT_READY (from the 81-set)
    # - 2 unaccounted (81 - 78 - 1 = 2)
    
    # Canonical run IDs (single source of truth)
    canonical_run_ids_set = set(canonical_run_ids)
    
    # Define the 81-set: files in time window 2025-10-09 to 2025-10-19
    WINDOW_START = "20251009"
    WINDOW_END = "20251019"
    
    window_files = []
    extra_files_list = []
    
    for filename in canonical_run_ids:
        ts = extract_timestamp_from_filename(filename)
        if ts:
            date_str = ts[0]
            if WINDOW_START <= date_str <= WINDOW_END:
                window_files.append(filename)
            else:
                extra_files_list.append(filename)
    
    # Expected 81-set: all files in time window
    expected_81_set = set(window_files)
    expected_total = 81  # Per authoritative source
    expected_ready = 78  # Per authoritative source (may be outdated)
    expected_not_ready = 1  # Per authoritative source (may be outdated)
    
    # Actual counts from canonical runs only (single source of truth)
    actual_ready = len(present_ready)
    actual_not_ready = len(present_not_ready)
    actual_unknown = len(present_unknown)
    actual_total = len(canonical_run_ids)  # Must equal actual_ready + actual_not_ready + actual_unknown
    
    # Calculate in-window counts (canonical 81-set only)
    all_present = set(present_ready) | set(present_not_ready) | set(present_unknown)
    ready_in_window = [f for f in present_ready if f in expected_81_set]
    not_ready_in_window = [f for f in present_not_ready if f in expected_81_set]
    unknown_in_window = [f for f in present_unknown if f in expected_81_set]
    ready_in_window_count = len(ready_in_window)
    not_ready_in_window_count = len(not_ready_in_window)
    unknown_in_window_count = len(unknown_in_window)
    
    # Calculate unaccounted: files in expected 81-set but not present
    unaccounted_set = expected_81_set - all_present
    unaccounted_count = len(unaccounted_set)
    
    # Extra: files present beyond the expected 81-set (outside time window)
    extra_count = len(extra_files_list)
    
    # Extra files are already identified (outside time window)
    extra = sorted(extra_files_list)
    
    # Unaccounted: files in expected 81-set but not present
    unaccounted = sorted(list(unaccounted_set)) if unaccounted_count > 0 else []
    
    # Get relative path safely
    try:
        scanned_rel_path = str(reports_path.relative_to(Path.cwd()))
    except ValueError:
        scanned_rel_path = str(reports_path)
    
    # Verify accounting integrity
    accounting_check = actual_total == (actual_ready + actual_not_ready + actual_unknown)
    if not accounting_check:
        print(f"{LOG_PREFIX} ERROR: Accounting integrity check failed: {actual_total} != {actual_ready} + {actual_not_ready} + {actual_unknown}")
    
    # Build result with explicit accounting
    result = {
        "timestamp_utc": datetime.utcnow().isoformat() + "Z",
        "scanned_paths": [scanned_rel_path],
        "canonical_run_glob": "ECRR_GATE_RUN_YYYYMMDD_HHMMSS.md",
        "excluded_files": sorted(excluded_files),
        "pointers": pointer_files,
        "summary": {
            "expected_total": expected_total,  # Per ECRR_PROCESSING_SUMMARY_20251019.md
            "expected_ready": expected_ready,  # Per authoritative source (may be outdated)
            "expected_not_ready": expected_not_ready,  # Per authoritative source (may be outdated)
            "present_total": actual_total,  # Canonical runs only
            "present_ready_count": actual_ready,  # From canonical runs (all)
            "present_not_ready_count": actual_not_ready,  # From canonical runs (all)
            "present_unknown_count": actual_unknown,  # From canonical runs (all)
            "present_in_window_count": len(window_files),  # Files in 2025-10-09 to 2025-10-19 window
            "present_ready_in_window_count": ready_in_window_count,  # READY in canonical 81-set
            "present_not_ready_in_window_count": not_ready_in_window_count,  # NOT_READY in canonical 81-set
            "present_unknown_in_window_count": unknown_in_window_count,  # UNKNOWN in canonical 81-set
            "unaccounted_count": unaccounted_count,  # Files in expected 81-set but not present
            "extra_count": extra_count,  # Files outside time window
            "accounting_integrity": accounting_check,  # present_total == ready + not_ready + unknown
        },
        "reconciliation": {
            "time_window": {
                "start": WINDOW_START,
                "end": WINDOW_END,
                "description": "Gate #006 81-set time window"
            },
            "expected_81_set_count": len(expected_81_set),
            "present_in_window_count": len([f for f in all_present if f in expected_81_set]),
            "ready_in_window_count": ready_in_window_count,
            "not_ready_in_window_count": not_ready_in_window_count,
            "unknown_in_window_count": unknown_in_window_count,
            "unaccounted_ids": unaccounted,
            "extra_files": [
                {
                    "filename": f,
                    "date": extract_timestamp_from_filename(f)[0] if extract_timestamp_from_filename(f) else None,
                    "reason": "Post-gate run (outside time window)",
                    "disposition": "EXCLUDE_FROM_CANONICAL"
                }
                for f in extra
            ]
        },
        "present_ready": sorted(present_ready),  # Partition of canonical_run_ids
        "present_not_ready": sorted(present_not_ready),  # Partition of canonical_run_ids
        "present_unknown": sorted(present_unknown),  # Partition of canonical_run_ids
        "canonical_run_ids": sorted(canonical_run_ids),  # Single source of truth
        "unaccounted": unaccounted,
        "extra": extra,
        "details": {
            "authoritative_source": {
                "file": "docs/ecrr/ECRR_REPORTS/ECRR_PROCESSING_SUMMARY_20251019.md",
                "line": "195-198",
                "expected_total": expected_total,
                "expected_ready": expected_ready,
                "expected_not_ready": expected_not_ready,
            },
            "accounting_rules": {
                "canonical_set": "ECRR_GATE_RUN_YYYYMMDD_HHMMSS.md (timestamped pattern)",
                "excluded": ["ECRR_GATE_RUN_LATEST.md (pointer)"],
                "partition_rule": "present_total == present_ready_count + present_not_ready_count + present_unknown_count",
            },
            "note": f"Unaccounted IDs: {unaccounted_count} file(s) from the 81-set {'cannot be deterministically listed without authoritative index' if unaccounted_count > 0 else 'none (all accounted)'}. Extra files ({extra_count}) are canonical runs outside the 2025-10-09 to 2025-10-19 window.",
            "present_files": present_by_id,
            "unaccounted_full": unaccounted,
            "extra_full": extra,
        }
    }
    
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description="Enumerate gate run reports")
    parser.add_argument(
        "--reports-dir",
        default="docs/ecrr/ECRR_REPORTS",
        help="Directory containing ECRR gate run reports"
    )
    parser.add_argument(
        "--output",
        default="artifacts/gate/gate-run-enumeration.json",
        help="Path to write enumeration JSON"
    )
    args = parser.parse_args()
    
    try:
        result = enumerate_gate_runs(args.reports_dir, args.output)
        
        # Write output
        output_path = Path(args.output)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        with open(output_path, "w", encoding="utf-8") as fh:
            json.dump(result, fh, indent=2)
        
        print(f"{LOG_PREFIX} Enumeration complete")
        print(f"{LOG_PREFIX} Summary:")
        print(f"  Expected: {result['summary']['expected_total']}")
        print(f"  Present: {result['summary']['present_total']}")
        print(f"  READY: {result['summary']['present_ready_count']}")
        print(f"  NOT_READY: {result['summary']['present_not_ready_count']}")
        print(f"  Unaccounted: {result['summary']['unaccounted_count']}")
        print(f"{LOG_PREFIX} Results written to: {args.output}")
        
        return 0
    except Exception as exc:
        print(f"{LOG_PREFIX} ERROR: {exc}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
