# ECRR — Collector Watchdog + API Error Body Capture

**Date:** 2026-08-02  
**Actor:** Cursor{Implementer} + machine operator `@fubumaki`  
**Verdict:** **GREEN** — watchdog task live; API error body surfaced in gate JSON

## 1. Examine

- `otelcol-contrib` found Stopped + Disabled twice in the same session (2026-08-02)
- Root cause: MSI default `start= disabled` + no automated recovery beyond the 3-attempt service failure policy
- No scheduled task or watchdog existed; silent dark after disable was the recurring failure mode
- `verify-pipeline` `Invoke-SigNozApiTraceCheck` catch block surfaced only `$_.Exception.Message` (bare HTTP status line) — actual SigNoz error body (`failed to get traces keys`) was invisible in gate logs and `gate_verification.json`
- Root cause of API 500: SigNoz v0.96.1 `v5/query_range` traces path calls `/api/v1/fields/keys?signal=traces` which returns 500; logs, ClickHouse, and v3 autocomplete all healthy — server-side metadata bug, not client payload shape
- PS7 `Invoke-RestMethod` does not populate `WebException.Response`; error body lives in `$_.ErrorDetails.Message`

## 2. Clean

**Watchdog (`scripts/windows/watchdog-otelcol.ps1` + `install-watchdog-task.ps1`)**
- Created `watchdog-otelcol.ps1`: checks service state every invocation; if not Running, checks registry `Start=4` (Disabled) and re-enables to `delayed-auto` before starting — covers both MSI-disable and crash-exhaust patterns
- Appends one JSON line per run to `artifacts/watchdog/watchdog.log` with `before`, `after`, `action` (`ok` / `started` / `reenabled_and_started` / `start_failed`)
- Created `install-watchdog-task.ps1`: idempotent registration of `BossCat-OtelcolWatchdog` scheduled task — every 5 min, SYSTEM, elevated, `IgnoreNew`, 2-min execution limit
- Task installed and verified: first manual trigger logged `{"action":"ok","before":"Running","after":"Running","ok":true}`

**API error body (`BRAV/SCPT/verify-pipeline.ps1`)**
- Replaced bare `$_.Exception.Message` catch with `Get-HttpErrorBody`: prefers `$_.ErrorDetails.Message` (PS7 `Invoke-RestMethod`), then `HttpResponseMessage.Content`, then `WebException.GetResponseStream()` as last resort
- Applied to both primary catch and inner fallback catch in `Invoke-SigNozApiTraceCheck`
- Verified live: warning now shows `{"status":"error","error":{"code":"internal","message":"internal(internal): failed to get traces keys"}}` and `error` field in return hash carries same string into `gate_verification.json`

## 3. Report

| Item | Before | After |
|------|--------|-------|
| Collector silent-disable recovery | None — manual only | `BossCat-OtelcolWatchdog` task, every 5 min |
| Watchdog log | None | `artifacts/watchdog/watchdog.log` (JSON per run) |
| API 500 error visibility | `http_error` + bare status line | Full SigNoz error body in warning + gate JSON |
| Gate outcome | GREEN via ClickHouse fallback | GREEN via ClickHouse fallback (unchanged; API bug is server-side) |

Files changed (3):
- `scripts/windows/watchdog-otelcol.ps1` — new
- `scripts/windows/install-watchdog-task.ps1` — new
- `BRAV/SCPT/verify-pipeline.ps1` — modified (`Get-HttpErrorBody` in two catch blocks)

## 4. Role

Cursor{Implementer} designed and implemented; machine operator verified live run and confirmed `Get-HttpErrorBody` PS7 path. SigNoz upgrade (to fix `failed to get traces keys`) is a separate work item — ClickHouse fallback remains the confirmed gate path until then.

**Status:** COMPLETE
