# ECRR Compliance Dashboard Generator
# Creates HTML dashboard for compliance monitoring

param(
    [string]$OutputPath = "artifacts/ecrr-compliance-dashboard.html",
    [string]$TrendsDataPath = "artifacts/ecrr-compliance-trends.json",
    [string]$ComplianceReportPath = "artifacts/ecrr-compliance-report.json",
    [switch]$AutoRefresh,
    [int]$RefreshIntervalSeconds = 300
)

# Initialize OpenTelemetry functions
. $PSScriptRoot\..\otel\otel-functions.ps1

Write-Host "📊 ECRR Compliance Dashboard Generator" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan

# Function to load compliance data
function Get-ComplianceData {
    $data = @{
        Trends = $null
        CurrentReport = $null
        LastUpdated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    # Load trends data
    if (Test-Path $TrendsDataPath) {
        try {
            $data.Trends = Get-Content $TrendsDataPath -Raw | ConvertFrom-Json
        }
        catch {
            Write-Warning "Failed to load trends data: $($_.Exception.Message)"
        }
    }
    
    # Load current compliance report
    if (Test-Path $ComplianceReportPath) {
        try {
            $data.CurrentReport = Get-Content $ComplianceReportPath -Raw | ConvertFrom-Json
        }
        catch {
            Write-Warning "Failed to load compliance report: $($_.Exception.Message)"
        }
    }
    
    return $data
}

# Function to generate HTML dashboard
function New-ComplianceDashboard {
    param($Data)
    
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ECRR Compliance Dashboard</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
            color: #333;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 20px;
            text-align: center;
        }
        .header h1 {
            margin: 0;
            font-size: 2.5em;
        }
        .header p {
            margin: 10px 0 0 0;
            opacity: 0.9;
        }
        .dashboard {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }
        .card {
            background: white;
            border-radius: 10px;
            padding: 20px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            transition: transform 0.2s;
        }
        .card:hover {
            transform: translateY(-2px);
        }
        .card h3 {
            margin-top: 0;
            color: #667eea;
            border-bottom: 2px solid #f0f0f0;
            padding-bottom: 10px;
        }
        .metric {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin: 10px 0;
            padding: 10px;
            background: #f8f9fa;
            border-radius: 5px;
        }
        .metric-value {
            font-weight: bold;
            font-size: 1.2em;
        }
        .trend-up { color: #28a745; }
        .trend-down { color: #dc3545; }
        .trend-stable { color: #6c757d; }
        .status-good { color: #28a745; }
        .status-warning { color: #ffc107; }
        .status-danger { color: #dc3545; }
        .chart-container {
            height: 300px;
            background: #f8f9fa;
            border-radius: 5px;
            padding: 20px;
            margin-top: 10px;
        }
        .report-list {
            max-height: 400px;
            overflow-y: auto;
        }
        .report-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 10px;
            border-bottom: 1px solid #eee;
        }
        .report-item:last-child {
            border-bottom: none;
        }
        .score {
            font-weight: bold;
            padding: 5px 10px;
            border-radius: 15px;
            color: white;
        }
        .score-perfect { background: #28a745; }
        .score-good { background: #17a2b8; }
        .score-warning { background: #ffc107; }
        .score-danger { background: #dc3545; }
        .refresh-info {
            text-align: center;
            color: #6c757d;
            font-size: 0.9em;
            margin-top: 20px;
        }
        @media (max-width: 768px) {
            .dashboard {
                grid-template-columns: 1fr;
            }
        }
    </style>
"@

    if ($AutoRefresh) {
        $html += @"
    <script>
        setTimeout(function() {
            location.reload();
        }, $($RefreshIntervalSeconds * 1000));
    </script>
"@
    }

    $html += @"
</head>
<body>
    <div class="header">
        <h1>📊 ECRR Compliance Dashboard</h1>
        <p>Real-time compliance monitoring and trend analysis</p>
        <p>Last Updated: $($Data.LastUpdated)</p>
    </div>

    <div class="dashboard">
"@

    # Current Status Card
    if ($Data.CurrentReport) {
        $overallScore = $Data.CurrentReport.Overall_Score
        $totalReports = $Data.CurrentReport.Total_Reports
        $complianceRate = [math]::Round(($overallScore / ($totalReports * 12)) * 100, 2)
        $passedReports = ($Data.CurrentReport.Reports | Where-Object { $_.Score -eq $_.Total }).Count
        
        $statusClass = if ($complianceRate -ge 80) { "status-good" } elseif ($complianceRate -ge 60) { "status-warning" } else { "status-danger" }
        
        $html += @"
        <div class="card">
            <h3>📈 Current Status</h3>
            <div class="metric">
                <span>Overall Score</span>
                <span class="metric-value $statusClass">$overallScore/$($totalReports * 12)</span>
            </div>
            <div class="metric">
                <span>Compliance Rate</span>
                <span class="metric-value $statusClass">$complianceRate%</span>
            </div>
            <div class="metric">
                <span>Passed Reports</span>
                <span class="metric-value">$passedReports/$totalReports</span>
            </div>
            <div class="metric">
                <span>Failed Reports</span>
                <span class="metric-value">$($totalReports - $passedReports)/$totalReports</span>
            </div>
        </div>
"@
    }

    # Trends Card
    if ($Data.Trends -and $Data.Trends.CurrentTrend) {
        $trend = $Data.Trends.CurrentTrend
        $trendClass = if ($trend.TrendDirection -eq "Upward") { "trend-up" } elseif ($trend.TrendDirection -eq "Downward") { "trend-down" } else { "trend-stable" }
        
        $html += @"
        <div class="card">
            <h3>📊 Trend Analysis</h3>
            <div class="metric">
                <span>Trend Direction</span>
                <span class="metric-value $trendClass">$($trend.TrendDirection)</span>
            </div>
            <div class="metric">
                <span>Trend Status</span>
                <span class="metric-value $trendClass">$($trend.Trend)</span>
            </div>
            <div class="metric">
                <span>Change</span>
                <span class="metric-value $trendClass">$($trend.TrendPercentage)%</span>
            </div>
            <div class="metric">
                <span>Recent Average</span>
                <span class="metric-value">$($trend.RecentAverage)%</span>
            </div>
            <div class="metric">
                <span>Historical Average</span>
                <span class="metric-value">$($trend.HistoricalAverage)%</span>
            </div>
            <div style="margin-top: 15px; padding: 10px; background: #e9ecef; border-radius: 5px;">
                <strong>Recommendation:</strong><br>
                $($trend.Recommendation)
            </div>
        </div>
"@
    }

    # Reports Card
    if ($Data.CurrentReport) {
        $html += @"
        <div class="card">
            <h3>📋 Report Status</h3>
            <div class="report-list">
"@

        foreach ($report in $Data.CurrentReport.Reports | Sort-Object Score -Descending) {
            $scorePercent = [math]::Round(($report.Score / $report.Total) * 100, 1)
            $scoreClass = if ($scorePercent -eq 100) { "score-perfect" } elseif ($scorePercent -ge 80) { "score-good" } elseif ($scorePercent -ge 60) { "score-warning" } else { "score-danger" }
            
            $html += @"
                <div class="report-item">
                    <span>$($report.File)</span>
                    <span class="score $scoreClass">$($report.Score)/$($report.Total)</span>
                </div>
"@
        }

        $html += @"
            </div>
        </div>
"@
    }

    # Historical Chart Card
    if ($Data.Trends -and $Data.Trends.HistoricalData) {
        $html += @"
        <div class="card">
            <h3>📈 Historical Compliance</h3>
            <div class="chart-container">
                <canvas id="complianceChart" width="400" height="200"></canvas>
            </div>
        </div>
"@
    }

    $html += @"
    </div>

    <div class="refresh-info">
"@

    if ($AutoRefresh) {
        $html += @"
        <p>🔄 Auto-refresh enabled (every $RefreshIntervalSeconds seconds)</p>
"@
    } else {
        $html += @"
        <p>Manual refresh - reload page to update</p>
"@
    }

    $html += @"
    </div>

    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script>
"@

    # Add chart script if historical data exists
    if ($Data.Trends -and $Data.Trends.HistoricalData) {
        $labels = $Data.Trends.HistoricalData | ForEach-Object { 
            if ($_.Timestamp -is [string]) { 
                $_.Timestamp.Split('T')[0] 
            } else { 
                $_.Timestamp.ToString('yyyy-MM-dd') 
            } 
        }
        $data = $Data.Trends.HistoricalData | ForEach-Object { $_.ComplianceRate }
        
        $html += @"
        const ctx = document.getElementById('complianceChart').getContext('2d');
        new Chart(ctx, {
            type: 'line',
            data: {
                labels: [$(($labels | ForEach-Object { "'$_'" }) -join ',')],
                datasets: [{
                    label: 'Compliance Rate (%)',
                    data: [$($data -join ',')],
                    borderColor: '#667eea',
                    backgroundColor: 'rgba(102, 126, 234, 0.1)',
                    tension: 0.4,
                    fill: true
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true,
                        max: 100
                    }
                },
                plugins: {
                    legend: {
                        display: false
                    }
                }
            }
        });
"@
    }

    $html += @"
    </script>
</body>
</html>
"@

    return $html
}

# Main execution
try {
    Write-Host "🚀 Generating compliance dashboard..." -ForegroundColor Green
    
    # Load compliance data
    $data = Get-ComplianceData
    
    # Generate HTML dashboard
    $html = New-ComplianceDashboard -Data $data
    
    # Save dashboard
    $html | Set-Content -Path $OutputPath -Encoding UTF8
    
    Write-Host "✅ Dashboard generated successfully!" -ForegroundColor Green
    Write-Host "   Output: $OutputPath" -ForegroundColor White
    
    if ($AutoRefresh) {
        Write-Host "   Auto-refresh: Every $RefreshIntervalSeconds seconds" -ForegroundColor White
    }
    
    # Open dashboard if possible
    if (Get-Command "Start-Process" -ErrorAction SilentlyContinue) {
        try {
            Start-Process $OutputPath
            Write-Host "   Dashboard opened in browser" -ForegroundColor White
        }
        catch {
            Write-Host "   Could not open dashboard automatically" -ForegroundColor Yellow
        }
    }
    
    exit 0
    
} catch {
    Write-Error "Dashboard generation failed: $($_.Exception.Message)"
    Write-Error "Stack trace: $($_.ScriptStackTrace)"
    exit 1
}
