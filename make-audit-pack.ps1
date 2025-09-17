# make-audit-pack.ps1
# Audit evidence pack generator for CAB/Change records
# ASCII only, PowerShell 5.1 compatible

$ErrorActionPreference = "Stop"
$root = "C:\otel"
$logd = Join-Path $root "logs"
$outd = Join-Path $root "audit"
$now = (Get-Date).ToString("yyyyMMdd_HHmmss")
$staged = Join-Path $outd "stage_$now"
$zip = Join-Path $outd "audit-pack_$now.zip"

New-Item -ItemType Directory -Force -Path $logd,$outd,$staged | Out-Null

Write-Host "Generating audit evidence pack..." -ForegroundColor Cyan
Write-Host "Stage directory: $staged" -ForegroundColor White
Write-Host "Output ZIP: $zip" -ForegroundColor White

# 1) Service + recovery
Write-Host "Collecting service information..." -ForegroundColor Yellow
Get-Service otelcol-contrib | Out-File (Join-Path $staged "service.txt")
(Get-CimInstance Win32_Service -Filter "Name='otelcol-contrib'").PathName | Out-File (Join-Path $staged "service-path.txt")
sc.exe qfailure otelcol-contrib | Out-File (Join-Path $staged "service-recovery.txt")

# 2) Ports
Write-Host "Collecting port bindings..." -ForegroundColor Yellow
cmd /c netstat -ano | findstr /R ":(5317|5318|8889|13134)\s" > (Join-Path $staged "ports.txt")

# 3) Health + metrics
Write-Host "Collecting health and metrics..." -ForegroundColor Yellow
try { (Invoke-WebRequest "http://127.0.0.1:13134" -TimeoutSec 5).Content | Out-File (Join-Path $staged "health.json") } catch { "unavailable" | Out-File (Join-Path $staged "health.json") }
try {
  $m = (Invoke-WebRequest "http://127.0.0.1:8889/metrics" -TimeoutSec 5).Content -split "`n"
  $m | Out-File (Join-Path $staged "metrics.txt")
  ($m | ? {$_ -match 'otelcol_receiver_accepted_log_records'}) | Out-File (Join-Path $staged "metrics.accepted.txt")
  ($m | ? {$_ -match 'exporter_send_failed_log_records'}) | Out-File (Join-Path $staged "metrics.exporter_failed.txt")
} catch { "unavailable" | Out-File (Join-Path $staged "metrics.txt") }

# 4) Scheduled tasks
Write-Host "Collecting scheduled task information..." -ForegroundColor Yellow
$tasks = 'otel_canary_10m','otel_drift_guard_15m','otel_queue_watch_5m','otel_config_backup_daily'
$tasks | ForEach-Object {
  try {
    Get-ScheduledTask -TaskName $_ | Out-File (Join-Path $staged "task.$_.txt")
    Get-ScheduledTaskInfo -TaskName $_ | Out-File (Join-Path $staged "task.$_.info.txt")
  } catch { "not found" | Out-File (Join-Path $staged "task.$_.txt") }
}

# 5) Config + hashes
Write-Host "Collecting configuration files..." -ForegroundColor Yellow
Copy-Item -Force (Join-Path $root "config.yaml") (Join-Path $staged "config.yaml") -ErrorAction SilentlyContinue
Copy-Item -Force (Join-Path $root "config-hardened-plus.yaml") (Join-Path $staged "config-hardened-plus.yaml") -ErrorAction SilentlyContinue
Get-FileHash (Join-Path $staged "config.yaml") -Algorithm SHA256 -ErrorAction SilentlyContinue |
  Out-File (Join-Path $staged "config.yaml.sha256.txt")

# 6) Logs (recent)
Write-Host "Collecting recent logs..." -ForegroundColor Yellow
Get-ChildItem $logd -Filter *.last.* -ErrorAction SilentlyContinue | ForEach-Object {
  Copy-Item -Force $_.FullName $staged
}

# 7) Package + hash
Write-Host "Creating audit package..." -ForegroundColor Yellow
Compress-Archive -Force -Path (Join-Path $staged '*') -DestinationPath $zip
$h = Get-FileHash $zip -Algorithm SHA256
$h | Tee-Object -FilePath (Join-Path $outd "audit-pack_$now.sha256.txt")

Write-Host ""
Write-Host "Audit pack created successfully!" -ForegroundColor Green
Write-Host "ZIP file: $zip" -ForegroundColor White
Write-Host "SHA256: $($h.Hash)" -ForegroundColor White
Write-Host ""
Write-Host "Copy both the ZIP path and SHA256 hash to your change ticket/CAB record." -ForegroundColor Cyan

# Return values for automation
$zip
$h.Hash
