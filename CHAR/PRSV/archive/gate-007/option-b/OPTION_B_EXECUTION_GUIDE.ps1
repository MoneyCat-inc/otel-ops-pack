# 🐾 Option B Execution Guide - Windows Collector Restore
# **RUN THIS IN ELEVATED POWERSHELL (Administrator)**

Write-Host "=== OPTION B EXECUTION SEQUENCE ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "🔐 ELEVATED SESSION REQUIRED" -ForegroundColor Yellow
Write-Host "   Right-click PowerShell → Run as Administrator" -ForegroundColor Gray
Write-Host ""

# Navigate to repo
Set-Location "C:\otel"
Write-Host "📂 Working Directory: C:\otel" -ForegroundColor Green
Write-Host ""

#──────────────────────────────────────────────────────────────
# STEP 1: Align + Restart Collector
#──────────────────────────────────────────────────────────────
Write-Host "STEP 1: Align + Restart Windows Collector" -ForegroundColor Cyan
Write-Host "Command: pwsh -File scripts/align-windows-collector-config.ps1 -Restart" -ForegroundColor Yellow
Write-Host ""

pwsh -File scripts/align-windows-collector-config.ps1 -Restart

Write-Host ""
Write-Host "✓ Step 1 Complete" -ForegroundColor Green
Write-Host ""

#──────────────────────────────────────────────────────────────
# STEP 2: Verify Service Running
#──────────────────────────────────────────────────────────────
Write-Host "STEP 2: Verify Service Status" -ForegroundColor Cyan
Write-Host "Command: sc query otelcol-contrib" -ForegroundColor Yellow
Write-Host ""

sc query otelcol-contrib

Write-Host ""
Write-Host "Expected: STATE = 4 RUNNING" -ForegroundColor Yellow
Write-Host ""

# Verification check
$svcStatus = Get-Service -Name otelcol-contrib -ErrorAction SilentlyContinue
if ($svcStatus.Status -eq 'Running') {
    Write-Host "✅ SERVICE RUNNING - Proceeding..." -ForegroundColor Green
} else {
    Write-Host "❌ SERVICE NOT RUNNING - Check Windows Event Log" -ForegroundColor Red
    Write-Host "   Event Log: Applications and Services Logs → OpenTelemetry-Collector" -ForegroundColor Gray
    Write-Host ""
    Write-Host "⚠️  STOPPING EXECUTION - Service must be running before Option B test" -ForegroundColor Red
    exit 1
}

Write-Host ""

#──────────────────────────────────────────────────────────────
# STEP 3: Warm-Up (Optional)
#──────────────────────────────────────────────────────────────
Write-Host "STEP 3: Warm-Up Test (Optional)" -ForegroundColor Cyan
Write-Host "Command: pnpm emit:full" -ForegroundColor Yellow
Write-Host "Purpose: Confirms OTLP HTTP 5318 connectivity" -ForegroundColor Gray
Write-Host ""

pnpm emit:full

Write-Host ""
Write-Host "✓ Step 3 Complete" -ForegroundColor Green
Write-Host ""

#──────────────────────────────────────────────────────────────
# STEP 4: Execute Option B with P95 Guard
#──────────────────────────────────────────────────────────────
Write-Host "STEP 4: Execute Option B E2E with P95 Latency Guard" -ForegroundColor Cyan
Write-Host "Command: pnpm otel:optionB" -ForegroundColor Yellow
Write-Host ""
Write-Host "This will:" -ForegroundColor Gray
Write-Host "  - Verify service + ports + SigNoz" -ForegroundColor Gray
Write-Host "  - Run 9 synthetic traces and measure P95 latency" -ForegroundColor Gray
Write-Host "  - Generate fresh artifacts:" -ForegroundColor Gray
Write-Host "    • DELT/ARTF/windows-otel-status.json" -ForegroundColor Gray
Write-Host "    • DELT/ARTF/otel-canary-<timestamp>.json" -ForegroundColor Gray
Write-Host "    • docs/BossCat/reports/ECRR_<timestamp>_SSOT.json" -ForegroundColor Gray
Write-Host "    • docs/BossCat/reports/ECRR_<timestamp>_SSOT.md" -ForegroundColor Gray
Write-Host ""

pnpm otel:optionB

Write-Host ""
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ OPTION B E2E: PASS" -ForegroundColor Green
} else {
    Write-Host "⚠️  OPTION B E2E: HOLD (exit code $LASTEXITCODE)" -ForegroundColor Yellow
    Write-Host "   Review artifacts for details" -ForegroundColor Gray
}

Write-Host ""
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ EXECUTION COMPLETE" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Next Steps:" -ForegroundColor Yellow
Write-Host "   1. Review artifacts in DELT/ARTF/ and docs/BossCat/reports/" -ForegroundColor Gray
Write-Host "   2. Report to Cursor{Implementer}: 'Option B run complete'" -ForegroundColor Gray
Write-Host "   3. Agent will verify all 6 pass conditions" -ForegroundColor Gray
Write-Host "   4. Agent will post final gate status" -ForegroundColor Gray
Write-Host ""
Write-Host "🐾 Standing by for verification..." -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan

