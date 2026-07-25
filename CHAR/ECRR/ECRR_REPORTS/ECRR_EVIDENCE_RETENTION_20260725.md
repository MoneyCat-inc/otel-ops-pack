# ECRR — Evidence Retention Policy Ship

**Timestamp:** 2026-07-25  
**Gate / Site:** Prevent / evidence-repo  
**Actor:** Cursor{Implementer}  
**Authority:** Post–Pack 3B oversight board (approved plan)

## Examine

- `otel-ops-evidence` accumulates raw run-reports via `run-archiver.yml` with no prune.
- Actions UI keep-~100 exists; evidence-repo raw archive did not.
- Evidence repo still small enough to set policy before growth.
- Classic checkout mtime trap documented; age must use filename/path or git `%ct`.
- viz-engine `LUMI_API_KEY` still absent (Phase A — Fae); Phase B decoupled.

## Clean

- Added `docs/BossCat/BRIEFING_EVIDENCE_RETENTION.md` (policy + age rules + history note).
- Updated `docs/BossCat/run-reports/README.md` retention pointer.
- Added `BRAV/SCPT/evidence-retention/prune.mjs` (filename → git-log; scope assert; manifest `date_source`).
- Added `.github/workflows/evidence-retention-prune.yml` (quarterly + dispatch; fail-loud token).
- Added `.github/workflows/evidence-pat-rotation-reminder.yml` (`EXPIRES_ON=2026-10-22`, 14d amber).
- Regenerated `docs/status/workflows.json`.

## Report

- Dry-run dispatch results (fill after first workflow run):
  - Would-delete count: _pending dispatch_
  - `date_source` filename: _pending_
  - `date_source` git-log: _pending_
  - Artifact: `evidence-prune-manifest` (14d retention)

## Role

Cursor{Implementer} — implement + dry-run prove.  
Fae — Phase A Lumi mint (separate).  
BossCat OEM — board acceptance.

## Follow-on (not this ECRR)

CHAR/docs 26 mismatches; CHAR/DELT/ALFA disposition; deploy-hub rename; clean-host E2E; sibling maturity.
