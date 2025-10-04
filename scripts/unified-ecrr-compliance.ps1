# Unified ECRR Compliance Validation Script
# Ensures consistent validation logic across all reporting formats

param(
    [string]$ReportsPath = "docs/ECRR_REPORTS",
    [string]$OutputPath = "artifacts",
    [switch]$Verbose = $false,
    [int]$Threshold = 95
)

$ErrorActionPreference = 'Stop'

# Ensure output directory exists
if (!(Test-Path $OutputPath)) { 
    New-Item -ItemType Directory -Path $OutputPath | Out-Null 
}

# Unified validation functions
function Test-HasSection {
    param([string]$content, [string]$pattern)
    return [regex]::IsMatch($content, $pattern, 'Singleline')
}

function Test-ECRRFourSectionStructure {
    param([string]$Content)
    
    $hasExamine = Test-HasSection $Content "##\s*🔍[\s\S]*?Examine|##\s*1\.[\s\S]*?Examine"
    $hasClean   = Test-HasSection $Content "##\s*🧹[\s\S]*?Clean|##\s*2\.[\s\S]*?Clean"
    $hasReport  = Test-HasSection $Content "##\s*📝[\s\S]*?Report|##\s*3\.[\s\S]*?Report"
    $hasRole    = Test-HasSection $Content "##\s*🎭[\s\S]*?Role|##\s*4\.[\s\S]*?Role"
    
    return $hasExamine -and $hasClean -and $hasReport -and $hasRole
}

function Test-ECRRGate {
    param([string]$Content)
    return Test-HasSection $Content "##\s*✅\s*\*\*ECRR Gate\*\*|##\s*ECRR Gate"
}

function Test-ECRRActorDeclaration {
    param([string]$Content)
    return Test-HasSection $Content "Actor Declaration|^\*\*Agent\*\*|\*\*Cursor Agent|\*\*Cursor-Local|\*\*Codex Agent|\*\*ChatGPT Agent"
}

function Test-ECRRProductionMarker {
    param([string]$Content)
    return Test-HasSection $Content "Production Readiness|PRODUCTION READY|Production Ready|Production Readiness Assessment"
}

# Get all ECRR report files with unified filtering
$files = Get-ChildItem -Path $ReportsPath -Recurse -Filter *.md | Where-Object {
    $_.FullName -notmatch "(/|\\)(archive|backup)(/|\\)" -and 
    $_.Name -notmatch "^\.gitkeep$" -and
    $_.Name -match '\d{4}-\d{2}-\d{2}'
}

Write-Host "🔍 Unified ECRR Compliance Validation" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "📁 Reports Path: $ReportsPath" -ForegroundColor Gray
Write-Host "📊 Total Files Found: $($files.Count)" -ForegroundColor Gray
Write-Host "🎯 Threshold: $Threshold%" -ForegroundColor Gray
Write-Host ""

if ($files.Count -eq 0) {
    Write-Host "❌ No ECRR reports found!" -ForegroundColor Red
    exit 1
}

# Validate each file with unified logic
$total = 0
$compliant = 0
$issues = @()
$complianceData = @()

$metrics = [ordered]@{
    totalReports = 0
    hasFourSection = 0
    hasEcrrGate = 0
    hasActor = 0
    hasProductionMarker = 0
}

