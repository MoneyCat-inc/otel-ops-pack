# SigNoz Monitoring Setup Script
# Sets up comprehensive monitoring for Resonai analytics pipeline

param(
    [switch]$OpenSigNoz = $false,
    [switch]$RunTests = $false,
    [switch]$ShowInstructions = $true
)

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Test-ServicesHealth {
    Write-ColorOutput "=== Checking Service Health ===" "Green"
    
    $healthy = $true
    
    # Test SigNoz
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/health" -TimeoutSec 5
        Write-ColorOutput "✅ SigNoz: Healthy" "Green"
    }
    catch {
        Write-ColorOutput "❌ SigNoz: Unhealthy - $($_.Exception.Message)" "Red"
        $healthy = $false
    }
    
    # Test ClickHouse
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8123/?query=SELECT 1" -TimeoutSec 5
        Write-ColorOutput "✅ ClickHouse: Healthy" "Green"
    }
    catch {
        Write-ColorOutput "❌ ClickHouse: Unhealthy - $($_.Exception.Message)" "Red"
        $healthy = $false
    }
    
    return $healthy
}

function Show-DashboardInstructions {
    Write-ColorOutput "`n=== SigNoz Dashboard Setup Instructions ===" "Green"
    
    Write-ColorOutput "`n1. Open SigNoz UI:" "Yellow"
    Write-ColorOutput "   http://localhost:8080" "White"
    
    Write-ColorOutput "`n2. Create New Dashboard:" "Yellow"
    Write-ColorOutput "   - Click 'Dashboards' in left sidebar" "White"
    Write-ColorOutput "   - Click 'New Dashboard'" "White"
    Write-ColorOutput "   - Name it 'Resonai Analytics Overview'" "White"
    
    Write-ColorOutput "`n3. Add Panels (use these filters):" "Yellow"
    Write-ColorOutput "   Filter: service.name = 'resonai-analytics'" "White"
    
    Write-ColorOutput "`n4. Panel Configurations:" "Yellow"
    
    Write-ColorOutput "`n   Panel 1: Event Volume (24h)" "Cyan"
    Write-ColorOutput "   - Type: Time Series" "White"
    Write-ColorOutput "   - Query: count(*)" "White"
    Write-ColorOutput "   - Time Range: Last 24 hours" "White"
    
    Write-ColorOutput "`n   Panel 2: Error Rate" "Cyan"
    Write-ColorOutput "   - Type: Stat" "White"
    Write-ColorOutput "   - Query: count(*) where event contains 'error' / count(*) * 100" "White"
    Write-ColorOutput "   - Unit: Percent" "White"
    Write-ColorOutput "   - Thresholds: Green < 2%, Yellow 2-5%, Red > 5%" "White"
    
    Write-ColorOutput "`n   Panel 3: TTV Performance" "Cyan"
    Write-ColorOutput "   - Type: Time Series" "White"
    Write-ColorOutput "   - Queries:" "White"
    Write-ColorOutput "     * avg(ttv_ms) - Avg TTV" "White"
    Write-ColorOutput "     * p50(ttv_ms) - P50 TTV" "White"
    Write-ColorOutput "     * p95(ttv_ms) - P95 TTV" "White"
    Write-ColorOutput "   - Unit: ms" "White"
    
    Write-ColorOutput "`n   Panel 4: Event Types Distribution" "Cyan"
    Write-ColorOutput "   - Type: Pie Chart" "White"
    Write-ColorOutput "   - Query: count(*) by event" "White"
    
    Write-ColorOutput "`n   Panel 5: Top Variants" "Cyan"
    Write-ColorOutput "   - Type: Bar Chart" "White"
    Write-ColorOutput "   - Query: count(*) by variant" "White"
    
    Write-ColorOutput "`n   Panel 6: Session Activity" "Cyan"
    Write-ColorOutput "   - Type: Stat" "White"
    Write-ColorOutput "   - Query: count(distinct session_id)" "White"
    
    Write-ColorOutput "`n   Panel 7: Pipeline Health" "Cyan"
    Write-ColorOutput "   - Type: Stat" "White"
    Write-ColorOutput "   - Query: count(*) where event = 'wiring_verification_test'" "White"
    
    Write-ColorOutput "`n5. Dashboard Configuration:" "Yellow"
    Write-ColorOutput "   - Refresh: 30 seconds" "White"
    Write-ColorOutput "   - Time Range: Last 24 hours" "White"
    Write-ColorOutput "   - Auto-refresh: Enable" "White"
}

