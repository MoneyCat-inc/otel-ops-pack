# Watchdog Protocol - GATE & SITE Bots

## Overview

**GATE Bot** - Guardian that monitors and restarts Windows Collector  
**SITE Bot** - Observer that monitors health endpoints and collects diagnostics

Both bots respect the kill-switch (`.agent/LOCK`) and follow ECRR methodology.

---

## Quick Start

### Deploy Both Bots
```powershell
pwsh -File BRAV/SCPT/watchdog-control.ps1 start both
```

### Deploy Individual Bots
```powershell
# Start GATE only (requires admin for restarts)
pwsh -File BRAV/SCPT/watchdog-control.ps1 start gate

# Start SITE only (monitoring/diagnostics)
pwsh -File BRAV/SCPT/watchdog-control.ps1 start site
```

### Custom Interval
```powershell
# Check every 15 seconds
pwsh -File BRAV/SCPT/watchdog-control.ps1 start both -Interval 15
```

### Dry Run (GATE only - no actual restarts)
```powershell
pwsh -File BRAV/SCPT/watchdog-control.ps1 start gate -DryRun
```

---

## Status & Monitoring

### Check Status
```powershell
pwsh -File BRAV/SCPT/watchdog-control.ps1 status both
```

### View Logs
```powershell
# View last 20 lines of both bots
pwsh -File BRAV/SCPT/watchdog-control.ps1 logs both

# View specific bot
pwsh -File BRAV/SCPT/watchdog-control.ps1 logs gate
```

### View Evidence
```powershell
# Show collected evidence
pwsh -File BRAV/SCPT/watchdog-control.ps1 evidence both
```

---

## Stop Bots

### Stop All
```powershell
pwsh -File BRAV/SCPT/watchdog-control.ps1 stop both
```

### Stop Individual
```powershell
pwsh -File BRAV/SCPT/watchdog-control.ps1 stop gate
```

### Emergency Kill-Switch
```powershell
# Create kill-switch manually
New-Item -ItemType File -Path .agent/LOCK

# Both bots will detect and shutdown gracefully
# Remove when ready to resume
Remove-Item .agent/LOCK
```

---

## Evidence Locations

**GATE Bot:**
- Log: `DELT/ARTF/watchdog-gate.log`
- Evidence: `DELT/ARTF/watchdog-gate-evidence.json`

**SITE Bot:**
- Log: `DELT/ARTF/watchdog-site.log`
- Snapshots: `docs/observability/snapshots/site-observations/`

---

## Typical Workflow

### 1. Deploy watchdogs
```powershell
# Start with monitoring only (no admin needed)
pwsh -File BRAV/SCPT/watchdog-control.ps1 start site

# Separately start GATE as admin (for restart capability)
Start-Process pwsh -Verb RunAs -ArgumentList "-File","BRAV/SCPT/watchdog-control.ps1","start","gate"
```

### 2. Monitor
```powershell
# Watch status
pwsh -File BRAV/SCPT/watchdog-control.ps1 status both

# Tail logs in real-time
Get-Content DELT/ARTF/watchdog-site.log -Wait -Tail 10
```

### 3. Review evidence
```powershell
# Check what SITE observed
pwsh -File BRAV/SCPT/watchdog-control.ps1 evidence site

# Check GATE actions
pwsh -File BRAV/SCPT/watchdog-control.ps1 evidence gate
```

### 4. Stop when done
```powershell
pwsh -File BRAV/SCPT/watchdog-control.ps1 stop both
```

---

## Bot Behavior

### GATE Bot
- **Checks:** Service status every N seconds
- **Action:** Restarts `otelcol-contrib` if stopped
- **Requires:** Admin privileges for restart capability
- **Evidence:** Logs checks, restart attempts, success/failure rates

### SITE Bot
- **Checks:** Health endpoint (:13133), Metrics (:8888)
- **Action:** Collects diagnostics (service state, ports, processes)
- **Requires:** No special privileges
- **Evidence:** Snapshots with health trends and patterns

---

## Troubleshooting

### GATE can't restart service
```
ERROR: PERMISSION ERROR: GATE requires admin privileges
```
**Solution:** Run as admin:
```powershell
Start-Process pwsh -Verb RunAs -ArgumentList "-File","BRAV/SCPT/watchdog-gate.ps1"
```

### Bots won't stop
**Solution:** Use kill-switch:
```powershell
New-Item -ItemType File -Path .agent/LOCK
# Wait 30-60 seconds
Remove-Item .agent/LOCK
```

### Check if bots are running
```powershell
Get-Process -Name pwsh | Where-Object { $_.CommandLine -like "*watchdog*" }
```

---

## Integration with Gate

Run watchdogs before gate verification:
```powershell
# 1. Deploy watchdogs
pwsh -File BRAV/SCPT/watchdog-control.ps1 start both

# 2. Wait 2-3 minutes for observations
Start-Sleep -Seconds 180

# 3. Run gate check
pwsh -File scripts/verify-iona-gate-full.ps1

# 4. Review watchdog evidence
pwsh -File BRAV/SCPT/watchdog-control.ps1 evidence both

# 5. Stop watchdogs
pwsh -File BRAV/SCPT/watchdog-control.ps1 stop both
```

---

## ECRR Framework

Both bots follow ECRR:
- **Examine:** Check service/endpoint state
- **Clean:** Take corrective action (restart) or diagnose
- **Report:** Log findings and export evidence
- **Role:** GATE (guardian) or SITE (observer)

---

## Log Rotation

Both watchdogs automatically rotate logs when they reach 10MB:
- **Max Size:** 10MB per log file
- **Keep Files:** 5 old logs (watchdog-*.log.1 through watchdog-*.log.5)
- **Auto-Cleanup:** Oldest logs deleted automatically
- **Rotation Event:** Logged to new file for audit trail

**Log Files:**
```
DELT/ARTF/watchdog-gate.log       (current)
DELT/ARTF/watchdog-gate.log.1     (previous)
DELT/ARTF/watchdog-gate.log.2     (older)
...
DELT/ARTF/watchdog-gate.log.5     (oldest kept)
```

**Manual Rotation (if needed):**
```powershell
# Force rotation of GATE log
Move-Item DELT/ARTF/watchdog-gate.log DELT/ARTF/watchdog-gate.log.1 -Force
```

