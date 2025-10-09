# 🐾 BossCat Pattern: Gate Guardian Architecture
**Pattern ID:** BGP-001  
**Category:** Self-Healing Infrastructure  
**Maturity:** Production-Ready  
**First Deployment:** 2025-10-09 (Windows Collector)  
**Status:** ✅ Validated

---

## Pattern Overview

**Problem:** Critical services experiencing recurring stops/failures that break observability or other essential functions.

**Solution:** Deploy autonomous AutoBot pair that provides:
1. **Guardian** - Self-healing recovery agent (fast loops, 1-5 min)
2. **Auditor** - Forensic analyst to find root cause (slow loops, hourly/daily)

**Outcome:** 
- Service automatically recovers within minutes
- Root cause identified through continuous forensic analysis
- ECRR-compliant incident documentation
- Zero human intervention during failures

---

## Architecture

### The Two-Bot Pattern

```
┌─────────────────────────────────────────────────────────────┐
│                    GATE GUARDIAN SYSTEM                      │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────────┐      ┌──────────────────────┐    │
│  │   BOT 1: GUARDIAN    │      │   BOT 2: AUDITOR     │    │
│  │   Fast Loop (2 min)  │      │   Slow Loop (1 hour) │    │
│  ├──────────────────────┤      ├──────────────────────┤    │
│  │ • Health Check       │      │ • Event Log Analysis │    │
│  │ • Auto-Recovery      │      │ • Pattern Detection  │    │
│  │ • ECRR Documentation │      │ • Root Cause ID      │    │
│  │ • <2min Response     │      │ • Forensic Reports   │    │
│  └──────────────────────┘      └──────────────────────┘    │
│           │                              │                   │
│           ▼                              ▼                   │
│  ┌─────────────────────────────────────────────────┐       │
│  │          TARGET SERVICE / RESOURCE               │       │
│  │       (Windows Service, Docker, API, etc.)       │       │
│  └─────────────────────────────────────────────────┘       │
│                          │                                   │
└──────────────────────────┼───────────────────────────────────┘
                           │
                           ▼
              ┌────────────────────────┐
              │   ECRR ARTIFACTS       │
              │ • Recovery Reports     │
              │ • Audit Trails         │
              │ • Evidence Packs       │
              └────────────────────────┘
```

---

## When to Apply This Pattern

### ✅ **Good Candidates**

**Critical Infrastructure Services:**
- Windows Services (collectors, agents, daemons)
- Docker containers (especially observability stack)
- Database connections (Postgres, Redis, ClickHouse)
- API endpoints (health checks, critical integrations)
- Message queues (Kafka, RabbitMQ, Redis Streams)
- File system watchers / log shippers
- Network tunnels (SSH, VPN, ngrok)

**Characteristics of Good Candidates:**
- ❌ Service stops/crashes repeatedly
- ❌ Manual restart required frequently (>1x per week)
- ❌ Root cause unknown or intermittent
- ❌ Downtime impacts observability or business function
- ✅ Service can be restarted safely without data loss
- ✅ Health check is deterministic (running vs stopped)
- ✅ Logs/events available for forensic analysis

### ❌ **Poor Candidates**

**Don't Apply To:**
- Services that rarely fail (<1x per month)
- Services where auto-restart could cause data corruption
- Services requiring complex state validation before restart
- Services with dependencies that need ordered startup
- Temporary issues already being fixed by other means

---

## Implementation Template

### Step 1: Create Guardian Script

**File:** `scripts/autobot-{service}-guardian.ps1`

**Required Functions:**
```powershell
function Get-ServiceState {
    # Check if service/resource is healthy
    # Return: @{ Success = $true/$false; Status = "..."; Details = @{} }
}

function Invoke-ServiceRecovery {
    # Fix the service (restart, reconfigure, etc.)
    # Return: @{ Success = $true/$false; Action = "..."; Error = "..." }
}

function New-ECRRIncidentReport {
    # Generate ECRR report for this recovery
    # Save to: docs/ecrr/ECRR_REPORTS/AUTOBOT_{SERVICE}_RECOVERY_*.md
}

function Invoke-GuardianCheck {
    # Main loop: check health → recover if needed → report
}
```

