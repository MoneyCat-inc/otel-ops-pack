[CmdletBinding()]
param(
    [string]$OutputPath = "artifacts",
    [switch]$IncludeCiSummary
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir

# Ensure output directory exists
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Run compliance monitor to get latest data
Write-Host "🔄 Running ECRR compliance monitor..." -ForegroundColor Cyan
$complianceScript = Join-Path $scriptDir "ecrr-compliance-monitor.ps1"
& pwsh -NoLogo -File $complianceScript -OutputPath $OutputPath -Threshold 95

# Run CI integration to get CI summary
if ($IncludeCiSummary) {
    Write-Host "🔄 Running ECRR CI integration..." -ForegroundColor Cyan
    $ciScript = Join-Path $scriptDir "ecrr-ci-integration.ps1"
    & pwsh -NoLogo -File $ciScript -Threshold 95 -FailOnRegression
}

# Find the latest compliance report
$latestReport = Get-ChildItem -Path $OutputPath -Filter "ecrr-compliance-report-*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $latestReport) {
    Write-Host "❌ No compliance report found!" -ForegroundColor Red
    exit 1
}

# Load compliance data
$complianceData = Get-Content -Path $latestReport.FullName -Raw | ConvertFrom-Json

# Load CI summary if available
$ciData = $null
$ciSummaryFile = Join-Path $OutputPath "ecrr-ci-summary.json"
if (Test-Path -Path $ciSummaryFile) {
    $ciData = Get-Content -Path $ciSummaryFile -Raw | ConvertFrom-Json
}

