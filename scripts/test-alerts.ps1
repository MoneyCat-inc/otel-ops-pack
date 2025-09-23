# SigNoz Alert Testing Script
# Tests alert conditions and thresholds for the Resonai analytics pipeline

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Test-ServiceHealth {
    Write-ColorOutput "=== Service Health Check ===" "Green"
    
    # Test SigNoz
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/health" -TimeoutSec 5
        Write-ColorOutput "✅ SigNoz: Healthy" "Green"
        $sigNozHealthy = $true
    }
    catch {
        Write-ColorOutput "❌ SigNoz: Unhealthy - $($_.Exception.Message)" "Red"
        $sigNozHealthy = $false
    }
    
    # Test ClickHouse
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8123/?query=SELECT 1" -TimeoutSec 5
        Write-ColorOutput "✅ ClickHouse: Healthy" "Green"
        $clickHouseHealthy = $true
    }
    catch {
        Write-ColorOutput "❌ ClickHouse: Unhealthy - $($_.Exception.Message)" "Red"
        $clickHouseHealthy = $false
    }
    
    return @{
        SigNoz = $sigNozHealthy
        ClickHouse = $clickHouseHealthy
    }
}

function Test-ErrorRateAlert {
    Write-ColorOutput "`n=== Error Rate Alert Test ===" "Green"
    
    try {
        $query = "SELECT count(*) as total, countIf(event LIKE '%error%') as errors FROM signoz_logs.distributed_logs_v2 WHERE timestamp >= now() - INTERVAL 5 MINUTE AND JSONExtractString(toString(resource), 'service', 'name') = 'resonai-analytics'"
        $encodedQuery = [System.Web.HttpUtility]::UrlEncode($query)
        $response = Invoke-RestMethod -Uri "http://localhost:8123/?query=$encodedQuery" -TimeoutSec 10
        
        if ($response.data -and $response.data.Count -gt 0) {
            $total = $response.data[0][0]
            $errors = $response.data[0][1]
            $errorRate = if ($total -gt 0) { [math]::Round(($errors / $total) * 100, 2) } else { 0 }
            
            Write-ColorOutput "Total Events (5min): $total" "White"
            Write-ColorOutput "Error Events: $errors" "White"
            Write-ColorOutput "Error Rate: $errorRate%" "White"
            
            $threshold = 5.0
            if ($errorRate -gt $threshold) {
                Write-ColorOutput "🚨 ALERT: Error rate $errorRate% exceeds threshold $threshold%" "Red"
                return @{ Triggered = $true; Value = $errorRate; Threshold = $threshold }
            } else {
                Write-ColorOutput "✅ OK: Error rate within threshold" "Green"
                return @{ Triggered = $false; Value = $errorRate; Threshold = $threshold }
            }
        } else {
            Write-ColorOutput "⚠️ No data available for error rate calculation" "Yellow"
            return @{ Triggered = $false; Value = 0; Threshold = 5.0 }
        }
    }
    catch {
        Write-ColorOutput "❌ Error testing error rate alert: $($_.Exception.Message)" "Red"
        return @{ Triggered = $false; Error = $_.Exception.Message }
    }
}

function Test-TTVAlert {
    Write-ColorOutput "`n=== TTV Performance Alert Test ===" "Green"
    
    try {
        $query = "SELECT quantile(0.95)(ttv_ms) as p95_ttv FROM signoz_logs.distributed_logs_v2 WHERE timestamp >= now() - INTERVAL 5 MINUTE AND JSONExtractString(toString(resource), 'service', 'name') = 'resonai-analytics' AND ttv_ms IS NOT NULL"
        $encodedQuery = [System.Web.HttpUtility]::UrlEncode($query)
        $response = Invoke-RestMethod -Uri "http://localhost:8123/?query=$encodedQuery" -TimeoutSec 10
        
        if ($response.data -and $response.data.Count -gt 0 -and $response.data[0][0]) {
            $p95TTV = [math]::Round($response.data[0][0], 2)
            
            Write-ColorOutput "P95 TTV (5min): $p95TTV ms" "White"
            
            $threshold = 1000.0
            if ($p95TTV -gt $threshold) {
                Write-ColorOutput "🚨 ALERT: P95 TTV $p95TTV ms exceeds threshold $threshold ms" "Red"
                return @{ Triggered = $true; Value = $p95TTV; Threshold = $threshold }
            } else {
                Write-ColorOutput "✅ OK: P95 TTV within threshold" "Green"
                return @{ Triggered = $false; Value = $p95TTV; Threshold = $threshold }
            }
        } else {
            Write-ColorOutput "⚠️ No TTV data available for alert calculation" "Yellow"
            return @{ Triggered = $false; Value = $null; Threshold = 1000.0 }
        }
    }
    catch {
        Write-ColorOutput "❌ Error testing TTV alert: $($_.Exception.Message)" "Red"
        return @{ Triggered = $false; Error = $_.Exception.Message }
    }
}

