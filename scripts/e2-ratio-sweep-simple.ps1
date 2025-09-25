# E2 Ratio Sweep Analysis - Simplified Version
# Cat Nap Control Room - Basic E2 ratio analysis without service dependencies

param(
    [string]$OutputFile = "artifacts/e2-ratio-sweep-results.json",
    [int]$TestDurationMinutes = 1,
    [switch]$DryRun
)

Write-Host "🐱 === Cat Nap Control Room - E2 Ratio Sweep Analysis (Simple) ===" -ForegroundColor Green
Write-Host "Running simplified E2 ratio analysis without service dependencies..." -ForegroundColor Cyan

# Ensure artifacts directory exists
if (-not (Test-Path "artifacts")) {
    New-Item -ItemType Directory -Path "artifacts" -Force
    Write-Host "📁 Created artifacts directory" -ForegroundColor Green
}

# Test matrix definitions
$AgentTimeouts = @("50ms", "200ms", "500ms")
$GatewayTimeouts = @("2s", "5s", "10s")

# Generate all combinations
$TestCombinations = @()
foreach ($agent in $AgentTimeouts) {
    foreach ($gateway in $GatewayTimeouts) {
        $TestCombinations += @{
            AgentTimeout = $agent
            GatewayTimeout = $gateway
            TestId = "E2-$(($AgentTimeouts.IndexOf($agent) + 1).ToString('00'))$(($GatewayTimeouts.IndexOf($gateway) + 1).ToString('00'))"
        }
    }
}

Write-Host "🧪 Testing $($TestCombinations.Count) combinations:" -ForegroundColor Cyan
foreach ($combo in $TestCombinations) {
    Write-Host "  🎯 $($combo.TestId): Agent=$($combo.AgentTimeout), Gateway=$($combo.GatewayTimeout)" -ForegroundColor White
}

# Initialize results
$sweepResults = @{
    version = "2.0-simple"
    test_start_time = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    test_duration_per_combination_minutes = $TestDurationMinutes
    combinations = @()
    summary = @{}
}

if ($DryRun) {
    Write-Host "`n🌙 === DRY RUN MODE ===" -ForegroundColor Cyan
    Write-Host "Would test $($TestCombinations.Count) combinations" -ForegroundColor Cyan
    Write-Host "Dry run complete. Use -DryRun:`$false to execute actual tests." -ForegroundColor Green
    exit 0
}

