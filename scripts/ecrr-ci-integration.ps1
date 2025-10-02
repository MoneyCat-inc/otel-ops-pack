[CmdletBinding()]
param(
    [string]$ReportsPath = "docs/ECRR_REPORTS",
    [int]$Threshold = 95,
    [switch]$FailOnRegression = $false,
    [string]$OutputPath = "artifacts",
    [string]$BaselineFile = "",
    [switch]$IncludeArchived = $false
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$scriptRoot = Split-Path -Parent $PSCommandPath
$repoRoot = (Resolve-Path (Join-Path $scriptRoot '..')).ProviderPath

function Resolve-RepoPath {
    param(
        [string]$Path,
        [switch]$RequireExists
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $null
    }

    if (Test-Path -LiteralPath $Path) {
        return (Resolve-Path -LiteralPath $Path).ProviderPath
    }

    $candidate = Join-Path $repoRoot $Path
    if (Test-Path -LiteralPath $candidate) {
        return (Resolve-Path -LiteralPath $candidate).ProviderPath
    }

    if ($RequireExists) {
        throw "Path '$Path' could not be resolved relative to '$repoRoot'."
    }

    return $candidate
}

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = 'artifacts'
}

if ([string]::IsNullOrWhiteSpace($BaselineFile)) {
    $BaselineFile = Join-Path $OutputPath 'ecrr-compliance-baseline.json'
}

$resolvedReportsPath = Resolve-RepoPath -Path $ReportsPath -RequireExists
$resolvedOutputPath = Resolve-RepoPath -Path $OutputPath
if (-not (Test-Path -LiteralPath $resolvedOutputPath)) {
    New-Item -Path $resolvedOutputPath -ItemType Directory -Force | Out-Null
}
$resolvedOutputPath = (Resolve-Path -LiteralPath $resolvedOutputPath).ProviderPath

$resolvedBaselinePath = Resolve-RepoPath -Path $BaselineFile
if ($resolvedBaselinePath) {
    $baselineDir = Split-Path -Parent $resolvedBaselinePath
    if ($baselineDir -and -not (Test-Path -LiteralPath $baselineDir)) {
        New-Item -Path $baselineDir -ItemType Directory -Force | Out-Null
    }
}

Write-Host "🚀 ECRR CI/CD Integration" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Cyan
Write-Host "📁 Reports Path: $resolvedReportsPath" -ForegroundColor Gray
Write-Host "📂 Output Path:  $resolvedOutputPath" -ForegroundColor Gray
Write-Host "🎯 Threshold:    $Threshold%" -ForegroundColor Gray
Write-Host "📦 Include Archived: $($IncludeArchived.IsPresent)" -ForegroundColor Gray
Write-Host ""

# Load baseline if it exists
$baseline = $null
if ($resolvedBaselinePath -and (Test-Path -LiteralPath $resolvedBaselinePath)) {
    try {
        $baseline = Get-Content -Path $resolvedBaselinePath -Raw | ConvertFrom-Json
        Write-Host "📊 Loaded baseline from: $resolvedBaselinePath" -ForegroundColor Green
        Write-Host "   Baseline Compliance: $($baseline.ComplianceRate)%" -ForegroundColor Gray
        Write-Host "   Baseline Date:       $($baseline.Timestamp)" -ForegroundColor Gray
    } catch {
        Write-Host "⚠️  Could not load baseline file: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Run compliance check
Write-Host ""
Write-Host "🔍 Running compliance check..." -ForegroundColor Cyan
$complianceScript = Join-Path $scriptRoot 'ecrr-compliance-monitor.ps1'

if (-not (Test-Path -LiteralPath $complianceScript)) {
    Write-Host "❌ Compliance monitor script not found: $complianceScript" -ForegroundColor Red
    exit 1
}

$complianceArgs = @(
    '-ReportsPath', $resolvedReportsPath,
    '-OutputPath', $resolvedOutputPath,
    '-Threshold', $Threshold.ToString()
)

if ($IncludeArchived) {
    $complianceArgs += '-IncludeArchived'
}

if ($FailOnRegression) {
    $complianceArgs += '-FailOnNonCompliant'
}

Write-Host "   → pwsh -NoLogo -File $complianceScript $($complianceArgs -join ' ')" -ForegroundColor Gray
$null = & pwsh -NoLogo -File $complianceScript @complianceArgs
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Compliance check failed!" -ForegroundColor Red
    exit $LASTEXITCODE
}

$latestReport = Get-ChildItem -Path $resolvedOutputPath -Filter 'ecrr-compliance-report-*.json' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $latestReport) {
    Write-Host "❌ No compliance report generated!" -ForegroundColor Red
    exit 1
}

$report = Get-Content -Path $latestReport.FullName -Raw | ConvertFrom-Json

