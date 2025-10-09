# 🐾 BossCat OEM - Incident Playbook

**Quick reference for incident response and recovery**

---

## 📋 Severity Definitions

### SEV-1: Critical (Pipeline Down)
- **Condition:** No spans flowing for ≥5 minutes
- **OR:** Collector service not running
- **Impact:** Complete observability loss
- **Response Time:** Immediate (0-5 minutes)

### SEV-2: High (Degraded)
- **Condition:** API not confirming spans but logs confirm
- **OR:** Continuous export drops
- **Impact:** Reduced confidence in data
- **Response Time:** Urgent (5-30 minutes)

### SEV-3: Medium (Performance)
- **Condition:** p95 ingest latency > 5000ms for ≥15 minutes
- **OR:** Success rate < 99% over 24 hours
- **Impact:** SLO breach, potential data delays
- **Response Time:** High (30-60 minutes)

---

## 🚨 Immediate Actions (All Severities)

### Step 1: Run Verification
```powershell
# Capture current state
pwsh -File scripts\verify-pipeline.ps1

# Check outcome
$j = Get-Content out\gate_verification.json | ConvertFrom-Json
$j.outcome  # OK, WARN, or FAIL
```

### Step 2: Update Gate Status
```powershell
# If FAIL, set gate to HOLD
if ((Get-Content out\gate_verification.json | ConvertFrom-Json).outcome -eq "FAIL") {
  pwsh -File scripts\set-gate-status.ps1 -Status HOLD -Reason "Incident #<ticket-number> - verification FAIL"
}
```

### Step 3: Generate Evidence Pack
```powershell
# Create audit package
pwsh -File scripts\write-evidence-pack.ps1

# Latest evidence
$evidence = dir out\evidence-*.zip | sort LastWriteTime -desc | select -first 1
Write-Host "Evidence pack: $($evidence.FullName)"
```

### Step 4: Quick Diagnostics
```powershell
# Check Windows collector service
Get-Service otelcol-contrib | Format-List Name, Status, StartType

# Check OTLP endpoint
Test-NetConnection 127.0.0.1 -Port 4318

# Check Docker containers
docker ps --filter "name=signoz"

# Check collector logs for errors
docker logs --since 5m signoz-otel-collector | Select-String -Pattern "error|fail|drop|retry"
```

---

## 🔧 Recovery Procedures

### SEV-1: Collector Service Stopped

#### Diagnosis
```powershell
Get-Service otelcol-contrib
# Status: Stopped
```

#### Recovery
```powershell
# Attempt restart
Restart-Service otelcol-contrib

# Wait for startup
Start-Sleep -Seconds 5

# Verify
Get-Service otelcol-contrib
# Status should be: Running

# Re-verify pipeline
pwsh -File scripts\verify-pipeline.ps1
```

#### If Restart Fails
```powershell
# Check Event Log for errors
Get-EventLog -LogName Application -Source "otelcol-contrib" -Newest 10

# Check service configuration
sc.exe query otelcol-contrib
sc.exe qc otelcol-contrib

# Manual start with verbose logging
Start-Service otelcol-contrib -Verbose
```

### SEV-1: OTLP Endpoint Unreachable

#### Diagnosis
```powershell
Test-NetConnection 127.0.0.1 -Port 4318
# TcpTestSucceeded: False
```

#### Recovery
```powershell
# Check if port is in use
Get-NetTCPConnection -LocalPort 4318 -ErrorAction SilentlyContinue

# Check Docker container
docker ps --filter "name=signoz-otel-collector"
docker logs signoz-otel-collector --tail 50

# Restart collector container
docker restart signoz-otel-collector

# Wait for startup
Start-Sleep -Seconds 10

# Re-verify
Test-NetConnection 127.0.0.1 -Port 4318
```

### SEV-2: API Not Confirming Spans

#### Diagnosis
```powershell
$j = Get-Content out\gate_verification.json | ConvertFrom-Json
$j.steps.canary_send.log_confirmed  # True
$j.steps.canary_send.api_confirmed  # False
$j.steps.canary_send.api_reason     # "no_span_found"
```

#### Recovery
```powershell
# Increase lookback window
$env:BOSSCAT_LOOKBACK_SEC = "300"  # 5 minutes

# Rerun verification
pwsh -File scripts\verify-pipeline.ps1

# Check SigNoz API health
Invoke-RestMethod -Uri "http://localhost:8080/api/v1/health"

# Verify in SigNoz UI manually
Start-Process "http://localhost:8080/traces?service=synthetic-windows-check"
```

### SEV-3: High Ingest Latency

#### Diagnosis
```powershell
# Check recent p95
pwsh -File scripts\calc-p95-latency.ps1

# View trend
Get-Content out\gate_verification_trend.csv -Tail 20 | 
  ConvertFrom-Csv | 
  Select-Object timestamp_utc, ingest_latency_ms, outcome
```

#### Recovery
```powershell
# Check collector resource usage
docker stats signoz-otel-collector --no-stream

# Check collector logs for backpressure
docker logs --since 10m signoz-otel-collector | 
  Select-String -Pattern "queue|backpressure|retry"

# Check ClickHouse health
docker ps --filter "name=clickhouse"
docker logs --tail 50 signoz-clickhouse

# If persistent, consider scaling collector
```

---

