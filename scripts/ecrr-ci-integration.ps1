# ECRR CI/CD Integration Script
param(
    [string]$ReportsPath = "docs/ECRR_REPORTS",
    [int]$Threshold = 95,
    [switch]$FailOnRegression = $false,
    [string]$BaselineFile = "artifacts/ecrr-compliance-baseline.json"
)

Write-Host "🚀 ECRR CI/CD Integration" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Cyan

# Load baseline if it exists
$baseline = $null
if (Test-Path $BaselineFile) {
    try {
        $baselineContent = Get-Content -Path $BaselineFile -Raw
        $baseline = $baselineContent | ConvertFrom-Json
        Write-Host "📊 Loaded baseline from: $BaselineFile" -ForegroundColor Green
        Write-Host "   Baseline Compliance: $($baseline.ComplianceRate)%" -ForegroundColor Gray
        Write-Host "   Baseline Date: $($baseline.Timestamp)" -ForegroundColor Gray
    } catch {
        Write-Host "⚠️  Could not load baseline file: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Run compliance check
Write-Host ""
Write-Host "🔍 Running compliance check..." -ForegroundColor Cyan
$complianceScript = Join-Path (Get-Location).Path "scripts/ecrr-compliance-monitor.ps1"

if (-not (Test-Path $complianceScript)) {
    Write-Host "❌ Compliance monitor script not found: $complianceScript" -ForegroundColor Red
    exit 1
}

# Run the compliance monitor
$result = & pwsh -File $complianceScript -Threshold $Threshold -FailOnNonCompliant:$FailOnRegression -OutputPath "artifacts"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Compliance check failed!" -ForegroundColor Red
    exit $LASTEXITCODE
}

# Load the latest compliance report
$latestReport = Get-ChildItem -Path "artifacts" -Filter "ecrr-compliance-report-*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if (-not $latestReport) {
    Write-Host "❌ No compliance report generated!" -ForegroundColor Red
    exit 1
}

$report = Get-Content -Path $latestReport.FullName -Raw | ConvertFrom-Json

Write-Host ""
Write-Host "📈 Current Compliance Results:" -ForegroundColor Green
Write-Host "  📊 Compliance Rate: $($report.Summary.ComplianceRate)%" -ForegroundColor $(if ($report.Summary.ComplianceRate -ge $Threshold) { "Green" } else { "Red" })
Write-Host "  ✅ Compliant Files: $($report.Summary.CompliantFiles)" -ForegroundColor Green
Write-Host "  ❌ Non-Compliant Files: $($report.Summary.NonCompliantFiles)" -ForegroundColor $(if ($report.Summary.NonCompliantFiles -eq 0) { "Green" } else { "Red" })
Write-Host "  🎯 Average Score: $($report.Summary.AverageScore)/100" -ForegroundColor $(if ($report.Summary.AverageScore -ge 90) { "Green" } elseif ($report.Summary.AverageScore -ge 80) { "Yellow" } else { "Red" })

# Check for regression if baseline exists
if ($baseline) {
    $complianceChange = $report.Summary.ComplianceRate - $baseline.ComplianceRate
    $scoreChange = $report.Summary.AverageScore - $baseline.AverageScore
    
    Write-Host ""
    Write-Host "📊 Regression Analysis:" -ForegroundColor Cyan
    Write-Host "  📈 Compliance Change: $([math]::Round($complianceChange, 2))%" -ForegroundColor $(if ($complianceChange -ge 0) { "Green" } else { "Red" })
    Write-Host "  📈 Score Change: $([math]::Round($scoreChange, 2)) points" -ForegroundColor $(if ($scoreChange -ge 0) { "Green" } else { "Red" })
    
    if ($complianceChange -lt 0 -and [math]::Abs($complianceChange) -gt 1) {
        Write-Host ""
        Write-Host "⚠️  REGRESSION DETECTED!" -ForegroundColor Red
        Write-Host "   Compliance dropped by $([math]::Abs($complianceChange))%" -ForegroundColor Red
        
        if ($FailOnRegression) {
            Write-Host "❌ Failing build due to compliance regression" -ForegroundColor Red
            exit 1
        }
    }
}

# Check threshold compliance
if ($report.Summary.ComplianceRate -lt $Threshold) {
    Write-Host ""
    Write-Host "❌ COMPLIANCE THRESHOLD NOT MET" -ForegroundColor Red
    Write-Host "   Target: $Threshold% | Actual: $($report.Summary.ComplianceRate)%" -ForegroundColor Red
    
    if ($report.Summary.NonCompliantFiles -gt 0) {
        Write-Host ""
        Write-Host "🔧 Non-Compliant Files:" -ForegroundColor Red
        foreach ($file in $report.NonCompliantFiles) {
            Write-Host "  ❌ $($file.File)" -ForegroundColor Red
            foreach ($issue in $file.Issues) {
                Write-Host "     - $issue" -ForegroundColor DarkRed
            }
        }
    }
    
    exit 1
}

# Update baseline if we passed
Write-Host ""
Write-Host "💾 Updating compliance baseline..." -ForegroundColor Cyan
$baselineData = @{
    Timestamp = $report.Timestamp
    ComplianceRate = $report.Summary.ComplianceRate
    AverageScore = $report.Summary.AverageScore
    TotalFiles = $report.Summary.TotalFiles
    CompliantFiles = $report.Summary.CompliantFiles
    NonCompliantFiles = $report.Summary.NonCompliantFiles
    Threshold = $Threshold
}

$baselineData | ConvertTo-Json -Depth 10 | Set-Content -Path $BaselineFile -Encoding UTF8

Write-Host "✅ Baseline updated successfully!" -ForegroundColor Green

# Generate CI summary
$ciSummary = @{
    Status = if ($report.Summary.ComplianceRate -ge $Threshold) { "PASS" } else { "FAIL" }
    ComplianceRate = $report.Summary.ComplianceRate
    Threshold = $Threshold
    CompliantFiles = $report.Summary.CompliantFiles
    TotalFiles = $report.Summary.TotalFiles
    AverageScore = $report.Summary.AverageScore
    Regression = if ($baseline) { $complianceChange -lt 0 -and [math]::Abs($complianceChange) -gt 1 } else { $false }
    Timestamp = $report.Timestamp
}

$ciSummaryPath = "artifacts/ecrr-ci-summary.json"
$ciSummary | ConvertTo-Json -Depth 10 | Set-Content -Path $ciSummaryPath -Encoding UTF8

Write-Host ""
Write-Host "📋 CI Summary:" -ForegroundColor Cyan
Write-Host "  Status: $($ciSummary.Status)" -ForegroundColor $(if ($ciSummary.Status -eq "PASS") { "Green" } else { "Red" })
Write-Host "  Compliance: $($ciSummary.ComplianceRate)%" -ForegroundColor $(if ($ciSummary.ComplianceRate -ge $Threshold) { "Green" } else { "Red" })
Write-Host "  Files: $($ciSummary.CompliantFiles)/$($ciSummary.TotalFiles)" -ForegroundColor Gray
Write-Host "  Score: $($ciSummary.AverageScore)/100" -ForegroundColor Gray
Write-Host "  Regression: $(if ($ciSummary.Regression) { 'YES' } else { 'NO' })" -ForegroundColor $(if ($ciSummary.Regression) { "Red" } else { "Green" })

Write-Host ""
Write-Host "🎉 ECRR CI/CD Integration completed!" -ForegroundColor Green

exit 0
