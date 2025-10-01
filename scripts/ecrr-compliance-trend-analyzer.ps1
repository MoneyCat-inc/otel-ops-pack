# ECRR Compliance Trend Analyzer
# Analyzes compliance trends over time and generates reports

param(
    [switch]$GenerateTrendReport,
    [switch]$ShowTrends,
    [string]$OutputPath = "artifacts/ecrr-compliance-trends.json",
    [int]$DaysToAnalyze = 30
)

# ECRR Trend Analyzer Configuration
$Config = @{
    ArtifactsPath = "artifacts"
    MaxHistoryDays = $DaysToAnalyze
    TrendThresholds = @{
        Improving = 5.0    # 5% improvement over baseline
        Declining = -5.0   # 5% decline from baseline
        Stable = 2.0       # Within 2% of baseline
    }
}

# Trend Analysis Structure
$TrendAnalysis = @{
    Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    AnalysisPeriod = @{
        StartDate = (Get-Date).AddDays(-$Config.MaxHistoryDays).ToString("yyyy-MM-dd")
        EndDate = (Get-Date).ToString("yyyy-MM-dd")
        DaysAnalyzed = $Config.MaxHistoryDays
    }
    TrendMetrics = @{
        OverallComplianceTrend = "UNKNOWN"
        TrendDirection = "UNKNOWN"
        TrendStrength = 0.0
        BaselineCompliance = 0.0
        CurrentCompliance = 0.0
        ComplianceChange = 0.0
    }
    DetailedTrends = @{
        FourSectionStructure = @{ Trend = "UNKNOWN"; Change = 0.0 }
        ECRRGate = @{ Trend = "UNKNOWN"; Change = 0.0 }
        ActorDeclaration = @{ Trend = "UNKNOWN"; Change = 0.0 }
        EvidenceReferences = @{ Trend = "UNKNOWN"; Change = 0.0 }
        StatusDeclaration = @{ Trend = "UNKNOWN"; Change = 0.0 }
        ProductionMarker = @{ Trend = "UNKNOWN"; Change = 0.0 }
    }
    Recommendations = @()
    HealthStatus = "UNKNOWN"
}

function Write-ECRRLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN" { "Yellow" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Get-HistoricalComplianceData {
    $historicalData = @()
    
    # Look for historical compliance reports (include current file)
    $artifactFiles = Get-ChildItem -Path $Config.ArtifactsPath -Filter "*compliance*.json" -Recurse -ErrorAction SilentlyContinue
    
    foreach ($file in $artifactFiles) {
        try {
            $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
            if ($content) {
                $data = $content | ConvertFrom-Json -ErrorAction SilentlyContinue
                if ($data -and $data.ComplianceRate) {
                    $historicalData += @{
                        Timestamp = $data.Timestamp
                        Date = if ($data.Timestamp -and $data.Timestamp -ne "") { $data.Timestamp.ToString().Split('T')[0] } else { $file.LastWriteTime.ToString("yyyy-MM-dd") }
                        ComplianceRate = $data.ComplianceRate
                        TotalReports = $data.TotalReports
                        CompliantReports = $data.CompliantReports
                        Breakdown = $data.ComplianceBreakdown
                        HealthStatus = $data.HealthStatus
                    }
                }
            }
        }
        catch {
            Write-ECRRLog "Error reading historical data from $($file.Name): $($_.Exception.Message)" "WARN"
        }
    }
    
    # Sort by date
    $historicalData = $historicalData | Sort-Object { [DateTime]$_.Date }
    
    Write-ECRRLog "Found $($historicalData.Count) historical compliance data points" "INFO"
    return $historicalData
}

