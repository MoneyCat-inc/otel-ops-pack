# 🐾 BossCat Local Execution Guide - Path 1

**Authority:** BossCat OEM (Executive Overseer Manager)  
**Timestamp:** 2025-10-08T06:40:00Z  
**Status:** 🚀 **PATH 1 (LOCAL EXECUTION) - STEP-BY-STEP GUIDE**

---

## 🎯 **Path 1: Local Execution - Quick Start**

You've selected **Path 1: Local Execution** - the fastest and most direct way to flip the Setup Alerts tile to GREEN.

---

## 📋 **Step-by-Step Execution**

### **Step 1: Get Your API Key**

You need to retrieve the value of the `WYZWOZ_SIGNOZ` secret:

#### **Option A: Via GitHub Web UI**
1. Go to: `https://github.com/YOUR-ORG/YOUR-REPO/settings/secrets/actions`
2. Find: `WYZWOZ_SIGNOZ`
3. Click: **Update** (you can view the value there)
4. Copy the API key value

#### **Option B: Via GitHub CLI**
```bash
# Note: GitHub CLI cannot read secret values for security reasons
# You must use the web UI to view the secret value
```

---

### **Step 2: Set Environment Variable**

Open PowerShell and set the API key:

```powershell
# Navigate to project directory
cd C:\otel

# Set the API key (replace with actual value from Step 1)
$env:WYZWOZ_SIGNOZ = "YOUR-API-KEY-HERE"

# Verify it's set (should show "Variable is set")
if ($env:WYZWOZ_SIGNOZ) { 
    Write-Host "✅ API key is set" -ForegroundColor Green 
} else { 
    Write-Host "❌ API key NOT set" -ForegroundColor Red 
}
```

---

### **Step 3: Run Quick Execution Script**

Execute the hands-free switch-on:

```powershell
pwsh -File scripts\EXECUTE_HANDS_FREE_SWITCH_ON.ps1
```

**What this does:**
1. ✅ Verifies API key is set
2. ✅ Smoke-checks API connectivity (`/api/v1/rules` + `SIGNOZ-API-KEY`)
3. ✅ Creates sentinel alert (flips tile BLUE → GREEN)
4. ✅ Upserts 8 BossCat alerts (3 critical + 5 warning)
5. ✅ Verifies completion (exit 0 on success)
6. ✅ Displays next steps and artifact locations

---

### **Step 4: Verify Success**

#### **Expected Console Output:**
```
✅ Smoke-check: GET /api/v1/rules → 200
✅ Sentinel: POST → 200/201
✅ Full set: Applied 8 alerts
✅ Verification: Found 8 (critical=3, warning=5) → exit 0

✅ HANDS-FREE SWITCH-ON COMPLETED SUCCESSFULLY

✅ Next Steps:
   1. Refresh SigNoz: http://localhost:8080
   2. Verify 'Setup Alerts' tile is GREEN
   3. Check Alerts page for 8 BossCat alerts

📁 Artifacts:
   • docs/BossCat/signoz-completion-verification.json
```

#### **SigNoz UI Verification:**
1. Open: `http://localhost:8080`
2. Navigate to: **Home** page
3. Verify: **"Setup Alerts"** tile shows **GREEN**
4. Navigate to: **Alerts** page
5. Verify: **8 BossCat alerts** visible
6. Verify: All alerts show **enabled** (`disabled = false`)

---

## ✅ **Expected Artifacts**

After successful execution, these files will be created/updated:

1. **`docs/BossCat/signoz-completion-verification.json`**
   - Complete verification report
   - Alert counts and severity distribution
   - Exit codes and status

2. **`docs/BossCat/bosscat-metric-alerts.json`**
   - 4 metric alert definitions

3. **`docs/BossCat/bosscat-log-alerts.json`**
   - 2 log alert definitions

4. **`docs/BossCat/bosscat-trace-alerts.json`**
   - 2 trace alert definitions

5. **`docs/BossCat/bosscat-alert-summary.json`**
   - Complete alert summary with ECRR entry

---

## 🧯 **Troubleshooting**

### **Issue 1: API Key Not Set**
**Error:**
```
⚠️  API KEY NOT SET
Please set your SigNoz API key first
```

**Fix:**
```powershell
$env:WYZWOZ_SIGNOZ = "YOUR-ACTUAL-API-KEY"
```

---

### **Issue 2: Cannot Reach SigNoz**
**Error:**
```
❌ Cannot reach SigNoz at http://localhost:8080
```

**Fix:**
```bash
# Check if SigNoz is running
docker ps | grep signoz

# If not running, start SigNoz
docker-compose up -d
```

