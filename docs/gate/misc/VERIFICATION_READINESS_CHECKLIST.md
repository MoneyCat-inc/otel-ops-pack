# 🔍 Verification Readiness Checklist

**Purpose:** Ensure all components are running before verification  
**Script:** `BRAV/SCPT/verify-all-components.ps1`  
**Updated:** 2025-10-09 (post-tetragram migration)

---

## ✅ Pre-Verification Checklist

Run through this list **before** executing `verify-all-components.ps1`:

### 1. SigNoz Stack Running ✅

**Check:**
```powershell
docker ps | Select-String "signoz"
```

**Expected:** SigNoz, ClickHouse, OTel Collector containers running

**If not running:**
```powershell
docker-compose -f docker-compose-signoz.yml up -d
# Wait 30 seconds for startup
Start-Sleep -Seconds 30
```

**Verify SigNoz UI:**
- Open: http://localhost:8080
- Should load successfully

---

### 2. Resonai App Running ⚠️ MISSING

**Check:**
```powershell
Test-NetConnection -ComputerName localhost -Port 3000
```

**Expected:** TcpTestSucceeded: True

**If not running:**
```powershell
# Start the Resonai app
npm run dev
# Or in background:
Start-Process pwsh -ArgumentList "-Command", "npm run dev" -WindowStyle Hidden
```

**Verify:**
- Open: http://localhost:3000
- Should load application

---

### 3. Webhook Server Running ⚠️ MISSING

**Check:**
```powershell
Test-NetConnection -ComputerName localhost -Port 3003
```

**Expected:** TcpTestSucceeded: True

**If not running:**
```powershell
# Start webhook server (if you have one)
pwsh -File BRAV\SCPT\simple-webhook-server.ps1

# Or check what script starts it
dir BRAV\SCPT\*webhook*.ps1
```

---

### 4. Environment Variables Set ⚠️ MISSING

**Check:**
```powershell
$env:ALERT_WEBHOOK_URL
```

