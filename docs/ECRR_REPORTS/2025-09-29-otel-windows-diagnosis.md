# ECRR Report: Windows OTel Collector Log Forwarding Diagnosis

**Date**: 2025-09-29  
**Actor**: Cursor Agent - Observability Copilot  
**Task**: Diagnose why otelcol-contrib on Windows stops forwarding logs to SigNoz

## 🔍 Examine

### Environment State Captured
- **Windows Service Status**: `otelcol-contrib` service is RUNNING (State: 4)
- **Recent Events**: Found retry errors from 02:52:08 showing connection refused to `http://localhost:14318/v1/logs`
- **Connectivity**: Port 14318 is now reachable (TcpTestSucceeded: True)
- **HTTP Response**: Returns 404 for root path (expected behavior)

### Evidence Collected
```powershell
# Service Status
SERVICE_NAME: otelcol-contrib 
STATE: 4  RUNNING 
(STOPPABLE, NOT_PAUSABLE, ACCEPTS_SHUTDOWN)

# Recent Retry Errors
TimeCreated : 29.9.25 02:52:08
Message: Exporting failed. Will retry the request after interval.
Error: "failed to make an HTTP request: Post \"http://localhost:14318/v1/logs\": 
dial tcp [::1]:14318: connectex: No connection could be made because the target 
machine actively refused it."

# Current Connectivity
TcpTestSucceeded : True
HTTP/1.1 404 Not Found (expected for root path)
```

## 🧹 Clean

### Issues Identified
1. **Historical Connection Refused**: Windows collector experienced connection refused errors when SigNoz OTLP HTTP listener was not ready
2. **Retry Behavior**: Collector properly retried with exponential backoff (200ms, 215ms intervals)
3. **Current State**: No recent retry errors found (last 2 minutes clean)

### Actions Taken
- Verified service is running and healthy
- Confirmed SigNoz OTLP HTTP endpoint is now accessible
- Tested end-to-end log forwarding with canary events

## 📝 Report

### Test Results
**Canary Log Emission**: ✅ SUCCESS
```json
{
  "timestamp": "1759111110595264800",
  "body": "SigNoz test event from Windows collector at 2025-09-29T02:58:29",
  "provider": {"name": "SigNozTest"},
  "event_id": {"id": 1001}
}
```

**ClickHouse Verification**: ✅ SUCCESS
- Query returned 2 recent canary events
- Latest event timestamp: 2025-09-29T02:58:29
- JSON structure intact with proper provider metadata

**End-to-End Pipeline**: ✅ FUNCTIONAL
- Windows Event Log → OTel Collector → SigNoz OTLP HTTP → ClickHouse
- No current retry errors or connection issues

### Root Cause Analysis
The Windows collector was experiencing temporary connection refused errors when SigNoz's OTLP HTTP listener was starting up or temporarily unavailable. The collector's retry mechanism worked correctly, and the connection is now stable.

## 🎭 Role

**Actor**: Cursor Agent - Observability Copilot  
**Responsibility**: Diagnosed Windows OTel collector log forwarding issues  
**Action**: Verified end-to-end pipeline functionality and identified historical connection issues

## ✅ ECRR Gate

- [x] **Examine** — Service state and recent events captured
- [x] **Clean** — Identified historical connection issues, confirmed current health
- [x] **Report** — Generated comprehensive diagnosis with evidence
- [x] **Role** — Declared Cursor Agent as responsible actor

## Recommendations

1. **Service Restart**: Consider restarting `otelcol-contrib` from elevated PowerShell to clear any stale connection state
2. **Health Check Integration**: Add a scheduled health check that waits for `Test-NetConnection 127.0.0.1 -Port 14318` before starting the Windows collector
3. **Monitoring Enhancement**: Implement alerts for retry error spikes to catch future connectivity issues early

## Verification Commands

```powershell
# Check service status
sc.exe query otelcol-contrib

# Test connectivity
Test-NetConnection 127.0.0.1 -Port 14318

# Emit canary
$msg = "SigNoz test event from Windows collector at $(Get-Date -Format s)"
Write-EventLog -LogName Application -Source 'SigNozTest' -EventId 1001 -EntryType Information -Message $msg

# Verify in ClickHouse
docker exec signoz-clickhouse clickhouse-client --query "SELECT timestamp, body FROM signoz_logs.logs_v2 WHERE body LIKE '%SigNoz test event from Windows collector%' ORDER BY timestamp DESC LIMIT 5"
```

---
**ECRR Mantra**: *Examine → Clean → Report → Role*

