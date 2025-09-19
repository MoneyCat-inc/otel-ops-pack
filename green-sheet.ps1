# green-sheet.ps1 — quick OTEL status summary
$ErrorActionPreference = "SilentlyContinue"

Write-Host "== Service status ==" -ForegroundColor Cyan
Get-Service otelcol-contrib | Format-Table -Auto

Write-Host "`n== Process ==" -ForegroundColor Cyan
Get-Process -Name otelcol-contrib -ErrorAction SilentlyContinue | Format-Table -Auto

Write-Host "`n== Health endpoint ==" -ForegroundColor Cyan
try {
  $r = Invoke-WebRequest -Uri "http://127.0.0.1:13134" -TimeoutSec 5
  $r.Content | Write-Output
} catch {
  Write-Host "Health endpoint not responding: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`n== Listening ports (otel-ish) ==" -ForegroundColor Cyan
netstat -ano | Select-String -Pattern "13134|4317|4318|55679"

Write-Host "`nDone." -ForegroundColor Green
