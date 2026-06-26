# End-to-End Pipeline Test Script
# ECRR Framework: Examine → Clean → Report → Role
# Actor: Cursor Agent - Observability Copilot

param(
    [int]$TestDurationSeconds = 120,
    [switch]$Detailed
)

Write-Host "🧪 End-to-End Pipeline Test" -ForegroundColor Cyan
Write-Host "Actor: Cursor Agent - Observability Copilot" -ForegroundColor Gray
Write-Host ""

# Examine: System State Check
Write-Host "🔍 Examine: System State Check..." -ForegroundColor Yellow

$HealthChecks = @()

# Check Windows Collector Service
try {
    $Service = Get-Service otelcol-contrib -ErrorAction Stop
    if ($Service.Status -eq 'Running') {
        $HealthChecks += "✅ Windows Collector Service: Running"
    } else {
        $HealthChecks += "❌ Windows Collector Service: $($Service.Status)"
    }
} catch {
    $HealthChecks += "❌ Windows Collector Service: Not found"
}

# Check Collector Health Endpoint
try {
    $HealthResponse = Invoke-RestMethod -Uri "http://localhost:13134/healthz" -Method Get -TimeoutSec 5
    $HealthChecks += "✅ Collector Health: Healthy"
} catch {
    $HealthChecks += "❌ Collector Health: Unreachable"
}

# Check OTLP Ports
$OtlpPorts = @(5317, 5318)
foreach ($Port in $OtlpPorts) {
    try {
        $Connection = Test-NetConnection -ComputerName localhost -Port $Port -InformationLevel Quiet
        if ($Connection) {
            $HealthChecks += "✅ OTLP Port $Port : Listening"
        } else {
            $HealthChecks += "❌ OTLP Port $Port : Not listening"
        }
    } catch {
        $HealthChecks += "❌ OTLP Port $Port : Error"
    }
}

# Check SigNoz Ports
$SigNozPorts = @(4317, 4318)
foreach ($Port in $SigNozPorts) {
    try {
        $Connection = Test-NetConnection -ComputerName localhost -Port $Port -InformationLevel Quiet
        if ($Connection) {
            $HealthChecks += "✅ SigNoz Port $Port : Listening"
        } else {
            $HealthChecks += "❌ SigNoz Port $Port : Not listening"
        }
    } catch {
        $HealthChecks += "❌ SigNoz Port $Port : Error"
    }
}

# Check SigNoz UI
try {
    $UiResponse = Invoke-WebRequest -Uri "http://localhost:8080" -Method Get -TimeoutSec 5
    if ($UiResponse.StatusCode -eq 200) {
        $HealthChecks += "✅ SigNoz UI: Reachable"
    } else {
        $HealthChecks += "❌ SigNoz UI: HTTP $($UiResponse.StatusCode)"
    }
} catch {
    $HealthChecks += "❌ SigNoz UI: Unreachable"
}

# Display health checks
foreach ($check in $HealthChecks) {
    Write-Host "  $check" -ForegroundColor $(if ($check -match "✅") { "Green" } else { "Red" })
}

# Check for failures
$Failures = $HealthChecks | Where-Object { $_ -match "❌" }
if ($Failures.Count -gt 0) {
    Write-Host ""
    Write-Host "❌ System health check failed. Please fix issues before running pipeline test." -ForegroundColor Red
    return
}

# Clean: Generate Test Load
Write-Host ""
Write-Host "🧹 Clean: Generating Test Load..." -ForegroundColor Yellow

# Create test log directory
$TestLogDir = "C:\logs"
if (-not (Test-Path $TestLogDir)) {
    New-Item -Path $TestLogDir -ItemType Directory -Force | Out-Null
    Write-Host "  ✅ Created test log directory: $TestLogDir" -ForegroundColor Green
}

# Generate test logs
$TestLogPath = "$TestLogDir\pipeline-test.log"
$TestStartTime = Get-Date
$TestLogCount = 0

Write-Host "  📝 Generating test logs for $TestDurationSeconds seconds..." -ForegroundColor Cyan

for ($i = 1; $i -le $TestDurationSeconds; $i++) {
    $LogEntry = @{
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        level = "INFO"
        message = "Pipeline test log entry $i"
        test_id = "pipeline-test-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        iteration = $i
        source = "pipeline-test"
    } | ConvertTo-Json -Compress
    
    Add-Content -Path $TestLogPath -Value $LogEntry
    $TestLogCount++
    
    if ($i % 10 -eq 0) {
        Write-Host "    Generated $i logs..." -ForegroundColor Gray
    }
    
    Start-Sleep -Seconds 1
}

