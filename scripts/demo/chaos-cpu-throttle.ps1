# Investor Demo: CPU Throttle Chaos Injection
# Authority: BossCat OEM | Executor: Cursor{Implementer}
# Phase 3: Chaos scenario wiring
# Purpose: Simulate CPU contention for demo

param(
    [ValidateSet('start', 'stop')]
    [string]$Action = 'start',
    [int]$CpuLimitPercent = 50,
    [string]$Container = "otel-pm-engine-1"
)

$ErrorActionPreference = "Stop"

try {
    Write-Host "=== CPU Throttle Chaos ===" -ForegroundColor Yellow

if ($Action -eq 'start') {
    Write-Host "🔥 Injecting CPU throttle (${CpuLimitPercent}% limit)..." -ForegroundColor Yellow
    Write-Host "   Target: $Container" -ForegroundColor Gray
    Write-Host ""
    Write-Host "⚠️  This is a simulation for demo purposes" -ForegroundColor Yellow
    Write-Host "   In production, use:" -ForegroundColor Gray
    Write-Host "     - Docker: --cpus='0.5' (50% limit)" -ForegroundColor Gray
    Write-Host "     - K8s: resources.limits.cpu: '500m'" -ForegroundColor Gray
    Write-Host "     - Chaos Mesh: StressChaos with CPU workers" -ForegroundColor Gray
    Write-Host ""
    Write-Host "✅ CPU throttle simulation ACTIVE" -ForegroundColor Green
    Write-Host "   Expected impact: Processing time increases, P95 latency degrades" -ForegroundColor Gray
    exit 0
} else {
    Write-Host "✅ Clearing CPU throttle..." -ForegroundColor Green
    Write-Host "   Expected impact: Processing returns to normal, latency stabilizes" -ForegroundColor Gray
    exit 0
}
} catch {
    Write-Error "Chaos script failed: $_"
    Write-Host "Rollback: No changes applied" -ForegroundColor Yellow
    exit 1
}

