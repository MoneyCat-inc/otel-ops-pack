# Queue Steward Operator Quick Reference

Purpose: Day-2 operations crib sheet for monitoring and troubleshooting the Queue Steward background worker.
System scope: SQLite-backed queue, canonical writes, SigNoz telemetry via local collectors.

---

## 1. Emergency Procedures

### Pause processing immediately
```powershell
# stop job execution instantly (idempotent)
New-Item -Path '.agent/LOCK' -ItemType File -Force

# confirm pause state
pnpm agent:status
```
Expected status excerpt:
```
Lock Present: YES
Shadow Mode: OFF
```

### Resume normal processing
```powershell
# remove the lock file to resume work
Remove-Item -Path '.agent/LOCK' -Force

# re-check status
pnpm agent:status
```
Expected status excerpt:
```
Lock Present: NO
Shadow Mode: OFF
```

---

## 2. Routine Health Monitoring

### Queue service snapshot
```powershell
pnpm agent:status
```
Healthy baseline:
```
Driver: sqlite
Shadow Mode: OFF
Queue Depth: < 50 (adjust for workload)
Running: < 10 workers
Admission Cap: 200
```

### Health log tail
```powershell
Get-Content 'C:\\logs\\queue\\health.log' -Tail 10
```
Expected log line format:
```json
{
  "timestamp": "2025-09-30T04:05:24.4701717+00:00",
  "dataset": "agent_queue",
  "queueLength": 1,
  "readyCount": 1,
  "jobsProcessed": 8,
  "killSwitch": false
}
```
Key checks: recent timestamp (< 5 minutes) and `killSwitch` remains `false`.

---

## 3. SigNoz Observability

### Collector and UI health
```powershell
Invoke-RestMethod -Uri 'http://localhost:8080/api/v1/health' -Method Get
```
Success returns `{ "status": "ok" }`.

### Primary queries (SigNoz Logs tab -> SQL)

Queue depth trend:
```sql
SELECT
  timestamp,
  JSON_EXTRACT(body, '$.queueLength') AS queue_length,
  JSON_EXTRACT(body, '$.readyCount') AS ready_count
FROM logs
WHERE dataset = 'agent_queue'
  AND timestamp > now() - INTERVAL 1 HOUR
ORDER BY timestamp DESC
LIMIT 100;
```

Jobs processed per minute:
```sql
SELECT
  toStartOfMinute(timestamp) AS minute,
  count() AS jobs_processed
FROM logs
WHERE dataset = 'agent_queue'
  AND JSON_EXTRACT(body, '$.jobsProcessed') > 0
  AND timestamp > now() - INTERVAL 1 HOUR
GROUP BY minute
ORDER BY minute DESC;
```

Error rate estimate:
```sql
SELECT
  toStartOfMinute(timestamp) AS minute,
  countIf(JSON_EXTRACT(body, '$.status') = 'error') AS error_count,
  count() AS total
FROM logs
WHERE dataset = 'agent_queue'
  AND timestamp > now() - INTERVAL 1 HOUR
GROUP BY minute
ORDER BY minute DESC;
```
Interpretation: `error_count / total` should stay under 0.05.

---

## 4. Functional Canary

Run the scripted canary to exercise the queue and telemetry:
```powershell
pwsh -File scripts/canary-test.ps1
```
Expected results:
- Exit code 0
- `artifacts/canary-result.txt` ends with `== Canary PASSED ==`
- New SigNoz logs visible with `message` containing `queue_canary`

Follow-up query (SigNoz -> Logs search):
```
message contains "queue_canary"
```

---

## 5. Troubleshooting Quick Table

| Symptom | Checks | Action |
| --- | --- | --- |
| Queue depth growing | `pnpm agent:status`, SigNoz queue depth query | Add workers, investigate long-running jobs, ensure `.agent/LOCK` absent |
| No jobs processing | `pnpm agent:status`, `Get-Content health.log -Tail 20` | Restart runner (`taskkill /F /IM node.exe` then `pnpm agent:runner`), confirm shadow mode disabled |
| JSON payload errors | `Get-Content health.log -Tail 20` for `invalid JSON` | Inspect queued payloads, fix producer schema, purge malformed jobs |
| SigNoz empty | Health endpoint, `Get-Service opentelemetry-collector` | Restart SigNoz compose stack, restart Windows collector, confirm ports 14317/14318 and 5317/5318 free |

---

## 6. Mode Management

### Check current mode
```powershell
pnpm agent:status
```
Look for `Shadow Mode: OFF` (canonical) or `Shadow Mode: ON` (shadow).

### Force shadow mode (rollback)
```powershell
$env:QUEUE_SHADOW = '1'
taskkill /F /IM node.exe
pnpm agent:runner
```

