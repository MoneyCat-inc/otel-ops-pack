#Requires -Version 7.0
<#
.SYNOPSIS
Extract metrics from all ECRR reports and generate analytics.

.DESCRIPTION
Parses 318 ECRR reports to extract:
- Lane distribution (COMP, FLAK, DOCS, etc.)
- Compliance rate (4-phase ECRR adherence)
- Gate readiness tracking
- Time series trends
- Quality metrics
#>

param(
    [string]$ReportsDir = "CHAR/ECRR/ECRR_REPORTS",
    [string]$ArchiveDir = "docs/archive/gates/2025-11",
    [string]$OutputDir = "artifacts/ecrr-analytics"
)

$ErrorActionPreference = "Stop"

Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  ECRR Metrics Extraction" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Create output directory
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

# Initialize metrics
$metrics = @{
    totalReports = 0
    byLane = @{}
    byPhase = @{
        examine = 0
        clean = 0
        report = 0
        role = 0
        complete = 0
    }
    gateReadiness = @{
        ready = 0
        partial = 0
        blocked = 0
        success = 0
    }
    timeline = @()
}

Write-Host "Scanning ECRR reports..." -ForegroundColor Cyan

# Process main reports
if (Test-Path $ReportsDir) {
    $reports = Get-ChildItem $ReportsDir -Filter *.md -Recurse
    Write-Host "  Found $($reports.Count) reports in main directory" -ForegroundColor Gray
    
    foreach ($report in $reports) {
        $metrics.totalReports++
        
        # Extract lane from filename or content
        $content = Get-Content $report.FullName -Raw
        
        # Lane detection
        $lanePatterns = @("COMP", "FLAK", "DOCS", "SELE", "VIZR", "AUDIO", "AGENT", "SSOT")
        foreach ($lane in $lanePatterns) {
            if ($report.Name -match $lane -or $content -match "Lane:\s*$lane") {
                if (-not $metrics.byLane.ContainsKey($lane)) {
                    $metrics.byLane[$lane] = 0
                }
                $metrics.byLane[$lane]++
                break
            }
        }
        
        # Phase detection
        if ($content -match "## Examine" -or $content -match "### Examine") { $metrics.byPhase.examine++ }
        if ($content -match "## Clean" -or $content -match "### Clean") { $metrics.byPhase.clean++ }
        if ($content -match "## Report" -or $content -match "### Report") { $metrics.byPhase.report++ }
        if ($content -match "## Role" -or $content -match "### Role") { $metrics.byPhase.role++ }
        
        # Complete if all 4 phases present
        if ($content -match "Examine" -and $content -match "Clean" -and 
            $content -match "Report" -and $content -match "Role") {
            $metrics.byPhase.complete++
        }
        
        # Gate readiness
        if ($report.Name -match "READY") { $metrics.gateReadiness.ready++ }
        if ($report.Name -match "PARTIAL") { $metrics.gateReadiness.partial++ }
        if ($report.Name -match "BLOCKED") { $metrics.gateReadiness.blocked++ }
        if ($report.Name -match "SUCCESS|COMPLETE") { $metrics.gateReadiness.success++ }
        
        # Timeline entry (extract date from filename)
        if ($report.Name -match "(\d{8})") {
            $dateStr = $Matches[1]
            try {
                $date = [DateTime]::ParseExact($dateStr, "yyyyMMdd", $null)
                $metrics.timeline += @{
                    date = $date.ToString("yyyy-MM-dd")
                    report = $report.Name
                }
            }
            catch {
                Write-Verbose "Skipping invalid timeline date '$dateStr' in $($report.Name)"
            }
        }
    }
}

