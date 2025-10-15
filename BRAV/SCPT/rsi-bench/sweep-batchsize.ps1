Param(
  [int[]]$BatchSizes = @(500,800,1000,1200,1500),
  [int]$IndexConcurrency = 8,
  [int]$SampleN = 2000,
  [string]$TagPrefix = 'sweep-batchsize',
  [string]$ArchivedRoot = 'docs/BossCat/run-reports/archived',
  [string]$BenchRoot = '.bench/archived'
)
$ErrorActionPreference = 'Stop'

function Read-Metrics([string]$file){ if(-not(Test-Path $file)){ return @() }; Get-Content -LiteralPath $file | % { if($_){ try{ $_ | ConvertFrom-Json } catch {} } } }
function Ensure-Dir([string]$p){ if(-not(Test-Path $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }

if (Test-Path '.agent/LOCK') { throw '.agent/LOCK present — sweep paused by governance.' }

$tags = @()
foreach ($bs in $BatchSizes) {
  $tag = "${TagPrefix}-bs${bs}"
  $tags += $tag
  pwsh BRAV/SCPT/rsi-bench/bench-index.ps1 -IndexConcurrency $IndexConcurrency -BatchSize $bs -SampleN $SampleN -Tag $tag -ArchivedRoot $ArchivedRoot -BenchRoot $BenchRoot -ReuseBench | Out-Null
}

$metFile = 'CHAR/EVID/artifacts/ecrr/index/METRICS.jsonl'
$rows = @(Read-Metrics $metFile | Where-Object { $_.kind -eq 'index' -and $_.tag -in $tags })
$summary = @{}
foreach ($r in $rows) {
  $bs = [int]$r.params.BatchSize
  $summary[$bs] = @{ files_per_sec = [double]$r.primary.files_per_sec; tag = $r.tag }
}

# Compute baseline and best
if (-not $summary.ContainsKey(1000)) { Write-Warning 'Baseline BatchSize=1000 not found in recent sweep results.' }
$baselineFps = if ($summary.ContainsKey(1000)) { [double]$summary[1000].files_per_sec } else { [double]0 }
$bestBS = $null; $bestFPS = -1.0
foreach ($k in $summary.Keys) { if ($summary[$k].files_per_sec -gt $bestFPS) { $bestFPS = [double]$summary[$k].files_per_sec; $bestBS = [int]$k } }

$ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss K'
$lines = @()
$lines += '# ECRR — RSI BatchSize Sweep'
$lines += ''
$lines += "Timestamp: $ts"
$lines += "SampleN: $SampleN | Concurrency: $IndexConcurrency"
$lines += ''
$lines += '## Results'
foreach ($k in ($summary.Keys | Sort-Object)) {
  $fps = [double]$summary[$k].files_per_sec
  $delta = if ($baselineFps -gt 0) { [math]::Round(($fps - $baselineFps) / $baselineFps * 100, 2) } else { 0 }
  $mark = if ($k -eq 1000) { '(baseline)' } elseif ($k -eq $bestBS) { '(best)' } else { '' }
  $lines += "- BatchSize=$k → ${fps} files/sec (${delta}%) $mark"
}
$lines += ''
$lines += '## Conclusion'
if ($bestBS -and $baselineFps -gt 0) {
  $bestDelta = [math]::Round((($bestFPS - $baselineFps) / $baselineFps) * 100, 2)
  if ($bestDelta -gt 0) {
    $lines += "BatchSize=$bestBS improves throughput by ${bestDelta}% vs baseline (1000)."
  } else {
    $lines += 'No improvement over baseline observed.'
  }
} else {
  $lines += 'Insufficient data to determine improvement.'
}

$outDir = 'docs/ecrr/ECRR_REPORTS'
Ensure-Dir $outDir
$outFile = Join-Path $outDir ("ECRR_RSI_BATCHSIZE_DISCOVERY_" + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.md')
($lines -join "`r`n") | Set-Content -LiteralPath $outFile -Encoding utf8
($lines -join "`r`n") | Set-Content -LiteralPath (Join-Path $outDir 'ECRR_RSI_BATCHSIZE_DISCOVERY_LATEST.md') -Encoding utf8

Write-Host "✅ Sweep complete. Report: $outFile" -ForegroundColor Green

