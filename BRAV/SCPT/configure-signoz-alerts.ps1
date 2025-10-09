# SigNoz Alert Configuration Script
# Usage: pwsh -File scripts/configure-signoz-alerts.ps1

param(
    [switch]$Critical,
    [switch]$Warning,
    [switch]$All,
    [switch]$DryRun
)

# Set working directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
Set-Location $RepoRoot

# SigNoz configuration
$SigNozBaseUrl = "http://localhost:8080"
$SigNozApiUrl = "$SigNozBaseUrl/api/v1"

# Alert templates
$CriticalAlerts = @(
    @{
        name = "Windows Collector Down"
        condition = "up{job=`"otelcol-contrib`"} == 0"
        duration = "0m"
        severity = "critical"
        notifications = @("email", "slack")
        message = "Windows Collector service is down. Immediate action required."
    },
    @{
        name = "SigNoz Container Unhealthy"
        condition = "up{job=`"signoz`"} == 0"
        duration = "0m"
        severity = "critical"
        notifications = @("email", "slack")
        message = "SigNoz container is unhealthy. Check Docker status."
    },
    @{
        name = "OTLP Pipeline Failure"
        condition = "rate(otelcol_receiver_accepted_log_records[5m]) == 0"
        duration = "5m"
        severity = "critical"
        notifications = @("email", "slack")
        message = "No logs ingested for 5 minutes. Check OTLP pipeline."
    }
)

