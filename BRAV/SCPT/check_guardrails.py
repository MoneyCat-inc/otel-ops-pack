#!/usr/bin/env python3
"""
Tetragram Repository Guardrails Checker
BossCat OEM Governance Framework

Validates repository structure against tetragram conventions (ALFA/BRAV/CHAR/DELT).
Stdlib only - no external dependencies required.
"""

import json
import os
import sys
import subprocess
from pathlib import Path
from typing import List, Set, Dict, Tuple, Optional

# Ensure UTF-8 encoding for Windows console
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

# Tetragram 4-letter plane/subdir enforcement
FOUR_CHAR_DIRS = {
    "ALFA": {"SRCE", "TEST", "TOOL", "OTEL", "APPS", "LIBS", "CORE", "INST"},
    "BRAV": {"SCPT", "INFR", "DOCK", "CICD", "HOOK", "BUIL"},
    "CHAR": {"DOCS", "EVID", "AUDT", "REPO", "RUNB", "PRSV", "ECRR"},
    "DELT": {"CONF", "ASST", "FIXT", "LOAD", "TMPL", "META", "SECR", "OVER", "BASE", "ARTF"}
}

class Colors:
    """ANSI color codes for terminal output"""
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    MAGENTA = '\033[95m'
    CYAN = '\033[96m'
    RESET = '\033[0m'
    BOLD = '\033[1m'

def log(level: str, message: str, file: str = None):
    """Log a message with color coding"""
    colors = {
        'ERROR': Colors.RED,
        'WARN': Colors.YELLOW,
        'INFO': Colors.CYAN,
        'SUCCESS': Colors.GREEN,
        'HEADER': Colors.MAGENTA + Colors.BOLD
    }
    color = colors.get(level, Colors.RESET)
    prefix = f"{color}[{level}]{Colors.RESET}"
    
    if file:
        print(f"{prefix} {message}: {Colors.BLUE}{file}{Colors.RESET}")
    else:
        print(f"{prefix} {message}")

