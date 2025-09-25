#Requires -Version 7.0

<#
.SYNOPSIS
    Analyze SigNoz canary baseline patterns and suggest optimal thresholds

.DESCRIPTION
    This script analyzes historical canary monitoring data to compute optimal
    AlertThreshold and SpikeThreshold values based on statistical analysis
    of traffic patterns.

.PARAMETER AnalysisDays
    Number of days of historical data to analyze (default: 7)

.PARAMETER OutputFormat
    Output format: "console", "json", or "csv" (default: console)

.EXAMPLE
    .\analyze-canary-baseline.ps1
    .\analyze-canary-baseline.ps1 -AnalysisDays 14 -OutputFormat json
#>

param(
    [int]$AnalysisDays = 7,
    [ValidateSet("console", "json", "csv")]
    [string]$OutputFormat = "console"
)

# Configuration
$ArtifactsDir = "artifacts"

function Write-Info { param($Message) Write-Host "ℹ️  $Message" -ForegroundColor Cyan }

try {
    # Find historical monitoring reports
    $pattern = "signoz-canary-monitor-*.json"
    $reports = Get-ChildItem -Path $ArtifactsDir -Filter $pattern | 
               Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-$AnalysisDays) } |
               Sort-Object LastWriteTime

    if ($reports.Count -lt 5) {
        throw "Insufficient historical data: found $($reports.Count) reports, need at least 5"
    }

    # Analyze canary counts
    $canaryCounts = @()
    foreach ($report in $reports) {
        try {
            $data = Get-Content $report.FullName | ConvertFrom-Json
            $canaryCounts += [PSCustomObject]@{
                Timestamp = [DateTime]$data.timestamp
                CanaryCount = [int]$data.canaryCount
                Status = $data.status
            }
        } catch {
            Write-Warning "Failed to parse report $($report.Name): $($_.Exception.Message)"
        }
    }

    if ($canaryCounts.Count -eq 0) {
        throw "No valid monitoring data found in reports"
    }

    # Calculate statistics
    $stats = $canaryCounts | Measure-Object -Property CanaryCount -Average -Minimum -Maximum -StandardDeviation
    $median = ($canaryCounts | Sort-Object CanaryCount).CanaryCount[[Math]::Floor($canaryCounts.Count / 2)]
    
    # Calculate percentiles
    $sorted = $canaryCounts | Sort-Object CanaryCount
    $p5 = $sorted[[Math]::Floor($sorted.Count * 0.05)].CanaryCount
    $p10 = $sorted[[Math]::Floor($sorted.Count * 0.1)].CanaryCount
    $p25 = $sorted[[Math]::Floor($sorted.Count * 0.25)].CanaryCount
    $p75 = $sorted[[Math]::Floor($sorted.Count * 0.75)].CanaryCount
    $p90 = $sorted[[Math]::Floor($sorted.Count * 0.9)].CanaryCount
    $p95 = $sorted[[Math]::Floor($sorted.Count * 0.95)].CanaryCount
    $p99 = $sorted[[Math]::Floor($sorted.Count * 0.99)].CanaryCount

    # Calculate recommended thresholds using robust statistics
    $recommendedAlertThreshold = [Math]::Max(1, [Math]::Floor($p10 * 0.8))  # 20% below P10
    $recommendedSpikeThreshold = [Math]::Floor($p95 * 1.5)  # 50% above P95

    # Calculate confidence intervals
    $confidence95 = [Math]::Round($stats.StandardDeviation * 1.96, 1)
    $confidence99 = [Math]::Round($stats.StandardDeviation * 2.58, 1)

    # Create analysis result
    $analysis = [PSCustomObject]@{
        AnalysisPeriod = "$AnalysisDays days"
        SamplesAnalyzed = $canaryCounts.Count
        Statistics = @{
            Mean = [Math]::Round($stats.Average, 1)
            Median = $median
            Min = $stats.Minimum
            Max = $stats.Maximum
            StdDev = [Math]::Round($stats.StandardDeviation, 1)
            Percentiles = @{
                P5 = $p5
                P10 = $p10
                P25 = $p25
                P75 = $p75
                P90 = $p90
                P95 = $p95
                P99 = $p99
            }
            ConfidenceIntervals = @{
                CI95 = $confidence95
                CI99 = $confidence99
            }
        }
        RecommendedThresholds = @{
            AlertThreshold = $recommendedAlertThreshold
            SpikeThreshold = $recommendedSpikeThreshold
            Rationale = @{
                AlertThreshold = "20% below P10 ($p10) to catch significant drops"
                SpikeThreshold = "50% above P95 ($p95) to detect unusual spikes"
            }
        }
        TrafficPattern = @{
            Baseline = [Math]::Round($stats.Average, 0)
            Variability = if ($stats.StandardDeviation / $stats.Average -lt 0.1) { "Low" } 
                         elseif ($stats.StandardDeviation / $stats.Average -lt 0.3) { "Moderate" } 
                         else { "High" }
            Trend = "Stable"  # Could be enhanced with time-series analysis
        }
    }

    # Output based on format
    switch ($OutputFormat) {
        "json" {
            $analysis | ConvertTo-Json -Depth 4
        }
        "csv" {
            $analysis.Statistics.Percentiles.PSObject.Properties | ForEach-Object {
                [PSCustomObject]@{
                    Metric = "Percentile_$($_.Name)"
                    Value = $_.Value
                }
            } | Export-Csv -NoTypeInformation
        }
        default {
            Write-Host "📊 SigNoz Canary Baseline Analysis" -ForegroundColor Green
            Write-Host "=====================================" -ForegroundColor Green
            Write-Host ""
            Write-Host "Analysis Period: $($analysis.AnalysisPeriod)" -ForegroundColor Cyan
            Write-Host "Samples Analyzed: $($analysis.SamplesAnalyzed)" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "📈 Statistical Summary:" -ForegroundColor Yellow
            Write-Host "  Mean: $($analysis.Statistics.Mean)"
            Write-Host "  Median: $($analysis.Statistics.Median)"
            Write-Host "  Range: $($analysis.Statistics.Min) - $($analysis.Statistics.Max)"
            Write-Host "  Std Dev: $($analysis.Statistics.StdDev)"
            Write-Host ""
            Write-Host "📊 Percentiles:" -ForegroundColor Yellow
            Write-Host "  P5: $($analysis.Statistics.Percentiles.P5)  P10: $($analysis.Statistics.Percentiles.P10)"
            Write-Host "  P25: $($analysis.Statistics.Percentiles.P25)  P75: $($analysis.Statistics.Percentiles.P75)"
            Write-Host "  P90: $($analysis.Statistics.Percentiles.P90)  P95: $($analysis.Statistics.Percentiles.P95)"
            Write-Host "  P99: $($analysis.Statistics.Percentiles.P99)"
            Write-Host ""
            Write-Host "🎯 Recommended Thresholds:" -ForegroundColor Green
            Write-Host "  Alert Threshold: $($analysis.RecommendedThresholds.AlertThreshold)"
            Write-Host "    $($analysis.RecommendedThresholds.Rationale.AlertThreshold)"
            Write-Host "  Spike Threshold: $($analysis.RecommendedThresholds.SpikeThreshold)"
            Write-Host "    $($analysis.RecommendedThresholds.Rationale.SpikeThreshold)"
            Write-Host ""
            Write-Host "📋 Traffic Pattern:" -ForegroundColor Cyan
            Write-Host "  Baseline: ~$($analysis.TrafficPattern.Baseline) entries/hour"
            Write-Host "  Variability: $($analysis.TrafficPattern.Variability)"
            Write-Host "  Trend: $($analysis.TrafficPattern.Trend)"
            Write-Host ""
            Write-Host "💡 Usage:" -ForegroundColor Magenta
            Write-Host "  pwsh -File scripts/monitor-signoz-canary.ps1 -AlertThreshold $($analysis.RecommendedThresholds.AlertThreshold) -SpikeThreshold $($analysis.RecommendedThresholds.SpikeThreshold)"
        }
    }

    exit 0

} catch {
    Write-Error "Baseline analysis failed: $($_.Exception.Message)"
    exit 1
}
