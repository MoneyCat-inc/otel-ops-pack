# Test Canary Alert Script
# Tests the Windows canary alert by generating and then stopping canary logs

param(
    [int]$TestDurationMinutes = 10,
    [switch]$GenerateCanary,
    [switch]$StopCanary,
    [switch]$FullTest
)

Write-Host "=== Canary Alert Test ===" -ForegroundColor Green
Write-Host "Test duration: $TestDurationMinutes minutes" -ForegroundColor Yellow

# Ensure logs directory exists
if (-not (Test-Path "C:\logs")) {
    New-Item -ItemType Directory -Path "C:\logs" -Force
}

$logFile = "C:\logs\windows-canary-test.log"
$testStartTime = Get-Date

if ($GenerateCanary -or $FullTest) {
    Write-Host "`nGenerating canary logs..." -ForegroundColor Yellow
    
    # Generate canary logs every 30 seconds for the test duration
    $endTime = $testStartTime.AddMinutes($TestDurationMinutes)
    $logCount = 0
    
    while ((Get-Date) -lt $endTime) {
        $logEntry = @{
            timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            level = "INFO"
            message = "windows-canary test log entry $logCount"
            service = "canary-test"
            canary = "true"
            test_id = "canary-alert-test"
        } | ConvertTo-Json -Compress
        
        Add-Content -Path $logFile -Value $logEntry
        $logCount++
        
        Write-Host "Generated canary log $logCount" -ForegroundColor Green
        Start-Sleep -Seconds 30
    }
    
    Write-Host "Generated $logCount canary logs" -ForegroundColor Green
}

if ($StopCanary -or $FullTest) {
    Write-Host "`nStopping canary log generation..." -ForegroundColor Yellow
    
    # Wait for the alert to trigger (5+ minutes without canary logs)
    Write-Host "Waiting for canary alert to trigger (5+ minutes without logs)..." -ForegroundColor Yellow
    Start-Sleep -Seconds 300  # 5 minutes
    
    Write-Host "Canary alert should have triggered by now" -ForegroundColor Red
    Write-Host "Check SigNoz UI -> Alerts for 'Windows Canary Log Absence' alert" -ForegroundColor Cyan
}

if ($FullTest) {
    Write-Host "`n=== Full Test Results ===" -ForegroundColor Green
    
    # Check if canary logs exist in SigNoz
    Write-Host "Verification steps:" -ForegroundColor Yellow
    Write-Host "1. SigNoz UI -> Logs -> filter: body contains 'windows-canary'" -ForegroundColor White
    Write-Host "2. SigNoz UI -> Alerts -> check 'Windows Canary Log Absence' status" -ForegroundColor White
    Write-Host "3. Verify alert triggers after 5 minutes of no canary logs" -ForegroundColor White
    
    # Generate test report
    $testResults = @{
        test_id = "canary-alert-test"
        start_time = $testStartTime.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        end_time = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        duration_minutes = $TestDurationMinutes
        canary_logs_generated = if ($GenerateCanary -or $FullTest) { $logCount } else { 0 }
        alert_expected = if ($StopCanary -or $FullTest) { $true } else { $false }
        log_file = $logFile
        verification_steps = @(
            "Check SigNoz UI -> Logs for canary entries",
            "Check SigNoz UI -> Alerts for canary alert status",
            "Verify alert triggers after 5 minutes of no logs"
        )
    }
    
    $reportFile = "artifacts/canary-alert-test-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $testResults | ConvertTo-Json -Depth 4 | Set-Content -Path $reportFile -Encoding UTF8
    Write-Host "`nTest report saved to: $reportFile" -ForegroundColor Blue
}

Write-Host "`nCanary alert test completed!" -ForegroundColor Green