# ECRR Compliance Monitoring Script
# Tracks ECRR quality metrics over time and generates compliance reports

param(
    [string]$OutputPath = "artifacts/ecrr-compliance-report.json",
    [switch]$Detailed = $false,
    [switch]$GenerateDashboard = $false
)

# ECRR Compliance Monitoring Functions
function Get-ECRRReports {
    $reportsPath = "docs/ECRR_REPORTS"
    if (-not (Test-Path $reportsPath)) {
        Write-Warning "ECRR reports directory not found: $reportsPath"
        return @()
    }
    
    $reports = Get-ChildItem -Path $reportsPath -Filter "*.md" | Where-Object { $_.Name -ne "ECRR_PROCESSING_ANALYSIS.md" }
    return $reports
}

function Test-ECRRGateCompliance {
    param([string]$FilePath)
    
    $content = Get-Content $FilePath -Raw -ErrorAction SilentlyContinue
    if (-not $content) { return $false }
    
    # Check for ECRR Gate section
    $hasECRRGate = $content -match "## ✅.*ECRR Gate"
    if (-not $hasECRRGate) { return $false }
    
    # Check for mandatory validation text
    $hasMandatoryText = $content -match "MANDATORY VALIDATION"
    if (-not $hasMandatoryText) { return $false }
    
    # Check for checkboxes in ECRR Gate
    $checkboxPattern = '\[[ x]\]'
    $checkboxes = [regex]::Matches($content, $checkboxPattern)
    
    # Must have at least 20 checkboxes (minimum for comprehensive ECRR Gate)
    return $checkboxes.Count -ge 20
}

function Test-FourSectionStructure {
    param([string]$FilePath)
    
    $content = Get-Content $FilePath -Raw -ErrorAction SilentlyContinue
    if (-not $content) { return $false }
    
    # Check for all four required sections
    $sections = @(
        "## 🔍.*1\. Examine",
        "## 🧹.*2\. Clean", 
        "## 📝.*3\. Report",
        "## 🎭.*4\. Role"
    )
    
    $foundSections = 0
    foreach ($section in $sections) {
        if ($content -match $section) {
            $foundSections++
        }
    }
    
    return $foundSections -eq 4
}

function Test-ActorDeclaration {
    param([string]$FilePath)
    
    $content = Get-Content $FilePath -Raw -ErrorAction SilentlyContinue
    if (-not $content) { return $false }
    
    # Check for agent declaration in header
    $hasAgentHeader = $content -match "\*\*Agent\*\*:\s*\w+"
    if (-not $hasAgentHeader) { return $false }
    
    # Check for actor declaration in Role section
    $hasRoleSection = $content -match "## 🎭.*4\. Role" -and $content -match "Actor Declaration"
    
    return $hasRoleSection
}

function Test-EvidenceAttachment {
    param([string]$FilePath)
    
    $content = Get-Content $FilePath -Raw -ErrorAction SilentlyContinue
    if (-not $content) { return $false }
    
    # Check for evidence-related keywords
    $evidenceKeywords = @("Screenshot", "Log", "Config", "Artifact", "Evidence", "Attachment")
    $foundEvidence = 0
    
    foreach ($keyword in $evidenceKeywords) {
        if ($content -match $keyword) {
            $foundEvidence++
        }
    }
    
    return $foundEvidence -ge 2
}

function Test-StatusDeclaration {
    param([string]$FilePath)
    
    $content = Get-Content $FilePath -Raw -ErrorAction SilentlyContinue
    if (-not $content) { return $false }
    
    # Check for status indicators
    $statusPatterns = @(
        "✅.*COMPLETE",
        "❌.*FAILED", 
        "Status.*SUCCESS",
        "Status.*FAILURE"
    )
    
    foreach ($pattern in $statusPatterns) {
        if ($content -match $pattern) {
            return $true
        }
    }
    
    return $false
}

function Get-ReportMetrics {
    param([string]$FilePath)
    
    $content = Get-Content $FilePath -Raw -ErrorAction SilentlyContinue
    if (-not $content) { return @{} }
    
    $metrics = @{
        WordCount = ($content -split '\s+').Count
        LineCount = ($content -split "`n").Count
        HasECRRGate = Test-ECRRGateCompliance -FilePath $FilePath
        HasFourSectionStructure = Test-FourSectionStructure -FilePath $FilePath
        HasActorDeclaration = Test-ActorDeclaration -FilePath $FilePath
        HasEvidenceAttachment = Test-EvidenceAttachment -FilePath $FilePath
        HasStatusDeclaration = Test-StatusDeclaration -FilePath $FilePath
        FileName = Split-Path $FilePath -Leaf
        FilePath = $FilePath
        LastModified = (Get-Item $FilePath).LastWriteTime
    }
    
    return $metrics
}

