# 🐾 BossCat CI/CD Execution Guide - Path 2

**Authority:** BossCat OEM (Executive Overseer Manager)  
**Timestamp:** 2025-10-08T06:45:00Z  
**Status:** 🚀 **PATH 2 (CI/CD) - STEP-BY-STEP GUIDE**

---

## 🎯 **Path 2: CI/CD Execution - GitHub Actions**

This guide covers **Path 2: CI/CD Execution** using GitHub Actions workflows for automated alert deployment.

---

## ⚠️ **CRITICAL: Network Configuration Required**

**Before you execute Path 2, understand this critical limitation:**

### **GitHub-Hosted Runners Cannot Reach `localhost:8080`**

If you trigger the workflow with GitHub-hosted runners:
- ✅ Workflow will run successfully (exit 0)
- ✅ Logs will show "alerts created"
- ❌ **Alerts won't actually be created** (network unreachable)
- ❌ **Tile stays BLUE** (Setup Alerts never turns GREEN)

### **Required Network Configuration:**

You must use **ONE** of these solutions:

#### **Solution A: Self-Hosted Runner (Recommended)**
- Install GitHub Actions runner on a machine in the same network as SigNoz
- Update workflow to use: `runs-on: self-hosted`

#### **Solution B: Publicly Accessible SigNoz**
- Expose SigNoz via reverse proxy or cloud load balancer
- Update workflow to use: `SIGNOZ_URL: https://signoz.yourdomain.com`
- Configure firewall allow-list for GitHub Actions IPs

#### **Solution C: Skip CI/CD (Use Path 1)**
- Use local execution instead (Path 1)
- Fastest for localhost SigNoz

---

## 📋 **Step-by-Step Execution (Assuming Self-Hosted Runner)**

### **Step 1: Set Up Self-Hosted Runner**

#### **1.1: Download and Configure Runner**

1. Go to: `https://github.com/YOUR-ORG/YOUR-REPO/settings/actions/runners/new`

2. Follow the instructions to download and configure the runner on a machine that can reach SigNoz:

```bash
# On Windows (PowerShell)
# Download runner
Invoke-WebRequest -Uri https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-win-x64-2.311.0.zip -OutFile actions-runner-win-x64-2.311.0.zip

# Extract
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory("$PWD/actions-runner-win-x64-2.311.0.zip", "$PWD/actions-runner")

# Configure
cd actions-runner
./config.cmd --url https://github.com/YOUR-ORG/YOUR-REPO --token YOUR-RUNNER-TOKEN

# Run as service
./run.cmd
```

#### **1.2: Verify Runner is Online**

1. Go to: `https://github.com/YOUR-ORG/YOUR-REPO/settings/actions/runners`
2. Verify: Runner shows **"Idle"** status (green dot)

---

### **Step 2: Update Workflow for Self-Hosted Runner**

The workflow file `.github/workflows/signoz-alerts.yml` needs to be updated:

```yaml
# .github/workflows/signoz-alerts.yml
name: BossCat • SigNoz Alerts

on:
  workflow_dispatch:
  push:
    paths:
      - scripts/bosscat-create-signoz-alerts.ps1
      - scripts/bosscat-verify-signoz-completion.ps1
      - docs/BossCat/**

permissions:
  contents: read

concurrency:
  group: signoz-alerts-${{ github.ref }}
  cancel-in-progress: false

jobs:
  alerts:
    runs-on: self-hosted  # ← CHANGED from windows-latest
    timeout-minutes: 20
    env:
      SIGNOZ_URL: http://localhost:8080  # ← Works with self-hosted runner
      SIGNOZ_API_KEY: ${{ secrets.WYZWOZ_SIGNOZ }}

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup PowerShell (pwsh 7.4)
        uses: PowerShell/PowerShell@v1
        with:
          pwsh-version: '7.4.x'

      - name: Apply BossCat Alerts to SigNoz
        shell: pwsh
        run: |
          pwsh -File scripts/bosscat-create-signoz-alerts.ps1 `
            -SigNozUrl $env:SIGNOZ_URL `
            -Apply `
            -ApiKey $env:SIGNOZ_API_KEY

      - name: Verify SigNoz Completion (6/6)
        shell: pwsh
        run: |
          pwsh -File scripts/bosscat-verify-signoz-completion.ps1 `
            -SigNozUrl $env:SIGNOZ_URL `
            -ApiKey $env:SIGNOZ_API_KEY

      - name: Upload verification report (always)
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: signoz-completion-report
          path: docs/BossCat/signoz-completion-verification.json
          if-no-files-found: warn
          retention-days: 14