Write-Host "  ✅ Generated $TestLogCount test logs" -ForegroundColor Green

# Generate Windows Event Log entries
try {
    $EventId = 1001
    $Message = "Pipeline test event - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    
    # Create Application log entry
    New-EventLog -LogName Application -Source "PipelineTest" -ErrorAction SilentlyContinue
    Write-EventLog -LogName Application -Source "PipelineTest" -EventId $EventId -Message $Message -ErrorAction SilentlyContinue
    
    Write-Host "  ✅ Generated Windows Event Log entries" -ForegroundColor Green
} catch {
    Write-Host "  ⚠️ Could not generate Windows Event Log entries: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Send OTLP test data
try {
    $OtlpPayload = @{
        resourceLogs = @(
            @{
                resource = @{
                    attributes = @(
                        @{
                            key = "service.name"
                            value = @{
                                stringValue = "pipeline-test"
                            }
                        }
                    )
                }
                scopeLogs = @(
                    @{
                        scope = @{
                            name = "pipeline-test"
                        }
                        logRecords = @(
                            @{
                                timeUnixNano = [long]((Get-Date).ToUniversalTime() - [DateTime]"1970-01-01").TotalMilliseconds * 1000000
                                severityNumber = 9
                                severityText = "INFO"
                                body = @{
                                    stringValue = "OTLP pipeline test log entry"
                                }
                                attributes = @(
                                    @{
                                        key = "test.type"
                                        value = @{
                                            stringValue = "otlp-test"
                                        }
                                    }
                                )
                            }
                        )
                    }
                )
            }
        )
    } | ConvertTo-Json -Depth 10

    $Headers = @{
        "Content-Type" = "application/json"
    }

    $OtlpResponse = Invoke-RestMethod -Uri "http://localhost:5318/v1/logs" -Method Post -Body $OtlpPayload -Headers $Headers -ErrorAction Stop
    Write-Host "  ✅ Sent OTLP test data" -ForegroundColor Green
} catch {
    Write-Host "  ⚠️ Could not send OTLP test data: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Report: Pipeline Performance Analysis
Write-Host ""
Write-Host "📝 Report: Pipeline Performance Analysis..." -ForegroundColor Yellow

# Wait for processing
Write-Host "  ⏳ Waiting for log processing..." -ForegroundColor Cyan
Start-Sleep -Seconds 30

# Get final metrics
try {
    $MetricsResponse = Invoke-RestMethod -Uri "http://localhost:8888/metrics" -Method Get
    $Metrics = $MetricsResponse -split "`n"
    
    # Extract metrics
    $QueueSize = ($Metrics | Where-Object { $_ -match 'otelcol_exporter_queue_size.*(\d+)' } | ForEach-Object { [int]($_ -split '\s+')[-1] })[0]
    $QueueCapacity = ($Metrics | Where-Object { $_ -match 'otelcol_exporter_queue_capacity.*(\d+)' } | ForEach-Object { [int]($_ -split '\s+')[-1] })[0]
    $LogsAccepted = ($Metrics | Where-Object { $_ -match 'otelcol_receiver_accepted_log_records.*(\d+)' } | ForEach-Object { [int]($_ -split '\s+')[-1] }) | Measure-Object -Sum | Select-Object -ExpandProperty Sum
    $LogsSent = ($Metrics | Where-Object { $_ -match 'otelcol_exporter_sent_log_records.*(\d+)' } | ForEach-Object { [int]($_ -split '\s+')[-1] }) | Measure-Object -Sum | Select-Object -ExpandProperty Sum
    $BatchCount = ($Metrics | Where-Object { $_ -match 'otelcol_processor_batch_batch_send_size_count.*(\d+)' } | ForEach-Object { [int]($_ -split '\s+')[-1] }) | Measure-Object -Sum | Select-Object -ExpandProperty Sum
    $BatchSum = ($Metrics | Where-Object { $_ -match 'otelcol_processor_batch_batch_send_size_sum.*(\d+)' } | ForEach-Object { [int]($_ -split '\s+')[-1] }) | Measure-Object -Sum | Select-Object -ExpandProperty Sum
    
    $QueueUtilization = if ($QueueCapacity -gt 0) { [math]::Round(($QueueSize / $QueueCapacity) * 100, 2) } else { 0 }
    $AvgBatchSize = if ($BatchCount -gt 0) { [math]::Round($BatchSum / $BatchCount, 2) } else { 0 }
    $ProcessingRate = if ($TestDurationSeconds -gt 0) { [math]::Round($LogsAccepted / $TestDurationSeconds, 2) } else { 0 }
    $SuccessRate = if ($LogsAccepted -gt 0) { [math]::Round(($LogsSent / $LogsAccepted) * 100, 2) } else { 0 }
    
    Write-Host "  📊 Pipeline Performance Metrics:" -ForegroundColor Cyan
    Write-Host "    Queue Utilization: $QueueUtilization% ($QueueSize/$QueueCapacity)" -ForegroundColor White
    Write-Host "    Logs Accepted: $LogsAccepted" -ForegroundColor White
    Write-Host "    Logs Sent: $LogsSent" -ForegroundColor White
    Write-Host "    Success Rate: $SuccessRate%" -ForegroundColor White
    Write-Host "    Processing Rate: $ProcessingRate logs/second" -ForegroundColor White
    Write-Host "    Average Batch Size: $AvgBatchSize" -ForegroundColor White
    Write-Host "    Total Batches: $BatchCount" -ForegroundColor White
    
} catch {
    Write-Host "  ❌ Could not retrieve performance metrics: $($_.Exception.Message)" -ForegroundColor Red
}

# Role: Test Results and Recommendations
Write-Host ""
Write-Host "🎭 Role: Test Results and Recommendations..." -ForegroundColor Yellow

# Determine pipeline health
$PipelineHealth = "HEALTHY"
$Issues = @()

if ($SuccessRate -lt 95) {
    $PipelineHealth = "DEGRADED"
    $Issues += "Low success rate: $SuccessRate%"
}

if ($QueueUtilization -gt 80) {
    $PipelineHealth = "DEGRADED"
    $Issues += "High queue utilization: $QueueUtilization%"
}

if ($ProcessingRate -lt 1) {
    $PipelineHealth = "DEGRADED"
    $Issues += "Low processing rate: $ProcessingRate logs/second"
}

if ($Issues.Count -gt 0) {
    Write-Host "  ⚠️ Pipeline Status: $PipelineHealth" -ForegroundColor Yellow
    Write-Host "  Issues Found:" -ForegroundColor Yellow
    foreach ($issue in $Issues) {
        Write-Host "    • $issue" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ✅ Pipeline Status: $PipelineHealth" -ForegroundColor Green
}

# Generate test report
$ReportPath = "artifacts/end-to-end-pipeline-test-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
$ReportContent = @"
# End-to-End Pipeline Test Report

**Date**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  
**Actor**: Cursor Agent - Observability Copilot  
**Test Duration**: $TestDurationSeconds seconds

## System Health Check
$($HealthChecks -join "`n")

## Test Load Generated
- **Test Logs**: $TestLogCount logs to $TestLogPath
- **Windows Events**: Application log entries
- **OTLP Data**: Direct HTTP API calls

## Performance Results
- **Queue Utilization**: $QueueUtilization% ($QueueSize/$QueueCapacity)
- **Logs Accepted**: $LogsAccepted
- **Logs Sent**: $LogsSent
- **Success Rate**: $SuccessRate%
- **Processing Rate**: $ProcessingRate logs/second
- **Average Batch Size**: $AvgBatchSize
- **Total Batches**: $BatchCount

## Pipeline Status
**Status**: $PipelineHealth
$($Issues | ForEach-Object { "**Issues**: $_" } | Out-String)

## Recommendations
$(
    if ($Issues.Count -eq 0) {
        "✅ Pipeline is performing well. Monitor queue utilization and batch efficiency over time."
    } else {
        "⚠️ Address the identified issues to improve pipeline performance."
    }
)

## Next Steps
1. Monitor pipeline performance over extended periods
2. Set up automated alerts for queue pressure and success rate
3. Optimize batch configuration based on usage patterns
4. Implement canary testing for continuous validation

---
**Generated by**: End-to-End Pipeline Test Script  
**ECRR Framework**: Examine → Clean → Report → Role
"@

New-Item -Path (Split-Path $ReportPath -Parent) -ItemType Directory -Force | Out-Null
Set-Content -Path $ReportPath -Value $ReportContent
Write-Host "  📊 Test report saved to: $ReportPath" -ForegroundColor Green

Write-Host ""
Write-Host "✅ End-to-End Pipeline Test Complete!" -ForegroundColor Green
Write-Host "Pipeline Status: $PipelineHealth" -ForegroundColor $(if ($PipelineHealth -eq "HEALTHY") { "Green" } else { "Yellow" })
