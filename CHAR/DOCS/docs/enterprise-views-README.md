# Enterprise View Provisioning System

**BossCat OEM · Production-Ready SigNoz View Management**

---

## 🎯 Overview

The Enterprise View Provisioning System provides **idempotent, ECRR-compliant provisioning** of production-grade Saved Views in SigNoz. It features automatic API discovery, dashboard fallback, comprehensive verification, and full audit trails.

**Status:** ✅ **BossCat Approved for Production**  
**Gate Approval:** [docs/ecrr/ECRR_REPORTS/GATE_APPROVAL_enterprise-views.md](ecrr/ECRR_REPORTS/GATE_APPROVAL_enterprise-views.md)

---

## 📦 Components

### 1. Main Provisioning Script
**`scripts/cursor-startup-signoz-enterprise-views.ps1`**

Provisions 6 enterprise views covering:
- **Logs:** Error Triage, Security Signals
- **Traces:** Hot Endpoints, Canary Spans
- **Metrics:** Collector Ingest Pulse, P95 Latency

**Key Features:**
- ✅ ECRR framework (Examine → Clean → Report → Role)
- ✅ Auto-discovery of SigNoz Saved Views API
- ✅ Fallback to Dashboard panels if API unavailable
- ✅ Idempotent upsert (safe to re-run)
- ✅ Built-in verification phase
- ✅ Comprehensive error handling
- ✅ Proof-to-disk artifacts (JSON + Markdown)

### 2. Verification Script
**`scripts/verify-enterprise-views.ps1`**

Standalone verification that all views are accessible.

**Exit Codes:**
- `0` = All views present
- `N` = N views missing

### 3. Integration Test Suite
**`scripts/integration-test-enterprise-views.ps1`**

Full lifecycle testing:
1. Initial provisioning
2. Verification
3. Re-provisioning (idempotency test)
4. Re-verification
5. Artifact validation
6. Monitoring integration check

---

## 🚀 Quick Start

### Basic Usage
```powershell
# Provision enterprise views (uses SigNoz at localhost:8080)
pwsh -File scripts\cursor-startup-signoz-enterprise-views.ps1
```

### Custom Configuration
```powershell
# Custom SigNoz URL and service filter
pwsh -File scripts\cursor-startup-signoz-enterprise-views.ps1 `
  -SigNozUrl http://signoz.example.com:8080 `
  -ServiceName backend `
  -Environment staging `
  -OrgPrefix "Staging •"
```

### Verification Only
```powershell
# Check if views are accessible
pwsh -File scripts\verify-enterprise-views.ps1

# Check exit code
if ($LASTEXITCODE -eq 0) {
  Write-Host "All views present"
} else {
  Write-Host "$LASTEXITCODE views missing"
}
```

### Integration Testing
```powershell
# Run full test suite
pwsh -File scripts\integration-test-enterprise-views.ps1
```

---

## 📋 Parameters

### cursor-startup-signoz-enterprise-views.ps1

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-SigNozUrl` | string | `http://localhost:8080` | SigNoz base URL |
| `-ApiKey` | string | `$env:SIGNOZ_API_KEY` | SigNoz API key (auto-detected) |
| `-OrgPrefix` | string | `Enterprise •` | View name prefix for grouping |
| `-ServiceName` | string | `frontend` | Default service for trace queries |
| `-Environment` | string | `prod` | Environment tag for filters |
| `-SkipVerification` | switch | `false` | Skip post-creation checks (not recommended) |
| `-ExportReport` | switch | `true` | Generate ECRR markdown report |

---

## 🛠️ API Key Setup

The script auto-detects your SigNoz API key from:

1. **Parameter:** `-ApiKey "your-key-here"`
2. **Environment Variable:** `$env:SIGNOZ_API_KEY`

### Setting Environment Variable (PowerShell)
```powershell
# Current session
$env:SIGNOZ_API_KEY = "your-api-key"

# Persistent (user profile)
[System.Environment]::SetEnvironmentVariable('SIGNOZ_API_KEY', 'your-api-key', 'User')
```

### Getting Your API Key from SigNoz
1. Navigate to SigNoz UI: `http://localhost:8080`
2. Go to **Settings** → **API Keys**
3. Create a new key or copy existing
4. Set the environment variable

---

## 📊 Enterprise Views Catalog

### Logs • Error Triage
**Query:** `severity = 'ERROR' OR level = 'error'`

High-priority errors for immediate attention. Includes trace correlation.

**Best For:**
- Incident triage
- Error spike detection
- Root cause analysis

### Logs • Security Signals
**Query:** `message CONTAINS 'auth' OR 'denied' OR 'forbidden'`

Security-related log patterns for audit compliance.

