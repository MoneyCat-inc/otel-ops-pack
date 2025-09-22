# Analyze E2 Ratio Sweep Results
# Ranks candidates based on performance criteria

param(
    [string]$ResultsFile = "artifacts/e2-ratio-sweep-results.json"
)

Write-Host "=== E2 Ratio Sweep Analysis ===" -ForegroundColor Green

if (-not (Test-Path $ResultsFile)) {
    Write-Error "Results file not found: $ResultsFile"
    exit 1
}

# Load results
$results = Get-Content $ResultsFile | ConvertFrom-Json

Write-Host "Loaded results for $($results.combinations.Count) combinations" -ForegroundColor Yellow

# Filter candidates that meet criteria
$candidates = $results.combinations | Where-Object { 
    $_.metrics.queue_utilization_percent -lt 70 -and 
    $_.metrics.data_loss_count -eq 0 
}

Write-Host "`nCandidates meeting criteria (queue < 70%, no data loss): $($candidates.Count)" -ForegroundColor Green

# Rank by p95 latency, then p99 latency
$ranked = $candidates | Sort-Object { $_.metrics.p95_latency_ms }, { $_.metrics.p99_latency_ms }

Write-Host "`n=== RANKED CANDIDATES ===" -ForegroundColor Green
Write-Host "Rank | Test ID | Agent  | Gateway | P95(ms) | P99(ms) | Queue% | Batch% | Notes" -ForegroundColor Yellow
Write-Host "-----|---------|--------|---------|---------|---------|--------|--------|------" -ForegroundColor Yellow

$rank = 1
foreach ($candidate in $ranked) {
    $agent = $candidate.agent_timeout.PadRight(6)
    $gateway = $candidate.gateway_timeout.PadRight(6)
    $p95 = $candidate.metrics.p95_latency_ms.ToString().PadLeft(7)
    $p99 = $candidate.metrics.p99_latency_ms.ToString().PadLeft(7)
    $queue = $candidate.metrics.queue_utilization_percent.ToString().PadLeft(6)
    $batch = $candidate.metrics.batch_efficiency_percent.ToString().PadLeft(6)
    $notes = $candidate.notes.Substring(0, [Math]::Min(20, $candidate.notes.Length))
    
    Write-Host "$($rank.ToString().PadLeft(4)) | $($candidate.test_id.PadRight(7)) | $agent | $gateway | $p95 | $p99 | $queue | $batch | $notes" -ForegroundColor White
    $rank++
}

# Find optimal configuration
$optimal = $ranked | Where-Object { 
    $_.metrics.p95_latency_ms -lt 2000 -and 
    $_.metrics.batch_efficiency_percent -ge 90 
} | Select-Object -First 1

if ($optimal) {
    Write-Host "`n=== OPTIMAL CONFIGURATION ===" -ForegroundColor Green
    Write-Host "Test ID: $($optimal.test_id)" -ForegroundColor Yellow
    Write-Host "Agent Timeout: $($optimal.agent_timeout)" -ForegroundColor White
    Write-Host "Gateway Timeout: $($optimal.gateway_timeout)" -ForegroundColor White
    Write-Host "P95 Latency: $($optimal.metrics.p95_latency_ms) ms" -ForegroundColor White
    Write-Host "P99 Latency: $($optimal.metrics.p99_latency_ms) ms" -ForegroundColor White
    Write-Host "Queue Utilization: $($optimal.metrics.queue_utilization_percent)%" -ForegroundColor White
    Write-Host "Batch Efficiency: $($optimal.metrics.batch_efficiency_percent)%" -ForegroundColor White
    Write-Host "Notes: $($optimal.notes)" -ForegroundColor White
} else {
    Write-Host "`nNo configuration meets all optimal criteria" -ForegroundColor Yellow
    Write-Host "Best available:" -ForegroundColor Yellow
    $best = $ranked | Select-Object -First 1
    Write-Host "Test ID: $($best.test_id) - P95: $($best.metrics.p95_latency_ms)ms, Batch: $($best.metrics.batch_efficiency_percent)%" -ForegroundColor White
}

# Summary statistics
Write-Host "`n=== SUMMARY STATISTICS ===" -ForegroundColor Green
$p95Values = $candidates | ForEach-Object { $_.metrics.p95_latency_ms }
$queueValues = $candidates | ForEach-Object { $_.metrics.queue_utilization_percent }
$batchValues = $candidates | ForEach-Object { $_.metrics.batch_efficiency_percent }

Write-Host "P95 Latency Range: $($p95Values | Measure-Object -Minimum).Minimum - $($p95Values | Measure-Object -Maximum).Maximum ms" -ForegroundColor White
Write-Host "Queue Utilization Range: $($queueValues | Measure-Object -Minimum).Minimum - $($queueValues | Measure-Object -Maximum).Maximum%" -ForegroundColor White
Write-Host "Batch Efficiency Range: $($batchValues | Measure-Object -Minimum).Minimum - $($batchValues | Measure-Object -Maximum).Maximum%" -ForegroundColor White

Write-Host "`nAnalysis completed!" -ForegroundColor Green
