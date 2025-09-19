# quick-all-green.ps1
# One-liner quick "all green" check for OpenTelemetry Collector
# ASCII only, PowerShell 5.1 compatible

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "== Quick All-Green Check ==" -ForegroundColor Cyan

# Service status
$svc = Get-Service otelcol-contrib -ErrorAction SilentlyContinue
if ($null -eq $svc) {
  Write-Host "Service: NOT FOUND" -ForegroundColor Red
  exit 1
}
Write-Host "Service: $($svc.Status)" -ForegroundColor $(if ($svc.Status -eq 'Running') { 'Green' } else { 'Red' })

# Health endpoint
try {
  $health = Invoke-WebRequest -Uri 'http://127.0.0.1:13134/healthz' -TimeoutSec 5 | ConvertFrom-Json
  Write-Host "Health: $($health.status)" -ForegroundColor Green
} catch {
  Write-Host "Health: DOWN" -ForegroundColor Red
}

# Metrics endpoint
try {
  $metrics = Invoke-WebRequest -Uri 'http://127.0.0.1:8889/metrics' -TimeoutSec 5 -UseBasicParsing
  Write-Host "Metrics: HTTP $($metrics.StatusCode)" -ForegroundColor Green
} catch {
  Write-Host "Metrics: DOWN" -ForegroundColor Red
}

# Canary test
Write-Host "Canary:" -ForegroundColor Cyan
try {
  & 'C:\otel\canary-check-min.ps1'
} catch {
  Write-Host "Canary: FAILED" -ForegroundColor Red
}

Write-Host "== End Quick Check ==" -ForegroundColor Cyan