function Test-DataFlowAlert {
    Write-ColorOutput "`n=== Data Flow Alert Test ===" "Green"
    
    try {
        $query = "SELECT count(*) as events FROM signoz_logs.distributed_logs_v2 WHERE timestamp >= now() - INTERVAL 10 MINUTE AND JSONExtractString(toString(resource), 'service', 'name') = 'resonai-analytics'"
        $encodedQuery = [System.Web.HttpUtility]::UrlEncode($query)
        $response = Invoke-RestMethod -Uri "http://localhost:8123/?query=$encodedQuery" -TimeoutSec 10
        
        if ($response.data -and $response.data.Count -gt 0) {
            $events = $response.data[0][0]
            
            Write-ColorOutput "Events (10min): $events" "White"
            
            $threshold = 0
            if ($events -eq $threshold) {
                Write-ColorOutput "🚨 ALERT: No events detected in last 10 minutes" "Red"
                return @{ Triggered = $true; Value = $events; Threshold = $threshold }
            } else {
                Write-ColorOutput "✅ OK: Data flow detected" "Green"
                return @{ Triggered = $false; Value = $events; Threshold = $threshold }
            }
        } else {
            Write-ColorOutput "⚠️ No data available for flow calculation" "Yellow"
            return @{ Triggered = $false; Value = 0; Threshold = 0 }
        }
    }
    catch {
        Write-ColorOutput "❌ Error testing data flow alert: $($_.Exception.Message)" "Red"
        return @{ Triggered = $false; Error = $_.Exception.Message }
    }
}

function Test-PipelineHealthAlert {
    Write-ColorOutput "`n=== Pipeline Health Alert Test ===" "Green"
    
    try {
        $query = "SELECT count(*) as verification_events FROM signoz_logs.distributed_logs_v2 WHERE timestamp >= now() - INTERVAL 30 MINUTE AND JSONExtractString(toString(resource), 'service', 'name') = 'resonai-analytics' AND JSONExtractString(body, 'event') = 'wiring_verification_test'"
        $encodedQuery = [System.Web.HttpUtility]::UrlEncode($query)
        $response = Invoke-RestMethod -Uri "http://localhost:8123/?query=$encodedQuery" -TimeoutSec 10
        
        if ($response.data -and $response.data.Count -gt 0) {
            $verificationEvents = $response.data[0][0]
            
            Write-ColorOutput "Verification Events (30min): $verificationEvents" "White"
            
            $threshold = 0
            if ($verificationEvents -eq $threshold) {
                Write-ColorOutput "🚨 ALERT: No verification events in last 30 minutes" "Red"
                return @{ Triggered = $true; Value = $verificationEvents; Threshold = $threshold }
            } else {
                Write-ColorOutput "✅ OK: Pipeline health checks detected" "Green"
                return @{ Triggered = $false; Value = $verificationEvents; Threshold = $threshold }
            }
        } else {
            Write-ColorOutput "⚠️ No verification data available" "Yellow"
            return @{ Triggered = $false; Value = 0; Threshold = 0 }
        }
    }
    catch {
        Write-ColorOutput "❌ Error testing pipeline health alert: $($_.Exception.Message)" "Red"
        return @{ Triggered = $false; Error = $_.Exception.Message }
    }
}

