# Test Canary Alert Script
# Generates canary logs and verifies alert conditions

param(
    [switch]$GenerateCanary,
    [switch]$StopCanary,
    [switch]$TestAlert,
    [int]$DurationMinutes = 10
)

Write-Host "=== Canary Alert Test Script ===" -ForegroundColor Green

# Ensure logs directory exists
if (-not (Test-Path "C:\logs")) {
    New-Item -ItemType Directory -Path "C:\logs" -Force
}

if ($GenerateCanary) {
    Write-Host "Generating canary logs for $DurationMinutes minutes..." -ForegroundColor Yellow
    
    $endTime = (Get-Date).AddMinutes($DurationMinutes)
    $logCount = 0
    
    while ((Get-Date) -lt $endTime) {
        # Create Windows Event Log entry
        Write-EventLog -LogName Application -Source "WindowsCanary" -EventId 5001 -Message "windows-canary test $logCount - $(Get-Date)"
        
        # Create file log entry
        $logEntry = @{
            timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            message = "windows-canary test log $logCount - $(Get-Date)"
            canary = "true"
            canary_type = "windows"
            test_id = "canary-alert-test"
        } | ConvertTo-Json -Compress
        
        Add-Content -Path "C:\logs\windows-canary-test.json" -Value $logEntry
        
        $logCount++
        Write-Host "Generated canary log $logCount" -ForegroundColor Cyan
        
        Start-Sleep -Seconds 30  # Generate every 30 seconds
    }
    
    Write-Host "Generated $logCount canary logs" -ForegroundColor Green
}

if ($StopCanary) {
    Write-Host "Stopping canary log generation..." -ForegroundColor Yellow
    
    # Remove canary log file
    if (Test-Path "C:\logs\windows-canary-test.json") {
        Remove-Item "C:\logs\windows-canary-test.json" -Force
        Write-Host "Removed canary log file" -ForegroundColor Green
    }
    
    Write-Host "Canary log generation stopped" -ForegroundColor Green
}

if ($TestAlert) {
    Write-Host "Testing canary alert conditions..." -ForegroundColor Yellow
    
    # Test SigNoz connectivity
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/health" -Method Get -TimeoutSec 10
        Write-Host "✓ SigNoz is accessible" -ForegroundColor Green
    } catch {
        Write-Warning "✗ SigNoz is not accessible: $($_.Exception.Message)"
        return
    }
    
    # Query for recent canary logs
    try {
        $query = "count(logs) where message contains 'windows-canary' and timestamp > now() - 5m"
        $body = @{
            query = $query
            start = (Get-Date).AddMinutes(-5).ToString("yyyy-MM-ddTHH:mm:ssZ")
            end = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/query_range" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30
        
        if ($response.data.result -and $response.data.result.Count -gt 0) {
            $count = $response.data.result[0].values[-1][1]
            Write-Host "✓ Found $count canary logs in last 5 minutes" -ForegroundColor Green
            
            if ([int]$count -eq 0) {
                Write-Host "⚠️  ALERT CONDITION: No canary logs found - alert should trigger!" -ForegroundColor Red
            } else {
                Write-Host "✓ Canary logs present - no alert should trigger" -ForegroundColor Green
            }
        } else {
            Write-Host "⚠️  No canary logs found in SigNoz - alert should trigger!" -ForegroundColor Red
        }
    } catch {
        Write-Warning "Failed to query canary logs: $($_.Exception.Message)"
    }
}

if (-not $GenerateCanary -and -not $StopCanary -and -not $TestAlert) {
    Write-Host "Usage examples:" -ForegroundColor Yellow
    Write-Host "  Generate canary logs: pwsh -File scripts/test-canary-alert.ps1 -GenerateCanary -DurationMinutes 10" -ForegroundColor White
    Write-Host "  Stop canary logs: pwsh -File scripts/test-canary-alert.ps1 -StopCanary" -ForegroundColor White
    Write-Host "  Test alert: pwsh -File scripts/test-canary-alert.ps1 -TestAlert" -ForegroundColor White
    Write-Host "  Full test: pwsh -File scripts/test-canary-alert.ps1 -GenerateCanary -DurationMinutes 5; Start-Sleep 60; pwsh -File scripts/test-canary-alert.ps1 -TestAlert" -ForegroundColor White
}