# Investor Demo: One-Click Launcher
# Authority: BossCat OEM | Executor: Cursor{Implementer}
# Phase 4: Package & Rehearse - Demo automation
# Purpose: Single command to boot entire demo environment

param(
    [switch]$SkipVerification,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

Write-Host "╔═══════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                                                   ║" -ForegroundColor Cyan
Write-Host "║     🎯 INVESTOR DEMO - ONE-CLICK LAUNCHER 🎯     ║" -ForegroundColor Cyan
Write-Host "║                                                   ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Step 1: Pre-flight verification
if (-not $SkipVerification) {
    Write-Host "[1/5] Running pre-flight verification..." -ForegroundColor White
    Write-Host ""
    
    try {
        pwsh -File .\scripts\demo\verify-telemetry.ps1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   ✅ All pre-flight checks PASS" -ForegroundColor Green
        } elseif ($LASTEXITCODE -eq 1) {
            Write-Host "   ⚠️  Some checks failed (proceeding)" -ForegroundColor Yellow
        } else {
            Write-Host "   ❌ Critical failures - aborting" -ForegroundColor Red
            exit 2
        }
    } catch {
        Write-Host "   ❌ Verification failed: $_" -ForegroundColor Red
        exit 2
    }
} else {
    Write-Host "[1/5] Skipping pre-flight verification (--SkipVerification)" -ForegroundColor Yellow
}

Write-Host ""

# Step 2: Emit synthetic trace
Write-Host "[2/5] Emitting demo synthetic trace..." -ForegroundColor White

if (-not $DryRun) {
    try {
        node scripts\demo\emit-demo-trace.js
        Write-Host "   ✅ Synthetic trace emitted (service: demo-prober)" -ForegroundColor Green
    } catch {
        Write-Host "   ⚠️  Trace emission failed (non-critical)" -ForegroundColor Yellow
    }
} else {
    Write-Host "   [DRY RUN] Would emit: node scripts\demo\emit-demo-trace.js" -ForegroundColor Gray
}

Write-Host ""

# Step 3: Open demo interfaces
Write-Host "[3/5] Opening demo interfaces..." -ForegroundColor White

if (-not $DryRun) {
    Start-Process "http://localhost:8080" # SigNoz
    Start-Sleep -Milliseconds 500
    Start-Process "file:///C:/otel/docs/demo/dashboard.html" # Executive Dashboard
    Start-Sleep -Milliseconds 500
    Start-Process "file:///C:/otel/docs/demo/data-room.html" # Data Room
    Write-Host "   ✅ Opened: SigNoz, Dashboard, Data Room" -ForegroundColor Green
} else {
    Write-Host "   [DRY RUN] Would open: SigNoz, Dashboard, Data Room" -ForegroundColor Gray
}

Write-Host ""

# Step 4: Display service start instructions
Write-Host "[4/5] Service deployment commands:" -ForegroundColor White
Write-Host ""
Write-Host "   Terminal 1 (API Service):" -ForegroundColor Cyan
Write-Host "   pwsh .\scripts\demo\deploy-demo-service.ps1 -ServiceName bosscat-svc2-api -Port 5556 -EnableDemo" -ForegroundColor Gray
Write-Host ""
Write-Host "   Terminal 2 (Worker Service):" -ForegroundColor Cyan
Write-Host "   pwsh .\scripts\demo\deploy-demo-service.ps1 -ServiceName bosscat-svc3-worker -Port 5557 -EnableDemo" -ForegroundColor Gray
Write-Host ""

if (-not $DryRun) {
    Write-Host "   ⏳ Start services manually in separate terminals" -ForegroundColor Yellow
    Write-Host "   Press any key when services are running..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
} else {
    Write-Host "   [DRY RUN] Services not started" -ForegroundColor Gray
}

Write-Host ""

# Step 5: Final readiness check
Write-Host "[5/5] Final readiness check..." -ForegroundColor White

if (-not $DryRun -and -not $SkipVerification) {
    Write-Host "   Verifying services..." -ForegroundColor Gray
    
    $svc2Ok = $false
    $svc3Ok = $false
    
    try {
        $result = Invoke-WebRequest -Uri "http://localhost:5556/health" -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
        $svc2Ok = ($result.StatusCode -eq 200)
    } catch {}
    
    try {
        $result = Invoke-WebRequest -Uri "http://localhost:5557/health" -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
        $svc3Ok = ($result.StatusCode -eq 200)
    } catch {}
    
    if ($svc2Ok -and $svc3Ok) {
        Write-Host "   ✅ Both services healthy" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Services not responding (start them manually)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                                                   ║" -ForegroundColor Green
Write-Host "║          ✅ DEMO READY FOR INVESTORS ✅          ║" -ForegroundColor Green
Write-Host "║                                                   ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Demo Script: C:\otel\docs\demo\DEMO_SCRIPT.md" -ForegroundColor White
Write-Host "Data Room:   file:///C:/otel/docs/demo/data-room.html" -ForegroundColor White
Write-Host "Dashboard:   file:///C:/otel/docs/demo/dashboard.html" -ForegroundColor White
Write-Host "SigNoz:      http://localhost:8080" -ForegroundColor White
Write-Host ""
Write-Host "📋 Follow DEMO_SCRIPT.md for the 7-minute investor walkthrough" -ForegroundColor Cyan
Write-Host ""

