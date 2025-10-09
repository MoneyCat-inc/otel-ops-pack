# 🐾 BossCat OEM - Operator Quick Start

**Gate Status:** ✅ APPROVED (98/100)  
**Last Updated:** 2025-10-08 23:50:00 UTC  
**Confidence:** 95% (High)

---

## Quick Commands

### 1️⃣ End-to-End Verification (One Command)
```powershell
# Runs quick-monitor + canary + gate checks + JSON summary
pwsh -File scripts\verify-pipeline.ps1

# Exit codes:
#   0 = OK (GREEN) - All checks passed
#   1 = WARN (YELLOW) - Manual verification recommended
#   2 = FAIL (RED) - Gate rollback required
```

### 2️⃣ Quick Health Check
```powershell
# Fast status check (services, ports, docker)
pwsh -File scripts\quick-monitor.ps1
```

### 3️⃣ Send Canary Trace
```powershell
# Send test trace and verify ingestion
pwsh -File scripts\send-canary-trace.ps1
```

### 4️⃣ Check Nightly Export
```powershell
# Validate dashboard export (run after 02:00 UTC)
pwsh -File scripts\check-nightly-export.ps1
```

### 5️⃣ Flip Gate Status
```powershell
# Set gate to HOLD if issues detected
pwsh -File scripts\set-gate-status.ps1 -Status HOLD -Reason "Collector failure"

# Set gate back to APPROVED
pwsh -File scripts\set-gate-status.ps1 -Status APPROVED -Reason "Recovery verified"
```

---

## Console Encoding Fix

If you see garbled box characters (`���������`), run this first:

```powershell
chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
```

Or add to your PowerShell profile:
```powershell
notepad $PROFILE
# Add the two lines above, save, restart PowerShell
```

---

## Automated Workflows

### Nightly Verification (GitHub Actions)
```yaml
# Already configured in: .github/workflows/gate-nightly.yml
# Runs: 02:03 UTC daily
# Manual trigger: GitHub Actions → gate-nightly → Run workflow
```

### Task Scheduler (Windows Local)
```powershell
# Schedule nightly export check
schtasks /Create /TN "NightlyDashboardExportCheck" `
  /TR "pwsh -File C:\otel\scripts\check-nightly-export.ps1" `
  /SC DAILY /ST 02:03

# Schedule full verification
schtasks /Create /TN "GateVerification" `
  /TR "pwsh -File C:\otel\scripts\verify-pipeline.ps1" `
  /SC HOURLY

# View scheduled tasks
schtasks /Query /TN "NightlyDashboardExportCheck" /V /FO LIST
schtasks /Query /TN "GateVerification" /V /FO LIST
```

---

## Typical Operations

### Morning Check
```powershell
# 1) Console encoding
chcp 65001 | Out-Null; [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

# 2) End-to-end verification
pwsh -File scripts\verify-pipeline.ps1

# 3) View results
cat out\gate_verification.json

# 4) Check SigNoz UI
Start-Process http://localhost:8080
```

### Responding to Failure
```powershell
# If verify-pipeline.ps1 exits with code 2 (FAIL):

# 1) Flip gate to HOLD
pwsh -File scripts\set-gate-status.ps1 -Status HOLD -Reason "Verification failed"

# 2) Check IONA error ledger
cat docs\IONA_ERRORS.md

# 3) Check service status
Get-Service otelcol-contrib | Select-Object Name, Status, StartType
docker ps --filter "name=signoz"

# 4) Check OTLP endpoints
Test-NetConnection localhost -Port 4318
Test-NetConnection localhost -Port 4317

# 5) Review collector logs
docker logs --tail 50 signoz-otel-collector

# 6) After fix, re-verify
pwsh -File scripts\verify-pipeline.ps1

# 7) If pass, restore gate
pwsh -File scripts\set-gate-status.ps1 -Status APPROVED -Reason "Issue resolved"
```

### Weekly Review
```powershell
# 1) Check compliance trends
cat artifacts\ecrr-compliance-trends.json | ConvertFrom-Json | Format-List

# 2) Review ECRR reports
Get-ChildItem docs\ecrr\ECRR_REPORTS -Filter "*2025-10-*" | Sort-Object LastWriteTime -Descending

# 3) Check recent verification summaries
Get-ChildItem out -Filter "gate_verification*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 7

# 4) Review dashboard exports
Get-ChildItem docs\observability\snapshots -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 7
```

---

## Rollback Criteria (Auto-HOLD)

Gate automatically downgrades to HOLD if **any** condition persists >5 minutes:

