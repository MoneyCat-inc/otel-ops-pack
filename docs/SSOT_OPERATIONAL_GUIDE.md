# SSOT Operational Guide
## Single Source of Truth for Gate Decisions

**Version**: 1.0  
**Last Updated**: 2025-09-27  
**Maintainer**: Cursor Agent (Observability Copilot)

---

## Overview

The SSOT (Single Source of Truth) system provides a canonical source of telemetry data for gate decisions, ensuring consistency across CI/CD pipelines, runbooks, and operational dashboards. This guide covers the complete SSOT operational process.

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Telemetry     │───▶│  SSOT Generator  │───▶│   SSOT Block    │
│   Sources       │    │  (TypeScript)    │    │   (Markdown)    │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│ • Telemetry     │    │ • Data           │    │ • .artifacts/   │
│   Summary       │    │   Validation     │    │   SSOT.md       │
│ • Flake Reports │    │ • Fallback       │    │ • RUN_AND_      │
│ • Agent State   │    │   Sources        │    │   VERIFY.md     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                                         │
                                                         ▼
                                               ┌─────────────────┐
                                               │   CI Step       │
                                               │   Summary       │
                                               └─────────────────┘
```

## Components

### 1. SSOT Generator (`scripts/ci-ssot-telemetry.ts`)

**Purpose**: Builds canonical SSOT block from local artifacts  
**Inputs**: 
- `artifacts/ssot-telemetry-summary.json` (primary)
- `.artifacts/flake-report.json` (fallback)
- `.agent/state.json` (optional)

**Outputs**:
- `.artifacts/SSOT.md` (canonical SSOT block)
- `RUN_AND_VERIFY.md` (top block updated)
- STDOUT (for CI step summary)

**Usage**:
```bash
# Generate SSOT block
node scripts/ci-ssot-telemetry.ts

# With environment variables
GITHUB_SHA=abc1234 node scripts/ci-ssot-telemetry.ts
```

### 2. SSOT Automation (`scripts/automate-ssot-updates.ps1`)

**Purpose**: Automates SSOT updates after telemetry changes  
**Features**:
- File change detection
- Continuous monitoring mode
- Freshness validation
- Error handling and reporting

**Usage**:
```powershell
# Single run
pwsh -File scripts/automate-ssot-updates.ps1

# Continuous monitoring
pwsh -File scripts/automate-ssot-updates.ps1 -Continuous

# Dry run
pwsh -File scripts/automate-ssot-updates.ps1 -DryRun
```

### 3. SSOT Health Monitoring (`scripts/monitor-ssot-health.ps1`)

**Purpose**: Monitors SSOT freshness and accuracy  
**Checks**:
- File existence
- Freshness (age < 60 minutes)
- Accuracy (data consistency)
- Integration (runbook presence)

**Usage**:
```powershell
# Basic health check
pwsh -File scripts/monitor-ssot-health.ps1

# Detailed report
pwsh -File scripts/monitor-ssot-health.ps1 -Detailed

# Export metrics
pwsh -File scripts/monitor-ssot-health.ps1 -ExportMetrics
```

## Data Sources

### Primary Source: `artifacts/ssot-telemetry-summary.json`

```json
{
  "jobsProcessed": 42,
  "jobsFailed": 0,
  "queueDepthMax": 2,
  "flakyActive": 5,
  "rehabilitated7d": 1,
  "timestamp": "2025-09-27T05:01:28Z",
  "source": "ci-build-test"
}
```

### Fallback Sources

1. **`.artifacts/flake-report.json`**: Flaky test counts
2. **`.agent/state.json`**: Agent system state
3. **Environment Variables**: `GITHUB_SHA`, `GIT_COMMIT_SHA`

## SSOT Block Format

```markdown
<!-- SSOT:BEGIN -->
**Build**: `abc1234` • **Generated**: 2025-09-27T05:01:28.864Z

### Agent Telemetry (OTel)
- Jobs processed: **42**
- Jobs failed: **0**
- Queue depth (max): **2**
- Flaky tests (active): **5**
- Rehabilitated (last 7d): **1**

> SSOT is the single source of truth for gate decisions. Keep PRs artifact‑driven.
<!-- SSOT:END -->
```

## CI/CD Integration

### GitHub Actions Workflow

```yaml
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  build-test:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '20'
        
    - name: Generate telemetry summary
      run: |
        mkdir -p artifacts .artifacts
        # Generate telemetry data
        
    - name: Build SSOT telemetry block
      run: |
        node scripts/ci-ssot-telemetry.ts > .artifacts/SSOT.md
        
    - name: Publish SSOT to step summary
      run: |
        echo "## 📊 SSOT Telemetry Block" >> $GITHUB_STEP_SUMMARY
        cat .artifacts/SSOT.md >> $GITHUB_STEP_SUMMARY
        
    - name: Upload SSOT artifacts
      uses: actions/upload-artifact@v4
      with:
        name: ssot-telemetry-${{ github.run_number }}
        path: |
          .artifacts/SSOT.md
          artifacts/ssot-telemetry-summary.json
        retention-days: 30
```

### Step Summary Integration

The SSOT block is automatically appended to GitHub Actions step summaries:

```markdown
## 📊 SSOT Telemetry Block

<!-- SSOT:BEGIN -->
**Build**: `abc1234` • **Generated**: 2025-09-27T05:01:28.864Z

### Agent Telemetry (OTel)
- Jobs processed: **42**
- Jobs failed: **0**
- Queue depth (max): **2**
- Flaky tests (active): **5**
- Rehabilitated (last 7d): **1**

