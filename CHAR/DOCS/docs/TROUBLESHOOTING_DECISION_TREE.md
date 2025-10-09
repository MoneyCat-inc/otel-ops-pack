# 🐾 BossCat OEM - Troubleshooting Decision Tree

**Quick diagnostic guide for WARN/FAIL outcomes**

---

## 🧭 Quick Decision Tree

```
Verification returned WARN or FAIL?
│
├─ A. Canary exit code non-zero (crashed)?
│   ├─ Check: Get-Command python → points to .venv?
│   │   └─ No: Activate venv → C:\otel\.venv\Scripts\Activate.ps1
│   │   └─ Yes: Continue →
│   │
│   ├─ Reinstall deps:
│   │   python -m pip install --force-reinstall opentelemetry-sdk opentelemetry-exporter-otlp-proto-http
│   │
│   └─ Test canary directly:
│       python synthetic\send_canary_with_traceid.py
│       Should print: TRACE_ID=..., CANARY_ID=..., SEND_TS_NS=...
│
├─ B. API check says "missing_api_key"?
│   ├─ Confirm env var:
│   │   $env:SIGNOZ_API_KEY  # Should show key
│   │   [Environment]::GetEnvironmentVariable("SIGNOZ_API_KEY","Machine")  # Should show key
│   │
│   ├─ If null: Set it
│   │   [Environment]::SetEnvironmentVariable("SIGNOZ_API_KEY","<key>","Machine")
│   │
│   └─ Restart PowerShell (new window to load Machine env)
│
├─ C. API check says "no_span_found" but logs confirm?
│   ├─ Increase lookback window:
│   │   $env:BOSSCAT_LOOKBACK_SEC = "240"  # 4 minutes
│   │
│   ├─ Check time sync:
│   │   w32tm /query /status
│   │   Large skew can cause latency confusion
│   │
│   └─ Verify in SigNoz UI:
│       Start-Process "http://localhost:8080/traces?service=synthetic-windows-check"
│       Check if trace exists manually
│
└─ D. Neither API nor logs confirm?
    ├─ Check OTLP endpoint:
    │   Test-NetConnection 127.0.0.1 -Port 4318
    │   Should return: TcpTestSucceeded = True
    │
    ├─ Check collector logs:
    │   docker logs --since 2m signoz-otel-collector | Select-String -Pattern "dropped|retry|error"
    │   Look for dropped spans or export errors
    │
    ├─ Check Windows collector service:
    │   Get-Service otelcol-contrib
    │   Should show: Status = Running
    │
    └─ Check SigNoz health:
        Invoke-RestMethod -Uri "http://localhost:8080/api/v1/health"
        Should return: status = "ok"
```

---

## 🔍 Detailed Diagnostics by Error

### A. Canary Script Crashed (Exit -1073741819)

**Error Code:** -1073741819 (0xC0000005 = Access Violation)

**Common Causes:**
1. Missing OpenTelemetry packages
2. gRPC native dependency issues (if using gRPC exporter)
3. Python environment issues

**Solutions:**

#### 1. Verify Virtual Environment
```powershell
# Check which Python is active
Get-Command python
# Should show: C:\otel\.venv\Scripts\python.exe

# If not, activate venv
C:\otel\.venv\Scripts\Activate.ps1

# Verify activation
Get-Command python  # Should now show venv path
```

#### 2. Reinstall Dependencies
```powershell
# Ensure venv is active first
C:\otel\.venv\Scripts\Activate.ps1

# Reinstall packages
python -m pip install --force-reinstall opentelemetry-sdk opentelemetry-exporter-otlp-proto-http

# Verify installation
python -c "from opentelemetry import trace; from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter; print('OK')"
# Should print: OK
```

#### 3. Test Canary Directly
```powershell
# Activate venv
C:\otel\.venv\Scripts\Activate.ps1

# Set environment
$env:OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:4318"
$env:SERVICE_NAME = "synthetic-windows-check"

# Run canary
python synthetic\send_canary_with_traceid.py

# Expected output:
# TRACE_ID=a1b2c3d4e5f67890123456789abcdef0
# CANARY_ID=1733728800123
# SEND_TS_NS=1733728800123456789
```

---

### B. API Check Says "missing_api_key"

**Symptom:** `api_reason: "missing_api_key"`

