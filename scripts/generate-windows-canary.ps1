# Windows Canary Log Generator
# Generates canary logs for Windows Event Log and file log sources
# Used for testing Windows logs absence detection alerts

param(
    [int]$DurationMinutes = 5,
    [int]$IntervalSeconds = 30,
    [string]$OutputDir = "C:\logs"
)

# ECRR - Examine → Clean → Report → Role
Write-Host "🔍 Examine Windows Canary Log Generation - ECRR Framework" -ForegroundColor Cyan
Write-Host "🎭 Actor: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

# Ensure output directory exists
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    Write-Host "✓ Created log directory: $OutputDir" -ForegroundColor Green
}

# Generate unique test session ID
$TestSessionId = "WINDOWS-CANARY-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$TestStartTime = Get-Date
$TestEndTime = $TestStartTime.AddMinutes($DurationMinutes)

Write-Host "`n📊 Windows Canary Test Configuration:" -ForegroundColor Green
Write-Host "  Test Session ID: $TestSessionId" -ForegroundColor Cyan
Write-Host "  Duration: $DurationMinutes minutes" -ForegroundColor Cyan
Write-Host "  Interval: $IntervalSeconds seconds" -ForegroundColor Cyan
Write-Host "  Output Directory: $OutputDir" -ForegroundColor Cyan
Write-Host "  Start Time: $($TestStartTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Cyan
Write-Host "  End Time: $($TestEndTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Cyan

# File log canary path
$FileCanaryPath = "$OutputDir\windows-canary-test.log"

# Counter for canary logs
$CanaryCount = 0

Write-Host "`n🚀 Starting Windows canary log generation..." -ForegroundColor Green

try {
    while ((Get-Date) -lt $TestEndTime) {
        $CurrentTime = Get-Date
        $CanaryCount++
        
        # Generate file log canary
        $FileCanaryLog = @{
            timestamp = $CurrentTime.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            session_id = $TestSessionId
            canary_id = "FILE-CANARY-$CanaryCount"
            message = "windows-canary test log entry"
            level = "INFO"
            source = "file-log-canary"
            test_duration_minutes = $DurationMinutes
            interval_seconds = $IntervalSeconds
            log_count = $CanaryCount
            test_type = "windows-logs-absence-detection"
        } | ConvertTo-Json -Compress
        
        Add-Content -Path $FileCanaryPath -Value $FileCanaryLog
        Write-Host "  ✓ Generated file canary #$CanaryCount at $($CurrentTime.ToString('HH:mm:ss'))" -ForegroundColor Green
        
        # Generate Windows Event Log canary (if possible)
        try {
            $EventLogMessage = "Windows canary test event - Session: $TestSessionId, Count: $CanaryCount"
            Write-EventLog -LogName Application -Source "Windows Canary Test" -EventId 1001 -Message $EventLogMessage -EntryType Information -ErrorAction Stop
            Write-Host "  ✓ Generated Event Log canary #$CanaryCount" -ForegroundColor Green
        } catch {
            Write-Host "  ⚠ Could not write to Event Log: $($_.Exception.Message)" -ForegroundColor Yellow
            # Create a simulated event log entry in file
            $EventLogCanary = @{
                timestamp = $CurrentTime.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                session_id = $TestSessionId
                canary_id = "EVENT-CANARY-$CanaryCount"
                message = "windows-canary simulated event log entry"
                level = "INFO"
                source = "windows-event-log-canary"
                event_id = 1001
                log_name = "Application"
                test_type = "windows-logs-absence-detection"
            } | ConvertTo-Json -Compress
            
            $EventLogFile = "$OutputDir\windows-event-canary.log"
            Add-Content -Path $EventLogFile -Value $EventLogCanary
            Write-Host "  ✓ Generated simulated Event Log canary #$CanaryCount" -ForegroundColor Green
        }
        
        # Wait for next interval
        Start-Sleep -Seconds $IntervalSeconds
    }
} catch {
    Write-Host "`n❌ Error during canary generation: $($_.Exception.Message)" -ForegroundColor Red
    throw
}

# Generate summary
$TestEndTime = Get-Date
$ActualDuration = ($TestEndTime - $TestStartTime).TotalMinutes

Write-Host "`n✅ Windows Canary Generation Complete!" -ForegroundColor Green
Write-Host "📊 Test Summary:" -ForegroundColor Cyan
Write-Host "  Test Session ID: $TestSessionId" -ForegroundColor White
Write-Host "  Canary Logs Generated: $CanaryCount" -ForegroundColor White
Write-Host "  Actual Duration: $([math]::Round($ActualDuration, 2)) minutes" -ForegroundColor White
Write-Host "  File Log Path: $FileCanaryPath" -ForegroundColor White
Write-Host "  Interval: $IntervalSeconds seconds" -ForegroundColor White

# Create test results file
$ResultsFile = "artifacts\windows-canary-test-results.json"
if (-not (Test-Path "artifacts")) {
    New-Item -ItemType Directory -Path "artifacts" -Force | Out-Null
}

$TestResults = @{
    test_session_id = $TestSessionId
    start_time = $TestStartTime.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    end_time = $TestEndTime.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    duration_minutes = $DurationMinutes
    actual_duration_minutes = [math]::Round($ActualDuration, 2)
    interval_seconds = $IntervalSeconds
    canary_count = $CanaryCount
    file_log_path = $FileCanaryPath
    output_directory = $OutputDir
    test_type = "windows-logs-absence-detection"
    status = "completed"
} | ConvertTo-Json -Depth 3

Set-Content -Path $ResultsFile -Value $TestResults -Encoding UTF8
Write-Host "  Results saved to: $ResultsFile" -ForegroundColor Cyan

Write-Host "`n🎯 Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Check SigNoz UI for canary logs in Logs section" -ForegroundColor White
Write-Host "  2. Import Windows Logs Canary Absence alert to SigNoz" -ForegroundColor White
Write-Host "  3. Test alert by stopping canary generation" -ForegroundColor White
Write-Host "  4. Verify alert triggers after 10 minutes of no canaries" -ForegroundColor White

Write-Host "`n📝 SigNoz Query for Verification:" -ForegroundColor Cyan
Write-Host "  (log.source = 'windows_event_log' AND body contains 'windows-canary') OR (log.file.path contains 'windows-canary-test.log' AND body contains 'windows-canary')" -ForegroundColor White

Write-Host "`n🎭 Role: Cursor-Local (Observability Copilot) - Windows Canary Generation Complete" -ForegroundColor Magenta
