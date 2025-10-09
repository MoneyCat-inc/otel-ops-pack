# Check Nightly Dashboard Export
# Part of BossCat OEM Gate Hardening Framework

param(
  [string]$ExportDir = "C:\otel\docs\observability\snapshots",
  [int]$MaxAgeMinutes = 90
)

Write-Host "`n🐾 [BossCat Export Check] Validating nightly dashboard exports..." -ForegroundColor Cyan

# Check if export directory exists
if (-not (Test-Path $ExportDir)) {
    Write-Error "❌ Export directory not found: $ExportDir"
    exit 2
}

# Get most recent export directories (should be dated)
$recentExports = Get-ChildItem -Path $ExportDir -Directory | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -First 1

if (-not $recentExports) {
    Write-Error "❌ No export directories found in $ExportDir"
    exit 2
}

Write-Host "📂 Most recent export: $($recentExports.Name)"

# Check age of most recent export
$age = (New-TimeSpan -Start $recentExports.LastWriteTimeUtc -End (Get-Date).ToUniversalTime()).TotalMinutes

if ($age -gt $MaxAgeMinutes) {
    Write-Error "❌ Export too old: $([int]$age) minutes (threshold: $MaxAgeMinutes min)"
    Write-Host "ℹ️  Expected export around 02:00 UTC daily"
    exit 2
}

# Check that export contains files
$exportFiles = Get-ChildItem -Path $recentExports.FullName -File -Recurse
$totalSize = ($exportFiles | Measure-Object -Property Length -Sum).Sum

if ($exportFiles.Count -eq 0) {
    Write-Error "❌ Export directory is empty: $($recentExports.Name)"
    exit 2
}

if ($totalSize -le 0) {
    Write-Error "❌ Export contains no data: $($recentExports.Name)"
    exit 2
}

# Check for expected file types (screenshots, data files)
$hasImages = $exportFiles | Where-Object { $_.Extension -match '\.(png|jpg|jpeg)$' }
$hasData = $exportFiles | Where-Object { $_.Extension -match '\.(json|csv|md)$' }

Write-Host ""
Write-Host "✅ Export validation passed:" -ForegroundColor Green
Write-Host "   📁 Directory: $($recentExports.Name)"
Write-Host "   📅 Age: $([int]$age) minutes (fresh within $MaxAgeMinutes min window)"
Write-Host "   📄 Files: $($exportFiles.Count) files"
Write-Host "   💾 Size: $([math]::Round($totalSize/1KB, 2)) KB"

if ($hasImages) {
    Write-Host "   🖼️  Images: $($hasImages.Count) screenshots"
}
if ($hasData) {
    Write-Host "   📊 Data: $($hasData.Count) data files"
}

Write-Host ""
Write-Host "🐾 Nightly export check: PASS" -ForegroundColor Green

exit 0

