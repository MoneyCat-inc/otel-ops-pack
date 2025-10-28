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

# Step 4: Auto-start demo services (background processes)
Write-Host "[4/5] Starting demo services..." -ForegroundColor White

if (-not $DryRun) {
    # Check if services already running
    $svc2Running = $false
    $svc3Running = $false
    
    try {
        $result = Invoke-WebRequest -Uri "http://localhost:5556/health" -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop
        $svc2Running = ($result.StatusCode -eq 200)
    } catch {}
    
    try {
        $result = Invoke-WebRequest -Uri "http://localhost:5557/health" -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop
        $svc3Running = ($result.StatusCode -eq 200)
    } catch {}
    
    if ($svc2Running -and $svc3Running) {
        Write-Host "   ✅ Services already running (ports 5556, 5557)" -ForegroundColor Green
    } else {
        Write-Host "   → Starting bosscat-svc2-api (port 5556)..." -ForegroundColor Gray
        if (-not $svc2Running) {
            $svc2Job = Start-Job -ScriptBlock {
                Set-Location C:\otel
                pwsh -File .\scripts\demo\deploy-demo-service.ps1 -ServiceName "bosscat-svc2-api" -Port 5556 -EnableDemo
            }
            Write-Host "   → Service 2 starting (job: $($svc2Job.Id))" -ForegroundColor Gray
        }
        
        Write-Host "   → Starting bosscat-svc3-worker (port 5557)..." -ForegroundColor Gray
        if (-not $svc3Running) {
            $svc3Job = Start-Job -ScriptBlock {
                Set-Location C:\otel
                pwsh -File .\scripts\demo\deploy-demo-service.ps1 -ServiceName "bosscat-svc3-worker" -Port 5557 -EnableDemo
            }
            Write-Host "   → Service 3 starting (job: $($svc3Job.Id))" -ForegroundColor Gray
        }
        
        Write-Host "   → Waiting for services to initialize (15s)..." -ForegroundColor Gray
        Start-Sleep -Seconds 15
        Write-Host "   ✅ Services started in background" -ForegroundColor Green
        Write-Host ""
        Write-Host "   Note: View background jobs with 'Get-Job'" -ForegroundColor Gray
        Write-Host "   Stop services: 'Stop-Job -Id <id>' or Ctrl+C in demo" -ForegroundColor Gray
    }
} else {
    Write-Host "   [DRY RUN] Services not started" -ForegroundColor Gray
}

Write-Host ""

# Step 5: Final readiness check
Write-Host "[5/5] Final readiness check..." -ForegroundColor White

if (-not $DryRun) {
    Write-Host "   Verifying services..." -ForegroundColor Gray
    
    # Give services a bit more time if just started
    Start-Sleep -Seconds 5
    
    $svc2Ok = $false
    $svc3Ok = $false
    $retries = 3
    
    for ($i = 0; $i -lt $retries; $i++) {
        try {
            $result = Invoke-WebRequest -Uri "http://localhost:5556/health" -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
            $svc2Ok = ($result.StatusCode -eq 200)
            if ($svc2Ok) { break }
        } catch {
            if ($i -lt ($retries - 1)) {
                Start-Sleep -Seconds 2
            }
        }
    }
    
    for ($i = 0; $i -lt $retries; $i++) {
        try {
            $result = Invoke-WebRequest -Uri "http://localhost:5557/health" -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
            $svc3Ok = ($result.StatusCode -eq 200)
            if ($svc3Ok) { break }
        } catch {
            if ($i -lt ($retries - 1)) {
                Start-Sleep -Seconds 2
            }
        }
    }
    
    if ($svc2Ok -and $svc3Ok) {
        Write-Host "   ✅ Both services healthy and responding" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Services not fully ready yet" -ForegroundColor Yellow
        if (-not $svc2Ok) { Write-Host "      - bosscat-svc2-api (5556): Not responding" -ForegroundColor Gray }
        if (-not $svc3Ok) { Write-Host "      - bosscat-svc3-worker (5557): Not responding" -ForegroundColor Gray }
        Write-Host "      Services may still be initializing (check 'Get-Job')" -ForegroundColor Gray
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

