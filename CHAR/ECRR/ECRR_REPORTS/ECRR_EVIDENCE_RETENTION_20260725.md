# ECRR — Evidence Retention Policy Ship

**Timestamp:** 2026-07-25  
**Gate / Site:** Prevent / evidence-repo  
**Actor:** Cursor{Implementer}  
**Authority:** Post–Pack 3B oversight board (approved plan)

## Examine

- `otel-ops-evidence` accumulates raw run-reports via `run-archiver.yml` with no prune.
- Classic checkout mtime trap documented; age must use filename/path or git `%ct`.
- viz-engine `LUMI_API_KEY` still absent (Phase A — Fae); Phase B decoupled.

## Clean

- Code PR **#381** (merged): prune workflow + `prune.mjs` + FG PAT amber + `workflows.json` + `package-lock` sync.
- Docs PR **#382** (merged): briefing, pointer README, `BOSSCAT_LOG`.

## Report

Dry-run dispatch ([run 30160387171](https://github.com/MoneyCat-inc/otel-ops-pack/actions/runs/30160387171)):

| Metric | Value |
|--------|-------|
| Would delete | **12532** files (~8.3 MB) |
| `date_source` filename | **12532** |
| `date_source` git-log | **0** |
| Kept permanent | 4 |
| Kept young (≤90d) | 15894 |
| Kept no_age | 0 |
| Dry run | true |

Derivation proven: archive path `archived/YYYY/MM/` stamps drive all candidates; no mtime used. Scope assertion held (all paths under `docs/BossCat/run-reports/`).

Live prune (`dry_run=false`) deferred until operator confirms counts — optional follow-up.

## Role

Cursor{Implementer} — implement + dry-run prove.  
Fae — Phase A Lumi mint (still awaiting).  
BossCat OEM — board acceptance.

## Follow-on (not this ECRR)

CHAR/docs 26 mismatches; CHAR/DELT/ALFA disposition; deploy-hub rename; clean-host E2E; sibling maturity; optional live prune.
