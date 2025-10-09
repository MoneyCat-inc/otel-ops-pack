# SSOT Usage Analysis
param(
    [int]$Days = 30,
    [string]$ReportPath = ".artifacts/improvement-reports"
)

function Get-UsageMetrics {
    param([int]$AnalysisDays)
    
    $metrics = @{
        HealthChecks = 0
        SSOTUpdates = 0
        AutomationRuns = 0
        ErrorCount = 0
        AverageHealthScore = 0
        PeakUsageHours = @()
        LowUsageHours = @()
        ErrorPatterns = @{}
        PerformanceTrends = @{}
    }
    
    # Analyze monitoring logs
    $monitoringLogs = Get-Content ".artifacts/production-monitoring.log" -ErrorAction SilentlyContinue
    if ($monitoringLogs) {
        $healthChecks = $monitoringLogs | Where-Object { $_ -match "Health Check" }
        $metrics.HealthChecks = $healthChecks.Count
        
        $ssotUpdates = $monitoringLogs | Where-Object { $_ -match "SSOT Update" }
        $metrics.SSOTUpdates = $ssotUpdates.Count
        
        $errors = $monitoringLogs | Where-Object { $_ -match "ERROR|FAILED|EXCEPTION" }
        $metrics.ErrorCount = $errors.Count
        
        # Extract health scores
        $healthScores = $monitoringLogs | Where-Object { $_ -match "Health Score: (\d+)%" } | ForEach-Object {
            if ($_ -match "Health Score: (\d+)%") { [int]$matches[1] }
        }
        if ($healthScores.Count -gt 0) {
            $metrics.AverageHealthScore = [math]::Round(($healthScores | Measure-Object -Average).Average, 2)
        }
        
        # Analyze time patterns
        $hourlyUsage = @{}
        foreach ($logEntry in $monitoringLogs) {
            if ($logEntry -match "(\d{4}-\d{2}-\d{2}T(\d{2}):\d{2}:\d{2}Z)") {
                $hour = [int]$matches[2]
                if (-not $hourlyUsage.ContainsKey($hour)) {
                    $hourlyUsage[$hour] = 0
                }
                $hourlyUsage[$hour]++
            }
        }
        
        # Identify peak and low usage hours
        $sortedHours = $hourlyUsage.GetEnumerator() | Sort-Object Value -Descending
        $metrics.PeakUsageHours = $sortedHours | Select-Object -First 5 | ForEach-Object { $_.Key }
        $metrics.LowUsageHours = $sortedHours | Select-Object -Last 5 | ForEach-Object { $_.Key }
    }
    
    # Analyze health reports
    $healthReports = Get-ChildItem ".artifacts/ssot-health-report.json" -ErrorAction SilentlyContinue
    if ($healthReports) {
        $latestReport = Get-Content $healthReports[0].FullName | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($latestReport) {
            $metrics.CurrentHealthScore = $latestReport.overall_health
            $metrics.CurrentFreshness = $latestReport.freshness_status
            $metrics.CurrentAccuracy = $latestReport.accuracy_status
        }
    }
    
    return $metrics
}

function Analyze-PerformanceTrends {
    param([hashtable]$Metrics)
    
    $trends = @{
        HealthTrend = "stable"
        UsageTrend = "stable"
        ErrorTrend = "stable"
        PerformanceTrend = "stable"
    }
    
    # Analyze health trend
    if ($Metrics.AverageHealthScore -ge 98) {
        $trends.HealthTrend = "excellent"
    } elseif ($Metrics.AverageHealthScore -ge 95) {
        $trends.HealthTrend = "good"
    } elseif ($Metrics.AverageHealthScore -ge 90) {
        $trends.HealthTrend = "declining"
    } else {
        $trends.HealthTrend = "poor"
    }
    
    # Analyze usage trend
    $healthCheckRate = $Metrics.HealthChecks / $Metrics.Days
    if ($healthCheckRate -gt 100) {
        $trends.UsageTrend = "high"
    } elseif ($healthCheckRate -gt 50) {
        $trends.UsageTrend = "moderate"
    } else {
        $trends.UsageTrend = "low"
    }
    
    # Analyze error trend
    $errorRate = $Metrics.ErrorCount / $Metrics.HealthChecks
    if ($errorRate -lt 0.01) {
        $trends.ErrorTrend = "low"
    } elseif ($errorRate -lt 0.05) {
        $trends.ErrorTrend = "moderate"
    } else {
        $trends.ErrorTrend = "high"
    }
    
    return $trends
}

