# SigNoz Restart Script
# Quick restart of Windows Collector service

Write-Host "Restarting Windows Collector service..." -ForegroundColor Cyan

try {
    sc stop otelcol-contrib
    Start-Sleep -Seconds 2
    sc start otelcol-contrib
    Start-Sleep -Seconds 1
    sc query otelcol-contrib
    Write-Host "`n✅ Collector service restarted successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to restart collector service: $($_.Exception.Message)" -ForegroundColor Red
}
