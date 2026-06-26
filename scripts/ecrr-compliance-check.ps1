# CI entrypoint: ECRR compliance rate check (workflow artifact + threshold gate)
param(
    [string]$ReportsPath = "CHAR/ECRR/ECRR_REPORTS",
    [int]$MinCompliancePct = 80
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path "artifacts")) {
    New-Item -ItemType Directory -Path "artifacts" -Force | Out-Null
}

$outJson = Join-Path "artifacts" ("ecrr-compliance-check-{0}.json" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
$result = & "$PSScriptRoot\..\BRAV\SCPT\validate-ecrr-compliance.ps1" `
    -ReportsPath $ReportsPath `
    -OutDir "artifacts" `
    -OutJson $outJson

$complianceRate = [double]$result.complianceRates.fourSection
Write-Host ""
Write-Host "Compliance Rate: $complianceRate%" -ForegroundColor $(if ($complianceRate -ge $MinCompliancePct) { "Green" } else { "Red" })
Write-Host "Reports scanned: $($result.metrics.totalReports)"
Write-Host "Four-section: $($result.complianceRates.fourSection)% | ECRR gate: $($result.complianceRates.ecrrGate)%"
Write-Host "Artifact: $outJson"

if ($complianceRate -lt $MinCompliancePct) {
    exit 1
}
exit 0

