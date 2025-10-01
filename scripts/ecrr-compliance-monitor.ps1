# ECRR Compliance Monitor - Automated Monitoring System
param(
    [string]$ReportsPath = "docs/ECRR_REPORTS",
    [string]$OutputPath = "artifacts",
    [switch]$Verbose = $false,
    [switch]$FailOnNonCompliant = $false,
    [int]$Threshold = 95
)

# Configuration
$Config = @{
    ReportsPath = $ReportsPath
    OutputPath = $OutputPath
    Threshold = $Threshold
    Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
}

# Ensure output directory exists
if (-not (Test-Path $Config.OutputPath)) {
    New-Item -Path $Config.OutputPath -ItemType Directory -Force | Out-Null
}

Write-Host "🔍 ECRR Compliance Monitor" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
Write-Host "📅 Timestamp: $($Config.Timestamp)" -ForegroundColor Gray
Write-Host "📁 Reports Path: $($Config.ReportsPath)" -ForegroundColor Gray
Write-Host "🎯 Compliance Threshold: $($Config.Threshold)%" -ForegroundColor Gray
Write-Host ""

# Get all ECRR report files (main directory only, exclude duplicates and archive)
$reportFiles = Get-ChildItem -Path $Config.ReportsPath -Filter "*.md" | Where-Object { 
    $_.Name -match '\d{4}-\d{2}-\d{2}' -and 
    $_.Name -notmatch 'backup' -and
    $_.Name -notmatch '20250929-200755-' -and  # Exclude duplicate prefixed files
    $_.FullName -notmatch '\\archive\\'
}

$totalFiles = $reportFiles.Count
Write-Host "📊 Total ECRR Reports Found: $totalFiles" -ForegroundColor Yellow

if ($totalFiles -eq 0) {
    Write-Host "❌ No ECRR reports found!" -ForegroundColor Red
    if ($FailOnNonCompliant) { exit 1 }
    exit 0
}

# Compliance checking functions
function Test-ECRRProductionMarker {
    param([string]$Content)
    return $Content -match '✅.*PRODUCTION READY'
}

function Test-ECRRFourSectionStructure {
    param([string]$Content)
    
    $sections = @(
        "## .*(1\. )?Examine",
        "## .*(2\. )?Clean", 
        "## .*(3\. )?Report",
        "## .*(4\. )?Role"
    )
    
    $foundSections = 0
    foreach ($section in $sections) {
        if ($Content -match $section) {
            $foundSections++
        }
    }
    
    return $foundSections -eq 4
}

function Test-ECRRGate {
    param([string]$Content)
    return $Content -match '## .*ECRR Gate'
}

function Test-ECRRCompliance {
    param([string]$FilePath)
    
    $content = Get-Content -Path $FilePath -Raw -ErrorAction SilentlyContinue
    if (-not $content) { 
        return @{
            Compliant = $false
            Issues = @("Cannot read file")
            Score = 0
        }
    }
    
    $issues = @()
    $score = 0
    
    # Check production marker (25 points)
    if (Test-ECRRProductionMarker -Content $content) {
        $score += 25
    } else {
        $issues += "Missing production marker"
    }
    
    # Check four-section structure (25 points)
    if (Test-ECRRFourSectionStructure -Content $content) {
        $score += 25
    } else {
        $issues += "Missing four-section structure"
    }
    
    # Check ECRR Gate (25 points)
    if (Test-ECRRGate -Content $content) {
        $score += 25
    } else {
        $issues += "Missing ECRR Gate"
    }
    
    # Check for actor declaration (25 points)
    if ($content -match '\*\*Actor\*\*:' -or $content -match 'Actor:') {
        $score += 25
    } else {
        $issues += "Missing actor declaration"
    }
    
    return @{
        Compliant = $issues.Count -eq 0
        Issues = $issues
        Score = $score
    }
}

# Check compliance for all files
$compliantFiles = 0
$nonCompliantFiles = @()
$complianceData = @()

foreach ($file in $reportFiles) {
    $result = Test-ECRRCompliance -FilePath $file.FullName
    
    $complianceData += @{
        File = $file.Name
        Path = $file.FullName
        Compliant = $result.Compliant
        Score = $result.Score
        Issues = $result.Issues
        LastModified = $file.LastWriteTime
    }
    
    if ($result.Compliant) {
        $compliantFiles++
        if ($Verbose) {
            Write-Host "✅ $($file.Name) - Score: $($result.Score)/100" -ForegroundColor Green
        }
    } else {
        $nonCompliantFiles += @{
            File = $file.Name
            Issues = $result.Issues
            Score = $result.Score
        }
        if ($Verbose) {
            Write-Host "❌ $($file.Name) - Score: $($result.Score)/100" -ForegroundColor Red
            foreach ($issue in $result.Issues) {
                Write-Host "   - $issue" -ForegroundColor DarkRed
            }
        }
    }
}

# Calculate compliance metrics
$complianceRate = [math]::Round(($compliantFiles / $totalFiles) * 100, 2)
$averageScore = [math]::Round(($complianceData | Measure-Object -Property Score -Average).Average, 2)

# Display results
Write-Host ""
Write-Host "📈 Compliance Results:" -ForegroundColor Green
Write-Host "  ✅ Compliant Files: $compliantFiles" -ForegroundColor Green
Write-Host "  ❌ Non-Compliant Files: $($nonCompliantFiles.Count)" -ForegroundColor Red
Write-Host "  📊 Compliance Rate: $complianceRate%" -ForegroundColor $(if ($complianceRate -ge $Config.Threshold) { "Green" } elseif ($complianceRate -ge 90) { "Yellow" } else { "Red" })
Write-Host "  🎯 Average Score: $averageScore/100" -ForegroundColor $(if ($averageScore -ge 90) { "Green" } elseif ($averageScore -ge 80) { "Yellow" } else { "Red" })