**Best For:**
- Security monitoring
- Compliance audits
- Access control verification

### Traces • Hot Endpoints
**Query:** `service = 'frontend' AND (status = 'ERROR' OR duration > 500ms)`

Slow or failing endpoints requiring optimization.

**Best For:**
- Performance bottleneck identification
- SLA monitoring
- Latency regression detection

### Traces • Canary Spans
**Query:** `service = 'frontend' AND (name = 'iona-canary-span' OR canary = '1')`

IONA canary test traces for pipeline health validation.

**Best For:**
- Pipeline health checks
- End-to-end testing
- Deployment verification

### Metrics • Collector Ingest Pulse
**PromQL:** `rate(otelcol_receiver_accepted_spans[5m])`

OTel collector span ingestion rate (5-minute rolling window).

**Best For:**
- Pipeline throughput monitoring
- Capacity planning
- Ingestion anomaly detection

### Metrics • P95 Latency
**PromQL:** `histogram_quantile(0.95, sum(rate(http_server_request_duration_seconds_bucket[5m])) by (le))`

95th percentile request latency across all services.

**Best For:**
- SLA compliance
- Performance trending
- Latency regression alerts

---

## 🔍 How It Works

### Phase 1: EXAMINE
1. Validates SigNoz health (`/api/v1/health`)
2. Checks API key availability
3. Creates required directories (`artifacts/`, `docs/ecrr/ECRR_REPORTS/`)
4. Discovers Saved Views API endpoint (tries 4 candidates)
5. Logs all preflight checks to ECRR report

### Phase 2: CLEAN
1. Fetches existing saved views
2. For each enterprise view definition:
   - **If exists:** UPDATE with latest definition (drift removal)
   - **If missing:** CREATE new view
3. Tracks created/updated/failed counts
4. Falls back to dashboard panels if Saved Views API unavailable

### Phase 3: VERIFY (unless `-SkipVerification`)
1. Re-fetches current view list
2. Confirms each enterprise view is accessible
3. Reports missing views
4. Logs verification results to ECRR

### Phase 4: REPORT
1. Generates JSON artifact to `artifacts/enterprise-views-*.json`
2. Generates Markdown ECRR report to `docs/ecrr/ECRR_REPORTS/enterprise-views-ecrr-*.md`
3. Includes full evidence trail with timestamps
4. Sets exit code (0 = success, 1 = failures detected)

---

## 🛡️ Error Handling

### Automatic Fallback
If Saved Views API is unavailable, the script automatically creates a **Dashboard** with equivalent panels:

**Dashboard Title:** `Enterprise • Saved Views (Dashboard)`

This ensures views are available regardless of SigNoz version or API changes.

### Partial Failure Handling
- **Individual View Failures:** Logged but don't block other views
- **API Errors:** Graceful degradation to dashboard mode
- **Verification Failures:** Reported in ECRR, exit code reflects count

### Recovery
```powershell
# 1. Check what failed
Get-Content docs\ecrr\ECRR_REPORTS\enterprise-views-ecrr-*.md | Select-String "FAIL"

# 2. Verify SigNoz is healthy
Invoke-RestMethod http://localhost:8080/api/v1/health

# 3. Re-run (idempotent - safe to retry)
pwsh -File scripts\cursor-startup-signoz-enterprise-views.ps1

# 4. Verify recovery
pwsh -File scripts\verify-enterprise-views.ps1
```

---

## 🎯 Integration with Cursor

### Workspace Task
Add to `.vscode/tasks.json`:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "BossCat: Provision Enterprise Views",
      "type": "shell",
      "command": "pwsh",
      "args": [
        "-File",
        "scripts/cursor-startup-signoz-enterprise-views.ps1"
      ],
      "problemMatcher": [],
      "group": {
        "kind": "test",
        "isDefault": false
      },
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared"
      }
    },
    {
      "label": "BossCat: Verify Enterprise Views",
      "type": "shell",
      "command": "pwsh",
      "args": [
        "-File",
        "scripts/verify-enterprise-views.ps1"
      ],
      "problemMatcher": [],
      "group": "test"
    }
  ]
}
```

### Startup Script (Optional)
Add to workspace settings to run on Cursor startup:

```json
{
  "terminal.integrated.shellArgs.windows": [
    "-NoExit",
    "-Command",
    "pwsh -File scripts\\cursor-startup-signoz-enterprise-views.ps1"
  ]
}
```

---

## 📈 CI/CD Integration

### GitHub Actions Example
```yaml
name: Verify Enterprise Views

on:
  schedule:
    - cron: '0 */6 * * *'  # Every 6 hours
  workflow_dispatch:

