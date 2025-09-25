# Project shell for 'myproj2' — scopes OTEL vars to shared Windows Collector
param([switch]$EmitCanary)

$env:OTEL_SERVICE_NAME = 'myproj2'
$env:OTEL_RESOURCE_ATTRIBUTES = 'service.name=myproj2,project=myproj2,dataset=resonai_analytics'
$env:OTEL_EXPORTER_OTLP_ENDPOINT = 'http://localhost:5318'
$env:OTEL_EXPORTER_OTLP_PROTOCOL = 'http/protobuf'
$env:OTEL_LOGS_EXPORTER = 'otlp'
$env:OTEL_TRACES_EXPORTER = 'none'
$env:OTEL_METRICS_EXPORTER = 'none'

Write-Host "Project 'myproj2' environment loaded." -ForegroundColor Green
Write-Host "OTEL → Windows Collector (5318) → SigNoz (14317)." -ForegroundColor DarkGreen
Write-Host "Logs dir: C:\otel\projects\myproj2\logs" -ForegroundColor DarkCyan

if ($EmitCanary) {
  $logDir = 'C:\otel\projects\myproj2\logs'
  if (-not (Test-Path -LiteralPath $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
  $logPath = Join-Path $logDir 'canary.log'
  $entry = ('{0} sample canary from {1}' -f (Get-Date).ToString('o'), 'myproj2')
  Add-Content -LiteralPath $logPath -Value $entry -Encoding UTF8
  Write-Host "Emitted canary: $logPath" -ForegroundColor Yellow
  Write-Host "In SigNoz → Logs, filter: service.name = myproj2 AND log.file.path contains '/projects/myproj2/logs'" -ForegroundColor Yellow
}
