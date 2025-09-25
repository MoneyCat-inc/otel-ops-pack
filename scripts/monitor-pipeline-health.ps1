# Resonai Pipeline Health Monitor
# Monitors the Resonai analytics pipeline health and performance

param(
    [int]$DurationMinutes = 60,
    [switch]$Continuous = $false,
    [int]$CheckIntervalSeconds = 30
)

# Import shared spinner toolkit
. (Join-Path $PSScriptRoot 'spinner-toolkit.ps1')

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Test-SigNozHealth {
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/health" -TimeoutSec 5
        return $true
    }
    catch {
        return $false
    }
}

function Test-ClickHouseHealth {
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8123/?query=SELECT 1" -TimeoutSec 5
        return $true
    }
    catch {
        return $false
    }
}

function Get-PipelineMetrics {
    try {
        $query = "SELECT count(*) as events, avg(JSONExtractInt(body, 'ttv_ms')) as avg_ttv, countIf(JSONExtractString(body, 'event') LIKE '%error%') as errors FROM signoz_logs.distributed_logs_v2 WHERE timestamp >= now() - INTERVAL 5 MINUTE AND JSONExtractString(toString(resource), 'service', 'name') = 'resonai-analytics'"
        $encodedQuery = [System.Web.HttpUtility]::UrlEncode($query)
        $response = Invoke-RestMethod -Uri "http://localhost:8123/?query=$encodedQuery" -TimeoutSec 10
        
        if ($response.data -and $response.data.Count -gt 0) {
            return @{
                Events = $response.data[0][0]
                AvgTTV = if ($response.data[0][1]) { [math]::Round($response.data[0][1], 2) } else { $null }
                Errors = $response.data[0][2]
            }
        }
        return $null
    }
    catch {
        Write-ColorOutput "Error getting pipeline metrics: $($_.Exception.Message)" "Red"
        return $null
    }
}

function Get-TTVPercentiles {
    try {
        $query = "SELECT quantile(0.5)(JSONExtractInt(body, 'ttv_ms')) as p50, quantile(0.9)(JSONExtractInt(body, 'ttv_ms')) as p90, quantile(0.95)(JSONExtractInt(body, 'ttv_ms')) as p95, quantile(0.99)(JSONExtractInt(body, 'ttv_ms')) as p99 FROM signoz_logs.distributed_logs_v2 WHERE timestamp >= now() - INTERVAL 1 HOUR AND JSONExtractString(toString(resource), 'service', 'name') = 'resonai-analytics' AND JSONExtractInt(body, 'ttv_ms') IS NOT NULL"
        $encodedQuery = [System.Web.HttpUtility]::UrlEncode($query)
        $response = Invoke-RestMethod -Uri "http://localhost:8123/?query=$encodedQuery" -TimeoutSec 10
        
        if ($response.data -and $response.data.Count -gt 0) {
            return @{
                P50 = if ($response.data[0][0]) { [math]::Round($response.data[0][0], 2) } else { $null }
                P90 = if ($response.data[0][1]) { [math]::Round($response.data[0][1], 2) } else { $null }
                P95 = if ($response.data[0][2]) { [math]::Round($response.data[0][2], 2) } else { $null }
                P99 = if ($response.data[0][3]) { [math]::Round($response.data[0][3], 2) } else { $null }
            }
        }
        return $null
    }
    catch {
        Write-ColorOutput "Error getting TTV percentiles: $($_.Exception.Message)" "Red"
        return $null
    }
}

function Get-ErrorRate {
    param($Events, $Errors)
    
    if ($Events -eq 0) { return 0 }
    return [math]::Round(($Errors / $Events) * 100, 2)
}

function Show-HealthStatus {
    param($Metrics, $TTVPercentiles)
    
    Write-ColorOutput "`n=== Pipeline Health Status ===" "Green"
    
    if ($Metrics) {
        Write-ColorOutput "Recent Activity (5min):" "Yellow"
        Write-ColorOutput "  Events: $($Metrics.Events)" "White"
        Write-ColorOutput "  Errors: $($Metrics.Errors)" "White"
        
        $errorRate = Get-ErrorRate $Metrics.Events $Metrics.Errors
        $errorColor = if ($errorRate -gt 5) { "Red" } elseif ($errorRate -gt 2) { "Yellow" } else { "Green" }
        Write-ColorOutput "  Error Rate: $errorRate%" $errorColor
        
        if ($Metrics.AvgTTV) {
            $ttvColor = if ($Metrics.AvgTTV -gt 1000) { "Red" } elseif ($Metrics.AvgTTV -gt 500) { "Yellow" } else { "Green" }
            Write-ColorOutput "  Avg TTV: $($Metrics.AvgTTV)ms" $ttvColor
        }
    } else {
        Write-ColorOutput "No recent activity detected" "Yellow"
    }
    
    if ($TTVPercentiles) {
        Write-ColorOutput "`nTTV Percentiles (1h):" "Yellow"
        if ($TTVPercentiles.P50) { Write-ColorOutput "  P50: $($TTVPercentiles.P50)ms" "White" }
        if ($TTVPercentiles.P90) { Write-ColorOutput "  P90: $($TTVPercentiles.P90)ms" "White" }
        if ($TTVPercentiles.P95) { Write-ColorOutput "  P95: $($TTVPercentiles.P95)ms" "White" }
        if ($TTVPercentiles.P99) { Write-ColorOutput "  P99: $($TTVPercentiles.P99)ms" "White" }
    }
}

