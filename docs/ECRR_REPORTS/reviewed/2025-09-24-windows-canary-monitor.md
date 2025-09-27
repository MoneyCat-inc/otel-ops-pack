# ECRR Report — Windows Logs Canary + Hourly Monitor

Date: 2025-09-24
Actor: Cursor Agent — Observability Copilot

## 1) Examine

- SigNoz/Collector health: `http://localhost:13134/healthz` returned `{ "status": "Server available" }` with recent uptime.
- Latest artifacts present:
  - `artifacts/windows-logs-canary-test-20250924-143027.json` → `status: "success"`, `success_count: 5`, `error_count: 0`.
  - `artifacts/signoz-canary-remediation-20250924-143108.json` → `status: "healthy"`, references `artifacts/signoz-canary-monitor-latest.json`.
  - `artifacts/signoz-canary-monitor-latest.json` → `status: "healthy"`, 5‑minute window, `canaryCount` observed.

## 2) Clean

- Scheduled an hourly monitor to keep the pipeline continuously checked:
  - Task name: `OTel Monitor Optimized Pipeline Hourly`
  - Action: `pwsh.exe -NoProfile -File C:/otel/scripts/monitor-optimized-pipeline.ps1 -DurationMinutes 10`
  - Trigger: starts ~5 minutes from creation, repeats hourly, duration 7 days (auto-renews with re-registration).

## 3) Report

- Evidence artifacts:
  - `C:/otel/artifacts/windows-logs-canary-test-20250924-143027.json`
  - `C:/otel/artifacts/signoz-canary-remediation-20250924-143108.json`
  - `C:/otel/artifacts/signoz-canary-monitor-latest.json`
- Acceptance criteria:
  - Canary artifact records `status: "success"` with `success_count: 5` — ✅ met
  - Remediation artifact reports `status: "healthy"` referencing latest monitor snapshot — ✅ met
- Operational evidence:
  - Task Scheduler shows NextRunTime set for `OTel Monitor Optimized Pipeline Hourly`.

## 4) Role

- Responsible actor: Cursor Agent — Observability Copilot
- Scope: Local Windows OTel Collector → SigNoz logs pipeline; canary and monitoring scripts under `scripts/`.

---

## Commands Executed (audit)

```powershell
# List newest artifacts
Get-ChildItem -Path .\artifacts -File | Sort-Object LastWriteTime -Descending | Select-Object -First 5 | Format-Table LastWriteTime, Name

# Inspect artifacts
Get-Content -Path .\artifacts\windows-logs-canary-test-20250924-143027.json | Select-Object -First 60
Get-Content -Path .\artifacts\signoz-canary-remediation-20250924-143108.json | Select-Object -First 120
Get-Content -Path .\artifacts\signoz-canary-monitor-latest.json | Select-Object -First 60

# Register hourly monitor task
$start = (Get-Date).AddMinutes(5)
$interval = New-TimeSpan -Hours 1
$duration = New-TimeSpan -Days 7
$action = New-ScheduledTaskAction -Execute 'pwsh.exe' -Argument '-NoProfile -File "C:\otel\scripts\monitor-optimized-pipeline.ps1" -DurationMinutes 10'
$trigger = New-ScheduledTaskTrigger -Once -At $start -RepetitionInterval $interval -RepetitionDuration $duration
Register-ScheduledTask -TaskName 'OTel Monitor Optimized Pipeline Hourly' -Action $action -Trigger $trigger -Description 'Hourly OTel health/monitor check' -Force

# Verify task status
Get-ScheduledTask -TaskName 'OTel Monitor Optimized Pipeline Hourly' | Get-ScheduledTaskInfo | Format-List LastRunTime, LastTaskResult, NextRunTime
```

## ✅ ECRR Gate

- Examine — evidence captured (health endpoint, artifacts) — ✅
- Clean — hourly monitor scheduled safely — ✅
- Report — artifacts listed; acceptance criteria met — ✅
- Role — declared — ✅

## Next Actions

- Import `artifacts/signoz-canary-monitor-latest.json` into SigNoz dashboards to visualize 5‑minute canary counts.
- Keep `scripts/monitor-optimized-pipeline.ps1` scheduled; review monitor artifact daily.
- Optional alert: create a SigNoz rule — "count(message contains \"windows-logs-canary\") < 1 over 5m" to detect ingestion stalls.
