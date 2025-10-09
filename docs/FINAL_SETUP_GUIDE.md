# 🐾 BossCat OEM - Final Setup Guide

**Status:** ✅ All features implemented - Ready for forensic-grade GREEN run  
**Time Required:** ~5 minutes

---

## ⚡ Quick Path to Forensic-Grade GREEN

### Step 1: Create SigNoz API Key
```powershell
# Open SigNoz API Keys page
Start-Process http://localhost:8080/settings/api-keys

# → Click "Create New Key"
# → Name: "gate-verification"
# → Copy the generated key
```

### Step 2: Set API Key (Machine Scope - Recommended)
```powershell
# Replace <paste-key-here> with your actual key
[Environment]::SetEnvironmentVariable("SIGNOZ_API_KEY","<paste-key-here>","Machine")

# Verify it's set
[Environment]::GetEnvironmentVariable("SIGNOZ_API_KEY","Machine")
```

### Step 3: Open NEW PowerShell Window
```powershell
# Close current window and open new one to load Machine environment variables
exit

# In new window, verify the key is loaded
$env:SIGNOZ_API_KEY  # Should display your key
```

### Step 4: Run Verification
```powershell
# Option A: Verify and manually flip gate
pwsh -File scripts\verify-pipeline.ps1

# Then check outcome and flip gate
if ((Get-Content out\gate_verification.json | ConvertFrom-Json).outcome -eq "OK") {
  pwsh -File scripts\set-gate-status.ps1 -Status APPROVED -Reason "Forensic-grade verification complete"
}

# Option B: Verify and auto-flip gate (ONE COMMAND)
pwsh -File scripts\verify-and-flip.ps1
```

---

## 🎯 Expected Forensic-Grade JSON

### Success Output
```json
{
  "timestamp_utc": "2025-10-08T23:55:00Z",
  "service_name": "synthetic-windows-check",
  "gate_id": "GATE-2025-10-08-234500",
  "steps": {
    "quick_monitor": "pass",
    "canary_send": {
      "exit_code": 0,
      "trace_id": "a1b2c3d4e5f67890123456789abcdef0",
      "canary_id": "1733728800123",
      "send_ts_ns": 1733728800123456789,
      "log_confirmed": true,
      "api_confirmed": true,
      "api_reason": "span_found",
      "api_mode": "PINPOINT (traceID)",
      "ingest_latency_ms": 1240,
      "status": "pass"
    }
  },
  "gate_checks": {
    "collector_service_running": true,
    "otlp_reachable": true,
    "span_rate_nonzero": true,
    "export_drops_zero": true,
    "error_ratio_under_5pct": true
  },
  "outcome": "OK",
  "exit_code": 0
}
```

### Key Forensic Fields ✅
- ✅ `trace_id`: Exact trace identifier (32-char hex)
- ✅ `canary_id`: Unique canary run identifier
- ✅ `log_confirmed`: true (collector logs verified)
- ✅ `api_confirmed`: true (SigNoz API verified)
- ✅ `api_reason`: "span_found" (explicit confirmation)
- ✅ `api_mode`: "PINPOINT (traceID)" (forensic verification)
- ✅ `ingest_latency_ms`: Measured latency (sub-second to few seconds)
- ✅ `outcome`: "OK" (all checks passed)
- ✅ `exit_code`: 0 (success)

---

## ✅ Sanity Checks

### 1. Trace Pinning
```powershell
# Verify trace ID is captured
$json = Get-Content out\gate_verification.json | ConvertFrom-Json
$json.steps.canary_send.trace_id
# Should show: a1b2c3d4e5f67890... (32-char hex)
```

### 2. Dual Confirmation
```powershell
# Both log and API should confirm
$json.steps.canary_send.log_confirmed  # Should be true
$json.steps.canary_send.api_confirmed  # Should be true
```

### 3. Latency Measured
```powershell
# Ingest latency should be recorded
$json.steps.canary_send.ingest_latency_ms
# Should show: 1240 (example, typically 500-3000ms)
```

### 4. Graceful Degradation
```powershell
# If key missing or transient failure
# → WARN with clear reason (as already observed)
$json.steps.canary_send.api_reason
# Shows: "missing_api_key" or "span_found"
```

---

## 🧰 One-Command Wrapper Usage

### Non-Strict Mode (Default)
```powershell
# WARN keeps APPROVED but annotated
pwsh -File scripts\verify-and-flip.ps1

# Expected output:
[verify-and-flip] Verification completed with exit code: 0
[verify-and-flip] Outcome: OK (exit code: 0)
[verify-and-flip] ✅ Verification passed - setting gate to APPROVED
[verify-and-flip] ✅ Gate status updated

📊 Summary:
   Verification Outcome: OK
   Gate Status: APPROVED
   Reason: Forensic-grade verification passed
   Exit Code: 0

🔬 Forensic Details:
   Trace ID: a1b2c3d4e5f67890...
   Canary ID: 1733728800123
   API Mode: PINPOINT (traceID)
   Ingest Latency: 1240 ms
```

### Strict Mode (Production)
```powershell
# WARN forces HOLD
pwsh -File scripts\verify-and-flip.ps1 -Strict

# WARN outcome will set gate to HOLD
```

---

## 🛡️ Guardrails & Best Practices

### 1. Clock Synchronization
```powershell
# Check Windows Time Service status
w32tm /query /status

# If time sync issues (negative latency):
# → System will detect and warn
# → Latency will be set to null
# → Fix: Enable NTP or domain time sync
```

### 2. Lookback Window Adjustment
```powershell
# If spans batch for longer (high load), increase lookback
$env:BOSSCAT_LOOKBACK_SEC = "240"  # 4 minutes instead of 3
pwsh -File scripts\verify-pipeline.ps1
```

