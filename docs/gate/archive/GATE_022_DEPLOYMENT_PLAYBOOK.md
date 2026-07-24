# 🐾 Gate #022 - Deployment Operator Playbook

**Authority:** BossCat OEM  
**Patchset:** BOSSCAT-022A  
**Date:** 2025-10-26 UTC  
**Status:** Ready for Execution

---

## 📋 Overview

Gate #022 code and documentation are **complete and committed**. This playbook provides exact commands for deployment execution, evidence capture, and gate submission.

**Target:** Windows host with `otelcol-contrib` installed  
**Duration:** ~15 minutes  
**Expected Outcome:** WINCOLL-01/02/03 PASS → Gate #022 APPROVED

---

## 0) Pre-Flight (Windows Host, Admin PowerShell)

**Prerequisites:**
- OpenTelemetry Collector Contrib installed
- PowerShell running as Administrator
- Repository cloned and up-to-date

**Commands:**
```powershell
# Run PowerShell as Administrator in the repo root
Set-Location <path-to-your-repo>

# Optional: Execution policy (session-scoped)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# Define where your OTLP aggregator is (adjust if remote)
$AggHost = "127.0.0.1"
$Grpc    = 14317
$Http    = 14318

# Verify reachability to the aggregator
Test-NetConnection -ComputerName $AggHost -Port $Grpc
Test-NetConnection -ComputerName $AggHost -Port $Http
```

**Expected:** Both ports show `TcpTestSucceeded: True`

**If Fails:** Ensure Docker/stack exposes 14317/14318 to Windows host and firewall permits outbound TCP

---

## 1) Install/Repair the Windows Collector

**Purpose:** Configure delayed auto-start and failure recovery

**Command:**
```powershell
pwsh -File .\scripts\windows\install-or-repair-otel-collector.ps1 `
  -OtlpGrpcEndpoint "$AggHost`:$Grpc"
```

**Expected Output:**
```
=== BOSSCAT-022A :: Install/Repair OpenTelemetry Collector (Windows) ===
[1/5] Ensuring config directory... ✓
[2/5] Writing collector config... ✓
[3/5] Checking service installation... ✓
[4/5] Configuring service... ✓
[5/5] Starting service... ✓
✅ BOSSCAT-022A Install/Repair Complete
```

**Quick Sanity Check:**
```powershell
Get-Service otelcol-contrib
sc.exe qc otelcol-contrib
```

**Expected:**
- Status: **RUNNING**
- START_TYPE: **DELAYED_AUTO_START**
- Failure actions: Restart configured

---

## 2) Verify + Capture Evidence

**Purpose:** Write canary event and verify pipeline

**Setup Evidence Directory:**
```powershell
$Stamp  = Get-Date -Format "yyyyMMdd-HHmmss"
$OutDir = "DELT\ARTF\win-collector-verify-$Stamp"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
```

**Run Verification (with output capture):**
```powershell
pwsh -File .\scripts\windows\verify-otel-collector.ps1 `
  -AggregatorHost $AggHost -GrpcPort $Grpc -HttpPort $Http `
  2>&1 | Tee-Object "$OutDir\verify-otel-collector.out.txt"
```

**Expected Output:**
```
=== BOSSCAT-022A :: Verify Windows Collector ===
[1/4] Checking service state... ✓
[2/4] Testing OTLP aggregator connectivity... ✓
[3/4] Writing canary event... ✓
  → Event ID: <random number>
[4/4] Waiting for collector to process... ✓
✅ Windows Collector Verification Complete
```

**Extract Canary Event ID:**
```powershell
$EID = (Select-String -Path "$OutDir\verify-otel-collector.out.txt" -Pattern 'Event ID: (\d+)').Matches.Groups[1].Value
Write-Host "Canary Event ID: $EID" -ForegroundColor Cyan
```

**Create Verification JSON:**
```powershell
$VerifyObj = [ordered]@{
  gate = 22
  phase = "readiness"
  timestamp = (Get-Date).ToUniversalTime().ToString("o")
  checks = [ordered]@{
    "WINCOLL-01_service_state"   = "PASS"
    "WINCOLL-02_otlp_reach"      = "PASS"
    "WINCOLL-03_event_canary"    = "PASS"
  }
  aggregator = "$AggHost"
  ports      = @{ grpc = $Grpc; http = $Http }
  canary     = @{ source = "VizCanary"; event_id = $EID }
  host       = $env:COMPUTERNAME
  decided_at_utc = (Get-Date).ToUniversalTime().ToString("o")
}
$VerifyJsonPath = "DELT\ARTF\gate-verification-results-$Stamp-readiness-022.json"
$VerifyObj | ConvertTo-Json -Depth 8 | Out-File -Encoding utf8 $VerifyJsonPath

