# ECRR — Evidence Retention Policy Ship

**Timestamp:** 2026-07-25  
**Gate / Site:** Prevent / evidence-repo  
**Actor:** Cursor{Implementer}  
**Authority:** Post–Pack 3B oversight board (approved plan)  
**Status:** PASS — live prune deleted 12532 files; would-delete = deleted

## Examine

- `otel-ops-evidence` accumulates raw run-reports via `run-archiver.yml` with no prune.
- Classic checkout mtime trap documented; age must use filename/path or git `%ct`.
- viz-engine `LUMI_API_KEY` still absent — mint is **machine-operator** seat (Cursor tab browser), not chat/review. See `AGENTS.md` actor seats.

## Clean

- Code PR **#381** (merged): prune workflow + `prune.mjs` + FG PAT amber + `workflows.json` + `package-lock` sync.
- Docs PR **#382** (merged): briefing, pointer README, `BOSSCAT_LOG`.
- Actor-map in root `AGENTS.md` (chat never owns mint/Secrets UI).
- Live prune executed after boundary proof (this closeout).

## Report

### Dry-run ([run 30160387171](https://github.com/MoneyCat-inc/otel-ops-pack/actions/runs/30160387171))

| Metric | Value |
|--------|-------|
| Would delete | **12532** files (~8.3 MB) |
| `date_source` filename | **12532** |
| `date_source` git-log | **0** |
| Kept permanent | 4 |
| Kept young (≤90d) | 15894 |
| Kept no_age | 0 |
| Dry run | true |
| Reconcile | 12532 + 15894 + 4 = **28430** |

### Permanent kept (whitelist — 4 paths by name)

1. `docs/BossCat/run-reports/INDEX.jsonl`
2. `docs/BossCat/run-reports/LATEST.md`
3. `docs/BossCat/run-reports/.gitkeep`
4. `docs/BossCat/run-reports/archived/.gitkeep`

Confirmed present in `otel-ops-evidence` HEAD before live prune.

### Boundary pair (straddle 90-day line)

Archive months present: 2025-09, 2025-10, 2026-06, 2026-07 (gap Nov–May). Cutoff ≈ 2026-04-26 for a 2026-07-25 run.

| Side | Path | `derived_date` | `date_source` | `age_days` |
|------|------|----------------|---------------|------------|
| **Newest would-delete** | `docs/BossCat/run-reports/archived/2025/10/run-18490622690.md` | 2025-10-01 | filename | 297 |
| **Oldest kept (filename)** | `docs/BossCat/run-reports/archived/2026/06/run-27413707649.md` | 2026-06-01 | filename | ~54 |

Boundary OK: newest delete far past 90d; oldest path-stamped keep is Jun 2026 (inside 90d). Young tally also includes ~14k `badges/` via `git-log` (bulk-extract commit age).

### Live prune ([run 30162695304](https://github.com/MoneyCat-inc/otel-ops-pack/actions/runs/30162695304))

| Metric | Value |
|--------|-------|
| Dry run | **false** |
| Would delete | **12532** |
| Deleted | **12532** |
| Bytes deleted | 8653925 |
| `date_source` filename / git-log | 12532 / 0 |
| Match | **would-delete = deleted** |

## Role

Cursor{Implementer} — implement, boundary proof, live prune, ECRR.  
Machine operator (`@fubumaki` at Cursor tab) — OpenAI mint + viz-engine `LUMI_API_KEY` Secrets UI.  
Chat/review — decisions only; no mint ownership.  
BossCat OEM — board acceptance.

## Follow-on (not this ECRR)

CHAR/docs 26 mismatches; CHAR/DELT/ALFA disposition; deploy-hub rename; clean-host E2E; sibling maturity.

## ECRR Gate

- Gate: PASS
- Scope: Structural normalization only.
- Evidence Reference: ECRR processor run 2026-08-18, 389/389 gated (PR #571).
- Guardrail: Append-only; original report body unchanged.