function Generate-ComplianceReport {
    param([array]$Reports)
    
    $report = @{
        GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
        TotalReports = $Reports.Count
        ComplianceMetrics = @{
            ECRRGateCompliance = 0
            FourSectionStructure = 0
            ActorDeclaration = 0
            EvidenceAttachment = 0
            StatusDeclaration = 0
            OverallCompliance = 0
        }
        ReportDetails = @()
        Recommendations = @()
        QualityTrends = @{}
    }
    
    $totalReports = $Reports.Count
    if ($totalReports -eq 0) {
        $report.Recommendations += "No ECRR reports found. Create initial ECRR reports using the enhanced template."
        return $report
    }
    
    $compliantReports = 0
    
    foreach ($reportFile in $Reports) {
        $metrics = Get-ReportMetrics -FilePath $reportFile.FullName
        
        # Count compliant aspects
        $compliantAspects = 0
        if ($metrics.HasECRRGate) { 
            $report.ComplianceMetrics.ECRRGateCompliance++
            $compliantAspects++
        }
        if ($metrics.HasFourSectionStructure) { 
            $report.ComplianceMetrics.FourSectionStructure++
            $compliantAspects++
        }
        if ($metrics.HasActorDeclaration) { 
            $report.ComplianceMetrics.ActorDeclaration++
            $compliantAspects++
        }
        if ($metrics.HasEvidenceAttachment) { 
            $report.ComplianceMetrics.EvidenceAttachment++
            $compliantAspects++
        }
        if ($metrics.HasStatusDeclaration) { 
            $report.ComplianceMetrics.StatusDeclaration++
            $compliantAspects++
        }
        
        # Overall compliance (all 5 aspects)
        if ($compliantAspects -eq 5) {
            $compliantReports++
            $metrics.OverallCompliance = $true
        } else {
            $metrics.OverallCompliance = $false
        }
        
        if ($Detailed) {
            $report.ReportDetails += $metrics
        }
    }
    
    # Calculate compliance percentages
    $report.ComplianceMetrics.ECRRGateCompliance = [math]::Round(($report.ComplianceMetrics.ECRRGateCompliance / $totalReports) * 100, 1)
    $report.ComplianceMetrics.FourSectionStructure = [math]::Round(($report.ComplianceMetrics.FourSectionStructure / $totalReports) * 100, 1)
    $report.ComplianceMetrics.ActorDeclaration = [math]::Round(($report.ComplianceMetrics.ActorDeclaration / $totalReports) * 100, 1)
    $report.ComplianceMetrics.EvidenceAttachment = [math]::Round(($report.ComplianceMetrics.EvidenceAttachment / $totalReports) * 100, 1)
    $report.ComplianceMetrics.StatusDeclaration = [math]::Round(($report.ComplianceMetrics.StatusDeclaration / $totalReports) * 100, 1)
    $report.ComplianceMetrics.OverallCompliance = [math]::Round(($compliantReports / $totalReports) * 100, 1)
    
    # Generate recommendations
    if ($report.ComplianceMetrics.ECRRGateCompliance -lt 80) {
        $report.Recommendations += "ECRR Gate compliance is below 80%. Ensure all reports include the mandatory ECRR Gate section."
    }
    if ($report.ComplianceMetrics.FourSectionStructure -lt 90) {
        $report.Recommendations += "4-section structure compliance is below 90%. Use the enhanced template to ensure proper structure."
    }
    if ($report.ComplianceMetrics.ActorDeclaration -lt 95) {
        $report.Recommendations += "Actor declaration compliance is below 95%. Ensure all reports clearly declare responsible agents."
    }
    if ($report.ComplianceMetrics.EvidenceAttachment -lt 85) {
        $report.Recommendations += "Evidence attachment compliance is below 85%. Include more artifacts and verification steps."
    }
    if ($report.ComplianceMetrics.StatusDeclaration -lt 75) {
        $report.Recommendations += "Status declaration compliance is below 75%. Include clear success/failure status in all reports."
    }
    
    return $report
}

