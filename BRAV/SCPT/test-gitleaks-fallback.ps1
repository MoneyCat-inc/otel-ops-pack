# GitLeaks License Fallback Script
# Run this locally to test GitLeaks scanning without a license

param(
    [string]$SourcePath = ".",
    [string]$ReportPath = "gitleaks-report.json",
    [switch]$Verbose
)

Write-Host "🔍 GitLeaks License Fallback Test" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# Set temporary license for this session
$env:GITLEAKS_LICENSE = "DUMMY_LOCAL_DEV"

Write-Host "⚠️ Using temporary license: DUMMY_LOCAL_DEV" -ForegroundColor Yellow
Write-Host "📧 To get your real license, visit: https://gitleaks.io" -ForegroundColor Blue
Write-Host ""

# Check if gitleaks is installed
try {
    $gitleaksVersion = gitleaks version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ GitLeaks found: $gitleaksVersion" -ForegroundColor Green
    } else {
        Write-Host "❌ GitLeaks not found. Please install it first:" -ForegroundColor Red
        Write-Host "   https://github.com/gitleaks/gitleaks#installation" -ForegroundColor Blue
        exit 1
    }
} catch {
    Write-Host "❌ GitLeaks not found. Please install it first:" -ForegroundColor Red
    Write-Host "   https://github.com/gitleaks/gitleaks#installation" -ForegroundColor Blue
    exit 1
}

# Run GitLeaks scan
Write-Host "🔍 Running GitLeaks scan on: $SourcePath" -ForegroundColor Cyan

$args = @(
    "detect",
    "--source", $SourcePath,
    "--report-path", $ReportPath,
    "--report-format", "json"
)

if ($Verbose) {
    $args += "--verbose"
}

try {
    & gitleaks @args
    $exitCode = $LASTEXITCODE
    
    if ($exitCode -eq 0) {
        Write-Host "✅ GitLeaks scan completed successfully" -ForegroundColor Green
        if (Test-Path $ReportPath) {
            $reportSize = (Get-Item $ReportPath).Length
            Write-Host "📄 Report generated: $ReportPath ($reportSize bytes)" -ForegroundColor Green
        }
    } else {
        Write-Host "⚠️ GitLeaks scan completed with warnings (exit code: $exitCode)" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "📋 Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Review the report: $ReportPath" -ForegroundColor White
    Write-Host "2. Get your real GitLeaks license: https://gitleaks.io" -ForegroundColor White
    Write-Host "3. Add it as a GitHub secret: GITLEAKS_LICENSE" -ForegroundColor White
    Write-Host "4. Remove this fallback script when license is added" -ForegroundColor White
    
    exit $exitCode
    
} catch {
    Write-Host "❌ Error running GitLeaks: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
