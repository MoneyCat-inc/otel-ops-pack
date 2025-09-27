# E2 Ratio Simple Analysis Script
# Tests current configuration and measures performance metrics
# No service restarts required - analyzes existing collector performance

param(
    [int]$DurationSeconds = 60,
    [string]$OutputDir = "artifacts"
)

# ECRR: Examine → Clean → Report → Role
Write-Host "E2 Ratio Simple Analysis - ECRR Framework" -ForegroundColor Cyan
Write-Host "Actor: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

# Ensure output directory exists
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# Examine current configuration
Write-Host "`nExamine: Current configuration analysis..." -ForegroundColor Green

# Read current config
$ConfigContent = Get-Content "config.yaml" -Raw
$BatchTimeout = if ($ConfigContent -match 'timeout:\s*(\d+ms)') { $matches[1] } else { "Not found" }
$BatchSize = if ($ConfigContent -match 'send_batch_size:\s*(\d+)') { $matches[1] } else { "Not found" }

Write-Host "  Current batch timeout: $BatchTimeout" -ForegroundColor White
Write-Host "  Current batch size: $BatchSize" -ForegroundColor White

# Check collector health
Write-Host "`nClean: Verifying collector health..." -ForegroundColor Green
try {
    $HealthResponse = Invoke-RestMethod -Uri "http://localhost:13134/healthz" -TimeoutSec 5
    if ($HealthResponse.status -eq "Server available") {
        Write-Host "  OK Collector is healthy" -ForegroundColor Green
    } else {
        Write-Host "  ERROR Collector health check failed" -ForegroundColor Red
        return
    }
} catch {
    Write-Host "  ERROR Cannot reach collector health endpoint" -ForegroundColor Red
    return
}

# Generate test load
Write-Host "`nReport: Generating test load for $DurationSeconds seconds..." -ForegroundColor Green

# Create logs directory if needed
if (-not (Test-Path "C:\logs")) {
    New-Item -ItemType Directory -Path "C:\logs" -Force | Out-Null
}

$TestStartTime = Get-Date
$TestEndTime = $TestStartTime.AddSeconds($DurationSeconds)
$LogCount = 0
$LogFile = "C:\logs\e2-simple-test.log"

Write-Host "  Metrics Generating test logs..." -ForegroundColor Yellow

while ((Get-Date) -lt $TestEndTime) {
    $LogEntry = @{
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        test_type = "e2-ratio-simple"
        batch_timeout = $BatchTimeout
        batch_size = $BatchSize
        log_count = $LogCount++
        message = "E2 ratio simple test log entry"
        level = "INFO"
        test_duration = $DurationSeconds
    } | ConvertTo-Json -Compress
    
    Add-Content -Path $LogFile -Value $LogEntry
    Start-Sleep -Milliseconds 100  # 10 logs per second
}

Write-Host "  OK Generated $LogCount test logs" -ForegroundColor Green

# Wait for processing
Write-Host "  Wait Waiting for log processing..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Collect metrics
Write-Host "  Stats Collecting performance metrics..." -ForegroundColor Yellow

$Metrics = @{
    test_type = "e2-ratio-simple"
    batch_timeout = $BatchTimeout
    batch_size = $BatchSize
    test_duration_seconds = $DurationSeconds
    logs_generated = $LogCount
    timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
}

# Try to get collector metrics
try {
    $CollectorMetrics = Invoke-RestMethod -Uri "http://localhost:8888/metrics" -TimeoutSec 10
    $QueueSize = ($CollectorMetrics | Select-String "otelcol_exporter_queue_size").Line
    $QueueCapacity = ($CollectorMetrics | Select-String "otelcol_exporter_queue_capacity").Line
    $SendFailed = ($CollectorMetrics | Select-String "otelcol_exporter_send_failed").Line
    
    if ($QueueSize) {
        $Metrics.queue_size = $QueueSize
    }
    if ($QueueCapacity) {
        $Metrics.queue_capacity = $QueueCapacity
    }
    if ($SendFailed) {
        $Metrics.send_failed = $SendFailed
    }
    
    Write-Host "  OK Collected collector metrics" -ForegroundColor Green
} catch {
    Write-Host "  WARNING Could not collect queue metrics" -ForegroundColor Yellow
}

