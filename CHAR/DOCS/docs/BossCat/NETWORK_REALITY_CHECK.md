# 🐾 BossCat Network Reality Check - Critical for Setup Alerts Tile

**Authority:** BossCat OEM (Executive Overseer Manager)  
**Timestamp:** 2025-10-08T06:25:00Z  
**Status:** ⚠️ **CRITICAL - NETWORK CONFIGURATION REQUIRED**

---

## ⚠️ **Network Reality Check - AVOID "STILL BLUE" TILE**

### **The Problem:**
**GitHub-hosted runners cannot reach `http://localhost:8080` on *your* machine.**

If you're using GitHub Actions with `SIGNOZ_URL=http://localhost:8080`, the workflow will:
- ✅ Run successfully (exit 0)
- ✅ Report "alerts created"
- ❌ **Never actually reach SigNoz** (network unreachable)
- ❌ **Tile stays BLUE** (no alerts created)

---

## ✅ **Solutions (Pick One)**

### **Solution 1: Self-Hosted Runner (Recommended)**

Use a self-hosted GitHub Actions runner in the same network as SigNoz.

#### **Setup:**
1. **Install runner on a machine that can reach SigNoz:**
   ```bash
   # Download and configure GitHub Actions runner
   # See: https://github.com/<org>/<repo>/settings/actions/runners/new
   ```

2. **Update workflow to use self-hosted runner:**
   ```yaml
   # .github/workflows/signoz-alerts.yml
   jobs:
     alerts:
       runs-on: self-hosted  # or your custom label
       env:
         SIGNOZ_URL: http://localhost:8080  # or internal network address
         SIGNOZ_API_KEY: ${{ secrets.WYZWOZ_SIGNOZ }}
   ```

#### **Benefits:**
- ✅ Direct network access to SigNoz
- ✅ No firewall/NAT configuration needed
- ✅ Fastest execution
- ✅ Most secure (no external exposure)

---

### **Solution 2: Publicly Reachable SigNoz**

Expose SigNoz with DNS/IP and configure firewall allow-list.

#### **Setup:**
1. **Configure public access:**
   ```bash
   # Option A: Use reverse proxy (nginx/traefik)
   # Option B: Configure cloud load balancer
   # Option C: Use ngrok/cloudflared tunnel (testing only)
   ```

2. **Update workflow with public URL:**
   ```yaml
   # .github/workflows/signoz-alerts.yml
   jobs:
     alerts:
       runs-on: ubuntu-latest  # or windows-latest
       env:
         SIGNOZ_URL: https://signoz.yourdomain.com  # or http://public-ip:8080
         SIGNOZ_API_KEY: ${{ secrets.WYZWOZ_SIGNOZ }}
   ```

3. **Configure firewall allow-list:**
   - Allow GitHub Actions IP ranges
   - See: https://api.github.com/meta (actions IP ranges)

#### **Benefits:**
- ✅ Works with GitHub-hosted runners
- ✅ No runner maintenance
- ⚠️ Requires secure exposure (HTTPS, firewall rules)

---

### **Solution 3: Local Execution Only**

Skip CI/CD and run locally from a machine that can reach SigNoz.

#### **Setup:**
```powershell
$env:SIGNOZ_URL = "http://localhost:8080"  # or internal network address
$env:SIGNOZ_API_KEY = $env:WYZWOZ_SIGNOZ  # or paste key

# Single orchestration command:
pwsh -File scripts\bosscat-hands-free-switch-on.ps1 `
  -SigNozUrl $env:SIGNOZ_URL `
  -ApiKey $env:SIGNOZ_API_KEY
```

#### **Benefits:**
- ✅ Immediate execution
- ✅ No network configuration needed
- ✅ Direct feedback
- ⚠️ Manual execution required

---

## 🧪 **Network Connectivity Test**

Before executing, verify the runner/machine can reach SigNoz:

### **Test 1: Health Check**
```powershell
$env:SIGNOZ_URL = "http://localhost:8080"  # or your SigNoz URL

# Test health endpoint
try {
  $health = Invoke-WebRequest -Uri "$env:SIGNOZ_URL/api/v1/health" -UseBasicParsing -TimeoutSec 10
  if ($health.StatusCode -eq 200) {
    Write-Host "✅ SigNoz reachable at $env:SIGNOZ_URL" -ForegroundColor Green
  }
} catch {
  Write-Host "❌ Cannot reach SigNoz at $env:SIGNOZ_URL" -ForegroundColor Red
  Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
}
```

### **Test 2: API Endpoint Check**
```powershell
$env:SIGNOZ_URL = "http://localhost:8080"
$env:SIGNOZ_API_KEY = $env:WYZWOZ_SIGNOZ

# Test rules endpoint with auth
try {
  $rules = Invoke-RestMethod -Uri "$env:SIGNOZ_URL/api/v1/rules" `
    -Headers @{ "SIGNOZ-API-KEY" = $env:SIGNOZ_API_KEY } `
    -TimeoutSec 10
  Write-Host "✅ Rules endpoint reachable, found $($rules.Count) rules" -ForegroundColor Green
} catch {
  Write-Host "❌ Cannot reach rules endpoint" -ForegroundColor Red
  Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
}
```

---

## 🎯 **Recommended Execution Path**

