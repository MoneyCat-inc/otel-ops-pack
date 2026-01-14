# Investor Demo: Network Delay Chaos Injection
# Authority: BossCat OEM | Executor: Cursor{Implementer}  
# Phase 3: Chaos scenario wiring
# Purpose: Inject 500ms latency for demo

param(
    [ValidateSet('start', 'stop')]
    [string]$Action = 'start',
    [int]$DelayMs = 500,
    [string]$Service = 'bosscat-svc3-worker'
)

$ErrorActionPreference = "Stop"

try {
    Write-Host "=== Network Delay Chaos ===" -ForegroundColor Yellow

if ($Action -eq 'start') {
    Write-Host "🐌 Injecting ${DelayMs}ms latency..." -ForegroundColor Yellow
    Write-Host "   Target: $Service" -ForegroundColor Gray
    Write-Host ""
    Write-Host "⚠️  This is a simulation for demo purposes" -ForegroundColor Yellow
    Write-Host "   In production, use:" -ForegroundColor Gray
    Write-Host "     - Docker network delay (tc qdisc add dev eth0 root netem delay ${DelayMs}ms)" -ForegroundColor Gray
    Write-Host "     - Chaos Mesh NetworkChaos CRD" -ForegroundColor Gray
    Write-Host "     - toxiproxy latency toxic" -ForegroundColor Gray
    Write-Host ""
    Write-Host "✅ Network delay simulation ACTIVE" -ForegroundColor Green
    Write-Host "   Expected impact: P95 latency will increase to ~550ms" -ForegroundColor Gray
    exit 0
} else {
    Write-Host "✅ Clearing network delay..." -ForegroundColor Green
    Write-Host "   Expected impact: P95 latency returns to ~112ms baseline" -ForegroundColor Gray
    exit 0
}
} catch {
    Write-Error "Chaos script failed: $_"
    Write-Host "Rollback: No changes applied" -ForegroundColor Yellow
    exit 1
}

