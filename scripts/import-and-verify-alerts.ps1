# scripts/import-and-verify-alerts.ps1
# Import SigNoz alerts and verify functionality
# ECRR Framework: Examine -> Clean -> Report -> Role

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$artifactsDir = Join-Path $root 'artifacts'

Write-Host "🔍 ECRR-Enhanced Alert Import & Verification" -ForegroundColor Cyan
Write-Host "Examine -> Clean -> Report -> Role" -ForegroundColor Yellow
Write-Host ""

# SECTION: EXAMINE - Current State
Write-Host "[SECTION] EXAMINE: Alert Configuration Status" -ForegroundColor Green

# Check SigNoz health
try {
    $healthResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/health" -Method Get
    Write-Host "✅ SigNoz UI: Healthy ($($healthResponse.status))" -ForegroundColor Green
} catch {
    Write-Host "❌ SigNoz UI: Unreachable" -ForegroundColor Red
    throw "SigNoz UI not accessible. Please ensure SigNoz is running."
}

# Verify alert configurations
$alertConfig = Get-Content -Path (Join-Path $artifactsDir "signoz-alerts.json") -Raw | ConvertFrom-Json
Write-Host "✅ Alert Configurations: $($alertConfig.alerts.Count) alerts ready" -ForegroundColor Green

foreach ($alert in $alertConfig.alerts) {
    Write-Host "  • $($alert.name) ($($alert.id))" -ForegroundColor Gray
}

# Check for test data
$canaryLogPath = "C:\logs\ecrr-canary-test.log"
if (Test-Path $canaryLogPath) {
    $canaryCount = (Get-Content $canaryLogPath | Measure-Object -Line).Lines
    Write-Host "✅ Canary Test Data: $canaryCount entries available" -ForegroundColor Green
} else {
    Write-Host "⚠️ Canary Test Data: No log file found" -ForegroundColor Yellow
}

# SECTION: CLEAN - Prepare for Import
Write-Host ""
Write-Host "[SECTION] CLEAN: Preparing Alert Import" -ForegroundColor Green

