#!/usr/bin/env pwsh
#Requires -Version 7
<#
.SYNOPSIS
  RSI BatchSize Sweep - Systematic search for optimal batch size
.DESCRIPTION
  Tests multiple BatchSize values while holding IndexConcurrency constant.
  Logs all results to METRICS.jsonl for comparison via score.mjs.
.PARAMETER Concurrency
  IndexConcurrency to use (default: 8, current optimum)
.PARAMETER SampleN
  Number of files to process (default: 1500 for speed)
.PARAMETER BatchSizes
  Array of BatchSize values to test (default: 500,800,1000,1200,1500)
.PARAMETER TagPrefix
  Prefix for tags (default: sweep-batch)
.EXAMPLE
  pwsh BRAV/SCPT/rsi-bench/sweep-batchsize.ps1 -SampleN 1500
.EXAMPLE
  pwsh BRAV/SCPT/rsi-bench/sweep-batchsize.ps1 -BatchSizes 600,800,1000,1200 -SampleN 2000
#>

param(
  [int]$Concurrency = 8,
  [int]$SampleN = 1500,
  [int[]]$BatchSizes = @(500, 800, 1000, 1200, 1500),
  [string]$TagPrefix = "sweep-batch"
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Colors
$Cyan = "`e[96m"
$Yellow = "`e[93m"
$Green = "`e[92m"
$Red = "`e[91m"
$Reset = "`e[0m"

Write-Host "${Cyan}═══════════════════════════════════════════════════════${Reset}"
Write-Host "${Cyan}🔍 RSI BatchSize Sweep${Reset}"
Write-Host "${Cyan}═══════════════════════════════════════════════════════${Reset}"
Write-Host ""
Write-Host "  Concurrency: ${Yellow}$Concurrency${Reset} (fixed)"
Write-Host "  SampleN: ${Yellow}$SampleN${Reset}"
Write-Host "  BatchSizes: ${Yellow}$($BatchSizes -join ', ')${Reset}"
Write-Host ""

# Results collection
$results = @()
$baselineResult = $null

foreach ($batchSize in $BatchSizes) {
  $tag = "${TagPrefix}-${batchSize}"
  
  Write-Host "${Yellow}Testing BatchSize=${batchSize}...${Reset}" -NoNewline
  
  try {
    # Run benchmark
    $output = & pwsh -File "$PSScriptRoot/bench-index.ps1" `
      -IndexConcurrency $Concurrency `
      -BatchSize $batchSize `
      -SampleN $SampleN `
      -Tag $tag 2>&1
    
    # Extract elapsed time from output
    $elapsed = $null
    $outputStr = $output | Out-String
    if ($outputStr -match '([\d.]+)\s*$') {
      $elapsed = [double]$Matches[1]
    }
    
    if ($null -eq $elapsed) {
      Write-Host " ${Red}✗ Failed to parse elapsed time${Reset}"
      Write-Host "  Output: $outputStr"
      continue
    }
    
    # Calculate throughput
    $filesPerSec = [math]::Round($SampleN / $elapsed, 2)
    
    $result = @{
      BatchSize = $batchSize
      Elapsed = $elapsed
      FilesPerSec = $filesPerSec
      Tag = $tag
    }
    
    $results += [PSCustomObject]$result
    
    # Mark baseline (BatchSize=1000, current default)
    if ($batchSize -eq 1000) {
      $baselineResult = $result
      Write-Host " ${Green}✓${Reset} ${filesPerSec} files/sec ${Cyan}[BASELINE]${Reset}"
    } else {
      # Calculate delta vs baseline if available
      if ($null -ne $baselineResult) {
        $delta = (($filesPerSec - $baselineResult.FilesPerSec) / $baselineResult.FilesPerSec) * 100
        $deltaStr = if ($delta -ge 0) { "+$([math]::Round($delta, 2))%" } else { "$([math]::Round($delta, 2))%" }
        $deltaColor = if ($delta -ge 0) { $Green } else { $Red }
        Write-Host " ${Green}✓${Reset} ${filesPerSec} files/sec (${deltaColor}${deltaStr}${Reset} vs baseline)"
      } else {
        Write-Host " ${Green}✓${Reset} ${filesPerSec} files/sec"
      }
    }
    
  } catch {
    Write-Host " ${Red}✗ Error: $($_.Exception.Message)${Reset}"
  }
}

Write-Host ""
Write-Host "${Cyan}═══════════════════════════════════════════════════════${Reset}"
Write-Host "${Cyan}📊 Sweep Results Summary${Reset}"
Write-Host "${Cyan}═══════════════════════════════════════════════════════${Reset}"
Write-Host ""

if ($results.Count -eq 0) {
  Write-Host "${Red}No results collected${Reset}"
  exit 1
}

# Sort by throughput (descending)
$sortedResults = $results | Sort-Object -Property FilesPerSec -Descending

# Display results table
$sortedResults | Format-Table -AutoSize @(
  @{Label="Rank"; Expression={$sortedResults.IndexOf($_) + 1}},
  @{Label="BatchSize"; Expression={$_.BatchSize}},
  @{Label="Files/sec"; Expression={$_.FilesPerSec}},
  @{Label="Elapsed (s)"; Expression={$_.Elapsed}},
  @{Label="Tag"; Expression={$_.Tag}}
)

# Find best configuration
$best = $sortedResults[0]

Write-Host ""
Write-Host "${Green}🏆 Best Configuration:${Reset}"
Write-Host "  BatchSize: ${Yellow}$($best.BatchSize)${Reset}"
Write-Host "  Throughput: ${Yellow}$($best.FilesPerSec)${Reset} files/sec"
Write-Host "  Tag: ${Yellow}$($best.Tag)${Reset}"

if ($null -ne $baselineResult) {
  $improvement = (($best.FilesPerSec - $baselineResult.FilesPerSec) / $baselineResult.FilesPerSec) * 100
  $improvementStr = [math]::Round($improvement, 2)
  
  Write-Host ""
  if ($improvement -gt 0) {
    Write-Host "${Green}✓ Improvement vs baseline (1000): +${improvementStr}%${Reset}"
  } elseif ($improvement -eq 0) {
    Write-Host "${Yellow}= No change vs baseline (1000)${Reset}"
  } else {
    Write-Host "${Red}✗ Regression vs baseline (1000): ${improvementStr}%${Reset}"
  }
}

Write-Host ""
Write-Host "${Cyan}Next Steps:${Reset}"
Write-Host "  1. Review results above"
Write-Host "  2. Check METRICS.jsonl: ${Yellow}CHAR/EVID/artifacts/ecrr/index/METRICS.jsonl${Reset}"
Write-Host "  3. Compare configurations:"
Write-Host "     ${Yellow}node BRAV/SCPT/rsi-bench/score.mjs --compare $($baselineResult.Tag) $($best.Tag) --kind index${Reset}"
Write-Host ""