# Generate detailed report
$reportPath = Join-Path $Config.OutputPath "ecrr-compliance-report-$($Config.Timestamp).json"
$report = @{
    Timestamp = $Config.Timestamp
    Summary = @{
        TotalFiles = $totalFiles
        CompliantFiles = $compliantFiles
        NonCompliantFiles = $nonCompliantFiles.Count
        ComplianceRate = $complianceRate
        AverageScore = $averageScore
        Threshold = $Config.Threshold
        Passed = $complianceRate -ge $Config.Threshold
    }
    Files = $complianceData
    NonCompliantFiles = $nonCompliantFiles
}

$report | ConvertTo-Json -Depth 10 | Set-Content -Path $reportPath -Encoding UTF8

# Generate HTML dashboard
$htmlPath = Join-Path $Config.OutputPath "ecrr-compliance-dashboard.html"
$html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ECRR Compliance Dashboard</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { text-align: center; margin-bottom: 30px; }
        .metrics { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-bottom: 30px; }
        .metric { background: #f8f9fa; padding: 20px; border-radius: 8px; text-align: center; }
        .metric-value { font-size: 2em; font-weight: bold; margin-bottom: 5px; }
        .metric-label { color: #666; font-size: 0.9em; }
        .pass { color: #28a745; }
        .warning { color: #ffc107; }
        .fail { color: #dc3545; }
        .table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        .table th, .table td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        .table th { background: #f8f9fa; font-weight: 600; }
        .status-pass { color: #28a745; font-weight: bold; }
        .status-fail { color: #dc3545; font-weight: bold; }
        .issues { font-size: 0.9em; color: #666; }
        .timestamp { text-align: center; color: #666; margin-top: 30px; font-size: 0.9em; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔍 ECRR Compliance Dashboard</h1>
            <p>Automated compliance monitoring and reporting</p>
        </div>
        
        <div class="metrics">
            <div class="metric">
                <div class="metric-value $(if ($complianceRate -ge $Config.Threshold) { 'pass' } elseif ($complianceRate -ge 90) { 'warning' } else { 'fail' })">$complianceRate%</div>
                <div class="metric-label">Compliance Rate</div>
            </div>
            <div class="metric">
                <div class="metric-value">$compliantFiles</div>
                <div class="metric-label">Compliant Files</div>
            </div>
            <div class="metric">
                <div class="metric-value">$($nonCompliantFiles.Count)</div>
                <div class="metric-label">Non-Compliant Files</div>
            </div>
            <div class="metric">
                <div class="metric-value $(if ($averageScore -ge 90) { 'pass' } elseif ($averageScore -ge 80) { 'warning' } else { 'fail' })">$averageScore</div>
                <div class="metric-label">Average Score</div>
            </div>
        </div>
        
        <h2>📊 File Compliance Status</h2>
        <table class="table">
            <thead>
                <tr>
                    <th>File</th>
                    <th>Status</th>
                    <th>Score</th>
                    <th>Issues</th>
                    <th>Last Modified</th>
                </tr>
            </thead>
            <tbody>
"@

foreach ($file in $complianceData) {
    $status = if ($file.Compliant) { '<span class="status-pass">✅ PASS</span>' } else { '<span class="status-fail">❌ FAIL</span>' }
    $issues = if ($file.Issues.Count -gt 0) { ($file.Issues -join ', ') } else { 'None' }
    $lastModified = $file.LastModified.ToString('yyyy-MM-dd HH:mm')
    
    $html += @"
                <tr>
                    <td>$($file.File)</td>
                    <td>$status</td>
                    <td>$($file.Score)/100</td>
                    <td class="issues">$issues</td>
                    <td>$lastModified</td>
                </tr>
"@
}

$html += @"
            </tbody>
        </table>
        
        <div class="timestamp">
            Generated on $($Config.Timestamp)
        </div>
    </div>
</body>
</html>
"@

Set-Content -Path $htmlPath -Value $html -Encoding UTF8

# Display summary
Write-Host ""
Write-Host "📄 Reports Generated:" -ForegroundColor Cyan
Write-Host "  📊 JSON Report: $reportPath" -ForegroundColor Gray
Write-Host "  🌐 HTML Dashboard: $htmlPath" -ForegroundColor Gray

# Check if compliance threshold is met
$thresholdMet = $complianceRate -ge $Config.Threshold
if ($thresholdMet) {
    Write-Host ""
    Write-Host "🎉 COMPLIANCE THRESHOLD MET!" -ForegroundColor Green
    Write-Host "   Target: $($Config.Threshold)% | Actual: $complianceRate%" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "⚠️  COMPLIANCE THRESHOLD NOT MET" -ForegroundColor Red
    Write-Host "   Target: $($Config.Threshold)% | Actual: $complianceRate%" -ForegroundColor Red
    Write-Host "   Need to fix $($nonCompliantFiles.Count) files" -ForegroundColor Red
    
    if ($nonCompliantFiles.Count -gt 0) {
        Write-Host ""
        Write-Host "🔧 Non-Compliant Files:" -ForegroundColor Red
        foreach ($file in $nonCompliantFiles) {
            Write-Host "  ❌ $($file.File)" -ForegroundColor Red
            foreach ($issue in $file.Issues) {
                Write-Host "     - $issue" -ForegroundColor DarkRed
            }
        }
    }
}

Write-Host ""
Write-Host "✅ ECRR Compliance Monitor completed" -ForegroundColor Green

# Exit with appropriate code
if ($FailOnNonCompliant -and -not $thresholdMet) {
    Write-Host "❌ Exiting with error code due to non-compliance" -ForegroundColor Red
    exit 1
}

exit 0