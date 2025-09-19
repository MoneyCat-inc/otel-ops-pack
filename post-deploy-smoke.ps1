# Post-Deploy Smoke Test
# CI/CD gate to prevent bad deploys from escaping

$ErrorActionPreference = 'Stop'

Write-Host "Running post-deploy smoke test..." -ForegroundColor Green

try {
    # Run unified health check
    Write-Host "  Running health check..." -ForegroundColor Yellow
    $p = Start-Process "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe" `
        -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', 'C:\otel\health-check.ps1', '-Mode', 'full') `
        -PassThru -Wait
    
    if ($p.ExitCode -ne 0) { 
        throw "health check failed (exit code: $($p.ExitCode))" 
    }
    
    # Optional Kafka smoke test (non-blocking)
    Write-Host "  Checking Kafka connectivity (optional)..." -ForegroundColor Yellow
    $kafkaP = Start-Process "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe" `
        -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', 'C:\otel\kafka-smoke.ps1') `
        -PassThru -Wait
    if ($kafkaP.ExitCode -eq 0) {
        Write-Host "  ✅ Kafka reachable" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  Kafka unreachable (optional)" -ForegroundColor Yellow
    }
    
    Write-Host "✅ SMOKE OK - All checks passed" -ForegroundColor Green
    exit 0
    
} catch {
    Write-Host "❌ SMOKE FAILED - $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
