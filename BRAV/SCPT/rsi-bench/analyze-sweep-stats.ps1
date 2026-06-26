#!/usr/bin/env pwsh
#Requires -Version 7
<#
.SYNOPSIS
  RSI Sweep Statistical Analysis - Calculate median, stddev, confidence intervals
.DESCRIPTION
  Analyzes multiple sweep runs to determine statistical significance of performance differences.
  Calculates median (robust to outliers), standard deviation, and confidence intervals.
.PARAMETER TagPattern
  Pattern to match sweep tags (e.g., "nightly-sweep-r*-bs*")
.PARAMETER OutputReport
  Path to output ECRR report
.PARAMETER ConfidenceLevel
  Confidence level for intervals (default: 0.95 for 95% CI)
.EXAMPLE
  pwsh BRAV/SCPT/rsi-bench/analyze-sweep-stats.ps1 -TagPattern "nightly-sweep-r*-bs*"
#>

Param(
  [string]$TagPattern = "nightly-sweep-r*-bs*",
  [string]$OutputReport = "CHAR/ECRR/ECRR_REPORTS/ECRR_RSI_NIGHTLY_STATS_LATEST.md",
  [double]$ConfidenceLevel = 0.95
)

$ErrorActionPreference = 'Stop'

function Read-Metrics([string]$file) {
  if (-not (Test-Path $file)) { return @() }
  Get-Content -LiteralPath $file | ForEach-Object {
    if ($_) {
      try { $_ | ConvertFrom-Json } catch {}
    }
  }
}

function Get-Median([double[]]$values) {
  $sorted = $values | Sort-Object
  $n = $sorted.Count
  if ($n -eq 0) { return 0 }
  if ($n % 2 -eq 1) {
    return $sorted[[int]($n / 2)]
  } else {
    $mid1 = $sorted[[int]($n / 2) - 1]
    $mid2 = $sorted[[int]($n / 2)]
    return ($mid1 + $mid2) / 2
  }
}

function Get-StdDev([double[]]$values, [double]$mean) {
  if ($values.Count -le 1) { return 0 }
  $sumSquares = ($values | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Sum).Sum
  return [Math]::Sqrt($sumSquares / ($values.Count - 1))
}

function Get-ConfidenceInterval([double[]]$values, [double]$mean, [double]$stddev, [double]$confidence) {
  if ($values.Count -le 1) { return @{ Lower = $mean; Upper = $mean } }
  
  # T-distribution critical value (approximation for small samples)
  $n = $values.Count
  $df = $n - 1
  $alpha = 1 - $confidence
  
  # T-critical approximations (for common confidence levels)
  $tCritical = if ($confidence -eq 0.95) {
    switch ($df) {
      2 { 4.303 }
      3 { 3.182 }
      4 { 2.776 }
      5 { 2.571 }
      default { 2.262 }  # ~10+ samples
    }
  } else { 2.0 }  # Rough approximation
  
  $marginOfError = $tCritical * ($stddev / [Math]::Sqrt($n))
  
  return @{
    Lower = $mean - $marginOfError
    Upper = $mean + $marginOfError
    MarginOfError = $marginOfError
  }
}

# Read metrics
$metFile = 'CHAR/EVID/artifacts/ecrr/index/METRICS.jsonl'
$rows = @(Read-Metrics $metFile | Where-Object { 
  $_.kind -eq 'index' -and $_.tag -like $TagPattern 
})

if ($rows.Count -eq 0) {
  Write-Warning "No metrics found matching pattern: $TagPattern"
  exit 1
}

# Group by BatchSize
$grouped = @{}
foreach ($row in $rows) {
  $bs = [int]$row.params.BatchSize
  if (-not $grouped.ContainsKey($bs)) {
    $grouped[$bs] = @()
  }
  $grouped[$bs] += [double]$row.primary.files_per_sec
}

# Calculate statistics for each BatchSize
$stats = @{}
foreach ($bs in $grouped.Keys) {
  $values = $grouped[$bs]
  $mean = ($values | Measure-Object -Average).Average
  $median = Get-Median $values
  $stddev = Get-StdDev $values $mean
  $ci = Get-ConfidenceInterval $values $mean $stddev $ConfidenceLevel
  
  $stats[$bs] = @{
    BatchSize = $bs
    N = $values.Count
    Mean = [Math]::Round($mean, 2)
    Median = [Math]::Round($median, 2)
    StdDev = [Math]::Round($stddev, 2)
    CV = if ($mean -gt 0) { [Math]::Round(($stddev / $mean) * 100, 2) } else { 0 }
    CI_Lower = [Math]::Round($ci.Lower, 2)
    CI_Upper = [Math]::Round($ci.Upper, 2)
    CI_Margin = [Math]::Round($ci.MarginOfError, 2)
    Values = $values
  }
}

# Find baseline and best
$baseline = if ($stats.ContainsKey(1000)) { $stats[1000] } else { $null }
$bestBS = ($stats.Keys | Sort-Object { $stats[$_].Median } -Descending | Select-Object -First 1)
$best = $stats[$bestBS]

# Generate report
$ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss K'
$ciPercent = [int]($ConfidenceLevel * 100)

$lines = @()
$lines += '# ECRR — RSI Sweep Statistical Analysis'
$lines += ''
$lines += "**Timestamp**: $ts"
$lines += "**Tag Pattern**: ``$TagPattern``"
$lines += "**Samples per BatchSize**: $($stats[$bestBS].N)"
$lines += "**Confidence Level**: $ciPercent%"
$lines += ''
$lines += '---'
$lines += ''
$lines += '## Summary Statistics'
$lines += ''
$lines += '| BatchSize | Median (files/sec) | Mean | StdDev | CV% | 95% CI |'
$lines += '|-----------|-------------------|------|--------|-----|--------|'

