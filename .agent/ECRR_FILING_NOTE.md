# ECRR Filing Note

This note tracks misfiled ECRR reports and the correct filing rules.

Filing rules:
- Place all reports under docs/ECRR_REPORTS/ (use reviewed/, working/, archive/).
- Do NOT place reports elsewhere in docs/. Templates and guides are exceptions.
- Naming: YYYY-MM-DD-slug.md or ECRR-timestamp-slug.md (example: 2025-09-24-canary.md).
- After adding a report, run: pwsh -File scripts/ecrr-manage.ps1 -Action Review -Report REPORT.md
- Regenerate index/ledger: pwsh -File scripts/ecrr-manage.ps1 -Action RegenerateAll

Misfiled files detected: 1
- None
