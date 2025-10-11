# 🐾 Option B Service Troubleshooting Guide

**Date:** 2025-10-11  
**Issue:** Windows Collector Service Won't Start (Error 1077)  
**Status:** ⚠️ Elevated Session Confirmed, Service Issue Detected

---

## 🔍 DIAGNOSIS

### ✅ **Confirmed Working:**
- Elevated PowerShell session (Administrator: True)
- Config file source exists: `C:\otel\config\otelcol-windows.yaml`

### ❌ **Issues Identified:**

**1. Config Copy Failed (Even When Elevated):**
```
Access to the path 'C:\ProgramData\OpenTelemetry Collector\config.yaml' is denied.
```

**2. Service Won't Start:**
```
STATE: 1 STOPPED
WIN32_EXIT_CODE: 1077 (0x435)
Error: Cannot start service 'otelcol-contrib' on computer '.'
```

**Error 1077 Meanings:**
- Service does not exist
- Service dependency not met
- Service configuration invalid
- Service binary path incorrect

---

## 🔧 TROUBLESHOOTING STEPS

### **Step 1: Verify Service Installation**

```powershell
# Check if service exists
Get-Service -Name otelcol-contrib -ErrorAction SilentlyContinue

# Check service registry
Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\otelcol-contrib" -ErrorAction SilentlyContinue

# List all otel services
Get-Service | Where-Object { $_.Name -like "*otel*" }
```

**Expected:** Service should be listed  
**If not found:** Service needs to be installed

---

### **Step 2: Check Service Configuration**

```powershell
# Query service config
sc.exe qc otelcol-contrib

# Look for:
# - BINARY_PATH_NAME: Should point to valid .exe
# - START_TYPE: Should be AUTO_START or DEMAND_START
# - SERVICE_START_NAME: Service account (usually LocalSystem)
```

**Verify binary exists:**
```powershell
# Get binary path from config
$config = sc.exe qc otelcol-contrib | Out-String
if ($config -match 'BINARY_PATH_NAME\s*:\s*"?([^"]+)"?') {
    $binPath = $Matches[1].Trim('"')
    Test-Path $binPath
}
```

---

### **Step 3: Check Config File Paths**

```powershell
# Check if config directory exists
Test-Path "C:\ProgramData\OpenTelemetry Collector"

# If not, create it
New-Item -Path "C:\ProgramData\OpenTelemetry Collector" -ItemType Directory -Force

# Copy config manually
Copy-Item -Path "C:\otel\config\otelcol-windows.yaml" -Destination "C:\ProgramData\OpenTelemetry Collector\config.yaml" -Force

# Verify copy
Test-Path "C:\ProgramData\OpenTelemetry Collector\config.yaml"
```

---

### **Step 4: Check Windows Event Log**

```powershell
# Check Application log for OpenTelemetry errors
Get-EventLog -LogName Application -Source "*OpenTelemetry*" -Newest 50 -ErrorAction SilentlyContinue | Format-Table -AutoSize

# Or use Get-WinEvent for more details
Get-WinEvent -LogName Application -MaxEvents 50 | Where-Object { $_.Message -like "*otelcol*" -or $_.Message -like "*OpenTelemetry*" } | Format-List TimeCreated, LevelDisplayName, Message
```

---

### **Step 5: Manual Service Start with Error Details**

```powershell
# Try to start and capture error
try {
    Start-Service -Name otelcol-contrib -ErrorAction Stop
    Write-Host "✅ Service started successfully!"
} catch {
    Write-Host "❌ Service start failed:"
    Write-Host $_.Exception.Message
    Write-Host ""
    Write-Host "Inner Exception:"
    Write-Host $_.Exception.InnerException
}

# Check service after attempt
sc query otelcol-contrib
```

---

### **Step 6: Check Service Dependencies**

