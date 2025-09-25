# Incident Report — Comfort Cat Folder Duplication

Date: 2025-09-22
Actor: fubumaki (reported), Cursor Agent (remediation)

Summary
- Two Comfort Cat guideline folders existed: `docs/comfort-cat` and `docs/comfort cat` (space vs hyphen).
- Risk: edits could diverge; references might point to the wrong path.

Examine
- Verified both folders existed with overlapping files.
- Searched repo references:
  - No repo-path references to `docs/comfort cat` remain (except merge script).
  - Windows mirror references to `C:\otel\docs\comfort cat` are intentional.

Clean
- Added `scripts/merge-comfort-cat.ps1` to merge space-named folder into hyphen path safely:
  - Non-destructive copy with `.conflict` suffix for differing files
  - Report written to `artifacts/comfort-cat-merge-report.txt`

Report
- Artifacts:
  - `scripts/merge-comfort-cat.ps1`
  - `artifacts/comfort-cat-merge-report.txt`
- Verification commands:
  - `rg --fixed-strings "docs/comfort cat" -n`
  - `rg --fixed-strings "C:\\otel\\docs\\comfort cat" -n`

Role
- You (fubumaki): review any `.conflict` files under `docs/comfort-cat`, decide canonical content, then delete `.conflict` copies.
- Cursor Agent: confirm references stay canonical, remove the space-named folder in a follow-up once conflicts resolved.

Next actions
- Resolve `.conflict` files (if any) and approve removal of `docs/comfort cat`.
- Replace any remaining helper references after cleanup.
