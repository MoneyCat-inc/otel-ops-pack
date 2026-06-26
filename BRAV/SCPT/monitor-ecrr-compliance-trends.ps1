# ECRR Compliance Trends Monitoring Script
# Monitors compliance rates over time and alerts on trends

param(
    [string]$OutputPath = "artifacts/ecrr-compliance-trends.json",
    [switch]$GenerateReport,
    [switch]$AlertOnDecline,
    [int]$ThresholdPercent = 80
)

$script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$script:ArtifactsDirectory = Join-Path $script:RepoRoot 'artifacts'
if (-not (Test-Path $script:ArtifactsDirectory)) {
    New-Item -Path $script:ArtifactsDirectory -ItemType Directory -Force | Out-Null
}
if (-not [System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath = Join-Path $script:RepoRoot $OutputPath
}
$script:ReportsDirectory = Join-Path $script:RepoRoot 'CHAR/ECRR/ECRR_REPORTS'
$script:ComplianceReportPath = Join-Path $script:ArtifactsDirectory 'ecrr-compliance-report.json'
$script:TrendMarkdownPath = Join-Path $script:ArtifactsDirectory 'ecrr-compliance-trends-report.md'
$OutputDirectory = Split-Path -Parent $OutputPath
if ($OutputDirectory -and -not (Test-Path $OutputDirectory)) {
    New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
}
# Initialize OpenTelemetry functions
. $PSScriptRoot\..\otel\otel-functions.ps1

Write-Host "?? ECRR Compliance Trends Monitoring" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

function Get-CurrentComplianceMetrics {
    Write-Host "?? Running compliance validation..." -ForegroundColor Yellow

    $reportOutput = $script:ComplianceReportPath
    $validationScript = Join-Path $PSScriptRoot 'unified-ecrr-compliance.ps1'
    $validationResult = & $validationScript -ReportsPath $script:ReportsDirectory -OutputPath (Split-Path $reportOutput -Parent)

    if ($LASTEXITCODE -gt 2) {
        Write-Warning "Compliance validation failed with exit code $LASTEXITCODE"
        return $null
    }

    if (-not (Test-Path $reportOutput)) {
        Write-Error "Compliance report not found at $reportOutput"
        return $null
    }

    $report = Get-Content $reportOutput -Raw | ConvertFrom-Json

    # Use unified compliance data structure
    $totalReports = $report.metrics.totalReports
    $compliantReports = $report.fullyCompliantCount
    $nonCompliantReports = $report.nonCompliant.Count
    $complianceRate = $report.complianceRates.fullyCompliant

    return [ordered]@{
        Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        OverallScore = $report.metrics.hasFourSection + $report.metrics.hasEcrrGate + $report.metrics.hasActor + $report.metrics.hasProductionMarker
        TotalReports = $totalReports
        PassedReports = $compliantReports
        FailedReports = $nonCompliantReports
        ComplianceRate = $complianceRate
        Reports = $report.files
    }
}

function Get-HistoricalTrends {
    param([string]$Path)

    if (Test-Path $Path) {
        try {
            return Get-Content $Path -Raw | ConvertFrom-Json
        }
        catch {
            Write-Warning "Failed to load historical trends: $($_.Exception.Message)"
        }
    }

    return @{ HistoricalData = @() }
}

function Analyze-ComplianceTrends {
    param(
        [array]$HistoricalData,
        $CurrentMetrics
    )

    if ($HistoricalData.Count -lt 2) {
        return @{
            Trend = "Insufficient Data"
            TrendDirection = "Unknown"
            TrendPercentage = 0
            Recommendation = "Collect more data points for trend analysis"
            RecentAverage = $CurrentMetrics.ComplianceRate
            HistoricalAverage = $CurrentMetrics.ComplianceRate
        }
    }

    $recentData = $HistoricalData | Select-Object -Last 5
    $olderData = $HistoricalData | Select-Object -First ([math]::Max(1, $HistoricalData.Count - 5))

    $recentAverage = ($recentData | Measure-Object -Property ComplianceRate -Average).Average
    $historicalAverage = ($olderData | Measure-Object -Property ComplianceRate -Average).Average
    $trendPercentage = [math]::Round($recentAverage - $historicalAverage, 2)

    if ($trendPercentage -gt 2) {
        $trend = "Improving"
        $direction = "Upward"
        $recommendation = "Continue current practices - compliance trending upward"
    } elseif ($trendPercentage -lt -2) {
        $trend = "Declining"
        $direction = "Downward"
        $recommendation = "Review recent changes and consider additional training"
    } else {
        $trend = "Stable"
        $direction = "Flat"
        $recommendation = "Maintain current practices"
    }

    return @{
        Trend = $trend
        TrendDirection = $direction
        TrendPercentage = $trendPercentage
        Recommendation = $recommendation
        RecentAverage = [math]::Round($recentAverage, 2)
        HistoricalAverage = [math]::Round($historicalAverage, 2)
    }
}

function Generate-ComplianceReport {
    param(
        $CurrentMetrics,
        $TrendAnalysis,
        [array]$HistoricalData,
        [string]$ReportPath = $script:TrendMarkdownPath
    )

    $reportPath = $ReportPath

    $report = @"
# ECRR Compliance Trends Report

**Generated**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Report Period**: Last $($HistoricalData.Count) measurements

## ?? Current Compliance Status

- **Overall Score**: $($CurrentMetrics.OverallScore)/$($CurrentMetrics.TotalReports * 12)
- **Compliance Rate**: $($CurrentMetrics.ComplianceRate)%
- **Passed Reports**: $($CurrentMetrics.PassedReports)/$($CurrentMetrics.TotalReports)
- **Failed Reports**: $($CurrentMetrics.FailedReports)/$($CurrentMetrics.TotalReports)

## ?? Trend Analysis

- **Trend Direction**: $($TrendAnalysis.TrendDirection)
- **Trend Status**: $($TrendAnalysis.Trend)
- **Change**: $($TrendAnalysis.TrendPercentage)%
- **Recent Average**: $($TrendAnalysis.RecentAverage)%
- **Historical Average**: $($TrendAnalysis.HistoricalAverage)%

## ?? Recommendations

$($TrendAnalysis.Recommendation)

## ?? Detailed Report Analysis

### Reports with Issues
"@

    $failedReports = $CurrentMetrics.Reports | Where-Object { -not $_.Compliant }
    if ($failedReports.Count -gt 0) {
        foreach ($failedReport in $failedReports) {
            $report += @"

**$($failedReport.File)** - Score: $($failedReport.Score)/100
Issues: $($failedReport.Issues.Count)
"@
        }
    } else {
        $report += @"

*All reports are compliant!* ??
"@
    }

    $report += @"

### Historical Compliance Rate
"@

    foreach ($dataPoint in $HistoricalData | Select-Object -Last 10) {
        $report += @"

- **$($dataPoint.Timestamp)**: $($dataPoint.ComplianceRate)%
"@
    }

    $report | Set-Content -Path $reportPath -Encoding UTF8
    Write-Host "?? Compliance trends report generated: $reportPath" -ForegroundColor Green
}

function Ensure-ComplianceEventSource {
    param([string]$Source)

    try {
        if (-not [System.Diagnostics.EventLog]::SourceExists($Source)) {
            New-EventLog -LogName Application -Source $Source -ErrorAction Stop
        }
    }
    catch {
        Write-Warning "Unable to create event log source ${Source}: $($_.Exception.Message)"
    }
}

function Publish-ComplianceObservability {
    param(
        $CurrentMetrics,
        $TrendAnalysis,
        [int]$ThresholdPercent
    )

    $logDirectory = "C:/logs/ecrr"
    $logFile = Join-Path $logDirectory "compliance-trends.log"

    if (-not (Test-Path $logDirectory)) {
        New-Item -Path $logDirectory -ItemType Directory -Force | Out-Null
    }

    $record = @{
        timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ")
        dataset = "ecrr_compliance"
        event = "compliance_trend_calculated"
        overall_score = $CurrentMetrics.OverallScore
        total_reports = $CurrentMetrics.TotalReports
        passed_reports = $CurrentMetrics.PassedReports
        failed_reports = $CurrentMetrics.FailedReports
        compliance_rate = $CurrentMetrics.ComplianceRate
        trend = $TrendAnalysis.Trend
        trend_direction = $TrendAnalysis.TrendDirection
        trend_percentage = $TrendAnalysis.TrendPercentage
        recommendation = $TrendAnalysis.Recommendation
        threshold = $ThresholdPercent
    }

    $json = $record | ConvertTo-Json -Compress
    [System.IO.File]::AppendAllText($logFile, $json + [Environment]::NewLine, [System.Text.Encoding]::UTF8)

    $eventSource = "ECRRComplianceMonitor"
    Ensure-ComplianceEventSource -Source $eventSource

    $eventMessage = "dataset=ecrr_compliance; compliance_rate=$($CurrentMetrics.ComplianceRate); trend=$($TrendAnalysis.Trend); direction=$($TrendAnalysis.TrendDirection); change=$($TrendAnalysis.TrendPercentage)"
    try {
        Write-EventLog -LogName Application -Source $eventSource -EventId 4100 -EntryType Information -Message $eventMessage
    }
    catch {
        Write-Warning "Failed to write compliance event log entry: $($_.Exception.Message)"
    }
}

try {
    Write-Host "?? Starting ECRR compliance trends monitoring..." -ForegroundColor Green

    $currentMetrics = Get-CurrentComplianceMetrics
    if (-not $currentMetrics) {
        throw "Failed to get current compliance metrics"
    }

    $historicalData = Get-HistoricalTrends -Path $OutputPath
    $dataPoints = @()
    if ($historicalData -and $historicalData.HistoricalData) {
        $dataPoints = @($historicalData.HistoricalData)
    }

    $dataPoints += $currentMetrics

    $trendAnalysis = Analyze-ComplianceTrends -HistoricalData $dataPoints -CurrentMetrics $currentMetrics

    $updated = @{
        LastUpdated = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        HistoricalData = $dataPoints
        CurrentTrend = $trendAnalysis
    }

    $updated | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8

    Write-Host "" 
    Write-Host "?? Current Compliance Status:" -ForegroundColor Cyan
    Write-Host "   Overall Score: $($currentMetrics.OverallScore)/$($currentMetrics.TotalReports * 12)" -ForegroundColor White
    Write-Host "   Compliance Rate: $($currentMetrics.ComplianceRate)%" -ForegroundColor White
    Write-Host "   Passed Reports: $($currentMetrics.PassedReports)/$($currentMetrics.TotalReports)" -ForegroundColor White

    Write-Host ""
    Write-Host "?? Trend Analysis:" -ForegroundColor Cyan
    Write-Host "   Trend: $($trendAnalysis.Trend)" -ForegroundColor White
    Write-Host "   Direction: $($trendAnalysis.TrendDirection)" -ForegroundColor White
    Write-Host "   Change: $($trendAnalysis.TrendPercentage)%" -ForegroundColor White
    Write-Host "   Recommendation: $($trendAnalysis.Recommendation)" -ForegroundColor White

    if ($AlertOnDecline -and $trendAnalysis.TrendDirection -eq "Downward") {
        Write-Host ""
        Write-Host "??  ALERT: Compliance rate is declining!" -ForegroundColor Red
        Write-Host "   Current rate: $($currentMetrics.ComplianceRate)%" -ForegroundColor Red
        Write-Host "   Trend: $($trendAnalysis.TrendPercentage)% decline" -ForegroundColor Red
        Write-Host "   Action required: Review recent changes and consider additional training" -ForegroundColor Red
    }

    if ($currentMetrics.ComplianceRate -lt $ThresholdPercent) {
        Write-Host ""
        Write-Host "??  WARNING: Compliance rate below threshold!" -ForegroundColor Yellow
        Write-Host "   Current: $($currentMetrics.ComplianceRate)%" -ForegroundColor Yellow
        Write-Host "   Threshold: $ThresholdPercent%" -ForegroundColor Yellow
    }

    Publish-ComplianceObservability -CurrentMetrics $currentMetrics -TrendAnalysis $trendAnalysis -ThresholdPercent $ThresholdPercent

    if ($GenerateReport) {
        Generate-ComplianceReport -CurrentMetrics $currentMetrics -TrendAnalysis $trendAnalysis -HistoricalData $dataPoints
    }

    Write-Host ""
    Write-Host "? Compliance trends monitoring complete!" -ForegroundColor Green
    Write-Host "   Trends data saved to: $OutputPath" -ForegroundColor White

    exit 0
}
catch {
    Write-Error "Compliance trends monitoring failed: $($_.Exception.Message)"
    Write-Error "Stack trace: $($_.ScriptStackTrace)"
    exit 1
}




