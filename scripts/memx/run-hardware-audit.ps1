param(
    [string]$OutputDir = "artifacts/memx/hardware",
    [switch]$OpenReport
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$timestamp = (Get-Date).ToString('yyyyMMddTHHmmssZ')
$outFile = Join-Path $OutputDir ("memx-hardware-" + $timestamp + ".json")

Write-Host "Running MemX hardware audit..." -ForegroundColor Cyan
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/memx/hardware-report.ps1 -OutDir $OutputDir | Write-Host

if (Test-Path $outFile) {
    Write-Host "✅ Hardware report: $outFile" -ForegroundColor Green
    if ($OpenReport) { Start-Process $outFile }
} else {
    Write-Host "ℹ️ Report directory: $OutputDir (script writes its own timestamped filename)" -ForegroundColor Yellow
}

exit 0


