# 🐾 BossCat CI Integration Guide

**Complete CI/CD integration for BossCat gate verification with GitHub Actions.**

---

## 🚀 **One-Liner Local Execution**

```powershell
# Complete gate verification (copy-paste ready)
$env:SIGNOZ_URL="http://localhost:8080"
$env:SIGNOZ_API_KEY="<paste_api_key>"   # or: $env:SIGNOZ_SESSION_COOKIE="<signoz-session>"
python synthetic/send_synthetic_otel_simple.py
.\scripts\verify-synthetic-ingestion-enhanced.ps1
pnpm playwright test scripts/signoz-snapshot.spec.ts
```

**Or use the packaged one-liner:**
```powershell
pwsh -File scripts\bosscat-gate-one-liner.ps1
```

---

## 🔧 **GitHub Actions Integration**

### **Workflow File:**
- **Location:** `.github/workflows/bosscat-gate-verify.yml`
- **Triggers:** Manual dispatch, push to relevant paths
- **Platform:** Windows latest
- **Artifacts:** Screenshots, logs, reports

### **Required Secrets:**
1. **SIGNOZ_API_KEY** (Recommended)
   - Create in SigNoz UI: Settings → API Keys → New Key
   - Add to GitHub: Settings → Secrets → Actions → New repository secret

2. **SIGNOZ_SESSION_COOKIE** (Alternative)
   - Copy from browser DevTools → Application → Cookies → signoz-session
   - Add to GitHub: Settings → Secrets → Actions → New repository secret

### **Environment Variables:**
```yaml
env:
  SIGNOZ_URL: http://localhost:8080
  SERVICE_NAME: synthetic-windows-check
  SIGNOZ_API_KEY: ${{ secrets.SIGNOZ_API_KEY }}
```

---

## 🤖 **BossCat Lane Automation**

### **TypeScript Agent Script:**
- **File:** `scripts/agent/verifyIngestion.ts`
- **Purpose:** Automated ingestion verification for agent queue
- **Usage:** `npx tsx scripts/agent/verifyIngestion.ts`

### **Integration Points:**
- Agent queue system
- ECRR ledger updates
- Budget enforcement
- Evidence collection

---

## 📋 **Workflow Steps**

### **1. Environment Setup**
- Node.js 22 + PNPM 9
- Python 3.11
- Playwright with dependencies

### **2. Dependency Installation**
- Python: OpenTelemetry SDK, exporters, instrumentation
- Node.js: Playwright browsers and dependencies

### **3. Verification Pipeline**
1. **Fire Synthetic Trace:** Python script generates OTLP traces
2. **Verify Ingestion:** PowerShell script checks SigNoz UI
3. **Capture Screenshots:** Playwright captures evidence
4. **Upload Artifacts:** Evidence bundle for audit trail

### **4. Artifact Collection**
- `artifacts/signoz-services-synthetic.png`
- `artifacts/signoz-service-detail.png`
- `artifacts/signoz-traces.png`
- `artifacts/signoz-logs.png`
- Success reports and logs

---

## 🎯 **CI-Friendly Features**

### **Robust Error Handling**
- Graceful fallbacks for missing services
- Timeout management (90s polling, 120s total)
- Warning vs. error differentiation

### **Environment Flexibility**
- Local SigNoz (localhost:8080)
- Remote SigNoz (configurable URL)
- API key or session cookie authentication
- Headless operation support

### **Evidence Collection**
- Full-page screenshots
- Structured logging
- ECRR-compliant reports
- Audit trail preservation

---

## 📝 **Setup Instructions**

### **1. Create API Key**
1. Open SigNoz UI: http://localhost:8080
2. Settings → **API Keys** → **New Key**
3. Copy the generated key
4. GitHub → Settings → **Secrets** → **Actions** → **New repository secret**
5. Name: `SIGNOZ_API_KEY`, Value: `<your_api_key>`

### **2. Deploy Workflow**
1. Copy `scripts/github-workflows/bosscat-gate-verify.yml` to `.github/workflows/`
2. Commit and push to trigger workflow
3. Monitor Actions tab for execution

### **3. Verify Integration**
1. Manual trigger: Actions → BossCat Gate Verify → Run workflow
2. Check artifacts: Actions → Run → Artifacts → bosscat-gate-evidence
3. Validate screenshots and reports

---

## 🚪 **Gate Signal Integration**

### **PR Comments:**
```markdown
CI is green and all checks are satisfied.
**@cat ready-for-gate** 🚪✅
```

### **Workflow Status:**
- ✅ **Green:** All verification steps passed
- ⚠️ **Yellow:** Warnings but gate-ready
- ❌ **Red:** Critical failures, gate blocked

### **Evidence Requirements:**
- Synthetic traces generated
- SigNoz service visible
- Screenshots captured
- ECRR reports complete

---

## 🔄 **Roll-Forward/Roll-Back**

### **Roll-Forward (Success):**
1. Workflow completes successfully
2. Artifacts uploaded
3. Gate signal triggered
4. PR ready for merge

### **Roll-Back (Failure):**
1. Workflow fails or times out
2. Evidence collected for debugging
3. Issues identified and documented
4. Remediation steps provided

---

**CI Integration Complete:** 2025-01-03 23:30:00 UTC  
**Actor:** BossCat OEM (Executive Overseer Manager)  
**Status:** Ready for production CI/CD integration