Write-Host ""
Write-Host "📈 Current Compliance Results:" -ForegroundColor Green
Write-Host "  📊 Compliance Rate: $($report.Summary.ComplianceRate)%" -ForegroundColor $(if ($report.Summary.ComplianceRate -ge $Threshold) { 'Green' } else { 'Red' })
Write-Host "  ✅ Compliant Files: $($report.Summary.CompliantFiles)" -ForegroundColor Green
Write-Host "  ❌ Non-Compliant Files: $($report.Summary.NonCompliantFiles)" -ForegroundColor $(if ($report.Summary.NonCompliantFiles -eq 0) { 'Green' } else { 'Red' })
Write-Host "  🎯 Average Score: $($report.Summary.AverageScore)/100" -ForegroundColor $(if ($report.Summary.AverageScore -ge 90) { 'Green' } elseif ($report.Summary.AverageScore -ge 80) { 'Yellow' } else { 'Red' })

$complianceChange = $null
$scoreChange = $null
$regressionDetected = $false

if ($baseline) {
    $complianceChange = $report.Summary.ComplianceRate - $baseline.ComplianceRate
    $scoreChange = $report.Summary.AverageScore - $baseline.AverageScore

    Write-Host ""
    Write-Host "📊 Regression Analysis:" -ForegroundColor Cyan
    Write-Host "  📈 Compliance Change: $([math]::Round($complianceChange, 2))%" -ForegroundColor $(if ($complianceChange -ge 0) { 'Green' } else { 'Red' })
    Write-Host "  📈 Score Change: $([math]::Round($scoreChange, 2)) points" -ForegroundColor $(if ($scoreChange -ge 0) { 'Green' } else { 'Red' })

    if ($complianceChange -lt 0 -and [math]::Abs($complianceChange) -gt 1) {
        Write-Host ""
        Write-Host "⚠️  REGRESSION DETECTED!" -ForegroundColor Red
        Write-Host "   Compliance dropped by $([math]::Abs([math]::Round($complianceChange, 2)))%" -ForegroundColor Red
        $regressionDetected = $true

        if ($FailOnRegression) {
            Write-Host "❌ Failing build due to compliance regression" -ForegroundColor Red
            exit 1
        }
    }
}

if ($report.Summary.ComplianceRate -lt $Threshold) {
    Write-Host ""
    Write-Host "❌ COMPLIANCE THRESHOLD NOT MET" -ForegroundColor Red
    Write-Host "   Target: $Threshold% | Actual: $($report.Summary.ComplianceRate)%" -ForegroundColor Red

    if ($report.NonCompliantFiles.Count -gt 0) {
        Write-Host ""
        Write-Host "🔧 Non-Compliant Files:" -ForegroundColor Red
        foreach ($file in $report.NonCompliantFiles) {
            $displayName = if ($file.Path) { $file.Path } else { $file.File }
            Write-Host "  - $displayName" -ForegroundColor Red
            if ($file.Issues) {
                foreach ($issue in $file.Issues) {
                    Write-Host "     • $issue" -ForegroundColor DarkRed
                }
            }
        }
    }

    exit 1
}

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
    IncludeArchived = $IncludeArchived.IsPresent
}

$baselineData | ConvertTo-Json -Depth 10 | Set-Content -Path $resolvedBaselinePath -Encoding UTF8
Write-Host "✅ Baseline updated successfully!" -ForegroundColor Green

$ciSummary = @{
    Status = if ($report.Summary.ComplianceRate -ge $Threshold) { 'PASS' } else { 'FAIL' }
    ComplianceRate = $report.Summary.ComplianceRate
    Threshold = $Threshold
    CompliantFiles = $report.Summary.CompliantFiles
    TotalFiles = $report.Summary.TotalFiles
    AverageScore = $report.Summary.AverageScore
    Regression = $regressionDetected
    ComplianceChange = if ($complianceChange -ne $null) { [math]::Round($complianceChange, 2) } else { $null }
    ScoreChange = if ($scoreChange -ne $null) { [math]::Round($scoreChange, 2) } else { $null }
    Timestamp = $report.Timestamp
    IncludeArchived = $IncludeArchived.IsPresent
}

$ciSummaryPath = Join-Path $resolvedOutputPath 'ecrr-ci-summary.json'
$ciSummary | ConvertTo-Json -Depth 10 | Set-Content -Path $ciSummaryPath -Encoding UTF8

Write-Host ""
Write-Host "📋 CI Summary:" -ForegroundColor Cyan
Write-Host "  Status: $($ciSummary.Status)" -ForegroundColor $(if ($ciSummary.Status -eq 'PASS') { 'Green' } else { 'Red' })
Write-Host "  Compliance: $($ciSummary.ComplianceRate)%" -ForegroundColor $(if ($ciSummary.Status -eq 'PASS') { 'Green' } else { 'Red' })
Write-Host "  Files: $($ciSummary.CompliantFiles)/$($ciSummary.TotalFiles)" -ForegroundColor Gray
Write-Host "  Score: $($ciSummary.AverageScore)/100" -ForegroundColor Gray
Write-Host "  Regression: $(if ($ciSummary.Regression) { 'YES' } else { 'NO' })" -ForegroundColor $(if ($ciSummary.Regression) { 'Yellow' } else { 'Green' })
Write-Host "  Summary File: $ciSummaryPath" -ForegroundColor Gray

Write-Host ""
Write-Host "🎉 ECRR CI/CD Integration completed!" -ForegroundColor Green

exit 0
