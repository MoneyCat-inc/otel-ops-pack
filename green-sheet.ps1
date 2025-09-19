# green-sheet.ps1
param(
  [string] $Service   = 'otelcol-contrib',
  [string] $HealthUrl = 'http://127.0.0.1:13134/healthz',
  [string] $MetricsUrl = 'http://127.0.0.1:8889/metrics'
)
$ErrorActionPreference = 'SilentlyContinue'

Write-Host "== OTel quick green sheet ==" -ForegroundColor Cyan

$svc = Get-Service $Service
"Service: $($svc.Status)"
"Path:    $((Get-CimInstance Win32_Service -Filter "Name='$Service'").PathName)"

try { 
  $h = Invoke-WebRequest -Uri $HealthUrl -TimeoutSec 5 | ConvertFrom-Json
  "Health:  $($h.status) (uptime $($h.uptime))"
} catch { "Health:  DOWN" }

try {
  $m = Invoke-WebRequest -Uri $MetricsUrl -TimeoutSec 5 -UseBasicParsing
  $lines = ($m.Content -split "`n") | Where-Object { $_ -match 'otelcol_receiver_accepted_log_records' }
  "Metrics: $($lines.Count) lines for accepted_log_records"
} catch { "Metrics: DOWN" }

# Optional: quick canary
try { & 'C:\otel\canary-check-min.ps1' } catch { }