function Show-AlertInstructions {
    Write-ColorOutput "`n=== Alert Setup Instructions ===" "Green"
    
    Write-ColorOutput "`n1. Navigate to Alerts:" "Yellow"
    Write-ColorOutput "   - Go to 'Alerts' in left sidebar" "White"
    Write-ColorOutput "   - Click 'New Alert Rule'" "White"
    
    Write-ColorOutput "`n2. Create These Alerts:" "Yellow"
    
    Write-ColorOutput "`n   Alert 1: High Error Rate" "Cyan"
    Write-ColorOutput "   - Name: 'Resonai High Error Rate'" "White"
    Write-ColorOutput "   - Condition: Error rate > 5% for 5 minutes" "White"
    Write-ColorOutput "   - Query: count(*) where event contains 'error' / count(*) > 0.05" "White"
    Write-ColorOutput "   - Filter: service.name = 'resonai-analytics'" "White"
    Write-ColorOutput "   - Severity: Critical" "White"
    
    Write-ColorOutput "`n   Alert 2: High TTV" "Cyan"
    Write-ColorOutput "   - Name: 'Resonai High TTV'" "White"
    Write-ColorOutput "   - Condition: P95 TTV > 1000ms for 5 minutes" "White"
    Write-ColorOutput "   - Query: p95(ttv_ms) > 1000" "White"
    Write-ColorOutput "   - Filter: service.name = 'resonai-analytics' AND ttv_ms IS NOT NULL" "White"
    Write-ColorOutput "   - Severity: Warning" "White"
    
    Write-ColorOutput "`n   Alert 3: Data Flow Stalled" "Cyan"
    Write-ColorOutput "   - Name: 'Resonai Data Flow Stalled'" "White"
    Write-ColorOutput "   - Condition: No events for 10 minutes" "White"
    Write-ColorOutput "   - Query: count(*) = 0" "White"
    Write-ColorOutput "   - Filter: service.name = 'resonai-analytics'" "White"
    Write-ColorOutput "   - Severity: Critical" "White"
    
    Write-ColorOutput "`n   Alert 4: Pipeline Health" "Cyan"
    Write-ColorOutput "   - Name: 'Resonai Pipeline Health'" "White"
    Write-ColorOutput "   - Condition: No verification events for 30 minutes" "White"
    Write-ColorOutput "   - Query: count(*) where event = 'wiring_verification_test' = 0" "White"
    Write-ColorOutput "   - Filter: service.name = 'resonai-analytics'" "White"
    Write-ColorOutput "   - Severity: Warning" "White"
}

function Show-MonitoringCommands {
    Write-ColorOutput "`n=== Monitoring Commands ===" "Green"
    
    Write-ColorOutput "`nDaily Health Check:" "Yellow"
    Write-ColorOutput "   pwsh -File scripts/verify-wiring.ps1" "White"
    
    Write-ColorOutput "`nReal-time Monitoring:" "Yellow"
    Write-ColorOutput "   pwsh -File scripts/monitor-pipeline-health.ps1" "White"
    Write-ColorOutput "   pwsh -File scripts/monitor-pipeline-health.ps1 -Continuous" "White"
    
    Write-ColorOutput "`nAlert Testing:" "Yellow"
    Write-ColorOutput "   pwsh -File scripts/test-alerts.ps1" "White"
    
    Write-ColorOutput "`nQuick Status Check:" "Yellow"
    Write-ColorOutput "   curl 'http://localhost:8123/?query=SELECT count(*) FROM signoz_logs.distributed_logs_v2 WHERE timestamp >= now() - INTERVAL 5 MINUTE AND service.name = '\''resonai-analytics'\'''" "White"
}

