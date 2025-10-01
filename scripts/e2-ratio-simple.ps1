# E2 Ratio Simple Analysis Script
# Tests current configuration without service restarts
# Measures log processing performance and queue utilization

param(
    [int]$DurationSeconds = 30,
    [string]$OutputDir = "artifacts"
)

# ECRR - Examine → Clean → Report → Role
Write-Host "🔍 Examine E2 Ratio Simple Analysis - ECRR Framework" -ForegroundColor Cyan
Write-Host "🎭 Actor: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

# Ensure output directory exists
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# Check system status
Write-Host "`n📊 System Status Check:" -ForegroundColor Green

# Check SigNoz health
try {
    $SigNozHealth = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/health" -TimeoutSec 5
    Write-Host "  ✓ SigNoz: Healthy" -ForegroundColor Green
} catch {
    Write-Host "  ✗ SigNoz: Unavailable" -ForegroundColor Red
    exit 1
}

# Check OTel collector status
$CollectorStatus = Get-Service otelcol-contrib -ErrorAction SilentlyContinue
if ($CollectorStatus -and $CollectorStatus.Status -eq "Running") {
    Write-Host "  ✓ OTel Collector: Running" -ForegroundColor Green
} else {
    Write-Host "  ⚠ OTel Collector: Stopped (will use SigNoz collector)" -ForegroundColor Yellow
}

# Generate test load
Write-Host "`n📝 Generating test load for $DurationSeconds seconds..." -ForegroundColor Yellow
$TestStartTime = Get-Date
$TestId = "E2-SIMPLE-$(Get-Date -Format 'HHmmss')"

# Create canary logs
$LogFile = "C:\logs\e2-test-$TestId.log"
if (-not (Test-Path "C:\logs")) {
    New-Item -ItemType Directory -Path "C:\logs" -Force | Out-Null
}

$TestEndTime = $TestStartTime.AddSeconds($DurationSeconds)
$LogCount = 0

Write-Host "  Generating logs to: $LogFile" -ForegroundColor Cyan

while ((Get-Date) -lt $TestEndTime) {
    $LogEntry = @{
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        test_id = $TestId
        test_duration = $DurationSeconds
        log_count = $LogCount++
        message = "E2 ratio simple test log entry"
        level = "INFO"
        source = "e2-ratio-test"
    } | ConvertTo-Json -Compress
    
    Add-Content -Path $LogFile -Value $LogEntry
    Start-Sleep -Milliseconds 100  # 10 logs per second
}

Write-Host "  ✓ Generated $LogCount test logs" -ForegroundColor Green

# Wait for processing
Write-Host "`n⏳ Waiting for log processing..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

# Collect metrics
Write-Host "`n📊 Collecting performance metrics..." -ForegroundColor Yellow

$Metrics = @{
    test_id = $TestId
    test_duration_seconds = $DurationSeconds
    logs_generated = $LogCount
    timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    collector_status = if ($CollectorStatus -and $CollectorStatus.Status -eq "Running") { "Running" } else { "Stopped" }
}

