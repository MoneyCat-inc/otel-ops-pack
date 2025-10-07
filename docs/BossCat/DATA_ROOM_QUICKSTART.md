# Data Room — Quick Start & Troubleshooting

**Version**: 1.0  
**Date**: 2025-10-07  
**BossCat OEM Certified**

---

## 🚀 QUICK START (3 STEPS)

### **Step 1: Start Services**

```powershell
# Start SigNoz
docker-compose up -d

# Start OTel Collector
sc start otelcol-contrib

# Wait 30 seconds
Start-Sleep -Seconds 30
```

### **Step 2: Open Data Room**

```bash
# IONA-integrated version (production)
start docs/BossCat/data_room_iona.html

# Or from project hub
start index.html
# → Testing & QA → Data Room (IONA Live)
```

### **Step 3: Test Connection**

Click **"🔌 Test Connection"** in the Data Room.

**Expected**: ✅ Status bar shows "All connections successful!"

---

## 🔧 TROUBLESHOOTING (30-SECOND FIX)

### **Problem: JSON Parse Error**

```
⚠️ SigNoz connection error: JSON.parse: unexpected character
```

**Cause**: SigNoz returning HTML instead of JSON (usually means it's not running)

**Fix**:
```powershell
# Quick restart
docker-compose restart
Start-Sleep -Seconds 30

# Then reload Data Room
# Press F5 in browser
```

---

### **Problem: Connection Refused**

```
⚠️ SigNoz connection error: Failed to fetch
```

**Cause**: SigNoz not running or wrong port

**Fix**:
```powershell
# Check if running
docker ps | findstr signoz

# If not running
docker-compose up -d

# Verify
Start-Process "http://localhost:8080"
```

---

### **Problem: OTLP Send Fails**

```
❌ Failed to send log: HTTP 404
```

**Cause**: OTel Collector not running

**Fix**:
```powershell
# Check status
Get-Service otelcol-contrib

# If stopped
sc start otelcol-contrib

# Verify
Test-NetConnection localhost -Port 5318
```

---

## 🔍 DIAGNOSTIC TOOLS

### **Tool 1: Debug Mode (Most Powerful)**

```bash
start docs/BossCat/data_room_iona_debug.html
```

**Features**:
- Tests all endpoints
- Shows exact HTTP responses
- Previews response bodies
- Identifies JSON parse issues

**Use When**: Any connection error

---

### **Tool 2: Health Check Script**

```powershell
# Copy/paste this entire block
Write-Host "=== Quick Health Check ===" -ForegroundColor Cyan

# Docker
Write-Host "`n1. SigNoz Containers:" -ForegroundColor Yellow
docker ps --format "{{.Names}}\t{{.Status}}" | Select-String "signoz"

# OTel
Write-Host "`n2. OTel Collector:" -ForegroundColor Yellow
Get-Service otelcol-contrib | Format-Table Name, Status -AutoSize

# API Test
Write-Host "`n3. SigNoz API:" -ForegroundColor Yellow
try {
  $r = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/version" -UseBasicParsing
  Write-Host "✅ HTTP $($r.StatusCode)" -ForegroundColor Green
} catch {
  Write-Host "❌ FAILED: $_" -ForegroundColor Red
}

Write-Host "`n=== Done ===" -ForegroundColor Cyan
```

**Use When**: Quick sanity check

---

### **Tool 3: PowerShell Direct Send**

```powershell
# Bypass browser entirely - send log via PowerShell
$payload = @{
  resourceLogs = @(@{
    resource = @{ attributes = @(@{ key = "service.name"; value = @{ stringValue = "ps-test" } }) }
    scopeLogs = @(@{
      scope = @{ name = "test"; version = "1.0" }
      logRecords = @(@{
        timeUnixNano = "$(((Get-Date).ToUniversalTime() - [datetime]'1970-01-01').TotalMilliseconds * 1000000)"
        severityNumber = 9
        severityText = "INFO"
        body = @{ stringValue = "PowerShell test - $(Get-Date)" }
      })
    })
  })
} | ConvertTo-Json -Depth 10

Invoke-WebRequest -Uri "http://localhost:5318/v1/logs" `
  -Method POST -ContentType "application/json" -Body $payload -UseBasicParsing
```

**Use When**: Browser API doesn't work

**Then verify in SigNoz**: Filter by `service.name = "ps-test"`

---

## 📋 PRE-FLIGHT CHECKLIST

Before using Data Room, verify:

- [ ] Docker Desktop is running
- [ ] `docker ps` shows 4+ SigNoz containers
- [ ] `http://localhost:8080` loads SigNoz UI
- [ ] `Get-Service otelcol-contrib` shows "Running"
- [ ] Port 5318 is listening (OTel Collector)
- [ ] Port 8080 is listening (SigNoz)

**Quick verify**:
```powershell
docker ps --format "{{.Names}}" | Select-String "signoz" | Measure-Object | Select-Object Count
# Expected: Count = 4 or more
```

---

## 🎯 COMMON WORKFLOWS

### **Workflow 1: Send Canary Test**

1. Open Data Room IONA
2. Click **"🐤 Send Canary"**
3. Note canary ID (e.g., `canary-abc123`)
4. Open SigNoz UI → Logs
5. Filter: `canary.source = "data-room-iona"`
6. Verify canary appears with correct ID

**Time**: 30 seconds

---

### **Workflow 2: Monitor Pipeline Health**

1. Open Data Room IONA
2. Observe **"IONA Controller Status"** section
3. Check Health Score (should be 90+)
4. Monitor "Active Anomalies" (should be 0)
5. Review "Pipeline Status" (should be "Active")

**Auto-refreshes**: Every 10 seconds

---

### **Workflow 3: Generate Test Load**

1. Open Data Room IONA
2. Click **"🌊 Send Laminar"** 10 times rapidly
3. Watch throughput chart update
4. Check SigNoz UI for 10 new logs
5. Verify all have `flow.type = "laminar"`

**Expected**: 10/10 logs appear within 5 seconds

---

### **Workflow 4: Emergency Stop**

1. Open Data Room IONA
2. Click **"🛑 Stop Signal"**
3. Verify log sent (status bar confirms)
4. Check SigNoz: `signal.type = "emergency-stop"`
5. Confirm WARN-level log appears

**Use Case**: Halt tests immediately, trigger alerts

---

## 📦 DATA ROOM VERSIONS

### **3 Versions Available**

| Version | Purpose | Link |
|---------|---------|------|
| **IONA Integrated** (Production) | Real OTLP + SigNoz | `data_room_iona.html` ⭐ |
| **IONA Debug** (Troubleshooting) | Diagnostics + Testing | `data_room_iona_debug.html` 🔍 |
| **Enhanced Mockup** (Demo) | Simulated data | `data_room_enhanced.html` |
| **Original Mockup** (Reference) | Basic version | `data_room.html` |

**Recommended**: Use IONA Integrated for production, Debug for troubleshooting

---

## 🚨 EMERGENCY RECOVERY

**If everything is broken:**

```powershell
# Nuclear option - full restart
Write-Host "Stopping all services..." -ForegroundColor Yellow
docker-compose down
sc stop otelcol-contrib
Start-Sleep -Seconds 10

Write-Host "Starting all services..." -ForegroundColor Yellow
docker-compose up -d
sc start otelcol-contrib
Start-Sleep -Seconds 30

Write-Host "Verifying..." -ForegroundColor Yellow
docker ps
Get-Service otelcol-contrib
Start-Process "http://localhost:8080"

Write-Host "Done! Retry Data Room now." -ForegroundColor Green
```

**Time**: 45 seconds

---

## 📞 GETTING HELP

### **Self-Service Diagnostics**

1. **Run Debug Mode**: `start docs/BossCat/data_room_iona_debug.html`
2. **Click "Run Full Diagnostics"**
3. **Review output** - shows exact errors
4. **Copy debug output** - share with team if needed

### **Documentation**

- **User Guide**: `docs/BossCat/DATA_ROOM_GUIDE.md`
- **Project Hub**: `index.html`
- **Architecture**: `docs/BossCat/SYSTEM_ARCHITECTURE_DIAGRAM.md`

### **Quick Links**

- SigNoz UI: http://localhost:8080
- OTel Collector: http://localhost:5318
- Project Hub: file:///C:/otel/index.html

---

## ✅ SUCCESS INDICATORS

### **Healthy System**

✅ Status bar: "✅ Connected to SigNoz"  
✅ IONA Health Score: 90-100  
✅ Active Anomalies: 0  
✅ Pipeline Status: "Active"  
✅ Logs table: Populated with real data  
✅ Chart: Updating with throughput metrics

### **Problem System**

❌ Status bar: "⚠️ SigNoz connection error"  
❌ IONA Health Score: < 70  
❌ Active Anomalies: > 5  
❌ Pipeline Status: "Idle" or "Unknown"  
❌ Logs table: Error message or empty  
❌ Chart: No data or flat line

---

## 🎓 TIPS & TRICKS

### **Tip 1: Bookmark Debug Mode**

Add to browser favorites for quick access:
```
file:///C:/otel/docs/BossCat/data_room_iona_debug.html
```

### **Tip 2: Create PowerShell Alias**

Add to your PowerShell profile:
```powershell
# $PROFILE
function Start-DataRoom {
    Start-Process "C:\otel\docs\BossCat\data_room_iona.html"
}

# Usage: Start-DataRoom
```

### **Tip 3: Auto-Start Script**

Create `start-observability.ps1`:
```powershell
docker-compose up -d
sc start otelcol-contrib
Start-Sleep -Seconds 30
Start-Process "http://localhost:8080"
Start-Process "C:\otel\docs\BossCat\data_room_iona.html"
```

### **Tip 4: Health Check Cron**

Schedule health checks every hour:
```powershell
# Task Scheduler
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
  -Argument "-File C:\otel\scripts\health-check.ps1"
$trigger = New-ScheduledTaskTrigger -Daily -At 9am -RepetitionInterval (New-TimeSpan -Hours 1)
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "OTel Health Check"
```

---

**🐾 BossCat OEM Quick Start Card**  
*Keep this handy for rapid troubleshooting!*