```powershell
# List service dependencies
sc.exe qc otelcol-contrib | Select-String -Pattern "DEPENDENCIES"

# Check if dependencies are running
$deps = (sc.exe qc otelcol-contrib | Select-String -Pattern "DEPENDENCIES").ToString()
if ($deps -match "DEPENDENCIES\s*:\s*(.+)") {
    $depList = $Matches[1].Trim()
    if ($depList -ne "") {
        $depList -split "/" | ForEach-Object {
            $depName = $_.Trim()
            Get-Service -Name $depName -ErrorAction SilentlyContinue
        }
    }
}
```

---

## 🚨 ALTERNATIVE: Check if Service is Installed

### **Possible Issue: Service Not Installed**

If the service doesn't exist or was improperly installed:

```powershell
# Check if service is registered
$service = Get-Service -Name otelcol-contrib -ErrorAction SilentlyContinue

if (-not $service) {
    Write-Host "❌ Service NOT installed!"
    Write-Host "   You need to install OpenTelemetry Collector service first."
    Write-Host ""
    Write-Host "Installation options:"
    Write-Host "  1. Download from: https://github.com/open-telemetry/opentelemetry-collector-releases"
    Write-Host "  2. Use MSI installer or manual service registration"
    Write-Host "  3. Or use docker-compose instead (no Windows service needed)"
} else {
    Write-Host "✅ Service is registered"
    Write-Host "   Name: $($service.Name)"
    Write-Host "   Display: $($service.DisplayName)"
    Write-Host "   Status: $($service.Status)"
}
```

---

## 🎯 FALLBACK OPTIONS

### **Option A: Use Docker Compose (Recommended)**

If Windows service is problematic, use the containerized stack instead:

```powershell
# Start SigNoz + Collector via Docker
docker-compose -f docker-compose-signoz.yml up -d

# Check collector is running
docker ps | Select-String otelcol

# Collector will be available on same ports (5317, 5318)
```

**Advantage:** No Windows service required, proven working

---

### **Option B: Manual Collector (Standalone)**

Run collector manually (no service):

```powershell
# Navigate to collector binary directory
cd "C:\Program Files\OpenTelemetry Collector"

# Run collector directly
.\otelcol-contrib.exe --config "C:\otel\config\otelcol-windows.yaml"
```

**Advantage:** Bypasses service registration issues

---

### **Option C: Skip Option B for This Gate**

Since Option B is **conditional** and **soft-fail** by default:

```
Gate #007: PR-Merge READY ✅
Option B: HOLD (Service unavailable - known issue)

Decision: Approve PR-Merge gate with Option B as informational
Action: Track Windows service issue as tech debt
Status: Production ready (Option B non-blocking)
```

---

## 📊 CURRENT ECRR STATUS

**Latest Run:** `ECRR_20251011_003823_SSOT.json`
- Outcome: "hold"
- P95: null
- Service: Not running
- Canary: Failed

**This is expected** given the service won't start.

---

## 🎯 RECOMMENDED NEXT STEPS

### **Quick Path (Recommended):**

**Use Docker Compose instead of Windows service:**

```powershell
# Check if SigNoz stack is running
docker ps

# If not, start it
docker-compose -f docker-compose-signoz.yml up -d

# Verify collector container
docker ps | Select-String otelcol

# Then retest
pnpm emit:full
pnpm otel:optionB
```

---

### **Diagnostic Path (If you want to fix Windows service):**

```powershell
# 1. Check service config
sc.exe qc otelcol-contrib

# 2. Check event logs
Get-EventLog -LogName Application -Newest 50

# 3. Verify binary path exists
# (from sc.exe qc output)

# 4. Try manual start with detailed errors
Start-Service otelcol-contrib -ErrorAction Continue

# 5. If service doesn't exist, it needs installation
```

---

## 📢 DECISION POINT

**You can choose:**

**Option 1:** Fix Windows service (requires debugging)  
**Option 2:** Use Docker Compose collector (proven working)  
**Option 3:** Skip Option B for this gate (soft-fail mode)

**My recommendation:** Use Docker Compose (fastest path to green)

---

🐾 **Let me know which path you'd like to take!**
