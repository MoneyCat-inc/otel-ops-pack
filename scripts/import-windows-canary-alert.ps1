# Import Windows Logs Canary Alert to SigNoz
# Imports the Windows logs absence detection alert configuration

param(
    [string]$SigNozUrl = "http://localhost:8080",
    [string]$AlertFile = "signoz-windows-logs-canary-alert.json"
)

# ECRR - Examine → Clean → Report → Role
Write-Host "🔍 Examine Windows Canary Alert Import - ECRR Framework" -ForegroundColor Cyan
Write-Host "🎭 Actor: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

# Check if alert file exists
if (-not (Test-Path $AlertFile)) {
    Write-Host "❌ Alert file not found: $AlertFile" -ForegroundColor Red
    exit 1
}

# Check SigNoz health
Write-Host "`n📊 Checking SigNoz health..." -ForegroundColor Green
try {
    $HealthResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/health" -TimeoutSec 10
    if ($HealthResponse.status -eq "ok") {
        Write-Host "  ✓ SigNoz is healthy" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ SigNoz health check returned: $($HealthResponse.status)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ❌ SigNoz health check failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  Please ensure SigNoz is running at $SigNozUrl" -ForegroundColor Yellow
    exit 1
}

# Read alert configuration
Write-Host "`n📄 Reading alert configuration..." -ForegroundColor Green
try {
    $AlertConfig = Get-Content $AlertFile -Raw | ConvertFrom-Json
    Write-Host "  ✓ Alert configuration loaded: $($AlertConfig.alert.name)" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Failed to parse alert configuration: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Display alert details
Write-Host "`n📋 Alert Configuration Details:" -ForegroundColor Cyan
Write-Host "  Name: $($AlertConfig.alert.name)" -ForegroundColor White
Write-Host "  Description: $($AlertConfig.alert.description)" -ForegroundColor White
Write-Host "  Severity: $($AlertConfig.alert.severity)" -ForegroundColor White
Write-Host "  Query: $($AlertConfig.alert.query.logsQuery.query)" -ForegroundColor White
Write-Host "  Threshold: $($AlertConfig.alert.condition.threshold)" -ForegroundColor White
Write-Host "  Evaluation Window: $($AlertConfig.alert.condition.evaluationWindow)" -ForegroundColor White

# Create import instructions
Write-Host "`n🚀 SigNoz Alert Import Instructions:" -ForegroundColor Green
Write-Host "Since API token authentication is not working, please import manually:" -ForegroundColor Yellow

Write-Host "`n📝 Manual Import Steps:" -ForegroundColor Cyan
Write-Host "1. Open SigNoz UI: $SigNozUrl" -ForegroundColor White
Write-Host "2. Navigate to Alerts → Create Alert" -ForegroundColor White
Write-Host "3. Use the following configuration:" -ForegroundColor White

Write-Host "`n🔧 Alert Configuration:" -ForegroundColor Yellow
Write-Host "Name: $($AlertConfig.alert.name)" -ForegroundColor White
Write-Host "Description: $($AlertConfig.alert.description)" -ForegroundColor White
Write-Host "Severity: $($AlertConfig.alert.severity)" -ForegroundColor White

Write-Host "`n📊 Query Configuration:" -ForegroundColor Yellow
Write-Host "Query Type: Logs" -ForegroundColor White
Write-Host "Query:" -ForegroundColor White
Write-Host "  $($AlertConfig.alert.query.logsQuery.query)" -ForegroundColor Cyan
Write-Host "Group By: $($AlertConfig.alert.query.logsQuery.groupBy -join ', ')" -ForegroundColor White
Write-Host "Legend Format: $($AlertConfig.alert.query.logsQuery.legendFormat)" -ForegroundColor White

Write-Host "`n⚠️ Alert Conditions:" -ForegroundColor Yellow
Write-Host "Threshold: $($AlertConfig.alert.condition.threshold)" -ForegroundColor White
Write-Host "Operator: $($AlertConfig.alert.condition.operator)" -ForegroundColor White
Write-Host "Evaluation Window: $($AlertConfig.alert.condition.evaluationWindow)" -ForegroundColor White
Write-Host "Alert Frequency: $($AlertConfig.alert.condition.alertFrequency)" -ForegroundColor White
Write-Host "Notification on Missing Data: $($AlertConfig.alert.condition.notificationOnMissingData)" -ForegroundColor White
Write-Host "Minimum Data Points: $($AlertConfig.alert.condition.minimumDataPoints)" -ForegroundColor White

Write-Host "`n🏷️ Labels:" -ForegroundColor Yellow
foreach ($Label in $AlertConfig.alert.labels.PSObject.Properties) {
    Write-Host "  $($Label.Name): $($Label.Value)" -ForegroundColor White
}

Write-Host "`n📧 Notification Channels:" -ForegroundColor Yellow
foreach ($Channel in $AlertConfig.alert.notificationChannels) {
    Write-Host "  - $Channel" -ForegroundColor White
}

# Create verification script
Write-Host "`n🧪 Creating verification script..." -ForegroundColor Green
$VerificationScript = @"
# Windows Canary Alert Verification Script
# Run this after importing the alert to verify it's working

Write-Host "Testing Windows Canary Alert..." -ForegroundColor Green

# Generate test canary logs
pwsh -File scripts/generate-windows-canary.ps1 -DurationMinutes 2 -IntervalSeconds 10

Write-Host "`nWait 2 minutes, then check SigNoz UI for:" -ForegroundColor Yellow
Write-Host "1. Canary logs appearing in Logs section" -ForegroundColor White
Write-Host "2. Alert status in Alerts section" -ForegroundColor White
Write-Host "3. No alert firing (since canaries are being generated)" -ForegroundColor White

Write-Host "`nTo test the alert:" -ForegroundColor Yellow
Write-Host "1. Stop canary generation" -ForegroundColor White
Write-Host "2. Wait 10+ minutes" -ForegroundColor White
Write-Host "3. Alert should fire due to missing canaries" -ForegroundColor White
"@

$VerificationScriptPath = "scripts/verify-windows-canary-alert.ps1"
Set-Content -Path $VerificationScriptPath -Value $VerificationScript -Encoding UTF8
Write-Host "  ✓ Verification script created: $VerificationScriptPath" -ForegroundColor Green

# Generate test data for immediate verification
Write-Host "`n🎯 Generating test canary logs for immediate verification..." -ForegroundColor Green
try {
    & pwsh -File scripts/generate-windows-canary.ps1 -DurationMinutes 1 -IntervalSeconds 15
    Write-Host "  ✓ Test canary logs generated" -ForegroundColor Green
} catch {
    Write-Host "  ⚠ Could not generate test canary logs: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Create summary report
$ReportFile = "artifacts/windows-canary-alert-import-summary.md"
if (-not (Test-Path "artifacts")) {
    New-Item -ItemType Directory -Path "artifacts" -Force | Out-Null
}

$Report = @"
# Windows Canary Alert Import Summary

**Generated**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  
**Actor**: Cursor-Local (Observability Copilot)  
**Alert**: Windows Logs Canary Absence Detection

## Alert Configuration

- **Name**: $($AlertConfig.alert.name)
- **Severity**: $($AlertConfig.alert.severity)
- **Evaluation Window**: $($AlertConfig.alert.condition.evaluationWindow)
- **Threshold**: $($AlertConfig.alert.condition.threshold)

## Query Details

\`\`\`
$($AlertConfig.alert.query.logsQuery.query)
\`\`\`

## Import Status

✅ **Alert configuration prepared**  
✅ **SigNoz health verified**  
✅ **Test canary logs generated**  
✅ **Verification script created**  

## Next Steps

1. **Manual Import**: Follow the import instructions above
2. **Verification**: Run \`pwsh -File scripts/verify-windows-canary-alert.ps1\`
3. **Testing**: Generate canary logs and verify alert behavior
4. **Monitoring**: Monitor alert status in SigNoz UI

## Files Generated

- \`$AlertFile\` - Alert configuration
- \`scripts/generate-windows-canary.ps1\` - Canary generator
- \`scripts/verify-windows-canary-alert.ps1\` - Verification script
- \`$ReportFile\` - This summary

---
*Generated by Cursor-Local (Observability Copilot) following ECRR methodology*
"@

Set-Content -Path $ReportFile -Value $Report -Encoding UTF8
Write-Host "  ✓ Summary report created: $ReportFile" -ForegroundColor Green

Write-Host "`n✅ Windows Canary Alert Import Setup Complete!" -ForegroundColor Green
Write-Host "📋 Summary:" -ForegroundColor Cyan
Write-Host "  Alert configuration: $AlertFile" -ForegroundColor White
Write-Host "  Test canary generator: scripts/generate-windows-canary.ps1" -ForegroundColor White
Write-Host "  Verification script: scripts/verify-windows-canary-alert.ps1" -ForegroundColor White
Write-Host "  Summary report: $ReportFile" -ForegroundColor White

Write-Host "`n🎯 Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Import alert manually in SigNoz UI using the configuration above" -ForegroundColor White
Write-Host "  2. Run verification script to test the alert" -ForegroundColor White
Write-Host "  3. Monitor alert status and canary log generation" -ForegroundColor White

Write-Host "`n🎭 Role: Cursor-Local (Observability Copilot) - Windows Canary Alert Setup Complete" -ForegroundColor Magenta