### Return to canonical mode
```powershell
$env:QUEUE_SHADOW = '0'
taskkill /F /IM node.exe
pnpm agent:runner
```
Verify with `pnpm agent:status` after restart.

---

## 7. Performance and Alerts

Metrics to track:
- Queue depth < 50 typical, alert at 100 (warning) and 200 (critical)
- Error rate < 5% warning, < 10% critical
- Jobs processed per minute steady with no 10 minute gaps
- p95 job latency < 5 minutes (derive from job start/finish timestamps)

Suggested alerting rules (SigNoz Alerts -> Create):
1. Queue depth critical: `max(queue_length) > 200` for 15 minutes
2. Error rate: `sum(error_count) / sum(total) > 0.1` for 10 minutes
3. Processing stall: `count() < 1` over 15 minutes window

---

## 8. Escalation Package

### Automated Diagnostics Collection
```powershell
# Run comprehensive diagnostics collection
pwsh -File scripts/collect-queue-diagnostics.ps1 -OutputDir "artifacts"

# Include canary test in diagnostics
pwsh -File scripts/collect-queue-diagnostics.ps1 -OutputDir "artifacts" -IncludeCanaryTest
```

### Manual Diagnostics Collection
```powershell
# Collect individual diagnostic files
pnpm agent:status > artifacts/queue-status-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt
Get-Content 'C:\\logs\\queue\\health.log' -Tail 50 > artifacts/queue-health-$(Get-Date -Format 'yyyyMMdd-HHmmss').log
Get-Service opentelemetry-collector > artifacts/collector-service-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt
```

**Diagnostics Script Features:**
- Automatic file naming with timestamps
- JSON summary with overall health status
- Exit codes: 0=Healthy, 1=Degraded, 2=Critical, 3=Script Error
- Collects: Queue status, health logs, collector service, SigNoz health, environment info
- Optional canary test integration

**Escalation Package Contents:**
When escalating issues, attach these files from the latest diagnostics run:
- `diagnostics-summary-YYYYMMDD-HHMMSS.json` - Overall health status and metrics
- `queue-status-YYYYMMDD-HHMMSS.txt` - Current queue state and configuration
- `queue-health-YYYYMMDD-HHMMSS.log` - Recent health log entries
- `signoz-health-YYYYMMDD-HHMMSS.txt` - SigNoz connectivity status
- `collector-service-YYYYMMDD-HHMMSS.txt` - Windows Collector service state
- `environment-info-YYYYMMDD-HHMMSS.txt` - System and environment details

### Nightly Diagnostics with Canary Integration
```powershell
# Run nightly diagnostics (includes canary test + artifact cleanup)
pwsh -File scripts/nightly-queue-diagnostics.ps1 -OutputDir "artifacts" -RetentionDays 7

# Or via npm script
pnpm agent:nightly-diagnostics
```

**Nightly Features:**
- Comprehensive diagnostics collection with canary test
- Automatic artifact cleanup (configurable retention)
- Trend analysis comparing with previous runs
- Windows Event Log integration for monitoring
- JSON summary with health status and cleanup metrics

### Automated Scheduling Setup

**Windows Task Scheduler:**
```powershell
# Run as Administrator to create scheduled task
pwsh -File scripts/setup-nightly-task.ps1 -WorkingDirectory "C:\otel" -StartTime "02:00"
```

**Linux/macOS Cron:**
```bash
# Run to add cron job for 2:00 AM daily
bash scripts/setup-nightly-cron.sh
```

**Manual Scheduling:**
- **Windows**: Use Task Scheduler UI (`taskschd.msc`) to create daily task at 2:00 AM
- **Linux/macOS**: Add to crontab: `0 2 * * * cd /path/to/otel && pnpm agent:nightly-diagnostics`

---

## 9. Quick Links

- **🚀 Day-2 Ops Cheat Sheet**: `docs/QUEUE_STEWARD_DAY2_OPS_CHEAT_SHEET.md` (single-page pocket guide)
- SigNoz UI: http://localhost:8080
- Health logs: `C:\\logs\\queue\\health.log`
- Crash recovery runbook: `docs/runbooks/queue-crash-recovery.md`
- Go-live checklist: `docs/QUEUE_STEWARD_GO_LIVE_CHECKLIST.md`
- SigNoz compliance alerts: `docs/SIGNOZ_ECRR_COMPLIANCE_ALERT_GUIDE.md`
- Diagnostics script: `scripts/collect-queue-diagnostics.ps1`
- Nightly diagnostics: `scripts/nightly-queue-diagnostics.ps1` (includes canary + cleanup)
- Windows scheduler: `scripts/setup-nightly-task.ps1` (Task Scheduler setup)
- Linux/macOS scheduler: `scripts/setup-nightly-cron.sh` (cron setup)

---

Last updated: 2025-09-30
Maintainer: Observability Copilot