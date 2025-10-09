# Enhanced Analytics Monitoring Script
# Monitors Resonai analytics ingestion with TTV metrics and alerting
# Usage: pwsh -File scripts/enhanced-analytics-monitor.ps1 -DurationMinutes 10

param(
    [int]$DurationMinutes = 10,
    [switch]$ExportReport = $false,
    [string]$ReportPath = "artifacts\analytics-monitor-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
)

Set-StrictMode -Version 2
$ErrorActionPreference = "Continue"

Write-Host "📊 Enhanced Analytics Monitoring" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Monitoring duration: $DurationMinutes minutes" -ForegroundColor Gray
Write-Host ""

$startTime = Get-Date
$endTime = $startTime.AddMinutes($DurationMinutes)
$monitoringData = @()
$alerts = @()

# Get SigNoz auth headers if available
$script:sigNozHeaders = $null
$envToken = [Environment]::GetEnvironmentVariable('SIGNOZ_API_TOKEN')
if (-not $envToken) { $envToken = [Environment]::GetEnvironmentVariable('SIGNOZ_API_BEARER') }
if (-not $envToken) { $envToken = [Environment]::GetEnvironmentVariable('SIGNOZ_JWT') }
if ($envToken) { $script:sigNozHeaders = @{ Authorization = "Bearer $envToken" } }

