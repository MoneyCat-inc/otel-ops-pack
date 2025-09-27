# SSOT Monitoring Enhancement
param(
    [hashtable]$UsageData,
    [string]$ReportPath = ".artifacts/improvement-reports"
)

function Enhance-MonitoringAlerts {
    param([hashtable]$UsageData)
    
    $alertEnhancements = @{
        HealthThresholds = @{
            Critical = 90
            Warning = 95
            Info = 98
        }
        ErrorThresholds = @{
            Critical = 10
            Warning = 5
            Info = 2
        }
        PerformanceThresholds = @{
            ResponseTimeCritical = 10
            ResponseTimeWarning = 5
            ResponseTimeInfo = 2
        }
        CustomAlerts = @()
    }
    
    # Adjust thresholds based on usage patterns
    if ($UsageData.Summary.AverageHealthScore -gt 98) {
        $alertEnhancements.HealthThresholds.Critical = 85
        $alertEnhancements.HealthThresholds.Warning = 90
        Write-Host "📈 High performance system - adjusting health thresholds" -ForegroundColor Green
    }
    
    if ($UsageData.Summary.ErrorRate -gt 5) {
        $alertEnhancements.ErrorThresholds.Critical = 5
        $alertEnhancements.ErrorThresholds.Warning = 3
        Write-Host "⚠️ High error rate system - tightening error thresholds" -ForegroundColor Yellow
    }
    
    # Add custom alerts based on patterns
    if ($UsageData.UsagePatterns.PeakUsageHours -contains 9) {
        $alertEnhancements.CustomAlerts += @{
            Name = "Morning Peak Load Alert"
            Condition = "hour == 9 AND health_score < 95"
            Severity = "warning"
            Message = "Health score below threshold during morning peak hours"
        }
    }
    
    if ($UsageData.Summary.ErrorRate -gt 3) {
        $alertEnhancements.CustomAlerts += @{
            Name = "Error Rate Spike Alert"
            Condition = "error_rate > 5% for 10 minutes"
            Severity = "critical"
            Message = "Error rate spike detected - immediate attention required"
        }
    }
    
    return $alertEnhancements
}

function Enhance-MonitoringDashboard {
    param([hashtable]$UsageData)
    
    $dashboardEnhancements = @{
        NewPanels = @()
        EnhancedPanels = @()
        CustomMetrics = @()
    }
    
    # Add usage pattern panels
    $dashboardEnhancements.NewPanels += @{
        Title = "Usage Patterns by Hour"
        Type = "bar_chart"
        Data = $UsageData.UsagePatterns
        Description = "Health check frequency by hour of day"
    }
    
    # Add trend analysis panels
    $dashboardEnhancements.NewPanels += @{
        Title = "Health Score Trends"
        Type = "line_chart"
        Data = @{
            Current = $UsageData.Summary.CurrentHealthScore
            Average = $UsageData.Summary.AverageHealthScore
            Trend = $UsageData.Trends.HealthTrend
        }
        Description = "Health score trends over time"
    }
    
    # Add error analysis panels
    $dashboardEnhancements.NewPanels += @{
        Title = "Error Rate Analysis"
        Type = "gauge"
        Data = @{
            Current = $UsageData.Summary.ErrorRate
            Trend = $UsageData.Trends.ErrorTrend
            Threshold = 5
        }
        Description = "Error rate analysis and trends"
    }
    
    # Add custom metrics
    $dashboardEnhancements.CustomMetrics += @{
        Name = "health_score_trend"
        Formula = "average(health_score) over 24h"
        Description = "24-hour health score trend"
    }
    
    $dashboardEnhancements.CustomMetrics += @{
        Name = "error_rate_trend"
        Formula = "sum(errors) / sum(health_checks) * 100"
        Description = "Error rate trend calculation"
    }
    
    return $dashboardEnhancements
}

function Generate-MonitoringEnhancements {
    param([hashtable]$UsageData, [string]$ReportPath)
    
    $timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'
    $reportFile = Join-Path $ReportPath "monitoring-enhancement-$timestamp.json"
    
    $alertEnhancements = Enhance-MonitoringAlerts -UsageData $UsageData
    $dashboardEnhancements = Enhance-MonitoringDashboard -UsageData $UsageData
    
    $enhancementReport = @{
        GeneratedAt = $timestamp
        AlertEnhancements = $alertEnhancements
        DashboardEnhancements = $dashboardEnhancements
        ImplementationSteps = @(
            "Update alert thresholds in monitoring scripts"
            "Add new dashboard panels to monitoring dashboard"
            "Implement custom metrics collection"
            "Test enhanced monitoring in staging environment"
            "Deploy enhanced monitoring to production"
        )
    }
    
    $enhancementReport | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportFile -Encoding UTF8
    
    return $enhancementReport
}

# Main monitoring enhancement
if ($UsageData) {
    $monitoringResults = Generate-MonitoringEnhancements -UsageData $UsageData -ReportPath $ReportPath
    
    Write-Host "📊 Monitoring Enhancement Results:" -ForegroundColor Green
    Write-Host "   New Alert Thresholds: $($monitoringResults.AlertEnhancements.HealthThresholds.Critical)% critical, $($monitoringResults.AlertEnhancements.HealthThresholds.Warning)% warning" -ForegroundColor Cyan
    Write-Host "   New Dashboard Panels: $($monitoringResults.DashboardEnhancements.NewPanels.Count)" -ForegroundColor Cyan
    Write-Host "   Custom Metrics: $($monitoringResults.DashboardEnhancements.CustomMetrics.Count)" -ForegroundColor Cyan
    Write-Host "   Custom Alerts: $($monitoringResults.AlertEnhancements.CustomAlerts.Count)" -ForegroundColor Cyan
    
    Write-Host "📋 Implementation Steps:" -ForegroundColor Yellow
    foreach ($step in $monitoringResults.ImplementationSteps) {
        Write-Host "   • $step" -ForegroundColor Cyan
    }
    
    return $monitoringResults
} else {
    Write-Host "❌ No usage data provided for monitoring enhancement" -ForegroundColor Red
    return $null
}
