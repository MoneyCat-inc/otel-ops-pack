# SigNoz Pipeline Verification Script
# Run this after restarting the Windows collector service
# Updated with progress indicators for better user experience

# Import progress indicators module
$progressScript = if (Test-Path ".\scripts\progress-indicators.ps1") {
    ".\scripts\progress-indicators.ps1"
} else {
    ".\BRAV\SCPT\progress-indicators.ps1"
}
. $progressScript

Write-Host "=== SigNoz Pipeline Verification ===" -ForegroundColor Green

# 1. Check service status
Write-Host "`n1. Checking Windows collector service..." -ForegroundColor Yellow
$spinnerJob = Start-SpinnerJob -Message "Checking service status..." -UpdateIntervalMs 150
sc.exe query otelcol-contrib
Stop-SpinnerJob -Job $spinnerJob

# 2. Emit fresh canaries
Write-Host "`n2. Emitting fresh canary logs..." -ForegroundColor Yellow
$spinnerJob = Start-SpinnerJob -Message "Creating canary logs..." -UpdateIntervalMs 150
Write-EventLog -LogName Application -Source SigNozTest -EventId 999 -EntryType Information -Message "SigNoz pipeline test event from Codex - $(Get-Date)"

$timestamp = (Get-Date).ToString('o')
$canary = '{"event":"signoz_canary","severity":"ERROR","message":"SigNoz file canary log","synthetic_id":"pipeline-check","timestamp":"' + $timestamp + '"}'
Add-Content -Path 'C:/logs/app.json' -Value $canary
Stop-SpinnerJob -Job $spinnerJob

Write-Host "✓ Windows Event Log entry created" -ForegroundColor Green
Write-Host "✓ File log entry created" -ForegroundColor Green

# 3. Wait for processing
Write-Host "`n3. Waiting for log processing (30 seconds)..." -ForegroundColor Yellow
$spinnerJob = Start-SpinnerJob -Message "Waiting for log processing..." -UpdateIntervalMs 150
Start-Sleep -Seconds 30
Stop-SpinnerJob -Job $spinnerJob

# 4. Query SigNoz for canaries
Write-Host "`n4. Querying SigNoz for canary logs..." -ForegroundColor Yellow

$query = @"
SELECT fromUnixTimestamp64Milli(timestamp) AS ts, JSONExtractString(body, 'message') AS message
FROM signoz_logs.distributed_logs_v2
WHERE JSONExtractString(body, 'message') ILIKE '%SigNoz pipeline test%'
ORDER BY timestamp DESC
LIMIT 3
"@

Write-Host "Windows Event Log canaries:" -ForegroundColor Cyan
$spinnerJob = Start-SpinnerJob -Message "Querying ClickHouse for canaries..." -UpdateIntervalMs 150
$result1 = docker exec signoz-clickhouse clickhouse-client --query "$query"
Stop-SpinnerJob -Job $spinnerJob
if ($result1) {
    Write-Host $result1 -ForegroundColor Green
} else {
    Write-Host "No Windows Event Log canaries found yet. Try waiting longer or check SigNoz UI." -ForegroundColor Yellow
}

$query2 = @"
SELECT fromUnixTimestamp64Milli(timestamp) AS ts, body
FROM signoz_logs.distributed_logs_v2
WHERE body ILIKE '%signoz_canary%'
ORDER BY timestamp DESC
LIMIT 3
"@

Write-Host "`nFile log canaries:" -ForegroundColor Cyan
$spinnerJob = Start-SpinnerJob -Message "Querying ClickHouse for file canaries..." -UpdateIntervalMs 150
$result2 = docker exec signoz-clickhouse clickhouse-client --query "$query2"
Stop-SpinnerJob -Job $spinnerJob
if ($result2) {
    Write-Host $result2 -ForegroundColor Green
} else {
    Write-Host "No file log canaries found yet. Try waiting longer or check SigNoz UI." -ForegroundColor Yellow
}

# 5. Provide UI instructions
Write-Host "`n5. SigNoz UI Verification:" -ForegroundColor Yellow
Write-Host "Open http://localhost:8080 → Logs" -ForegroundColor Cyan
Write-Host "Add filter: message contains 'SigNoz pipeline test'" -ForegroundColor Cyan
Write-Host "Or filter: log.file.path contains 'C:/logs/app.json'" -ForegroundColor Cyan

# 6. Alternative verification
Write-Host "`n6. Alternative verification commands:" -ForegroundColor Yellow
Write-Host "Check recent Windows Event Log:" -ForegroundColor Cyan
Write-Host "Get-WinEvent -FilterHashtable @{LogName='Application'; ID=999} -MaxEvents 1" -ForegroundColor White
Write-Host "Check file log:" -ForegroundColor Cyan
Write-Host "Get-Content 'C:/logs/app.json' -Tail 1" -ForegroundColor White

Write-Host "`n=== Verification Complete ===" -ForegroundColor Green