> SSOT is the single source of truth for gate decisions. Keep PRs artifact‑driven.
<!-- SSOT:END -->

**Generated**: 2025-09-27 05:01:28 UTC
```

## Operational Procedures

### Daily Operations

1. **Monitor SSOT Health**
   ```powershell
   pwsh -File scripts/monitor-ssot-health.ps1 -Detailed
   ```

2. **Check Freshness**
   - SSOT block should be < 60 minutes old
   - If stale, run SSOT generator

3. **Validate Accuracy**
   - Compare SSOT values with source data
   - Investigate any mismatches

### Weekly Operations

1. **Review SSOT Metrics**
   ```powershell
   pwsh -File scripts/monitor-ssot-health.ps1 -ExportMetrics
   ```

2. **Update Documentation**
   - Review operational procedures
   - Update troubleshooting guides

3. **Cleanup Artifacts**
   - Remove old SSOT reports
   - Archive historical data

### Incident Response

#### SSOT Block Missing

**Symptoms**: 
- `.artifacts/SSOT.md` not found
- Runbook missing SSOT block
- CI step summary empty

**Resolution**:
```powershell
# Generate SSOT block
node scripts/ci-ssot-telemetry.ts

# Verify creation
pwsh -File scripts/monitor-ssot-health.ps1
```

#### SSOT Block Stale

**Symptoms**:
- SSOT block > 60 minutes old
- Health check shows "stale" status

**Resolution**:
```powershell
# Update SSOT block
node scripts/ci-ssot-telemetry.ts

# Verify freshness
pwsh -File scripts/monitor-ssot-health.ps1
```

#### SSOT Data Mismatch

**Symptoms**:
- SSOT values don't match source data
- Health check shows "mismatch" status

**Resolution**:
```powershell
# Check source data
Get-Content artifacts/ssot-telemetry-summary.json

# Regenerate SSOT block
node scripts/ci-ssot-telemetry.ts

# Verify accuracy
pwsh -File scripts/monitor-ssot-health.ps1 -Detailed
```

## Monitoring and Alerting

### Health Metrics

- **SSOT Health Score**: 0-100% (target: >67%)
- **Freshness**: Age in minutes (target: <60)
- **Accuracy**: Data consistency (target: 100%)
- **Integration**: Runbook presence (target: 100%)

### Prometheus Metrics

```yaml
# SSOT Health Metrics
ssot_health_score: 100
ssot_freshness_ok: 1
ssot_accuracy_ok: 1
ssot_integration_ok: 1
ssot_age_minutes: 5
ssot_mismatch_count: 0
```

### Alert Rules

```yaml
groups:
- name: ssot-health
  rules:
  - alert: SSOTBlockStale
    expr: ssot_age_minutes > 60
    for: 5m
    labels: {severity: warning}
    annotations:
      summary: "SSOT block is stale"
      description: "SSOT block age is {{ $value }} minutes"

  - alert: SSOTDataMismatch
    expr: ssot_mismatch_count > 0
    for: 1m
    labels: {severity: critical}
    annotations:
      summary: "SSOT data mismatch detected"
      description: "{{ $value }} data mismatches found"
```

## Troubleshooting

### Common Issues

#### 1. SSOT Generator Fails

**Error**: `Cannot find package 'tsx'`

**Solution**:
```bash
# Use Node.js directly
node scripts/ci-ssot-telemetry.ts

# Or install tsx
npm install -g tsx
```

#### 2. File Permissions

**Error**: `Permission denied`

**Solution**:
```powershell
# Check file permissions
Get-Acl .artifacts/SSOT.md

# Fix permissions
icacls .artifacts /grant Everyone:F /T
```

#### 3. JSON Parse Errors

**Error**: `Unexpected token in JSON`

**Solution**:
```powershell
# Validate JSON
Get-Content artifacts/ssot-telemetry-summary.json | ConvertFrom-Json

# Fix JSON format
# Ensure proper escaping and structure
```

### Debug Mode

Enable detailed logging:

```powershell
# PowerShell debug
$DebugPreference = "Continue"
pwsh -File scripts/monitor-ssot-health.ps1 -Detailed

# Node.js debug
DEBUG=* node scripts/ci-ssot-telemetry.ts
```

## Best Practices

### 1. Data Consistency
- Always use the same data sources
- Validate JSON format before processing
- Handle missing files gracefully

### 2. Error Handling
- Implement fallback mechanisms
- Log errors with context
- Provide actionable error messages

### 3. Performance
- Cache frequently accessed data
- Minimize file I/O operations
- Use efficient parsing methods

### 4. Security
- Validate input data
- Sanitize output content
- Restrict file access permissions

## Maintenance

### Regular Tasks

- **Daily**: Monitor SSOT health
- **Weekly**: Review metrics and trends
- **Monthly**: Update documentation
- **Quarterly**: Review and optimize processes

### Version Control

- Track SSOT generator changes
- Maintain backward compatibility
- Document breaking changes

### Backup and Recovery

- Backup SSOT artifacts
- Test recovery procedures
- Maintain disaster recovery plans

## Support

### Documentation
- This operational guide
- API documentation
- Troubleshooting guides

### Monitoring
- Health dashboards
- Alert notifications
- Performance metrics

### Escalation
- Level 1: Operational team
- Level 2: Development team
- Level 3: Architecture team

---

## ECRR Compliance

**Examine**: Current state captured and analyzed  
**Clean**: SSOT system operational and monitored  
**Report**: Operational procedures documented  
**Role**: Cursor Agent (Observability Copilot) - SSOT system maintainer

**Last Updated**: 2025-09-27  
**Next Review**: 2025-10-27