function Generate-UsageReport {
    param([hashtable]$Metrics, [hashtable]$Trends, [string]$ReportPath)
    
    $timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'
    $reportFile = Join-Path $ReportPath "usage-analysis-$timestamp.json"
    
    $report = @{
        GeneratedAt = $timestamp
        AnalysisPeriod = "$($Metrics.Days) days"
        Summary = @{
            TotalHealthChecks = $Metrics.HealthChecks
            TotalSSOTUpdates = $Metrics.SSOTUpdates
            TotalErrors = $Metrics.ErrorCount
            AverageHealthScore = $Metrics.AverageHealthScore
            CurrentHealthScore = $Metrics.CurrentHealthScore
            ErrorRate = if ($Metrics.HealthChecks -gt 0) { [math]::Round(($Metrics.ErrorCount / $Metrics.HealthChecks) * 100, 2) } else { 0 }
        }
        Trends = $Trends
        UsagePatterns = @{
            PeakUsageHours = $Metrics.PeakUsageHours
            LowUsageHours = $Metrics.LowUsageHours
            HealthCheckRate = [math]::Round($Metrics.HealthChecks / $Metrics.Days, 2)
            SSOTUpdateRate = [math]::Round($Metrics.SSOTUpdates / $Metrics.Days, 2)
        }
        Recommendations = @()
    }
    
    # Generate recommendations based on analysis
    if ($Trends.HealthTrend -eq "declining" -or $Trends.HealthTrend -eq "poor") {
        $report.Recommendations += "Health score declining - investigate telemetry sources and SSOT generation"
    }
    
    if ($Trends.ErrorTrend -eq "high") {
        $report.Recommendations += "High error rate - review automation scripts and error handling"
    }
    
    if ($Metrics.PeakUsageHours -contains 9 -or $Metrics.PeakUsageHours -contains 10) {
        $report.Recommendations += "High usage during business hours - consider scaling during peak times"
    }
    
    if ($Metrics.AverageHealthScore -lt 95) {
        $report.Recommendations += "Average health score below 95% - optimize SSOT generation process"
    }
    
    $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportFile -Encoding UTF8
    
    return $report
}

# Main usage analysis
$metrics = Get-UsageMetrics -AnalysisDays $AnalysisDays
$metrics.Days = $AnalysisDays

$trends = Analyze-PerformanceTrends -Metrics $metrics
$usageReport = Generate-UsageReport -Metrics $metrics -Trends $trends -ReportPath $ReportPath

Write-Host "📊 Usage Analysis Results:" -ForegroundColor Green
Write-Host "   Health Checks: $($metrics.HealthChecks)" -ForegroundColor Cyan
Write-Host "   SSOT Updates: $($metrics.SSOTUpdates)" -ForegroundColor Cyan
Write-Host "   Errors: $($metrics.ErrorCount)" -ForegroundColor Cyan
Write-Host "   Average Health Score: $($metrics.AverageHealthScore)%" -ForegroundColor Cyan
Write-Host "   Error Rate: $($usageReport.Summary.ErrorRate)%" -ForegroundColor Cyan

Write-Host "📈 Trends:" -ForegroundColor Yellow
Write-Host "   Health Trend: $($trends.HealthTrend)" -ForegroundColor Cyan
Write-Host "   Usage Trend: $($trends.UsageTrend)" -ForegroundColor Cyan
Write-Host "   Error Trend: $($trends.ErrorTrend)" -ForegroundColor Cyan

Write-Host "💡 Recommendations:" -ForegroundColor Magenta
foreach ($recommendation in $usageReport.Recommendations) {
    Write-Host "   • $recommendation" -ForegroundColor Cyan
}

return $usageReport