function Show-UsefulQueries {
    Write-ColorOutput "`n=== Useful SigNoz Queries ===" "Green"
    
    Write-ColorOutput "`nCurrent Activity (5min):" "Yellow"
    Write-ColorOutput "   service.name = 'resonai-analytics'" "White"
    
    Write-ColorOutput "`nError Events:" "Yellow"
    Write-ColorOutput "   service.name = 'resonai-analytics' AND event contains 'error'" "White"
    
    Write-ColorOutput "`nHigh TTV Events:" "Yellow"
    Write-ColorOutput "   service.name = 'resonai-analytics' AND ttv_ms > 1000" "White"
    
    Write-ColorOutput "`nVerification Events:" "Yellow"
    Write-ColorOutput "   service.name = 'resonai-analytics' AND event = 'wiring_verification_test'" "White"
    
    Write-ColorOutput "`nSpecific Session:" "Yellow"
    Write-ColorOutput "   service.name = 'resonai-analytics' AND session_id = 'your-session-id'" "White"
    
    Write-ColorOutput "`nRecent Events (1h):" "Yellow"
    Write-ColorOutput "   service.name = 'resonai-analytics' AND timestamp >= now() - INTERVAL 1 HOUR" "White"
}

# Main execution
Write-ColorOutput "=== SigNoz Monitoring Setup ===" "Green"
Write-ColorOutput "Started at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "White"

# Check service health
$servicesHealthy = Test-ServicesHealth

if (-not $servicesHealthy) {
    Write-ColorOutput "`n❌ CRITICAL: Required services are not healthy." "Red"
    Write-ColorOutput "Please ensure SigNoz and ClickHouse are running before setting up monitoring." "Yellow"
    exit 1
}

Write-ColorOutput "`n✅ All services healthy - proceeding with setup instructions" "Green"

# Show instructions
if ($ShowInstructions) {
    Show-DashboardInstructions
    Show-AlertInstructions
    Show-MonitoringCommands
    Show-UsefulQueries
}

# Open SigNoz if requested
if ($OpenSigNoz) {
    Write-ColorOutput "`nOpening SigNoz UI..." "Yellow"
    Start-Process "http://localhost:8080"
}

# Run tests if requested
if ($RunTests) {
    Write-ColorOutput "`nRunning monitoring tests..." "Yellow"
    
    Write-ColorOutput "`n1. Testing verification script..." "Yellow"
    try {
        & pwsh -File scripts/verify-wiring.ps1
        Write-ColorOutput "✅ Verification script passed" "Green"
    }
    catch {
        Write-ColorOutput "❌ Verification script failed: $($_.Exception.Message)" "Red"
    }
    
    Write-ColorOutput "`n2. Testing alert conditions..." "Yellow"
    try {
        & pwsh -File scripts/test-alerts.ps1
        Write-ColorOutput "✅ Alert tests completed" "Green"
    }
    catch {
        Write-ColorOutput "❌ Alert tests failed: $($_.Exception.Message)" "Red"
    }
}

Write-ColorOutput "`n=== Setup Complete ===" "Green"
Write-ColorOutput "Next steps:" "Yellow"
Write-ColorOutput "1. Follow the dashboard setup instructions above" "White"
Write-ColorOutput "2. Configure alerts as described" "White"
Write-ColorOutput "3. Run daily health checks with verify-wiring.ps1" "White"
Write-ColorOutput "4. Use monitor-pipeline-health.ps1 for continuous monitoring" "White"

Write-ColorOutput "`nCompleted at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "White"