foreach ($file in $files) {
    $total++
    $content = Get-Content -Raw -Encoding UTF8 -Path $file.FullName
    
    # Apply unified validation logic
    $hasFourSection = Test-ECRRFourSectionStructure -Content $content
    $hasEcrrGate = Test-ECRRGate -Content $content
    $hasActor = Test-ECRRActorDeclaration -Content $content
    $hasProduction = Test-ECRRProductionMarker -Content $content
    
    # Count metrics
    if ($hasFourSection) { $metrics.hasFourSection++ }
    if ($hasEcrrGate) { $metrics.hasEcrrGate++ }
    if ($hasActor) { $metrics.hasActor++ }
    if ($hasProduction) { $metrics.hasProductionMarker++ }
    
    # Determine compliance and issues
    $fileIssues = @()
    if (-not $hasFourSection) { $fileIssues += "missing_four_section" }
    if (-not $hasEcrrGate) { $fileIssues += "missing_ecrr_gate" }
    if (-not $hasActor) { $fileIssues += "missing_actor_declaration" }
    if (-not $hasProduction) { $fileIssues += "missing_production_marker" }
    
    $isCompliant = $fileIssues.Count -eq 0
    if ($isCompliant) { $compliant++ }
    
    # Store compliance data
    $complianceData += @{
        File = $file.Name
        Path = $file.FullName.Replace("\\","/")
        Compliant = $isCompliant
        Issues = $fileIssues
        HasFourSection = $hasFourSection
        HasEcrrGate = $hasEcrrGate
        HasActor = $hasActor
        HasProduction = $hasProduction
        LastModified = $file.LastWriteTime
    }
    
    # Add to issues list if non-compliant
    if (-not $isCompliant) {
        $issues += [ordered]@{
            file = $file.FullName.Replace("\\","/")
            issues = $fileIssues
        }
    }
    
    if ($Verbose) {
        $status = if ($isCompliant) { "✅ PASS" } else { "❌ FAIL" }
        Write-Host "$status $($file.Name)" -ForegroundColor $(if ($isCompliant) { "Green" } else { "Red" })
        if (-not $isCompliant) {
            foreach ($issue in $fileIssues) {
                Write-Host "   - $issue" -ForegroundColor DarkRed
            }
        }
    }
}

$metrics.totalReports = $total

# Calculate compliance rates
$complianceRate = if ($total -gt 0) { [math]::Round(($compliant / $total) * 100, 1) } else { 0 }

$result = [ordered]@{
    generatedAt = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
    metrics = $metrics
    complianceRates = [ordered]@{
        fourSection = if ($total -gt 0) { [math]::Round(($metrics.hasFourSection/$total)*100,1) } else { 0 }
        ecrrGate    = if ($total -gt 0) { [math]::Round(($metrics.hasEcrrGate/$total)*100,1) } else { 0 }
        actor       = if ($total -gt 0) { [math]::Round(($metrics.hasActor/$total)*100,1) } else { 0 }
        production  = if ($total -gt 0) { [math]::Round(($metrics.hasProductionMarker/$total)*100,1) } else { 0 }
        fullyCompliant = $complianceRate
    }
    fullyCompliantCount = $compliant
    nonCompliant = $issues
    files = $complianceData
}

# Generate JSON report
$jsonPath = Join-Path $OutputPath 'ecrr-compliance-report.json'
($result | ConvertTo-Json -Depth 6) | Out-File -Encoding UTF8 $jsonPath

# Generate Markdown report
$mdPath = Join-Path $OutputPath 'ecrr-compliance-report.md'
@(
    "# ECRR Compliance Report",
    "",
    "Generated: $($result.generatedAt)",
    "",
    "## Metrics",
    "- Total Reports: $($metrics.totalReports)",
    "- Four-Section Compliance: $($result.complianceRates.fourSection)%",
    "- ECRR Gate Compliance: $($result.complianceRates.ecrrGate)%",
    "- Actor Declaration Compliance: $($result.complianceRates.actor)%",
    "- Production Marker Presence: $($result.complianceRates.production)%",
    "- Fully Compliant: $($result.complianceRates.fullyCompliant)% ($compliant/$total)",
    "",
    "## Top Non-compliance Samples (up to 20)",
    ($issues | Select-Object -First 20 | ForEach-Object { "- ``$($_.file)``: $([string]::Join(', ', $_.issues))" })
) | Out-File -Encoding UTF8 $mdPath

