import subprocess
import sys
from pathlib import Path


DATA = """\
2024-10-05 12:34:56 INFO Startup complete
2024-10-05 12:35:00 ERROR Timeout while connecting
2024-10-05 12:35:02 ERROR TIMEOUT occurred during read
2024-10-05 12:35:05 WARN Minor delay detected
2024-10-05 12:35:10 INFO timeout in lowercase appears
"""


def write_sample(tmp_path: Path) -> Path:
    p = tmp_path / "sample.log"
    p.write_text(DATA, encoding="utf-8")
    return p


def run_cli(args: list[str]) -> subprocess.CompletedProcess:
    return subprocess.run([sys.executable, "-m", "logfilter.main", *args], capture_output=True, text=True, check=False)


def test_keyword_filter_is_case_insensitive(tmp_path: Path):
    log = write_sample(tmp_path)
    # Expect to match lines containing Timeout/TIMEOUT/timeout regardless of case (BUG initially)
    cp = run_cli([str(log), "--contains", "timeout"])  # lower search
    lines = [ln for ln in cp.stdout.splitlines() if ln.strip()]
    # Should match 3 lines (ERROR Timeout, ERROR TIMEOUT, INFO timeout)
    assert len(lines) == 3


def test_level_filter_only(tmp_path: Path):
    log = write_sample(tmp_path)
    cp = run_cli([str(log), "--level", "ERROR"])  # should match exactly 2 ERROR lines
    lines = [ln for ln in cp.stdout.splitlines() if ln.strip()]
    assert len(lines) == 2





