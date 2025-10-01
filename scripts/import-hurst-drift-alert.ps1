# Import Hurst Exponent Drift Alert into SigNoz
# Provides manual import instructions and creates supporting scripts

param(
    [string]$AlertConfigFile = "signoz-hurst-exponent-drift-alert.json",
    [switch]$CreateDashboard = $false
)

# ECRR: Examine → Clean → Report → Role
Write-Host "🔍 Examine Hurst Exponent Drift Alert Import - ECRR Framework" -ForegroundColor Cyan
Write-Host "🎭 Actor: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

$ArtifactsDir = "artifacts"
if (-not (Test-Path $ArtifactsDir)) {
    New-Item -ItemType Directory -Path $ArtifactsDir | Out-Null
}

# Check SigNoz health
Write-Host "`nChecking SigNoz health..." -ForegroundColor Cyan
try {
    $SigNozHealth = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/health" -TimeoutSec 5
    if ($SigNozHealth.status -eq "ok") {
        Write-Host "  ✅ SigNoz is healthy" -ForegroundColor Green
    } else {
        Write-Host "  ❌ SigNoz is not healthy" -ForegroundColor Red
        Write-Host "    Please ensure SigNoz is running before proceeding." -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "  ❌ Could not connect to SigNoz: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "    Please ensure SigNoz is running and accessible at http://localhost:8080." -ForegroundColor Red
    exit 1
}

# Read alert configuration
Write-Host "`nReading alert configuration..." -ForegroundColor Cyan
if (-not (Test-Path $AlertConfigFile)) {
    Write-Host "  ❌ Alert configuration file not found: $AlertConfigFile" -ForegroundColor Red
    exit 1
}
$AlertConfig = Get-Content $AlertConfigFile -Raw | ConvertFrom-Json
Write-Host "  ✅ Alert configuration loaded: $($AlertConfig.name)" -ForegroundColor Green

Write-Host "`nAlert Configuration Details:" -ForegroundColor Cyan
Write-Host "  Name: $($AlertConfig.name)"
Write-Host "  Description: $($AlertConfig.description)"
Write-Host "  Severity: $($AlertConfig.severity)"
Write-Host "  Query: $($AlertConfig.query.logsQuery.query)"
Write-Host "  Threshold: $($AlertConfig.condition.threshold)"
Write-Host "  Evaluation Window: $($AlertConfig.condition.evaluationWindow)"

Write-Host "`nSigNoz Alert Import Instructions:" -ForegroundColor Yellow
Write-Host "Since API token authentication is not working, please import manually:" -ForegroundColor Yellow

Write-Host "`nManual Import Steps:" -ForegroundColor Green
Write-Host "1. Open SigNoz UI: http://localhost:8080"
Write-Host "2. Navigate to Alerts -> Create Alert"
Write-Host "3. Use the following configuration:"

Write-Host "`nAlert Configuration:" -ForegroundColor Cyan
Write-Host "Name: $($AlertConfig.name)"
Write-Host "Description: $($AlertConfig.description)"
Write-Host "Severity: $($AlertConfig.severity)"

Write-Host "`nQuery Configuration:" -ForegroundColor Cyan
Write-Host "Query Type: Logs"
Write-Host "Query:"
Write-Host "  $($AlertConfig.query.logsQuery.query)"
Write-Host "Group By: $($AlertConfig.query.logsQuery.groupBy -join ', ')"
Write-Host "Legend Format: $($AlertConfig.query.logsQuery.legendFormat)"

Write-Host "`nAlert Conditions:" -ForegroundColor Cyan
Write-Host "Threshold: $($AlertConfig.condition.threshold)"
Write-Host "Operator: $($AlertConfig.condition.operator)"
Write-Host "Evaluation Window: $($AlertConfig.condition.evaluationWindow)"
Write-Host "Alert Frequency: $($AlertConfig.condition.alertFrequency)"
Write-Host "Notification on Missing Data: $($AlertConfig.condition.notificationOnMissingData)"
Write-Host "Minimum Data Points: $($AlertConfig.condition.minimumDataPoints)"

Write-Host "`nLabels:" -ForegroundColor Cyan
$AlertConfig.labels.PSObject.Properties | ForEach-Object {
    Write-Host "  $($_.Name): $($_.Value)"
}

Write-Host "`nNotification Channels:" -ForegroundColor Cyan
$AlertConfig.notificationChannels | ForEach-Object {
    Write-Host "  - $_"
}

# Create verification script
Write-Host "`nCreating verification script..." -ForegroundColor Cyan
$VerificationScriptContent = @"
# Verify Hurst Exponent Drift Alert
# Checks alert status and provides monitoring guidance

param(
    [string]$AlertName = "$($AlertConfig.name)"
)

Write-Host "🔍 Verifying SigNoz Hurst Drift Alert: '$AlertName'" -ForegroundColor Cyan
Write-Host "🎭 Actor: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

Write-Host "`nManual Verification Steps:" -ForegroundColor Green
Write-Host "1. Open SigNoz UI: http://localhost:8080"
Write-Host "2. Navigate to Alerts"
Write-Host "3. Find the alert named '$AlertName'"
Write-Host "4. Verify its status (should be 'Active' if patterns are flowing normally)"
Write-Host "5. Check the 'Logs' section in SigNoz using the query:"
Write-Host "   $($AlertConfig.query.logsQuery.query)"
Write-Host "6. Confirm that fractal pattern logs are visible with Hurst estimates"

Write-Host "`nExpected Hurst Values:" -ForegroundColor Cyan
Write-Host "  Steady Pattern: H ≈ 0.5 (random walk)"
Write-Host "  Poisson Pattern: H ≈ 0.5 (memoryless process)"
Write-Host "  Pareto Pattern: H > 0.5 (long-range dependence)"

Write-Host "`nAlert Thresholds:" -ForegroundColor Yellow
Write-Host "  Drift Alert: H > $($AlertConfig.condition.threshold) (persistent behavior)"
Write-Host "  Anti-persistent: H < 0.3 (mean-reverting behavior)"
Write-Host "  Normal Range: 0.3 ≤ H ≤ 0.7 (acceptable variation)"

Write-Host "`nTo test the alert:" -ForegroundColor Green
Write-Host "1. Run daily pattern drills to generate baseline data"
Write-Host "2. Monitor alert status for any drift detection"
Write-Host "3. Investigate if persistent behavior (H > 0.7) is detected"

Write-Host "`nInvestigation Resources:" -ForegroundColor Cyan
Write-Host "  Analysis Report: artifacts/poisson-anomaly-analysis-report.md"
Write-Host "  Investigation Results: artifacts/poisson-anomaly-investigation.json"
Write-Host "  Pattern Results: artifacts/canary-pattern-results.json"
"@
$VerificationScriptPath = "scripts/verify-hurst-drift-alert.ps1"
Set-Content -Path $VerificationScriptPath -Value $VerificationScriptContent -Encoding UTF8
Write-Host "  ✅ Verification script created: $VerificationScriptPath" -ForegroundColor Green

# Create fractal drift dashboard if requested
if ($CreateDashboard) {
    Write-Host "`nCreating fractal drift monitoring dashboard..." -ForegroundColor Cyan
    
    $DashboardConfig = @{
        name = "Fractal Pattern Drift Monitor"
        description = "Dashboard for monitoring Hurst exponent drift in fractal pattern analysis"
        panels = @(
            @{
                title = "Hurst Exponent Trends"
                query = "message contains `"hurst_estimate`" AND log.file.path contains `"canary-pattern-results.json`""
                visualization = "time_series"
                description = "Track Hurst exponent values over time for each pattern type"
            },
            @{
                title = "Pattern Event Counts"
                query = "message contains `"windows-canary`""
                visualization = "table"
                description = "Monitor event counts for each pattern type"
            },
            @{
                title = "Drift Alert Status"
                query = "alert_name = `"$($AlertConfig.name)`""
                visualization = "stat"
                description = "Current status of Hurst drift alert"
            }
        )
        refreshInterval = "30s"
        timeRange = "24h"
    }
    
    $DashboardFile = "artifacts/fractal-drift-dashboard.json"
    $DashboardConfig | ConvertTo-Json -Depth 4 | Set-Content -Path $DashboardFile -Encoding UTF8
    Write-Host "  ✅ Dashboard configuration created: $DashboardFile" -ForegroundColor Green
}

# Create monitoring script
$MonitoringScriptContent = @"
# Fractal Drift Monitoring Script
# Provides ongoing monitoring of Hurst exponent patterns

Write-Host "🔍 Fractal Drift Monitoring Dashboard" -ForegroundColor Cyan
Write-Host "🎭 Actor: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

# Check for recent pattern results
Write-Host "`n📊 Recent Pattern Analysis:" -ForegroundColor Green
`$RecentResults = Get-ChildItem "artifacts\canary-pattern-results.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if (`$RecentResults) {
    `$Age = (Get-Date) - `$RecentResults.LastWriteTime
    Write-Host "  Latest Results: `$(`$RecentResults.Name) (`$(`$Age.TotalHours.ToString('F1')) hours ago)" -ForegroundColor White
    
    `$Results = Get-Content `$RecentResults.FullName -Raw | ConvertFrom-Json
    Write-Host "`n  Pattern Analysis:" -ForegroundColor Cyan
    
    foreach (`$Pattern in `$Results.pattern_results) {
        `$Hurst = `$Pattern.hurst_estimate
        `$Status = if (`$Hurst -lt 0.3) { "Anti-persistent" } 
                  elseif (`$Hurst -gt 0.7) { "Persistent (ALERT)" } 
                  elseif (`$Hurst -gt 0.6) { "Slightly Persistent" }
                  else { "Normal" }
        
        Write-Host "    `$(`$Pattern.pattern): H=`$Hurst (`$Status)" -ForegroundColor White
    }
} else {
    Write-Host "  ⚠️ No recent pattern results found" -ForegroundColor Yellow
}

