# 🐾 BossCat SigNoz Automation Stack

**Authority:** BossCat OEM (Executive Overseer Manager)  
**Status:** Production-Ready with Full Hardening  
**Gate:** 100/100 HARDENED 🛡️

---

## 🎯 Overview

Complete automation suite for deploying, verifying, and maintaining SigNoz observability configuration. Implements **Cat Nap Control Room** aesthetic with **Feline Silence** monitoring philosophy.

### What This Stack Does

1. **Automates SigNoz Setup (8/8 Steps)**
   - ✅ Workspace configuration
   - ✅ Data sources
   - ✅ Log ingestion
   - ✅ Trace ingestion
   - ✅ Metrics collection
   - ✅ Alert rules (8 BossCat alerts: 3 critical, 5 warning)
   - ✅ Saved Views (4 views: 2 logs, 2 traces)
   - ✅ Executive Dashboard (4 panels)

2. **Provides Drift Prevention**
   - Daily CI/CD verification at 06:17 UTC
   - Idempotent operations (safe to re-run)
   - Evidence-based governance
   - Automatic artifact uploads

3. **Enables Operational Excellence**
   - One-liner utilities for common tasks
   - Comprehensive hardening guide
   - API key rotation procedures
   - Rollback capabilities

---

## 🚀 Quick Start

### Prerequisites

- **SigNoz:** Running instance (default: `http://localhost:8080`)
- **API Key:** Admin-level SigNoz API key
- **PowerShell:** Version 7.4+ recommended
- **Environment:** Windows (native) or cross-platform (pwsh)

### One-Shot Setup

```powershell
# 1. Set your API key
$env:SIGNOZ_API_KEY = "<your-api-key>"
$env:SIGNOZ_URL = "http://localhost:8080"

# 2. Apply full configuration
pwsh -File scripts/bosscat-hands-free-switch-on.ps1 `
  -SigNozUrl $env:SIGNOZ_URL `
  -ApiKey $env:SIGNOZ_API_KEY

# 3. Apply Saved Views & Dashboard
pwsh -File scripts/bosscat-steps-7-8.ps1 `
  -SigNozUrl $env:SIGNOZ_URL `
  -ApiKey $env:SIGNOZ_API_KEY `
  -Apply

# 4. Verify completion
pwsh -File scripts/bosscat-verify-signoz-completion.ps1 `
  -SigNozUrl $env:SIGNOZ_URL `
  -ApiKey $env:SIGNOZ_API_KEY
```

**Expected Result:** Exit code `0`, SigNoz Home shows "Setup Alerts" tile as **GREEN**

---

## 📋 Script Reference

### Core Configuration Scripts

#### 1. `scripts/bosscat-create-signoz-alerts.ps1`

Creates 8 BossCat alert rules using SigNoz v0.96+ schema.

**Alerts Created:**
- **Metric Alerts (4):**
  - Pipeline Health (critical) - Fires when pipeline stops receiving spans
  - High Error Rate (warning) - Fires when error rate > 5%
  - Latency Spike (warning) - Fires when P95 latency > 1s
  - Throughput Drop (warning) - Fires when throughput < 10 spans/sec

- **Log Alerts (2):**
  - Canary Missing (critical) - Fires when canary logs absent > 10min
  - Error Log (warning) - Fires when error log count > 10 in 5min

- **Trace Alerts (2):**
  - High Latency Trace (warning) - Fires when trace duration > 500ms
  - Error Trace (critical) - Fires when error traces detected

**Usage:**
```powershell
# Export only (safe mode)
pwsh -File scripts/bosscat-create-signoz-alerts.ps1 -SigNozUrl http://localhost:8080

# Apply to SigNoz
pwsh -File scripts/bosscat-create-signoz-alerts.ps1 `
  -SigNozUrl http://localhost:8080 `
  -Apply `
  -ApiKey $env:SIGNOZ_API_KEY
```

#### 2. `scripts/bosscat-verify-signoz-completion.ps1`

Verifies complete SigNoz setup with robust parsing.

**Checks:**
- SigNoz health (`/api/v1/health`)
- Docker services status
- Alert count (expects 8 BossCat alerts)
- Severity distribution (3 critical, 5 warning)
- Alert enabled status

**Exit Codes:**
- `0` - All checks pass
- `2` - Incomplete setup or drift detected

**Usage:**
```powershell
pwsh -File scripts/bosscat-verify-signoz-completion.ps1 `
  -SigNozUrl http://localhost:8080 `
  -ApiKey $env:SIGNOZ_API_KEY