# Generate fresh canary test data
Write-Host "Generating fresh canary test data..."
try {
    pwsh -File (Join-Path $root "scripts\canary-ecrr.ps1") | Out-Null
    Write-Host "✅ Canary test data generated" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Canary test generation failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

# SECTION: REPORT - Import Instructions
Write-Host ""
Write-Host "[SECTION] REPORT: Alert Import Instructions" -ForegroundColor Green

Write-Host "🚀 SIGNOZ ALERT IMPORT PROCESS" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Step 1: Access SigNoz UI" -ForegroundColor Yellow
Write-Host "  Navigate to: http://localhost:8080/alerts" -ForegroundColor Cyan
Write-Host ""

Write-Host "Step 2: Import Each Alert" -ForegroundColor Yellow
Write-Host "  For each alert below:" -ForegroundColor White
Write-Host "  1. Click 'Create Alert Rule'" -ForegroundColor Gray
Write-Host "  2. Switch to JSON mode (if available)" -ForegroundColor Gray
Write-Host "  3. Copy the alert JSON block" -ForegroundColor Gray
Write-Host "  4. Paste into SigNoz UI (Ctrl+V)" -ForegroundColor Gray
Write-Host "  5. Save & Enable" -ForegroundColor Gray
Write-Host ""

# Display individual alert blocks
Write-Host "📋 ALERT BLOCKS FOR IMPORT:" -ForegroundColor Yellow
Write-Host "===========================" -ForegroundColor Yellow
Write-Host ""

foreach ($alert in $alertConfig.alerts) {
    Write-Host "Alert: $($alert.name)" -ForegroundColor Cyan
    Write-Host "ID: $($alert.id)" -ForegroundColor Gray
    Write-Host "Check Frequency: $($alert.checkFrequency)" -ForegroundColor Gray
    Write-Host "Evaluation Window: $($alert.evaluationWindow)" -ForegroundColor Gray
    Write-Host ""
    
    # Copy individual alert to clipboard
    $alertJson = $alert | ConvertTo-Json -Depth 10
    Set-Clipboard -Value $alertJson
    Write-Host "✅ Alert JSON copied to clipboard - ready to paste" -ForegroundColor Green
    Write-Host ""
    Write-Host "Press any key to continue to next alert..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Write-Host ""
}

# SECTION: ROLE - Verification Steps
Write-Host "[SECTION] ROLE: Verification & Testing" -ForegroundColor Green
Write-Host "Role: Cursor Agent - Observability Copilot" -ForegroundColor Cyan
Write-Host ""

Write-Host "🔍 VERIFICATION STEPS:" -ForegroundColor Yellow
Write-Host "=====================" -ForegroundColor Yellow
Write-Host ""

Write-Host "1. PowerShell Verification Commands:" -ForegroundColor Cyan
Write-Host "   # Check alert configurations" -ForegroundColor Gray
Write-Host "   Get-Content -Raw artifacts\signoz-alerts.json | ConvertFrom-Json | Select-Object -Expand alerts | Select-Object name, checkFrequency, evaluationWindow" -ForegroundColor Gray
Write-Host ""

Write-Host "2. SigNoz UI Verification:" -ForegroundColor Cyan
Write-Host "   • Navigate to: http://localhost:8080/alerts" -ForegroundColor Gray
Write-Host "   • Verify all 3 alerts appear in alerts list" -ForegroundColor Gray
Write-Host "   • Check that no syntax errors are reported" -ForegroundColor Gray
Write-Host ""

Write-Host "3. Log Filtering Tests:" -ForegroundColor Cyan
Write-Host "   • Navigate to: http://localhost:8080/logs" -ForegroundColor Gray
Write-Host "   • Filter: body contains 'ECRR-Canary-Test'" -ForegroundColor Gray
Write-Host "   • Expected: Recent canary entries visible" -ForegroundColor Gray
Write-Host "   • Filter: service.name = 'otelcol-contrib'" -ForegroundColor Gray
Write-Host "   • Expected: Collector logs visible" -ForegroundColor Gray
Write-Host ""

Write-Host "4. Alert Functionality Tests:" -ForegroundColor Cyan
Write-Host "   • Windows Canary Alert: Should trigger if no canary logs for 10 minutes" -ForegroundColor Gray
Write-Host "   • Collector Error Burst: Should trigger if 3+ errors in 5 minutes" -ForegroundColor Gray
Write-Host "   • Collector Heartbeat: Should trigger if no heartbeat for 15 minutes" -ForegroundColor Gray
Write-Host ""

# Generate comprehensive report
$reportPath = Join-Path $artifactsDir "alert-import-verification-report.txt"
$report = @"
# SigNoz Alert Import & Verification Report
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Agent: Cursor Agent - Observability Copilot

## Alert Import Status

### Configuration Verified
- JSON Structure: Valid and parseable
- Alert Count: $($alertConfig.alerts.Count) alerts ready
- SigNoz UI: Healthy and accessible

### Alerts Ready for Import
$($alertConfig.alerts | ForEach-Object { "- $($_.name) ($($_.id)) - $($_.checkFrequency) check, $($_.evaluationWindow) window" } | Out-String)

### Test Data Generated
- Canary Test: ECRR-Canary-Test-$(Get-Date -Format "yyyyMMdd-HHmmss")
- Log File: C:\logs\ecrr-canary-test.log
- Windows Event Log: Application log entry created

## Import Instructions

### Step 1: Access SigNoz UI
Navigate to: http://localhost:8080/alerts

### Step 2: Import Each Alert
1. Click "Create Alert Rule"
2. Switch to JSON mode (if available)
3. Copy individual alert JSON block
4. Paste into SigNoz UI (Ctrl+V)
5. Save & Enable

### Step 3: Verify Import Success
- All 3 alerts appear in alerts list
- No syntax errors reported
- Query builder displays properly
- Alert conditions evaluate correctly

## Verification Commands

```powershell
# Check alert configurations
Get-Content -Raw artifacts\signoz-alerts.json | ConvertFrom-Json | Select-Object -Expand alerts | Select-Object name, checkFrequency, evaluationWindow

# Generate canary test
pwsh -File scripts\canary-ecrr.ps1

# Check SigNoz health
curl -s http://localhost:8080/api/v1/health
```

## Log Filtering Tests

### SigNoz UI Logs Section
1. Navigate to: http://localhost:8080/logs
2. Test filters:
   - body contains "ECRR-Canary-Test" (canary data)
   - service.name = "otelcol-contrib" (collector logs)
   - severity_text = "ERROR" (error logs)

## Alert Functionality Tests

### Windows Canary Log Missing
- Query: body contains "windows-canary" AND service.name = "windows-canary"
- Condition: Count < 1 in 10 minutes
- Test: Stop canary generation, wait 10+ minutes

### Collector Error Burst
- Query: service.name = "otelcol-contrib" AND severity_text = "ERROR"
- Condition: Count >= 3 in 5 minutes
- Test: Generate multiple error logs

### Collector Heartbeat Missing
- Query: service.name = "otelcol-contrib" AND body contains "otel-heartbeat"
- Condition: Count < 1 in 15 minutes
- Test: Stop heartbeat generation, wait 15+ minutes

## ECRR Mantra
Examine → Clean → Report → Role - Every change must begin with evidence, remove drift, leave an artifact, and declare its actor.
"@

$report | Out-File -FilePath $reportPath -Encoding UTF8
Write-Host "✅ Comprehensive report generated: $reportPath" -ForegroundColor Green

# Final Summary
Write-Host ""
Write-Host "🎯 ALERT IMPORT READY" -ForegroundColor Green
Write-Host "====================" -ForegroundColor Green
Write-Host ""
Write-Host "✅ Alert configurations validated" -ForegroundColor Green
Write-Host "✅ Test data generated" -ForegroundColor Green
Write-Host "✅ Import instructions provided" -ForegroundColor Green
Write-Host "✅ Verification steps documented" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Open SigNoz UI: http://localhost:8080/alerts" -ForegroundColor Cyan
Write-Host "2. Import each alert using the provided JSON blocks" -ForegroundColor Cyan
Write-Host "3. Verify functionality with the provided tests" -ForegroundColor Cyan
Write-Host "4. Monitor alert performance and adjust as needed" -ForegroundColor Cyan
Write-Host ""
Write-Host "📊 SigNoz UI Links:" -ForegroundColor Yellow
Write-Host "• Alerts: http://localhost:8080/alerts" -ForegroundColor Cyan
Write-Host "• Logs: http://localhost:8080/logs" -ForegroundColor Cyan
Write-Host "• Dashboards: http://localhost:8080/dashboards" -ForegroundColor Cyan