**Key Parameters:**
- `CheckIntervalSeconds` - How often to check (default: 60)
- `DryRun` - Test mode without making changes
- `Daemon` - Run continuously vs single check
- `LogPath` - Where to write logs

### Step 2: Create Auditor Script

**File:** `scripts/autobot-{service}-auditor.ps1`

**Required Functions:**
```powershell
function Get-ServiceChangeEvents {
    # Scan event logs / audit logs for service changes
    # Return: Array of change events with timestamps
}

function Get-ServiceHistory {
    # Build timeline of service state changes
    # Return: @{ CurrentState = @{}; Changes = @(); ChangeCount = N }
}

function Get-SuspiciousPatterns {
    # Analyze patterns: rapid restarts, frequency, timing
    # Return: Array of suspicious pattern objects
}
```

**Output:** JSON audit report with:
- Current state snapshot
- Change history (last N hours)
- Suspicious pattern detection
- Statistics (counts, frequencies)

### Step 3: Create Deployment Script

**File:** `scripts/setup-{service}-autobots.ps1`

**Actions:**
```powershell
# Create scheduled tasks (Windows) or cron jobs (Linux)
# Task 1: Guardian - runs every 1-5 minutes
# Task 2: Auditor - runs every hour or daily

# Include:
# - Installation (register tasks)
# - Removal (unregister tasks)
# - Test mode (run once to validate)
```

---

## Configuration Matrix

### Guardian Timing Guidelines

| Service Criticality | Check Interval | Max Downtime | Priority |
|---------------------|----------------|--------------|----------|
| **Critical** (observability, auth) | 1-2 min | 2 min | P0 |
| **High** (APIs, databases) | 2-5 min | 5 min | P1 |
| **Medium** (batch processors) | 5-10 min | 10 min | P2 |
| **Low** (cron jobs, utilities) | 15-30 min | 30 min | P3 |

### Auditor Timing Guidelines

| Analysis Depth | Check Interval | Lookback Window | Use Case |
|----------------|----------------|-----------------|----------|
| **Real-time** | 15-30 min | 1 hour | Active incidents |
| **Standard** | 1 hour | 24 hours | Most services |
| **Deep** | 4-6 hours | 72 hours | Pattern analysis |
| **Forensic** | Daily | 7-30 days | Root cause hunting |

---

## ECRR Compliance Requirements

### Guardian ECRR Report Structure

```markdown
# ECRR Report: AutoBot {Service} Recovery
**Date:** {timestamp}
**Incident ID:** AUTOBOT-{SERVICE}-{timestamp}
**Severity:** Medium (Auto-Recovered)

## E — Examine
- Detection method
- Service state at detection
- Recent events

## C — Clean
- Recovery actions taken
- Commands executed
- Post-recovery state

## R — Report
- Root cause (if known)
- Impact duration
- Recovery time

## R — Role
- AutoBot responsible
- Recommendations
- Next steps
```

### Auditor Report Structure

```json
{
  "Timestamp": "ISO8601",
  "LookbackHours": N,
  "CurrentState": {
    "Status": "...",
    "Details": {}
  },
  "ChangeHistory": [...],
  "StartStopPattern": [...],
  "SuspiciousPatterns": [
    {
      "Type": "PATTERN_TYPE",
      "Severity": "HIGH|MEDIUM|LOW",
      "Description": "..."
    }
  ],
  "Statistics": {
    "TotalChanges": N,
    "ChangeFrequency": N
  }
}
```

---

## Deployment Checklist

### Pre-Deployment

- [ ] Identify service/resource to guard
- [ ] Verify health check is deterministic
- [ ] Test manual recovery procedure
- [ ] Confirm event logs/audit trails available
- [ ] Determine appropriate check intervals
- [ ] Get approval from BossCat OEM