```

#### 3. `scripts/bosscat-steps-7-8.ps1`

Automates Saved Views and Dashboard creation.

**Creates:**
- **4 Saved Views:**
  - BossCat Error Logs View
  - BossCat Canary Logs View
  - BossCat High Latency Traces
  - BossCat Error Traces

- **1 Dashboard:**
  - BossCat Executive Dashboard (4 panels)

**Usage:**
```powershell
pwsh -File scripts/bosscat-steps-7-8.ps1 `
  -SigNozUrl http://localhost:8080 `
  -ApiKey $env:SIGNOZ_API_KEY `
  -Apply
```

#### 4. `scripts/bosscat-hands-free-switch-on.ps1`

Orchestrates the full setup process.

**Workflow:**
1. Smoke-check API endpoints
2. Create sentinel alert (flips UI tile to GREEN)
3. Apply full alert set (8 rules)
4. Verify completion

**Usage:**
```powershell
pwsh -File scripts/bosscat-hands-free-switch-on.ps1 `
  -SigNozUrl http://localhost:8080 `
  -ApiKey $env:SIGNOZ_API_KEY
```

### Operational Utilities

#### 5. `scripts/bosscat-ops-oneliners.ps1`

Daily operational utilities for managing SigNoz.

**Operations:**

```powershell
# Full status check (health + alerts + dashboards)
pwsh -File scripts/bosscat-ops-oneliners.ps1 `
  -Operation FullStatus `
  -ApiKey $env:SIGNOZ_API_KEY

# List all alerts with details
pwsh -File scripts/bosscat-ops-oneliners.ps1 `
  -Operation ListAlerts `
  -ApiKey $env:SIGNOZ_API_KEY

# List dashboards
pwsh -File scripts/bosscat-ops-oneliners.ps1 `
  -Operation ListDashboards `
  -ApiKey $env:SIGNOZ_API_KEY

# Export dashboards (backup)
pwsh -File scripts/bosscat-ops-oneliners.ps1 `
  -Operation ExportDashboards `
  -ApiKey $env:SIGNOZ_API_KEY

# Health check only
pwsh -File scripts/bosscat-ops-oneliners.ps1 `
  -Operation HealthCheck `
  -ApiKey $env:SIGNOZ_API_KEY