# Check alert status (manual verification needed)
Write-Host "`n🚨 Alert Status Check:" -ForegroundColor Yellow
Write-Host "  Manual verification required in SigNoz UI:" -ForegroundColor White
Write-Host "  1. Navigate to http://localhost:8080/alerts" -ForegroundColor White
Write-Host "  2. Check '$($AlertConfig.name)' status" -ForegroundColor White
Write-Host "  3. Verify threshold: H > $($AlertConfig.condition.threshold)" -ForegroundColor White

Write-Host "`n📈 Monitoring Recommendations:" -ForegroundColor Green
Write-Host "  1. Run daily pattern drills for baseline data" -ForegroundColor White
Write-Host "  2. Monitor for H > 0.7 (persistent behavior)" -ForegroundColor White
Write-Host "  3. Investigate H < 0.3 (anti-persistent behavior)" -ForegroundColor White
Write-Host "  4. Track long-term trends in Hurst values" -ForegroundColor White

Write-Host "`n🎯 Next Actions:" -ForegroundColor Cyan
Write-Host "  - Run pattern drills: pwsh -File scripts/canary-pattern-drills.ps1" -ForegroundColor White
Write-Host "  - Check alert: pwsh -File scripts/verify-hurst-drift-alert.ps1" -ForegroundColor White
Write-Host "  - View dashboard: http://localhost:8080/dashboards" -ForegroundColor White
"@

