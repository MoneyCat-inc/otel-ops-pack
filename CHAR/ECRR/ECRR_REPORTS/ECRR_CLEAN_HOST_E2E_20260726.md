# ECRR ΓÇö Clean-Host E2E Re-Run (`clean-host-e2e-20260726`)

**Date:** 2026-07-25  
**Actor:** Cursor{Implementer} (PowerShell Direct) + machine operator (Docker Desktop session left open)  
**Verdict:** **GREEN** ΓÇö clone ΓåÆ first span **7.47 min** (target Γëñ30)  
**Prior:** `clean-host-e2e-20260725` RED on clock at **68.1 min** ΓåÆ **~60 min improvement** after F1ΓÇôF3  
**Artifacts:** `artifacts/clean-host-e2e-20260726.json` ┬╖ Run card: `docs/BossCat/CLEAN_HOST_E2E_RUN_CARD_20260726.md`

---

## Examine

- Restored / used Phase-0 checkpoint `phase0-ready-20260726` (collector Stopped+Disabled, no `C:\otel`, no SigNoz, 4317/4318 free).
- Cloned `docs/clean-host-e2e-scheduled` at tip `e7e9ba420` (orphaned by the #391 split); its F1ΓÇôF2 code content landed on `main` as `312aff7db` via #391. `main` still lacked map syntax at schedule time.
- Pre-clone confirm: map scrapers + registry ImagePath repair present in tree.

## Clean

No in-guest hotfix required. F1ΓÇôF3 fixed in repo + Phase-0 checkpoint behavior:

| Fix | Evidence this run |
|---|---|
| F1 scrapers map | `hasMapSyntax=true`; collector started without crash-loop |
| F2 registry ImagePath | ImagePath ΓåÆ `ProgramData\otelcol-contrib\config.yaml`; repair **0.39 min** |
| F3 MSI stop+disable | `signoz-otel-collector` healthy on first `compose up` (no 4317 collision) |

## Report

### Gate clock

| Milestone | UTC | Elapsed |
|---|---|---|
| Clone start | 22:49:10Z | 0 |
| First span evidence | 22:56:38Z | **7.47 min** |
| verify-pipeline exit 0 | 22:58:00Z | 8.83 min |

Phase splits: P1 0.44 ┬╖ P2 6.18 ┬╖ P3 0.39 ┬╖ P4 1.67 min.

### Evidence

- `verify_pipeline_exit`: **0**
- ClickHouse: logs=3, spans=1, canary_logs=2
- `signoz-otel-collector`: Up (healthy) ΓÇö F1 port race gone
- Windows collector: Running on ProgramData config; ports 5320/5321 up

### Comparison

| Run | Clone ΓåÆ first span | Verdict |
|---|---|---|
| 20260725 (broken scripts) | 68.1 min | RED on clock / GREEN after manual fix-forward |
| 20260726 (F1ΓÇôF3) | **7.47 min** | **GREEN** |

## Role

- **Cursor{Implementer}:** checkpoint prep, gate drive, evidence, this report.  
- **Machine operator:** prior Phase 0 / Docker interactive session; F1ΓÇôF2 commit+push to scheduled branch.

ΓÇö Cursor{Implementer}

## ECRR Gate

- Gate: PASS
- Scope: Structural normalization only.
- Evidence Reference: ECRR processor run 2026-08-18, 389/389 gated (PR #571).
- Guardrail: Append-only; original report body unchanged.