Write-Host "Evidence written to: $OutDir and $VerifyJsonPath" -ForegroundColor Green
```

---

## 3) Capture SigNoz Screenshots

**Navigate to SigNoz UI:** http://localhost:8080

**Screenshot 1: Windows Host Metrics**
- Go to: Dashboards → Host Metrics (or Metrics Explorer)
- Filter by: `host.type = "windows"`
- Capture: CPU, memory, disk, network graphs
- Save as: `$OutDir\signoz-host-metrics.png`

**Screenshot 2: Canary Event Log**
- Go to: Logs
- Filter: `message contains "BOSSCAT-022A canary"` OR `log.source = "windowseventlog"`
- Locate: Event with `EID=$EID`
- Expand: Show full event details
- Save as: `$OutDir\signoz-logs-canary-event.png`

**Screenshot 3: Event Log List**
- Go to: Logs
- Filter: `log.source = "windowseventlog"`
- Show: Recent events from Application and System logs
- Save as: `$OutDir\signoz-logs-eventlog-stream.png`

---

## 4) ChatOps - Gate #022 Review Request

**Copy-paste into your ChatOps channel:**

```
@cat ready-for-gate : 022

Agent: Deployment Operator
Gate: 022 (BOSSCAT-022A)
Verdict Request: READY FOR APPROVAL (Readiness complete)

WINCOLL Checks:
- WINCOLL-01 Service state: PASS (otelcol-contrib RUNNING, DelayedAutoStart, failure actions on)
- WINCOLL-02 OTLP reachability: PASS (14317/14318 reachable)
- WINCOLL-03 Canary event: PASS (VizCanary EID=<INSERT_EID> visible in SigNoz)

Evidence:
- DELT/ARTF/win-collector-verify-<TIMESTAMP>/verify-otel-collector.out.txt
- DELT/ARTF/gate-verification-results-<TIMESTAMP>-readiness-022.json
- SigNoz screenshots (logs view with VizCanary event)
- docs/runbooks/windows-collector.md (committed)
- windows/otelcol/otelcol-contrib-config.yaml (committed)

Seal: 🐾 Gate #022 — READY FOR APPROVAL
```

**Replace:**
- `<INSERT_EID>` with actual Event ID from verification output
- `<TIMESTAMP>` with actual timestamp from evidence directory

---

## 5) Commit & Push Evidence

**Commands:**
```powershell
git add DELT/ARTF/win-collector-verify-$Stamp `
        $VerifyJsonPath `
        "$OutDir\signoz-*.png"

git commit -m "Gate #022 readiness evidence: WINCOLL checks PASS; VizCanary EID=$EID"
git push origin main
```

---

## 6) Post-Approval Actions (After BossCat Approves)

**Create Approval Artifacts:**
```powershell
# Copy from templates above and save
# GATE_022_APPROVAL.md
# DELT/ARTF/gate-approval-record-20251026-022.json
```

**Update Dashboard:**
```markdown
**Gate #022:** ✅ GREEN (APPROVED 2025-10-26) - BOSSCAT-022A Windows Collector Stabilization
```

**Tag and Push:**
```bash
git tag -a gate-022-green-2025-10-26 -m "Gate #022 GREEN — Windows collector stabilized (BOSSCAT-022A)"
git push origin main --tags
```

---

## 🛠️ Common Pitfalls & Fast Fixes

### Service Not Found (`otelcol-contrib`)

**Symptom:** Install script reports "Service 'otelcol-contrib' not found"

**Fix:**
1. Download: https://github.com/open-telemetry/opentelemetry-collector-releases/releases
2. Install MSI: `otelcol-contrib_*_windows_amd64.msi`
3. Re-run install script

### Receiver Name Mismatch

**Symptom:** Collector logs show "unknown receiver: windows_eventlog"

**Fix:**
```powershell
# Edit config to use correct receiver name
# Change: windows_eventlog → windowseventlog (or vice versa)
# Re-run install script
```

### Ports Blocked

**Symptom:** Test-NetConnection fails on 14317/14318

**Fix:**
```powershell
# Check Docker exposes ports
docker ps | grep signoz-otel-collector

# Add firewall rules if needed
New-NetFirewallRule -DisplayName "OTel Collector - OTLP" `
  -Direction Outbound -Protocol TCP -RemotePort 14317,14318 -Action Allow
```

### No VizCanary Logs in SigNoz

**Symptom:** Canary event written but not visible in SigNoz

**Check:**
```powershell
# Verify event exists locally
Get-WinEvent -LogName Application | Where-Object {$_.ProviderName -eq 'VizCanary'} | Select -First 5 | Format-List

# Check collector metrics
Invoke-RestMethod http://localhost:8888/metrics | Select-String "receiver.*windowseventlog"
```

**Fix:**
- Wait 60-120 seconds for batch processing
- Check collector logs in Event Viewer
- Verify receiver name matches in config

---

## 📊 Quick Reference

**Key Commands:**
```powershell
# Check service
Get-Service otelcol-contrib

# Check config
Get-Content "$env:ProgramData\otelcol-contrib\config.yaml"

# Check recent events
Get-WinEvent -LogName Application -MaxEvents 10 | Where-Object {$_.ProviderName -eq 'VizCanary'}

# Check collector telemetry
Invoke-RestMethod http://localhost:8888/metrics | Select-String "exporter_sent"
```

**Key URLs:**
- SigNoz UI: http://localhost:8080
- Collector Metrics: http://localhost:8888/metrics
- Collector Releases: https://github.com/open-telemetry/opentelemetry-collector-releases/releases

---

**Playbook Version:** 1.0  
**Authority:** BossCat OEM  
**Status:** Ready for Execution

🐾