```

---

### **Step 3: Trigger the Workflow**

#### **Option A: Via GitHub Web UI**
1. Go to: `https://github.com/YOUR-ORG/YOUR-REPO/actions`
2. Select: **"BossCat • SigNoz Alerts"** workflow
3. Click: **"Run workflow"** dropdown
4. Select: Branch (e.g., `main`)
5. Click: **"Run workflow"** button

#### **Option B: Via GitHub CLI**
```bash
# Trigger the workflow
gh workflow run "BossCat • SigNoz Alerts" -r main

# Watch the workflow run
gh run watch --exit-status
```

---

### **Step 4: Monitor Workflow Execution**

#### **Via GitHub Web UI:**
1. Go to: `https://github.com/YOUR-ORG/YOUR-REPO/actions`
2. Click: Latest workflow run
3. Expand: Job steps to see detailed logs

#### **Via GitHub CLI:**
```bash
# Watch latest run (blocks until complete)
gh run watch --exit-status

# Or view logs after completion
gh run view --log
```

**Key log lines to watch:**
- ✅ `Applied: …` (alert creation)
- ✅ `BossCat alerts: FOUND 8 (critical=3, warning=5)` (verification)
- ✅ `Exit code 0` (success)

---

### **Step 5: Download Artifacts**

After workflow completes, download the verification report:

```bash
# List artifacts
gh run list --workflow "BossCat • SigNoz Alerts" --limit 1

# Download latest artifact
gh run download --name signoz-completion-report
```

Or via Web UI:
1. Go to workflow run page
2. Scroll to **Artifacts** section
3. Download: **signoz-completion-report**

---

### **Step 6: Verify Success**

#### **SigNoz UI Verification:**
1. Open: `http://localhost:8080`
2. Navigate to: **Home** page
3. Verify: **"Setup Alerts"** tile shows **GREEN**
4. Navigate to: **Alerts** page
5. Verify: **8 BossCat alerts** visible
6. Verify: All alerts show **enabled** (`disabled = false`)

---

## 🧯 **Troubleshooting CI/CD Path**

### **Issue 1: Runner Cannot Reach SigNoz**
**Error in logs:**
```
Cannot reach SigNoz at http://localhost:8080
```

**Fix:**
- Verify runner is on same network as SigNoz
- Test connectivity: `curl http://localhost:8080/api/v1/health` from runner machine
- Or use publicly accessible SigNoz URL

---

### **Issue 2: Workflow Uses GitHub-Hosted Runner**
**Symptom:** Workflow succeeds but alerts not created

**Fix:**
- Update workflow: `runs-on: self-hosted`
- Commit and push the change
- Re-run workflow

---

### **Issue 3: Runner Offline**
**Error:**
```
No runner matching the specified labels was found
```

**Fix:**
```bash
# On runner machine, check status
cd actions-runner
./run.cmd  # Start runner if stopped
```

---

### **Issue 4: Secret Not Available**
**Error:**
```
API key not set
```

**Fix:**
- Verify `WYZWOZ_SIGNOZ` secret exists
- Check secret is available to workflow (Settings → Secrets → Actions)

---

## ✅ **Expected Outcomes**

