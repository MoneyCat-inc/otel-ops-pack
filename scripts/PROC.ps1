# PROC = Process Reports Order Correct
param(
    [int]$CorrelationWindowMinutes = 720,
    [string]$EcrrOutputDir = "artifacts",
    [string]$BossOutputDir = "artifacts",
    [string]$BossReportsDir = "docs/BossCat/reports",
    [string]$MemxOutputDir = "artifacts/memx/hardware"
)

$ErrorActionPreference = 'Stop'

Write-Host "PROC - Process Reports Order Correct" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ("Window: {0} min | IncludeMemx: True" -f $CorrelationWindowMinutes) -ForegroundColor Gray

pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/process-ecrr-and-boss.ps1 `
    -EcrrOutputDir $EcrrOutputDir `
    -BossOutputDir $BossOutputDir `
    -BossReportsDir $BossReportsDir `
    -CorrelationWindowMinutes $CorrelationWindowMinutes `
    -MemxOutputDir $MemxOutputDir `
    -IncludeMemx | Write-Host

$corr = Join-Path $EcrrOutputDir 'ecrr-boss-correlation.json'
if (Test-Path $corr) {
    try {
        $j = Get-Content $corr -Raw | ConvertFrom-Json
        $pairs = @($j.pairs).Count
        Write-Host ("✅ Correlation ready: {0} (pairs: {1})" -f $corr, $pairs) -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Correlation file present but not readable as JSON" -ForegroundColor Yellow
    }
} else {
    Write-Host "ℹ️ Correlation file not found yet." -ForegroundColor Yellow
}

exit 0


