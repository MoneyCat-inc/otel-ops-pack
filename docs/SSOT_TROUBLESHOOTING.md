# SSOT Troubleshooting Guide
## Quick Reference for Common Issues

**Version**: 1.0  
**Last Updated**: 2025-09-27  
**Maintainer**: Cursor Agent (Observability Copilot)

---

## Quick Diagnostics

### Health Check Commands

```powershell
# Basic health check
pwsh -File scripts/monitor-ssot-health.ps1

# Detailed health report
pwsh -File scripts/monitor-ssot-health.ps1 -Detailed -ExportMetrics

# Check SSOT automation
pwsh -File scripts/automate-ssot-updates.ps1 -DryRun
```

### File Verification

```powershell
# Check SSOT files exist
Test-Path .artifacts/SSOT.md
Test-Path artifacts/ssot-telemetry-summary.json
Test-Path RUN_AND_VERIFY.md

# Check file contents
Get-Content .artifacts/SSOT.md
Get-Content artifacts/ssot-telemetry-summary.json
```

---

## Common Issues and Solutions

### 1. SSOT Block Missing

**Symptoms**:
- `.artifacts/SSOT.md` not found
- Health check shows "missing" status
- CI step summary empty

**Diagnosis**:
```powershell
# Check if SSOT file exists
Test-Path .artifacts/SSOT.md

# Check directory structure
Get-ChildItem .artifacts/
```

**Solution**:
```powershell
# Generate SSOT block
node scripts/ci-ssot-telemetry.ts

# Verify creation
pwsh -File scripts/monitor-ssot-health.ps1
```

**Prevention**:
- Ensure SSOT generator runs in CI
- Monitor automation scripts
- Set up alerts for missing files

### 2. SSOT Block Stale

**Symptoms**:
- SSOT block > 60 minutes old
- Health check shows "stale" status
- Outdated telemetry data

**Diagnosis**:
```powershell
# Check file age
$ssotFile = Get-Item .artifacts/SSOT.md
$age = (Get-Date) - $ssotFile.LastWriteTime
Write-Host "SSOT age: $($age.TotalMinutes) minutes"
```

**Solution**:
```powershell
# Update SSOT block
node scripts/ci-ssot-telemetry.ts

# Verify freshness
pwsh -File scripts/monitor-ssot-health.ps1
```

**Prevention**:
- Enable continuous monitoring
- Set up automated updates
- Monitor telemetry source changes

### 3. SSOT Data Mismatch

**Symptoms**:
- SSOT values don't match source data
- Health check shows "mismatch" status
- Inconsistent telemetry

**Diagnosis**:
```powershell
# Compare values
$ssotContent = Get-Content .artifacts/SSOT.md -Raw
$telemetryJson = Get-Content artifacts/ssot-telemetry-summary.json | ConvertFrom-Json

# Extract SSOT values
$ssotJobs = if ($ssotContent -match "Jobs processed:\s*\*\*(\d+)\*\*") { $matches[1] } else { "N/A" }
$jsonJobs = $telemetryJson.jobsProcessed

Write-Host "SSOT Jobs: $ssotJobs"
Write-Host "JSON Jobs: $jsonJobs"
```

**Solution**:
```powershell
# Regenerate SSOT block
node scripts/ci-ssot-telemetry.ts

# Verify accuracy
pwsh -File scripts/monitor-ssot-health.ps1 -Detailed
```

**Prevention**:
- Validate source data format
- Use consistent data sources
- Implement data validation

### 4. SSOT Generator Fails

**Symptoms**:
- Node.js execution errors
- TypeScript compilation issues
- Missing dependencies

**Diagnosis**:
```powershell
# Check Node.js version
node --version

# Check script syntax
node -c scripts/ci-ssot-telemetry.ts

# Check dependencies
npm list
```

**Solution**:
```powershell
# Use Node.js directly (no tsx needed)
node scripts/ci-ssot-telemetry.ts

# Or install tsx
npm install -g tsx

# Check file permissions
Get-Acl scripts/ci-ssot-telemetry.ts
```

**Prevention**:
- Use stable Node.js versions
- Document dependencies
- Test in clean environments

### 5. File Permission Issues

**Symptoms**:
- "Permission denied" errors
- Cannot write to `.artifacts/`
- Access denied to files

**Diagnosis**:
```powershell
# Check directory permissions
Get-Acl .artifacts/

# Check file permissions
Get-Acl .artifacts/SSOT.md
```

**Solution**:
```powershell
# Fix directory permissions
icacls .artifacts /grant Everyone:F /T

# Fix file permissions
icacls .artifacts/SSOT.md /grant Everyone:F

# Or use PowerShell
Set-Acl -Path .artifacts/ -AclObject (Get-Acl .)
```

**Prevention**:
- Set proper directory permissions
- Use consistent user accounts
- Monitor permission changes

### 6. JSON Parse Errors

**Symptoms**:
- "Unexpected token" errors
- JSON validation failures
- Malformed data

**Diagnosis**:
```powershell
# Validate JSON format
try {
    Get-Content artifacts/ssot-telemetry-summary.json | ConvertFrom-Json
    Write-Host "JSON is valid"
} catch {
    Write-Host "JSON error: $($_.Exception.Message)"
}
```

