# Pre-merge ECRR Hook
# Triggers BossCat verification when critical paths change

param(
    [string[]]$ChangedFiles = @()
)

$CriticalPaths = @(
    "synthetic/**/*.py",
    "scripts/**/*.ps1", 
    "scripts/**/*.ts",
    "docs/BossCat/**/*.md",
    "config.yaml"
)

Write-Host "🐾 BossCat Pre-merge ECRR Hook" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan

$TriggerRequired = $false
$TriggerPaths = @()

foreach ($file in $ChangedFiles) {
    foreach ($pattern in $CriticalPaths) {
        if ($file -like $pattern) {
            $TriggerRequired = $true
            $TriggerPaths += $file
            break
        }
    }
}

if ($TriggerRequired) {
    Write-Host "⚠️  Critical paths modified - BossCat verification required:" -ForegroundColor Yellow
    foreach ($path in $TriggerPaths) {
        Write-Host "   - $path" -ForegroundColor White
    }
    Write-Host ""
    Write-Host "🔧 Running BossCat gate verification..." -ForegroundColor Cyan
    
    # Set environment for verification
    $env:SIGNOZ_URL = "http://localhost:8080"
    $env:SERVICE_NAME = "synthetic-windows-check"
    
    # Run verification suite
    try {
        python synthetic/send_synthetic_otel_simple.py
        .\scripts\verify-synthetic-ingestion-enhanced.ps1
        pnpm playwright test scripts/signoz-snapshot.spec.ts
        
        Write-Host "✅ BossCat verification completed successfully" -ForegroundColor Green
        Write-Host "🚪 Ready for gate signal" -ForegroundColor Cyan
    } catch {
        Write-Host "❌ BossCat verification failed: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "✅ No critical paths modified - BossCat verification not required" -ForegroundColor Green
}

Write-Host ""
Write-Host "ECRR Protocol: Examine → Clean → Report → Recovery" -ForegroundColor Gray