### 3. Strict Policy in Production
```powershell
# Convert any WARN to HOLD (zero tolerance)
$env:BOSSCAT_STRICT = "1"
pwsh -File scripts\verify-pipeline.ps1
# OR
pwsh -File scripts\verify-and-flip.ps1 -Strict
```

### 4. Air-Gapped Mode
```powershell
# Skip API checks (no SigNoz connectivity)
$env:BOSSCAT_SKIP_API = "1"
pwsh -File scripts\verify-pipeline.ps1
```

---

## 📊 What Success Looks Like

### Console Output
```
🐾 BossCat OEM - Pipeline Verification
═══════════════════════════════════════════════════════════

[verify] Step 1/3: quick-monitor
✅ Quick check complete

[verify] Step 2/3: canary trace (capturing TRACE_ID for pinpoint verification)
[verify] Running canary script: C:\otel\synthetic\send_synthetic_otel_simple.py
[verify] ✓ Captured TRACE_ID: a1b2c3d4e5f67890123456789abcdef0
[verify] ✓ Canary sent successfully (TRACE_ID: a1b2..., CANARY_ID: 1733728800123)
[verify] Waiting up to 60 s for ingestion...
[verify] ✓ Canary confirmed in collector logs

[verify] API check (SigNoz Trace API - forensic verification)...
[api-check] Mode: PINPOINT (traceID) (last 180 s)...
[api-check] PINPOINT ✓ Span confirmed via SigNoz API
[verify] 📊 Ingest latency: 1240 ms

[verify] Step 3/3: apply gate rules

[verify] Summary written: out\gate_verification.json
🧾 [verify] Trend updated: out\gate_verification_trend.csv

═══════════════════════════════════════════════════════════
✅ VERIFICATION OK — pipeline healthy
   All checks passed
═══════════════════════════════════════════════════════════

📦 [evidence] Creating evidence pack...
✅ Evidence pack created: out\evidence-20251008-235500Z.zip
   Size: 245.67 KB

🐾 BossCat OEM - Verification Complete
```

### Files Generated
```
out/
├── gate_verification.json          ← Forensic-grade results
├── gate_verification_trend.csv     ← SLO tracking
└── evidence-20251008-235500Z.zip   ← Audit package

docs/ecrr/
└── GATE_STATUS.md                  ← Updated with APPROVED
```

---

## 🎯 Next Steps After First Green Run

### 1. Review Results
```powershell
# View full JSON
cat out\gate_verification.json | ConvertFrom-Json | ConvertTo-Json -Depth 10

# View specific forensic fields
$json = Get-Content out\gate_verification.json | ConvertFrom-Json
Write-Host "Trace ID: $($json.steps.canary_send.trace_id)"
Write-Host "API Mode: $($json.steps.canary_send.api_mode)"
Write-Host "Latency: $($json.steps.canary_send.ingest_latency_ms) ms"
Write-Host "Outcome: $($json.outcome)"
```

### 2. Verify in SigNoz UI
```powershell
# Open SigNoz and search for your trace ID
Start-Process "http://localhost:8080/traces?service=synthetic-windows-check"

# In SigNoz UI:
# → Click on latest trace
# → Should match the trace_id from JSON
# → Verify span attributes (canary.id, boss.cat, etc.)
```

### 3. Check Evidence Pack
```powershell
# Extract latest evidence pack
$latest = dir out\evidence-*.zip | sort LastWriteTime -desc | select -first 1
Expand-Archive -Path $latest.FullName -DestinationPath "out\latest-evidence"

# Review contents
dir out\latest-evidence
```

### 4. Analyze Trend
```powershell
# View last 10 runs
Import-Csv out\gate_verification_trend.csv | Select-Object -Last 10 | Format-Table

# Calculate p95 latency
$csv = Import-Csv out\gate_verification_trend.csv
$latencies = $csv | Where-Object { $_.ingest_latency_ms -ne "" } | 
    Select-Object -ExpandProperty ingest_latency_ms | Sort-Object
$p95 = $latencies[[math]::Floor($latencies.Count * 0.95)]
Write-Host "P95 Ingest Latency: $p95 ms (Target: < 5000ms)"
```

---

## 🔄 CI/CD Integration

### GitHub Actions (Already Configured)
```yaml
# Workflow: .github/workflows/gate-nightly.yml
# Runs nightly at 02:03 UTC
# Uses SIGNOZ_API_KEY from repository secrets
# Creates issues on WARN/FAIL (exit code != 0)
```

### Local Scheduled Task
```powershell
# Schedule hourly verification
schtasks /Create /TN "BossCatVerification" `
  /TR "pwsh -File C:\otel\scripts\verify-and-flip.ps1" `
  /SC HOURLY `
  /RU SYSTEM

# Schedule strict mode (production)
schtasks /Create /TN "BossCatVerificationStrict" `
  /TR "pwsh -File C:\otel\scripts\verify-and-flip.ps1 -Strict" `
  /SC HOURLY `
  /RU SYSTEM
```

---

## 🎉 Success Criteria

✅ **Forensic-Grade Achieved When:**
- Trace ID captured (32-char hex)
- API mode shows "PINPOINT (traceID)"
- Both log_confirmed and api_confirmed are true
- Ingest latency measured (typically 500-3000ms)
- Outcome is "OK" with exit code 0
- Evidence pack generated automatically
- Gate status updated to APPROVED

---

🐾 **BossCat OEM** | Forensic-Grade Setup Complete  
**Status:** Ready for GREEN run  
**Time:** 5 minutes  
**Result:** Mathematically provable verification 🔬

**Run the commands above to see forensic-grade in action!** 🔥✨

