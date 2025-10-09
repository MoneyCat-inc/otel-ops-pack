# ECRR Compliance Trend Visualization Script
param(
    [string]$HistoryFile = "artifacts/ecrr-compliance-history.jsonl",
    [string]$OutputDir = "artifacts",
    [switch]$GenerateChart = $true,
    [switch]$GenerateReport = $true
)

$ErrorActionPreference = "Stop"

Write-Host "ECRR Compliance Trend Visualization" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

if (-not (Test-Path $HistoryFile)) {
    Write-Error "History file not found: $HistoryFile"
    exit 1
}

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# Parse JSONL history (handle multi-line JSON entries)
$history = @()
$content = Get-Content $HistoryFile -Raw
$jsonEntries = $content -split '(?=\{)'

foreach ($entry in $jsonEntries) {
    $entry = $entry.Trim()
    if ($entry -and $entry.StartsWith('{')) {
        try {
            $parsed = $entry | ConvertFrom-Json
            $history += $parsed
        } catch {
            Write-Warning "Failed to parse entry: $entry"
        }
    }
}

if ($history.Count -eq 0) {
    Write-Error "No valid history entries found"
    exit 1
}

Write-Host "Parsed $($history.Count) history entries" -ForegroundColor Green

# Calculate trends
$latest = $history[-1]
$earliest = $history[0]
$trend = @{
    TotalEntries = $history.Count
    DateRange = @{
        Start = $earliest.timestamp
        End = $latest.timestamp
    }
    LatestMetrics = @{
        FourSectionPct = $latest.fourSectionPct
        GatePct = $latest.gatePct
        Total = $latest.total
        Passed = $latest.passed
    }
    Trends = @{
        FourSectionTrend = if ($history.Count -gt 1) { $latest.fourSectionPct - $earliest.fourSectionPct } else { 0 }
        GateTrend = if ($history.Count -gt 1) { $latest.gatePct - $earliest.gatePct } else { 0 }
    }
    AverageMetrics = @{
        FourSectionPct = [math]::Round(($history | Measure-Object -Property fourSectionPct -Average).Average, 1)
        GatePct = [math]::Round(($history | Measure-Object -Property gatePct -Average).Average, 1)
    }
}

# Generate HTML chart
if ($GenerateChart) {
    $chartData = $history | ForEach-Object {
        $date = [DateTime]::Parse($_.timestamp)
        @{
            date = $date.ToString("yyyy-MM-dd HH:mm")
            fourSection = $_.fourSectionPct
            gates = $_.gatePct
            passed = $_.passed
        }
    } | ConvertTo-Json -Depth 3

    $htmlChart = @"
<!DOCTYPE html>
<html>
<head>
    <title>ECRR Compliance Trends</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .chart-container { width: 800px; height: 400px; margin: 20px 0; }
        .summary { background: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .metric { display: inline-block; margin: 10px 20px 10px 0; }
        .metric-value { font-size: 24px; font-weight: bold; }
        .metric-label { font-size: 14px; color: #666; }
    </style>
</head>
<body>
    <h1>ECRR Compliance Trends</h1>
    
    <div class="summary">
        <h3>Summary</h3>
        <div class="metric">
            <div class="metric-value">$($trend.LatestMetrics.FourSectionPct)%</div>
            <div class="metric-label">Four-section Structure</div>
        </div>
        <div class="metric">
            <div class="metric-value">$($trend.LatestMetrics.GatePct)%</div>
            <div class="metric-label">ECRR Gates</div>
        </div>
        <div class="metric">
            <div class="metric-value">$($trend.LatestMetrics.Total)</div>
            <div class="metric-label">Total Reports</div>
        </div>
        <div class="metric">
            <div class="metric-value">$($trend.TotalEntries)</div>
            <div class="metric-label">History Entries</div>
        </div>
    </div>
    
    <div class="chart-container">
        <canvas id="complianceChart"></canvas>
    </div>
    
    <script>
        const data = $chartData;
        const ctx = document.getElementById('complianceChart').getContext('2d');
        
        new Chart(ctx, {
            type: 'line',
            data: {
                labels: data.map(d => d.date),
                datasets: [{
                    label: 'Four-section Structure %',
                    data: data.map(d => d.fourSection),
                    borderColor: 'rgb(75, 192, 192)',
                    backgroundColor: 'rgba(75, 192, 192, 0.2)',
                    tension: 0.1
                }, {
                    label: 'ECRR Gates %',
                    data: data.map(d => d.gates),
                    borderColor: 'rgb(255, 99, 132)',
                    backgroundColor: 'rgba(255, 99, 132, 0.2)',
                    tension: 0.1
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: false,
                        min: 90,
                        max: 100
                    }
                },
                plugins: {
                    title: {
                        display: true,
                        text: 'ECRR Compliance Trends Over Time'
                    }
                }
            }
        });
    </script>
</body>
</html>
"@

    $chartPath = Join-Path $OutputDir "ecrr-compliance-trends.html"
    $htmlChart | Out-File -FilePath $chartPath -Encoding UTF8
    Write-Host "Generated chart: $chartPath" -ForegroundColor Green
}

# Generate JSON report
if ($GenerateReport) {
    $reportPath = Join-Path $OutputDir "ecrr-compliance-trends.json"
    $trend | ConvertTo-Json -Depth 5 | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Host "Generated report: $reportPath" -ForegroundColor Green
}

# Display summary
Write-Host "`nTrend Analysis Summary:" -ForegroundColor Yellow
Write-Host "======================" -ForegroundColor Yellow
Write-Host "Total Entries: $($trend.TotalEntries)" -ForegroundColor White
Write-Host "Date Range: $($trend.DateRange.Start) to $($trend.DateRange.End)" -ForegroundColor White
Write-Host "Latest Four-section: $($trend.LatestMetrics.FourSectionPct)%" -ForegroundColor White
Write-Host "Latest Gates: $($trend.LatestMetrics.GatePct)%" -ForegroundColor White
Write-Host "Average Four-section: $($trend.AverageMetrics.FourSectionPct)%" -ForegroundColor White
Write-Host "Average Gates: $($trend.AverageMetrics.GatePct)%" -ForegroundColor White
Write-Host "Four-section Trend: $($trend.Trends.FourSectionTrend)%" -ForegroundColor White
Write-Host "Gates Trend: $($trend.Trends.GateTrend)%" -ForegroundColor White

Write-Host "`nVisualization complete!" -ForegroundColor Green
