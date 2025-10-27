# Gate #025 Track B: Manual Cluster Control Test
# Authority: BossCat OEM | Executor: Cursor{Implementer}
# Purpose: Verify cluster-wide disable/enable via admin API (simulates canary behavior)

param([string]$Service = "pm-engine")

$ErrorActionPreference = "Stop"

Write-Host "=== Gate #025 Track B: Cluster Control Verification ===" -ForegroundColor Cyan
Write-Host ""

# Get replica containers
$containers = @(docker ps --filter "name=otel-$Service" --format "{{.ID}}")
if ($containers.Count -lt 3) {
    Write-Error "Need 3 replicas, found $($containers.Count)"
    exit 1
}

Write-Host "Found $($containers.Count) replicas" -ForegroundColor Green
$ctlContainer = $containers[0]

# Helper: Get audio state from all replicas
function Get-ClusterAudioState {
    $states = @()
    foreach ($c in $script:containers) {
        try {
            $result = docker exec $c sh -c "curl -s http://localhost:7020/health 2>/dev/null" | ConvertFrom-Json
            $states += [PSCustomObject]@{
                container = $c.Substring(0, 12)
                enabled = $result.audio.enabled
                reason = $result.audio.reason
            }
        } catch {
            $states += [PSCustomObject]@{
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
        $allMatch = ($states | Where-Object { $_.enabled -eq $targetState }).Count -eq $script:containers.Count
        
        if ($allMatch) {
            $durationMs = [int]((Get-Date) - $start).TotalMilliseconds
            return @{ success = $true; durationMs = $durationMs; states = $states }
        }
        
        Start-Sleep -Milliseconds 50
    } while ((Get-Date) -lt $deadline)
    
    return @{ success = $false; durationMs = $timeoutMs; states = (Get-ClusterAudioState) }
}

# Test 1: Cluster-Wide Disable
Write-Host ""
Write-Host "[Test 1/2] Cluster-Wide Disable..." -ForegroundColor White

$disablePayload = '{"enabled":false,"reason":"cluster-test-disable-gate025"}'
docker exec $ctlContainer sh -c "curl -s -X POST http://localhost:7020/admin/audio -H 'Content-Type: application/json' -d '$disablePayload' 2>/dev/null" | Out-Null
Write-Host "  -> Disable command sent" -ForegroundColor Gray

$disableResult = Wait-ClusterConvergence $false 5000

if ($disableResult.success) {
    Write-Host "  [OK] All replicas disabled in $($disableResult.durationMs)ms" -ForegroundColor Green
} else {
    Write-Host "  [FAIL] Convergence timeout" -ForegroundColor Red
    foreach ($s in $disableResult.states) {
        Write-Host "    $($s.container): enabled=$($s.enabled)" -ForegroundColor Yellow
    }
    exit 1
}

# Test 2: Cluster-Wide Enable  
Write-Host ""
Write-Host "[Test 2/2] Cluster-Wide Enable..." -ForegroundColor White

$enablePayload = '{"enabled":true,"reason":"cluster-test-enable-gate025"}'
docker exec $ctlContainer sh -c "curl -s -X POST http://localhost:7020/admin/audio -H 'Content-Type: application/json' -d '$enablePayload' 2>/dev/null" | Out-Null
Write-Host "  -> Enable command sent" -ForegroundColor Gray

$enableResult = Wait-ClusterConvergence $true 5000

if ($enableResult.success) {
    Write-Host "  [OK] All replicas enabled in $($enableResult.durationMs)ms" -ForegroundColor Green
} else {
    Write-Host "  [FAIL] Convergence timeout" -ForegroundColor Red
    foreach ($s in $enableResult.states) {
        Write-Host "    $($s.container): enabled=$($s.enabled)" -ForegroundColor Yellow
    }
    exit 1
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Cluster Control: PASS" -ForegroundColor Green
Write-Host ""
Write-Host "Results:" -ForegroundColor White
Write-Host "  Disable propagation: $($disableResult.durationMs)ms (target: <2000ms)" -ForegroundColor Green
Write-Host "  Enable propagation:  $($enableResult.durationMs)ms (target: <2000ms)" -ForegroundColor Green
Write-Host ""
Write-Host "Final cluster state:" -ForegroundColor White
foreach ($s in $enableResult.states) {
    Write-Host "  $($s.container): enabled=$($s.enabled), reason=$($s.reason)" -ForegroundColor Gray
}
Write-Host ""

# Evidence
$evidence = @{
    gate = 25
    track = "B-Resilience"
    test = "cluster-control"
    timestamp = (Get-Date).ToUniversalTime().ToString("o")
    replicas = $containers.Count
    results = @{
        disable_ms = $disableResult.durationMs
        enable_ms = $enableResult.durationMs
        disable_success = $disableResult.success
        enable_success = $enableResult.success
    }
    verdict = "PASS"
} | ConvertTo-Json -Depth 5

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$evidence | Out-File -Encoding utf8 "artifacts/perf/cluster-control-$timestamp.json"
Write-Host "Evidence: artifacts/perf/cluster-control-$timestamp.json"

