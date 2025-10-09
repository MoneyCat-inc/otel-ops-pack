# Monitor Windows Canary Alert Script
# Continuous monitoring for Windows canary alert system

param(
    [int]$DurationMinutes = 30,
    [int]$CheckIntervalSeconds = 60,
    [switch]$GenerateCanary,
    [switch]$StopCanary,
    [switch]$VerifyAlert
)

Write-Host "=== Windows Canary Alert Monitor ===" -ForegroundColor Green
Write-Host "Duration: $DurationMinutes minutes, Check interval: $CheckIntervalSeconds seconds" -ForegroundColor Yellow

$startTime = Get-Date
$endTime = $startTime.AddMinutes($DurationMinutes)
$logFile = "C:\logs\windows-canary-test.log"
$reportFile = "artifacts/canary-monitor-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"

# Ensure directories exist
if (-not (Test-Path "C:\logs")) {
    New-Item -ItemType Directory -Path "C:\logs" -Force
}
if (-not (Test-Path "artifacts")) {
    New-Item -ItemType Directory -Path "artifacts" -Force
}

$monitoringData = @{
    start_time = $startTime.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    duration_minutes = $DurationMinutes
    check_interval_seconds = $CheckIntervalSeconds
    canary_logs_generated = 0
    canary_logs_stopped = $false
    alert_triggered = $false
    checks_performed = @()
    signoz_ui_url = "http://localhost:8080"
    verification_queries = @(
        "log.file.path = 'C:/logs/windows-canary-test.log'",
        "body contains 'windows-canary'",
        "canary log count >= 1 in last 5 minutes"
    )
}

if ($GenerateCanary) {
    Write-Host "`n=== Generating Canary Logs ===" -ForegroundColor Yellow
    
    $logCount = 0
    while ((Get-Date) -lt $endTime) {
        $logEntry = @{
            timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            level = "INFO"
            message = "windows-canary monitoring log entry $logCount - $(Get-Date)"
            service = "canary-test"
            canary = "true"
            test_id = "canary-alert-monitoring"
            source = "windows-event-log"
            monitoring_session = "active"
        } | ConvertTo-Json -Compress
        
        Add-Content -Path $logFile -Value $logEntry
        $logCount++
        $monitoringData.canary_logs_generated = $logCount
        
        Write-Host "Generated canary log $logCount at $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Green
        
        Start-Sleep -Seconds $CheckIntervalSeconds
    }
    
    Write-Host "Generated $logCount canary logs over $DurationMinutes minutes" -ForegroundColor Green
}

if ($StopCanary) {
    Write-Host "`n=== Stopping Canary Generation ===" -ForegroundColor Yellow
    $monitoringData.canary_logs_stopped = $true
    Write-Host "Canary log generation stopped at $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Red
    Write-Host "Alert should trigger after 5 minutes of no canary logs" -ForegroundColor Yellow
}

if ($VerifyAlert) {
    Write-Host "`n=== Verifying Alert System ===" -ForegroundColor Yellow
    
    # Check if canary logs exist
    if (Test-Path $logFile) {
        $lastLogTime = (Get-Item $logFile).LastWriteTime
        $timeSinceLastLog = (Get-Date) - $lastLogTime
        
        Write-Host "Last canary log: $lastLogTime" -ForegroundColor Cyan
        Write-Host "Time since last log: $($timeSinceLastLog.TotalMinutes.ToString('F1')) minutes" -ForegroundColor Cyan
        
        if ($timeSinceLastLog.TotalMinutes -gt 5) {
            $monitoringData.alert_triggered = $true
            Write-Host "ALERT CONDITION: No canary logs for $($timeSinceLastLog.TotalMinutes.ToString('F1')) minutes" -ForegroundColor Red
        } else {
            Write-Host "Alert condition not met: Canary logs are recent" -ForegroundColor Green
        }
    } else {
        Write-Host "No canary log file found - Alert should be triggered" -ForegroundColor Red
        $monitoringData.alert_triggered = $true
    }
}

# Perform monitoring checks
$checkCount = 0
while ((Get-Date) -lt $endTime) {
    $checkCount++
    $currentTime = Get-Date
    
    $checkData = @{
        check_number = $checkCount
        timestamp = $currentTime.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        canary_log_file_exists = Test-Path $logFile
        last_log_time = if (Test-Path $logFile) { (Get-Item $logFile).LastWriteTime.ToString("yyyy-MM-ddTHH:mm:ss.fffZ") } else { $null }
        time_since_last_log_minutes = if (Test-Path $logFile) { ((Get-Date) - (Get-Item $logFile).LastWriteTime).TotalMinutes } else { $null }
        alert_condition_met = if (Test-Path $logFile) { ((Get-Date) - (Get-Item $logFile).LastWriteTime).TotalMinutes -gt 5 } else { $true }
    }
    
    $monitoringData.checks_performed += $checkData
    
    Write-Host "Check $checkCount at $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Cyan
    if ($checkData.alert_condition_met) {
        Write-Host "  ⚠️  ALERT CONDITION MET: No canary logs for $($checkData.time_since_last_log_minutes.ToString('F1')) minutes" -ForegroundColor Red
    } else {
        Write-Host "  ✅ Alert condition not met: Canary logs are recent" -ForegroundColor Green
    }
    
    Start-Sleep -Seconds $CheckIntervalSeconds
}

# Generate final report
$monitoringData.end_time = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
$monitoringData.total_checks = $checkCount
$monitoringData.final_status = if ($monitoringData.alert_triggered) { "ALERT_TRIGGERED" } else { "MONITORING_COMPLETE" }

$monitoringData | ConvertTo-Json -Depth 4 | Set-Content -Path $reportFile -Encoding UTF8

Write-Host "`n=== Monitoring Complete ===" -ForegroundColor Green
Write-Host "Total checks performed: $checkCount" -ForegroundColor Cyan
Write-Host "Canary logs generated: $($monitoringData.canary_logs_generated)" -ForegroundColor Cyan
Write-Host "Alert triggered: $($monitoringData.alert_triggered)" -ForegroundColor Cyan
Write-Host "Report saved to: $reportFile" -ForegroundColor Blue

Write-Host "`n=== Verification Steps ===" -ForegroundColor Yellow
Write-Host "1. SigNoz UI: http://localhost:8080" -ForegroundColor White
Write-Host "2. Logs -> Filter: log.file.path = 'C:/logs/windows-canary-test.log' AND body contains 'windows-canary'" -ForegroundColor White
Write-Host "3. Alerts -> Check 'Windows Canary Log Absence' status" -ForegroundColor White
Write-Host "4. Verify alert configuration is imported" -ForegroundColor White

Write-Host "`nWindows Canary Alert monitoring completed!" -ForegroundColor Green
