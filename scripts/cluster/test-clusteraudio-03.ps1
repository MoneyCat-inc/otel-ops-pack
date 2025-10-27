# Gate #025 Track B: CLUSTERAUDIO-03 Verification
# Authority: BossCat OEM | Executor: Cursor{Implementer}
# Purpose: Verify canary breach/reset cluster-wide control with 3 replicas

param(
    [string]$Service = "pm-engine"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Gate #025 Track B: CLUSTERAUDIO-03 Verification ===" -ForegroundColor Cyan
Write-Host ""

# Get replica containers
$containers = @(docker ps --filter "name=otel-$Service" --format "{{.ID}}")
if ($containers.Count -lt 3) {
    Write-Error "Need 3 replicas, found $($containers.Count). Deploy: docker compose up -d --scale $Service=3"
    exit 1
}

Write-Host "Found $($containers.Count) replicas" -ForegroundColor Green
$ctlContainer = $containers[0]

# Helper: Get audio state from all replicas
function Get-ClusterAudioState {
    $states = @()
    foreach ($c in $containers) {
        try {
            $result = docker exec $c sh -c "curl -s http://localhost:7020/health 2>/dev/null" | ConvertFrom-Json
            $states += @{
                container = $c.Substring(0, 12)
                enabled = $result.audio.enabled
                reason = $result.audio.reason
            }
        } catch {
            $states += @{
                container = $c.Substring(0, 12)
                enabled = $null
                reason = "ERROR"
            }
        }
    }
    return $states
}

# Helper: Wait for cluster convergence
function Wait-ClusterConvergence([bool]$targetState, [int]$timeoutMs = 5000) {
    $start = Get-Date
    $deadline = $start.AddMilliseconds($timeoutMs)
    
    do {
        $states = Get-ClusterAudioState
        $allMatch = ($states | Where-Object { $_.enabled -eq $targetState }).Count -eq $containers.Count
        
        if ($allMatch) {
            $durationMs = [int]((Get-Date) - $start).TotalMilliseconds
            return @{ success = $true; durationMs = $durationMs }
        }
        
        Start-Sleep -Milliseconds 50
    } while ((Get-Date) -lt $deadline)
    
    return @{ success = $false; durationMs = $timeoutMs }
}

# Test 1: Canary Breach (Disable Cluster-Wide)
Write-Host ""
Write-Host "[Test 1/2] Canary Breach: Triggering halt..." -ForegroundColor White

try {
    $haltPayload = '{"reason":"clusteraudio-03-test"}'
    $result = docker exec $ctlContainer sh -c "curl -s -X POST http://localhost:7020/canary/halt -H 'Content-Type: application/json' -d '$haltPayload' 2>/dev/null"
    Write-Host "  -> Canary halt initiated" -ForegroundColor Gray
} catch {
    Write-Error "Failed to trigger canary halt: $_"
    exit 1
}

# Wait for cluster to converge to disabled
Write-Host "  -> Waiting for cluster convergence (disabled)..." -ForegroundColor Gray
$disableResult = Wait-ClusterConvergence $false 5000

if ($disableResult.success) {
    Write-Host "  [OK] All replicas disabled in $($disableResult.durationMs)ms" -ForegroundColor Green
} else {
    Write-Host "  [FAIL] Cluster did not converge within timeout" -ForegroundColor Red
    $states = Get-ClusterAudioState
    foreach ($s in $states) {
        Write-Host "    Container $($s.container): enabled=$($s.enabled)" -ForegroundColor Yellow
    }
    exit 1
}

# Test 2: Canary Reset (Enable Cluster-Wide)  
Write-Host ""
Write-Host "[Test 2/2] Canary Reset: Triggering reset..." -ForegroundColor White

try {
    $result = docker exec $ctlContainer sh -c "curl -s -X POST http://localhost:7020/canary/reset -H 'Content-Type: application/json' 2>/dev/null" | ConvertFrom-Json
    Write-Host "  -> Canary reset initiated" -ForegroundColor Gray
} catch {
    Write-Error "Failed to trigger canary reset: $_"
    exit 1
}

# Wait for cluster to converge to enabled
Write-Host "  -> Waiting for cluster convergence (enabled)..." -ForegroundColor Gray
$enableResult = Wait-ClusterConvergence $true 5000

if ($enableResult.success) {
    Write-Host "  [OK] All replicas enabled in $($enableResult.durationMs)ms" -ForegroundColor Green
} else {
    Write-Host "  [FAIL] Cluster did not converge within timeout" -ForegroundColor Red
    $states = Get-ClusterAudioState
    foreach ($s in $states) {
        Write-Host "    Container $($s.container): enabled=$($s.enabled)" -ForegroundColor Yellow
    }
    exit 1
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CLUSTERAUDIO-03: PASS" -ForegroundColor Green
Write-Host ""
Write-Host "Results:" -ForegroundColor White
Write-Host "  Breach->Disable: $($disableResult.durationMs)ms (target: <2000ms) $(if ($disableResult.durationMs -lt 2000) { '[OK]' } else { '[FAIL]' })" -ForegroundColor $(if ($disableResult.durationMs -lt 2000) { 'Green' } else { 'Red' })
Write-Host "  Reset->Enable:   $($enableResult.durationMs)ms (target: <2000ms) $(if ($enableResult.durationMs -lt 2000) { '[OK]' } else { '[FAIL]' })" -ForegroundColor $(if ($enableResult.durationMs -lt 2000) { 'Green' } else { 'Red' })
Write-Host ""
Write-Host "Final cluster state:" -ForegroundColor White
$finalStates = Get-ClusterAudioState
foreach ($s in $finalStates) {
    Write-Host "  $($s.container): enabled=$($s.enabled), reason=$($s.reason)" -ForegroundColor Gray
}
Write-Host ""

# Generate evidence
$evidence = @{
    gate = 25
    track = "B-Resilience"
    test = "CLUSTERAUDIO-03"
    timestamp = (Get-Date).ToUniversalTime().ToString("o")
    replicas = $containers.Count
    results = @{
        breach_to_disable_ms = $disableResult.durationMs
        reset_to_enable_ms = $enableResult.durationMs
        breach_success = $disableResult.success
        reset_success = $enableResult.success
    }
    pass_criteria = @{
        convergence_time_ms_target = 2000
        breach_pass = $disableResult.durationMs -lt 2000
        reset_pass = $enableResult.durationMs -lt 2000
        overall_pass = ($disableResult.success -and $enableResult.success -and $disableResult.durationMs -lt 2000 -and $enableResult.durationMs -lt 2000)
    }
} | ConvertTo-Json -Depth 5

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$evidencePath = "artifacts/perf/clusteraudio-03-$timestamp.json"
$evidence | Out-File -Encoding utf8 $evidencePath

Write-Host "Evidence: $evidencePath" -ForegroundColor White
Write-Host ""