# Process archived gate reports
if (Test-Path $ArchiveDir) {
    $archived = Get-ChildItem $ArchiveDir -Filter *.md
    Write-Host "  Found $($archived.Count) archived gate reports" -ForegroundColor Gray
    $metrics.totalReports += $archived.Count
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host "  Metrics Summary" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host ""

Write-Host "Total Reports Processed: $($metrics.totalReports)" -ForegroundColor Cyan
Write-Host ""

Write-Host "Lane Distribution:" -ForegroundColor Yellow
$metrics.byLane.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object {
    $pct = [math]::Round(($_.Value / $metrics.totalReports) * 100, 1)
    Write-Host ("  {0,-8} {1,4} ({2,5}%)" -f $_.Key, $_.Value, $pct) -ForegroundColor Gray
}

Write-Host ""
Write-Host "Phase Compliance:" -ForegroundColor Yellow
Write-Host ("  Examine:  {0,4}" -f $metrics.byPhase.examine) -ForegroundColor Gray
Write-Host ("  Clean:    {0,4}" -f $metrics.byPhase.clean) -ForegroundColor Gray
Write-Host ("  Report:   {0,4}" -f $metrics.byPhase.report) -ForegroundColor Gray
Write-Host ("  Role:     {0,4}" -f $metrics.byPhase.role) -ForegroundColor Gray
Write-Host ("  Complete: {0,4} (all 4 phases)" -f $metrics.byPhase.complete) -ForegroundColor Green

$complianceRate = [math]::Round(($metrics.byPhase.complete / $metrics.totalReports) * 100, 1)
Write-Host ""
Write-Host "  ECRR Compliance Rate: $complianceRate%" -ForegroundColor $(if ($complianceRate -ge 80) { "Green" } elseif ($complianceRate -ge 60) { "Yellow" } else { "Red" })

Write-Host ""
Write-Host "Gate Readiness:" -ForegroundColor Yellow
Write-Host ("  Ready:    {0,4}" -f $metrics.gateReadiness.ready) -ForegroundColor Green
Write-Host ("  Success:  {0,4}" -f $metrics.gateReadiness.success) -ForegroundColor Green
Write-Host ("  Partial:  {0,4}" -f $metrics.gateReadiness.partial) -ForegroundColor Yellow
Write-Host ("  Blocked:  {0,4}" -f $metrics.gateReadiness.blocked) -ForegroundColor Red

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor DarkGray

# Export metrics
$metricsPath = Join-Path $OutputDir "ecrr-metrics.json"
$metrics | ConvertTo-Json -Depth 4 | Out-File -Encoding UTF8 $metricsPath
Write-Host ""
Write-Host "✅ Metrics exported to: $metricsPath" -ForegroundColor Green

# Generate CSV for trending
$csvPath = Join-Path $OutputDir "ecrr-timeline.csv"
$metrics.timeline | Sort-Object date | 
    Select-Object @{N='Date';E={$_.date}}, @{N='Report';E={$_.report}} |
    Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

Write-Host "✅ Timeline CSV exported to: $csvPath" -ForegroundColor Green

# Generate HTML dashboard
$htmlPath = Join-Path $OutputDir "ecrr-dashboard.html"
$html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>ECRR Metrics Dashboard</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 20px; background: #1e1e1e; color: #d4d4d4; }
        .container { max-width: 1200px; margin: 0 auto; }
        h1 { color: #4fc3f7; border-bottom: 2px solid #0288d1; padding-bottom: 10px; }
        h2 { color: #81c784; margin-top: 30px; }
        .metric-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin: 20px 0; }
        .metric-card { background: #2d2d30; border: 1px solid #3e3e42; border-radius: 8px; padding: 20px; }
        .metric-value { font-size: 2.5em; font-weight: bold; color: #4fc3f7; }
        .metric-label { color: #858585; text-transform: uppercase; font-size: 0.9em; margin-top: 5px; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; background: #2d2d30; }
        th { background: #0288d1; color: white; padding: 12px; text-align: left; }
        td { padding: 10px; border-bottom: 1px solid #3e3e42; }
        tr:hover { background: #3e3e42; }
        .status-ready { color: #81c784; }
        .status-partial { color: #ffb74d; }
        .status-blocked { color: #e57373; }
        .footer { margin-top: 40px; padding-top: 20px; border-top: 1px solid #3e3e42; color: #858585; text-align: center; }
    </style>
</head>
<body>
    <div class="container">
        <h1>📊 ECRR Methodology Dashboard</h1>
        <p>Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        
        <div class="metric-grid">
            <div class="metric-card">
                <div class="metric-value">$($metrics.totalReports)</div>
                <div class="metric-label">Total Reports</div>
            </div>
            <div class="metric-card">
                <div class="metric-value">$complianceRate%</div>
                <div class="metric-label">ECRR Compliance</div>
            </div>
            <div class="metric-card">
                <div class="metric-value">$($metrics.gateReadiness.ready + $metrics.gateReadiness.success)</div>
                <div class="metric-label">Successful Gates</div>
            </div>
            <div class="metric-card">
                <div class="metric-value">$($metrics.byLane.Count)</div>
                <div class="metric-label">Active Lanes</div>
            </div>
        </div>

        <h2>Lane Distribution</h2>
        <table>
            <thead>
                <tr><th>Lane</th><th>Reports</th><th>Percentage</th></tr>
            </thead>
            <tbody>
"@

$metrics.byLane.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object {
    $pct = [math]::Round(($_.Value / $metrics.totalReports) * 100, 1)
    $html += "                <tr><td>$($_.Key)</td><td>$($_.Value)</td><td>$pct%</td></tr>`n"
}

$html += @"
            </tbody>
        </table>

        <h2>Phase Compliance</h2>
        <table>
            <thead>
                <tr><th>Phase</th><th>Count</th></tr>
            </thead>
            <tbody>
                <tr><td>Examine</td><td>$($metrics.byPhase.examine)</td></tr>
                <tr><td>Clean</td><td>$($metrics.byPhase.clean)</td></tr>
                <tr><td>Report</td><td>$($metrics.byPhase.report)</td></tr>
                <tr><td>Role</td><td>$($metrics.byPhase.role)</td></tr>
                <tr style="font-weight: bold;"><td>Complete (all 4)</td><td class="status-ready">$($metrics.byPhase.complete)</td></tr>
            </tbody>
        </table>

        <h2>Gate Readiness Status</h2>
        <table>
            <thead>
                <tr><th>Status</th><th>Count</th></tr>
            </thead>
            <tbody>
                <tr><td class="status-ready">Ready</td><td>$($metrics.gateReadiness.ready)</td></tr>
                <tr><td class="status-ready">Success</td><td>$($metrics.gateReadiness.success)</td></tr>
                <tr><td class="status-partial">Partial</td><td>$($metrics.gateReadiness.partial)</td></tr>
                <tr><td class="status-blocked">Blocked</td><td>$($metrics.gateReadiness.blocked)</td></tr>
            </tbody>
        </table>

        <div class="footer">
            <p>Cat Nap Control Room - ECRR Analytics Suite</p>
        </div>
    </div>
</body>
</html>
"@

$html | Out-File -Encoding UTF8 $htmlPath
Write-Host "✅ HTML dashboard exported to: $htmlPath" -ForegroundColor Green
Write-Host ""


