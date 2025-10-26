# Gate #024 - Track 1: AudioSwitch Propagation Baseline
# Authority: Fubumaki + BossCat OEM | Executor: Cursor{Implementer}
# Purpose: Measure current cluster propagation performance (100 iterations)

param(
    [int]$Iterations = 100,
    [int]$Replicas = 3,
    [string]$Service = "pm-engine",
    [string]$OutputDir = "artifacts/perf"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Gate #024 Track 1: AudioSwitch Propagation Baseline ===" -ForegroundColor Cyan
Write-Host ""

# Ensure output directory exists
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

# Get replica containers
$containers = @(docker ps --filter "name=otel-$Service" --format "{{.ID}}")
if ($containers.Count -eq 0) {
    Write-Error "No running containers for $Service. Deploy cluster first: docker compose up -d --scale $Service=$Replicas"
    exit 1
}

Write-Host "Found $($containers.Count) replica(s)" -ForegroundColor Green
$ctlContainer = $containers[0]

# Helper: Get audio state
function Get-AudioState($cid) {
    try {
        $result = docker exec $cid sh -c "curl -s http://localhost:7020/health 2>/dev/null" | ConvertFrom-Json
        return $result.audio
    } catch {
        return $null
    }
}

# Helper: Toggle audio
function Toggle-Audio($cid, [bool]$enabled, $reason) {
    $enabledStr = if ($enabled) { "true" } else { "false" }
    $json = "{`"enabled`":$enabledStr,`"reason`":`"$reason`"}"
    try {
        docker exec $cid sh -c "curl -s -X POST http://localhost:7020/admin/audio -H 'Content-Type: application/json' -d '$json' 2>/dev/null" | Out-Null
    } catch {
        return $false
    }
    return $true
}

# Baseline measurements
$results = @()
$errors = 0

Write-Host "Running $Iterations iterations..." -ForegroundColor White
Write-Host ""

for ($i = 1; $i -le $Iterations; $i++) {
    $isDisable = ($i % 2) -eq 1
    $targetState = -not $isDisable
    $reason = if ($isDisable) { "baseline-disable-$i" } else { "baseline-enable-$i" }
    
    if ($i % 10 -eq 0) {
        Write-Host "  Progress: $i/$Iterations ($(($i/$Iterations*100).ToString('0'))%)" -ForegroundColor Gray
    }
    
    $start = Get-Date
    
    # Toggle via control container
    $toggleOk = Toggle-Audio $ctlContainer (-not $isDisable) $reason
    if (-not $toggleOk) {
        $errors++
        continue
    }
    
    # Wait for all replicas to synchronize
    $deadline = (Get-Date).AddSeconds(5)
    $allSynced = $false
    
    do {
        $synced = $true
        foreach ($c in $containers) {
            $state = Get-AudioState $c
            if ($null -eq $state -or $state.enabled -ne $targetState) {
                $synced = $false
                break
            }
        }
        if ($synced) {
            $allSynced = $true
            break
        }
        Start-Sleep -Milliseconds 50
    } while ((Get-Date) -lt $deadline)
    
    $durationMs = [int]((Get-Date) - $start).TotalMilliseconds
    
    if (-not $allSynced) {
        $errors++
    }
    
    $results += [PSCustomObject]@{
        iteration = $i
        operation = if ($isDisable) { "disable" } else { "enable" }
        duration_ms = $durationMs
        synced = $allSynced
        error = -not $allSynced
    }
}

# Calculate statistics
$successResults = $results | Where-Object { -not $_.error }
$disables = $successResults | Where-Object { $_.operation -eq "disable" }
$enables = $successResults | Where-Object { $_.operation -eq "enable" }

$stats = @{
    iterations = $Iterations
    errors = $errors
    error_rate = ($errors / $Iterations)
    all = @{
        p50 = ($successResults.duration_ms | Measure-Object -Average).Average
        p95 = ($successResults | Sort-Object duration_ms | Select-Object -Index ([int]($successResults.Count * 0.95))).duration_ms
        p99 = ($successResults | Sort-Object duration_ms | Select-Object -Index ([int]($successResults.Count * 0.99))).duration_ms
        min = ($successResults.duration_ms | Measure-Object -Minimum).Minimum
        max = ($successResults.duration_ms | Measure-Object -Maximum).Maximum
    }
    disable = @{
        p50 = ($disables.duration_ms | Measure-Object -Average).Average
        p95 = ($disables | Sort-Object duration_ms | Select-Object -Index ([int]($disables.Count * 0.95))).duration_ms
    }
    enable = @{
        p50 = ($enables.duration_ms | Measure-Object -Average).Average
        p95 = ($enables | Sort-Object duration_ms | Select-Object -Index ([int]($enables.Count * 0.95))).duration_ms
    }
}

# Generate evidence
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$evidence = @{
    gate = 24
    track = "performance"
    phase = "baseline"
    timestamp = (Get-Date).ToUniversalTime().ToString("o")
    configuration = @{
        iterations = $Iterations
        replicas = $containers.Count
        service = $Service
    }
    statistics = $stats
    target_criteria = @{
        p50_target_ms = 1000
        p95_target_ms = 1300
        error_rate_target = 0.01
    }
    pass_criteria = @{
        p50_pass = $stats.all.p50 -le 1000
        p95_pass = $stats.all.p95 -le 1300
        error_rate_pass = $stats.error_rate -lt 0.01
    }
} | ConvertTo-Json -Depth 8

$evidencePath = "$OutputDir/baseline-propagation-$timestamp.json"
$evidence | Out-File -Encoding utf8 $evidencePath

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ Baseline Measurement Complete" -ForegroundColor Green
Write-Host ""
Write-Host "Results ($Iterations iterations):" -ForegroundColor White
Write-Host "  p50: $([int]$stats.all.p50)ms (target: ≤1000ms) $(if ($stats.all.p50 -le 1000) { '✓' } else { '✗' })" -ForegroundColor $(if ($stats.all.p50 -le 1000) { 'Green' } else { 'Yellow' })
Write-Host "  p95: $([int]$stats.all.p95)ms (target: ≤1300ms) $(if ($stats.all.p95 -le 1300) { '✓' } else { '✗' })" -ForegroundColor $(if ($stats.all.p95 -le 1300) { 'Green' } else { 'Yellow' })
Write-Host "  Error rate: $(($stats.error_rate * 100).ToString('0.00'))% (target: <1%) $(if ($stats.error_rate -lt 0.01) { '✓' } else { '✗' })" -ForegroundColor $(if ($stats.error_rate -lt 0.01) { 'Green' } else { 'Yellow' })
Write-Host "  Min: $([int]$stats.all.min)ms" -ForegroundColor Gray
Write-Host "  Max: $([int]$stats.all.max)ms" -ForegroundColor Gray
Write-Host ""
Write-Host "Breakdown:" -ForegroundColor White
Write-Host "  Disable - p50: $([int]$stats.disable.p50)ms, p95: $([int]$stats.disable.p95)ms" -ForegroundColor Gray
Write-Host "  Enable  - p50: $([int]$stats.enable.p50)ms, p95: $([int]$stats.enable.p95)ms" -ForegroundColor Gray
Write-Host ""
Write-Host "Evidence: $evidencePath" -ForegroundColor White
Write-Host ""