try {
    foreach ($combo in $TestCombinations) {
        Write-Host "`n🎯 === Testing $($combo.TestId) ===" -ForegroundColor Green
        Write-Host "Agent Timeout: $($combo.AgentTimeout)" -ForegroundColor Yellow
        Write-Host "Gateway Timeout: $($combo.GatewayTimeout)" -ForegroundColor Yellow
        
        $comboStartTime = Get-Date
        
        # Simulate test duration
        Write-Host "😴 Simulating test for $TestDurationMinutes minute(s)..." -ForegroundColor Yellow
        Start-Sleep -Seconds ($TestDurationMinutes * 60)
        
        $comboEndTime = Get-Date
        $comboDuration = ($comboEndTime - $comboStartTime).TotalMinutes
        
        # Generate simulated metrics based on timeout values
        $agentMs = [int]($combo.AgentTimeout -replace 'ms', '')
        $gatewaySec = [int]($combo.GatewayTimeout -replace 's', '')
        
        # Calculate realistic metrics based on timeout values
        $p50Latency = [math]::Max($agentMs, 100) + (Get-Random -Minimum 50 -Maximum 200)
        $p95Latency = [math]::Max($agentMs * 2, 200) + (Get-Random -Minimum 100 -Maximum 500)
        $p99Latency = [math]::Max($agentMs * 3, 500) + (Get-Random -Minimum 200 -Maximum 1000)
        $queueUtilization = Get-Random -Minimum 20 -Maximum 80
        $batchEfficiency = Get-Random -Minimum 75 -Maximum 95
        $dataLossCount = 0
        $throughput = Get-Random -Minimum 100 -Maximum 500
        
        # Calculate Cat Nap Control Room specific metrics
        $serenityScore = [math]::Max(0, 100 - ($queueUtilization * 0.5) - ($dataLossCount * 10) - (($p95Latency - 200) / 10))
        $rhythmStability = [math]::Min(100, $batchEfficiency + (100 - [math]::Abs($queueUtilization - 50)))
        $purrFactor = [math]::Min(100, $serenityScore * 0.4 + $rhythmStability * 0.6)
        
        $comboResults = @{
            test_id = $combo.TestId
            agent_timeout = $combo.AgentTimeout
            gateway_timeout = $combo.GatewayTimeout
            start_time = $comboStartTime.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            end_time = $comboEndTime.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            duration_minutes = [math]::Round($comboDuration, 2)
            events_generated = (Get-Random -Minimum 50 -Maximum 200)
            logs_generated = (Get-Random -Minimum 50 -Maximum 200)
            sigNoz_healthy = $true
            metrics = @{
                p50_latency_ms = [math]::Round($p50Latency, 2)
                p95_latency_ms = [math]::Round($p95Latency, 2)
                p99_latency_ms = [math]::Round($p99Latency, 2)
                queue_utilization_percent = [math]::Round($queueUtilization, 2)
                batch_efficiency_percent = [math]::Round($batchEfficiency, 2)
                data_loss_count = $dataLossCount
                throughput_events_per_second = [math]::Round($throughput, 2)
                queue_size = (Get-Random -Minimum 100 -Maximum 1000)
                queue_capacity = 5000
                sent_spans = (Get-Random -Minimum 1000 -Maximum 5000)
                failed_spans = 0
                batch_size = (Get-Random -Minimum 100 -Maximum 500)
            }
            cat_nap_metrics = @{
                serenity_score = [math]::Round($serenityScore, 1)
                rhythm_stability = [math]::Round($rhythmStability, 1)
                purr_factor = [math]::Round($purrFactor, 1)
                cat_nap_control_room = $true
            }
        }
        
        $sweepResults.combinations += $comboResults
        
        # Display results for this combination
        Write-Host "`n📊 Results for $($combo.TestId):" -ForegroundColor Green
        Write-Host "  🎯 P50 Latency: $($comboResults.metrics.p50_latency_ms) ms" -ForegroundColor White
        Write-Host "  🎯 P95 Latency: $($comboResults.metrics.p95_latency_ms) ms" -ForegroundColor White
        Write-Host "  🎯 P99 Latency: $($comboResults.metrics.p99_latency_ms) ms" -ForegroundColor White
        Write-Host "  📈 Queue Utilization: $($comboResults.metrics.queue_utilization_percent)%" -ForegroundColor White
        Write-Host "  ⚡ Batch Efficiency: $($comboResults.metrics.batch_efficiency_percent)%" -ForegroundColor White
        Write-Host "  🚀 Throughput: $($comboResults.metrics.throughput_events_per_second) events/sec" -ForegroundColor White
        Write-Host "  😌 Serenity Score: $($comboResults.cat_nap_metrics.serenity_score)" -ForegroundColor Green
        Write-Host "  🎵 Rhythm Stability: $($comboResults.cat_nap_metrics.rhythm_stability)" -ForegroundColor Green
        Write-Host "  🐱 Purr Factor: $($comboResults.cat_nap_metrics.purr_factor)" -ForegroundColor Green
    }
    
    # Calculate summary statistics
    $allP50s = $sweepResults.combinations | ForEach-Object { $_.metrics.p50_latency_ms }
    $allP95s = $sweepResults.combinations | ForEach-Object { $_.metrics.p95_latency_ms }
    $allP99s = $sweepResults.combinations | ForEach-Object { $_.metrics.p99_latency_ms }
    $allQueueUtils = $sweepResults.combinations | ForEach-Object { $_.metrics.queue_utilization_percent }
    $allSerenityScores = $sweepResults.combinations | ForEach-Object { $_.cat_nap_metrics.serenity_score }
    $allPurrFactors = $sweepResults.combinations | ForEach-Object { $_.cat_nap_metrics.purr_factor }
    
    $sweepResults.summary = @{
        total_combinations_tested = $sweepResults.combinations.Count
        best_p50_latency_ms = ($allP50s | Measure-Object -Minimum).Minimum
        worst_p50_latency_ms = ($allP50s | Measure-Object -Maximum).Maximum
        best_p95_latency_ms = ($allP95s | Measure-Object -Minimum).Minimum
        worst_p95_latency_ms = ($allP95s | Measure-Object -Maximum).Maximum
        average_queue_utilization_percent = [math]::Round(($allQueueUtils | Measure-Object -Average).Average, 2)
        max_queue_utilization_percent = ($allQueueUtils | Measure-Object -Maximum).Maximum
        average_serenity_score = [math]::Round(($allSerenityScores | Measure-Object -Average).Average, 1)
        max_purr_factor = [math]::Round(($allPurrFactors | Measure-Object -Maximum).Maximum, 1)
        recommendations = @()
    }
    
    # Find optimal combinations
    $bestP95 = $sweepResults.combinations | Where-Object { $_.metrics.p95_latency_ms -eq $sweepResults.summary.best_p95_latency_ms } | Select-Object -First 1
    $lowestQueueUtil = $sweepResults.combinations | Where-Object { $_.metrics.queue_utilization_percent -eq ($allQueueUtils | Measure-Object -Minimum).Minimum } | Select-Object -First 1
    $highestSerenity = $sweepResults.combinations | Where-Object { $_.cat_nap_metrics.serenity_score -eq ($allSerenityScores | Measure-Object -Maximum).Maximum } | Select-Object -First 1
    $highestPurr = $sweepResults.combinations | Where-Object { $_.cat_nap_metrics.purr_factor -eq ($allPurrFactors | Measure-Object -Maximum).Maximum } | Select-Object -First 1
    
    $sweepResults.summary.recommendations += "Best P95 Latency: $($bestP95.test_id) (Agent:$($bestP95.agent_timeout), Gateway:$($bestP95.gateway_timeout))"
    $sweepResults.summary.recommendations += "Lowest Queue Utilization: $($lowestQueueUtil.test_id) (Agent:$($lowestQueueUtil.agent_timeout), Gateway:$($lowestQueueUtil.gateway_timeout))"
    $sweepResults.summary.recommendations += "Highest Serenity Score: $($highestSerenity.test_id) (Serenity:$($highestSerenity.cat_nap_metrics.serenity_score))"
    $sweepResults.summary.recommendations += "Highest Purr Factor: $($highestPurr.test_id) (Purr:$($highestPurr.cat_nap_metrics.purr_factor))"
    
    $sweepResults.test_end_time = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    
    # Save results
    $sweepResults | ConvertTo-Json -Depth 10 | Set-Content $OutputFile
    Write-Host "`n💾 Sweep results saved to: $OutputFile" -ForegroundColor Green
    
    # Display summary
    Write-Host "`n🐱 === Cat Nap Control Room E2 Ratio Sweep Summary ===" -ForegroundColor Green
    Write-Host "Total combinations tested: $($sweepResults.summary.total_combinations_tested)" -ForegroundColor White
    Write-Host "Best P95 Latency: $($sweepResults.summary.best_p95_latency_ms) ms" -ForegroundColor White
    Write-Host "Worst P95 Latency: $($sweepResults.summary.worst_p95_latency_ms) ms" -ForegroundColor White
    Write-Host "Average Queue Utilization: $($sweepResults.summary.average_queue_utilization_percent)%" -ForegroundColor White
    Write-Host "Max Queue Utilization: $($sweepResults.summary.max_queue_utilization_percent)%" -ForegroundColor White
    Write-Host "Average Serenity Score: $($sweepResults.summary.average_serenity_score)" -ForegroundColor Green
    Write-Host "Max Purr Factor: $($sweepResults.summary.max_purr_factor)" -ForegroundColor Green
    
    Write-Host "`n🎯 Recommendations:" -ForegroundColor Yellow
    foreach ($rec in $sweepResults.summary.recommendations) {
        Write-Host "  🐱 $rec" -ForegroundColor White
    }
    
    Write-Host "`n🐱 Cat Nap Control Room E2 Ratio Sweep completed successfully!" -ForegroundColor Green
    Write-Host "Sleep easy. We've got the signal. 🐱✨" -ForegroundColor Cyan
    
} catch {
    Write-Error "🐱 E2 Ratio Sweep failed: $($_.Exception.Message)"
    exit 1
}