$MonitoringScriptPath = "scripts/monitor-fractal-drift.ps1"
Set-Content -Path $MonitoringScriptPath -Value $MonitoringScriptContent -Encoding UTF8
Write-Host "  ✅ Monitoring script created: $MonitoringScriptPath" -ForegroundColor Green

# ECRR Report
$ECRRReport = @"
# ECRR Report: Hurst Exponent Drift Alert Setup

**Date**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
**Actor**: Cursor-Local (Observability Copilot)
**Task**: Create SigNoz alert for Hurst exponent drift detection

## Examine
- Alert Configuration File: `$AlertConfigFile
- SigNoz Health: Verified operational
- API Authentication: Not working, requiring manual import
- Investigation Results: Poisson anomaly investigation completed

## Clean
- Created comprehensive Hurst drift alert configuration
- Provided detailed manual import instructions for SigNoz UI
- Generated verification and monitoring scripts
- Established drift thresholds and interpretation guidelines

## Report
- Alert Name: `$($AlertConfig.name)
- Alert Description: `$($AlertConfig.description)
- Alert Query: `$($AlertConfig.query.logsQuery.query)
- Drift Threshold: H > `$($AlertConfig.condition.threshold)
- Manual Import Guide: Provided in terminal output
- Verification Script: `$VerificationScriptPath
- Monitoring Script: `$MonitoringScriptPath

## Role
Cursor-Local (Observability Copilot) - Hurst Exponent Drift Alert Setup Complete
"@

$ECRRReportPath = "$ArtifactsDir/hurst-drift-alert-setup-summary.md"
Set-Content -Path $ECRRReportPath -Value $ECRRReport -Encoding UTF8
Write-Host "  ✅ Summary report created: $ECRRReportPath" -ForegroundColor Green

Write-Host "`n✅ Hurst Exponent Drift Alert Setup Complete!" -ForegroundColor Green
Write-Host "`nSummary:" -ForegroundColor Cyan
Write-Host "  Alert configuration: $AlertConfigFile"
Write-Host "  Verification script: $VerificationScriptPath"
Write-Host "  Monitoring script: $MonitoringScriptPath"
Write-Host "  Summary report: $ECRRReportPath"

if ($CreateDashboard) {
    Write-Host "  Dashboard config: artifacts/fractal-drift-dashboard.json"
}

Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "  1. Import alert manually in SigNoz UI using the configuration above"
Write-Host "  2. Run verification script to test the alert"
Write-Host "  3. Use monitoring script for ongoing drift detection"
Write-Host "  4. Investigate any persistent behavior alerts (H > 0.7)"

Write-Host "`n🎭 Role: Cursor-Local (Observability Copilot) - Hurst Exponent Drift Alert Setup Complete" -ForegroundColor Magenta