# Create enhanced dashboard HTML
$dashboardHtml = @"
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
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #333;
            min-height: 100vh;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 15px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, #2c3e50 0%, #3498db 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }
        .header h1 {
            margin: 0;
            font-size: 2.5em;
            font-weight: 300;
        }
        .header p {
            margin: 10px 0 0 0;
            opacity: 0.9;
            font-size: 1.1em;
        }
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            padding: 30px;
            background: #f8f9fa;
        }
        .stat-card {
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.08);
            text-align: center;
            transition: transform 0.3s ease;
        }
        .stat-card:hover {
            transform: translateY(-5px);
        }
        .stat-value {
            font-size: 3em;
            font-weight: bold;
            margin: 10px 0;
        }
        .stat-label {
            color: #666;
            font-size: 1.1em;
            margin-bottom: 10px;
        }
        .compliance-100 { color: #27ae60; }
        .compliance-95 { color: #f39c12; }
        .compliance-low { color: #e74c3c; }
        .status-pass { color: #27ae60; }
        .status-fail { color: #e74c3c; }
        .status-warn { color: #f39c12; }
        .details-section {
            padding: 30px;
            border-top: 1px solid #eee;
        }
        .details-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 30px;
            margin-top: 20px;
        }
        .detail-card {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            border-left: 4px solid #3498db;
        }
        .detail-card h3 {
            margin: 0 0 15px 0;
            color: #2c3e50;
        }
        .detail-item {
            display: flex;
            justify-content: space-between;
            padding: 8px 0;
            border-bottom: 1px solid #ddd;
        }
        .detail-item:last-child {
            border-bottom: none;
        }
        .detail-label {
            font-weight: 500;
            color: #555;
        }
        .detail-value {
            color: #333;
        }
        .footer {
            background: #2c3e50;
            color: white;
            padding: 20px;
            text-align: center;
            font-size: 0.9em;
        }
        .refresh-info {
            background: #e8f4f8;
            padding: 15px;
            margin: 20px 30px;
            border-radius: 8px;
            border-left: 4px solid #3498db;
        }
        @media (max-width: 768px) {
            .details-grid {
                grid-template-columns: 1fr;
            }
            .stats-grid {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔍 ECRR Compliance Dashboard</h1>
            <p>Examine → Clean → Report → Role</p>
            <p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
        </div>
        
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-label">Compliance Rate</div>
                <div class="stat-value $(if ($complianceData.Summary.ComplianceRate -eq 100) { 'compliance-100' } elseif ($complianceData.Summary.ComplianceRate -ge 95) { 'compliance-95' } else { 'compliance-low' })">$($complianceData.Summary.ComplianceRate)%</div>
                <div>Target: 95%</div>
            </div>
            
            <div class="stat-card">
                <div class="stat-label">Compliant Reports</div>
                <div class="stat-value compliance-100">$($complianceData.Summary.CompliantFiles)</div>
                <div>Total: $($complianceData.Summary.TotalFiles)</div>
            </div>
            
            <div class="stat-card">
                <div class="stat-label">Average Score</div>
                <div class="stat-value compliance-100">$($complianceData.Summary.AverageScore)/100</div>
                <div>Quality Metric</div>
            </div>
            
            <div class="stat-card">
                <div class="stat-label">Non-Compliant</div>
                <div class="stat-value $(if ($complianceData.Summary.NonCompliantFiles -eq 0) { 'compliance-100' } else { 'compliance-low' })">$($complianceData.Summary.NonCompliantFiles)</div>
                <div>Issues Found</div>
            </div>
        </div>
        
        <div class="refresh-info">
            <strong>🔄 Auto-Refresh:</strong> This dashboard updates every 6 hours via scheduled tasks. 
            Last report: $($complianceData.Timestamp)
        </div>
        
        <div class="details-section">
            <h2>📊 Detailed Metrics</h2>
            <div class="details-grid">
                <div class="detail-card">
                    <h3>📋 Compliance Breakdown</h3>
                    <div class="detail-item">
                        <span class="detail-label">Total Reports:</span>
                        <span class="detail-value">$($complianceData.Summary.TotalFiles)</span>
                    </div>
                    <div class="detail-item">
                        <span class="detail-label">Compliant:</span>
                        <span class="detail-value">$($complianceData.Summary.CompliantFiles)</span>
                    </div>
                    <div class="detail-item">
                        <span class="detail-label">Non-Compliant:</span>
                        <span class="detail-value">$($complianceData.Summary.NonCompliantFiles)</span>
                    </div>
                    <div class="detail-item">
                        <span class="detail-label">Threshold:</span>
                        <span class="detail-value">95%</span>
                    </div>
                </div>
                
                <div class="detail-card">
                    <h3>🎯 Quality Metrics</h3>
                    <div class="detail-item">
                        <span class="detail-label">Compliance Rate:</span>
                        <span class="detail-value">$($complianceData.Summary.ComplianceRate)%</span>
                    </div>
                    <div class="detail-item">
                        <span class="detail-label">Average Score:</span>
                        <span class="detail-value">$($complianceData.Summary.AverageScore)/100</span>
                    </div>
                    <div class="detail-item">
                        <span class="detail-label">Report Path:</span>
                        <span class="detail-value">$($complianceData.Settings.ReportsPath)</span>
                    </div>
                    <div class="detail-item">
                        <span class="detail-label">Include Archived:</span>
                        <span class="detail-value">$($complianceData.Settings.IncludeArchived)</span>
                    </div>
                </div>
            </div>
        </div>
        
        $(if ($ciData) {
            @"
        <div class="details-section">
            <h2>🔄 CI/CD Integration Status</h2>
            <div class="details-grid">
                <div class="detail-card">
                    <h3>📈 CI Summary</h3>
                    <div class="detail-item">
                        <span class="detail-label">Status:</span>
                        <span class="detail-value status-$(if ($ciData.Status -eq 'PASS') { 'pass' } else { 'fail' })">$($ciData.Status)</span>
                    </div>
                    <div class="detail-item">
                        <span class="detail-label">Compliance:</span>
                        <span class="detail-value">$($ciData.ComplianceRate)%</span>
                    </div>
                    <div class="detail-item">
                        <span class="detail-label">Files:</span>
                        <span class="detail-value">$($ciData.CompliantFiles)/$($ciData.TotalFiles)</span>
                    </div>
                    <div class="detail-item">
                        <span class="detail-label">Regression:</span>
                        <span class="detail-value status-$(if ($ciData.Regression) { 'warn' } else { 'pass' })">$(if ($ciData.Regression) { 'YES' } else { 'NO' })</span>
                    </div>
                </div>
                
                <div class="detail-card">
                    <h3>📊 CI Metrics</h3>
                    <div class="detail-item">
                        <span class="detail-label">Score:</span>
                        <span class="detail-value">$($ciData.AverageScore)/100</span>
                    </div>
                    <div class="detail-item">
                        <span class="detail-label">Compliance Change:</span>
                        <span class="detail-value">$(if ($ciData.ComplianceChange -ne $null) { "$($ciData.ComplianceChange)%" } else { 'N/A' })</span>
                    </div>
                    <div class="detail-item">
                        <span class="detail-label">Score Change:</span>
                        <span class="detail-value">$(if ($ciData.ScoreChange -ne $null) { "$($ciData.ScoreChange) pts" } else { 'N/A' })</span>
                    </div>
                    <div class="detail-item">
                        <span class="detail-label">Timestamp:</span>
                        <span class="detail-value">$($ciData.Timestamp)</span>
                    </div>
                </div>
            </div>
        </div>
"@
        })
        
        <div class="footer">
            <p>🔄 ECRR Compliance Dashboard | Auto-generated by ECRR monitoring system</p>
            <p>Scheduled Tasks: ECRR Compliance Monitor (6h) | ECRR CI Integration (12h) | ECRR Archive Management (Daily)</p>
        </div>
    </div>
</body>
</html>
"@

# Save the dashboard
$dashboardPath = Join-Path $OutputPath "ecrr-compliance-dashboard.html"
$dashboardHtml | Out-File -Path $dashboardPath -Encoding UTF8

Write-Host "✅ ECRR Dashboard created successfully!" -ForegroundColor Green
Write-Host "📁 Location: $dashboardPath" -ForegroundColor Gray
Write-Host "🌐 Open in browser: file:///$($dashboardPath.Replace('\', '/'))" -ForegroundColor Blue

# Also create a simple status JSON for API consumption
$statusJson = @{
    Timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'
    Compliance = @{
        Rate = $complianceData.Summary.ComplianceRate
        CompliantFiles = $complianceData.Summary.CompliantFiles
        TotalFiles = $complianceData.Summary.TotalFiles
        AverageScore = $complianceData.Summary.AverageScore
        NonCompliantFiles = $complianceData.Summary.NonCompliantFiles
    }
    CI = if ($ciData) {
        @{
            Status = $ciData.Status
            ComplianceRate = $ciData.ComplianceRate
            Regression = $ciData.Regression
            AverageScore = $ciData.AverageScore
        }
    } else {
        $null
    }
    Dashboard = @{
        Path = $dashboardPath
        Generated = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'
    }
}

$statusPath = Join-Path $OutputPath "ecrr-dashboard-status.json"
$statusJson | ConvertTo-Json -Depth 5 | Out-File -Path $statusPath -Encoding UTF8

Write-Host "📊 Status JSON created: $statusPath" -ForegroundColor Gray