function Test-AlertConditions {
    param($Metrics, $TTVPercentiles)
    
    $alerts = @()
    
    if ($Metrics) {
        $errorRate = Get-ErrorRate $Metrics.Events $Metrics.Errors
        if ($errorRate -gt 5) {
            $alerts += "HIGH ERROR RATE: $errorRate% (threshold: 5%)"
        }
        
        if ($Metrics.AvgTTV -and $Metrics.AvgTTV -gt 1000) {
            $alerts += "HIGH TTV: $($Metrics.AvgTTV)ms (threshold: 1000ms)"
        }
    }
    
    if ($TTVPercentiles -and $TTVPercentiles.P95 -and $TTVPercentiles.P95 -gt 1000) {
        $alerts += "HIGH P95 TTV: $($TTVPercentiles.P95)ms (threshold: 1000ms)"
    }
    
    if ($Metrics -and $Metrics.Events -eq 0) {
        $alerts += "NO EVENTS: No activity in last 5 minutes"
    }
    
    return $alerts
}

# Main execution
Write-ColorOutput "=== Resonai Pipeline Health Monitor ===" "Green"
Write-ColorOutput "Started at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "White"

# Initial health checks
Write-ColorOutput "`nRunning initial health checks..." "Yellow"

$sigNozHealthy = Test-SigNozHealth
$clickHouseHealthy = Test-ClickHouseHealth

Write-ColorOutput "SigNoz Health: $(if ($sigNozHealthy) { 'OK' } else { 'FAILED' })" $(if ($sigNozHealthy) { "Green" } else { "Red" })
Write-ColorOutput "ClickHouse Health: $(if ($clickHouseHealthy) { 'OK' } else { 'FAILED' })" $(if ($clickHouseHealthy) { "Green" } else { "Red" })

if (-not $sigNozHealthy -or -not $clickHouseHealthy) {
    Write-ColorOutput "`nCRITICAL: Required services are not healthy. Aborting monitoring." "Red"
    exit 1
}

# Run verification script
Write-ColorOutput "`nRunning pipeline verification..." "Yellow"
try {
    & pwsh -File scripts/verify-wiring.ps1
    Write-ColorOutput "Verification completed" "Green"
}
catch {
    Write-ColorOutput "Verification failed: $($_.Exception.Message)" "Red"
}

# Monitoring loop
$startTime = Get-Date
$endTime = $startTime.AddMinutes($DurationMinutes)

Write-ColorOutput "`nStarting monitoring loop..." "Yellow"
Write-ColorOutput "Duration: $DurationMinutes minutes" "White"
Write-ColorOutput "Check interval: $CheckIntervalSeconds seconds" "White"

do {
    $currentTime = Get-Date
    $elapsed = ($currentTime - $startTime).TotalMinutes
    
    Write-ColorOutput "`n--- Check at $(Get-Date -Format 'HH:mm:ss') (Elapsed: $([math]::Round($elapsed, 1))min) ---" "Cyan"
    
    # Get metrics
    $metrics = Get-PipelineMetrics
    $ttvPercentiles = Get-TTVPercentiles
    
    # Show status
    Show-HealthStatus $metrics $ttvPercentiles
    
    # Check alert conditions
    $alerts = Test-AlertConditions $metrics $ttvPercentiles
    if ($alerts.Count -gt 0) {
        Write-ColorOutput "`n🚨 ALERTS:" "Red"
        foreach ($alert in $alerts) {
            Write-ColorOutput "  - $alert" "Red"
        }
    } else {
        Write-ColorOutput "`n✅ All systems normal" "Green"
    }
    
    # Check if we should continue
    if (-not $Continuous -and $currentTime -ge $endTime) {
        break
    }
    
    if ($Continuous -or $currentTime -lt $endTime) {
        Write-ColorOutput "`nWaiting $CheckIntervalSeconds seconds..." "Gray"
        Start-Sleep -Seconds $CheckIntervalSeconds
    }
    
} while ($Continuous -or $currentTime -lt $endTime)

Write-ColorOutput "`n=== Monitoring Complete ===" "Green"
Write-ColorOutput "Ended at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "White"

# Final summary
$finalMetrics = Get-PipelineMetrics
$finalTTV = Get-TTVPercentiles
Show-HealthStatus $finalMetrics $finalTTV

$finalAlerts = Test-AlertConditions $finalMetrics $finalTTV
if ($finalAlerts.Count -gt 0) {
    Write-ColorOutput "`nFinal Status: ISSUES DETECTED" "Red"
    foreach ($alert in $finalAlerts) {
        Write-ColorOutput "  - $alert" "Red"
    }
} else {
    Write-ColorOutput "`nFinal Status: ALL SYSTEMS HEALTHY" "Green"
}
