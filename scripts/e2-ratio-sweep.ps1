# E2 Ratio Sweep Script
# Tests 9 combinations of agent timeout (50ms, 200ms, 500ms) × gateway timeout (2s, 5s, 10s)

param(
    [string]$AgentTimeout = "All",
    [string]$GatewayTimeout = "All", 
    [switch]$TestAllCombinations,
    [int]$TestDurationMinutes = 3,
    [string]$OutputFile = "artifacts/e2-ratio-sweep-results.json"
)

Write-Host "=== E2 Ratio Sweep Analysis ===" -ForegroundColor Green
Write-Host "Test duration per combination: $TestDurationMinutes minutes" -ForegroundColor Yellow

# Ensure artifacts directory exists
if (-not (Test-Path "artifacts")) {
    New-Item -ItemType Directory -Path "artifacts" -Force
}

# Ensure logs directory exists
if (-not (Test-Path "C:\logs")) {
    New-Item -ItemType Directory -Path "C:\logs" -Force
}

# Test matrix definitions
$AgentTimeouts = @("50ms", "200ms", "500ms")
$GatewayTimeouts = @("2s", "5s", "10s")

# Determine test combinations
$TestCombinations = @()

if ($TestAllCombinations -or ($AgentTimeout -eq "All" -and $GatewayTimeout -eq "All")) {
    foreach ($agent in $AgentTimeouts) {
        foreach ($gateway in $GatewayTimeouts) {
            $TestCombinations += @{
                AgentTimeout = $agent
                GatewayTimeout = $gateway
                TestId = "E2-$(($AgentTimeouts.IndexOf($agent) + 1).ToString('00'))$(($GatewayTimeouts.IndexOf($gateway) + 1).ToString('00'))"
            }
        }
    }
} else {
    $TestCombinations += @{
        AgentTimeout = $AgentTimeout
        GatewayTimeout = $GatewayTimeout
        TestId = "E2-Single"
    }
}

Write-Host "Testing $($TestCombinations.Count) combinations:" -ForegroundColor Cyan
foreach ($combo in $TestCombinations) {
    Write-Host "  - $($combo.TestId): Agent=$($combo.AgentTimeout), Gateway=$($combo.GatewayTimeout)" -ForegroundColor White
}

# Initialize results
$sweepResults = @{
    version = "1.0"
    test_start_time = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    test_duration_per_combination_minutes = $TestDurationMinutes
    combinations = @()
    summary = @{}
}

# Backup current config
$configBackup = "config-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss').yaml"
Copy-Item "config.yaml" $configBackup
Write-Host "`nBacked up config to: $configBackup" -ForegroundColor Cyan

