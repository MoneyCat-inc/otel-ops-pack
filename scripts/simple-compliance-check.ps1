# Simple ECRR Compliance Checker
param(
    [string]$ReportsPath = "docs/ECRR_REPORTS"
)

Write-Host "🔍 ECRR Compliance Checker" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan

# Get all ECRR report files (excluding archive)
$reportFiles = Get-ChildItem -Path $ReportsPath -Filter "*.md" -Recurse | Where-Object { 
    $_.Name -match '\d{4}-\d{2}-\d{2}' -and 
    $_.Name -notmatch 'backup' -and 
    $_.FullName -notmatch '\\archive\\'
}

$totalFiles = $reportFiles.Count
Write-Host "📊 Total ECRR Reports Found: $totalFiles" -ForegroundColor Yellow

if ($totalFiles -eq 0) {
    Write-Host "❌ No ECRR reports found!" -ForegroundColor Red
    exit 1
}

# Check compliance criteria
$compliantFiles = 0
$nonCompliantFiles = @()

foreach ($file in $reportFiles) {
    $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }
    
    $isCompliant = $true
    $issues = @()
    
    # Check for production marker
    if ($content -notmatch '✅.*PRODUCTION READY') {
        $isCompliant = $false
        $issues += "Missing production marker"
    }
    
    # Check for four-section structure (flexible regex)
    $sections = @(
        "## .*(1\. )?Examine",
        "## .*(2\. )?Clean", 
        "## .*(3\. )?Report",
        "## .*(4\. )?Role"
    )
    
    $foundSections = 0
    foreach ($section in $sections) {
        if ($content -match $section) {
            $foundSections++
        }
    }
    
    if ($foundSections -ne 4) {
        $isCompliant = $false
        $issues += "Missing four-section structure ($foundSections/4 sections found)"
    }
    
    # Check for ECRR Gate
    if ($content -notmatch '## .*ECRR Gate') {
        $isCompliant = $false
        $issues += "Missing ECRR Gate"
    }
    
    if ($isCompliant) {
        $compliantFiles++
    } else {
        $nonCompliantFiles += @{
            File = $file.Name
            Issues = $issues
        }
    }
}

$complianceRate = [math]::Round(($compliantFiles / $totalFiles) * 100, 2)

Write-Host ""
Write-Host "📈 Compliance Results:" -ForegroundColor Green
Write-Host "  ✅ Compliant Files: $compliantFiles" -ForegroundColor Green
Write-Host "  ❌ Non-Compliant Files: $($nonCompliantFiles.Count)" -ForegroundColor Red
Write-Host "  📊 Compliance Rate: $complianceRate%" -ForegroundColor $(if ($complianceRate -ge 95) { "Green" } elseif ($complianceRate -ge 90) { "Yellow" } else { "Red" })

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

Write-Host ""
if ($complianceRate -ge 95) {
    Write-Host "🎉 TARGET ACHIEVED! Compliance rate: $complianceRate% (≥95%)" -ForegroundColor Green
} else {
    $needed = [math]::Ceiling((95 - $complianceRate) * $totalFiles / 100)
    Write-Host "🎯 Target: 95% | Need to fix $needed more files" -ForegroundColor Yellow
}

exit 0
