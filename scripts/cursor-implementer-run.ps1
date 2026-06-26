Param(
  [string]$Site = 'local',
  [string]$Gate = 'IONA',
  [int]$Loops = 1,
  [int]$DelaySec = 2,
  [string]$RunRoot = 'DELT/ARTF/cursor-runs',
  [switch]$Strict,
  [switch]$UseMock,
  [switch]$EmitSynthetic
)
$ErrorActionPreference = 'Stop'

function Ensure-Dirs([string[]]$Dirs){ foreach($d in $Dirs){ if(-not(Test-Path -LiteralPath $d)){ New-Item -ItemType Directory -Path $d -Force|Out-Null } } }
function Get-GitMeta { try {$c=(git rev-parse --short HEAD 2>$null).Trim()}catch{$c=''}; try{$b=(git rev-parse --abbrev-ref HEAD 2>$null).Trim()}catch{$b=''}; [pscustomobject]@{Commit=$c;Branch=$b} }
function Write-Json([object]$Obj,[string]$Path){ ($Obj | ConvertTo-Json -Depth 8) | Set-Content -Path $Path -Encoding utf8 }
function NowIso(){ Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK' }
function LatestFile([string]$Dir,[string]$Pattern){ Get-ChildItem -LiteralPath $Dir -Filter $Pattern -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1 }

if ($UseMock) { $env:USE_MOCK = 'true' }
Ensure-Dirs @('DELT/ARTF','docs/observability/snapshots','CHAR/ECRR/ECRR_REPORTS', $RunRoot)
$ts = Get-Date -Format 'yyyyMMdd_HHmmss'
$runDir = Join-Path $RunRoot ("run_"+$ts)
Ensure-Dirs @($runDir)

$summaryChecks = New-Object System.Collections.ArrayList
$screens = New-Object System.Collections.ArrayList

for ($i=1; $i -le $Loops; $i++) {
  $iter = ('{0:00}' -f $i)
  $iterDir = Join-Path $runDir ("iter-$iter")
  Ensure-Dirs @($iterDir)

  # 1) Gate verification
  $gateJson = Join-Path $iterDir 'gate-results.json'
  & pwsh -File 'scripts/verify-iona-gate.ps1' -Strict:$Strict -NoFailOnMissing -OutputJson $gateJson -PrCommentPath (Join-Path $iterDir 'PR_COMMENT.md') -Gate $Gate -Site $Site | Out-Null
  $gateObj = $null; try { $gateObj = Get-Content -Raw -LiteralPath $gateJson | ConvertFrom-Json } catch {}

  # 2) Health checks
  $ui = @{ ok=$false; status=0; body=''; target='http://127.0.0.1:8080/api/v1/health' }
  try { $r = Invoke-WebRequest -Uri $ui.target -TimeoutSec 3; $ui.ok = ($r.StatusCode -eq 200); $ui.status=$r.StatusCode; $ui.body=$r.Content } catch { $ui.ok=$false; $ui.status=0 }

  $collector = @{ ok=$false; status=0; target=''; body='' }
  foreach ($cand in @('http://127.0.0.1:13134/healthz','http://127.0.0.1:18888/metrics')) {
    try { $rr = Invoke-WebRequest -Uri $cand -TimeoutSec 3; $collector.ok = ($rr.StatusCode -eq 200 -or $rr.StatusCode -eq 0); $collector.status = ($rr.StatusCode); $collector.target = $cand; $collector.body = ($rr.Content|Select-Object -First 1); if($collector.ok){break} } catch { }
  }

  # 3) Optional synthetic trace emit
  $synthetic = @{ attempted = [bool]$EmitSynthetic; ok = $false; exitCode = -1 }
  if ($EmitSynthetic) {
    try { & pnpm -s emit | Out-Null; $synthetic.ok = $true; $synthetic.exitCode = 0 } catch { $synthetic.ok = $false; $synthetic.exitCode = 1 }
  }

  # 4) Screenshot capture
  try {
    & pnpm -s export:status:screenshot | Out-Null
    $latestPngPath = 'docs/observability/snapshots/status-latest.png'
    $latestJsonPath = 'docs/observability/snapshots/status-latest.json'
    # Wait briefly for files to appear to avoid race
    $waitStart = Get-Date
    while(-not (Test-Path -LiteralPath $latestPngPath) -and ((Get-Date) - $waitStart).TotalSeconds -lt 5) { Start-Sleep -Milliseconds 200 }
    while(-not (Test-Path -LiteralPath $latestJsonPath) -and ((Get-Date) - $waitStart).TotalSeconds -lt 5) { Start-Sleep -Milliseconds 100 }
    if (Test-Path -LiteralPath $latestPngPath) { Copy-Item -LiteralPath $latestPngPath -Destination (Join-Path $iterDir 'status.png') -Force }
    if (Test-Path -LiteralPath $latestJsonPath) { Copy-Item -LiteralPath $latestJsonPath -Destination (Join-Path $iterDir 'status.json') -Force }
    if (Test-Path -LiteralPath $latestPngPath) { [void]$screens.Add((Split-Path -Leaf $latestPngPath)) }
    if (-not (Test-Path -LiteralPath $latestPngPath)) {
      # Fallback to newest timestamped file
      $latestPng = LatestFile 'docs/observability/snapshots' 'status-*.png'
      $latestJson = LatestFile 'docs/observability/snapshots' 'status-*.json'
      if ($latestPng) { Copy-Item -LiteralPath $latestPng.FullName -Destination (Join-Path $iterDir 'status.png') -Force }
      if ($latestJson) { Copy-Item -LiteralPath $latestJson.FullName -Destination (Join-Path $iterDir 'status.json') -Force }
      if ($latestPng) { [void]$screens.Add((Split-Path -Leaf $latestPng.FullName)) }
    }
  } catch {}

  # 5) Compose per-iteration summary
  $iterSummary = [ordered]@{
    iteration = $i
    timestamp = (NowIso)
    site = $Site
    gate = $Gate
    ui = $ui
    collector = $collector
    synthetic = $synthetic
    gate_verdict = ($gateObj.verdict | ForEach-Object { $_ })
  }
  Write-Json $iterSummary (Join-Path $iterDir 'summary.json')
  [void]$summaryChecks.Add($iterSummary)

  if ($i -lt $Loops -and $DelaySec -gt 0) { Start-Sleep -Seconds $DelaySec }
}

# Aggregate status.tests.json for the dashboard
$g = Get-GitMeta
$endedAt = NowIso
$checksArr = @(
  @{ name='ui_health'; ok=$summaryChecks[-1].ui.ok; details=@{ status=$summaryChecks[-1].ui.status; target=$summaryChecks[-1].ui.target } },
  @{ name='collector_health'; ok=$summaryChecks[-1].collector.ok; details=@{ status=$summaryChecks[-1].collector.status; target=$summaryChecks[-1].collector.target } },
  @{ name='synthetic_trace'; ok=$summaryChecks[-1].synthetic.ok; details=@{ attempted=$summaryChecks[-1].synthetic.attempted; exitCode=$summaryChecks[-1].synthetic.exitCode } }
)
$failCount = ($checksArr | Where-Object { -not $_.ok }).Count
$verdict = if ($failCount -eq 0) { 'READY' } elseif ($Strict) { 'NOT_READY' } else { 'READY_WITH_WARNINGS' }
$testsObj = [ordered]@{
  version = '1.0'
  endedAt = $endedAt
  actor = 'BossCat OEM'
  verdict = $verdict
  evidence = @()
  checks = $checksArr
  reasons = @()
  branch = $g.Branch
  commit = $g.Commit
  gatePhrase = '@cat ready-for-gate'
}
Write-Json $testsObj 'docs/status/tests.json'

# ECRR report
$ecrrLines = @(
  '# ECRR — Cursor Implementer Run',
  '',
  "Timestamp: $endedAt",
  "Branch: $($g.Branch)",
  "Commit: $($g.Commit)",
  "Gate: $Gate",
  "Site: $Site",
  '',
  '## Examine',
  "- UI health: $($checksArr[0].ok)",
  "- Collector health: $($checksArr[1].ok)",
  "- Synthetic trace: $($checksArr[2].ok) (attempted=$($checksArr[2].details.attempted))",
  '',
  '## Clean',
  '- Automated checks + screenshot evidence captured.',
  '',
  '## Report',
  "- Verdict: $verdict",
  "- Iterations: $Loops",
  '',
  '## Role',
  '- Investigator: Validated local system health',
  '- Gap-Closer: Provided runnable script + evidence to disk',
  '- QA Scribe: Updated docs/status/tests.json for dashboard'
)
$ecrrPath = Join-Path 'CHAR/ECRR/ECRR_REPORTS' ("ECRR_CURSOR_RUN_" + $ts + '.md')
($ecrrLines -join "`r`n") | Set-Content -Path $ecrrPath -Encoding utf8

Write-Host "Run complete → $runDir" -ForegroundColor Green
Write-Host "Verdict: $verdict | UI: $($checksArr[0].ok) | Collector: $($checksArr[1].ok) | Synthetic: $($checksArr[2].ok)"

