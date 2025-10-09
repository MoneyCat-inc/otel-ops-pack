# BossCat OEM - Evidence Retention Policy
# Prunes old evidence packs to keep artifacts directory tidy

<#
.SYNOPSIS
  Removes evidence packs older than specified retention period.

.DESCRIPTION
  Cleans up old evidence-*.zip files from the out directory
  while preserving recent artifacts for compliance.

.PARAMETER OutDir
  Directory containing evidence packs (default: out)

.PARAMETER Days
  Retention period in days (default: 30)

.EXAMPLE
  pwsh -File scripts\prune-evidence.ps1
  
.EXAMPLE
  pwsh -File scripts\prune-evidence.ps1 -OutDir out -Days 90
#>

param(
  [string]$OutDir = "out",
  [int]$Days = 30
)

Write-Host "🧹 BossCat OEM - Evidence Retention Policy" -ForegroundColor Cyan

if (-not (Test-Path $OutDir)) {
  Write-Host "   ℹ️  Output directory not found: $OutDir" -ForegroundColor Yellow
  exit 0
}

$cutoff = (Get-Date).AddDays(-$Days)
$cutoffStr = $cutoff.ToString("yyyy-MM-dd HH:mm:ss UTC")

Write-Host "   Retention period: $Days days" -ForegroundColor Gray
Write-Host "   Cutoff date: $cutoffStr" -ForegroundColor Gray
Write-Host ""

# Find old evidence packs
$oldPacks = Get-ChildItem $OutDir -Filter "evidence-*.zip" -ErrorAction SilentlyContinue |
  Where-Object { $_.LastWriteTime -lt $cutoff }

if ($oldPacks.Count -eq 0) {
  Write-Host "   ✅ No evidence packs older than $Days days" -ForegroundColor Green
  exit 0
}

# Calculate total size
$totalSize = ($oldPacks | Measure-Object -Property Length -Sum).Sum
$totalSizeMB = [math]::Round($totalSize / 1MB, 2)

Write-Host "   Found $($oldPacks.Count) evidence pack(s) older than $Days days (total: $totalSizeMB MB)" -ForegroundColor Yellow
Write-Host ""

# Remove old packs
$removed = 0
foreach ($pack in $oldPacks) {
  try {
    $age = ((Get-Date) - $pack.LastWriteTime).Days
    Write-Host "   Removing: $($pack.Name) (age: $age days)" -ForegroundColor Gray
    Remove-Item $pack.FullName -Force
    $removed++
  } catch {
    Write-Warning "   Failed to remove $($pack.Name): $_"
  }
}

Write-Host ""
Write-Host "🧹 Pruned $removed evidence pack(s), freed $totalSizeMB MB" -ForegroundColor Cyan
exit 0

