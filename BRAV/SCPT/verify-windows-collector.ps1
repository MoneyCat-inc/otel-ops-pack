# BOSSCAT-022A: Gate Integration - Windows Collector Verification
# Purpose: Single-command verification for gate suite
# Authority: BossCat OEM | Executor: Cursor{Implementer}

$ErrorActionPreference = "Stop"

Write-Host "=== BOSSCAT-022A :: Gate Verification - Windows Collector ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Install/Repair (idempotent)
Write-Host "[Gate Check: WINCOLL-01] Running install/repair..." -ForegroundColor White
try {
  & .\scripts\windows\install-or-repair-otel-collector.ps1
  Write-Host "  ✓ WINCOLL-01: PASS (Service configured)" -ForegroundColor Green
} catch {
  Write-Error "WINCOLL-01 FAILED: $_"
  exit 1
}

Write-Host ""

# Step 2: Verify health + canary
Write-Host "[Gate Check: WINCOLL-02/03] Running verification..." -ForegroundColor White
try {
  & .\scripts\windows\verify-otel-collector.ps1
  Write-Host "  ✓ WINCOLL-02: PASS (OTLP reachability)" -ForegroundColor Green
  Write-Host "  ✓ WINCOLL-03: PASS (Canary event written)" -ForegroundColor Green
} catch {
  Write-Error "WINCOLL-02/03 FAILED: $_"
  exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ Gate Check: Windows Collector → PASS" -ForegroundColor Green
Write-Host ""

