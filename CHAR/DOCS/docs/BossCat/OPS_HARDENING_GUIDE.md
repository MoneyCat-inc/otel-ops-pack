# 🐾 BossCat SigNoz Operations Hardening Guide

**Authority:** BossCat OEM (Executive Overseer Manager)  
**Purpose:** Operational excellence and drift prevention for SigNoz configuration  
**WyzWoz Style:** Cat Nap Control Room - Feline Silence Monitoring

---

## 🎯 Quick Operations Reference

### Essential One-Liners

All operations require the SigNoz API key. Set it once:

```powershell
$env:SIGNOZ_API_KEY = $env:WYZWOZ_SIGNOZ  # from repo secret or local env
$env:SIGNOZ_URL = "http://localhost:8080"
```

#### 1. Full Status Check

```powershell
pwsh -File scripts/bosscat-ops-oneliners.ps1 `
  -Operation FullStatus `
  -SigNozUrl $env:SIGNOZ_URL `
  -ApiKey $env:SIGNOZ_API_KEY
```

**Shows:** Health, Alert counts (total/critical/warning/enabled), Dashboard counts

#### 2. List All Alerts

```powershell
pwsh -File scripts/bosscat-ops-oneliners.ps1 `
  -Operation ListAlerts `
  -SigNozUrl $env:SIGNOZ_URL `
  -ApiKey $env:SIGNOZ_API_KEY
```

**Shows:** Table of all alerts with Name, Severity, Type, Disabled status

#### 3. List Dashboards

```powershell
pwsh -File scripts/bosscat-ops-oneliners.ps1 `
  -Operation ListDashboards `
  -SigNozUrl $env:SIGNOZ_URL `
  -ApiKey $env:SIGNOZ_API_KEY
```

**Shows:** Dashboard IDs, Titles, Panel counts

#### 4. Export Dashboards (Backup)

```powershell
pwsh -File scripts/bosscat-ops-oneliners.ps1 `
  -Operation ExportDashboards `
  -SigNozUrl $env:SIGNOZ_URL `
  -ApiKey $env:SIGNOZ_API_KEY
```

**Saves to:** `docs/BossCat/bosscat-executive-dashboard.live.json`

#### 5. Health Check Only

```powershell
pwsh -File scripts/bosscat-ops-oneliners.ps1 `
  -Operation HealthCheck `
  -SigNozUrl $env:SIGNOZ_URL `
  -ApiKey $env:SIGNOZ_API_KEY
```

**Shows:** SigNoz health status and version

---

## 🔁 Drift Prevention & CI/CD

### Daily Drift Guard Workflow

The `signoz-config.yml` workflow runs daily at 06:17 UTC and:

1. **Applies** all BossCat alerts (8 rules with v0.96+ schema)
2. **Applies** Saved Views and Dashboards
3. **Verifies** alert counts and health
4. **Snapshots** current configuration as evidence
5. **Uploads** artifacts for audit trail

**Trigger manually:**

```bash
gh workflow run signoz-config.yml
```

**View results:**

```bash
gh run list --workflow=signoz-config.yml --limit 5
gh run view <run-id>
```

### Workflow Files

- **`.github/workflows/signoz-config.yml`** - Daily drift guard + config apply
- **`.github/workflows/signoz-alerts.yml`** - Alert-only workflow (deprecated, merged into config)

---

## 🛡️ Operations Hardening Checklist

### 1. Idempotent Operations

**Current State:**
- ✅ Alerts: Name-based upsert (create if missing, skip if exists)
- ✅ Dashboards: API handles duplicates gracefully
- ⚠️ Saved Views: API endpoint under investigation

**Improvement Opportunity:**
- Add explicit ID-based updates for dashboards
- Implement saved views name-based upsert when API is confirmed

### 2. Drift Detection

**Current Implementation:**

```powershell
# Verify 8 BossCat alerts (3 critical, 5 warning)
pwsh -File scripts/bosscat-verify-signoz-completion.ps1 `
  -SigNozUrl $env:SIGNOZ_URL `
  -ApiKey $env:SIGNOZ_API_KEY
```

**Exit Codes:**
- `0` - All checks pass (8 alerts found, correct severity distribution)
- `2` - Drift detected (missing alerts or wrong counts)

**CI Integration:** Workflow fails if verification returns non-zero

### 3. Time-Range Smoke Test

**Dashboard Panel Validation:**

```powershell
# Quick query to ensure panels have data
$query = "rate(otelcol_*_spans_received_total[5m])"
$body = @{
  query = $query
  start = (Get-Date).AddMinutes(-5).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
  end = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
  step = "30s"
} | ConvertTo-Json

