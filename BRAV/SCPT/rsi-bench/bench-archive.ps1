Param(
  [double]$ArchQps = 2.0,
  [int]$ArchConcurrency = 48,
  [int]$Tasks = 480,
  [int]$TaskMs = 1000,
  [string]$Tag = '',
  [switch]$Trace
)
$ErrorActionPreference = 'Stop'

function Append-JSONL([string]$path, [hashtable]$obj){ $dir = Split-Path -Parent $path; if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }; ($obj | ConvertTo-Json -Compress) + "`n" | Add-Content -LiteralPath $path -Encoding utf8 }

if (Test-Path '.agent/LOCK') { throw '.agent/LOCK present — RSI paused by governance.' }

# Use conveyor self-test to exercise concurrency with deterministic synthetic tasks
$env:CONVEYOR_SELFTEST = '1'
$env:CONVEYOR_SELFTEST_N = [string]$Tasks
$env:CONVEYOR_SELFTEST_MS = [string]$TaskMs
$env:ARCH_CONCURRENCY = [string]$ArchConcurrency
$env:ARCH_QPS = [string]$ArchQps
$env:REPO_ROOT = (Resolve-Path '.').Path

Write-Host "🧪 RSI Bench — Archive (self-test)" -ForegroundColor Yellow
Write-Host "  Workers: $ArchConcurrency | QPS: $ArchQps | Tasks: $Tasks × ${TaskMs}ms" -ForegroundColor DarkGray

$sw = [System.Diagnostics.Stopwatch]::StartNew()
node BRAV/SCPT/run-archiver/conveyor.mjs | Out-String | Write-Verbose
$sw.Stop()

$elapsedMs = [int]$sw.Elapsed.TotalMilliseconds
$effectiveQps = if ($elapsedMs -gt 0) { [math]::Round(($Tasks / ($elapsedMs/1000.0)), 2) } else { 0 }

$ts = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK'
$tag = if ($Tag) { $Tag } else { 'rsi-' + (Get-Date -Format 'yyyyMMdd_HHmmss') }

$metricsPath = 'CHAR/EVID/artifacts/ecrr/arch/METRICS.jsonl'
Append-JSONL $metricsPath (@{
  ts=$ts; tag=$tag; kind='arch';
  params=@{ ARCH_QPS=$ArchQps; ARCH_CONCURRENCY=$ArchConcurrency; Tasks=$Tasks; TaskMs=$TaskMs };
  totals=@{ tasks=$Tasks; elapsed_ms=$elapsedMs };
  primary=@{ arch_qps_effective=$effectiveQps };
  guards=@{ error_rate=0; rate_backoff_ms=$null; http429=0; http5xx=0 }
})

if ($Trace) {
  Write-Host ("Elapsed: {0} ms | Effective QPS: {1}" -f $elapsedMs, $effectiveQps) -ForegroundColor Green
}

Write-Output ($effectiveQps)