**Solutions:**

#### 1. Check Environment Variable
```powershell
# Check Process scope (current session)
$env:SIGNOZ_API_KEY

# Check Machine scope (permanent)
[Environment]::GetEnvironmentVariable("SIGNOZ_API_KEY","Machine")

# Check User scope
[Environment]::GetEnvironmentVariable("SIGNOZ_API_KEY","User")

# One should return your key
```

#### 2. Set API Key
```powershell
# Open SigNoz API Keys page
Start-Process http://localhost:8080/settings/api-keys

# Create new key:
# → Click "Create New Key"
# → Name: "gate-verification"
# → Copy the generated key

# Set Machine environment variable (permanent)
[Environment]::SetEnvironmentVariable("SIGNOZ_API_KEY","<paste-key-here>","Machine")

# Verify it's set
[Environment]::GetEnvironmentVariable("SIGNOZ_API_KEY","Machine")
```

#### 3. Restart PowerShell
```powershell
# IMPORTANT: Machine-scope env vars require new session
exit  # Close current window

# Open new PowerShell window
# Verify key is loaded
$env:SIGNOZ_API_KEY  # Should display your key
```

---

### C. API Check Says "no_span_found" But Logs Confirm

**Symptom:** `log_confirmed: true` but `api_confirmed: false`, `api_reason: "no_span_found"`

**Common Causes:**
1. Span not yet visible in SigNoz (ingestion delay)
2. Lookback window too short
3. Time sync issues (clock skew)

**Solutions:**

#### 1. Increase Lookback Window
```powershell
# Set longer lookback (default 180s → 240s)
$env:BOSSCAT_LOOKBACK_SEC = "240"

# Rerun verification
pwsh -File scripts\verify-pipeline.ps1
```

#### 2. Check Time Synchronization
```powershell
# Query Windows Time Service
w32tm /query /status

# Look for:
# Source: (should show NTP server or domain controller)
# Last Sync: (should be recent)
# Stratum: (should be 3-5 for domain, 4-10 for internet NTP)

# If time sync issues, resync
w32tm /resync
```

#### 3. Verify in SigNoz UI
```powershell
# Get trace ID from last run
$json = Get-Content out\gate_verification.json | ConvertFrom-Json
$traceId = $json.steps.canary_send.trace_id

Write-Host "Trace ID: $traceId"

# Open SigNoz traces
Start-Process "http://localhost:8080/traces"

# In UI: Search for trace ID or filter by service
# serviceName = synthetic-windows-check
# Last 5 minutes
```

---

### D. Neither API Nor Logs Confirm

**Symptom:** Both `log_confirmed: false` and `api_confirmed: false`

**Common Causes:**
1. OTLP endpoint not reachable
2. Collector not processing spans
3. Service stopped
4. Network/firewall issues

**Solutions:**

#### 1. Check OTLP Endpoint
```powershell
# Test HTTP endpoint (4318)
Test-NetConnection 127.0.0.1 -Port 4318
# Should return: TcpTestSucceeded = True

# Test gRPC endpoint (4317) if using gRPC
Test-NetConnection 127.0.0.1 -Port 4317

# If failed, check Docker
docker ps --filter "name=signoz"
# Should show signoz-otel-collector running
```

#### 2. Check Collector Logs
```powershell
# View recent logs
docker logs --since 5m signoz-otel-collector

# Look for errors
docker logs --since 5m signoz-otel-collector | Select-String -Pattern "error|fail|drop|retry"

# Common issues:
# - "connection refused" → Check endpoint configuration
# - "dropped" → Check collector capacity
# - "retry" → Check network connectivity
```

#### 3. Check Windows Collector Service
```powershell
# Check service status
Get-Service otelcol-contrib | Format-List

# Should show:
# Status: Running
# StartType: Automatic

# If stopped, start it
Start-Service otelcol-contrib

# If disabled, enable and start
Set-Service otelcol-contrib -StartupType Automatic
Start-Service otelcol-contrib
```

#### 4. Check SigNoz Health
```powershell
# Query health endpoint
Invoke-RestMethod -Uri "http://localhost:8080/api/v1/health"

# Should return:
# status: "ok"

# If failed, check Docker
docker ps --filter "name=signoz"
docker logs signoz --tail 50
```

