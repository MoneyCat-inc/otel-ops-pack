# Sleek Pipeline Monitor - Optimized & Condensed
# Ultra-low latency monitoring with 200ms batches and optimized wiring
# Usage: pwsh -File scripts/monitor-sleek.ps1 -DurationMinutes 10

param(
    [int]$DurationMinutes = 10,
    [switch]$Continuous = $false,
    [switch]$ExportReport = $false
)

# Import optimized core
. .\scripts\optimized-monitoring-core.ps1

# Initialize with optimized settings
Initialize-OptimizedMonitoring @{
    BatchTimeout = 200ms
    BatchSize = 1024
    MaxConcurrency = 8
    MemoryLimit = 1024MB
}

Write-OptimizedLog "🚀 Sleek Pipeline Monitor v2.0" "INFO" "Cyan"
Write-OptimizedLog "Monitoring: 200ms batches, optimized wiring, sub-second latency" "INFO" "Gray"

$startTime = Get-Date
$endTime = $startTime.AddMinutes($DurationMinutes)
$monitoringData = @{
    StartTime = $startTime
    Metrics = @()
    Alerts = @()
}

# Optimized monitoring loop
$monitoringJobs = @()
$services = @("signoz", "otel-collector", "clickhouse")

try {
    while ((Get-Date) -lt $endTime -or $Continuous) {
        $loopStart = Get-Date
        
        # Parallel health checks
        $healthJobs = $services | ForEach-Object -Parallel {
            $service = $_
            $endpoint = switch ($service) {
                "signoz" { "http://localhost:8080/api/v1/health" }
                "otel-collector" { "http://localhost:13134/healthz" }
                "clickhouse" { "http://localhost:8123/ping" }
            }
            
            @{
                Service = $service
                Healthy = Test-ServiceHealth $service $endpoint
                Timestamp = Get-Date
            }
        } -ThrottleLimit 8
        
        # Collect metrics
        $metrics = Get-OptimizedMetrics "pipeline" @{
            HealthChecks = $healthJobs
            BatchSize = 1024
            BatchTimeout = 200
        }
        
        $monitoringData.Metrics += $metrics
        
        # Check for alerts
        $unhealthy = $healthJobs | Where-Object { -not $_.Healthy }
        if ($unhealthy.Count -gt 0) {
            $alert = @{
                Timestamp = Get-Date
                Type = "ServiceUnhealthy"
                Services = $unhealthy.Service
                Severity = "Warning"
            }
            $monitoringData.Alerts += $alert
            Write-OptimizedLog "Alert: Unhealthy services: $($unhealthy.Service -join ', ')" "WARN" "Yellow"
        }
        
        # Calculate loop time
        $loopTime = (Get-Date) - $loopStart
        $remainingTime = $endTime - (Get-Date)
        
        Write-OptimizedLog "Loop: $([math]::Round($loopTime.TotalMilliseconds))ms, Remaining: $([math]::Round($remainingTime.TotalMinutes, 1))min" "INFO" "Cyan"
        
        # Optimized sleep
        Start-Sleep -Milliseconds 200
    }
} finally {
    # Generate report
    $report = @{
        Summary = @{
            Duration = (Get-Date) - $startTime
            TotalMetrics = $monitoringData.Metrics.Count
            TotalAlerts = $monitoringData.Alerts.Count
            AverageLatency = ($monitoringData.Metrics | Measure-Object -Property { $_.Latency.HealthCheck } -Average).Average
        }
        Metrics = $monitoringData.Metrics
        Alerts = $monitoringData.Alerts
    }
    
    if ($ExportReport) {
        $reportPath = "artifacts/sleek-monitor-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
        $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding UTF8
        Write-OptimizedLog "Report exported: $reportPath" "SUCCESS" "Green"
    }
    
    Write-OptimizedLog "Monitoring complete" "SUCCESS" "Green"
    Write-OptimizedLog "Total metrics: $($report.Summary.TotalMetrics)" "INFO" "Cyan"
    Write-OptimizedLog "Total alerts: $($report.Summary.TotalAlerts)" "INFO" "Cyan"
    Write-OptimizedLog "Average latency: $([math]::Round($report.Summary.AverageLatency, 2))ms" "INFO" "Cyan"
}
