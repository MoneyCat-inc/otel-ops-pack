# Post-Deploy Smoke Test
# CI/CD gate to prevent bad deploys from escaping

$ErrorActionPreference = 'Stop'

Write-Host "Running post-deploy smoke test..." -ForegroundColor Green

try {
    # Run green sheet status check
    Write-Host "  Checking service status..." -ForegroundColor Yellow
    & 'C:\otel\green-sheet.ps1'
    
    # Run canary check with proper error handling
    Write-Host "  Running canary check..." -ForegroundColor Yellow
    $p = Start-Process "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe" `
        -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', 'C:\otel\canary-check-min.ps1') `
        -PassThru -Wait
    
    if ($p.ExitCode -ne 0) { 
        throw "canary failed (exit code: $($p.ExitCode))" 
    }
    
    Write-Host "✅ SMOKE OK - All checks passed" -ForegroundColor Green
    exit 0
    
} catch {
    Write-Host "❌ SMOKE FAILED - $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
