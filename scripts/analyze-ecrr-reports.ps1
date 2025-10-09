# ECRR Reports Analysis Script
# Analyzes all ECRR reports for compliance and generates consolidated metrics

$ErrorActionPreference = "Continue"

Write-Host "`n📊 ECRR Reports Analysis" -ForegroundColor Cyan
Write-Host "=" * 60

# Get all ECRR reports
$reportsPath = "docs\ecrr\ECRR_REPORTS"
$mdReports = Get-ChildItem -Path $reportsPath -Recurse -Include "*.md" -File
$jsonFiles = Get-ChildItem -Path $reportsPath -Recurse -Include "*.json" -File

Write-Host "`n📁 Inventory:" -ForegroundColor Yellow
Write-Host "   Markdown Reports: $($mdReports.Count)"
Write-Host "   JSON Evidence Files: $($jsonFiles.Count)"
Write-Host "   Total Artifacts: $($mdReports.Count + $jsonFiles.Count)"

# Analyze by month
Write-Host "`n📅 Reports by Month:" -ForegroundColor Yellow
$mdReports | Group-Object {$_.LastWriteTime.ToString("yyyy-MM")} | 
    Sort-Object Name -Descending | 
    ForEach-Object { 
        Write-Host "   $($_.Name): $($_.Count) reports" 
    }

# Most recent reports
Write-Host "`n🆕 Most Recent Reports:" -ForegroundColor Yellow
$mdReports | Sort-Object LastWriteTime -Descending | Select-Object -First 5 | ForEach-Object {
    Write-Host "   - $($_.Name) ($(Get-Date $_.LastWriteTime -Format 'yyyy-MM-dd HH:mm'))"
}

# Analyze content for ECRR compliance
Write-Host "`n✅ ECRR Compliance Analysis:" -ForegroundColor Yellow

$compliance = @{
    TotalReports = $mdReports.Count
    HasExamine = 0
    HasClean = 0
    HasReport = 0
    HasRole = 0
    FullCompliance = 0
}

foreach ($report in $mdReports) {
    $content = Get-Content $report.FullName -Raw -ErrorAction SilentlyContinue
    if ($content) {
        $hasE = $content -match "(?i)(##?\s*E[xamine]*\s*[-:]|Examine)" 
        $hasC = $content -match "(?i)(##?\s*C[lean]*\s*[-:]|Clean)"
        $hasR1 = $content -match "(?i)(##?\s*R[eport]*\s*[-:]|Report)"
        $hasR2 = $content -match "(?i)(##?\s*R[ole]*\s*[-:]|Role|Actor|Agent)"
        
        if ($hasE) { $compliance.HasExamine++ }
        if ($hasC) { $compliance.HasClean++ }
        if ($hasR1) { $compliance.HasReport++ }
        if ($hasR2) { $compliance.HasRole++ }
        if ($hasE -and $hasC -and $hasR1 -and $hasR2) { $compliance.FullCompliance++ }
    }
}

$complianceRate = [math]::Round(($compliance.FullCompliance / $compliance.TotalReports) * 100, 1)

Write-Host "   Reports with 'Examine' section: $($compliance.HasExamine)/$($compliance.TotalReports) ($([math]::Round(($compliance.HasExamine/$compliance.TotalReports)*100,1))%)"
Write-Host "   Reports with 'Clean' section: $($compliance.HasClean)/$($compliance.TotalReports) ($([math]::Round(($compliance.HasClean/$compliance.TotalReports)*100,1))%)"
Write-Host "   Reports with 'Report' section: $($compliance.HasReport)/$($compliance.TotalReports) ($([math]::Round(($compliance.HasReport/$compliance.TotalReports)*100,1))%)"
Write-Host "   Reports with 'Role' section: $($compliance.HasRole)/$($compliance.TotalReports) ($([math]::Round(($compliance.HasRole/$compliance.TotalReports)*100,1))%)"
Write-Host "`n   ✨ Full ECRR Compliance: $($compliance.FullCompliance)/$($compliance.TotalReports) ($complianceRate%)" -ForegroundColor Green

# Report types analysis
Write-Host "`n📋 Report Types:" -ForegroundColor Yellow
$reportTypes = @{
    Deployment = 0
    Nightly = 0
    Service = 0
    BossCat = 0
    Status = 0
    Implementation = 0
    Other = 0
}

foreach ($report in $mdReports) {
    $name = $report.Name.ToLower()
    if ($name -match "deployment") { $reportTypes.Deployment++ }
    elseif ($name -match "nightly|orchestration") { $reportTypes.Nightly++ }
    elseif ($name -match "service|recovery") { $reportTypes.Service++ }
    elseif ($name -match "bosscat|rollout") { $reportTypes.BossCat++ }
    elseif ($name -match "status|dashboard") { $reportTypes.Status++ }
    elseif ($name -match "implementation|complete|analysis") { $reportTypes.Implementation++ }
    else { $reportTypes.Other++ }
}

$reportTypes.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object {
    if ($_.Value -gt 0) {
        Write-Host "   $($_.Key): $($_.Value) reports"
    }
}

# Evidence files analysis
Write-Host "`n🔍 Evidence Trail:" -ForegroundColor Yellow
Write-Host "   JSON Evidence Files: $($jsonFiles.Count)"

$evidenceTypes = $jsonFiles | ForEach-Object {
    $name = $_.Name
    if ($name -match "evidence") { "Evidence" }
    elseif ($name -match "metrics|compliance") { "Metrics" }
    elseif ($name -match "config|plan") { "Configuration" }
    elseif ($name -match "results|summary") { "Results" }
    else { "Other" }
} | Group-Object | Sort-Object Count -Descending

$evidenceTypes | ForEach-Object {
    Write-Host "   $($_.Name): $($_.Count) files"
}

# Summary
Write-Host "`n" + ("=" * 60)
Write-Host "📊 ECRR Processing Summary" -ForegroundColor Cyan
Write-Host "=" * 60
Write-Host "   Total ECRR Reports: $($mdReports.Count)" -ForegroundColor Green
Write-Host "   ECRR Compliance Rate: $complianceRate%" -ForegroundColor Green
Write-Host "   Evidence Files: $($jsonFiles.Count)" -ForegroundColor Green
Write-Host "   Analysis Status: ✅ COMPLETE" -ForegroundColor Green
Write-Host "`n"

# Export summary to JSON
$summary = @{
    timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    total_reports = $mdReports.Count
    total_json_files = $jsonFiles.Count
    compliance = $compliance
    compliance_rate_percent = $complianceRate
    report_types = $reportTypes
    recent_reports = $mdReports | Sort-Object LastWriteTime -Descending | Select-Object -First 10 | ForEach-Object {
        @{
            name = $_.Name
            last_modified = $_.LastWriteTime.ToString("yyyy-MM-ddTHH:mm:ssZ")
            size_kb = [math]::Round($_.Length / 1KB, 2)
        }
    }
}

$summaryPath = "artifacts\ecrr-processing-summary-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$summary | ConvertTo-Json -Depth 10 | Out-File $summaryPath -Encoding utf8
Write-Host "📁 Summary exported to: $summaryPath" -ForegroundColor Cyan

