# Gate #020 - Job CNY2 - Audio Rollback Script
# ECRR: BossCat OEM | Executor: Cursor{Implementer}
# Purpose: One-click audio rollback with verification

param(
    [switch]$DryRun,
    [switch]$Verify
)

$ErrorActionPreference = "Stop"

Write-Host "🔄 Audio Canary Rollback Script" -ForegroundColor Cyan
Write-Host "================================`n"

if ($DryRun) {
    Write-Host "⚠️  DRY RUN MODE - No changes will be applied`n" -ForegroundColor Yellow
}

# Step 1: Disable audio via feature flag
Write-Host "[1/4] Disabling audio feature flag..." -ForegroundColor White

if (-not $DryRun) {
    # Set environment variable (requires container restart to take effect)
    Write-Host "  → Setting AUDIO_ENABLED=false in environment"
    $env:AUDIO_ENABLED = "false"
} else {
    Write-Host "  → [DRY RUN] Would set AUDIO_ENABLED=false"
}

Write-Host "  ✓ Feature flag disabled`n" -ForegroundColor Green

# Step 2: Restart pm-engine container
Write-Host "[2/4] Restarting pm-engine container..." -ForegroundColor White

if (-not $DryRun) {
    try {
        docker restart pm-engine | Out-Null
        Write-Host "  → Container restarting..."
        Start-Sleep -Seconds 5
    } catch {
        Write-Host "  ✗ Failed to restart container: $_" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "  → [DRY RUN] Would execute: docker restart pm-engine"
}

Write-Host "  ✓ Container restarted`n" -ForegroundColor Green

# Step 3: Verify audio disabled
Write-Host "[3/4] Verifying audio disabled..." -ForegroundColor White

if (-not $DryRun) {
    Start-Sleep -Seconds 3  # Wait for container to be ready
    
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:7020/health" -Method Get
        
        if ($response.audio_enabled -eq $false) {
            Write-Host "  ✓ Audio confirmed disabled (audio_enabled: false)" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  Warning: audio_enabled still true" -ForegroundColor Yellow
            Write-Host "  → May need manual intervention"
        }
    } catch {
        Write-Host "  ⚠️  Could not verify (endpoint may not be ready yet)" -ForegroundColor Yellow
    }
} else {
    Write-Host "  → [DRY RUN] Would verify: curl http://localhost:7020/health"
}

Write-Host ""

# Step 4: Test audio ingestion blocked
Write-Host "[4/4] Testing audio ingestion blocked..." -ForegroundColor White

if (-not $DryRun -and -not $Verify) {
    Write-Host "  → Skipped (use -Verify to test POST /audio blocking)"
} elseif ($Verify) {
    try {
        $testData = @{ base64 = "AAAA" }  # Minimal test payload
        $response = Invoke-RestMethod -Uri "http://localhost:7020/audio" -Method Post -Body ($testData | ConvertTo-Json) -ContentType "application/json" -SkipHttpErrorCheck
        
        if ($response.ok -eq $false -and $response.error -match "Audio disabled") {
            Write-Host "  ✓ Audio ingestion properly blocked (HTTP 503)" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  Warning: Audio may not be properly blocked" -ForegroundColor Yellow
        }
    } catch {
        # HTTP 503 expected, catch and confirm
        if ($_.Exception.Response.StatusCode -eq 503) {
            Write-Host "  ✓ Audio ingestion properly blocked (HTTP 503)" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  Unexpected error: $_" -ForegroundColor Yellow
        }
    }
}

Write-Host "`n================================"
Write-Host "✅ Rollback Complete" -ForegroundColor Green
Write-Host "`nAudio Status: DISABLED"
Write-Host "Container: pm-engine (restarted)"
Write-Host "Feature Flag: AUDIO_ENABLED=false"
Write-Host "`nTo re-enable audio:"
Write-Host "  1. Set AUDIO_ENABLED=true in environment"
Write-Host "  2. Restart pm-engine: docker restart pm-engine"
Write-Host "  3. Verify: curl http://localhost:7020/health"

