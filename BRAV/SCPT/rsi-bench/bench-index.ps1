Param(
  [int]$IndexConcurrency = 8,
  [int]$BatchSize = 1000,
  [int]$SampleN = 1000,
  [string]$Tag = '',
  [switch]$Trace,
  [string]$ArchivedRoot = 'docs/BossCat/run-reports/archived',
  [string]$BenchRoot = '.bench/archived'
)
$ErrorActionPreference = 'Stop'

function Ensure-Dir([string]$p){ if (-not (Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function Append-JSONL([string]$path, [hashtable]$obj){ Ensure-Dir (Split-Path -Parent $path); ($obj | ConvertTo-Json -Compress) + "`n" | Add-Content -LiteralPath $path -Encoding utf8 }

# Kill-switch
if (Test-Path '.agent/LOCK') { throw '.agent/LOCK present — RSI paused by governance.' }

# Resolve dataset: copy a deterministic sample from archived → bench
if (-not (Test-Path -LiteralPath $ArchivedRoot)) {
  throw "Archived root not found: $ArchivedRoot"
}
Ensure-Dir $BenchRoot

$allFiles = @(Get-ChildItem -Path $ArchivedRoot -Recurse -File -Filter 'run-*.md')
if ($allFiles.Count -eq 0) { throw "No archived run reports under $ArchivedRoot" }

# Deterministic sample by path order
$sample = $allFiles | Sort-Object FullName | Select-Object -First $SampleN

# Mirror the folder structure into .bench/archived (shallow copy)
foreach ($f in $sample) {
  $rootPath = (Resolve-Path $ArchivedRoot).Path
  $rel = $f.FullName.Substring($rootPath.Length)
  if ($rel.StartsWith('\\') -or $rel.StartsWith('/')) { $rel = $rel.Substring(1) }
  $dst = Join-Path $BenchRoot $rel
  Ensure-Dir (Split-Path -Parent $dst)
  Copy-Item -LiteralPath $f.FullName -Destination $dst -Force
}

# Worklist to process
$work = @(Get-ChildItem -Path $BenchRoot -Recurse -File -Filter 'run-*.md')
$total = $work.Count
if ($total -eq 0) { throw 'Sampling produced no files to process.' }

Write-Host "🧪 RSI Bench — Index" -ForegroundColor Yellow
Write-Host "  Files: $total  | Concurrency: $IndexConcurrency  | Batch: $BatchSize" -ForegroundColor DarkGray

# Simple parser: read key metadata lines; simulate per-batch append by grouping
function Parse-Item([string]$path){
  $lines = Get-Content -LiteralPath $path -ErrorAction SilentlyContinue
  $obj = [ordered]@{ id=$null; workflow=$null; actor=$null; conclusion=$null; duration=0; date=$null }
  foreach($line in $lines){
    if (-not $obj.id -and $line -match '^\- \*\*ID:\*\*\s+(\d+)') { $obj.id = $matches[1] }
    elseif (-not $obj.workflow -and $line -match '^\- \*\*Workflow:\*\*\s+(.+)$') { $obj.workflow = $matches[1].Trim() }
    elseif (-not $obj.actor -and $line -match '^\- \*\*Actor:\*\*\s+@([A-Za-z0-9_.\-]+)') { $obj.actor = $matches[1] }
    elseif (-not $obj.conclusion -and $line -match '^\- \*\*Conclusion:\*\*\s+`([^`]+)`') { $obj.conclusion = $matches[1] }
    elseif (-not $obj.duration -and $line -match '^\- \*\*Duration:\*\*\s+([0-9]+)s') { $obj.duration = [int]$matches[1] }
    elseif (-not $obj.date -and $line -match '^\- \*\*Started:\*\*\s+([0-9T:\-]+)') { try { $obj.date = ([datetime]::Parse($matches[1])).ToString('yyyy-MM-dd') } catch {} }
  }
  if (-not $obj.id) { $obj.id = '-'; }
  return $obj
}

$errors = 0
$processed = [System.Collections.Concurrent.ConcurrentBag[object]]::new()

$sw = [System.Diagnostics.Stopwatch]::StartNew()

# Process in batches respecting BatchSize and IndexConcurrency
for ($i = 0; $i -lt $total; $i += $BatchSize) {
  $batch = $work | Select-Object -Skip $i -First $BatchSize
  $jobs = @()
  # Pre-split batch into worker chunks deterministically
  $chunks = @()
  for ($w = 0; $w -lt $IndexConcurrency; $w++) { $chunks += ,@() }
  for ($j = 0; $j -lt $batch.Count; $j++) {
    $w = $j % [Math]::Max($IndexConcurrency,1)
    $chunks[$w] += ,$batch[$j]
  }
  foreach ($chunk in $chunks) {
    if ($chunk.Count -eq 0) { continue }
    $jobs += Start-Job -ScriptBlock {
      param($list)
      $ok = 0; $err = 0
      foreach($f in $list){
        try { $null = Get-Content -LiteralPath $f.FullName -ErrorAction Stop -TotalCount 200; $ok++ } catch { $err++ }
      }
      [pscustomobject]@{ok=$ok;err=$err}
    } -ArgumentList (,@($chunk))
  }
  if ($jobs.Count -gt 0) {
    Receive-Job -Job $jobs -Wait | ForEach-Object {
      for ($k=0; $k -lt $_.ok; $k++) { $null = $processed.Add(1) }
      $errors += $_.err
    }
    Remove-Job -Job $jobs -Force -ErrorAction SilentlyContinue | Out-Null
  }
}

$sw.Stop()

$elapsedMs = [int]$sw.Elapsed.TotalMilliseconds
$filesSec = if ($elapsedMs -gt 0) { [math]::Round(($total / $elapsedMs) * 1000, 2) } else { 0 }

$ts = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK'
$tag = if ($Tag) { $Tag } else { 'rsi-' + (Get-Date -Format 'yyyyMMdd_HHmmss') }

$metricsPath = 'CHAR/EVID/artifacts/ecrr/index/METRICS.jsonl'
Append-JSONL $metricsPath (@{
  ts=$ts; tag=$tag; kind='index';
  params=@{ IndexConcurrency=$IndexConcurrency; BatchSize=$BatchSize; SampleN=$SampleN };
  totals=@{ files=$total; elapsed_ms=$elapsedMs };
  primary=@{ files_per_sec=$filesSec };
  guards=@{ errors=$errors; batch_p95_ms=$null; append_p95_ms=$null }
})

if ($Trace) {
  Write-Host ("Elapsed: {0} ms | Files/sec: {1}" -f $elapsedMs, $filesSec) -ForegroundColor Green
}

Write-Output ($filesSec)
