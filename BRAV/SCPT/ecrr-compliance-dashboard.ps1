# ECRR Compliance Dashboard
# Provides a comprehensive dashboard view of ECRR compliance status

param(
    [switch]$ShowDashboard,
    [switch]$GenerateHTML,
    [string]$OutputPath = "artifacts/ecrr-compliance-dashboard.html",
    [switch]$AutoRefresh,
    [int]$RefreshInterval = 30
)

# Dashboard Configuration
$Config = @{
    ArtifactsPath = "artifacts"
    ComplianceThreshold = 95.0
    WarningThreshold = 80.0
    CriticalThreshold = 60.0
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

function Get-ComplianceData {
    $complianceFile = Join-Path $Config.ArtifactsPath "ecrr-compliance-monitor.json"
    $trendFile = Join-Path $Config.ArtifactsPath "ecrr-compliance-trends.json"
    
    $complianceData = $null
    $trendData = $null
    
    # Load compliance data
    if (Test-Path $complianceFile) {
        try {
            $content = Get-Content -Path $complianceFile -Raw
            $complianceData = $content | ConvertFrom-Json
        }
        catch {
            Write-ECRRLog "Error loading compliance data: $($_.Exception.Message)" "ERROR"
        }
    }
    
    # Load trend data
    if (Test-Path $trendFile) {
        try {
            $content = Get-Content -Path $trendFile -Raw
            $trendData = $content | ConvertFrom-Json
        }
        catch {
            Write-ECRRLog "Error loading trend data: $($_.Exception.Message)" "WARN"
        }
    }
    
    return @{
        Compliance = $complianceData
        Trends = $trendData
    }
}

function Show-ComplianceDashboard {
    $data = Get-ComplianceData
    
    if (-not $data.Compliance) {
        Write-ECRRLog "No compliance data available. Run the compliance monitor first." "ERROR"
        return
    }
    
    # Clear screen and show header (skip if not in interactive console)
    try {
        Clear-Host
    } catch {
        # Ignore clear host errors in non-interactive environments
    }
    Write-Host "ECRR Compliance Dashboard" -ForegroundColor Cyan
    Write-Host "========================" -ForegroundColor Cyan
    Write-Host "Last Updated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White
    Write-Host ""
    
    # Overall compliance status
    $compliance = $data.Compliance.ComplianceRate
    $totalReports = $data.Compliance.TotalReports
    $compliantReports = $data.Compliance.CompliantReports
    
    $statusColor = if ($compliance -ge $Config.ComplianceThreshold) { "Green" }
                   elseif ($compliance -ge $Config.WarningThreshold) { "Yellow" }
                   else { "Red" }
    
    $statusText = if ($compliance -ge $Config.ComplianceThreshold) { "HEALTHY" }
                  elseif ($compliance -ge $Config.WarningThreshold) { "WARNING" }
                  else { "CRITICAL" }
    
    Write-Host "Overall Compliance Status" -ForegroundColor Cyan
    Write-Host "------------------------" -ForegroundColor Cyan
    Write-Host "Status: $statusText" -ForegroundColor $statusColor
    Write-Host "Rate: $compliance% ($compliantReports/$totalReports reports)" -ForegroundColor $statusColor
    Write-Host ""
    
    # Compliance breakdown
    Write-Host "Compliance Breakdown" -ForegroundColor Cyan
    Write-Host "-------------------" -ForegroundColor Cyan
    foreach ($criterion in $data.Compliance.ComplianceBreakdown.Keys) {
        $breakdown = $data.Compliance.ComplianceBreakdown.$criterion
        $rate = $breakdown.Rate
        $color = if ($rate -ge 95) { "Green" } elseif ($rate -ge 80) { "Yellow" } else { "Red" }
        Write-Host "  $criterion`: $rate% ($($breakdown.Compliant)/$($breakdown.Total))" -ForegroundColor $color
    }
    Write-Host ""
    
    # Agent distribution (top 10)
    Write-Host "Top Agent Contributors" -ForegroundColor Cyan
    Write-Host "---------------------" -ForegroundColor Cyan
    $agentData = $data.Compliance.AgentDistribution | Get-Member -MemberType NoteProperty | Sort-Object { $data.Compliance.AgentDistribution.$($_.Name) } -Descending | Select-Object -First 10
    foreach ($agent in $agentData) {
        $count = $data.Compliance.AgentDistribution.$($agent.Name)
        $percentage = [Math]::Round(($count / $totalReports) * 100, 1)
        Write-Host "  $($agent.Name): $count reports ($percentage%)" -ForegroundColor White
    }
    Write-Host ""
    
    # Report categories
    Write-Host "Report Categories" -ForegroundColor Cyan
    Write-Host "----------------" -ForegroundColor Cyan
    foreach ($category in $data.Compliance.ReportCategories.Keys) {
        $count = $data.Compliance.ReportCategories.$category
        $percentage = [Math]::Round(($count / $totalReports) * 100, 1)
        Write-Host "  $category`: $count reports ($percentage%)" -ForegroundColor White
    }
    Write-Host ""
    
    # Non-compliant reports (top 10)
    if ($data.Compliance.NonCompliantReports.Count -gt 0) {
        Write-Host "Non-Compliant Reports (Top 10)" -ForegroundColor Yellow
        Write-Host "-----------------------------" -ForegroundColor Yellow
        $nonCompliantReports = $data.Compliance.NonCompliantReports | Select-Object -First 10
        foreach ($report in $nonCompliantReports) {
            Write-Host "  $($report.File): $($report.Issues -join ', ')" -ForegroundColor Red
        }
        if ($data.Compliance.NonCompliantReports.Count -gt 10) {
            Write-Host "  ... and $($data.Compliance.NonCompliantReports.Count - 10) more" -ForegroundColor Red
        }
        Write-Host ""
    }
    
    # Trend information
    if ($data.Trends) {
        Write-Host "Trend Analysis" -ForegroundColor Cyan
        Write-Host "-------------" -ForegroundColor Cyan
        $trendDirection = $data.Trends.TrendMetrics.TrendDirection
        $trendColor = switch ($trendDirection) {
            "IMPROVING" { "Green" }
            "DECLINING" { "Red" }
            default { "Yellow" }
        }
        Write-Host "  Direction: $trendDirection" -ForegroundColor $trendColor
        Write-Host "  Change: $($data.Trends.TrendMetrics.ComplianceChange.ToString('+0.0;-0.0;0.0'))%" -ForegroundColor $trendColor
        Write-Host "  Health: $($data.Trends.HealthStatus)" -ForegroundColor $trendColor
        Write-Host ""
    }
    
    # Recommendations
    if ($data.Compliance.Recommendations.Count -gt 0) {
        Write-Host "Recommendations" -ForegroundColor Cyan
        Write-Host "--------------" -ForegroundColor Cyan
        foreach ($recommendation in $data.Compliance.Recommendations) {
            Write-Host "  - $recommendation" -ForegroundColor Yellow
        }
        Write-Host ""
    }
    
    Write-Host "Press Ctrl+C to exit (if auto-refresh enabled)" -ForegroundColor Gray
}

function Generate-HTMLDashboard {
    $data = Get-ComplianceData
    
    if (-not $data.Compliance) {
        Write-ECRRLog "No compliance data available. Run the compliance monitor first." "ERROR"
        return
    }
    
    $compliance = $data.Compliance.ComplianceRate
    $totalReports = $data.Compliance.TotalReports
    $compliantReports = $data.Compliance.CompliantReports
    
    $statusColor = if ($compliance -ge $Config.ComplianceThreshold) { "#28a745" }
                   elseif ($compliance -ge $Config.WarningThreshold) { "#ffc107" }
                   else { "#dc3545" }
    
    $statusText = if ($compliance -ge $Config.ComplianceThreshold) { "HEALTHY" }
                  elseif ($compliance -ge $Config.WarningThreshold) { "WARNING" }
                  else { "CRITICAL" }
    
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ECRR Compliance Dashboard</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
        .card { background: white; border-radius: 8px; padding: 20px; margin-bottom: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .status-healthy { color: #28a745; }
        .status-warning { color: #ffc107; }
        .status-critical { color: #dc3545; }
        .metric { display: inline-block; margin: 10px 20px 10px 0; }
        .metric-value { font-size: 2em; font-weight: bold; }
        .metric-label { font-size: 0.9em; color: #666; }
        .breakdown-item { display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #eee; }
        .breakdown-item:last-child { border-bottom: none; }
        .progress-bar { width: 100%; height: 20px; background-color: #e9ecef; border-radius: 10px; overflow: hidden; }
        .progress-fill { height: 100%; transition: width 0.3s ease; }
        .progress-healthy { background-color: #28a745; }
        .progress-warning { background-color: #ffc107; }
        .progress-critical { background-color: #dc3545; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }
        .timestamp { color: #666; font-size: 0.9em; }
        .recommendation { background-color: #fff3cd; border-left: 4px solid #ffc107; padding: 10px; margin: 5px 0; }
        .non-compliant { background-color: #f8d7da; border-left: 4px solid #dc3545; padding: 10px; margin: 5px 0; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>ECRR Compliance Dashboard</h1>
            <p class="timestamp">Last Updated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
        </div>
        
        <div class="card">
            <h2>Overall Compliance Status</h2>
            <div class="metric">
                <div class="metric-value status-$($statusText.ToLower())">$compliance%</div>
                <div class="metric-label">Compliance Rate</div>
            </div>
            <div class="metric">
                <div class="metric-value">$compliantReports</div>
                <div class="metric-label">Compliant Reports</div>
            </div>
            <div class="metric">
                <div class="metric-value">$totalReports</div>
                <div class="metric-label">Total Reports</div>
            </div>
            <div class="progress-bar">
                <div class="progress-fill progress-$($statusText.ToLower())" style="width: $compliance%"></div>
            </div>
        </div>
        
        <div class="grid">
            <div class="card">
                <h3>Compliance Breakdown</h3>
"@

    foreach ($criterion in $data.Compliance.ComplianceBreakdown.Keys) {
        $breakdown = $data.Compliance.ComplianceBreakdown.$criterion
        $rate = $breakdown.Rate
        $progressClass = if ($rate -ge 95) { "progress-healthy" } elseif ($rate -ge 80) { "progress-warning" } else { "progress-critical" }
        
        $html += @"
                <div class="breakdown-item">
                    <span>$criterion</span>
                    <span>$rate% ($($breakdown.Compliant)/$($breakdown.Total))</span>
                </div>
                <div class="progress-bar">
                    <div class="progress-fill $progressClass" style="width: $rate%"></div>
                </div>
"@
    }
    
    $html += @"
            </div>
            
            <div class="card">
                <h3>Report Categories</h3>
"@

    foreach ($category in $data.Compliance.ReportCategories.Keys) {
        $count = $data.Compliance.ReportCategories.$category
        $percentage = [Math]::Round(($count / $totalReports) * 100, 1)
        
        $html += @"
                <div class="breakdown-item">
                    <span>$category</span>
                    <span>$count reports ($percentage%)</span>
                </div>
"@
    }
    
    $html += @"
            </div>
        </div>
        
        <div class="card">
            <h3>Non-Compliant Reports</h3>
            <p>Total: $($data.Compliance.NonCompliantReports.Count) reports</p>
"@

    $topNonCompliant = $data.Compliance.NonCompliantReports | Select-Object -First 10
    foreach ($report in $topNonCompliant) {
        $html += @"
            <div class="non-compliant">
                <strong>$($report.File)</strong><br>
                <span>Issues: $($report.Issues -join ', ')</span>
            </div>
"@
    }
    
    $html += @"
        </div>
        
        <div class="card">
            <h3>Recommendations</h3>
"@

    foreach ($recommendation in $data.Compliance.Recommendations) {
        $html += @"
            <div class="recommendation">$recommendation</div>
"@
    }
    
    $html += @"
        </div>
    </div>
    
    <script>
        // Auto-refresh every 5 minutes
        setTimeout(function() {
            location.reload();
        }, 300000);
    </script>
</body>
</html>
"@

    $html | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-ECRRLog "HTML dashboard generated: $OutputPath" "SUCCESS"
}

# Main execution
try {
    if ($ShowDashboard) {
        if ($AutoRefresh) {
            Write-ECRRLog "Starting dashboard with auto-refresh every $RefreshInterval seconds..." "INFO"
            Write-ECRRLog "Press Ctrl+C to stop" "INFO"
            
            while ($true) {
                Show-ComplianceDashboard
                Start-Sleep -Seconds $RefreshInterval
            }
        } else {
            Show-ComplianceDashboard
        }
    }
    elseif ($GenerateHTML) {
        Generate-HTMLDashboard
    }
    else {
        Write-Host "ECRR Compliance Dashboard" -ForegroundColor Cyan
        Write-Host "========================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Usage:" -ForegroundColor Yellow
        Write-Host "  -ShowDashboard    Show live dashboard in console" -ForegroundColor White
        Write-Host "  -GenerateHTML     Generate HTML dashboard file" -ForegroundColor White
        Write-Host "  -AutoRefresh      Auto-refresh dashboard (use with -ShowDashboard)" -ForegroundColor White
        Write-Host "  -RefreshInterval  Refresh interval in seconds (default: 30)" -ForegroundColor White
        Write-Host ""
        Write-Host "Examples:" -ForegroundColor Yellow
        Write-Host "  .\ecrr-compliance-dashboard.ps1 -ShowDashboard" -ForegroundColor White
        Write-Host "  .\ecrr-compliance-dashboard.ps1 -GenerateHTML" -ForegroundColor White
        Write-Host "  .\ecrr-compliance-dashboard.ps1 -ShowDashboard -AutoRefresh" -ForegroundColor White
    }
}
catch {
    Write-ECRRLog "Error in dashboard: $($_.Exception.Message)" "ERROR"
    exit 1
}