jobs:
  verify-views:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Provision Enterprise Views
        env:
          SIGNOZ_API_KEY: ${{ secrets.SIGNOZ_API_KEY }}
        run: |
          pwsh -File scripts/cursor-startup-signoz-enterprise-views.ps1 `
            -SigNozUrl ${{ secrets.SIGNOZ_URL }}
      
      - name: Verify Views
        run: |
          pwsh -File scripts/verify-enterprise-views.ps1
      
      - name: Upload Artifacts
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: enterprise-views-reports
          path: |
            artifacts/enterprise-views-*.json
            docs/ecrr/ECRR_REPORTS/enterprise-views-ecrr-*.md
```

---

## 📂 Artifacts Generated

### JSON Report (`artifacts/enterprise-views-*.json`)
Structured data including:
- BossCat metadata
- Timestamp and duration
- Configuration parameters
- Results (created/updated/failed counts)
- Full ECRR report
- Failed view details

### ECRR Markdown Report (`docs/ecrr/ECRR_REPORTS/enterprise-views-ecrr-*.md`)
Human-readable compliance report with:
- Executive summary table
- Preflight check results
- Actions taken and drift removed
- Evidence trail with timestamps
- View definitions catalog
- Gate compliance checklist

---

## 🔄 Idempotency Guarantee

The script is **safe to run multiple times**:

- **First Run:** Creates all 6 enterprise views
- **Subsequent Runs:** Updates existing views with latest definitions
- **No Side Effects:** Existing views are preserved, only metadata updated
- **Drift Correction:** Ensures views match current enterprise definitions

**Test Idempotency:**
```powershell
# Run twice
pwsh -File scripts\cursor-startup-signoz-enterprise-views.ps1
pwsh -File scripts\cursor-startup-signoz-enterprise-views.ps1

# Second run should show "Updated: 6"
```

---

## 🐞 Troubleshooting

### "No API key" Error
**Solution:** Set `$env:SIGNOZ_API_KEY` or pass `-ApiKey` parameter

```powershell
$env:SIGNOZ_API_KEY = "your-key-here"
```

### "SigNoz health check failed"
**Solution:** Verify SigNoz is running

```powershell
docker ps | Select-String signoz
Invoke-RestMethod http://localhost:8080/api/v1/health
```

### "No Saved Views API endpoint detected"
**Expected Behavior:** Script automatically falls back to Dashboard mode

**Verify Fallback:**
```powershell
# Check for dashboard
Invoke-RestMethod -Uri "http://localhost:8080/api/v1/dashboards" `
  -Headers @{"SIGNOZ-API-KEY"=$env:SIGNOZ_API_KEY} | 
  ConvertTo-Json -Depth 5 | 
  Select-String "Enterprise"
```

### Verification Reports Missing Views
**Solution:** Check ECRR report for specific errors

```powershell
# Find latest ECRR report
Get-ChildItem docs\ecrr\ECRR_REPORTS\enterprise-views-ecrr-*.md | 
  Sort-Object LastWriteTime -Descending | 
  Select-Object -First 1 | 
  Get-Content
```

---

## 🎓 Best Practices

### 1. Always Use Environment Variables for API Keys
```powershell
# DON'T commit API keys to source control
# DO use environment variables
$env:SIGNOZ_API_KEY = "..."
```

### 2. Run Verification After Provisioning
```powershell
# Provision
pwsh -File scripts\cursor-startup-signoz-enterprise-views.ps1

# Always verify
pwsh -File scripts\verify-enterprise-views.ps1
```

### 3. Review ECRR Reports Regularly
```powershell
# Check latest provisioning report
Get-ChildItem docs\ecrr\ECRR_REPORTS\enterprise-views-ecrr-*.md |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1
```

### 4. Include in Nightly Automation
Add verification to nightly CI/CD to catch drift early.

### 5. Customize View Prefixes per Environment
```powershell
# Development
-OrgPrefix "Dev •"

# Staging
-OrgPrefix "Staging •"

# Production
-OrgPrefix "Production •"
```

---

## 📞 Support & Feedback

**BossCat Governance Framework:** [docs/AGENTS.md](AGENTS.md)  
**Creative Guidelines:** [docs/comfort-cat/](comfort-cat/)  
**Gate Approval:** [docs/ecrr/ECRR_REPORTS/GATE_APPROVAL_enterprise-views.md](ecrr/ECRR_REPORTS/GATE_APPROVAL_enterprise-views.md)

---

## 🐾 BossCat Approval

**Status:** ✅ **PRODUCTION READY**  
**Authority:** BossCat OEM (Executive Overseer Manager)  
**Framework:** ECRR v2.0  
**Date:** 2025-10-08

---

🎯 **Happy Monitoring!**

