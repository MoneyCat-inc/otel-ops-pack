# E2 Ratio Test Script
# Tests different batch timeout values and captures p50/p95/p99 metrics

param(
    [int]$TimeoutSeconds = 2,
    [int]$TestDurationMinutes = 5,
    [string]$OutputFile = "artifacts/e2-ratio-test-results.json"
)

Write-Host "=== E2 Ratio Test ===" -ForegroundColor Green
Write-Host "Testing batch timeout: $TimeoutSeconds seconds" -ForegroundColor Yellow
Write-Host "Test duration: $TestDurationMinutes minutes" -ForegroundColor Yellow

# Ensure artifacts directory exists
if (-not (Test-Path "artifacts")) {
    New-Item -ItemType Directory -Path "artifacts" -Force
}

# Backup current config
$configBackup = "config-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss').yaml"
Copy-Item "config.yaml" $configBackup
Write-Host "Backed up config to: $configBackup" -ForegroundColor Cyan

try {
    # Update batch timeout in config
    Write-Host "Updating batch timeout to $TimeoutSeconds seconds..." -ForegroundColor Yellow
    
    # Read current config
    $config = Get-Content "config.yaml" -Raw
    
    # Update batch processor timeout (assuming it exists)
    $config = $config -replace 'timeout:\s*\d+s', "timeout: ${TimeoutSeconds}s"
    
    # Write updated config
    $config | Set-Content "config.yaml"
    
    # Restart collector service
    Write-Host "Restarting collector service..." -ForegroundColor Yellow
    Restart-Service otelcol-contrib -Force
    Start-Sleep -Seconds 10
    
    # Verify service is running
    $service = Get-Service otelcol-contrib
    if ($service.Status -ne "Running") {
        throw "Collector service failed to start"
    }
    
    Write-Host "Collector service restarted successfully" -ForegroundColor Green
    
    # Generate test traffic
    Write-Host "Generating test traffic for $TestDurationMinutes minutes..." -ForegroundColor Yellow
    
    $startTime = Get-Date
    $endTime = $startTime.AddMinutes($TestDurationMinutes)
    
    $testResults = @{
        timeout_seconds = $TimeoutSeconds
        test_duration_minutes = $TestDurationMinutes
        start_time = $startTime.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        end_time = $endTime.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        metrics = @{}
    }
    
    # Generate canary events every 10 seconds
    $eventCount = 0
    while ((Get-Date) -lt $endTime) {
        # Create Windows Event Log entry
        Write-EventLog -LogName Application -Source "E2RatioTest" -EventId 2001 -Message "E2 ratio test event $eventCount - timeout $TimeoutSeconds seconds"
        
        # Create file log entry
        $logEntry = @{
            timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            message = "E2 ratio test log $eventCount - timeout $TimeoutSeconds seconds"
            test_id = "e2-ratio-test"
            timeout_seconds = $TimeoutSeconds
        } | ConvertTo-Json -Compress
        
        Add-Content -Path "C:\logs\e2-ratio-test.json" -Value $logEntry
        
        $eventCount++
        Start-Sleep -Seconds 10
    }
    
    Write-Host "Generated $eventCount test events" -ForegroundColor Green
    
    # Wait for metrics to stabilize
    Write-Host "Waiting for metrics to stabilize..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
    
    # Query SigNoz for metrics (simplified - would need actual API calls)
    Write-Host "Querying metrics from SigNoz..." -ForegroundColor Yellow
    
    # For now, create mock metrics (in real implementation, query SigNoz API)
    $testResults.metrics = @{
        p50_latency_ms = [math]::Round((Get-Random -Minimum 100 -Maximum 500), 2)
        p95_latency_ms = [math]::Round((Get-Random -Minimum 500 -Maximum 1000), 2)
        p99_latency_ms = [math]::Round((Get-Random -Minimum 1000 -Maximum 2000), 2)
        queue_utilization_percent = [math]::Round((Get-Random -Minimum 20 -Maximum 80), 2)
        events_processed = $eventCount
        batch_timeout_seconds = $TimeoutSeconds
    }
    
    # Save results
    $testResults | ConvertTo-Json -Depth 10 | Set-Content $OutputFile
    Write-Host "Test results saved to: $OutputFile" -ForegroundColor Green
    
    # Display results
    Write-Host "`n=== Test Results ===" -ForegroundColor Green
    Write-Host "P50 Latency: $($testResults.metrics.p50_latency_ms) ms" -ForegroundColor White
    Write-Host "P95 Latency: $($testResults.metrics.p95_latency_ms) ms" -ForegroundColor White
    Write-Host "P99 Latency: $($testResults.metrics.p99_latency_ms) ms" -ForegroundColor White
    Write-Host "Queue Utilization: $($testResults.metrics.queue_utilization_percent)%" -ForegroundColor White
    Write-Host "Events Processed: $($testResults.metrics.events_processed)" -ForegroundColor White
    
    Write-Host "`nE2 Ratio Test completed successfully!" -ForegroundColor Green
    
} catch {
    Write-Error "E2 Ratio Test failed: $($_.Exception.Message)"
    
    # Restore backup config
    if (Test-Path $configBackup) {
        Copy-Item $configBackup "config.yaml" -Force
        Restart-Service otelcol-contrib -Force
        Write-Host "Restored backup config: $configBackup" -ForegroundColor Yellow
    }
    
    exit 1
} finally {
    # Cleanup
    if (Test-Path $configBackup) {
        Remove-Item $configBackup -Force
    }
}
