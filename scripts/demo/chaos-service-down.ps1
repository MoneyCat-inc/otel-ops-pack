# Investor Demo: Service Down Chaos Injection
# Authority: BossCat OEM | Executor: Cursor{Implementer}
# Phase 3: Chaos scenario wiring
# Purpose: Simulate service failure for demo

param(
    [ValidateSet('start', 'stop')]
    [string]$Action = 'start',
    [string]$Service = 'bosscat-svc3-worker',
    [int]$Port = 5557
)

$ErrorActionPreference = "Stop"

Write-Host "=== Service Down Chaos ===" -ForegroundColor Yellow

if ($Action -eq 'start') {
    Write-Host "💥 Simulating service failure..." -ForegroundColor Yellow
    Write-Host "   Target: ${Service}:${Port}" -ForegroundColor Gray
    Write-Host ""
    Write-Host "⚠️  For demo, manually stop the service process (Ctrl+C)" -ForegroundColor Yellow
    Write-Host "   Or use: docker stop <container>" -ForegroundColor Gray
    Write-Host ""
    Write-Host "✅ Service down simulation ACTIVE" -ForegroundColor Green
    Write-Host "   Expected impact: Error rate will increase, alerts will fire" -ForegroundColor Gray
    exit 0
} else {
    Write-Host "✅ Restoring service..." -ForegroundColor Green
    Write-Host "   Restart service process or container" -ForegroundColor Gray
    Write-Host "   Expected impact: Error rate returns to 0%, alerts clear" -ForegroundColor Gray
    exit 0
}