function Get-AnalyticsMetrics {
    param([int]$MinutesBack = 5)
    
    $now = [long]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())
    $start = $now - [long]($MinutesBack * 60000)
    $filterExpression = "attributes.dataset = `"resonai_analytics`""
    
    # Get total count
    $countPayload = @{
        start = $start
        end = $now
        requestType = "raw"
        compositeQuery = @{
            queries = @(@{
                type = "builder_query"
                spec = @{
                    name = "analytics_count"
                    signal = "logs"
                    filter = @{ expression = $filterExpression }
                    order = @(@{ key = @{ name = "timestamp" }; direction = "desc" })
                    limit = 1000
                    offset = 0
                }
            })
        }
    } | ConvertTo-Json -Depth 8
    
    # Get TTV metrics
    $ttvPayload = @{
        start = $start
        end = $now
        requestType = "raw"
        compositeQuery = @{
            queries = @(@{
                type = "builder_query"
                spec = @{
                    name = "ttv_metrics"
                    signal = "logs"
                    filter = @{ expression = "$filterExpression AND attributes.ttv_ms exists" }
                    order = @(@{ key = @{ name = "timestamp" }; direction = "desc" })
                    limit = 100
                    offset = 0
                }
            })
        }
    } | ConvertTo-Json -Depth 8
    
    # Get event types breakdown
    $eventsPayload = @{
        start = $start
        end = $now
        requestType = "raw"
        compositeQuery = @{
            queries = @(@{
                type = "builder_query"
                spec = @{
                    name = "event_types"
                    signal = "logs"
                    filter = @{ expression = $filterExpression }
                    groupBy = @(@{ name = "attributes.event" })
                    order = @(@{ key = @{ name = "timestamp" }; direction = "desc" })
                    limit = 20
                    offset = 0
                }
            })
        }
    } | ConvertTo-Json -Depth 8
    
    $params = @{ Method = 'Post'; Uri = 'http://localhost:8080/api/v5/query_range'; ContentType = 'application/json'; TimeoutSec = 10 }
    if ($script:sigNozHeaders) { $params.Headers = $script:sigNozHeaders }
    
    $metrics = @{
        TotalCount = 0
        TTVMetrics = @{
            Count = 0
            P50 = 0
            P90 = 0
            P95 = 0
            Mean = 0
        }
        EventTypes = @{}
        ErrorRate = 0
        Timestamp = Get-Date
    }
    
    try {
        # Get total count
        $params.Body = $countPayload
        $countResponse = Invoke-RestMethod @params
        if ($countResponse -and $countResponse.data -and $countResponse.data.result) {
            $metrics.TotalCount = $countResponse.data.result[0].values.Count
        }
        
        # Get TTV metrics
        $params.Body = $ttvPayload
        $ttvResponse = Invoke-RestMethod @params
        if ($ttvResponse -and $ttvResponse.data -and $ttvResponse.data.result -and $ttvResponse.data.result[0].values) {
            $ttvValues = $ttvResponse.data.result[0].values | ForEach-Object {
                if ($_.attributes -and $_.attributes.ttv_ms) {
                    [int]$_.attributes.ttv_ms
                }
            } | Where-Object { $_ -gt 0 }
            
            if ($ttvValues.Count -gt 0) {
                $sortedTTV = $ttvValues | Sort-Object
                $metrics.TTVMetrics.Count = $ttvValues.Count
                $metrics.TTVMetrics.P50 = $sortedTTV[[Math]::Floor($sortedTTV.Count * 0.5)]
                $metrics.TTVMetrics.P90 = $sortedTTV[[Math]::Floor($sortedTTV.Count * 0.9)]
                $metrics.TTVMetrics.P95 = $sortedTTV[[Math]::Floor($sortedTTV.Count * 0.95)]
                $metrics.TTVMetrics.Mean = [Math]::Round(($ttvValues | Measure-Object -Average).Average, 2)
            }
        }
        
        # Get event types
        $params.Body = $eventsPayload
        $eventsResponse = Invoke-RestMethod @params
        if ($eventsResponse -and $eventsResponse.data -and $eventsResponse.data.result) {
            foreach ($eventGroup in $eventsResponse.data.result) {
                $eventName = $eventGroup.metric.attributes.event
                $eventCount = $eventGroup.values.Count
                $metrics.EventTypes[$eventName] = $eventCount
            }
        }
        
        return $metrics
        
    } catch {
        if ($_.Exception.Response -and $_.Exception.Response.StatusCode.value__ -eq 401) {
            Write-Host "   ⚠️ Authentication required - set SIGNOZ_API_TOKEN for detailed metrics" -ForegroundColor Yellow
            return $metrics
        } else {
            Write-Host "   ❌ Query failed: $($_.Exception.Message)" -ForegroundColor Red
            return $null
        }
    }
}

function Test-PipelineHealth {
    $health = @{
        ResonaiAPI = $false
        OTelCollector = $false
        SigNozUI = $false
        IngestionRate = 0
        LastIngestion = $null
    }
    
    # Test Resonai API
    try {
        $apiResponse = Invoke-RestMethod -Uri "http://localhost:3003/api/events" -Method GET -TimeoutSec 3
        $health.ResonaiAPI = $true
        $health.LastIngestion = $apiResponse.lastIngestion
    } catch {
        Write-Host "   ⚠️ Resonai API not responding" -ForegroundColor Yellow
    }
    
    # Test OTel Collector health
    try {
        $healthResponse = Invoke-WebRequest -Uri "http://localhost:13134/healthz" -TimeoutSec 3
        if ($healthResponse.StatusCode -eq 200) {
            $health.OTelCollector = $true
        }
    } catch {
        Write-Host "   ⚠️ OTel Collector health check failed" -ForegroundColor Yellow
    }
    
    # Test SigNoz UI
    try {
        $uiResponse = Invoke-WebRequest -Uri "http://localhost:8080" -UseBasicParsing -TimeoutSec 3
        if ($uiResponse.StatusCode -eq 200) {
            $health.SigNozUI = $true
        }
    } catch {
        Write-Host "   ⚠️ SigNoz UI not accessible" -ForegroundColor Yellow
    }
    
    return $health
}

function Write-MetricsDisplay {
    param($Metrics)
    
    if (-not $Metrics) {
        Write-Host "   📊 No metrics available" -ForegroundColor Yellow
        return
    }
    
    Write-Host "   📊 Analytics Events: $($Metrics.TotalCount)" -ForegroundColor Cyan
    
    if ($Metrics.TTVMetrics.Count -gt 0) {
        Write-Host "   ⏱️ TTV Metrics (ms):" -ForegroundColor Cyan
        Write-Host "      Mean: $($Metrics.TTVMetrics.Mean)" -ForegroundColor White
        Write-Host "      P50:  $($Metrics.TTVMetrics.P50)" -ForegroundColor White
        Write-Host "      P90:  $($Metrics.TTVMetrics.P90)" -ForegroundColor White
        Write-Host "      P95:  $($Metrics.TTVMetrics.P95)" -ForegroundColor White
    }
    
    if ($Metrics.EventTypes.Count -gt 0) {
        Write-Host "   📈 Event Types:" -ForegroundColor Cyan
        $topEvents = $Metrics.EventTypes.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 5
        foreach ($event in $topEvents) {
            Write-Host "      $($event.Key): $($event.Value)" -ForegroundColor White
        }
    }
}

function Check-Alerts {
    param($Metrics, $Health)
    
    $currentAlerts = @()
    
    # Check ingestion rate
    if ($Metrics -and $Metrics.TotalCount -eq 0) {
        $currentAlerts += @{
            Type = "NoIngestion"
            Severity = "Warning"
            Message = "No analytics events ingested in last 5 minutes"
            Timestamp = Get-Date
        }
    }
    
    # Check TTV thresholds
    if ($Metrics -and $Metrics.TTVMetrics.Count -gt 0) {
        if ($Metrics.TTVMetrics.P95 -gt 500) {
            $currentAlerts += @{
                Type = "HighTTV"
                Severity = "Warning"
                Message = "TTV P95 is high: $($Metrics.TTVMetrics.P95)ms"
                Timestamp = Get-Date
            }
        }
        
        if ($Metrics.TTVMetrics.Mean -gt 300) {
            $currentAlerts += @{
                Type = "HighMeanTTV"
                Severity = "Info"
                Message = "TTV Mean is elevated: $($Metrics.TTVMetrics.Mean)ms"
                Timestamp = Get-Date
            }
        }
    }
    
    # Check pipeline health
    if (-not $Health.ResonaiAPI) {
        $currentAlerts += @{
            Type = "APIUnavailable"
            Severity = "Critical"
            Message = "Resonai API is not responding"
            Timestamp = Get-Date
        }
    }
    
    if (-not $Health.OTelCollector) {
        $currentAlerts += @{
            Type = "CollectorUnhealthy"
            Severity = "Critical"
            Message = "OTel Collector health check failed"
            Timestamp = Get-Date
        }
    }
    
    return $currentAlerts
}

Write-Host "🔄 Starting monitoring loop..." -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop early" -ForegroundColor Gray
Write-Host ""

$iteration = 0
$lastMetrics = $null

try {
    while ((Get-Date) -lt $endTime) {
        $iteration++
        $timestamp = Get-Date -Format "HH:mm:ss"
        $remaining = ($endTime - (Get-Date)).TotalMinutes
        
        Write-Host "[$timestamp] Iteration $iteration (${remaining}m remaining)" -ForegroundColor Cyan
        
        # Get current metrics
        $currentMetrics = Get-AnalyticsMetrics -MinutesBack 5
        $currentHealth = Test-PipelineHealth
        
        # Display metrics
        Write-MetricsDisplay -Metrics $currentMetrics
        
        # Check for alerts
        $currentAlerts = Check-Alerts -Metrics $currentMetrics -Health $currentHealth
        
        if ($currentAlerts.Count -gt 0) {
            Write-Host "   🚨 Active Alerts:" -ForegroundColor Red
            foreach ($alert in $currentAlerts) {
                $alertIcon = switch ($alert.Severity) {
                    "Critical" { "🔴" }
                    "Warning" { "🟡" }
                    "Info" { "🔵" }
                    default { "⚪" }
                }
                Write-Host "      $alertIcon $($alert.Message)" -ForegroundColor Red
            }
            $alerts += $currentAlerts
        }
        
        # Store monitoring data
        $monitoringData += @{
            Timestamp = Get-Date
            Iteration = $iteration
            Metrics = $currentMetrics
            Health = $currentHealth
            Alerts = $currentAlerts
        }
        
        # Show trend
        if ($lastMetrics -and $currentMetrics) {
            $countDiff = $currentMetrics.TotalCount - $lastMetrics.TotalCount
            if ($countDiff -gt 0) {
                Write-Host "   📈 New events: +$countDiff" -ForegroundColor Green
            } elseif ($countDiff -eq 0) {
                Write-Host "   ➡️ No new events" -ForegroundColor Yellow
            }
        }
        
        $lastMetrics = $currentMetrics
        
        Write-Host ""
        
        # Sleep for next iteration (30 seconds)
        Start-Sleep -Seconds 30
    }
} catch {
    Write-Host "`nMonitoring interrupted." -ForegroundColor Yellow
}

