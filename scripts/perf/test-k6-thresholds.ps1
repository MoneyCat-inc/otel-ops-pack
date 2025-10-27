# Gate #026 Track B: Test k6 Thresholds Locally
# Authority: BossCat OEM | Executor: Cursor{Implementer}
# Purpose: Simulate k6 run and generate evidence

param(
    [string]$TargetUrl = "http://localhost:8080/api/v1/version",
    [int]$Iterations = 50
)

$ErrorActionPreference = "Continue"

Write-Host "=== k6 Threshold Simulation ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Note: This simulates k6 behavior for evidence generation" -ForegroundColor Gray
Write-Host "Actual k6 runs in CI via grafana/k6-action" -ForegroundColor Gray
Write-Host ""

# Ensure artifacts directory
New-Item -ItemType Directory -Path "artifacts" -Force | Out-Null

# Run simple load test
$results = @()
$errors = 0

Write-Host "[1/3] Running $Iterations requests..." -ForegroundColor White

for ($i = 1; $i -le $Iterations; $i++) {
    $start = Get-Date
    try {
        $response = Invoke-WebRequest -Uri $TargetUrl -TimeoutSec 2 -UseBasicParsing
        $durationMs = [int]((Get-Date) - $start).TotalMilliseconds
        $results += [PSCustomObject]@{
            iteration = $i
            duration_ms = $durationMs
            status_code = $response.StatusCode
            error = $false
        }
    } catch {
        $durationMs = [int]((Get-Date) - $start).TotalMilliseconds
        $results += [PSCustomObject]@{
            iteration = $i
            duration_ms = $durationMs
            status_code = 0
            error = $true
        }
        $errors++
    }
    
    if ($i % 10 -eq 0) {
        Write-Host "  Progress: $i/$Iterations" -ForegroundColor Gray
    }
    
    Start-Sleep -Milliseconds 100
}

# Calculate statistics
$successResults = $results | Where-Object { -not $_.error }
$sorted = $successResults | Sort-Object duration_ms

$p50_idx = [int]($sorted.Count * 0.50)
$p95_idx = [int]($sorted.Count * 0.95)
$p99_idx = [int]($sorted.Count * 0.99)

$stats = @{
    p50 = if ($p50_idx -lt $sorted.Count) { $sorted[$p50_idx].duration_ms } else { 0 }
    p95 = if ($p95_idx -lt $sorted.Count) { $sorted[$p95_idx].duration_ms } else { 0 }
    p99 = if ($p99_idx -lt $sorted.Count) { $sorted[$p99_idx].duration_ms } else { 0 }
    min = ($sorted | Measure-Object duration_ms -Minimum).Minimum
    max = ($sorted | Measure-Object duration_ms -Maximum).Maximum
    avg = ($sorted | Measure-Object duration_ms -Average).Average
    error_rate = $errors / $Iterations
    total_requests = $Iterations
    successful_requests = $successResults.Count
}

# Check thresholds (Gate #026 targets)
$thresholds = @{
    p50_target = 900
    p95_target = 1200
    p99_target = 1500
    error_rate_target = 0.01
}

$p50_pass = $stats.p50 -lt $thresholds.p50_target
$p95_pass = $stats.p95 -lt $thresholds.p95_target
$p99_pass = $stats.p99 -lt $thresholds.p99_target
$error_rate_pass = $stats.error_rate -lt $thresholds.error_rate_target

$overall_pass = $p50_pass -and $p95_pass -and $p99_pass -and $error_rate_pass

Write-Host ""
Write-Host "[2/3] Analyzing results..." -ForegroundColor White
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "k6 Threshold Check Results" -ForegroundColor White
Write-Host ""
Write-Host "Latency:" -ForegroundColor White
Write-Host "  p50: $($stats.p50)ms (threshold: <$($thresholds.p50_target)ms) $(if ($p50_pass) { '[PASS]' } else { '[FAIL]' })" -ForegroundColor $(if ($p50_pass) { 'Green' } else { 'Red' })
Write-Host "  p95: $($stats.p95)ms (threshold: <$($thresholds.p95_target)ms) $(if ($p95_pass) { '[PASS]' } else { '[FAIL]' })" -ForegroundColor $(if ($p95_pass) { 'Green' } else { 'Red' })
Write-Host "  p99: $($stats.p99)ms (threshold: <$($thresholds.p99_target)ms) $(if ($p99_pass) { '[PASS]' } else { '[FAIL]' })" -ForegroundColor $(if ($p99_pass) { 'Green' } else { 'Red' })
Write-Host ""
Write-Host "Error Rate: $(($stats.error_rate * 100).ToString('0.00'))% (threshold: <$($thresholds.error_rate_target * 100)%) $(if ($error_rate_pass) { '[PASS]' } else { '[FAIL]' })" -ForegroundColor $(if ($error_rate_pass) { 'Green' } else { 'Red' })
Write-Host ""
Write-Host "Additional Stats:" -ForegroundColor Gray
Write-Host "  Min: $($stats.min)ms" -ForegroundColor Gray
Write-Host "  Max: $($stats.max)ms" -ForegroundColor Gray
Write-Host "  Avg: $([int]$stats.avg)ms" -ForegroundColor Gray
Write-Host "  Success: $($stats.successful_requests)/$($stats.total_requests)" -ForegroundColor Gray
Write-Host ""
Write-Host "Overall: $(if ($overall_pass) { 'PASS' } else { 'FAIL' })" -ForegroundColor $(if ($overall_pass) { 'Green' } else { 'Red' })
Write-Host ""

# Generate evidence
Write-Host "[3/3] Generating evidence..." -ForegroundColor White

$evidence = @{
    gate = 26
    track = "B-CI-Performance-Gates"
    timestamp = (Get-Date).ToUniversalTime().ToString("o")
    test_type = "k6-threshold-simulation"
    target_url = $TargetUrl
    iterations = $Iterations
    statistics = $stats
    thresholds = $thresholds
    threshold_results = @{
        p50_pass = $p50_pass
        p95_pass = $p95_pass
        p99_pass = $p99_pass
        error_rate_pass = $error_rate_pass
        overall_pass = $overall_pass
    }
    verdict = if ($overall_pass) { "PASS" } else { "FAIL" }
} | ConvertTo-Json -Depth 5

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$evidencePath = "artifacts/k6-simulation-$timestamp.json"
$evidence | Out-File -Encoding utf8 $evidencePath

Write-Host "  [OK] Evidence saved: $evidencePath" -ForegroundColor Green
Write-Host ""

# Exit with k6-style behavior (non-zero on threshold breach)
if (-not $overall_pass) {
    Write-Host "Thresholds breached - exiting with code 99" -ForegroundColor Red
    exit 99
}

exit 0

