#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Append a concise benchmark summary to a daily note under CHAR/EVID.

.PARAMETER TrendCsvPath
  Path to processing-trend.csv produced by the benchmark harness.

.PARAMETER DailyDir
  Directory to store daily notes (default: CHAR/EVID/daily).

.PARAMETER LogPath
  Optional path to the overnight benchmark log; included for reference.
#>

[CmdletBinding()]
param(
  [string]$TrendCsvPath = 'CHAR/EVID/benchmarks/process-all-ecrr-reports/processing-trend.csv',
  [string]$DailyDir = 'CHAR/EVID/daily',
  [string]$LogPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path $TrendCsvPath)) {
  Write-Host "[Summary] Trend CSV not found: $TrendCsvPath" -ForegroundColor Yellow
  exit 0
}

try {
  $rows = Import-Csv -Path $TrendCsvPath
  if (-not $rows -or $rows.Count -lt 1) {
    Write-Host "[Summary] Trend CSV is empty: $TrendCsvPath" -ForegroundColor Yellow
    exit 0
  }
  $last = $rows[-1]
} catch {
  Write-Host "[Summary] Failed to parse trend CSV: $($_.Exception.Message)" -ForegroundColor Red
  exit 1
}

$dateStr = (Get-Date).ToString('yyyy-MM-dd')
if (-not (Test-Path $DailyDir)) { $null = New-Item -ItemType Directory -Path $DailyDir -Force }
$notePath = Join-Path $DailyDir ("$dateStr.md")

$ts = $last.timestamp
$scenario = $last.scenario
$par = $last.parallelism
$rep = $last.reportCount
$iter = $last.iterations
$issues = $last.issuesFound
$faultPct = $last.faultyPercentage
$bestMs = $last.bestMs
$avgMs = $last.averageMs
$score = $last.score
$scoreBonus = $last.scoreWithBonus
$runDir = $last.runDir

$lines = @()
if (-not (Test-Path $notePath)) {
  $lines += "# Daily Evidence — $dateStr"
  $lines += ""
}

$lines += "## Benchmark Summary ($ts)"
$lines += "- Scenario: $scenario (parallelism: $par)"
$lines += "- Reports: $rep • Iterations: $iter • Issues: $issues • Faulty: $faultPct%"
$lines += "- Latency: best $bestMs ms • avg $avgMs ms"
$lines += "- Score: $score (with bonus: $scoreBonus)"
$lines += "- Run dir: $runDir"
if ($LogPath) { $lines += "- Log: $LogPath" }
$lines += ""

Add-Content -Path $notePath -Value $lines -Encoding UTF8
Write-Host "[Summary] Appended to $notePath" -ForegroundColor Green

