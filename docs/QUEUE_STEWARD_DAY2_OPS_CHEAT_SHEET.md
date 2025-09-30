# Queue Steward Day-2 Ops Cheat Sheet

**Purpose**: Pocket guide for on-call engineers - emergency response, health checks, and troubleshooting in one page.

---

## 🚨 **EMERGENCY RESPONSE** (30 seconds)

### **Instant Pause**
```powershell
New-Item -Path '.agent/LOCK' -ItemType File -Force
pnpm agent:status  # Verify: "Lock Present: YES"
```

### **Resume Processing**
```powershell
Remove-Item -Path '.agent/LOCK' -Force
pnpm agent:status  # Verify: "Lock Present: NO"
```

---

## 📊 **HEALTH CHECK** (2 minutes)

### **Quick Status**
```powershell
pnpm agent:status
```
**✅ Healthy**: `Queue Depth: <50`, `Shadow Mode: OFF`, `Lock Present: NO`

### **Health Log**
```powershell
Get-Content 'C:\logs\queue\health.log' -Tail 10
```
**✅ Healthy**: Recent timestamp (<5min), `killSwitch: false`

### **SigNoz Health**
```powershell
Invoke-RestMethod -Uri 'http://localhost:8080/api/v1/health'
```
**✅ Healthy**: `{"status":"ok"}`

---

## 🔍 **DIAGNOSTICS** (5 minutes)

### **Full Diagnostics Collection**
```powershell
pwsh -File scripts/collect-queue-diagnostics.ps1 -OutputDir artifacts
```
**Exit Codes**: `0=Healthy`, `1=Degraded`, `2=Critical`, `3=Script Error`

### **Nightly Diagnostics (includes canary)**
```powershell
pnpm agent:nightly-diagnostics
```

---

## 🧪 **CANARY TEST** (1 minute)

```powershell
pwsh -File scripts/canary-test.ps1
```
**✅ Pass**: Exit code 0, new logs in SigNoz with `message contains "queue_canary"`

---

## 📈 **SIGNOZ QUERIES** (SigNoz UI → Logs → SQL Console)

### **Queue Depth Trend**
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

### **Error Rate Check**
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
**✅ Healthy**: `error_count / total < 0.05`

---

## 🔧 **TROUBLESHOOTING MATRIX**

| **Symptom** | **Check** | **Action** |
|-------------|-----------|------------|
| Queue depth growing | `pnpm agent:status` | Add workers, check long jobs, ensure no LOCK |
| No jobs processing | Health log tail | Restart runner: `taskkill /F /IM node.exe` then `pnpm agent:runner` |
| JSON errors | Health log for `invalid JSON` | Inspect payloads, fix schema, purge bad jobs |
| SigNoz empty | Health endpoint, collector service | Restart SigNoz, restart Windows collector |

---

## 🔄 **MODE MANAGEMENT**

### **Check Mode**
```powershell
pnpm agent:status  # Look for "Shadow Mode: OFF/ON"
```

### **Force Shadow Mode (Rollback)**
```powershell
$env:QUEUE_SHADOW = '1'
taskkill /F /IM node.exe
pnpm agent:runner
```

### **Return to Canonical**
```powershell
$env:QUEUE_SHADOW = '0'
taskkill /F /IM node.exe
pnpm agent:runner
```

---

## 📞 **ESCALATION PACKAGE**

### **Auto Collection**
```powershell
pwsh -File scripts/collect-queue-diagnostics.ps1 -OutputDir artifacts -IncludeCanaryTest
```

### **Attach These Files**
- `diagnostics-summary-YYYYMMDD-HHMMSS.json` - Overall health status
- `queue-status-YYYYMMDD-HHMMSS.txt` - Current queue state
- `queue-health-YYYYMMDD-HHMMSS.log` - Recent health logs
- `signoz-health-YYYYMMDD-HHMMSS.txt` - SigNoz connectivity

---

## 🎯 **ALERT THRESHOLDS**

| **Metric** | **Warning** | **Critical** |
|------------|-------------|--------------|
| Queue Depth | >100 | >200 |
| Error Rate | >5% | >10% |
| Processing Gap | >10min | >15min |
| Job Latency P95 | >5min | >10min |

---

## 🔗 **QUICK LINKS**

- **SigNoz UI**: http://localhost:8080
- **Health Logs**: `C:\logs\queue\health.log`
- **Full Docs**: `docs/QUEUE_STEWARD_OPERATOR_QUICK_REFERENCE.md`
- **Crash Recovery**: `docs/runbooks/queue-crash-recovery.md`
- **Go-Live Checklist**: `docs/QUEUE_STEWARD_GO_LIVE_CHECKLIST.md`

---

## ⚡ **COMMAND REFERENCE**

```powershell
# Status & Health
pnpm agent:status
pnpm agent:verify
pnpm agent:nightly-diagnostics

# Diagnostics
pwsh -File scripts/collect-queue-diagnostics.ps1
pwsh -File scripts/canary-test.ps1

# Emergency
New-Item -Path '.agent/LOCK' -ItemType File -Force  # Pause
Remove-Item -Path '.agent/LOCK' -Force              # Resume
taskkill /F /IM node.exe                            # Kill processes

# Scheduling (Windows)
pwsh -File scripts/setup-nightly-task.ps1

# Scheduling (Linux/macOS)
bash scripts/setup-nightly-cron.sh
```

---

**Last Updated**: 2025-09-30  
**Maintainer**: Observability Copilot  
**Emergency Contact**: Queue Steward Team

---

> 💡 **Pro Tip**: Bookmark this page and keep `pnpm agent:status` output handy for quick health verification.