---

## 🎯 Quick Validation Commands

### One-Glance Green Check
```powershell
# After verification, quick validation
$j = Get-Content out\gate_verification.json -Raw | ConvertFrom-Json
$j.outcome, $j.steps.canary_send.trace_id, $j.steps.canary_send.ingest_latency_ms

# Should print:
# OK
# a1b2c3d4e5f67890123456789abcdef0
# 1240
```

### Detailed Status
```powershell
# Full canary_send details
$j = Get-Content out\gate_verification.json | ConvertFrom-Json
$j.steps.canary_send | Format-List

# Should show:
# exit_code          : 0
# trace_id           : a1b2c3d4...
# canary_id          : 1733728800123
# log_confirmed      : True
# api_confirmed      : True
# api_reason         : span_found
# api_mode           : PINPOINT (traceID)
# ingest_latency_ms  : 1240
# status             : pass
```

---

## 🛡️ Good Hygiene Practices

### 1. Keep Secrets Out of Logs ✅
```powershell
# Your scripts already do this correctly
# Never echo SIGNOZ_API_KEY
# Use environment variables, not command-line flags
```

### 2. Pin Localhost Bypass
```powershell
# If behind corporate proxy
$env:NO_PROXY = "localhost,127.0.0.1"

# Make permanent
[Environment]::SetEnvironmentVariable("NO_PROXY","localhost,127.0.0.1","Machine")
```

### 3. Use Venv Consistently
```powershell
# Add to operator startup
# In: docs\OPERATOR_QUICKSTART.md

# Always activate venv before verification
C:\otel\.venv\Scripts\Activate.ps1
pwsh -File scripts\verify-pipeline.ps1
```

### 4. Regular API Key Rotation
```powershell
# Every 90 days (security best practice)
# 1. Create new key in SigNoz UI
# 2. Update environment variable
# 3. Restart PowerShell
# 4. Run verification to confirm
```

---

## 📊 Common Warning Messages (Non-Errors)

### Expected Warnings (Not Failures)

#### 1. "TRACE_ID not captured" (using old canary script)
```
[verify] Canary sent but TRACE_ID not captured from output.
[verify] ℹ️  Using standard serviceName-based verification
```
**Status:** OK - Falls back to STANDARD mode  
**Action:** Upgrade to forensic canary (already done)

#### 2. "Negative ingest latency detected"
```
[verify] Negative ingest latency detected (-500 ms) - clock skew between systems
[verify] ℹ️  Ensure NTP/domain time sync is enabled
```
**Status:** WARNING - Clock skew detected  
**Action:** Fix time sync with `w32tm /resync`

#### 3. "No API key" (first run)
```
[api-check] No API key in SIGNOZ_API_KEY environment variable
[api-check] ℹ️  Create API key in SigNoz: Settings → API Keys
```
**Status:** EXPECTED - Needs setup  
**Action:** Create and set API key

---

## 🎯 Success Criteria Checklist

✅ **Forensic-Grade GREEN When:**
- [ ] `outcome: "OK"`
- [ ] `exit_code: 0`
- [ ] `trace_id: "<32-char-hex>"`
- [ ] `canary_id: "<timestamp>"`
- [ ] `log_confirmed: true`
- [ ] `api_confirmed: true`
- [ ] `api_reason: "span_found"`
- [ ] `api_mode: "PINPOINT (traceID)"`
- [ ] `ingest_latency_ms: <positive-number>`

---

## 📞 Support Resources

### Documentation
- **Quick Start:** `QUICKSTART.md`
- **Setup Guide:** `docs/FINAL_SETUP_GUIDE.md`
- **Operator Guide:** `docs/OPERATOR_QUICKSTART.md`
- **This Guide:** `docs/TROUBLESHOOTING_DECISION_TREE.md`

### Quick Commands
```powershell
# Health check
pwsh -File scripts\quick-monitor.ps1

# Full verification
pwsh -File scripts\verify-pipeline.ps1

# View latest result
cat out\gate_verification.json | ConvertFrom-Json | Format-List

# Check gate status
cat docs\ecrr\GATE_STATUS.md
```

---

🐾 **BossCat OEM** | Troubleshooting Guide  
**Status:** Ready for any scenario  
**Next:** Fix any prerequisites → Rerun → GREEN