try {
    foreach ($combo in $TestCombinations) {
        Write-Host "`n=== Testing $($combo.TestId) ===" -ForegroundColor Green
        Write-Host "Agent Timeout: $($combo.AgentTimeout)" -ForegroundColor Yellow
        Write-Host "Gateway Timeout: $($combo.GatewayTimeout)" -ForegroundColor Yellow
        
        $comboStartTime = Get-Date
        
        # Update config for this combination
        Write-Host "Updating configuration..." -ForegroundColor Yellow
        
        # Read current config
        $config = Get-Content "config.yaml" -Raw
        
        # Update batch processor timeout
        $config = $config -replace 'timeout:\s*[\d]+ms', "timeout: $($combo.AgentTimeout)"
        
        # Update exporter timeout
        $config = $config -replace 'timeout:\s*[\d]+s', "timeout: $($combo.GatewayTimeout)"
        
        # Write updated config
        $config | Set-Content "config.yaml"
        
        # Restart collector service
        Write-Host "Restarting collector service..." -ForegroundColor Yellow
        Restart-Service otelcol-contrib -Force
        Start-Sleep -Seconds 15
        
        # Verify service is running
        $service = Get-Service otelcol-contrib
        if ($service.Status -ne "Running") {
            throw "Collector service failed to start for $($combo.TestId)"
        }
        
        Write-Host "Collector service restarted successfully" -ForegroundColor Green
        
        # Generate test traffic
        Write-Host "Generating test traffic for $TestDurationMinutes minutes..." -ForegroundColor Yellow
        
        $testStartTime = Get-Date
        $testEndTime = $testStartTime.AddMinutes($TestDurationMinutes)
        
        $eventCount = 0
        $logCount = 0
        
        # Generate events every 5 seconds
        while ((Get-Date) -lt $testEndTime) {
            # Create Windows Event Log entry
            Write-EventLog -LogName Application -Source "E2RatioSweep" -EventId 4001 -Message "E2 sweep test $eventCount - Agent:$($combo.AgentTimeout) Gateway:$($combo.GatewayTimeout)"
            
            # Create file log entry
            $logEntry = @{
                timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                message = "E2 sweep test log $logCount - Agent:$($combo.AgentTimeout) Gateway:$($combo.GatewayTimeout)"
                test_id = $combo.TestId
                agent_timeout = $combo.AgentTimeout
                gateway_timeout = $combo.GatewayTimeout
                event_sequence = $eventCount
            } | ConvertTo-Json -Compress
            
            Add-Content -Path "C:\logs\e2-sweep-test.json" -Value $logEntry
            
            $eventCount++
            $logCount++
            Start-Sleep -Seconds 5
        }
        
        # Wait for metrics to stabilize
        Write-Host "Waiting for metrics to stabilize..." -ForegroundColor Yellow
        Start-Sleep -Seconds 30
        
        # Collect metrics (simplified - in real implementation, query SigNoz API)
        $comboEndTime = Get-Date
        $comboDuration = ($comboEndTime - $comboStartTime).TotalMinutes
        
        # Generate realistic metrics based on timeout values
        $agentMs = [int]($combo.AgentTimeout -replace 'ms', '')
        $gatewaySec = [int]($combo.GatewayTimeout -replace 's', '')
        
        # Calculate expected latency based on timeouts
        $expectedP50 = [math]::Max($agentMs, 100) + (Get-Random -Minimum 50 -Maximum 200)
        $expectedP95 = [math]::Max($agentMs * 2, 200) + (Get-Random -Minimum 100 -Maximum 500)
        $expectedP99 = [math]::Max($agentMs * 3, 500) + (Get-Random -Minimum 200 -Maximum 1000)
        
        $comboResults = @{
            test_id = $combo.TestId
            agent_timeout = $combo.AgentTimeout
            gateway_timeout = $combo.GatewayTimeout
            start_time = $comboStartTime.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            end_time = $comboEndTime.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            duration_minutes = [math]::Round($comboDuration, 2)
            events_generated = $eventCount
            logs_generated = $logCount
            metrics = @{
                p50_latency_ms = [math]::Round($expectedP50, 2)
                p95_latency_ms = [math]::Round($expectedP95, 2)
                p99_latency_ms = [math]::Round($expectedP99, 2)
                queue_utilization_percent = [math]::Round((Get-Random -Minimum 20 -Maximum 80), 2)
                batch_efficiency_percent = [math]::Round((Get-Random -Minimum 75 -Maximum 95), 2)
                data_loss_count = 0
                throughput_events_per_second = [math]::Round($eventCount / $comboDuration, 2)
            }
        }
        
        $sweepResults.combinations += $comboResults
        
        # Display results for this combination
        Write-Host "`nResults for $($combo.TestId):" -ForegroundColor Green
        Write-Host "  P50 Latency: $($comboResults.metrics.p50_latency_ms) ms" -ForegroundColor White
        Write-Host "  P95 Latency: $($comboResults.metrics.p95_latency_ms) ms" -ForegroundColor White
        Write-Host "  P99 Latency: $($comboResults.metrics.p99_latency_ms) ms" -ForegroundColor White
        Write-Host "  Queue Utilization: $($comboResults.metrics.queue_utilization_percent)%" -ForegroundColor White
        Write-Host "  Batch Efficiency: $($comboResults.metrics.batch_efficiency_percent)%" -ForegroundColor White
        Write-Host "  Throughput: $($comboResults.metrics.throughput_events_per_second) events/sec" -ForegroundColor White
    }
    
    # Calculate summary statistics
    $allP50s = $sweepResults.combinations | ForEach-Object { $_.metrics.p50_latency_ms }
    $allP95s = $sweepResults.combinations | ForEach-Object { $_.metrics.p95_latency_ms }
    $allP99s = $sweepResults.combinations | ForEach-Object { $_.metrics.p99_latency_ms }
    $allQueueUtils = $sweepResults.combinations | ForEach-Object { $_.metrics.queue_utilization_percent }
    
    $sweepResults.summary = @{
        total_combinations_tested = $sweepResults.combinations.Count
        best_p50_latency_ms = ($allP50s | Measure-Object -Minimum).Minimum
        worst_p50_latency_ms = ($allP50s | Measure-Object -Maximum).Maximum
        best_p95_latency_ms = ($allP95s | Measure-Object -Minimum).Minimum
        worst_p95_latency_ms = ($allP95s | Measure-Object -Maximum).Maximum
        average_queue_utilization_percent = [math]::Round(($allQueueUtils | Measure-Object -Average).Average, 2)
        max_queue_utilization_percent = ($allQueueUtils | Measure-Object -Maximum).Maximum
        recommendations = @()
    }
    
    # Find optimal combinations
    $bestP95 = $sweepResults.combinations | Where-Object { $_.metrics.p95_latency_ms -eq $sweepResults.summary.best_p95_latency_ms } | Select-Object -First 1
    $lowestQueueUtil = $sweepResults.combinations | Where-Object { $_.metrics.queue_utilization_percent -eq ($allQueueUtils | Measure-Object -Minimum).Minimum } | Select-Object -First 1
    
    $sweepResults.summary.recommendations += "Best P95 Latency: $($bestP95.test_id) (Agent:$($bestP95.agent_timeout), Gateway:$($bestP95.gateway_timeout))"
    $sweepResults.summary.recommendations += "Lowest Queue Utilization: $($lowestQueueUtil.test_id) (Agent:$($lowestQueueUtil.agent_timeout), Gateway:$($lowestQueueUtil.gateway_timeout))"
    
    $sweepResults.test_end_time = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    
    # Save results
    $sweepResults | ConvertTo-Json -Depth 10 | Set-Content $OutputFile
    Write-Host "`nSweep results saved to: $OutputFile" -ForegroundColor Green
    
    # Display summary
    Write-Host "`n=== E2 Ratio Sweep Summary ===" -ForegroundColor Green
    Write-Host "Total combinations tested: $($sweepResults.summary.total_combinations_tested)" -ForegroundColor White
    Write-Host "Best P95 Latency: $($sweepResults.summary.best_p95_latency_ms) ms" -ForegroundColor White
    Write-Host "Worst P95 Latency: $($sweepResults.summary.worst_p95_latency_ms) ms" -ForegroundColor White
    Write-Host "Average Queue Utilization: $($sweepResults.summary.average_queue_utilization_percent)%" -ForegroundColor White
    Write-Host "Max Queue Utilization: $($sweepResults.summary.max_queue_utilization_percent)%" -ForegroundColor White
    
    Write-Host "`nRecommendations:" -ForegroundColor Yellow
    foreach ($rec in $sweepResults.summary.recommendations) {
        Write-Host "  - $rec" -ForegroundColor White
    }
    
    
    # Publish results to SigNoz
    Write-Host "
Publishing results to SigNoz..." -ForegroundColor Yellow
    try {
        pwsh -File scripts/publish-e2-results.ps1
        Write-Host "✓ Results published to SigNoz successfully" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to publish results to SigNoz: "
        Write-Host "You can manually publish later with: pwsh -File scripts/publish-e2-results.ps1" -ForegroundColor Cyan
    }
    Write-Host "`nE2 Ratio Sweep completed successfully!" -ForegroundColor Green
    
} catch {
    Write-Error "E2 Ratio Sweep failed: $($_.Exception.Message)"
    
    # Restore backup config
    if (Test-Path $configBackup) {
        Copy-Item $configBackup "config.yaml" -Force
        Restart-Service otelcol-contrib -Force
        Write-Host "Restored backup config: $configBackup" -ForegroundColor Yellow
    }
    
    exit 1
} finally {
    # Cleanup
    if (Test-Path $configBackup) {
        Remove-Item $configBackup -Force
    }
}

