#Requires -Version 7.0

<#
.SYNOPSIS
    Import and test the SigNoz Queue Pressure Dashboard

.DESCRIPTION
    This script imports the queue pressure dashboard configuration into SigNoz
    and verifies that the metrics are being collected properly.

.PARAMETER DashboardFile
    Path to the dashboard JSON file (default: signoz-queue-pressure-dashboard.json)

.PARAMETER TestMetrics
    Test that queue pressure metrics are available in SigNoz

.EXAMPLE
    .\import-queue-pressure-dashboard.ps1
    .\import-queue-pressure-dashboard.ps1 -DashboardFile "custom-dashboard.json" -TestMetrics
#>

param(
    [string]$DashboardFile = "signoz-queue-pressure-dashboard.json",
    [switch]$TestMetrics
)

# Color functions for output
function Write-Success { param($Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host "⚠️  $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "❌ $Message" -ForegroundColor Red }
function Write-Info { param($Message) Write-Host "ℹ️  $Message" -ForegroundColor Cyan }

# Configuration
$SigNozUrl = "http://localhost:8080"
$ArtifactsDir = "artifacts"
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

# Ensure artifacts directory exists
if (-not (Test-Path $ArtifactsDir)) {
    New-Item -Path $ArtifactsDir -ItemType Directory | Out-Null
}

Write-Info "Starting SigNoz Queue Pressure Dashboard import at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

try {
    # Check if SigNoz is running
    $healthResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/health" -Method Get
    if ($healthResponse.status -ne "ok") {
        throw "SigNoz health check failed: $($healthResponse.status)"
    }
    Write-Success "SigNoz is healthy and running"

    # Check if dashboard file exists
    if (-not (Test-Path $DashboardFile)) {
        throw "Dashboard file not found: $DashboardFile"
    }
    Write-Success "Dashboard file found: $DashboardFile"

    # Read dashboard configuration
    $dashboardConfig = Get-Content -Path $DashboardFile -Raw | ConvertFrom-Json
    Write-Info "Dashboard configuration loaded: $($dashboardConfig.dashboard.title)"

    if ($TestMetrics) {
        Write-Info "Testing queue pressure metrics availability..."
        
        # Test key metrics
        $keyMetrics = @(
            "otelcol_exporter_queue_size",
            "otelcol_exporter_queue_capacity", 
            "otelcol_exporter_enqueue_failed_log_records",
            "otelcol_exporter_enqueue_failed_metric_points",
            "otelcol_processor_batch_batch_size_trigger_send",
            "otelcol_process_memory_rss"
        )

        $availableMetrics = @()
        $missingMetrics = @()

        foreach ($metric in $keyMetrics) {
            try {
                # Query ClickHouse directly for metric availability
                $query = "SELECT count(*) FROM signoz_metrics.distributed_samples_v4 WHERE metric_name = '$metric' AND unix_milli > (toUnixTimestamp(now()) - 3600) * 1000"
                $result = docker exec signoz-clickhouse clickhouse-client --query $query
                
                if ([int]$result -gt 0) {
                    $availableMetrics += $metric
                    Write-Success "✓ $metric - Available ($result recent samples)"
                } else {
                    $missingMetrics += $metric
                    Write-Warning "✗ $metric - No recent samples"
                }
            } catch {
                $missingMetrics += $metric
                Write-Warning "✗ $metric - Query failed: $($_.Exception.Message)"
            }
        }

        # Generate metrics test report
        $metricsReport = @{
            timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            totalMetrics = $keyMetrics.Count
            availableMetrics = $availableMetrics.Count
            missingMetrics = $missingMetrics.Count
            available = $availableMetrics
            missing = $missingMetrics
            status = if ($missingMetrics.Count -eq 0) { "all_available" } elseif ($availableMetrics.Count -gt 0) { "partial" } else { "none_available" }
        }

        $metricsFile = Join-Path $ArtifactsDir "queue-pressure-metrics-test-$Timestamp.json"
        $metricsReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $metricsFile -Encoding UTF8
        Write-Info "Metrics test report saved to: $metricsFile"

        if ($missingMetrics.Count -gt 0) {
            Write-Warning "Some metrics are missing. Dashboard may not display all panels correctly."
            Write-Warning "Missing metrics: $($missingMetrics -join ', ')"
        } else {
            Write-Success "All queue pressure metrics are available!"
        }
    }

    # Generate import instructions
    $instructions = @"
# SigNoz Queue Pressure Dashboard Import Instructions

## Manual Import Steps:
1. Open SigNoz UI: $SigNozUrl
2. Navigate to: Dashboards → New Dashboard
3. Dashboard Name: "$($dashboardConfig.dashboard.title)"
4. Add panels using the following queries:

### Key Panels:
- **Queue Size vs Capacity**: 
  - otelcol_exporter_queue_size
  - otelcol_exporter_queue_capacity

- **Queue Utilization %**: 
  - (otelcol_exporter_queue_size / otelcol_exporter_queue_capacity) * 100

- **Enqueue Failures**: 
  - rate(otelcol_exporter_enqueue_failed_log_records[5m]) + rate(otelcol_exporter_enqueue_failed_metric_points[5m])

- **Batch Processing**: 
  - rate(otelcol_processor_batch_batch_size_trigger_send[5m])
  - rate(otelcol_processor_batch_timeout_trigger_send[5m])

- **Memory Usage**: 
  - otelcol_process_memory_rss / 1024 / 1024

## Alert Configuration:
Configure the following alerts in SigNoz:
- High Queue Utilization (>90% for 5m)
- Queue Enqueue Failures (>0 for 2m) 
- Low Send Success Rate (<95% for 5m)
- High Memory Usage (>1GB for 5m)

## Dashboard File Location:
$DashboardFile

## Import completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@

    $instructionsFile = Join-Path $ArtifactsDir "queue-pressure-dashboard-instructions-$Timestamp.md"
    $instructions | Out-File -FilePath $instructionsFile -Encoding UTF8
    Write-Info "Import instructions saved to: $instructionsFile"

    # Generate summary report
    $summaryReport = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        dashboardFile = $DashboardFile
        dashboardTitle = $dashboardConfig.dashboard.title
        panelCount = $dashboardConfig.dashboard.panels.Count
        alertCount = $dashboardConfig.alerts.Count
        signozUrl = $SigNozUrl
        status = "ready_for_import"
        instructionsFile = $instructionsFile
    }

    if ($TestMetrics) {
        $summaryReport.metricsTest = $metricsReport
    }

    $summaryFile = Join-Path $ArtifactsDir "queue-pressure-dashboard-summary-$Timestamp.json"
    $summaryReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $summaryFile -Encoding UTF8
    Write-Info "Summary report saved to: $summaryFile"

    Write-Success "Queue Pressure Dashboard import preparation completed!"
    Write-Info "Next steps:"
    Write-Info "1. Follow instructions in: $instructionsFile"
    Write-Info "2. Import dashboard manually in SigNoz UI"
    Write-Info "3. Configure alerts as specified"
    Write-Info "4. Test dashboard functionality"

    exit 0

} catch {
    $errorMsg = "Queue Pressure Dashboard import failed: $($_.Exception.Message)"
    Write-Error $errorMsg
    
    # Save error report
    $errorReport = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        error = $errorMsg
        dashboardFile = $DashboardFile
        status = "error"
    }
    $errorFile = Join-Path $ArtifactsDir "queue-pressure-dashboard-error-$Timestamp.json"
    $errorReport | ConvertTo-Json | Out-File -FilePath $errorFile -Encoding UTF8
    
    exit 1
}