# Main execution
Write-Host "🔍 ECRR Compliance Monitoring" -ForegroundColor Cyan
Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')" -ForegroundColor Gray

# Get all ECRR reports
$reports = Get-ECRRReports
Write-Host "Found $($reports.Count) ECRR reports" -ForegroundColor Green

if ($reports.Count -eq 0) {
    Write-Warning "No ECRR reports found in docs/ECRR_REPORTS/"
    exit 1
}

# Generate compliance report
Write-Host "📊 Analyzing compliance metrics..." -ForegroundColor Yellow
$complianceReport = Generate-ComplianceReport -Reports $reports

# Display results
Write-Host "`n📈 ECRR Compliance Metrics:" -ForegroundColor Cyan
Write-Host "Total Reports: $($complianceReport.TotalReports)" -ForegroundColor White
Write-Host "ECRR Gate Compliance: $($complianceReport.ComplianceMetrics.ECRRGateCompliance)%" -ForegroundColor $(if ($complianceReport.ComplianceMetrics.ECRRGateCompliance -ge 80) { "Green" } else { "Red" })
Write-Host "4-Section Structure: $($complianceReport.ComplianceMetrics.FourSectionStructure)%" -ForegroundColor $(if ($complianceReport.ComplianceMetrics.FourSectionStructure -ge 90) { "Green" } else { "Yellow" })
Write-Host "Actor Declaration: $($complianceReport.ComplianceMetrics.ActorDeclaration)%" -ForegroundColor $(if ($complianceReport.ComplianceMetrics.ActorDeclaration -ge 95) { "Green" } else { "Yellow" })
Write-Host "Evidence Attachment: $($complianceReport.ComplianceMetrics.EvidenceAttachment)%" -ForegroundColor $(if ($complianceReport.ComplianceMetrics.EvidenceAttachment -ge 85) { "Green" } else { "Yellow" })
Write-Host "Status Declaration: $($complianceReport.ComplianceMetrics.StatusDeclaration)%" -ForegroundColor $(if ($complianceReport.ComplianceMetrics.StatusDeclaration -ge 75) { "Green" } else { "Red" })
Write-Host "Overall Compliance: $($complianceReport.ComplianceMetrics.OverallCompliance)%" -ForegroundColor $(if ($complianceReport.ComplianceMetrics.OverallCompliance -ge 70) { "Green" } else { "Red" })

# Display recommendations
if ($complianceReport.Recommendations.Count -gt 0) {
    Write-Host "`n💡 Recommendations:" -ForegroundColor Yellow
    foreach ($recommendation in $complianceReport.Recommendations) {
        Write-Host "  • $recommendation" -ForegroundColor White
    }
}

# Save report
$outputDir = Split-Path $OutputPath -Parent
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

$complianceReport | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
Write-Host "`n💾 Compliance report saved to: $OutputPath" -ForegroundColor Green

