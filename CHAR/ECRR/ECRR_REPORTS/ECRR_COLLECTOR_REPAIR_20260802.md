# ECRR — Windows OTel Collector Repair

**Date:** 2026-08-02  
**Actor:** Cursor{Implementer} + machine operator `@fubumaki`  
**Verdict:** **GREEN** — collector Running · Automatic; quick-monitor exit 0

## 1. Examine

- Boot health: **5/6 (83%)** — SigNoz stack healthy; `otelcol-contrib` **Stopped / Disabled**
- ImagePath already correct: `--config C:\ProgramData\otelcol-contrib\config.yaml`
- Preflight OTLP 4317/4318 + SigNoz UI: **4/4 PASS**
- No config drift observed

## 2. Clean

- `Set-Service otelcol-contrib -StartupType Automatic`
- `Start-Service otelcol-contrib`
- Root cause: post-MSI disable step (clean-host runbook) left service Disabled and never re-enabled

## 3. Report

| Check | Before | After |
| --- | --- | --- |
| `otelcol-contrib` Status | Stopped | Running |
| StartType | Disabled | Automatic |
| Boot health | 5/6 | expected 6/6 |
| quick-monitor | collector Not Running | Docker / Collector / SigNoz all green (exit 0) |

Artifacts: `artifacts/boot-reports/boot-health-20260802-161033.json` · `artifacts/quick-monitor-20260802-161152.json`

## 4. Role

Cursor{Implementer} examined and verified; machine operator re-enabled and started the service. No further action required.

**Status:** COMPLETE