# Generate HTML dashboard
$htmlPath = Join-Path $OutputPath 'ecrr-compliance-dashboard.html'
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
            <p>Unified compliance monitoring and reporting</p>
        </div>
        
        <div class="metrics">
            <div class="metric">
                <div class="metric-value $(if ($complianceRate -ge $Threshold) { 'pass' } elseif ($complianceRate -ge 90) { 'warning' } else { 'fail' })">$complianceRate%</div>
                <div class="metric-label">Compliance Rate</div>
            </div>
            <div class="metric">
                <div class="metric-value">$compliant</div>
                <div class="metric-label">Compliant Files</div>
            </div>
            <div class="metric">
                <div class="metric-value">$($issues.Count)</div>
                <div class="metric-label">Non-Compliant Files</div>
            </div>
            <div class="metric">
                <div class="metric-value">$($metrics.totalReports)</div>
                <div class="metric-label">Total Reports</div>
            </div>
        </div>
        
        <h2>📊 File Compliance Status</h2>
        <table class="table">
            <thead>
                <tr>
                    <th>File</th>
                    <th>Status</th>
                    <th>Four Section</th>
                    <th>ECRR Gate</th>
                    <th>Actor</th>
                    <th>Production</th>
                    <th>Issues</th>
                </tr>
            </thead>
            <tbody>
"@

foreach ($file in $complianceData) {
    $status = if ($file.Compliant) { '<span class="status-pass">✅ PASS</span>' } else { '<span class="status-fail">❌ FAIL</span>' }
    $issues = if ($file.Issues.Count -gt 0) { ($file.Issues -join ', ') } else { 'None' }
    
    $html += @"
                <tr>
                    <td>$($file.File)</td>
                    <td>$status</td>
                    <td>$(if ($file.HasFourSection) { '✅' } else { '❌' })</td>
                    <td>$(if ($file.HasEcrrGate) { '✅' } else { '❌' })</td>
                    <td>$(if ($file.HasActor) { '✅' } else { '❌' })</td>
                    <td>$(if ($file.HasProduction) { '✅' } else { '❌' })</td>
                    <td class="issues">$issues</td>
                </tr>
"@
}

$html += @"
            </tbody>
        </table>
        
        <div class="timestamp">
            Generated on $($result.generatedAt)
        </div>
    </div>
</body>
</html>
"@

Set-Content -Path $htmlPath -Value $html -Encoding UTF8

# Display results
Write-Host ""
Write-Host "📈 Compliance Results:" -ForegroundColor Green
Write-Host "  ✅ Compliant Files: $compliant" -ForegroundColor Green
Write-Host "  ❌ Non-Compliant Files: $($issues.Count)" -ForegroundColor Red
Write-Host "  📊 Compliance Rate: $complianceRate%" -ForegroundColor $(if ($complianceRate -ge $Threshold) { "Green" } elseif ($complianceRate -ge 90) { "Yellow" } else { "Red" })
Write-Host "  📊 Four-Section: $($result.complianceRates.fourSection)%" -ForegroundColor Gray
Write-Host "  📊 ECRR Gate: $($result.complianceRates.ecrrGate)%" -ForegroundColor Gray
Write-Host "  📊 Actor Declaration: $($result.complianceRates.actor)%" -ForegroundColor Gray
Write-Host "  📊 Production Marker: $($result.complianceRates.production)%" -ForegroundColor Gray

Write-Host ""
Write-Host "📄 Reports Generated:" -ForegroundColor Cyan
Write-Host "  📊 JSON Report: $jsonPath" -ForegroundColor Gray
Write-Host "  📝 Markdown Report: $mdPath" -ForegroundColor Gray
Write-Host "  🌐 HTML Dashboard: $htmlPath" -ForegroundColor Gray

# Check threshold
if ($complianceRate -ge $Threshold) {
    Write-Host ""
    Write-Host "🎉 COMPLIANCE THRESHOLD MET!" -ForegroundColor Green
    Write-Host "   Target: $Threshold% | Actual: $complianceRate%" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "⚠️  COMPLIANCE THRESHOLD NOT MET" -ForegroundColor Red
    Write-Host "   Target: $Threshold% | Actual: $complianceRate%" -ForegroundColor Red
    Write-Host "   Need to fix $($issues.Count) files" -ForegroundColor Red
}

Write-Host ""
Write-Host "✅ Unified ECRR Compliance Validation completed" -ForegroundColor Green

return $result