**Expected:** Should show a URL (e.g., http://localhost:3003/webhook)

**If not set:**
```powershell
# Set for current session
$env:ALERT_WEBHOOK_URL = "http://localhost:3003/webhook"

# Or add to .env file (if you use one)
# ALERT_WEBHOOK_URL=http://localhost:3003/webhook

# Or export persistently (optional)
[System.Environment]::SetEnvironmentVariable('ALERT_WEBHOOK_URL', 'http://localhost:3003/webhook', 'User')
```

---

### 5. Dashboard Config Present ⚠️ MISSING

**Check:**
```powershell
# Find which dashboard config is expected
Select-String -Path BRAV\SCPT\verify-all-components.ps1 -Pattern "dashboard.*json"
```

**Common locations (post-migration):**
- `DELT/CONF/config/signoz-*.json`
- `DELT/ASST/assets/dashboards/*.json`
- Root level: `signoz-queue-steward-dashboard.json`, etc.

**If missing:**
```powershell
# Check if it exists but in old location
dir *dashboard*.json -Recurse | Select-Object FullName

# Copy or create needed dashboard
# Example:
cp DELT\ASST\assets\dashboards\otel-collector-health.json .
```

---

### 6. OTel Collector Running

**Check:**
```powershell
# Windows service
sc query otelcol-contrib

# Or Docker
docker ps | Select-String "otel"
```

**Expected:** SERVICE_RUNNING or container running

**If not running:**
```powershell
# Windows service
sc start otelcol-contrib

# Or restart
pwsh -File BRAV\SCPT\restart-collector.ps1
```

---

## 🚀 Running Verification

### Full Verification (All Components)

```powershell
pwsh -File BRAV\SCPT\verify-all-components.ps1
```

### With End-to-End Test

```powershell
pwsh -File BRAV\SCPT\verify-all-components.ps1 -TestEndToEnd
```

### Check Specific Component

```powershell
# Just check SigNoz
curl http://localhost:8080/api/v1/health

# Just check collector
curl http://localhost:13134/

# Just check Resonai app
curl http://localhost:3000
```

---

## 📊 Expected Output

**Successful Verification:**
```
🐾 BossCat Component Verification
===================================

Examine: Checking all components...
  ✅ SigNoz UI: http://localhost:8080 (200 OK)
  ✅ OTel Collector: http://localhost:13134/ (200 OK)
  ✅ Resonai App: http://localhost:3000 (200 OK)
  ✅ Webhook Server: http://localhost:3003 (200 OK)
  ✅ ALERT_WEBHOOK_URL set

Clean: Running checks...
  ✅ End-to-end test: Completed

Report: Generated artifacts/component-verification-report.json
  ✅ All components: operational
  ✅ Evidence: captured

Role: BossCat OEM / Verification Agent
```

---

## 🔧 Troubleshooting

### Issue: "scripts/end-to-end-test.ps1 not found"

**Fixed!** Updated to `BRAV/SCPT/end-to-end-test.ps1` (commit: 52bb956)

If you still see this, ensure you have the latest code:
```powershell
git pull origin main
```

### Issue: Port Already in Use

**Error:** `Port 3000 is already in use`

**Fix:**
```powershell
# Find what's using the port
Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue

# Kill process if needed
Stop-Process -Id <PID>
```

### Issue: Services Not Starting

**Check logs:**
```powershell
# Docker logs
docker-compose logs -f signoz

# Windows Event Log
Get-EventLog -LogName Application -Newest 50 | Where-Object Source -Match "otel"
```

---

## 📝 Quick Start Script

Save this as `start-all-services.ps1` in BRAV/SCPT:

```powershell
Write-Host "🚀 Starting all services for verification..." -ForegroundColor Cyan

# Start SigNoz stack
docker-compose -f docker-compose-signoz.yml up -d
Write-Host "  ✅ SigNoz stack starting..." -ForegroundColor Green
Start-Sleep -Seconds 30

# Start Resonai app (if applicable)
if (Test-Path "package.json") {
    Start-Job -ScriptBlock { npm run dev } -Name "ResonaiApp"
    Write-Host "  ✅ Resonai app starting..." -ForegroundColor Green
    Start-Sleep -Seconds 10
}

# Start webhook server (if applicable)
if (Test-Path "BRAV\SCPT\simple-webhook-server.ps1") {
    Start-Job -ScriptBlock { pwsh -File BRAV\SCPT\simple-webhook-server.ps1 } -Name "WebhookServer"
    Write-Host "  ✅ Webhook server starting..." -ForegroundColor Green
    Start-Sleep -Seconds 5
}

# Set environment variable
$env:ALERT_WEBHOOK_URL = "http://localhost:3003/webhook"
Write-Host "  ✅ Environment variables set" -ForegroundColor Green

Write-Host "`n✅ All services started. Ready for verification!" -ForegroundColor Green
Write-Host "Run: pwsh -File BRAV\SCPT\verify-all-components.ps1" -ForegroundColor Cyan
```

**Usage:**
```powershell
pwsh -File BRAV\SCPT\start-all-services.ps1
pwsh -File BRAV\SCPT\verify-all-components.ps1
```

---

## 🎯 Post-Migration Notes

### Paths Updated (commit: 52bb956)

**17 workflows now use:**
- `BRAV/SCPT/` instead of `scripts/`
- Tetragram-compliant paths
- Ready for CI execution

**Verification script fixed:**
- `scripts/end-to-end-test.ps1` → `BRAV/SCPT/end-to-end-test.ps1`
- Will work correctly now

---

## 📞 Quick Commands

**Check all services:**
```powershell
# SigNoz
curl http://localhost:8080/api/v1/health

# Collector  
curl http://localhost:13134/

# Resonai app (if running)
curl http://localhost:3000

# Webhook (if running)
curl http://localhost:3003
```

**Run verification:**
```powershell
pwsh -File BRAV\SCPT\verify-all-components.ps1
```

**View report:**
```powershell
cat CHAR\EVID\artifacts\component-verification-report.json | ConvertFrom-Json | ConvertTo-Json -Depth 10
```

---

🐾 **After starting all services, rerun the verification. It should now pass cleanly with the updated paths!**

---

_Checklist: Verification Readiness_  
_Updated: 2025-10-09 (post-tetragram migration)_  
_Script Fixed: commit 52bb956_

