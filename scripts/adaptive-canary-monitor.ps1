#Requires -Version 7.0

<#
.SYNOPSIS
    Adaptive SigNoz canary monitoring agent that analyzes patterns and adjusts thresholds

.DESCRIPTION
    This background agent analyzes historical canary monitoring data to detect drift
    in traffic patterns and automatically adjusts AlertThreshold and SpikeThreshold
    values. It runs daily to keep monitoring thresholds aligned with actual baseline.

.PARAMETER AnalysisDays
    Number of days of historical data to analyze (default: 7)

.PARAMETER MinSamples
    Minimum number of samples required for analysis (default: 24)

.PARAMETER DriftThreshold
    Percentage change that triggers threshold adjustment (default: 25%)

.PARAMETER DryRun
    Analyze and report but don't modify thresholds (default: false)

.EXAMPLE
    .\adaptive-canary-monitor.ps1
    .\adaptive-canary-monitor.ps1 -AnalysisDays 14 -DriftThreshold 15% -DryRun
#>

param(
    [int]$AnalysisDays = 7,
    [int]$MinSamples = 5,
    [decimal]$DriftThreshold = 0.25,  # 25%
    [switch]$DryRun
)

# Color functions for output
function Write-Success { param($Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host "⚠️  $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "❌ $Message" -ForegroundColor Red }
function Write-Info { param($Message) Write-Host "ℹ️  $Message" -ForegroundColor Cyan }

# Configuration
$ArtifactsDir = "artifacts"
$MonitorScript = "scripts\monitor-signoz-canary.ps1"
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

Write-Info "Starting adaptive canary monitoring analysis at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Info "Analysis period: $AnalysisDays days, Minimum samples: $MinSamples, Drift threshold: $($DriftThreshold * 100)%"

try {
    # Ensure artifacts directory exists
    if (-not (Test-Path $ArtifactsDir)) {
        New-Item -Path $ArtifactsDir -ItemType Directory | Out-Null
    }

    # Find historical monitoring reports
    $pattern = "signoz-canary-monitor-*.json"
    $reports = Get-ChildItem -Path $ArtifactsDir -Filter $pattern | 
               Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-$AnalysisDays) } |
               Sort-Object LastWriteTime

    if ($reports.Count -lt $MinSamples) {
        throw "Insufficient historical data: found $($reports.Count) reports, need at least $MinSamples"
    }

    Write-Info "Found $($reports.Count) monitoring reports from last $AnalysisDays days"

    # Analyze canary counts
    $canaryCounts = @()
    foreach ($report in $reports) {
        try {
            $data = Get-Content $report.FullName | ConvertFrom-Json
            $canaryCounts += [PSCustomObject]@{
                Timestamp = [DateTime]$data.timestamp
                CanaryCount = [int]$data.canaryCount
                Status = $data.status
                FileName = $report.Name
            }
        } catch {
            Write-Warning "Failed to parse report $($report.Name): $($_.Exception.Message)"
        }
    }

    if ($canaryCounts.Count -eq 0) {
        throw "No valid monitoring data found in reports"
    }

    # Calculate baseline statistics
    $stats = $canaryCounts | Measure-Object -Property CanaryCount -Average -Minimum -Maximum -StandardDeviation
    $median = ($canaryCounts | Sort-Object CanaryCount).CanaryCount[[Math]::Floor($canaryCounts.Count / 2)]
    
    # Calculate percentiles
    $sorted = $canaryCounts | Sort-Object CanaryCount
    $p10 = $sorted[[Math]::Floor($sorted.Count * 0.1)].CanaryCount
    $p90 = $sorted[[Math]::Floor($sorted.Count * 0.9)].CanaryCount
    $p95 = $sorted[[Math]::Floor($sorted.Count * 0.95)].CanaryCount

    Write-Info "Baseline Statistics:"
    Write-Info "  Samples: $($stats.Count)"
    Write-Info "  Average: $([Math]::Round($stats.Average, 1))"
    Write-Info "  Median: $median"
    Write-Info "  Min/Max: $($stats.Minimum)/$($stats.Maximum)"
    Write-Info "  StdDev: $([Math]::Round($stats.StandardDeviation, 1))"
    Write-Info "  P10/P90/P95: $p10/$p90/$p95"

    # Calculate recommended thresholds
    $recommendedAlertThreshold = [Math]::Max(1, [Math]::Floor($p10 * 0.8))  # 20% below P10
    $recommendedSpikeThreshold = [Math]::Floor($p95 * 1.5)  # 50% above P95

    Write-Info "Recommended Thresholds:"
    Write-Info "  Alert Threshold: $recommendedAlertThreshold (20% below P10: $p10)"
    Write-Info "  Spike Threshold: $recommendedSpikeThreshold (50% above P95: $p95)"

    # Check current thresholds
    $currentScript = Get-Content $MonitorScript
    $currentAlertMatch = $currentScript | Select-String 'AlertThreshold = (\d+)'
    $currentSpikeMatch = $currentScript | Select-String 'SpikeThreshold = (\d+)'
    
    if ($currentAlertMatch -and $currentSpikeMatch) {
        $currentAlertThreshold = [int]$currentAlertMatch.Matches[0].Groups[1].Value
        $currentSpikeThreshold = [int]$currentSpikeMatch.Matches[0].Groups[1].Value
        
        Write-Info "Current Thresholds:"
        Write-Info "  Alert Threshold: $currentAlertThreshold"
        Write-Info "  Spike Threshold: $currentSpikeThreshold"
        
        # Calculate drift
        $alertDrift = [Math]::Abs($currentAlertThreshold - $recommendedAlertThreshold) / [Math]::Max($currentAlertThreshold, $recommendedAlertThreshold)
        $spikeDrift = [Math]::Abs($currentSpikeThreshold - $recommendedSpikeThreshold) / [Math]::Max($currentSpikeThreshold, $recommendedSpikeThreshold)
        
        Write-Info "Drift Analysis:"
        Write-Info "  Alert drift: $([Math]::Round($alertDrift * 100, 1))%"
        Write-Info "  Spike drift: $([Math]::Round($spikeDrift * 100, 1))%"
        
        $needsAdjustment = $alertDrift -gt $DriftThreshold -or $spikeDrift -gt $DriftThreshold
        
        if ($needsAdjustment) {
            if ($DryRun) {
                Write-Warning "DRY RUN: Would adjust thresholds to Alert=$recommendedAlertThreshold, Spike=$recommendedSpikeThreshold"
            } else {
                Write-Warning "Adjusting thresholds due to drift > $($DriftThreshold * 100)%"
                
                # Create backup of current script
                $backupFile = "$MonitorScript.backup-$Timestamp"
                Copy-Item $MonitorScript $backupFile
                Write-Info "Backup created: $backupFile"
                
                # Update thresholds in script
                $newScript = $currentScript -replace 'AlertThreshold = \d+', "AlertThreshold = $recommendedAlertThreshold"
                $newScript = $newScript -replace 'SpikeThreshold = \d+', "SpikeThreshold = $recommendedSpikeThreshold"
                
                # Update parameter descriptions
                $newScript = $newScript -replace '\(default: \d+, adjusted for observed baseline ~\d+/hour\)', "(default: $recommendedAlertThreshold, adjusted for observed baseline ~$([Math]::Round($stats.Average, 0))/hour)"
                $newScript = $newScript -replace '\(default: \d+, ~\d+% above baseline\)', "(default: $recommendedSpikeThreshold, ~50% above P95)"
                
                $newScript | Out-File -FilePath $MonitorScript -Encoding UTF8
                Write-Success "Thresholds updated: Alert=$recommendedAlertThreshold, Spike=$recommendedSpikeThreshold"
                
                # Test the updated script
                Write-Info "Testing updated monitoring script..."
                $testResult = & pwsh -File $MonitorScript -TimeWindowMinutes 60 2>&1
                $exitCode = $LASTEXITCODE
                
                if ($exitCode -eq 0 -or $exitCode -eq 1) {
                    Write-Success "Updated monitoring script tested successfully (exit code: $exitCode)"
                } else {
                    Write-Error "Updated monitoring script failed test (exit code: $exitCode)"
                    # Restore backup
                    Copy-Item $backupFile $MonitorScript -Force
                    Write-Warning "Restored backup due to test failure"
                }
            }
        } else {
            Write-Success "Thresholds are within acceptable drift range - no adjustment needed"
        }
    } else {
        Write-Warning "Could not parse current thresholds from script"
    }

    # Generate analysis report
    $analysisReport = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        analysisDays = $AnalysisDays
        samplesAnalyzed = $canaryCounts.Count
        baselineStats = @{
            average = [Math]::Round($stats.Average, 1)
            median = $median
            minimum = $stats.Minimum
            maximum = $stats.Maximum
            standardDeviation = [Math]::Round($stats.StandardDeviation, 1)
            p10 = $p10
            p90 = $p90
            p95 = $p95
        }
        currentThresholds = @{
            alert = $currentAlertThreshold
            spike = $currentSpikeThreshold
        }
        recommendedThresholds = @{
            alert = $recommendedAlertThreshold
            spike = $recommendedSpikeThreshold
        }
        driftAnalysis = @{
            alertDriftPercent = [Math]::Round($alertDrift * 100, 1)
            spikeDriftPercent = [Math]::Round($spikeDrift * 100, 1)
            needsAdjustment = $needsAdjustment
        }
        action = if ($DryRun) { "dry-run" } elseif ($needsAdjustment) { "adjusted" } else { "no-change" }
    }

    $reportFile = Join-Path $ArtifactsDir "adaptive-canary-analysis-$Timestamp.json"
    $analysisReport | ConvertTo-Json -Depth 4 | Out-File -FilePath $reportFile -Encoding UTF8
    Write-Info "Analysis report saved to: $reportFile"

    # Cleanup old analysis reports (keep last 30 days)
    $oldReports = Get-ChildItem -Path $ArtifactsDir -Filter "adaptive-canary-analysis-*.json" |
                  Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) }
    if ($oldReports) {
        $oldReports | Remove-Item
        Write-Info "Cleaned up $($oldReports.Count) old analysis reports"
    }

    exit 0

} catch {
    $errorMsg = "Adaptive canary monitoring failed: $($_.Exception.Message)"
    Write-Error $errorMsg
    
    # Save error report
    $errorReport = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        error = $errorMsg
        analysisDays = $AnalysisDays
        minSamples = $MinSamples
        driftThreshold = $DriftThreshold
        dryRun = $DryRun
    }
    $errorFile = Join-Path $ArtifactsDir "adaptive-canary-analysis-error-$Timestamp.json"
    $errorReport | ConvertTo-Json | Out-File -FilePath $errorFile -Encoding UTF8
    
    exit 1
}
