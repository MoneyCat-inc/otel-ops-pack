# Orchestrate full ECRR processing and publish the dashboard
# Steps: processing summary -> compliance validation -> monitoring entry -> dashboard publish

param(
    [string]$ReportsDir = "docs/ECRR_REPORTS",
    [string]$SummaryJson = "artifacts/ecrr-processing-summary.json",
    [string]$ValidationJson = "artifacts/ecrr-ci-validation.json",
    [string]$HistoryFile = "artifacts/ecrr-compliance-history.jsonl",
    [switch]$FailOnThreshold = $false,
    [switch]$StartWebServer,
    [switch]$GenerateGitHubPages
)

$ErrorActionPreference = "Stop"

Write-Host "ECRR End-to-End Process + Dashboard Publish" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

$overallExit = 0

try {
    # 1) Processing summary
    Write-Host "[1/4] Generating ECRR processing summary..." -ForegroundColor Yellow
    pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/ecrr-processing-summary.ps1 -OutputPath $SummaryJson | Write-Host

    # 2) Compliance validation (capture exit but continue)
    Write-Host "[2/4] Validating ECRR compliance..." -ForegroundColor Yellow
    $validateArgs = @("-File","scripts/validate-ecrr-compliance.ps1","-ReportsDir",$ReportsDir,"-OutJson",$ValidationJson)
    $validation = Start-Process pwsh -ArgumentList $validateArgs -NoNewWindow -PassThru -Wait
    if ($validation.ExitCode -ne 0) {
        Write-Host "Compliance validation returned non-zero exit code: $($validation.ExitCode)" -ForegroundColor Red
        $overallExit = $validation.ExitCode
    }

    # 3) Append monitoring entry
    Write-Host "[3/4] Appending compliance monitoring entry..." -ForegroundColor Yellow
    pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/monitor-ecrr-compliance.ps1 -ReportsDir $ReportsDir -HistoryFile $HistoryFile | Write-Host

    # 4) Publish dashboard
    Write-Host "[4/4] Publishing dashboard..." -ForegroundColor Yellow
    $publishArgs = @("-File","scripts/publish-ecrr-dashboard.ps1")
    if ($StartWebServer) { $publishArgs += "-StartWebServer" }
    if ($GenerateGitHubPages) { $publishArgs += "-GenerateGitHubPages" }
    $pub = Start-Process pwsh -ArgumentList $publishArgs -NoNewWindow -PassThru -Wait
    if ($pub.ExitCode -ne 0) {
        Write-Host "Dashboard publish returned non-zero exit code: $($pub.ExitCode)" -ForegroundColor Red
        if ($overallExit -eq 0) { $overallExit = $pub.ExitCode }
    }

    Write-Host "\nArtifacts:" -ForegroundColor Cyan
    Write-Host "- Summary JSON: $SummaryJson" -ForegroundColor White
    Write-Host "- Validation JSON: $ValidationJson" -ForegroundColor White
    Write-Host "- Compliance history: $HistoryFile" -ForegroundColor White
    Write-Host "- Dashboard: docs/dashboard/index.html" -ForegroundColor White
    Write-Host "- Trends: docs/dashboard/ecrr-compliance-trends.html" -ForegroundColor White

    if ($FailOnThreshold -and $overallExit -ne 0) {
        Write-Host "\n❌ ECRR thresholds failed; overall process marked as failed due to -FailOnThreshold." -ForegroundColor Red
        exit $overallExit
    }

    if ($overallExit -eq 0) {
        Write-Host "\n✅ E2E ECRR process complete; dashboard published." -ForegroundColor Green
        exit 0
    } else {
        Write-Host "\n⚠️  E2E ECRR process finished with validation/publish warnings (exit=$overallExit)." -ForegroundColor Yellow
        exit $overallExit
    }
}
catch {
    Write-Host ("Unhandled error: {0}" -f $_) -ForegroundColor Red
    exit 2
}


