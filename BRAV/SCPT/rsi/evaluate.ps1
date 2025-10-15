Param(
  [string]$Candidate = '.agent/rsi-candidate.json',
  [string]$BaselineTag = '',
  [int]$IndexSampleN = 1000,
  [int]$ArchTasks = 480,
  [int]$ArchTaskMs = 800,
  [switch]$DryRun
)
$ErrorActionPreference = 'Stop'

function Read-Json([string]$p){ if (-not (Test-Path $p)) { return $null }; try { Get-Content -Raw -LiteralPath $p | ConvertFrom-Json } catch { $null } }
function AppendLine([string]$p,[string]$line){ $dir=Split-Path -Parent $p; if($dir -and -not(Test-Path $dir)){ New-Item -ItemType Directory -Force -Path $dir|Out-Null}; Add-Content -LiteralPath $p -Value $line -Encoding utf8 }

if (Test-Path '.agent/LOCK') { throw '.agent/LOCK present — RSI paused by governance.' }

$cand = Read-Json $Candidate
if (-not $cand) { throw "Candidate JSON not found or invalid: $Candidate" }

# 1) Ensure baseline exists (or create one now)
$nowTag = 'rsi-' + (Get-Date -Format 'yyyyMMdd_HHmmss')
$baseline = if ($BaselineTag) { $BaselineTag } else { '' }

if (-not $baseline) {
  $baseline = 'baseline-' + (Get-Date -Format 'yyyyMMdd_HHmmss')
  # Run index baseline
  pwsh BRAV/SCPT/rsi-bench/bench-index.ps1 -IndexConcurrency 8 -BatchSize 1000 -SampleN $IndexSampleN -Tag $baseline | Out-Null
  # Run arch baseline
  pwsh BRAV/SCPT/rsi-bench/bench-archive.ps1 -ArchQps 2.0 -ArchConcurrency 48 -Tasks $ArchTasks -TaskMs $ArchTaskMs -Tag $baseline | Out-Null
}

# 2) Run candidate benches
$idxTag = "$nowTag-idx"
$archTag = "$nowTag-arch"

$idxConc = [int]$cand.index.IndexConcurrency
$idxBatch = [int]$cand.index.BatchSize
if (-not $idxConc) { $idxConc = 8 }
if (-not $idxBatch) { $idxBatch = 1000 }

pwsh BRAV/SCPT/rsi-bench/bench-index.ps1 -IndexConcurrency $idxConc -BatchSize $idxBatch -SampleN $IndexSampleN -Tag $idxTag | Out-Null

$aQps = [double]$cand.conveyor.ARCH_QPS
$aConc = [int]$cand.conveyor.ARCH_CONCURRENCY
if (-not $aQps) { $aQps = 2.0 }
if (-not $aConc) { $aConc = 48 }

pwsh BRAV/SCPT/rsi-bench/bench-archive.ps1 -ArchQps $aQps -ArchConcurrency $aConc -Tasks $ArchTasks -TaskMs $ArchTaskMs -Tag $archTag | Out-Null

# 3) Score
$scoreJSON = node BRAV/SCPT/rsi-bench/score.mjs --compare $baseline $idxTag --kind index
$scoreIdx = $scoreJSON | ConvertFrom-Json

$scoreJSON2 = node BRAV/SCPT/rsi-bench/score.mjs --compare $baseline $archTag --kind arch
$scoreArch = $scoreJSON2 | ConvertFrom-Json

$pass = ($scoreIdx.pass -and $scoreArch.pass)

# 4) Evidence & TL;DR
$ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss K'
$tldr = @()
$tldr += "# RSI Evaluation — BossCat TL;DR"
$tldr += ""
$tldr += "- Timestamp: $ts"
$tldr += "- Baseline: $baseline"
$tldr += "- Candidate: index tag $idxTag, arch tag $archTag"
$tldr += "- Verdict: $(([string]::Copy(($pass) ? 'PASS' : 'REJECT')))"
$tldr += ""
$tldr += "## Index"
$tldr += "- Δ score: $($scoreIdx.score) • pass=$($scoreIdx.pass) • files/sec=$($scoreIdx.index.primary.files_per_sec)"
$tldr += ""
$tldr += "## Archive"
$tldr += "- Δ score: $($scoreArch.score) • pass=$($scoreArch.pass) • arch_qps_effective=$($scoreArch.arch.primary.arch_qps_effective)"

$mdPath = 'docs/ecrr/ECRR_REPORTS/RSI_EVAL_LATEST.md'
$mdDir = Split-Path -Parent $mdPath
if (-not (Test-Path $mdDir)) { New-Item -ItemType Directory -Force -Path $mdDir | Out-Null }
Set-Content -LiteralPath $mdPath -Value ($tldr -join "`r`n") -Encoding utf8

$logLine = "[$ts] RSI: baseline=$baseline → idx=$idxTag arch=$archTag verdict=$(([string]::Copy(($pass)?'PASS':'REJECT')))"
AppendLine 'BOSSCAT_LOG.md' $logLine

if (-not $pass) {
  Write-Warning 'RSI candidate rejected by gates.'
  if (-not $DryRun) { exit 2 }
} else {
  Write-Host 'RSI candidate passes gates. Prepare PR (skeleton).' -ForegroundColor Green
}