function Analyze-ComplianceTrends {
    param([array]$HistoricalData)
    
    if ($HistoricalData.Count -lt 2) {
        Write-ECRRLog "Insufficient historical data for trend analysis (need at least 2 data points)" "WARN"
        return
    }
    
    # Calculate baseline (first data point) and current (last data point)
    $baseline = $HistoricalData[0]
    $current = $HistoricalData[-1]
    
    $TrendAnalysis.TrendMetrics.BaselineCompliance = $baseline.ComplianceRate
    $TrendAnalysis.TrendMetrics.CurrentCompliance = $current.ComplianceRate
    $TrendAnalysis.TrendMetrics.ComplianceChange = $current.ComplianceRate - $baseline.ComplianceRate
    
    # Determine trend direction and strength
    $change = $TrendAnalysis.TrendMetrics.ComplianceChange
    if ($change -gt $Config.TrendThresholds.Improving) {
        $TrendAnalysis.TrendMetrics.TrendDirection = "IMPROVING"
        $TrendAnalysis.TrendMetrics.OverallComplianceTrend = "IMPROVING"
        $TrendAnalysis.TrendMetrics.TrendStrength = [Math]::Min($change / 10.0, 1.0)  # Normalize to 0-1
    }
    elseif ($change -lt $Config.TrendThresholds.Declining) {
        $TrendAnalysis.TrendMetrics.TrendDirection = "DECLINING"
        $TrendAnalysis.TrendMetrics.OverallComplianceTrend = "DECLINING"
        $TrendAnalysis.TrendMetrics.TrendStrength = [Math]::Min([Math]::Abs($change) / 10.0, 1.0)
    }
    else {
        $TrendAnalysis.TrendMetrics.TrendDirection = "STABLE"
        $TrendAnalysis.TrendMetrics.OverallComplianceTrend = "STABLE"
        $TrendAnalysis.TrendMetrics.TrendStrength = 0.1
    }
    
    # Analyze breakdown trends if available
    if ($baseline.Breakdown -and $current.Breakdown) {
        foreach ($criterion in $TrendAnalysis.DetailedTrends.Keys) {
            if ($baseline.Breakdown.$criterion -and $current.Breakdown.$criterion) {
                $baselineRate = $baseline.Breakdown.$criterion.Rate
                $currentRate = $current.Breakdown.$criterion.Rate
                $change = $currentRate - $baselineRate
                
                $TrendAnalysis.DetailedTrends.$criterion.Change = $change
                
                if ($change -gt 2.0) {
                    $TrendAnalysis.DetailedTrends.$criterion.Trend = "IMPROVING"
                }
                elseif ($change -lt -2.0) {
                    $TrendAnalysis.DetailedTrends.$criterion.Trend = "DECLINING"
                }
                else {
                    $TrendAnalysis.DetailedTrends.$criterion.Trend = "STABLE"
                }
            }
        }
    }
    
    # Generate recommendations
    if ($TrendAnalysis.TrendMetrics.TrendDirection -eq "DECLINING") {
        $TrendAnalysis.Recommendations += "Compliance is declining. Investigate root causes and implement corrective actions."
        $TrendAnalysis.Recommendations += "Focus on criteria showing the largest declines: $($TrendAnalysis.DetailedTrends.Keys | Where-Object { $TrendAnalysis.DetailedTrends.$_.Trend -eq 'DECLINING' } | Join-String -Separator ', ')"
    }
    elseif ($TrendAnalysis.TrendMetrics.TrendDirection -eq "IMPROVING") {
        $TrendAnalysis.Recommendations += "Compliance is improving. Continue current practices and maintain momentum."
        $TrendAnalysis.Recommendations += "Focus on criteria still needing improvement: $($TrendAnalysis.DetailedTrends.Keys | Where-Object { $TrendAnalysis.DetailedTrends.$_.Trend -ne 'IMPROVING' -and $TrendAnalysis.DetailedTrends.$_.Trend -ne 'STABLE' } | Join-String -Separator ', ')"
    }
    else {
        $TrendAnalysis.Recommendations += "Compliance is stable. Consider setting higher targets for continuous improvement."
    }
    
    # Determine overall health status
    if ($TrendAnalysis.TrendMetrics.CurrentCompliance -ge 95 -and $TrendAnalysis.TrendMetrics.TrendDirection -ne "DECLINING") {
        $TrendAnalysis.HealthStatus = "EXCELLENT"
    }
    elseif ($TrendAnalysis.TrendMetrics.CurrentCompliance -ge 90 -and $TrendAnalysis.TrendMetrics.TrendDirection -ne "DECLINING") {
        $TrendAnalysis.HealthStatus = "GOOD"
    }
    elseif ($TrendAnalysis.TrendMetrics.TrendDirection -eq "IMPROVING") {
        $TrendAnalysis.HealthStatus = "IMPROVING"
    }
    elseif ($TrendAnalysis.TrendMetrics.TrendDirection -eq "DECLINING") {
        $TrendAnalysis.HealthStatus = "DECLINING"
    }
    else {
        $TrendAnalysis.HealthStatus = "STABLE"
    }
}

