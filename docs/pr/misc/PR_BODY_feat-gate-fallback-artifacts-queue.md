# fix(gap): IONA gate accepts artifacts/queue-steward-verification.txt fallback

## Summary
- Treats `queue-steward-verification.txt` as REQUIRED evidence with fallback in either `DELT/ARTF/` or `artifacts/`.
- Normalizes ECRR report/PR output (ASCII-safe dashes).
- Adds ECRR benchmark trend append + mirror with de-dup and retention defaults.
- Wires CI/PR gate and nightly workflows to maintain and publish rolling CSV and queue-steward evidence.

## CI/Nightly Integration
- Gate CI: `.github/workflows/bosscat-gate-verify.yml`
  - Generates queue steward evidence if snapshots exist.
  - Uploads `artifacts/*.txt` including `artifacts/queue-steward-verification.txt`.
- Nightly: `.github/workflows/nightly-dashboard-export.yml`
  - After snapshot collection, runs `scripts/generate-queue-steward-evidence.ps1`.
  - Uploads `artifacts/*.txt` alongside snapshots.
  - Appends ECRR benchmark trend and mirrors to `artifacts/`.

## Evidence
- Gate verdict + checks: `DELT/ARTF/gate-verification-results.json`
- ECRR latest: `docs/ecrr/ECRR_REPORTS/ECRR_GATE_RUN_LATEST.md`
- Benchmark JSON: `DELT/ARTF/ecrr-benchmark.json`
- Trend CSV: `DELT/ARTF/ecrr-benchmark-trend.csv`, mirror `artifacts/ecrr-benchmark-trend.csv`
- Queue steward evidence: `artifacts/queue-steward-verification.txt`

## Governance
- ECRR: Examine, Clean, Report, Role satisfied with artifacts written to disk.
- BossCat OEM approval required before merge.

