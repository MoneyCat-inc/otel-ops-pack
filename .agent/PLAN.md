# Gate #013C — Job B — Renderer Integration

**Authority:** BossCat OEM  
**Executor:** Cursor{Implementer}  
**Lane:** `audio-013c`  
**Date:** 2025-10-24

## Goal

Integrate `AudioInjector` → `ProjectMInjector` into pm-engine render loop to deliver continuous PCM to `projectM::feedPCM(...)`. Prove integrity via 60-second AM-sine test with:
- **Buffer health:** underrun ratio <1%
- **Signal tracking:** Pearson r ≥0.70 between AM envelope and intake RMS
- **Stability:** No frame-time regressions

Emit synthetic "audio-on" trace for gate verification. Changed-paths tests only.

## Budgets (HARD)

- **LOC:** ≤200
- **Files:** ≤6
- **Jobs:** 1
- **TTL:** 90 min
- **Retries:** ≤3

## Exit Codes

- 0 = GREEN
- 50 = kill-switch
- 51 = git blocked
- 52 = writer conflict
- 53 = retry exhausted

**No merge to trunk.**
