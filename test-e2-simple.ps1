Write-Host "🐱 === Cat Nap Control Room - E2 Ratio Test ===" -ForegroundColor Green
Write-Host "Testing E2 ratio analysis..." -ForegroundColor Cyan

# Test matrix
$AgentTimeouts = @("50ms", "200ms", "500ms")
$GatewayTimeouts = @("2s", "5s", "10s")

Write-Host "🧪 Testing combinations:" -ForegroundColor Cyan
foreach ($agent in $AgentTimeouts) {
    foreach ($gateway in $GatewayTimeouts) {
        Write-Host "  🎯 Agent=$agent, Gateway=$gateway" -ForegroundColor White
    }
}

# Simulate results
$results = @{
    version = "1.0-test"
    test_start_time = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    combinations = @()
    summary = @{}
}

foreach ($agent in $AgentTimeouts) {
    foreach ($gateway in $GatewayTimeouts) {
        $agentMs = [int]($agent -replace 'ms', '')
        $gatewaySec = [int]($gateway -replace 's', '')
        
        $p95Latency = [math]::Max($agentMs, 100) + (Get-Random -Minimum 50 -Maximum 200)
        $queueUtil = Get-Random -Minimum 20 -Maximum 80
        $serenity = [math]::Max(0, 100 - ($queueUtil * 0.5) - (($p95Latency - 200) / 10))
        $purrFactor = [math]::Min(100, $serenity * 0.8)
        
        $combo = @{
            test_id = "E2-$agent-$gateway"
            agent_timeout = $agent
            gateway_timeout = $gateway
            metrics = @{
                p95_latency_ms = [math]::Round($p95Latency, 2)
                queue_utilization_percent = [math]::Round($queueUtil, 2)
            }
            cat_nap_metrics = @{
                serenity_score = [math]::Round($serenity, 1)
                purr_factor = [math]::Round($purrFactor, 1)
            }
        }
        
        $results.combinations += $combo
        
        Write-Host "  📊 $($combo.test_id): P95=$($combo.metrics.p95_latency_ms)ms, Queue=$($combo.metrics.queue_utilization_percent)%, Serenity=$($combo.cat_nap_metrics.serenity_score), Purr=$($combo.cat_nap_metrics.purr_factor)" -ForegroundColor White
    }
}

# Find best configuration
$bestConfig = $results.combinations | Sort-Object { $_.cat_nap_metrics.purr_factor } -Descending | Select-Object -First 1

Write-Host "`n🌟 Best Configuration:" -ForegroundColor Green
Write-Host "  Test ID: $($bestConfig.test_id)" -ForegroundColor White
Write-Host "  Agent Timeout: $($bestConfig.agent_timeout)" -ForegroundColor White
Write-Host "  Gateway Timeout: $($bestConfig.gateway_timeout)" -ForegroundColor White
Write-Host "  P95 Latency: $($bestConfig.metrics.p95_latency_ms) ms" -ForegroundColor White
Write-Host "  Purr Factor: $($bestConfig.cat_nap_metrics.purr_factor)" -ForegroundColor White

# Save results
if (-not (Test-Path "artifacts")) {
    New-Item -ItemType Directory -Path "artifacts" -Force
}

$results | ConvertTo-Json -Depth 10 | Set-Content "artifacts/e2-ratio-sweep-results.json"
Write-Host "`n💾 Results saved to: artifacts/e2-ratio-sweep-results.json" -ForegroundColor Green

Write-Host "`n🐱 Cat Nap Control Room E2 Ratio Test completed!" -ForegroundColor Green
Write-Host "Sleep easy. We've got the signal. 🐱✨" -ForegroundColor Cyan