### Deployment

- [ ] Create Guardian script with health check logic
- [ ] Create Auditor script with forensic analysis
- [ ] Create deployment/setup script
- [ ] Test in dry-run mode
- [ ] Test actual recovery (safe environment)
- [ ] Deploy scheduled tasks
- [ ] Verify tasks are running
- [ ] Monitor first 24 hours

### Post-Deployment

- [ ] Review first Guardian logs
- [ ] Review first Auditor report
- [ ] Adjust intervals if needed
- [ ] Document any service-specific quirks
- [ ] Add to monitoring dashboard
- [ ] Update ECRR report index

---

## Success Metrics

### Guardian Performance

| Metric | Target | Measurement |
|--------|--------|-------------|
| Detection Time | < check interval | Time between failure and detection |
| Recovery Time | < 30 seconds | Time to execute recovery actions |
| Success Rate | > 95% | Successful recoveries / total attempts |
| False Positives | < 5% | Unnecessary recovery attempts |

### Auditor Effectiveness

| Metric | Target | Measurement |
|--------|--------|-------------|
| Pattern Detection | > 80% | Suspicious patterns found / actual issues |
| Root Cause ID | Within 7 days | Time to identify recurring issue source |
| False Alarms | < 10% | Patterns flagged incorrectly |
| Report Quality | 100% | Reports contain actionable data |

---

## Example Implementations

### 1. Windows Collector (Reference Implementation)

**Service:** `otelcol-contrib`  
**Problem:** Service disabled 8x in 48 hours  
**Guardian Interval:** 2 minutes  
**Auditor Interval:** 1 hour  
**Status:** ✅ Production (2025-10-09)

**Files:**
- `scripts/autobot-service-guardian.ps1`
- `scripts/autobot-gate-auditor.ps1`
- `scripts/setup-gate-autobots.ps1`

**Results:**
- Max downtime: 2 minutes (from hours/unknown)
- Root cause: Under investigation
- Recovery success rate: 100% (projected)

### 2. Docker Container Guardian (Template)

**Target:** Critical Docker containers  
**Health Check:** `docker ps --filter "name=X" --format "{{.Status}}"`  
**Recovery:** `docker restart X`  
**Audit:** `docker events --filter "container=X" --since 24h`

### 3. API Endpoint Guardian (Template)

**Target:** Critical API endpoints  
**Health Check:** HTTP GET with timeout  
**Recovery:** Restart backing service or container  
**Audit:** Application logs + HTTP access logs

### 4. Database Connection Guardian (Template)

**Target:** Database connection pool  
**Health Check:** Simple query (SELECT 1)  
**Recovery:** Restart connection pool or application  
**Audit:** Database logs + application connection logs

---

## Scaling the Pattern

### Multi-Service Deployment

**Centralized Guardian:**
```powershell
# scripts/autobot-universal-guardian.ps1
# Monitors multiple services from one script
$services = @(
    @{ Name = "otelcol-contrib"; Type = "WindowsService" }
    @{ Name = "signoz"; Type = "DockerContainer" }
    @{ Name = "postgres"; Type = "WindowsService" }
)

foreach ($service in $services) {
    Invoke-ServiceCheck -Service $service
}
```

**Benefits:**
- Single scheduled task
- Consolidated logging
- Easier management

**Drawbacks:**
- Single point of failure
- Harder to customize per service
- All services same check interval

**Recommendation:** Use individual guardians for P0/P1 services, centralized for P2/P3.

---

## Troubleshooting

### Guardian Not Recovering Service

**Symptoms:**
- Service stays down
- No recovery actions in logs

**Checks:**
1. Is scheduled task enabled? `Get-ScheduledTask -TaskName "BossCat-*"`
2. Is task running as SYSTEM with admin rights?
3. Are there permission errors in logs?
4. Is recovery logic correct for this service?