function Show-TrendSummary {
    Write-Host "`nECRR Compliance Trend Analysis" -ForegroundColor Cyan
    Write-Host ('=' * 50)
    
    Write-Host "`nAnalysis Period:" -ForegroundColor Cyan
    Write-Host "  From: $($TrendAnalysis.AnalysisPeriod.StartDate)" -ForegroundColor White
    Write-Host "  To: $($TrendAnalysis.AnalysisPeriod.EndDate)" -ForegroundColor White
    Write-Host "  Days: $($TrendAnalysis.AnalysisPeriod.DaysAnalyzed)" -ForegroundColor White
    
    Write-Host "`nOverall Trend:" -ForegroundColor Cyan
    $trendColor = switch ($TrendAnalysis.TrendMetrics.OverallComplianceTrend) {
        "IMPROVING" { "Green" }
        "DECLINING" { "Red" }
        default { "Yellow" }
    }
    Write-Host "  Direction: $($TrendAnalysis.TrendMetrics.OverallComplianceTrend)" -ForegroundColor $trendColor
    Write-Host "  Strength: $($TrendAnalysis.TrendMetrics.TrendStrength.ToString('P1'))" -ForegroundColor White
    Write-Host "  Change: $($TrendAnalysis.TrendMetrics.ComplianceChange.ToString('+0.0;-0.0;0.0'))%" -ForegroundColor $trendColor
    
    Write-Host "`nCompliance Metrics:" -ForegroundColor Cyan
    Write-Host "  Baseline: $($TrendAnalysis.TrendMetrics.BaselineCompliance)%" -ForegroundColor White
    Write-Host "  Current: $($TrendAnalysis.TrendMetrics.CurrentCompliance)%" -ForegroundColor White
    
    Write-Host "`nDetailed Trends:" -ForegroundColor Cyan
    foreach ($criterion in $TrendAnalysis.DetailedTrends.Keys) {
        $trend = $TrendAnalysis.DetailedTrends.$criterion
        $color = switch ($trend.Trend) {
            "IMPROVING" { "Green" }
            "DECLINING" { "Red" }
            default { "Yellow" }
        }
        Write-Host "  $criterion`: $($trend.Trend) ($($trend.Change.ToString('+0.0;-0.0;0.0'))%)" -ForegroundColor $color
    }
    
    Write-Host "`nRecommendations:" -ForegroundColor Cyan
    foreach ($recommendation in $TrendAnalysis.Recommendations) {
        Write-Host "  - $recommendation" -ForegroundColor Yellow
    }
    
    Write-Host "`nHealth Status: $($TrendAnalysis.HealthStatus)" -ForegroundColor $(switch ($TrendAnalysis.HealthStatus) {
        "EXCELLENT" { "Green" }
        "GOOD" { "Green" }
        "IMPROVING" { "Yellow" }
        "STABLE" { "Yellow" }
        default { "Red" }
    })
    Write-Host ('=' * 50)
}

function Save-TrendReport {
    param([string]$Path)
    $TrendAnalysis | ConvertTo-Json -Depth 10 | Out-File -FilePath $Path -Encoding UTF8
    Write-ECRRLog "Trend analysis report saved to: $Path" "SUCCESS"
}

# Main execution
try {
    Write-ECRRLog "Starting ECRR Compliance Trend Analysis..." "INFO"
    
    # Get historical data
    $historicalData = Get-HistoricalComplianceData
    
    if ($historicalData.Count -gt 0) {
        # Analyze trends
        Analyze-ComplianceTrends -HistoricalData $historicalData
        
        # Show summary if requested
        if ($ShowTrends) {
            Show-TrendSummary
        }
        
        # Save report if requested
        if ($GenerateTrendReport) {
            Save-TrendReport -Path $OutputPath
        }
        
        Write-ECRRLog "Trend analysis completed successfully" "SUCCESS"
    } else {
        Write-ECRRLog "No historical data found for trend analysis" "WARN"
        Write-ECRRLog "Run the compliance monitor a few times to generate historical data" "INFO"
    }
    
    # Return trend direction for scripting
    Write-Output $TrendAnalysis.TrendMetrics.TrendDirection
    
} catch {
    Write-ECRRLog "Error in trend analysis: $($_.Exception.Message)" "ERROR"
    exit 1
}