### **Workflow Logs:**
```
✅ Apply BossCat Alerts to SigNoz
   Applied: 8 (ok) / 0 (failed)

✅ Verify SigNoz Completion (6/6)
   BossCat alerts: FOUND 8 (critical=3, warning=5)
   Exit code: 0

✅ Upload verification report (always)
   Artifact uploaded: signoz-completion-report
```

### **Artifacts:**
- ✅ `signoz-completion-report.zip`
  - Contains: `signoz-completion-verification.json`

### **SigNoz UI:**
- ✅ "Setup Alerts" tile: **GREEN**
- ✅ Alerts page: **8 BossCat alerts**
- ✅ All alerts: **enabled**

---

## 🎯 **Advantages of Path 2 (CI/CD)**

### **✅ Benefits:**
1. **Automated Execution**
   - No manual API key management
   - Repeatable and consistent

2. **Audit Trail**
   - Complete workflow logs
   - Artifact storage (14 days retention)
   - Git commit history

3. **CI/CD Integration**
   - Triggers on code changes
   - Part of deployment pipeline
   - Automated testing

4. **Team Collaboration**
   - Shared execution environment
   - No local setup required
   - Centralized secret management

### **⚠️ Considerations:**
1. **Network Configuration**
   - Requires self-hosted runner OR
   - Publicly accessible SigNoz

2. **Setup Overhead**
   - Runner installation required
   - Workflow configuration needed

3. **Execution Delay**
   - Queue time (if busy)
   - Job startup overhead (~30-60 seconds)

---

## 📋 **Post-Execution Checklist**

After successful CI/CD execution:

- [ ] Workflow shows **green checkmark**
- [ ] Workflow logs show: `Found 8 (critical=3, warning=5)` + exit 0
- [ ] Artifact downloaded: `signoz-completion-report.zip`
- [ ] SigNoz Home → "Setup Alerts" tile is **GREEN**
- [ ] SigNoz Alerts page shows **8 BossCat alerts**
- [ ] All alerts show `disabled = false`

---

## 🧾 **ECRR Ledger Entry (Add After Success)**

Once CI/CD execution completes successfully, add this entry to `docs/BossCat/BOSSCAT_LOG.md`:

```
2025-10-08: Hands-free switch-on executed via CI/CD with WYZWOZ_SIGNOZ; Setup Alerts BLUE→GREEN; 8 rules present (3 critical/5 warning); verification artifact uploaded; workflow run ID: XXXXX.
```

---

## 🐾 **BossCat Executive Summary**

### **Path 2 (CI/CD) Characteristics:**
- ✅ **Automated:** No manual execution needed
- ✅ **Repeatable:** Consistent results
- ✅ **Auditable:** Complete workflow logs + artifacts
- ⚠️ **Network:** Requires self-hosted runner or public SigNoz
- ⚠️ **Setup:** Runner installation required

### **Prerequisites:**
- ✅ Self-hosted runner installed and running
- ✅ Runner can reach SigNoz
- ✅ `WYZWOZ_SIGNOZ` secret configured
- ✅ Workflow updated to use `self-hosted` runner

### **Expected Timeline:**
- **Setup (first time):** 15-30 minutes (runner installation)
- **Execution:** 2-3 minutes (workflow run)
- **Verification:** 1 minute
- **Total (first time):** ~20-35 minutes
- **Total (subsequent):** ~3-5 minutes

### **Authority:**
**BossCat OEM (Executive Overseer Manager)**
- Path 2 (CI/CD) documented
- Self-hosted runner guide provided
- Feline Silence maintained
- Gate integrity preserved

---

> **🎯 Path 2 requires self-hosted runner for localhost SigNoz.**  
> **✅ Follow the setup guide for automated CI/CD execution.**  
> **🐾 Authority: BossCat OEM - CI/CD path documented.**

**Path 2 is ready for execution once you complete the self-hosted runner setup.** 🐾

---

**🐾 End of CI/CD Execution Guide - Path 2** 🐾

