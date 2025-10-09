# Windows Collector -> SigNoz Canaries Runbook

## Task
Lock the final Windows `otelcol-contrib` canary run so that every execution restarts the collector if needed, emits the synthetic signals, and proves they land in SigNoz.

## Success
SigNoz Logs view shows the canary record by filtering with `message contains "SigNoz pipeline test"` after the runbook completes.

---

## Prerequisites (One-time)
- PowerShell available with administrator access for service restarts.
- Windows OpenTelemetry Collector service installed as `otelcol-contrib` using `C:\otel\config.yaml`.
- SigNoz stack running in WSL2/Docker and reachable at `http://localhost:8080`, OTLP mapped to `14317/14318` (inside WSL) and bridged from Windows via `5317/5318`.
- Repository cloned at `C:\otel` with scripts in place.
- Local log folder `C:\logs` (scripts create it if missing).

---

## Pre-flight Checks
Run these before the canary if there is any doubt about environment health.

```powershell
# Make sure service exists and is running
Get-Service otelcol-contrib

# Confirm Windows collector ports are open
Test-NetConnection -ComputerName localhost -Port 5317
Test-NetConnection -ComputerName localhost -Port 5318

# Confirm SigNoz UI reachable (WSL2 stack)
Invoke-WebRequest -Uri http://localhost:8080 -UseBasicParsing | Select-Object StatusCode
```

Expected: `Status : Running` from `Get-Service`, `TcpTestSucceeded : True` for ports, and `StatusCode : 200` for SigNoz UI.

---

## Execute Runbook
Follow the steps in order; note which windows must be elevated.

### 1. Restart Windows Collector (elevated PowerShell)
```powershell
cd C:\otel
./restart-collector.ps1
```
Expected output (abridged):
```
Restarting Windows OTel Collector...
Service stopped successfully
Service started successfully
Port 5317 (gRPC) is listening
Port 5318 (HTTP) is listening
```
If the elevation guard triggers, reopen PowerShell as Administrator and rerun.

Manual fallback:
```powershell
Restart-Service otelcol-contrib -Force
Start-Sleep -Seconds 5
Get-Service otelcol-contrib
```

### 2. Emit Canary Signals (standard PowerShell)
```powershell
cd C:\otel
./canary-test.ps1
```
Expected output:
```
== Starting Observability Canary Test ==
[OK] Wrote canary log entry to C:\logs\canary-test.log
[OK] Created Windows Event Log entry
[OK] Sent OTLP trace (http://localhost:5318/v1/traces)
[OK] Sent OTLP log (http://localhost:5318/v1/logs)
```
The script prints follow-up verification hints for UI and Event Viewer.

Optional targeted check:
```powershell
./verify-pipeline.ps1
```
This validates the OTLP pipeline without re-emitting events.

### 3. Run Integration Verifier (standard PowerShell)
```powershell
cd C:\otel
./verify-integration.ps1
```
Key lines to confirm (truncated example):
```
[OK] Service otelcol-contrib is running
[OK] Windows collector (HTTP) port 5318 reachable
[OK] SigNoz UI reachable (HTTP 200)
[OK] Canary ID: <guid>
=== Integration verification PASSED ===
```
Capture the printed canary ID; it matches the record stored in SigNoz.

---

## Verification

### SigNoz UI (Logs)
1. Open `http://localhost:8080`.
2. Navigate: Observability -> Logs.
3. Apply filter `message contains "SigNoz pipeline test"`.
4. Confirm latest entry timestamp matches current run, with attributes:
   - `service.name = "canary-test"`
   - `synthetic_id = "pipeline-check"`
   - `resource.type = "windows"` (if mapped)

Optional additional filters:
- `log.file.path contains "C:/logs/canary-test.log"`
- `event.domain = "windows"`

### SigNoz UI (Traces)
Navigate to Traces and filter `canary = "true"` to see the synthetic span emitted by the script.

### Windows Event Viewer
Open **Event Viewer** -> Windows Logs -> Application -> filter Source = `SigNoz-Canary`. Expect an information event with the same message body.

### File Log Confirmation
```powershell
Get-Content C:\logs\canary-test.log -Tail 5 | Select-String "SigNoz pipeline test"
```
Expect at least one line appended with the current timestamp.

### Stored Canary ID Cross-check
```powershell
Select-String -Path artifacts\canary-ecrr-report.txt -Pattern "Canary ID"
```
The ID reported here should match the SigNoz log field `canary_id`.

---

## Troubleshooting

### Service Problems
```powershell
# Inspect recent Application log entries for the collector
Get-EventLog -LogName Application -Source otelcol-contrib -Newest 10

# Dry-run the collector configuration
"C:\Program Files\OpenTelemetry Collector\otelcol-contrib.exe" --config "C:\otel\config.yaml" --dry-run
```
If ports 5317/5318 are not listening, re-run the restart step or reboot the host after ensuring no conflicting services occupy those ports (`netstat -ano | findstr 5317`).

### SigNoz Stack Down
```powershell
# Requires WSL-enabled Docker context
cd C:\otel
docker ps | Select-String signoz
```
If containers are stopped, use `docker compose up -d` inside WSL2 (refer to SigNoz deploy docs) and rerun the runbook once healthy.

### Canary Script Failures
- **Event Log source missing**: run `New-EventLog -LogName Application -Source "SigNoz-Canary"` once with admin rights.
- **Log directory missing**: `New-Item -ItemType Directory -Path C:\logs -Force`.
- **OTLP HTTP rejects payload**: confirm Windows collector exporter in `config.yaml` points to `http://localhost:14318` (SigNoz) and `verify-integration.ps1` passes.

### Cannot Reach SigNoz UI
Check firewall or VPN settings. From Windows, run `Test-NetConnection localhost -Port 8080`. If false, inspect the WSL2 port forwarding rules and ensure Docker Desktop exposes the UI port.

---

## Quick Reference (copy/paste)
```powershell
# Elevated terminal
cd C:\otel
./restart-collector.ps1

# Standard terminal
cd C:\otel
./canary-test.ps1
./verify-integration.ps1
```
SigNoz UI path: `http://localhost:8080` -> Logs -> filter `message contains "SigNoz pipeline test"`.

---

## Next Steps / Automation Ideas
1. Add a scheduled task that runs `scripts\schedule-canary.ps1` (or `schedule-canary-simple.ps1`) to emit canaries hourly.
2. Import `signoz-health-canary-alert.json` into SigNoz to raise alerts when canaries go missing.
3. Extend `verify-integration.ps1` to push status to `.agent/status.json` for local dashboards.

---

## Verification Log (last known good)
- `restart-collector.ps1` executed successfully (requires admin). Output stored in `artifacts\hygiene.log`.
- `canary-test.ps1` emitted canary ID recorded in `artifacts\canary-ecrr-report.txt`.
- `verify-integration.ps1` produced `=== Integration verification PASSED ===` on 2025-09-20.

Keep this runbook alongside the scripts; update timestamps or commands whenever tooling changes.