| Trigger | Severity | Detection |
|---------|----------|-----------|
| 🔴 Collector service stopped | Critical | `verify-pipeline.ps1` |
| 🔴 OTLP ports unreachable (4317/4318) | Critical | `verify-pipeline.ps1` |
| 🟡 Span rate = 0 (synthetic service) | High | `verify-pipeline.ps1` |
| 🟡 Continuous export drops | High | Collector log scan |
| 🟠 Error ratio > 5% | Medium | Metrics (manual) |

---

## SLO Targets

```yaml
Availability:  99.5% monthly uptime
Latency (p95): < 5 seconds (canary → visible)
Quality:       Zero dropped spans
Error Budget:  < 5% error ratio (5min window)
```

Track in SigNoz dashboards or via verification JSON summaries.

---

## File Locations

### Scripts
```
scripts/
├── verify-pipeline.ps1          ← Main verification (one command)
├── quick-monitor.ps1             ← Fast health check
├── send-canary-trace.ps1         ← Canary with assertion
├── check-nightly-export.ps1      ← Export validation
└── set-gate-status.ps1           ← Gate status updater
```

### Documentation
```
docs/ecrr/
├── GATE_STATUS.md                        ← Current status + badges
├── gate_decision.json                    ← Machine-readable decision
├── ECRR_REPORTS/
│   ├── GATE-APPROVAL-2025-10-08.md      ← One-pager certificate
│   ├── ECRR-2025-10-08-234500.md        ← Full ECRR report
│   └── QA-HARDENING-IMPLEMENTATION...md ← Hardening details
```

### Outputs
```
out/
└── gate_verification.json        ← Latest verification summary
```

---

## Troubleshooting

### Canary Script Not Found
```powershell
# Check if synthetic script exists
Test-Path C:\otel\synthetic\send_synthetic_otel_simple.py

# If not, verify-pipeline.ps1 will skip with exit code 1 (WARN)
# Create the script or adjust path in verify-pipeline.ps1 parameters
```

### Docker Not Available
```powershell
# Check Docker Desktop is running
docker ps

# Start Docker Desktop if needed
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"

# Wait for Docker to start (30-60 seconds)
```

### Service Won't Start
```powershell
# Check service status
Get-Service otelcol-contrib

# Check startup type
Get-Service otelcol-contrib | Select-Object StartType

# Enable and start
Set-Service otelcol-contrib -StartupType Automatic
Start-Service otelcol-contrib

# Check logs
Get-EventLog -LogName Application -Source "otelcol-contrib" -Newest 10
```

### SigNoz Not Responding
```powershell
# Check containers
docker ps --filter "name=signoz"

# Restart SigNoz stack (if using docker-compose)
docker-compose -f signoz/docker-compose.yml restart

# Check logs
docker logs signoz --tail 50
```

---

## Quick Reference URLs

- **SigNoz UI:** http://localhost:8080
- **SigNoz API Health:** http://localhost:8080/api/v1/health
- **SigNoz Version:** http://localhost:8080/api/v1/version
- **Local OTLP HTTP:** http://localhost:4318
- **Local OTLP gRPC:** http://localhost:4317
- **Windows Collector HTTP:** http://localhost:5318

---

## CI/CD Integration

### Exit Code Handling
```powershell
# In CI/CD pipeline
pwsh -File scripts\verify-pipeline.ps1
$exitCode = $LASTEXITCODE

if ($exitCode -eq 0) {
  Write-Host "✅ Gate verification passed - proceed with deployment"
  exit 0
} elseif ($exitCode -eq 1) {
  Write-Host "⚠️  Gate verification has warnings - manual review required"
  exit 1
} else {
  Write-Host "❌ Gate verification failed - block deployment"
  exit 2
}
```

### JSON Parsing
```powershell
# Read verification result
$result = Get-Content out\gate_verification.json | ConvertFrom-Json

Write-Host "Outcome: $($result.outcome)"
Write-Host "Timestamp: $($result.timestamp_utc)"
Write-Host "Service: $($result.service_name)"
Write-Host "Gate Checks:"
$result.gate_checks | Format-Table
```

---

## Contact & Escalation

**For Issues:**
1. Check `docs/IONA_ERRORS.md` for known issues
2. Run `verify-pipeline.ps1` for current state
3. Review recent ECRR reports in `docs/ecrr/ECRR_REPORTS/`
4. Check gate decision: `docs/ecrr/gate_decision.json`

**For Incidents:**
1. Flip gate to HOLD: `pwsh -File scripts\set-gate-status.ps1 -Status HOLD`
2. Document in IONA ledger: `docs/IONA_ERRORS.md`
3. Create ECRR report after resolution
4. Restore gate after verification

---

🐾 **BossCat OEM** | Executive Overseer Manager  
**Status:** Production Ready  
**Updated:** 2025-10-08 23:50:00 UTC