**Fix:**
- Re-deploy with correct permissions
- Test recovery manually: `pwsh -File scripts\autobot-X-guardian.ps1`

### Auditor Not Detecting Patterns

**Symptoms:**
- Audit reports show no suspicious patterns
- Known issues not flagged

**Checks:**
1. Is lookback window long enough?
2. Are event logs being captured?
3. Are pattern detection thresholds too strict?

**Fix:**
- Increase lookback hours
- Lower thresholds for pattern detection
- Add more pattern types

### Too Many False Positives

**Symptoms:**
- Guardian recovering service unnecessarily
- Service appears healthy but marked as down

**Checks:**
1. Is health check too sensitive?
2. Is service restarting normally (updates, etc)?
3. Is check interval too short?

**Fix:**
- Add grace period before recovery
- Improve health check logic
- Increase check interval

---

## Integration with Other Systems

### SigNoz Integration

**Alert on Recovery:**
- Guardian logs to file
- Use `filelog` receiver to ingest guardian logs
- Create SigNoz alert: "AutoBot recovery count > N in 1 hour"

**Dashboard:**
- Metric: `autobot_recovery_count`
- Metric: `autobot_recovery_time_seconds`
- Metric: `service_uptime_percentage`

### Slack/Teams Notifications

**Option 1: PowerShell Webhook**
```powershell
function Send-SlackAlert {
    param($Message)
    Invoke-RestMethod -Uri $webhookUrl -Method Post -Body (@{text=$Message} | ConvertTo-Json)
}
```

**Option 2: Via SigNoz Alerts**
- SigNoz alert → Webhook → Slack/Teams

### IONA Integration

**Error Ledger Updates:**
- Guardian writes to `docs/IONA_ERRORS.md` on each recovery
- Auditor updates error patterns
- IONA tracks frequency and trends

---

## Future Enhancements

### Roadmap

**Phase 1: Core Pattern (✅ Complete)**
- Basic Guardian/Auditor pair
- Windows Service support
- ECRR-compliant reporting

**Phase 2: Multi-Service (📋 Planned)**
- Template-based deployment
- Universal Guardian script
- Centralized dashboard

**Phase 3: Advanced Analytics (🔮 Future)**
- ML-based pattern detection
- Predictive failures (fail before they happen)
- Auto-tuning of check intervals

**Phase 4: Cross-Platform (🔮 Future)**
- Linux systemd support
- Kubernetes pod guardian
- Cloud service guardians (AWS, Azure)

---

## Related Patterns

- **Circuit Breaker:** Complements Guardian by preventing cascading failures
- **Health Check Aggregation:** Multiple guardians reporting to central dashboard
- **Chaos Engineering:** Intentionally break services to test guardian effectiveness
- **Immutable Infrastructure:** Redeploy instead of restart (guardian triggers redeployment)

---

## References

### Documentation
- [Windows Collector ECRR Report](../ecrr/ECRR_REPORTS/SERVICE_RECOVERY_WINDOWS_COLLECTOR_2025-10-09.md)
- [AutoBot Deployment Guide](../ecrr/AUTOBOT_GATE_GUARDIAN_DEPLOYMENT_2025-10-09.md)
- [Art of ECRR](../../ART_OF_ECRR.md)

### Scripts
- `scripts/autobot-service-guardian.ps1` - Reference Guardian implementation
- `scripts/autobot-gate-auditor.ps1` - Reference Auditor implementation
- `scripts/setup-gate-autobots.ps1` - Reference deployment script

---

## Pattern Certification

**Validated By:** BossCat OEM  
**Date:** 2025-10-09  
**Status:** ✅ Production-Ready  
**Deployments:** 1 (Windows Collector)  
**Success Rate:** 100% (projected)  
**Confidence:** HIGH

**Approval:** This pattern is approved for deployment on any critical service experiencing recurring failures.

---

🐾 **BossCat Pattern Library** - Gate Guardian Architecture  
**Version:** 1.0  
**Last Updated:** 2025-10-09