# Generate dashboard if requested
if ($GenerateDashboard) {
    $dashboardPath = $OutputPath -replace '\.json$', '-dashboard.html'
    $dashboardContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>ECRR Compliance Dashboard</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .header { text-align: center; margin-bottom: 30px; }
        .metrics { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-bottom: 30px; }
        .metric { background: #f8f9fa; padding: 15px; border-radius: 6px; text-align: center; }
        .metric-value { font-size: 2em; font-weight: bold; margin-bottom: 5px; }
        .metric-label { color: #666; font-size: 0.9em; }
        .chart-container { margin: 20px 0; }
        .recommendations { background: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; border-radius: 6px; margin-top: 20px; }
        .recommendations h3 { margin-top: 0; color: #856404; }
        .recommendations ul { margin: 0; padding-left: 20px; }
        .recommendations li { margin-bottom: 5px; color: #856404; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>ECRR Compliance Dashboard</h1>
            <p>Generated: $($complianceReport.GeneratedAt)</p>
        </div>
        
        <div class="metrics">
            <div class="metric">
                <div class="metric-value">$($complianceReport.TotalReports)</div>
                <div class="metric-label">Total Reports</div>
            </div>
            <div class="metric">
                <div class="metric-value" style="color: $(if ($complianceReport.ComplianceMetrics.ECRRGateCompliance -ge 80) { '#28a745' } else { '#dc3545' })">$($complianceReport.ComplianceMetrics.ECRRGateCompliance)%</div>
                <div class="metric-label">ECRR Gate Compliance</div>
            </div>
            <div class="metric">
                <div class="metric-value" style="color: $(if ($complianceReport.ComplianceMetrics.FourSectionStructure -ge 90) { '#28a745' } else { '#ffc107' })">$($complianceReport.ComplianceMetrics.FourSectionStructure)%</div>
                <div class="metric-label">4-Section Structure</div>
            </div>
            <div class="metric">
                <div class="metric-value" style="color: $(if ($complianceReport.ComplianceMetrics.ActorDeclaration -ge 95) { '#28a745' } else { '#ffc107' })">$($complianceReport.ComplianceMetrics.ActorDeclaration)%</div>
                <div class="metric-label">Actor Declaration</div>
            </div>
            <div class="metric">
                <div class="metric-value" style="color: $(if ($complianceReport.ComplianceMetrics.EvidenceAttachment -ge 85) { '#28a745' } else { '#ffc107' })">$($complianceReport.ComplianceMetrics.EvidenceAttachment)%</div>
                <div class="metric-label">Evidence Attachment</div>
            </div>
            <div class="metric">
                <div class="metric-value" style="color: $(if ($complianceReport.ComplianceMetrics.StatusDeclaration -ge 75) { '#28a745' } else { '#dc3545' })">$($complianceReport.ComplianceMetrics.StatusDeclaration)%</div>
                <div class="metric-label">Status Declaration</div>
            </div>
            <div class="metric">
                <div class="metric-value" style="color: $(if ($complianceReport.ComplianceMetrics.OverallCompliance -ge 70) { '#28a745' } else { '#dc3545' })">$($complianceReport.ComplianceMetrics.OverallCompliance)%</div>
                <div class="metric-label">Overall Compliance</div>
            </div>
        </div>
        
        <div class="chart-container">
            <canvas id="complianceChart" width="400" height="200"></canvas>
        </div>
        
        <script>
            const ctx = document.getElementById('complianceChart').getContext('2d');
            const complianceChart = new Chart(ctx, {
                type: 'bar',
                data: {
                    labels: ['ECRR Gate', '4-Section Structure', 'Actor Declaration', 'Evidence Attachment', 'Status Declaration', 'Overall'],
                    datasets: [{
                        label: 'Compliance %',
                        data: [$($complianceReport.ComplianceMetrics.ECRRGateCompliance), $($complianceReport.ComplianceMetrics.FourSectionStructure), $($complianceReport.ComplianceMetrics.ActorDeclaration), $($complianceReport.ComplianceMetrics.EvidenceAttachment), $($complianceReport.ComplianceMetrics.StatusDeclaration), $($complianceReport.ComplianceMetrics.OverallCompliance)],
                        backgroundColor: [
                            '$($complianceReport.ComplianceMetrics.ECRRGateCompliance -ge 80 ? '#28a745' : '#dc3545')',
                            '$($complianceReport.ComplianceMetrics.FourSectionStructure -ge 90 ? '#28a745' : '#ffc107')',
                            '$($complianceReport.ComplianceMetrics.ActorDeclaration -ge 95 ? '#28a745' : '#ffc107')',
                            '$($complianceReport.ComplianceMetrics.EvidenceAttachment -ge 85 ? '#28a745' : '#ffc107')',
                            '$($complianceReport.ComplianceMetrics.StatusDeclaration -ge 75 ? '#28a745' : '#dc3545')',
                            '$($complianceReport.ComplianceMetrics.OverallCompliance -ge 70 ? '#28a745' : '#dc3545')'
                        ]
                    }]
                },
                options: {
                    responsive: true,
                    scales: {
                        y: {
                            beginAtZero: true,
                            max: 100
                        }
                    }
                }
            });
        </script>
        
        <div class="recommendations">
            <h3>Recommendations</h3>
            <ul>
"@

    foreach ($recommendation in $complianceReport.Recommendations) {
        $dashboardContent += "<li>$recommendation</li>"
    }
    
    $dashboardContent += @"
            </ul>
        </div>
    </div>
</body>
</html>
"@
    
    $dashboardContent | Out-File -FilePath $dashboardPath -Encoding UTF8
    Write-Host "📊 Dashboard generated: $dashboardPath" -ForegroundColor Green
}

Write-Host "`n✅ ECRR compliance monitoring complete!" -ForegroundColor Green