# Try to get SigNoz metrics
try {
    # Query for our test logs
    $SigNozQuery = @{
        query = "message contains `"E2 ratio simple test log entry`""
        start = [int64]((Get-Date).AddMinutes(-10) - (Get-Date "1970-01-01")).TotalSeconds
        end = [int64]((Get-Date) - (Get-Date "1970-01-01")).TotalSeconds
    }
    
    $SigNozResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/logs" -Method POST -Body ($SigNozQuery | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 10
    
    if ($SigNozResponse -and $SigNozResponse.data) {
        $Metrics.logs_processed = $SigNozResponse.data.Count
        $Metrics.ingestion_success_rate = if ($LogCount -gt 0) { ($SigNozResponse.data.Count / $LogCount) * 100 } else { 0 }
        Write-Host "  ✓ Found $($SigNozResponse.data.Count) processed logs in SigNoz" -ForegroundColor Green
    } else {
        $Metrics.logs_processed = 0
        $Metrics.ingestion_success_rate = 0
        Write-Host "  ⚠ No processed logs found in SigNoz" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ✗ Could not query SigNoz: $($_.Exception.Message)" -ForegroundColor Red
    $Metrics.logs_processed = 0
    $Metrics.ingestion_success_rate = 0
    $Metrics.error = $_.Exception.Message
}

# Try to get collector metrics if running
if ($CollectorStatus -and $CollectorStatus.Status -eq "Running") {
    try {
        $CollectorMetrics = Invoke-RestMethod -Uri "http://localhost:8888/metrics" -TimeoutSec 5
        $QueueSize = ($CollectorMetrics | Select-String "otelcol_exporter_queue_size").Line
        $QueueCapacity = ($CollectorMetrics | Select-String "otelcol_exporter_queue_capacity").Line
        
        if ($QueueSize) {
            $Metrics.queue_size = $QueueSize
            Write-Host "  ✓ Queue size: $QueueSize" -ForegroundColor Green
        }
        if ($QueueCapacity) {
            $Metrics.queue_capacity = $QueueCapacity
            Write-Host "  ✓ Queue capacity: $QueueCapacity" -ForegroundColor Green
        }
    } catch {
        Write-Host "  ⚠ Could not collect queue metrics" -ForegroundColor Yellow
    }
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
**Test ID**: $TestId

## Test Results

| Metric | Value |
|--------|-------|
| Test Duration | $DurationSeconds seconds |
| Logs Generated | $($Metrics.logs_generated) |
| Logs Processed | $($Metrics.logs_processed) |
| Success Rate | $([math]::Round($Metrics.ingestion_success_rate, 2))% |
| Collector Status | $($Metrics.collector_status) |

## Analysis

### Current Configuration Performance
- **Log Generation Rate**: $($Metrics.logs_generated / $DurationSeconds) logs/second
- **Processing Success Rate**: $([math]::Round($Metrics.ingestion_success_rate, 2))%
- **System Status**: $(if ($Metrics.ingestion_success_rate -gt 80) { "✅ Healthy" } elseif ($Metrics.ingestion_success_rate -gt 50) { "⚠️ Degraded" } else { "❌ Poor" })

### Recommendations
$(if ($Metrics.ingestion_success_rate -gt 80) {
"✅ **Current configuration is performing well**
- Continue monitoring queue utilization
- Consider optimizing batch sizes for higher throughput"
} elseif ($Metrics.ingestion_success_rate -gt 50) {
"⚠️ **Configuration needs optimization**
- Investigate log processing bottlenecks
- Check SigNoz collector health
- Consider adjusting batch timeouts"
} else {
"❌ **Configuration requires immediate attention**
- Check OTel collector service status
- Verify SigNoz connectivity
- Review log processing pipeline"
})

## Files Generated
- **Results**: `$ResultsFile`
- **Report**: `$ReportFile`

## Next Steps
1. Review results and system performance
2. $(if ($Metrics.ingestion_success_rate -lt 80) { "Investigate processing bottlenecks" } else { "Monitor system performance" })
3. Consider running full E2 ratio sweep for optimization
4. Set up continuous monitoring for queue pressure

---
*Generated by E2 Ratio Simple Analysis Script*
"@

Set-Content $ReportFile $Report -Encoding UTF8

Write-Host "`n✅ E2 Ratio Simple Analysis Complete!" -ForegroundColor Green
Write-Host "📊 Results saved to: $ResultsFile" -ForegroundColor Cyan
Write-Host "📄 Report saved to: $ReportFile" -ForegroundColor Cyan

# Display summary
Write-Host "`n📈 Quick Summary:" -ForegroundColor Cyan
Write-Host "  Test ID: $TestId" -ForegroundColor White
Write-Host "  Logs Generated: $($Metrics.logs_generated)" -ForegroundColor White
Write-Host "  Logs Processed: $($Metrics.logs_processed)" -ForegroundColor White
Write-Host "  Success Rate: $([math]::Round($Metrics.ingestion_success_rate, 1))%" -ForegroundColor $(if ($Metrics.ingestion_success_rate -gt 80) { "Green" } elseif ($Metrics.ingestion_success_rate -gt 50) { "Yellow" } else { "Red" })
Write-Host "  Status: $(if ($Metrics.ingestion_success_rate -gt 80) { "✅ Healthy" } elseif ($Metrics.ingestion_success_rate -gt 50) { "⚠️ Degraded" } else { "❌ Poor" })" -ForegroundColor $(if ($Metrics.ingestion_success_rate -gt 80) { "Green" } elseif ($Metrics.ingestion_success_rate -gt 50) { "Yellow" } else { "Red" })

Write-Host "`n🎯 Next: $(if ($Metrics.ingestion_success_rate -lt 80) { "Investigate processing issues" } else { "System performing well - consider full optimization sweep" })" -ForegroundColor Yellow