# Agent Runbook - Observability Pipeline

## Quick Start

### 1. Enqueue a Task
```powershell
.\ .agent\scripts\enqueue-task.ps1 '{"id":"T-2025-09-17-006","title":"Test task","goal":"Test the agent system","acceptance":["test passes"],"scope":{"paths":["test.txt"]},"priority":"L","deadline":"2025-09-25"}'
```

### 2. Run codex-local
```powershell
.\ .agent\scripts\run-codex.ps1
```

### 3. Review with cursor-local
- Open new Cursor chat
- Set system prompt to `.agent/cursor.prompt.md`
- Paste PR context for review

## Escalation Procedures

### Collector Service Issues
1. Check service status: `sc query otelcol-contrib`
2. Restart if needed: `.\restart-collectors.ps1`
3. Validate config: `& "C:\Program Files\OpenTelemetry Collector\otelcol-contrib.exe" validate --config config.yaml`
4. If still failing, escalate to `ALERTS.log`

### Canary Test Failures
1. Check SigNoz connectivity: `Test-NetConnection -ComputerName localhost -Port 8080`
2. Check collector port: `Test-NetConnection -ComputerName localhost -Port 5318`
3. Run simple test: `.\simple-test.ps1`
4. If all fail, restart collector service

### Agent System Issues
1. Check task queue: `Get-Content .agent\state\queue.jsonl`
2. Run smoke tests: `node .agent\tools\smoke.mjs`
3. Check results log: `Get-Content .agent\state\results.jsonl`

## Break-Glass Procedures

### Emergency Collector Restart
```powershell
Stop-Process -Name "otelcol-contrib" -Force
Start-Sleep -Seconds 5
& "C:\Program Files\OpenTelemetry Collector\otelcol-contrib.exe" --config config.yaml
```

### Reset Agent State
```powershell
Remove-Item .agent\state\queue.jsonl -Force
# Recreate with initial tasks
```

### Rollback Configuration
```powershell
Copy-Item config-hardened.yaml config.yaml -Force
.\restart-collectors.ps1
```

## Monitoring

### Health Checks
- Collector port 5318: `Test-NetConnection -ComputerName localhost -Port 5318`
- SigNoz port 8080: `Test-NetConnection -ComputerName localhost -Port 8080`
- Canary test: `.\canary-check.ps1`

### Logs
- Collector logs: Windows Event Logs
- Agent logs: `.agent\state\results.jsonl`
- Alerts: `ALERTS.log` (if created)

## Contact
- Primary: Cursor Agent (autonomous)
- Escalation: Human operator
- Emergency: Break-glass procedures above

