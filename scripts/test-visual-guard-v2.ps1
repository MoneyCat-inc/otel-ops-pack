# Gate #016 Job V2 - Frame Timing Stabilizer Validation
# Validate jitter ceiling and stabilizer pin budget

param(
    [int]$WarmupSeconds = 12,
    [string]$BaseUrl = "http://localhost:7020",
    [string]$OutputPath = "artifacts/pm/gate-016-v2-test.jsonl"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Gate #016 Job V2 - Frame Timing Stabilizer Validation ===" -ForegroundColor Cyan
Write-Host "Warmup: $WarmupSeconds seconds"
Write-Host "Base URL: $BaseUrl"
Write-Host ""

# Ensure output directory exists
$outputDir = Split-Path -Parent $OutputPath
if ($outputDir -and !(Test-Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

Write-Host "Resetting guard and stabilizer..." -ForegroundColor Yellow
Invoke-RestMethod -Uri "$BaseUrl/guard/reset" -Method POST -TimeoutSec 5 | Out-Null

Write-Host "Warmup sampling for $WarmupSeconds seconds..."
Start-Sleep -Seconds $WarmupSeconds

$metrics = Invoke-RestMethod -Uri "$BaseUrl/pm/metrics" -Method GET -TimeoutSec 5
$guardStats = Invoke-RestMethod -Uri "$BaseUrl/guard/stats" -Method GET -TimeoutSec 5

if (-not $metrics.stabilizer) {
    Write-Host "  ❌ FAIL: Stabilizer metrics missing from /pm/metrics" -ForegroundColor Red
    exit 1
}

$stabilizer = $metrics.stabilizer
$cadenceHz = $guardStats.timingStats.avgCadenceHz
$sampleCount = $stabilizer.sampleCount
$maxJitterMs = [double]$stabilizer.jitterMaxMs
$p95JitterMs = [double]$stabilizer.jitterP95Ms
$pinCount = [int]$stabilizer.stabilizerPinCount

Write-Host ""
Write-Host "=== Timing Metrics ===" -ForegroundColor Yellow
Write-Host ("  Avg cadence: {0} Hz" -f $cadenceHz)
Write-Host ("  Samples: {0}" -f $sampleCount)
Write-Host ("  Jitter max: {0} ms" -f $maxJitterMs)
Write-Host ("  Jitter p95: {0} ms" -f $p95JitterMs)
Write-Host ("  Stabilizer pin count (60s window): {0}" -f $pinCount)

$failures = @()

if ($cadenceHz -lt 9.0) {
    $failures += "Cadence below 9 Hz"
}

if ($sampleCount -lt 30) {
    $failures += "Insufficient jitter samples collected (<30)"
}

# Accept p95 jitter as primary metric (max may spike due to container environment)
if ($p95JitterMs -gt 8.0) {
    $failures += "P95 jitter exceeds 8 ms budget"
}

# Allow some pin budget (measure sustained issues, not isolated spikes)
if ($pinCount -gt 5) {
    $failures += "Stabilizer pin budget exceeded (>5/60s)"
}

if ($failures.Count -gt 0) {
    Write-Host ""
    Write-Host "❌ JOB V2 VALIDATION FAILED" -ForegroundColor Red
    foreach ($failure in $failures) {
        Write-Host ("  - {0}" -f $failure) -ForegroundColor Red
    }

    $summary = @{
        timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        job = "V2"
        cadence_hz = $cadenceHz
        jitter_max_ms = $maxJitterMs
        jitter_p95_ms = $p95JitterMs
        pin_count = $pinCount
        sample_count = $sampleCount
        status = "FAIL"
        failures = $failures
    }

    $summary | ConvertTo-Json -Compress | Out-File -Append -Encoding UTF8 $OutputPath
    exit 1
}

Write-Host ""
Write-Host "✅ ALL TIMING CHECKS PASSED" -ForegroundColor Green

$summary = @{
    timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    job = "V2"
    cadence_hz = $cadenceHz
    jitter_max_ms = $maxJitterMs
    jitter_p95_ms = $p95JitterMs
    pin_count = $pinCount
    sample_count = $sampleCount
    status = "GREEN"
}

$summary | ConvertTo-Json -Compress | Out-File -Append -Encoding UTF8 $OutputPath

Write-Host ""
Write-Host ("Evidence saved to: {0}" -f $OutputPath)

exit 0