try {
  $result = Invoke-RestMethod -Method POST `
    -Uri "$env:SIGNOZ_URL/api/v1/query_range" `
    -Headers @{ "SIGNOZ-API-KEY" = $env:SIGNOZ_API_KEY } `
    -Body $body `
    -ContentType "application/json"
  
  if ($result.data.result.Count -gt 0) {
    Write-Host "✅ Pipeline data flowing (last 5m)" -ForegroundColor Green
  } else {
    Write-Host "⚠️ No data in last 5m window" -ForegroundColor Yellow
  }
} catch {
  Write-Host "❌ Query failed: $($_.Exception.Message)" -ForegroundColor Red
}
```

### 4. Evidence Parity

**Source of Truth:** `docs/BossCat/*.json` files

**Principle:** The JSON files committed to the repo should be:
- The **exact schema** used for POST operations
- The **same structure** returned by GET operations
- **Version-controlled** for audit and rollback

**Verification:**

```powershell
# Compare live config to source of truth
$live = Invoke-RestMethod -Uri "$env:SIGNOZ_URL/api/v1/rules" `
  -Headers @{ "SIGNOZ-API-KEY" = $env:SIGNOZ_API_KEY }

$source = Get-Content "docs/BossCat/bosscat-metric-alerts.json" | ConvertFrom-Json

# Check count match
if ($live.data.rules.Count -ne ($source.Count * 3)) {  # We have 3 alert types
  Write-Host "⚠️ Drift detected: live count doesn't match source" -ForegroundColor Yellow
}
```

---

## 🔐 Security Best Practices

### API Key Management

1. **Never commit keys** to version control
2. **Rotate regularly** (every 90 days minimum)
3. **Use repo secrets** for CI/CD (`WYZWOZ_SIGNOZ`)
4. **Set as env var locally** (`$env:WYZWOZ_SIGNOZ`)

### Rotation Procedure

```powershell
# 1. Generate new key in SigNoz UI
#    Settings → API Keys → Create New Key

# 2. Update GitHub secret
gh secret set WYZWOZ_SIGNOZ --body "new-key-value"

# 3. Update local environment
$env:WYZWOZ_SIGNOZ = "new-key-value"

# 4. Test with health check
pwsh -File scripts/bosscat-ops-oneliners.ps1 `
  -Operation HealthCheck `
  -ApiKey $env:WYZWOZ_SIGNOZ

# 5. Revoke old key in SigNoz UI
```

### Least Privilege

- **CI/CD workflows:** `contents: read` only
- **API Keys:** Create dedicated keys per use case (CI vs local ops)
- **Network:** Restrict SigNoz API access to known IPs if possible

---

## 📊 Monitoring the Monitor

### Alert on Alert Failures

**Concept:** Create a meta-alert that fires if the BossCat alert set is incomplete.

```powershell
# This could be a separate alert that queries the SigNoz rules API
# and verifies the count is 8 with correct severity distribution
# Implementation depends on SigNoz's ability to self-monitor via API
```

### Dashboard Health Metrics

Add a panel to the BossCat Executive Dashboard that shows:

- Number of active alerts
- Last alert evaluation time
- Alert evaluation failure rate

---

## 🧪 Testing & Validation

### Pre-Production Checklist

Before deploying config changes:

1. **Export current state** (backup)

   ```powershell
   pwsh -File scripts/bosscat-ops-oneliners.ps1 -Operation ExportDashboards -ApiKey $env:WYZWOZ_SIGNOZ
   ```

2. **Apply changes** in dev/staging first

3. **Verify** with full status check

4. **Test alert firing** with synthetic data

   ```powershell
   pwsh -File scripts/canary-test.ps1
   ```

5. **Confirm UI updates** (refresh SigNoz Home page)

### Rollback Procedure

If drift or errors occur:

```powershell
# 1. Revert to last known good config
git checkout HEAD~1 -- docs/BossCat/*.json

# 2. Re-apply from source of truth
pwsh -File scripts/bosscat-create-signoz-alerts.ps1 -Apply -ApiKey $env:WYZWOZ_SIGNOZ
pwsh -File scripts/bosscat-steps-7-8.ps1 -Apply -ApiKey $env:WYZWOZ_SIGNOZ

# 3. Verify
pwsh -File scripts/bosscat-verify-signoz-completion.ps1 -ApiKey $env:WYZWOZ_SIGNOZ
```

---

## 📁 Artifact Structure

```
docs/BossCat/
├── BOSSCAT_LOG.md                          # ECRR compliance ledger
├── OPS_HARDENING_GUIDE.md                  # This file
├── bosscat-metric-alerts.json              # 4 metric alert definitions
├── bosscat-log-alerts.json                 # 2 log alert definitions
├── bosscat-trace-alerts.json               # 2 trace alert definitions
├── bosscat-saved-views.json                # 4 saved view definitions
├── bosscat-executive-dashboard.json        # Dashboard definition
├── signoz-completion-verification.json     # Latest verification report
├── bosscat-steps-7-8-summary.json          # Steps 7-8 automation summary
├── _evidence_dashboards.json               # Live snapshot (CI-generated)
└── bosscat-executive-dashboard.live.json   # Live export (manual backup)
```

---

## 🚀 Quick Start (New Environment)

```powershell
# 1. Set credentials
$env:SIGNOZ_URL = "http://localhost:8080"
$env:SIGNOZ_API_KEY = "<your-api-key>"

# 2. Apply full config (alerts + views + dashboards)
pwsh -File scripts/bosscat-create-signoz-alerts.ps1 -Apply -ApiKey $env:SIGNOZ_API_KEY
pwsh -File scripts/bosscat-steps-7-8.ps1 -Apply -ApiKey $env:SIGNOZ_API_KEY

# 3. Verify 8/8 complete
pwsh -File scripts/bosscat-verify-signoz-completion.ps1 -ApiKey $env:SIGNOZ_API_KEY

# 4. Check full status
pwsh -File scripts/bosscat-ops-oneliners.ps1 -Operation FullStatus -ApiKey $env:SIGNOZ_API_KEY

# 5. Confirm in UI: http://localhost:8080 → Setup Alerts should be GREEN
```

---

## 🎯 Success Criteria

**BossCat SigNoz Setup is Complete When:**

- ✅ Home → Setup Alerts tile = **GREEN**
- ✅ Alerts → **8 BossCat rules** visible (3 critical, 5 warning), all **enabled**
- ✅ Dashboards → **1 BossCat Executive Dashboard** with 4 panels
- ✅ Saved Views → **4 views defined** (2 logs + 2 traces)
- ✅ Verification script exits with **code 0**
- ✅ All artifacts present in `docs/BossCat/`
- ✅ ECRR ledger updated with completion entry
- ✅ CI workflow runs successfully
- ✅ **Gate = 100/100**

---

## 🐾 Support & Troubleshooting

### Common Issues

1. **401 Unauthorized**
   - Check API key is correct and not expired
   - Verify `SIGNOZ-API-KEY` header format
   - Confirm key has admin permissions

2. **400 Bad Request**
   - Verify payload schema matches SigNoz v0.96+ format
   - Remove `labels` field if present
   - Check severity values are lowercase

3. **UI Not Updating**
   - Hard refresh browser (Ctrl+Shift+R)
   - Check browser console for errors
   - Verify alerts are actually created via API

4. **Verification Shows 0 Alerts**
   - Check endpoint path (`/api/v1/rules` not `/api/v1/alerts`)
   - Verify response parsing logic handles `data.rules`
   - Confirm API key has read permissions

### Debug Commands

```powershell
# Raw API check
$H = @{ "SIGNOZ-API-KEY" = $env:SIGNOZ_API_KEY }
Invoke-RestMethod -Uri "$env:SIGNOZ_URL/api/v1/rules" -Headers $H | ConvertTo-Json -Depth 5

# Check specific alert
$rules = (Invoke-RestMethod -Uri "$env:SIGNOZ_URL/api/v1/rules" -Headers $H).data.rules
$rules | Where-Object { $_.alert -like "*BossCat*" } | Format-List

# Test alert creation (single)
$payload = @{ alert = "Test Alert"; alertType = "METRIC_BASED_ALERT"; severity = "warning"; disabled = $false }
Invoke-RestMethod -Method POST -Uri "$env:SIGNOZ_URL/api/v1/rules" -Headers $H -Body ($payload | ConvertTo-Json)
```

---

## 📞 Escalation

For issues not covered by this guide:

1. Check `docs/BossCat/BOSSCAT_LOG.md` for recent changes
2. Review CI workflow logs in GitHub Actions
3. Export current state for comparison
4. Consult SigNoz documentation: https://signoz.io/docs/
5. BossCat OEM final authority on production changes

---

🐾 **End of Operations Hardening Guide**

*Feline Silence maintained. Gate integrity preserved.*