## 📊 Verification Commands by Symptom

### "Canary crashed"
```powershell
# Check Python environment
Get-Command python
# Should point to: C:\otel\.venv\Scripts\python.exe

# Activate venv
C:\otel\.venv\Scripts\Activate.ps1

# Test canary directly
python synthetic\send_canary_with_traceid.py

# Reinstall deps if needed
python -m pip install --force-reinstall opentelemetry-sdk opentelemetry-exporter-otlp-proto-http
```

### "API key missing"
```powershell
# Check environment variable
$env:SIGNOZ_API_KEY
[Environment]::GetEnvironmentVariable("SIGNOZ_API_KEY","Machine")

# If null, create and set
Start-Process http://localhost:8080/settings/api-keys
[Environment]::SetEnvironmentVariable("SIGNOZ_API_KEY","<key>","Machine")

# Restart PowerShell
exit  # Open new window
```

### "No spans confirmed"
```powershell
# Check collector service
Get-Service otelcol-contrib

# Check OTLP endpoints
Test-NetConnection 127.0.0.1 -Port 4318
Test-NetConnection 127.0.0.1 -Port 5318

# Check collector logs
docker logs --since 5m signoz-otel-collector | Select-String -Pattern "span|trace|export"

# Test canary manually
C:\otel\.venv\Scripts\Activate.ps1
python synthetic\send_canary_with_traceid.py
```

---

## 🔄 Recovery Verification

### After Any Fix
```powershell
# Run full verification
pwsh -File scripts\verify-and-flip.ps1

# OR strict mode
pwsh -File scripts\verify-and-flip.ps1 -Strict

# Check outcome
$j = Get-Content out\gate_verification.json | ConvertFrom-Json
if ($j.outcome -eq "OK") {
  Write-Host "✅ Recovery verified - pipeline healthy" -ForegroundColor Green
} else {
  Write-Host "❌ Still failing - continue investigation" -ForegroundColor Red
}
```

### Evidence Collection
```powershell
# Generate fresh evidence pack
pwsh -File scripts\write-evidence-pack.ps1

# Latest pack
$latest = dir out\evidence-*.zip | sort LastWriteTime -desc | select -first 1

# Extract for analysis
Expand-Archive -Path $latest.FullName -DestinationPath "out\incident-analysis"

# Review
cat out\incident-analysis\README.txt
cat out\incident-analysis\collector_logs_10m.txt | Select-String -Pattern "error|drop"
```

---

## 📝 Post-Incident Actions

### 1. Update IONA Ledger
```powershell
# Document incident in docs/IONA_ERRORS.md
# Include:
# - Timestamp
# - Root cause
# - Resolution
# - Evidence location
```

### 2. Generate ECRR Report
```powershell
# Create post-incident ECRR in docs/ecrr/ECRR_REPORTS/
# Include:
# - Examine: Pre-incident state
# - Clean: Actions taken
# - Report: Evidence artifacts
# - Role: Accountability
```

### 3. Review Trend Data
```powershell
# 5-day lookback
$csv = Import-Csv out\gate_verification_trend.csv
$fiveDaysAgo = (Get-Date).AddDays(-5)
$recent = $csv | Where-Object { 
  [DateTime]::Parse($_.timestamp_utc) -gt $fiveDaysAgo 
}

# Analyze patterns
$recent | Group-Object outcome | Select-Object Count, Name
$recent | Where-Object outcome -ne "OK" | Format-Table timestamp_utc, outcome, api_reason
```

### 4. Update Gate Status
```powershell
# After recovery verification passes
pwsh -File scripts\set-gate-status.ps1 -Status APPROVED -Reason "Recovery verified - incident resolved"
```

---

## 🚨 Escalation Criteria

### Page On-Call If:
- Collector service won't start after 3 restart attempts
- OTLP endpoints unreachable for >10 minutes
- No span confirmation for >15 minutes
- p95 latency >10000ms (2x SLO) for >30 minutes
- Continuous FAIL outcomes for >5 verifications

### Escalation Contacts
- **On-Call:** Check team rotation
- **BossCat OEM:** Executive escalation
- **SigNoz Team:** For backend issues

---

## 📦 Incident Template

```markdown
## Incident #XXXX - Gate Verification Failure

**Date:** YYYY-MM-DD HH:MM UTC
**Severity:** SEV-X
**Duration:** X minutes
**Status:** RESOLVED / INVESTIGATING

### Timeline
- HH:MM - Incident detected (verification FAIL)
- HH:MM - Evidence pack generated
- HH:MM - Root cause identified: <description>
- HH:MM - Fix applied: <action>
- HH:MM - Recovery verified
- HH:MM - Gate restored to APPROVED

### Root Cause
<Description>

### Resolution
<Actions taken>

### Evidence
- Evidence pack: out/evidence-YYYYMMDD-HHMMSSZ.zip
- Verification JSON: out/gate_verification.json
- IONA ledger: docs/IONA_ERRORS.md
- ECRR report: docs/ecrr/ECRR_REPORTS/ECRR-YYYY-MM-DD.md

### Prevention
<Future improvements>

### BossCat Sign-Off
🐾 _____________________
Date: _____________________
```

---

🐾 **BossCat OEM** | Incident Playbook  
**Status:** Reference guide for all incident scenarios  
**Use:** Keep accessible during on-call rotations