**Solution**:
```powershell
# Fix JSON format
$jsonContent = Get-Content artifacts/ssot-telemetry-summary.json -Raw
$jsonContent | ConvertFrom-Json | ConvertTo-Json -Depth 3 | Out-File artifacts/ssot-telemetry-summary.json -Encoding UTF8

# Validate fix
Get-Content artifacts/ssot-telemetry-summary.json | ConvertFrom-Json
```

**Prevention**:
- Validate JSON before writing
- Use proper escaping
- Test with sample data

### 7. CI Integration Issues

**Symptoms**:
- SSOT not in step summary
- Artifacts not uploaded
- Workflow failures

**Diagnosis**:
```yaml
# Check GitHub Actions logs
# Look for SSOT-related steps
# Verify artifact uploads
```

**Solution**:
```yaml
# Ensure SSOT step in workflow
- name: Build SSOT telemetry block
  run: |
    node scripts/ci-ssot-telemetry.ts > .artifacts/SSOT.md
    
- name: Publish SSOT to step summary
  run: |
    echo "## 📊 SSOT Telemetry Block" >> $GITHUB_STEP_SUMMARY
    cat .artifacts/SSOT.md >> $GITHUB_STEP_SUMMARY
```

**Prevention**:
- Test workflows locally
- Monitor CI execution
- Validate step outputs

---

## Advanced Troubleshooting

### Debug Mode

Enable detailed logging:

```powershell
# PowerShell debug
$DebugPreference = "Continue"
$VerbosePreference = "Continue"
pwsh -File scripts/monitor-ssot-health.ps1 -Detailed

# Node.js debug
DEBUG=* node scripts/ci-ssot-telemetry.ts
```

### Log Analysis

Check system logs:

```powershell
# Windows Event Logs
Get-WinEvent -LogName Application | Where-Object { $_.Message -like "*SSOT*" }

# PowerShell logs
Get-Content $env:USERPROFILE\AppData\Local\Temp\ps-script-*.log
```

### Performance Issues

Monitor system resources:

```powershell
# Check CPU usage
Get-Process | Where-Object { $_.ProcessName -like "*node*" }

# Check memory usage
Get-Process | Where-Object { $_.ProcessName -like "*pwsh*" }

# Check disk space
Get-WmiObject -Class Win32_LogicalDisk | Select-Object DeviceID, @{Name="Size(GB)";Expression={[math]::Round($_.Size/1GB,2)}}, @{Name="FreeSpace(GB)";Expression={[math]::Round($_.FreeSpace/1GB,2)}}
```

---

## Recovery Procedures

### Complete SSOT Reset

If SSOT system is completely broken:

```powershell
# 1. Backup current state
Copy-Item .artifacts/SSOT.md .artifacts/SSOT.md.backup -ErrorAction SilentlyContinue
Copy-Item artifacts/ssot-telemetry-summary.json artifacts/ssot-telemetry-summary.json.backup -ErrorAction SilentlyContinue

# 2. Clean artifacts
Remove-Item .artifacts/SSOT.md -ErrorAction SilentlyContinue
Remove-Item artifacts/ssot-telemetry-summary.json -ErrorAction SilentlyContinue

# 3. Regenerate from scratch
node scripts/ci-ssot-telemetry.ts

# 4. Verify recovery
pwsh -File scripts/monitor-ssot-health.ps1 -Detailed
```

### Partial Recovery

If only specific components are broken:

```powershell
# 1. Identify broken component
pwsh -File scripts/monitor-ssot-health.ps1 -Detailed

# 2. Fix specific issue
# (Use specific solutions above)

# 3. Verify fix
pwsh -File scripts/monitor-ssot-health.ps1
```

---

## Monitoring and Alerting

### Health Metrics

Monitor these key metrics:

- **SSOT Health Score**: Target >67%
- **Freshness**: Target <60 minutes
- **Accuracy**: Target 100%
- **Integration**: Target 100%

### Alert Thresholds

Set up alerts for:

- SSOT block missing
- SSOT block stale (>60 minutes)
- Data mismatches
- Generator failures
- File permission issues

### Dashboard Queries

Use these queries in monitoring dashboards:

```prometheus
# SSOT Health Score
ssot_health_score

# SSOT Freshness
ssot_age_minutes

# SSOT Accuracy
ssot_mismatch_count

# SSOT Integration
ssot_integration_ok
```

---

## Support Contacts

### Level 1 Support
- **Team**: Operations
- **Contact**: ops-team@company.com
- **SLA**: 4 hours

### Level 2 Support
- **Team**: Development
- **Contact**: dev-team@company.com
- **SLA**: 2 hours

### Level 3 Support
- **Team**: Architecture
- **Contact**: arch-team@company.com
- **SLA**: 1 hour

---

## ECRR Compliance

**Examine**: Troubleshooting procedures documented  
**Clean**: Common issues identified and resolved  
**Report**: Troubleshooting guide created  
**Role**: Cursor Agent (Observability Copilot) - SSOT troubleshooting specialist

**Last Updated**: 2025-09-27  
**Next Review**: 2025-10-27
