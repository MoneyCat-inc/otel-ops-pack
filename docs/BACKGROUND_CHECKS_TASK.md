# Background Check Task

This guide describes how to run the continuous background health checks that keep the local OTel wiring in good shape.

## Overview

- Ensures `scripts/verify-wiring.ps1` runs on a loop (default every 15 minutes).
- Respects `.agent/LOCK` so maintenance windows can pause checks.
- Writes JSON log lines to `artifacts/background-check.log` for later review.
- Optional flag `-RunMonitor` also executes `scripts/monitor-analytics-ingestion.ps1` each cycle.

## Usage

From the repository root (`C:\otel`):

```powershell
pwsh -File scripts/continuous-background-check.ps1
```

Common variations:

- **Run once for smoke test**
  ```powershell
  pwsh -File scripts/continuous-background-check.ps1 -Once
  ```
- **Change cadence to every 30 minutes**
  ```powershell
  pwsh -File scripts/continuous-background-check.ps1 -VerifyIntervalMinutes 30
  ```
- **Include analytics monitor (if it supports bounded runs)**
  ```powershell
  pwsh -File scripts/continuous-background-check.ps1 -RunMonitor
  ```

The script logs each iteration to `artifacts/background-check.log` so you can tail the activity:

```powershell
Get-Content artifacts/background-check.log -Wait
```

## Scheduling (Optional)

To run the loop as a Windows scheduled task under the current user:

```powershell
$action = New-ScheduledTaskAction -Execute 'pwsh.exe' -Argument '-NoProfile -File "C:\otel\scripts\continuous-background-check.ps1"'
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 15) -RepetitionDuration ([TimeSpan]::MaxValue)
Register-ScheduledTask -TaskName 'OTelBackgroundChecks' -Action $action -Trigger $trigger -Description 'Run local OTel health checks every 15 minutes.'
```

Use `Unregister-ScheduledTask -TaskName 'OTelBackgroundChecks' -Confirm:$false` to remove it later.

## Verification

After the first loop finishes, confirm log entries:

```powershell
Select-String -Path artifacts/background-check.log -Pattern 'verify-wiring'
```

A successful entry looks similar to:

```
{"timestamp":"2025-09-23T03:00:15.123Z","check":"verify-wiring","status":"success","detail":"== Wiring verification PASSED =="}
```

## Troubleshooting

- Missing scripts are logged as `status":"skipped"`; ensure both verification scripts exist.
- If `.agent/LOCK` is present, the loop pauses and records `status":"paused"` until the lock clears.
- For persistent failures, inspect the tail of `artifacts/background-check.log` and rerun the failing script manually for richer output.