$WarningAlerts = @(
    @{
        name = "High CPU Usage"
        condition = "rate(process_cpu_seconds_total[5m]) * 100 > 80"
        duration = "5m"
        severity = "warning"
        notifications = @("slack")
        message = "CPU usage above 80% for 5 minutes."
    },
    @{
        name = "Memory Leak Detection"
        condition = "increase(process_resident_memory_bytes[1h]) > 0.1"
        duration = "1h"
        severity = "warning"
        notifications = @("slack")
        message = "Memory usage increasing significantly."
    },
    @{
        name = "Service Worker Registration Failed"
        condition = "service_worker_registration_success_rate < 0.95"
        duration = "10m"
        severity = "warning"
        notifications = @("slack")
        message = "Service Worker registration success rate below 95%."
    },
    @{
        name = "Cross-Origin Isolation Lost"
        condition = "cross_origin_isolated == 0"
        duration = "0m"
        severity = "warning"
        notifications = @("slack")
        message = "Cross-origin isolation lost. Check COOP/COEP headers."
    },
    @{
        name = "Audio Latency Degradation"
        condition = "audio_latency_p90 > 200"
        duration = "2m"
        severity = "warning"
        notifications = @("slack")
        message = "Audio latency P90 above 200ms."
    },
    @{
        name = "Canary Test Failure"
        condition = "rate(otelcol_receiver_accepted_log_records{source=`"canary`"}[5m]) == 0"
        duration = "5m"
        severity = "warning"
        notifications = @("slack")
        message = "Canary test failure detected. Check canary system."
    },
    @{
        name = "Log Parsing Errors"
        condition = "rate(otelcol_receiver_refused_log_records[5m]) > 0.01"
        duration = "10m"
        severity = "warning"
        notifications = @("slack")
        message = "Log parsing error rate above 1%."
    }
)

function Test-SigNozConnection {
    try {
        $response = Invoke-WebRequest -Uri "$SigNozApiUrl/health" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ SigNoz API accessible" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ SigNoz API returned status: $($response.StatusCode)" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ SigNoz API not accessible: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Configure-Alert {
    param($AlertConfig)
    
    Write-Host "🚨 Configuring alert: $($AlertConfig.name)" -ForegroundColor Yellow
    
    if ($DryRun) {
        Write-Host "🔍 DRY RUN: Would configure alert '$($AlertConfig.name)'" -ForegroundColor Yellow
        Write-Host "   Condition: $($AlertConfig.condition)" -ForegroundColor White
        Write-Host "   Duration: $($AlertConfig.duration)" -ForegroundColor White
        Write-Host "   Severity: $($AlertConfig.severity)" -ForegroundColor White
        return $true
    }
    
    try {
        # Create alert rule object
        $alertRule = @{
            name = $AlertConfig.name
            condition = $AlertConfig.condition
            duration = $AlertConfig.duration
            severity = $AlertConfig.severity
            message = $AlertConfig.message
            notifications = $AlertConfig.notifications
            enabled = $true
        }
        
        $jsonBody = $alertRule | ConvertTo-Json -Depth 10
        $response = Invoke-WebRequest -Uri "$SigNozApiUrl/alerts" -Method POST -ContentType "application/json" -Body $jsonBody -UseBasicParsing -TimeoutSec 30 -ErrorAction Stop
        
        if ($response.StatusCode -eq 200 -or $response.StatusCode -eq 201) {
            Write-Host "✅ Alert '$($AlertConfig.name)' configured successfully" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ Failed to configure alert '$($AlertConfig.name)'. Status: $($response.StatusCode)" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ Error configuring alert '$($AlertConfig.name)': $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Configure-AlertGroup {
    param($AlertGroup, $GroupName)
    
    Write-Host "`n🚨 Configuring $GroupName Alerts..." -ForegroundColor Cyan
    $successCount = 0
    $totalCount = $AlertGroup.Count
    
    foreach ($alert in $AlertGroup) {
        if (Configure-Alert $alert) {
            $successCount++
        }
    }
    
    Write-Host "`n📊 $GroupName Alerts Summary:" -ForegroundColor Cyan
    Write-Host "   Total: $totalCount" -ForegroundColor White
    Write-Host "   Success: $successCount" -ForegroundColor Green
    Write-Host "   Failed: $($totalCount - $successCount)" -ForegroundColor Red
    
    return $successCount
}

# Main execution
Write-Host "=== SigNoz Alert Configuration Script ===" -ForegroundColor Cyan
Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White

# Test SigNoz connection
if (-not (Test-SigNozConnection)) {
    Write-Host "`n❌ Cannot connect to SigNoz. Please ensure SigNoz is running on $SigNozBaseUrl" -ForegroundColor Red
    exit 1
}

# Determine which alerts to configure
$configureCritical = $false
$configureWarning = $false

if ($All) {
    $configureCritical = $true
    $configureWarning = $true
} else {
    if ($Critical) { $configureCritical = $true }
    if ($Warning) { $configureWarning = $true }
}

# If no specific alerts selected, configure all
if (-not $configureCritical -and -not $configureWarning) {
    $configureCritical = $true
    $configureWarning = $true
}

# Configure alerts
$totalSuccess = 0
$totalAlerts = 0

if ($configureCritical) {
    $criticalSuccess = Configure-AlertGroup $CriticalAlerts "Critical"
    $totalSuccess += $criticalSuccess
    $totalAlerts += $CriticalAlerts.Count
}

if ($configureWarning) {
    $warningSuccess = Configure-AlertGroup $WarningAlerts "Warning"
    $totalSuccess += $warningSuccess
    $totalAlerts += $WarningAlerts.Count
}

# Final summary
Write-Host "`n=== Alert Configuration Summary ===" -ForegroundColor Cyan
Write-Host "Total Alerts: $totalAlerts" -ForegroundColor White
Write-Host "Successfully Configured: $totalSuccess" -ForegroundColor Green
Write-Host "Failed: $($totalAlerts - $totalSuccess)" -ForegroundColor Red

if ($totalSuccess -eq $totalAlerts) {
    Write-Host "`n🎉 All alerts configured successfully!" -ForegroundColor Green
    Write-Host "Access SigNoz Alerts at: $SigNozBaseUrl/alerts" -ForegroundColor White
} else {
    Write-Host "`n⚠️ Some alerts failed to configure. Check SigNoz logs for details." -ForegroundColor Yellow
}

Write-Host "`n=== Alert Configuration Complete ===" -ForegroundColor Cyan