# Check SigNoz for processed logs
try {
    $SigNozQuery = @{
        query = "message contains `"E2 ratio simple test log entry`""
        start = [int64]((Get-Date).AddMinutes(-5) - (Get-Date "1970-01-01")).TotalSeconds
        end = [int64]((Get-Date) - (Get-Date "1970-01-01")).TotalSeconds
    }
    
    $SigNozResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/logs" -Method POST -Body ($SigNozQuery | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 10
    
    if ($SigNozResponse -and $SigNozResponse.data) {
        $Metrics.logs_processed = $SigNozResponse.data.Count
        $Metrics.ingestion_success_rate = if ($LogCount -gt 0) { ($SigNozResponse.data.Count / $LogCount) * 100 } else { 0 }
        Write-Host "  OK Found $($SigNozResponse.data.Count) processed logs in SigNoz" -ForegroundColor Green
    } else {
        $Metrics.logs_processed = 0
        $Metrics.ingestion_success_rate = 0
        Write-Host "  WARNING No processed logs found in SigNoz" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  WARNING Could not query SigNoz for processed logs" -ForegroundColor Yellow
    $Metrics.logs_processed = 0
    $Metrics.ingestion_success_rate = 0
}

# Save results
$ResultsFile = "$OutputDir/e2-ratio-simple-results.json"
$Metrics | ConvertTo-Json -Depth 3 | Set-Content $ResultsFile -Encoding UTF8

# Generate summary report
$ReportFile = "$OutputDir/e2-ratio-simple-summary.md"
$Report = @"
# E2 Ratio Simple Analysis Results

**Generated**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Actor**: Cursor-Local (Observability Copilot)
**Test Duration**: $DurationSeconds seconds

## Current Configuration
- **Batch Timeout**: $BatchTimeout
- **Batch Size**: $BatchSize

## Test Results
- **Logs Generated**: $($Metrics.logs_generated)
- **Logs Processed**: $($Metrics.logs_processed)
- **Success Rate**: $([math]::Round($Metrics.ingestion_success_rate, 2))%
- **Queue Size**: $($Metrics.queue_size)
- **Queue Capacity**: $($Metrics.queue_capacity)
- **Send Failed**: $($Metrics.send_failed)

## Analysis

### Performance Metrics
- **Ingestion Rate**: $([math]::Round($Metrics.logs_processed / $DurationSeconds, 2)) logs/second
- **Processing Efficiency**: $([math]::Round($Metrics.ingestion_success_rate, 2))%
- **Queue Utilization**: $(if ($Metrics.queue_size -and $Metrics.queue_capacity) { [math]::Round(($Metrics.queue_size -replace '[^\d]', '') / ($Metrics.queue_capacity -replace '[^\d]', '') * 100, 2) } else { "N/A" })%

### Recommendations
1. **If Success Rate < 95%**: Consider increasing batch timeout or reducing batch size
2. **If Queue Utilization > 80%**: Consider increasing queue capacity or reducing load
3. **If Send Failed > 0**: Check exporter configuration and network connectivity

## Files Generated
- **Results**: `$ResultsFile`
- **Report**: `$ReportFile`

## Next Steps
1. Review current performance metrics
2. Consider configuration adjustments based on results
3. Run additional tests with different parameters
4. Set up monitoring for queue pressure and latency

---
*Generated by E2 Ratio Simple Analysis Script*
"@

Set-Content $ReportFile $Report -Encoding UTF8

Write-Host "`nOK E2 Ratio Simple Analysis Complete!" -ForegroundColor Green
Write-Host "Metrics Results saved to: $ResultsFile" -ForegroundColor Cyan
Write-Host "Report Report saved to: $ReportFile" -ForegroundColor Cyan

# Display summary
Write-Host "`nStats Quick Summary:" -ForegroundColor Cyan
Write-Host "  Configuration: $BatchTimeout timeout, $BatchSize batch size" -ForegroundColor White
Write-Host "  Performance: $($Metrics.logs_processed)/$($Metrics.logs_generated) logs processed ($([math]::Round($Metrics.ingestion_success_rate, 1))%)" -ForegroundColor White
Write-Host "  Rate: $([math]::Round($Metrics.logs_processed / $DurationSeconds, 2)) logs/second" -ForegroundColor White

Write-Host "`nTarget Next: Review results and consider configuration optimization" -ForegroundColor Yellow