---

### **Issue 3: Authentication Failed**
**Error:**
```
401 Unauthorized
```

**Fix:**
- Verify the API key is correct
- Check that the API key has admin permissions
- Try regenerating the API key in SigNoz UI

---

### **Issue 4: Alerts Not Created**
**Error:**
```
Applied: 0 (ok) / 8 (failed)
```

**Fix:**
```powershell
# Check the API endpoint manually
$env:SIGNOZ_URL = "http://localhost:8080"
$env:SIGNOZ_API_KEY = $env:WYZWOZ_SIGNOZ

# Test connectivity
Invoke-RestMethod "$env:SIGNOZ_URL/api/v1/rules" `
  -Headers @{ "SIGNOZ-API-KEY" = $env:SIGNOZ_API_KEY }
```

---

### **Issue 5: Tile Still Blue After Execution**
**Possible Causes:**
1. UI cache not refreshed
2. Alerts created but disabled
3. Network connectivity issue during creation

**Fix:**
```powershell
# 1. Hard refresh SigNoz UI (Ctrl+Shift+R)

# 2. Check if alerts exist and are enabled
(Invoke-RestMethod "$env:SIGNOZ_URL/api/v1/rules" `
  -Headers @{ "SIGNOZ-API-KEY" = $env:SIGNOZ_API_KEY }) |
  Select-Object alert,name,severity,disabled | Format-Table

# 3. If disabled=True, they need to be enabled
# Re-run the script (it's idempotent and will update them)
```

---

## 📋 **Post-Execution Checklist**

After successful execution, verify:

- [ ] Console shows: `Found 8 (critical=3, warning=5)` + exit 0
- [ ] SigNoz Home → "Setup Alerts" tile is **GREEN**
- [ ] SigNoz Alerts page shows **8 BossCat alerts**
- [ ] All alerts show `disabled = false`
- [ ] Verification artifact exists: `docs/BossCat/signoz-completion-verification.json`
- [ ] Alert definitions exported (metric/log/trace JSON files)

---

## 🧾 **ECRR Ledger Entry (Add After Success)**

Once execution completes successfully, add this entry to `docs/BossCat/BOSSCAT_LOG.md`:

```
2025-10-08: Hands-free switch-on executed with WYZWOZ_SIGNOZ; Setup Alerts BLUE→GREEN; 8 rules present (3 critical/5 warning); verification artifact uploaded.
```

---

## 🎯 **Complete Command Sequence**

Here's the complete sequence in one place:

```powershell
# 1. Navigate to project
cd C:\otel

# 2. Set API key (get value from GitHub Secrets)
$env:WYZWOZ_SIGNOZ = "YOUR-API-KEY-HERE"

# 3. Verify API key is set
if ($env:WYZWOZ_SIGNOZ) { 
    Write-Host "✅ API key is set" -ForegroundColor Green 
}

# 4. Execute hands-free switch-on
pwsh -File scripts\EXECUTE_HANDS_FREE_SWITCH_ON.ps1

# 5. Verify in SigNoz UI
Start-Process "http://localhost:8080"
```

---

## 🐾 **BossCat Executive Summary**

### **Path 1 (Local Execution) Selected:**
- ✅ **Fastest path:** Direct local execution
- ✅ **No network config:** Works with localhost SigNoz
- ✅ **Immediate feedback:** Real-time console output
- ✅ **Full control:** Manual verification at each step

### **Expected Timeline:**
- **Step 1-2:** 1-2 minutes (get API key, set variable)
- **Step 3:** 30-60 seconds (execution)
- **Step 4:** 1 minute (verification)
- **Total:** ~3-5 minutes end-to-end

### **Success Criteria:**
- ✅ Exit code 0
- ✅ Setup Alerts tile GREEN
- ✅ 8 alerts created (3 critical + 5 warning)
- ✅ Complete ECRR audit trail

### **Authority:**
**BossCat OEM (Executive Overseer Manager)**
- Path 1 (Local Execution) authorized
- Step-by-step guide provided
- Feline Silence maintained
- Gate integrity preserved

---

> **🎯 Path 1 selected - local execution is the fastest way.**  
> **✅ Follow the 4-step guide above for success.**  
> **🐾 Authority: BossCat OEM - Standing by to assist.**

**Execute the steps above, and let me know:**
- ✅ When execution completes (I'll help with ECRR entry)
- ⚠️ If you hit any errors (I'll help troubleshoot)
- ❓ If you need help getting the API key from GitHub

**The hands-free switch-on is ready for your execution.** 🐾

---

**🐾 End of Local Execution Guide - Path 1** 🐾