foreach ($bs in ($stats.Keys | Sort-Object)) {
  $s = $stats[$bs]
  $marker = if ($bs -eq 1000) { ' **(baseline)**' } elseif ($bs -eq $bestBS) { ' **(best)**' } else { '' }
  $ci = "[$($s.CI_Lower), $($s.CI_Upper)]"
  $lines += "| $bs$marker | **$($s.Median)** | $($s.Mean) | ±$($s.StdDev) | $($s.CV)% | $ci |"
}

$lines += ''
$lines += '_CV = Coefficient of Variation (lower is more consistent)_'
$lines += ''
$lines += '---'
$lines += ''
$lines += '## Detailed Analysis'
$lines += ''

foreach ($bs in ($stats.Keys | Sort-Object)) {
  $s = $stats[$bs]
  $lines += "### BatchSize=$bs"
  $lines += ''
  $lines += "- **N**: $($s.N) samples"
  $lines += "- **Median**: $($s.Median) files/sec (robust central tendency)"
  $lines += "- **Mean**: $($s.Mean) files/sec"
  $lines += "- **StdDev**: ±$($s.StdDev) files/sec"
  $lines += "- **CV**: $($s.CV)% (variability)"
  $lines += "- **$ciPercent% CI**: [$($s.CI_Lower), $($s.CI_Upper)] (±$($s.CI_Margin))"
  $lines += "- **Raw values**: $($s.Values -join ', ')"
  
  if ($baseline -and $bs -ne 1000) {
    $deltaMedian = (($s.Median - $baseline.Median) / $baseline.Median) * 100
    $deltaMean = (($s.Mean - $baseline.Mean) / $baseline.Mean) * 100
    
    # Simple significance test: CI overlap check
    $ciOverlap = $s.CI_Lower -le $baseline.CI_Upper -and $s.CI_Upper -ge $baseline.CI_Lower
    $significance = if ($ciOverlap) { '**NOT significant** (CIs overlap)' } else { '**Significant** (CIs do not overlap)' }
    
    $lines += ''
    $lines += '**vs Baseline (1000)**:'
    $lines += "- Median Δ: **$([Math]::Round($deltaMedian, 2))%**"
    $lines += "- Mean Δ: $([Math]::Round($deltaMean, 2))%"
    $lines += "- Statistical significance: $significance"
  }
  
  $lines += ''
}

$lines += '---'
$lines += ''
$lines += '## Conclusion'
$lines += ''

if ($baseline -and $bestBS -ne 1000) {
  $bestStat = $stats[$bestBS]
  $deltaMedian = (($bestStat.Median - $baseline.Median) / $baseline.Median) * 100
  $ciOverlap = $bestStat.CI_Lower -le $baseline.CI_Upper -and $bestStat.CI_Upper -ge $baseline.CI_Lower
  
  $lines += "**Best configuration**: BatchSize=$bestBS"
  $lines += "- Median improvement: **$([Math]::Round($deltaMedian, 2))%** vs baseline"
  $lines += "- Consistency: CV=$($bestStat.CV)% (vs baseline CV=$($baseline.CV)%)"
  
  if ($ciOverlap) {
    $lines += "- **Recommendation**: ⚠️ **Keep BatchSize=1000** (improvement not statistically significant)"
    $lines += "- Confidence intervals overlap, indicating difference may be due to variance"
  } else {
    $lines += "- **Recommendation**: ✅ **Consider BatchSize=$bestBS** (statistically significant improvement)"
    $lines += "- Confidence intervals do not overlap, indicating real performance difference"
  }
} else {
  $lines += 'Baseline (BatchSize=1000) is the best configuration.'
}

$lines += ''
$lines += '---'
$lines += ''
$lines += '## Interpretation Guide'
$lines += ''
$lines += '- **Median**: Central value, robust to outliers (preferred over mean)'
$lines += '- **StdDev**: Spread of values (lower is more consistent)'
$lines += '- **CV%**: Normalized variability (< 5% is good, < 2% is excellent)'
$lines += "- **$ciPercent% CI**: Range where true value likely lies"
$lines += '- **CI Overlap**: If CIs overlap, difference may not be real (within variance)'
$lines += ''

# Write report
$outDir = Split-Path -Parent $OutputReport
if (-not (Test-Path $outDir)) {
  New-Item -ItemType Directory -Force -Path $outDir | Out-Null
}

($lines -join "`r`n") | Set-Content -LiteralPath $OutputReport -Encoding utf8

Write-Host "✅ Statistical analysis complete: $OutputReport" -ForegroundColor Green
Write-Host ""
Write-Host "Key Findings:" -ForegroundColor Cyan
Write-Host "  Best: BatchSize=$bestBS (Median: $($best.Median) files/sec)" -ForegroundColor Yellow
if ($baseline) {
  $deltaMedian = (($best.Median - $baseline.Median) / $baseline.Median) * 100
  Write-Host "  Improvement: $([Math]::Round($deltaMedian, 2))% vs baseline" -ForegroundColor Yellow
  
  $ciOverlap = $best.CI_Lower -le $baseline.CI_Upper -and $best.CI_Upper -ge $baseline.CI_Lower
  if ($ciOverlap) {
    Write-Host "  Significance: NOT significant (keep 1000)" -ForegroundColor Red
  } else {
    Write-Host "  Significance: Significant (consider $bestBS)" -ForegroundColor Green
  }
}


