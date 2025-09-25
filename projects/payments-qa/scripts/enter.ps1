# Project shell for 'payments-qa' — scopes OTEL vars to shared Windows Collector
param([switch]$EmitCanary)

$env:OTEL_SERVICE_NAME = 'payments-qa'
$env:OTEL_RESOURCE_ATTRIBUTES = 'service.name=payments-qa,project=payments-qa,dataset=resonai_analytics'
$env:OTEL_EXPORTER_OTLP_ENDPOINT = 'http://localhost:5318'
$env:OTEL_EXPORTER_OTLP_PROTOCOL = 'http/protobuf'
$env:OTEL_LOGS_EXPORTER = 'otlp'
$env:OTEL_TRACES_EXPORTER = 'none'
$env:OTEL_METRICS_EXPORTER = 'none'

Write-Host "Project 'payments-qa' environment loaded." -ForegroundColor Green
Write-Host "OTEL → Windows Collector (5318) → SigNoz (14317)." -ForegroundColor DarkGreen
Write-Host "Logs dir: C:\otel\projects\payments-qa\logs" -ForegroundColor DarkCyan

if ($EmitCanary) {
  $logDir = 'C:\otel\projects\payments-qa\logs'
  if (-not (Test-Path -LiteralPath $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
  $logPath = Join-Path $logDir 'canary.log'
  $entry = ('{0} sample canary from {1}' -f (Get-Date).ToString('o'), 'payments-qa')
  Add-Content -LiteralPath $logPath -Value $entry -Encoding UTF8
  Write-Host "Emitted canary: $logPath" -ForegroundColor Yellow
  Write-Host "In SigNoz → Logs, filter: service.name = payments-qa AND log.file.path contains '/projects/payments-qa/logs'" -ForegroundColor Yellow
}