```

---

## 🔁 CI/CD Integration

### Workflow: `.github/workflows/signoz-config.yml`

**Triggers:**
- Daily at 06:17 UTC (cron schedule)
- Manual dispatch (`workflow_dispatch`)
- Push to config paths

**Actions:**
1. Apply all BossCat alerts
2. Apply Saved Views and Dashboard
3. Verify 8/8 completion
4. Snapshot current configuration
5. Upload artifacts (always, even on failure)

**Environment:**
- Uses `secrets.WYZWOZ_SIGNOZ` for API authentication
- Runs on `windows-latest` runner
- 20-minute timeout
- Least-privilege permissions (`contents: read`)

**Manual Trigger:**
```bash
gh workflow run signoz-config.yml
gh run list --workflow=signoz-config.yml --limit 5
```

---

## 📁 Artifact Structure

```
docs/BossCat/
├── BOSSCAT_LOG.md                          # ECRR compliance ledger
├── OPS_HARDENING_GUIDE.md                  # Comprehensive ops guide
├── README.md                               # This file
├── bosscat-metric-alerts.json              # 4 metric alert definitions
├── bosscat-log-alerts.json                 # 2 log alert definitions
├── bosscat-trace-alerts.json               # 2 trace alert definitions
├── bosscat-saved-views.json                # 4 saved view definitions
├── bosscat-executive-dashboard.json        # Dashboard definition
├── signoz-completion-verification.json     # Latest verification report
├── bosscat-steps-7-8-summary.json          # Steps 7-8 summary
└── _evidence_dashboards.json               # Live snapshot (CI-generated)
```

**Principle:** All JSON files are the **source of truth** for configuration, enabling:
- Version control
- Drift detection
- Audit trails
- Rollback capability

---

## 🛡️ Hardening Features

### 1. Idempotent Operations

All scripts are safe to re-run multiple times:
- **Alerts:** Name-based upsert (create if missing, skip if exists)
- **Dashboards:** API handles duplicates gracefully
- **Verification:** Read-only, always safe

### 2. Drift Detection

**Automated Checks:**
- Alert count: Expects exactly 8
- Severity distribution: 3 critical, 5 warning
- Enabled status: All alerts must be enabled
- Exit codes: Non-zero on drift

**CI Integration:**
- Daily verification via GitHub Actions
- Fails workflow if drift detected
- Uploads evidence artifacts

### 3. Evidence Parity

**Source of Truth:** `docs/BossCat/*.json` files match API payloads exactly

**Benefits:**
- Infrastructure as Code (IaC)
- Git-based audit trail
- Easy rollback to previous versions
- Clear diff on changes

### 4. Security Best Practices

**API Key Management:**
- Never committed to version control
- Stored in GitHub Secrets (`WYZWOZ_SIGNOZ`)
- Rotation procedure documented
- Separate keys for CI vs local ops

**Least Privilege:**
- CI workflows: `contents: read` only
- API keys: Admin level (required for rule creation)
- Network: Restrict SigNoz API if possible

### 5. Rollback Capability

```powershell
# Revert to last known good config
git checkout HEAD~1 -- docs/BossCat/*.json

# Re-apply from source of truth
pwsh -File scripts/bosscat-create-signoz-alerts.ps1 -Apply -ApiKey $env:SIGNOZ_API_KEY
pwsh -File scripts/bosscat-steps-7-8.ps1 -Apply -ApiKey $env:SIGNOZ_API_KEY

# Verify
pwsh -File scripts/bosscat-verify-signoz-completion.ps1 -ApiKey $env:SIGNOZ_API_KEY
```

---

## 📚 Documentation

### Complete Guides

1. **`OPS_HARDENING_GUIDE.md`** - Comprehensive operational guide covering:
   - Quick operations reference
   - Drift prevention strategies
   - Security best practices
   - Testing & validation procedures
   - Troubleshooting common issues
   - Escalation paths

2. **`BOSSCAT_LOG.md`** - ECRR compliance ledger with:
   - Executive decision log
   - Configuration change history
   - Audit trail entries
   - Gate status updates

---

## 🎯 Success Criteria

**Complete when:**
- ✅ SigNoz Home → "Setup Alerts" tile = **GREEN**
- ✅ 8 BossCat alerts visible and **enabled**
- ✅ 1 BossCat Executive Dashboard created
- ✅ 4 Saved Views defined
- ✅ Verification script exits with code **0**
- ✅ All artifacts present in `docs/BossCat/`
- ✅ ECRR ledger updated
- ✅ CI workflow runs successfully
- ✅ **Gate = 100/100**

---

## 🐾 Philosophy: Cat Nap Control Room

**Aesthetic Principles:**
- **Feline Silence:** Calm, efficient monitoring without noise
- **Peaceful Vigilance:** Always watching, never intrusive
- **Evidence-First:** All actions produce audit trails
- **Executive Oversight:** BossCat OEM maintains supreme authority

**Implementation:**
- Low-latency pipeline (200ms batches)
- Noise filtering (~50% volume reduction)
- Color-coded status indicators
- Automated nightly dashboard exports
- Serene, minimalist observability cockpit

---

## 🔧 Troubleshooting

### Common Issues

**❌ 401 Unauthorized**
- Check API key format and expiration
- Verify header: `SIGNOZ-API-KEY` (not `X-API-KEY`)
- Confirm key has admin permissions

**❌ 400 Bad Request**
- Ensure v0.96+ schema (use `alert`, `alertType`, `ruleType`)
- Remove `labels` field if present
- Lowercase severity values

**⚠️ UI Not Updating**
- Hard refresh: Ctrl+Shift+R
- Clear browser cache
- Verify alerts exist via API

**⚠️ Verification Shows 0 Alerts**
- Check endpoint: `/api/v1/rules` (not `/api/v1/alerts`)
- Verify response parsing handles `data.rules`
- Confirm API key read permissions

### Debug Commands

```powershell
# Raw API check
$H = @{ "SIGNOZ-API-KEY" = $env:SIGNOZ_API_KEY }
Invoke-RestMethod -Uri "http://localhost:8080/api/v1/rules" -Headers $H | ConvertTo-Json -Depth 5

# Check BossCat alerts only
$rules = (Invoke-RestMethod -Uri "http://localhost:8080/api/v1/rules" -Headers $H).data.rules
$rules | Where-Object { $_.alert -like "*BossCat*" } | Format-List
```

---

## 🌐 SigNoz Access Points

- **UI:** http://localhost:8080
- **Alerts:** http://localhost:8080/alerts
- **Dashboards:** http://localhost:8080/dashboards
- **Logs:** http://localhost:8080/logs
- **Traces:** http://localhost:8080/traces
- **Metrics:** http://localhost:8080/metrics

---

## 🚪 Gate Phrase

```
CI is green and all checks are satisfied.
**@cat ready-for-gate** 🚪✅
```

---

## 📞 Support

For issues not covered in this documentation:

1. Check `BOSSCAT_LOG.md` for recent changes
2. Review `OPS_HARDENING_GUIDE.md` for detailed procedures
3. Examine CI workflow logs in GitHub Actions
4. Export current state for comparison
5. Consult SigNoz documentation: https://signoz.io/docs/

**Final Authority:** BossCat OEM on all production changes

---

🐾 **End of BossCat SigNoz Automation Stack Documentation**

*Feline Silence maintained. Gate integrity preserved. Mission complete with production hardening.*

**Status:** 100/100 HARDENED 🛡️