function Get-CurrentMetrics {
    Write-ColorOutput "`n=== Current Metrics Summary ===" "Green"
    
    try {
        $query = @"
SELECT 
    count(*) as total_events,
    countIf(JSONExtractString(body, 'event') LIKE '%error%') as error_events,
    avg(JSONExtractInt(body, 'ttv_ms')) as avg_ttv,
    quantile(0.95)(JSONExtractInt(body, 'ttv_ms')) as p95_ttv,
    uniqExact(JSONExtractString(body, 'session_id')) as unique_sessions
FROM signoz_logs.distributed_logs_v2 
WHERE timestamp >= now() - INTERVAL 1 HOUR 
  AND JSONExtractString(toString(resource), 'service', 'name') = 'resonai-analytics'
"@
        
        $encodedQuery = [System.Web.HttpUtility]::UrlEncode($query)
        $response = Invoke-RestMethod -Uri "http://localhost:8123/?query=$encodedQuery" -TimeoutSec 10
        
        if ($response.data -and $response.data.Count -gt 0) {
            $data = $response.data[0]
            $totalEvents = $data[0]
            $errorEvents = $data[1]
            $avgTTV = if ($data[2]) { [math]::Round($data[2], 2) } else { $null }
            $p95TTV = if ($data[3]) { [math]::Round($data[3], 2) } else { $null }
            $uniqueSessions = $data[4]
            $errorRate = if ($totalEvents -gt 0) { [math]::Round(($errorEvents / $totalEvents) * 100, 2) } else { 0 }
            
            Write-ColorOutput "Hourly Metrics:" "Yellow"
            Write-ColorOutput "  Total Events: $totalEvents" "White"
            Write-ColorOutput "  Error Events: $errorEvents" "White"
            Write-ColorOutput "  Error Rate: $errorRate%" "White"
            Write-ColorOutput "  Unique Sessions: $uniqueSessions" "White"
            if ($avgTTV) { Write-ColorOutput "  Avg TTV: $avgTTV ms" "White" }
            if ($p95TTV) { Write-ColorOutput "  P95 TTV: $p95TTV ms" "White" }
        } else {
            Write-ColorOutput "⚠️ No metrics data available" "Yellow"
        }
    }
    catch {
        Write-ColorOutput "❌ Error getting current metrics: $($_.Exception.Message)" "Red"
    }
}

# Main execution
Write-ColorOutput "=== SigNoz Alert Testing ===" "Green"
Write-ColorOutput "Started at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "White"

# Test service health
$health = Test-ServiceHealth

if (-not $health.SigNoz -or -not $health.ClickHouse) {
    Write-ColorOutput "`n❌ CRITICAL: Required services are not healthy. Cannot test alerts." "Red"
    exit 1
}

# Test all alert conditions
$alertResults = @{
    ErrorRate = Test-ErrorRateAlert
    TTV = Test-TTVAlert
    DataFlow = Test-DataFlowAlert
    PipelineHealth = Test-PipelineHealthAlert
}

# Show current metrics
Get-CurrentMetrics

# Summary
Write-ColorOutput "`n=== Alert Test Summary ===" "Green"
$triggeredAlerts = 0
foreach ($alert in $alertResults.Keys) {
    $result = $alertResults[$alert]
    if ($result.Triggered) {
        Write-ColorOutput "🚨 $alert`: TRIGGERED" "Red"
        $triggeredAlerts++
    } elseif ($result.Error) {
        Write-ColorOutput "❌ $alert`: ERROR - $($result.Error)" "Red"
    } else {
        Write-ColorOutput "✅ $alert`: OK" "Green"
    }
}

Write-ColorOutput "`n=== Final Status ===" "Green"
if ($triggeredAlerts -gt 0) {
    Write-ColorOutput "🚨 $triggeredAlerts alert(s) triggered - Review conditions" "Red"
} else {
    Write-ColorOutput "✅ All alert conditions normal" "Green"
}

Write-ColorOutput "`nCompleted at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "White"
