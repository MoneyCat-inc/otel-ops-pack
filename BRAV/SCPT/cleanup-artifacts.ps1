#Requires -Version 7.0
<#!
.SYNOPSIS
  Prune stale artifacts and logs with a dry-run by default (ECRR-compliant).

.DESCRIPTION
  Scans common output directories under C:\otel (artifacts, logs) and proposes deletions
  based on age and patterns. Produces a JSON report in artifacts/ with actions taken or proposed.

.PARAMETER Days
  Age threshold in days. Files older than this are selected. Default: 14

.PARAMETER IncludeLogs
  Also include items under logs/. Default: false

.PARAMETER Force
  Execute deletions (not just dry-run). Default: false

.EXAMPLE
  pwsh -File scripts/cleanup-artifacts.ps1 -Days 7

.EXAMPLE
  pwsh -File scripts/cleanup-artifacts.ps1 -Days 30 -IncludeLogs -Force

.NOTES
  ECRR: Examine -> Clean -> Report -> Role
  - Examine: inventory current files and sizes
  - Clean: delete only when -Force is provided
  - Report: write artifacts/cleanup-report-<timestamp>.json
  - Role: Cursor Agent — Observability Copilot
#>

param(
  [int]$Days = 14,
  [switch]$IncludeLogs,
  [switch]$Force
)

$ErrorActionPreference = 'Stop'

function New-Timestamp {
  Get-Date -Format 'yyyyMMdd-HHmmss'
}

function Write-Color($Message, [ConsoleColor]$Color = [ConsoleColor]::Gray) {
  $orig = $Host.UI.RawUI.ForegroundColor
  $Host.UI.RawUI.ForegroundColor = $Color
  Write-Host $Message
  $Host.UI.RawUI.ForegroundColor = $orig
}

# Examine
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$repo = Resolve-Path (Join-Path $root '..')
Set-Location $repo

$targets = @('artifacts')
if ($IncludeLogs) { $targets += 'logs' }

$ageThreshold = (Get-Date).AddDays(-$Days)
$selected = @()

foreach ($dir in $targets) {
  $path = Join-Path $repo $dir
  if (-not (Test-Path $path)) { continue }
  Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt $ageThreshold } |
    ForEach-Object {
      $selected += [pscustomobject]@{
        path = $_.FullName
        size_bytes = $_.Length
        last_write = $_.LastWriteTime
        target_dir = $dir
      }
    }
}

$totalBytes = ($selected | Measure-Object -Property size_bytes -Sum).Sum
$humanSize = if ($totalBytes -ge 1GB) { '{0:N2} GB' -f ($totalBytes/1GB) } elseif ($totalBytes -ge 1MB) { '{0:N2} MB' -f ($totalBytes/1MB) } elseif ($totalBytes -ge 1KB) { '{0:N2} KB' -f ($totalBytes/1KB) } else { '{0} B' -f $totalBytes }

Write-Color "Found $($selected.Count) files older than $Days days (~$humanSize)." ([ConsoleColor]::Yellow)

# Clean (optional)
$deleted = @()
if ($Force) {
  foreach ($item in $selected) {
    try {
      Remove-Item -LiteralPath $item.path -Force -ErrorAction Stop
      $deleted += $item
    } catch {
      Write-Color "Failed to delete: $($item.path) -> $($_.Exception.Message)" ([ConsoleColor]::Red)
    }
  }
  Write-Color "Deleted $($deleted.Count) files." ([ConsoleColor]::Green)
} else {
  Write-Color 'Dry-run mode: no files deleted. Use -Force to apply.' ([ConsoleColor]::Cyan)
}

# Report
$artifactDir = Join-Path $repo 'artifacts'
if (-not (Test-Path $artifactDir)) { New-Item -ItemType Directory -Path $artifactDir | Out-Null }

$report = [pscustomobject]@{
  timestamp = (Get-Date).ToString('o')
  actor = 'Cursor Agent — Observability Copilot'
  days_threshold = $Days
  include_logs = [bool]$IncludeLogs
  force = [bool]$Force
  total_candidates = $selected.Count
  total_size_bytes = $totalBytes
  deleted_count = $deleted.Count
  candidates = $selected
  deleted = $deleted
}

$reportPath = Join-Path $artifactDir ("cleanup-report-{0}.json" -f (New-Timestamp))
$report | ConvertTo-Json -Depth 5 | Set-Content -Path $reportPath -Encoding UTF8

Write-Color "Report written: $reportPath" ([ConsoleColor]::White)

# Verify hint
Write-Host "Verification: `(Get-Content $reportPath | ConvertFrom-Json).total_candidates` should be >= 0"