### **Current Network Configuration:**
- 🔵 **SigNoz Location:** `http://localhost:8080` (local machine)
- 🔵 **Runner Type:** GitHub-hosted (assumed)
- ⚠️ **Network Access:** ❌ Runner cannot reach SigNoz

### **Recommended Path: Local Execution (Solution 3)**

Since SigNoz is running on `localhost:8080`, the fastest path is **local execution**:

```powershell
# Navigate to project directory
cd C:\otel

# Set environment variables
$env:SIGNOZ_URL = "http://localhost:8080"
$env:SIGNOZ_API_KEY = $env:WYZWOZ_SIGNOZ  # or paste the key

# Execute hands-free switch-on
pwsh -File scripts\bosscat-hands-free-switch-on.ps1 `
  -SigNozUrl $env:SIGNOZ_URL `
  -ApiKey $env:SIGNOZ_API_KEY
```

**Expected Runtime:** 30-60 seconds

**Expected Output:**
```
✅ Smoke-check: GET /api/v1/rules → 200
✅ Sentinel: POST → 200/201
✅ Full set: Applied 8 alerts
✅ Verification: Found 8 (critical=3, warning=5) → exit 0
```

**Then verify in SigNoz UI:**
- Reload `http://localhost:8080` → Home
- "Setup Alerts" tile should be **GREEN**

---

## 🧯 **Troubleshooting Network Issues**

### **Issue 1: "Connection refused" or "Cannot reach"**
**Cause:** SigNoz not running or wrong URL

**Fix:**
```bash
# Check SigNoz containers
docker ps | grep signoz

# Check SigNoz health directly
curl http://localhost:8080/api/v1/health
```

### **Issue 2: "401 Unauthorized"**
**Cause:** API key invalid or not set

**Fix:**
```powershell
# Verify API key is set
if ($env:WYZWOZ_SIGNOZ) {
  Write-Host "✅ API key is set"
} else {
  Write-Host "❌ API key not set - set WYZWOZ_SIGNOZ environment variable"
}
```

### **Issue 3: "404 Not Found"**
**Cause:** Wrong API path

**Fix:**
- Ensure path is `/api/v1/rules` (not `/api/v1/alerts`)
- Our scripts already use the correct path

### **Issue 4: GitHub Actions workflow fails**
**Cause:** Runner cannot reach SigNoz

**Fix:**
- Switch to **Solution 1** (self-hosted runner)
- Or **Solution 2** (publicly reachable SigNoz)
- Or skip CI and use **Solution 3** (local execution)

---

## 📋 **Pre-Execution Checklist**

Before executing, verify:

- [ ] **Network:** Runner/machine can reach SigNoz URL
- [ ] **Health:** `http://localhost:8080/api/v1/health` returns 200
- [ ] **API Key:** `WYZWOZ_SIGNOZ` or `SIGNOZ_API_KEY` is set
- [ ] **Endpoint:** Scripts use `/api/v1/rules` (already configured)
- [ ] **Header:** Scripts use `SIGNOZ-API-KEY` (already configured)

---

## ✅ **Post-Execution Verification**

After execution, verify:

- [ ] Console shows: `Found 8 (critical=3, warning=5)` + exit 0
- [ ] SigNoz Home → "Setup Alerts" tile is **GREEN**
- [ ] SigNoz Alerts page shows 8 BossCat alerts
- [ ] All alerts show `disabled = false`
- [ ] Verification artifact: `docs/BossCat/signoz-completion-verification.json`

---

## 🧾 **ECRR Ledger Entry (Post-Execution)**

Add to `docs/BossCat/BOSSCAT_LOG.md`:
```
2025-10-08: Hands-free switch-on executed with WYZWOZ_SIGNOZ; Setup Alerts BLUE→GREEN; 8 rules present (3 critical/5 warning); verification artifact uploaded.
```

---

## 🐾 **BossCat Executive Summary**

### **Critical Network Reality:**
**GitHub-hosted runners cannot reach `http://localhost:8080` on your machine.**

### **Recommended Action:**
**Use Solution 3 (Local Execution)** - fastest and most straightforward for localhost SigNoz.

### **Execution Command:**
```powershell
cd C:\otel
$env:SIGNOZ_URL = "http://localhost:8080"
$env:SIGNOZ_API_KEY = $env:WYZWOZ_SIGNOZ
pwsh -File scripts\bosscat-hands-free-switch-on.ps1 -SigNozUrl $env:SIGNOZ_URL -ApiKey $env:SIGNOZ_API_KEY
```

### **Expected Outcome:**
- ✅ Sentinel flips tile BLUE → GREEN
- ✅ 8 BossCat alerts created (3 critical + 5 warning)
- ✅ Verification exit 0
- ✅ Complete ECRR audit trail

### **Authority:**
**BossCat OEM (Executive Overseer Manager)**
- Network reality check documented
- Local execution path recommended
- Feline Silence maintained
- Gate integrity preserved

---

> **🎯 Network configuration is critical for success.**  
> **✅ Local execution recommended for localhost SigNoz.**  
> **🐾 Authority: BossCat OEM - Ready for local execution.**

**Execute the local command above, and the stack will create the sentinel, upsert all 8 alerts, verify completion, and flip the tile to GREEN.** 🐾

---

**🐾 End of Network Reality Check - Local Execution Recommended** 🐾

