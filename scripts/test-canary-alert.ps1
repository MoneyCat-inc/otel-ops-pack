# Test Canary Alert Script
# Tests the canary alert by generating and then stopping canary logs

param(
    [int]$TestDurationMinutes = 10,
    [string]$OutputFile = "artifacts/canary-alert-test-results.json"
)

Write-Host "=== Canary Alert Test ===" -ForegroundColor Green
Write-Host "Test duration: $TestDurationMinutes minutes" -ForegroundColor Yellow

# Ensure artifacts directory exists
if (-not (Test-Path "artifacts")) {
    New-Item -ItemType Directory -Path "artifacts" -Force
}

# Ensure logs directory exists
if (-not (Test-Path "C:\logs")) {
    New-Item -ItemType Directory -Path "C:\logs" -Force
}

try {
    $testResults = @{
        test_duration_minutes = $TestDurationMinutes
        start_time = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        phases = @()
    }
    
    # Phase 1: Generate canary logs for first half of test
    Write-Host "Phase 1: Generating canary logs..." -ForegroundColor Yellow
    $phase1Start = Get-Date
    $phase1End = $phase1Start.AddMinutes($TestDurationMinutes / 2)
    
    $canaryCount = 0
    while ((Get-Date) -lt $phase1End) {
        # Create Windows Event Log entry
        Write-EventLog -LogName Application -Source "WindowsCanary" -EventId 3001 -Message "windows-canary test event $canaryCount"
        
        # Create file log entry
        $logEntry = @{
            timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            message = "windows-canary test log $canaryCount"
            test_id = "canary-alert-test"
            phase = "generation"
        } | ConvertTo-Json -Compress
        
        Add-Content -Path "C:\logs\windows-canary-test.json" -Value $logEntry
        
        $canaryCount++
        Start-Sleep -Seconds 30
    }
    
    $testResults.phases += @{
        name = "generation"
        start_time = $phase1Start.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        end_time = $phase1End.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        canary_events_generated = $canaryCount
    }
    
    Write-Host "Generated $canaryCount canary events" -ForegroundColor Green
    
    # Phase 2: Stop generating canary logs (should trigger alert)
    Write-Host "Phase 2: Stopping canary logs (alert should trigger)..." -ForegroundColor Yellow
    $phase2Start = Get-Date
    $phase2End = $phase2Start.AddMinutes($TestDurationMinutes / 2)
    
    # Wait for alert to potentially trigger
    while ((Get-Date) -lt $phase2End) {
        Write-Host "Waiting for alert to trigger... (no canary logs being generated)" -ForegroundColor Yellow
        Start-Sleep -Seconds 60
    }
    
    $testResults.phases += @{
        name = "alert_trigger"
        start_time = $phase2Start.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        end_time = $phase2End.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        canary_events_generated = 0
    }
    
    # Phase 3: Resume canary logs (should clear alert)
    Write-Host "Phase 3: Resuming canary logs (alert should clear)..." -ForegroundColor Yellow
    $phase3Start = Get-Date
    $phase3End = $phase3Start.AddMinutes(2)
    
    $resumeCount = 0
    while ((Get-Date) -lt $phase3End) {
        # Create Windows Event Log entry
        Write-EventLog -LogName Application -Source "WindowsCanary" -EventId 3001 -Message "windows-canary resume event $resumeCount"
        
        # Create file log entry
        $logEntry = @{
            timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            message = "windows-canary resume log $resumeCount"
            test_id = "canary-alert-test"
            phase = "resume"
        } | ConvertTo-Json -Compress
        
        Add-Content -Path "C:\logs\windows-canary-test.json" -Value $logEntry
        
        $resumeCount++
        Start-Sleep -Seconds 30
    }
    
    $testResults.phases += @{
        name = "resume"
        start_time = $phase3Start.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        end_time = $phase3End.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        canary_events_generated = $resumeCount
    }
    
    $testResults.end_time = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    $testResults.total_canary_events = $canaryCount + $resumeCount
    
    # Save results
    $testResults | ConvertTo-Json -Depth 10 | Set-Content $OutputFile
    Write-Host "Test results saved to: $OutputFile" -ForegroundColor Green
    
    # Display results
    Write-Host "`n=== Test Results ===" -ForegroundColor Green
    Write-Host "Total canary events generated: $($testResults.total_canary_events)" -ForegroundColor White
    Write-Host "Generation phase: $canaryCount events" -ForegroundColor White
    Write-Host "Resume phase: $resumeCount events" -ForegroundColor White
    Write-Host "Alert trigger phase: 0 events (should trigger alert)" -ForegroundColor White
    
    Write-Host "`nCanary Alert Test completed!" -ForegroundColor Green
    Write-Host "Check SigNoz UI → Alerts → Windows Canary Alert for alert status" -ForegroundColor Cyan
    
} catch {
    Write-Error "Canary Alert Test failed: $($_.Exception.Message)"
    exit 1
}