Write-Host "✅ Monitoring complete!" -ForegroundColor Green
Write-Host ""

# Generate summary
$totalAlerts = $alerts.Count
$criticalAlerts = ($alerts | Where-Object { $_.Severity -eq "Critical" }).Count
$warningAlerts = ($alerts | Where-Object { $_.Severity -eq "Warning" }).Count

Write-Host "📊 Monitoring Summary:" -ForegroundColor Cyan
Write-Host "   Duration: $DurationMinutes minutes" -ForegroundColor White
Write-Host "   Iterations: $iteration" -ForegroundColor White
Write-Host "   Total Alerts: $totalAlerts" -ForegroundColor White
Write-Host "   Critical: $criticalAlerts" -ForegroundColor Red
Write-Host "   Warnings: $warningAlerts" -ForegroundColor Yellow

if ($lastMetrics) {
    Write-Host "   Final Event Count: $($lastMetrics.TotalCount)" -ForegroundColor White
    if ($lastMetrics.TTVMetrics.Count -gt 0) {
        Write-Host "   Final TTV P95: $($lastMetrics.TTVMetrics.P95)ms" -ForegroundColor White
    }
}

# Export report if requested
if ($ExportReport) {
    $report = @{
        ECRR = @{
            Examine = @{
                Environment = "Windows 11 + OTel + SigNoz"
                Timestamp = $startTime
                Pipeline = "Resonai API → OTel Collector → SigNoz → ClickHouse"
            }
            Clean = @{
                Actions = @("Monitored analytics ingestion", "Checked pipeline health", "Generated alerts")
                Duration = $DurationMinutes
            }
            Report = @{
                Artifacts = @($ReportPath)
                Evidence = @("Monitoring data collected", "Alerts generated", "Metrics tracked")
                Alerts = $alerts
            }
            Role = "Cursor Agent - Observability Copilot"
        }
        MonitoringData = $monitoringData
        Summary = @{
            StartTime = $startTime
            EndTime = Get-Date
            Duration = (Get-Date) - $startTime
            TotalIterations = $iteration
            TotalAlerts = $totalAlerts
            CriticalAlerts = $criticalAlerts
            WarningAlerts = $warningAlerts
            FinalMetrics = $lastMetrics
        }
    }
    
    # Create artifacts directory if it doesn't exist
    if (-not (Test-Path "artifacts")) {
        New-Item -ItemType Directory -Path "artifacts" -Force | Out-Null
    }
    
    $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $ReportPath -Encoding UTF8
    Write-Host ""
    Write-Host "📄 Report exported to: $ReportPath" -ForegroundColor Green
}

Write-Host ""
Write-Host "💡 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Open SigNoz UI: http://localhost:8080/logs" -ForegroundColor White
Write-Host "2. Filter: attributes.dataset = `"resonai_analytics`"" -ForegroundColor White
Write-Host "3. Set up alerts in SigNoz for automated monitoring" -ForegroundColor White
Write-Host "4. Run optimization: pwsh -File scripts/optimize-end-to-end-pipeline.ps1" -ForegroundColor White

# Exit with appropriate code based on alerts
if ($criticalAlerts -gt 0) {
    exit 2
} elseif ($warningAlerts -gt 0) {
    exit 1
} else {
    exit 0
}