def load_config(config_path: str) -> dict:
    """Load guardrails configuration"""
    try:
        with open(config_path, 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        log('ERROR', f"Config file not found: {config_path}")
        sys.exit(1)
    except json.JSONDecodeError as e:
        log('ERROR', f"Invalid JSON in config: {e}")
        sys.exit(1)

def get_repo_root() -> Path:
    """Find repository root by looking for .git directory"""
    current = Path.cwd()
    while current != current.parent:
        if (current / '.git').exists():
            return current
        current = current.parent
    return Path.cwd()

def scan_top_level_dirs(repo_root: Path, exemptions: Set[str]) -> List[str]:
    """Get all top-level directories, excluding exemptions"""
    try:
        items = [item.name for item in repo_root.iterdir() 
                if item.is_dir() and item.name not in exemptions]
        return sorted(items)
    except PermissionError:
        log('ERROR', f"Permission denied scanning: {repo_root}")
        return []

def check_forbidden_roots(top_level: List[str], forbidden: List[str]) -> List[str]:
    """Check for forbidden legacy root directories"""
    violations = [d for d in top_level if d in forbidden]
    return violations

def git_tracked_top_level(repo_root: Path) -> Optional[Set[str]]:
    """
    Return set of top-level paths that are tracked by git.
    Returns None if git is not available.
    """
    try:
        out = subprocess.check_output(
            ["git", "ls-files", "--full-name"],
            cwd=str(repo_root),
            text=True,
            stderr=subprocess.DEVNULL,
        )
        first_components = set()
        for line in out.splitlines():
            if not line.strip():
                continue
            parts = Path(line.strip()).parts
            if parts:
                first_components.add(parts[0])
        return first_components
    except Exception:
        return None

def check_allowed_roots(
    top_level: List[str], 
    allowed: List[str], 
    exemptions: Set[str],
    repo_root: Path = None,
    ephemeral: List[str] = None,
    ignore_untracked: bool = False
) -> Tuple[List[str], List[str]]:
    """
    Check for directories that aren't in the allowed list.
    Returns (errors, warnings) tuple.
    
    Ephemeral directories (logs/, out/, tmp/) are handled specially:
    - If untracked: warned but ignored
    - If tracked: error (should be in .gitignore)
    
    All other unauthorized directories are always errors (tracked or not).
    """
    ephemeral_set = set(ephemeral or [])
    # Always query git to check ephemeral tracking status
    tracked = git_tracked_top_level(repo_root) if repo_root else None
    
    errors = []
    warnings = []
    
    for d in top_level:
        # Skip if in allowed or exemptions
        if d in allowed or d in exemptions:
            continue
        
        # Handle ephemeral directories specially
        if d in ephemeral_set:
            if tracked is not None and d in tracked:
                errors.append(f"{d}/ (ephemeral but tracked - add to .gitignore)")
            else:
                warnings.append(f"{d}/ (ephemeral, untracked - ignored)")
            continue
        
        # For any other unauthorized directory: ALWAYS error
        # (Don't hide real violations just because they're untracked)
        errors.append(d)
    
    return errors, warnings

def check_path_depth(repo_root: Path, max_depth: int, exemptions: Set[str]) -> List[Tuple[str, int]]:
    """Check for paths exceeding maximum depth"""
    violations = []
    
    # Comprehensive list of directories to skip
    skip_dirs = exemptions | {
        ".git", "node_modules", "__pycache__", ".pytest_cache", ".mypy_cache",
        ".idea", ".vscode", ".cursor", "dist", "build", "target", "coverage",
        "venv", ".venv", ".tox", ".nox", ".eggs", "*.egg-info"
    }
    
    for root, dirs, files in os.walk(repo_root):
        # Filter out exempted and build directories
        dirs[:] = [d for d in dirs if d not in skip_dirs and not d.endswith('.egg-info')]
        
        rel_path = Path(root).relative_to(repo_root)
        depth = len(rel_path.parts)
        
        if depth > max_depth:
            violations.append((str(rel_path), depth))
    
    return violations

def check_plane_subdirs(repo_root: Path) -> Tuple[bool, List[str]]:
    """Check that plane subdirectories follow 4-char uppercase naming convention"""
    violations = []
    
    for plane, allowed in FOUR_CHAR_DIRS.items():
        plane_path = repo_root / plane
        if not plane_path.exists() or not plane_path.is_dir():
            continue
        
        try:
            for child in plane_path.iterdir():
                if not child.is_dir():
                    continue
                name = child.name
                
                # Check 4-char uppercase convention
                if not (len(name) == 4 and name.isupper() and name.isalpha()):
                    violations.append(f"{plane}/{name}: not 4-char UPPERCASE")
                elif name not in allowed:
                    violations.append(f"{plane}/{name}: not in allowed set {sorted(allowed)}")
        except PermissionError:
            pass
    
    return (len(violations) == 0, violations)

def check_workflow_files(repo_root: Path, config: dict) -> List[Dict[str, any]]:
    """Check GitHub workflow files for compliance"""
    violations = []
    workflows_dir = repo_root / '.github' / 'workflows'
    
    if not workflows_dir.exists():
        return violations
    
    max_lines = config['rules']['ci_workflow_rules'].get('max_inline_run_lines', 20)
    require_brav = config['rules']['ci_workflow_rules'].get('require_brav_scpt_reference', False)
    
    for workflow_file in workflows_dir.glob('*.yml'):
        try:
            with open(workflow_file, 'r', encoding='utf-8') as f:
                content = f.read()
                lines = content.split('\n')
            
            # Check for long inline run blocks
            in_run_block = False
            run_line_count = 0
            run_start_line = 0
            
            for i, line in enumerate(lines, 1):
                if 'run:' in line and '|' in line:
                    in_run_block = True
                    run_line_count = 0
                    run_start_line = i
                elif in_run_block:
                    if line.strip() and not line.strip().startswith('#'):
                        run_line_count += 1
                    if line and not line[0].isspace():
                        in_run_block = False
                        if run_line_count > max_lines:
                            violations.append({
                                'file': str(workflow_file.relative_to(repo_root)),
                                'type': 'long_inline_run',
                                'line': run_start_line,
                                'count': run_line_count,
                                'max': max_lines
                            })
            
            # Check for BRAV/SCPT reference
            if require_brav and 'BRAV/SCPT' not in content:
                violations.append({
                    'file': str(workflow_file.relative_to(repo_root)),
                    'type': 'missing_brav_scpt_reference',
                    'suggestion': 'Consider extracting logic to BRAV/SCPT scripts'
                })
        
        except Exception as e:
            log('WARN', f"Could not parse workflow file {workflow_file}: {e}")
    
    return violations

def generate_report(repo_root: Path, config: dict, violations: Dict[str, List]) -> bool:
    """Generate compliance report and return pass/fail status"""
    log('HEADER', f"🐾 BossCat Guardrails Report - {repo_root.name}")
    print()
    
    has_violations = False
    
    # Forbidden roots check
    if violations['forbidden_roots']:
        has_violations = True
        log('ERROR', f"Found {len(violations['forbidden_roots'])} forbidden legacy root directories:")
        for root in violations['forbidden_roots']:
            print(f"  ❌ {root}/")
        print()
    
    # Allowed roots check
    if violations['disallowed_roots']:
        has_violations = True
        log('ERROR', f"Found {len(violations['disallowed_roots'])} unauthorized top-level directories:")
        for root in violations['disallowed_roots']:
            print(f"  ❌ {root}/")
        print()
    
    # Allowed roots warnings (ephemeral/untracked)
    if violations.get('disallowed_warnings'):
        log('WARN', f"Found {len(violations['disallowed_warnings'])} ephemeral/untracked directories (ignored):")
        for root in violations['disallowed_warnings']:
            print(f"  ℹ️  {root}")
        print()
    
    # Plane subdir structure check
    if violations.get('plane_subdirs'):
        has_violations = True
        log('ERROR', f"Found {len(violations['plane_subdirs'])} plane subdirectory violations:")
        for v in violations['plane_subdirs'][:10]:
            print(f"  ❌ {v}")
        if len(violations['plane_subdirs']) > 10:
            print(f"  ... and {len(violations['plane_subdirs']) - 10} more")
        print()
    
    # Path depth check
    if violations['path_depth']:
        has_violations = True
        log('WARN', f"Found {len(violations['path_depth'])} paths exceeding max depth:")
        for path, depth in violations['path_depth'][:10]:  # Show first 10
            print(f"  ⚠️  {path} (depth: {depth})")
        if len(violations['path_depth']) > 10:
            print(f"  ... and {len(violations['path_depth']) - 10} more")
        print()
    
    # Workflow checks
    if violations['workflows']:
        for v in violations['workflows']:
            if v['type'] == 'long_inline_run':
                log('WARN', f"Workflow has long inline run block ({v['count']} > {v['max']} lines)", v['file'])
            elif v['type'] == 'missing_brav_scpt_reference':
                log('WARN', v['suggestion'], v['file'])
        print()
    
    # Tetragram structure info
    if not has_violations:
        log('SUCCESS', '✅ Repository structure complies with tetragram guardrails')
        print()
        log('INFO', 'Tetragram planes detected:')
        for plane in ['ALFA', 'BRAV', 'CHAR', 'DELT']:
            plane_path = repo_root / plane
            if plane_path.exists():
                print(f"  ✓ {plane}/ - {config['rules']['tetragram_structure'][plane]['description']}")
        print()
    
    return not has_violations

def main():
    """Main execution"""
    # Parse arguments
    config_path = 'BRAV/SCPT/guardrails.json'
    
    if len(sys.argv) > 1:
        if sys.argv[1] in ['-h', '--help']:
            print("Usage: check_guardrails.py [--config PATH]")
            print()
            print("Options:")
            print("  --config PATH    Path to guardrails.json (default: BRAV/SCPT/guardrails.json)")
            print("  -h, --help       Show this help message")
            sys.exit(0)
        elif sys.argv[1] == '--config' and len(sys.argv) > 2:
            config_path = sys.argv[2]
    
    # Load configuration
    repo_root = get_repo_root()
    full_config_path = repo_root / config_path
    
    if not full_config_path.exists():
        log('ERROR', f"Config not found: {config_path}")
        print()
        print("Run from repository root or specify --config PATH")
        sys.exit(1)
    
    config = load_config(str(full_config_path))
    
    # Collect exemptions
    exemptions = set(
        config['exemptions']['hidden_dirs'] + 
        config['exemptions']['temp_dirs'] +
        config['exemptions'].get('build_dirs', [])
    )
    
    # Run checks
    log('INFO', 'Scanning repository structure...')
    
    top_level = scan_top_level_dirs(repo_root, exemptions)
    
    # Check plane subdirectory structure
    plane_ok, plane_violations = check_plane_subdirs(repo_root)
    
    # Check allowed roots with ephemeral handling
    disallowed_errors, disallowed_warnings = check_allowed_roots(
        top_level,
        config['rules']['allowed_top_level'],
        exemptions,
        repo_root=repo_root,
        ephemeral=config['rules'].get('ephemeral_top_level', []),
        ignore_untracked=config['rules'].get('ignore_untracked_top_level', False)
    )
    
    violations = {
        'forbidden_roots': check_forbidden_roots(
            top_level, 
            config['rules']['forbidden_legacy_roots']
        ),
        'disallowed_roots': disallowed_errors,
        'disallowed_warnings': disallowed_warnings,
        'plane_subdirs': plane_violations,
        'path_depth': check_path_depth(
            repo_root,
            config['rules']['max_path_depth'],
            exemptions
        ),
        'workflows': check_workflow_files(repo_root, config)
    }
    
    # Generate report
    passed = generate_report(repo_root, config, violations)
    
    # Exit with appropriate code
    enforcement = config.get('enforcement', {})
    if not passed and enforcement.get('mode') == 'fail':
        log('ERROR', '🚫 Guardrails check failed')
        sys.exit(enforcement.get('exit_code_on_violation', 1))
    else:
        log('SUCCESS', '✅ Guardrails check passed')
        sys.exit(0)

if __name__ == '__main__':
    main()

